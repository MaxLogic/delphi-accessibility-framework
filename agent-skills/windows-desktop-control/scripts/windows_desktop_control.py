#!/usr/bin/env python3
"""Windows desktop control helper for Codex agents."""

from __future__ import annotations

import argparse
from collections.abc import Callable
from contextlib import contextmanager
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import queue
import struct
import subprocess
import sys
import tempfile
import threading
import time
import uuid
import winsound


PIPE_PREFIX = "\\\\.\\pipe\\"
AUTO_BRIDGE_PROBE_TIMEOUT_MS = 5
AUTO_SEMANTIC_BRIDGE_PROBE_TIMEOUT_MS = 75
BRIDGE_PROTOCOL_VERSION = 2
BRIDGE_OPERATION_POLL_SECONDS = 0.05
FASTER_SEMANTIC_ALTERNATIVES = [
    "fast-semantic-map",
    "fast-map",
    "bridge-form-map",
    "bridge-provider-map",
    "win32-map --detail geometry",
]
START_TEXT = (
    "Quick heads-up: I am going to borrow the mouse and keyboard for a moment. "
    "Please lift your hands, enjoy a tiny coffee break, and I will start in three seconds."
)
DONE_TEXT = "All done. The mouse and keyboard are yours again. Thanks for the tiny coffee break."
SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
ANNOUNCEMENT_DIR = SKILL_DIR / "assets" / "announcements"
ANNOUNCEMENTS = {
    "takeover": ("takeover.wav", START_TEXT, 3),
    "release": ("release.wav", DONE_TEXT, 0),
}

KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_EXTENDEDKEY = 0x0001
KEYEVENTF_UNICODE = 0x0004
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_MIDDLEDOWN = 0x0020
MOUSEEVENTF_MIDDLEUP = 0x0040
PW_RENDERFULLCONTENT = 0x00000002
SRCCOPY = 0x00CC0020
SW_RESTORE = 9
GA_ROOT = 2
GA_ROOTOWNER = 3
GW_HWNDNEXT = 2
GW_OWNER = 4
GW_CHILD = 5
SYNCHRONIZE = 0x00100000
WAIT_TIMEOUT = 0x00000102
DEFAULT_SESSION_STATE_PATH = Path(tempfile.gettempdir()) / "maxlogic-windows-desktop-control-lease.json"

VK_CODES = {
    "backspace": 0x08,
    "tab": 0x09,
    "enter": 0x0D,
    "shift": 0x10,
    "ctrl": 0x11,
    "control": 0x11,
    "alt": 0x12,
    "esc": 0x1B,
    "escape": 0x1B,
    "space": 0x20,
    "pageup": 0x21,
    "page-up": 0x21,
    "pagedown": 0x22,
    "page-down": 0x22,
    "end": 0x23,
    "home": 0x24,
    "left": 0x25,
    "up": 0x26,
    "right": 0x27,
    "down": 0x28,
    "insert": 0x2D,
    "delete": 0x2E,
    "del": 0x2E,
}
VK_CODES.update({f"f{number}": 0x6F + number for number in range(1, 25)})
EXTENDED_VK_CODES = {
    VK_CODES[name]
    for name in ["pageup", "pagedown", "end", "home", "left", "up", "right", "down", "insert", "delete"]
}

kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
gdi32 = ctypes.WinDLL("gdi32", use_last_error=True)
user32 = ctypes.WinDLL("user32", use_last_error=True)


ULONG_PTR = ctypes.c_ulonglong if ctypes.sizeof(ctypes.c_void_p) == 8 else ctypes.c_ulong


class RECT(ctypes.Structure):
    _fields_ = [
        ("left", wintypes.LONG),
        ("top", wintypes.LONG),
        ("right", wintypes.LONG),
        ("bottom", wintypes.LONG),
    ]


class POINT(ctypes.Structure):
    _fields_ = [("x", wintypes.LONG), ("y", wintypes.LONG)]


class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [
        ("biSize", wintypes.DWORD),
        ("biWidth", wintypes.LONG),
        ("biHeight", wintypes.LONG),
        ("biPlanes", wintypes.WORD),
        ("biBitCount", wintypes.WORD),
        ("biCompression", wintypes.DWORD),
        ("biSizeImage", wintypes.DWORD),
        ("biXPelsPerMeter", wintypes.LONG),
        ("biYPelsPerMeter", wintypes.LONG),
        ("biClrUsed", wintypes.DWORD),
        ("biClrImportant", wintypes.DWORD),
    ]


class BITMAPINFO(ctypes.Structure):
    _fields_ = [("bmiHeader", BITMAPINFOHEADER), ("bmiColors", wintypes.DWORD * 3)]


EnumWindowsProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

gdi32.BitBlt.argtypes = [
    wintypes.HDC,
    ctypes.c_int,
    ctypes.c_int,
    ctypes.c_int,
    ctypes.c_int,
    wintypes.HDC,
    ctypes.c_int,
    ctypes.c_int,
    wintypes.DWORD,
]
gdi32.BitBlt.restype = wintypes.BOOL
gdi32.CreateCompatibleBitmap.argtypes = [wintypes.HDC, ctypes.c_int, ctypes.c_int]
gdi32.CreateCompatibleBitmap.restype = wintypes.HBITMAP
gdi32.CreateCompatibleDC.argtypes = [wintypes.HDC]
gdi32.CreateCompatibleDC.restype = wintypes.HDC
gdi32.DeleteDC.argtypes = [wintypes.HDC]
gdi32.DeleteDC.restype = wintypes.BOOL
gdi32.DeleteObject.argtypes = [wintypes.HGDIOBJ]
gdi32.DeleteObject.restype = wintypes.BOOL
gdi32.GetDIBits.argtypes = [
    wintypes.HDC,
    wintypes.HBITMAP,
    wintypes.UINT,
    wintypes.UINT,
    wintypes.LPVOID,
    ctypes.POINTER(BITMAPINFO),
    wintypes.UINT,
]
gdi32.GetDIBits.restype = ctypes.c_int
gdi32.SelectObject.argtypes = [wintypes.HDC, wintypes.HGDIOBJ]
gdi32.SelectObject.restype = wintypes.HGDIOBJ
kernel32.GetCurrentThreadId.argtypes = []
kernel32.GetCurrentThreadId.restype = wintypes.DWORD
kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
kernel32.CloseHandle.restype = wintypes.BOOL
kernel32.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
kernel32.OpenProcess.restype = wintypes.HANDLE
kernel32.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
kernel32.WaitForSingleObject.restype = wintypes.DWORD
user32.AttachThreadInput.argtypes = [wintypes.DWORD, wintypes.DWORD, wintypes.BOOL]
user32.AttachThreadInput.restype = wintypes.BOOL
user32.BringWindowToTop.argtypes = [wintypes.HWND]
user32.BringWindowToTop.restype = wintypes.BOOL
user32.EnumWindows.argtypes = [EnumWindowsProc, wintypes.LPARAM]
user32.EnumWindows.restype = wintypes.BOOL
user32.GetClassNameW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetClassNameW.restype = ctypes.c_int
user32.GetCursorPos.argtypes = [ctypes.POINTER(POINT)]
user32.GetCursorPos.restype = wintypes.BOOL
user32.GetAncestor.argtypes = [wintypes.HWND, wintypes.UINT]
user32.GetAncestor.restype = wintypes.HWND
user32.GetForegroundWindow.argtypes = []
user32.GetForegroundWindow.restype = wintypes.HWND
user32.GetWindow.argtypes = [wintypes.HWND, wintypes.UINT]
user32.GetWindow.restype = wintypes.HWND
user32.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(RECT)]
user32.GetWindowRect.restype = wintypes.BOOL
user32.GetWindowTextLengthW.argtypes = [wintypes.HWND]
user32.GetWindowTextLengthW.restype = ctypes.c_int
user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetWindowTextW.restype = ctypes.c_int
user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
user32.GetWindowThreadProcessId.restype = wintypes.DWORD
user32.IsWindowVisible.argtypes = [wintypes.HWND]
user32.IsWindowVisible.restype = wintypes.BOOL
user32.IsWindowEnabled.argtypes = [wintypes.HWND]
user32.IsWindowEnabled.restype = wintypes.BOOL
user32.PrintWindow.argtypes = [wintypes.HWND, wintypes.HDC, wintypes.UINT]
user32.PrintWindow.restype = wintypes.BOOL
user32.ReleaseDC.argtypes = [wintypes.HWND, wintypes.HDC]
user32.ReleaseDC.restype = ctypes.c_int
user32.SetForegroundWindow.argtypes = [wintypes.HWND]
user32.SetForegroundWindow.restype = wintypes.BOOL
user32.ShowWindow.argtypes = [wintypes.HWND, ctypes.c_int]
user32.ShowWindow.restype = wintypes.BOOL
if hasattr(user32, "SwitchToThisWindow"):
    user32.SwitchToThisWindow.argtypes = [wintypes.HWND, wintypes.BOOL]
    user32.SwitchToThisWindow.restype = None


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [
        ("wVk", wintypes.WORD),
        ("wScan", wintypes.WORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ULONG_PTR),
    ]


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [
        ("dx", wintypes.LONG),
        ("dy", wintypes.LONG),
        ("mouseData", wintypes.DWORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ULONG_PTR),
    ]


class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [
        ("uMsg", wintypes.DWORD),
        ("wParamL", wintypes.WORD),
        ("wParamH", wintypes.WORD),
    ]


class INPUTUNION(ctypes.Union):
    _fields_ = [("mi", MOUSEINPUT), ("ki", KEYBDINPUT), ("hi", HARDWAREINPUT)]


class INPUT(ctypes.Structure):
    _fields_ = [("type", wintypes.DWORD), ("union", INPUTUNION)]


def print_json(value: object) -> None:
    print(json.dumps(value, ensure_ascii=True, indent=2))


def fail(message: str, code: int = 1, **extra: object) -> int:
    payload = {"ok": False, "message": message}
    payload.update(extra)
    print_json(payload)
    return code


def elapsed_ms_since(started: float) -> float:
    return round((time.perf_counter() - started) * 1000.0, 3)


def play_announcement(asset: str, dry_run: bool) -> dict[str, object]:
    file_name, text, sleep_after = ANNOUNCEMENTS[asset]
    path = ANNOUNCEMENT_DIR / file_name
    if not path.exists():
        raise FileNotFoundError(f"Announcement asset is missing: {path}")
    if not dry_run:
        winsound.PlaySound(str(path), winsound.SND_FILENAME)
        if sleep_after > 0:
            time.sleep(sleep_after)
    return {"provider": "asset", "asset": asset, "path": str(path), "text": text}


def command_announce(args: argparse.Namespace) -> int:
    try:
        print_json({"ok": True, **play_announcement(args.asset, args.dry_run)})
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), provider="asset")


def command_takeover(args: argparse.Namespace) -> int:
    args.asset = "takeover"
    return command_announce(args)


def command_release(args: argparse.Namespace) -> int:
    args.asset = "release"
    return command_announce(args)


def epoch_ms() -> int:
    return int(time.time() * 1000)


def process_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if pid == os.getpid():
        return True
    handle = kernel32.OpenProcess(SYNCHRONIZE, False, pid)
    if not handle:
        return False
    try:
        return kernel32.WaitForSingleObject(handle, 0) == WAIT_TIMEOUT
    finally:
        kernel32.CloseHandle(handle)


def session_state_path(args: argparse.Namespace) -> Path:
    return Path(getattr(args, "state_path", None) or DEFAULT_SESSION_STATE_PATH).resolve()


def session_lock_path(path: Path) -> Path:
    return path.with_name(path.name + ".lock")


@contextmanager
def lock_session(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    lock_path = session_lock_path(path)
    deadline = time.monotonic() + 2.0
    while True:
        try:
            descriptor = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(descriptor, str(os.getpid()).encode("ascii"))
            os.close(descriptor)
            break
        except FileExistsError:
            try:
                owner_text = lock_path.read_text(encoding="ascii").strip()
                if owner_text and not process_alive(int(owner_text)):
                    lock_path.unlink()
                    continue
            except (FileNotFoundError, OSError, ValueError):
                pass
            if time.monotonic() >= deadline:
                raise TimeoutError(f"Timed out waiting for foreground-session lock: {lock_path}")
            time.sleep(0.01)
    try:
        yield
    finally:
        try:
            lock_path.unlink()
        except FileNotFoundError:
            pass


def read_session(path: Path) -> dict[str, object] | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else None
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return None


def write_session(path: Path, value: dict[str, object]) -> None:
    temporary = path.with_name(f".{path.name}.{os.getpid()}.{uuid.uuid4().hex}.tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=True), encoding="utf-8")
    os.replace(temporary, path)


def append_session_event(path_text: object, event: str, session_id: str, **extra: object) -> None:
    if not path_text:
        return
    path = Path(str(path_text)).resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {"event": event, "sessionId": session_id, "atMs": epoch_ms(), **extra}
    with path.open("a", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(payload, ensure_ascii=True) + "\n")


def spawn_session_watchdog(path: Path, session_id: str) -> int:
    command = [
        sys.executable,
        str(Path(__file__).resolve()),
        "foreground-session",
        "_watchdog",
        "--session-id",
        session_id,
        "--state-path",
        str(path),
    ]
    flags = (
        getattr(subprocess, "CREATE_NO_WINDOW", 0)
        | getattr(subprocess, "DETACHED_PROCESS", 0)
        | getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
    )
    process = subprocess.Popen(
        command,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=flags,
        close_fds=True,
    )
    return process.pid


def command_foreground_session_start(args: argparse.Namespace) -> int:
    path = session_state_path(args)
    ttl_ms = max(1, int(args.ttl_ms))
    try:
        with lock_session(path):
            existing = read_session(path)
            if existing is not None and (
                int(existing.get("expiresAtMs") or 0) > epoch_ms()
                and process_alive(int(existing.get("controllerPid") or 0))
            ):
                same_owner = (
                    int(existing.get("targetPid") or 0) == args.target_pid
                    and int(existing.get("targetHwnd") or 0) == args.target_hwnd
                    and int(existing.get("controllerPid") or 0) == args.controller_pid
                )
                if not same_owner:
                    return fail(
                        "Another foreground session is active.",
                        2,
                        reason="session-active",
                        activeSession=existing,
                    )
                print_json(
                    {
                        "ok": True,
                        "action": "foreground-session-start",
                        "sessionId": existing["sessionId"],
                        "watchdogPid": existing.get("watchdogPid"),
                        "expiresAtMs": existing["expiresAtMs"],
                        "reused": True,
                        "announcementPlayed": False,
                    }
                )
                return 0

            if existing is not None:
                return fail(
                    "The prior foreground session is awaiting watchdog release.",
                    2,
                    reason="session-release-pending",
                    activeSession=existing,
                )

            session_id = uuid.uuid4().hex
            state: dict[str, object] = {
                "sessionId": session_id,
                "targetPid": args.target_pid,
                "targetHwnd": args.target_hwnd,
                "controllerPid": args.controller_pid,
                "expiresAtMs": epoch_ms() + ttl_ms,
                "eventPath": str(Path(args.event_path).resolve()) if args.event_path else None,
                "dryRun": bool(args.dry_run),
            }
            write_session(path, state)
            watchdog_pid = spawn_session_watchdog(path, session_id)
            state["watchdogPid"] = watchdog_pid
            write_session(path, state)
            append_session_event(state.get("eventPath"), "takeover", session_id)
        announcement = play_announcement("takeover", args.dry_run)
        print_json(
            {
                "ok": True,
                "action": "foreground-session-start",
                "sessionId": session_id,
                "watchdogPid": watchdog_pid,
                "expiresAtMs": state["expiresAtMs"],
                "reused": False,
                "announcementPlayed": True,
                "announcement": announcement,
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), 2, reason="session-start-failed")


def command_foreground_session_renew(args: argparse.Namespace) -> int:
    path = session_state_path(args)
    try:
        with lock_session(path):
            state = read_session(path)
            if state is None:
                return fail("No foreground session is active.", 2, reason="session-absent")
            if state.get("sessionId") != args.session_id:
                return fail("The foreground session ID does not match.", 2, reason="session-mismatch")
            if int(state.get("expiresAtMs") or 0) <= epoch_ms():
                return fail("The foreground session has expired.", 2, reason="session-expired")
            if not process_alive(int(state.get("controllerPid") or 0)):
                return fail("The foreground session controller has exited.", 2, reason="session-controller-exited")
            state["expiresAtMs"] = epoch_ms() + max(1, int(args.ttl_ms))
            write_session(path, state)
        print_json(
            {
                "ok": True,
                "action": "foreground-session-renew",
                "sessionId": args.session_id,
                "expiresAtMs": state["expiresAtMs"],
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), 2, reason="session-renew-failed")


def command_foreground_session_release(args: argparse.Namespace) -> int:
    path = session_state_path(args)
    try:
        with lock_session(path):
            state = read_session(path)
            if state is None:
                print_json(
                    {
                        "ok": True,
                        "action": "foreground-session-release",
                        "sessionId": args.session_id,
                        "alreadyReleased": True,
                        "announcementPlayed": False,
                    }
                )
                return 0
            if state.get("sessionId") != args.session_id:
                return fail("The foreground session ID does not match.", 2, reason="session-mismatch")
            path.unlink()
            event_path = args.event_path or state.get("eventPath")
            append_session_event(event_path, "release", args.session_id, reason="normal")
        announcement = play_announcement("release", bool(state.get("dryRun")))
        print_json(
            {
                "ok": True,
                "action": "foreground-session-release",
                "sessionId": args.session_id,
                "alreadyReleased": False,
                "announcementPlayed": True,
                "announcement": announcement,
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), 2, reason="session-release-failed")


def command_foreground_session_status(args: argparse.Namespace) -> int:
    path = session_state_path(args)
    state = read_session(path)
    active = bool(
        state is not None
        and int(state.get("expiresAtMs") or 0) > epoch_ms()
        and process_alive(int(state.get("controllerPid") or 0))
    )
    print_json({"ok": True, "action": "foreground-session-status", "active": active, "lease": state})
    return 0


def command_foreground_session_watchdog(args: argparse.Namespace) -> int:
    path = session_state_path(args)
    while True:
        state = read_session(path)
        if state is None or state.get("sessionId") != args.session_id:
            return 0
        expired = int(state.get("expiresAtMs") or 0) <= epoch_ms()
        controller_exited = not process_alive(int(state.get("controllerPid") or 0))
        if not expired and not controller_exited:
            time.sleep(0.05)
            continue
        with lock_session(path):
            state = read_session(path)
            if state is None or state.get("sessionId") != args.session_id:
                return 0
            expired = int(state.get("expiresAtMs") or 0) <= epoch_ms()
            controller_exited = not process_alive(int(state.get("controllerPid") or 0))
            if not expired and not controller_exited:
                continue
            path.unlink()
            reason = "controller-exited" if controller_exited else "expired"
            append_session_event(state.get("eventPath"), "release", args.session_id, reason=reason)
        try:
            play_announcement("release", bool(state.get("dryRun")))
        except Exception:
            return 1
        return 0


def normalize_pipe_path(pipe_name: str) -> str:
    value = pipe_name.strip()
    if not value:
        raise ValueError("Pipe name must not be empty.")
    if value.lower().startswith(PIPE_PREFIX.lower()):
        return value
    return PIPE_PREFIX + value


def wait_named_pipe(path: str, timeout_ms: int) -> bool:
    kernel32.WaitNamedPipeW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD]
    kernel32.WaitNamedPipeW.restype = wintypes.BOOL
    return bool(kernel32.WaitNamedPipeW(path, timeout_ms))


def wait_named_pipe_until_available(path: str, timeout_ms: int) -> bool:
    deadline = time.monotonic() + max(timeout_ms, 1) / 1000.0
    while True:
        remaining_ms = max(0, int((deadline - time.monotonic()) * 1000))
        if wait_named_pipe(path, remaining_ms):
            return True
        if time.monotonic() >= deadline:
            return False
        sleep_seconds = max(0.0, min(0.025, deadline - time.monotonic()))
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)


def read_line(handle) -> str:
    line = handle.readline()
    if not line:
        raise RuntimeError("Pipe closed before a response line was received.")
    if not line.endswith(b"\n"):
        raise RuntimeError("Pipe closed before a complete response line was received.")
    return line.rstrip(b"\r\n").decode("utf-8")


def bridge_request(pipe_name: str, request_text: str, timeout_ms: int) -> dict[str, object]:
    path = normalize_pipe_path(pipe_name)
    if not wait_named_pipe_until_available(path, timeout_ms):
        raise RuntimeError(f"Named pipe is not available: {path}")
    with open(path, "r+b", buffering=0) as pipe:
        pipe.write(request_text.encode("utf-8") + b"\n")
        response = read_line(pipe)
    try:
        return json.loads(response)
    except json.JSONDecodeError:
        return {"ok": False, "raw": response, "message": "Response was not JSON."}


def bridge_request_many(pipe_name: str, request_texts: list[str], timeout_ms: int) -> list[dict[str, object]]:
    path = normalize_pipe_path(pipe_name)
    if not wait_named_pipe_until_available(path, timeout_ms):
        raise RuntimeError(f"Named pipe is not available: {path}")
    results: list[dict[str, object]] = []
    with open(path, "r+b", buffering=0) as pipe:
        for request_text in request_texts:
            pipe.write(request_text.encode("utf-8") + b"\n")
            response = read_line(pipe)
            try:
                results.append(json.loads(response))
            except json.JSONDecodeError:
                results.append({"ok": False, "raw": response, "message": "Response was not JSON."})
    return results


def command_bridge_request(args: argparse.Namespace) -> int:
    try:
        request_text = args.request
        if args.request_file:
            request_text = Path(args.request_file).read_text(encoding="utf-8")
        result = bridge_request(args.pipe_name, request_text, args.timeout_ms)
        print_json(result)
        return 0 if result.get("ok") is not False else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_probe_bridge(args: argparse.Namespace) -> int:
    args.request = '{"cmd":"hello"}'
    args.request_file = None
    return command_bridge_request(args)


def load_bridge_batch_requests(args: argparse.Namespace) -> list[str]:
    requests: list[str] = []
    for request_text in args.request or []:
        if request_text.strip():
            requests.append(request_text.strip())
    for file_name in args.request_file or []:
        for line in Path(file_name).read_text(encoding="utf-8").splitlines():
            if line.strip():
                requests.append(line.strip())
    if not requests and not sys.stdin.isatty():
        for line in sys.stdin:
            if line.strip():
                requests.append(line.strip())
    if not requests:
        raise ValueError("Provide at least one --request, --request-file JSONL line, or stdin request line.")
    return requests


def command_bridge_batch(args: argparse.Namespace) -> int:
    try:
        requests = load_bridge_batch_requests(args)
        responses = bridge_request_many(args.pipe_name, requests, args.timeout_ms)
        ok = all(response.get("ok") is not False for response in responses)
        print_json({"ok": ok, "count": len(responses), "responses": responses})
        return 0 if ok else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_bridge_window_info_request(args: argparse.Namespace) -> str:
    payload: dict[str, object] = {"cmd": "window.info", "target": args.target}
    if args.target == "handle":
        if args.handle is None:
            raise ValueError("--handle is required when --target handle is used.")
        payload["handle"] = args.handle
    elif args.target == "name":
        if not args.name:
            raise ValueError("--name is required when --target name is used.")
        payload["name"] = args.name
    return json.dumps(payload, separators=(",", ":"))


def command_bridge_window_info(args: argparse.Namespace) -> int:
    try:
        result = bridge_request(args.pipe_name, build_bridge_window_info_request(args), args.timeout_ms)
        print_json(result)
        return 0 if result.get("ok") is not False else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_bridge_form_map_request(args: argparse.Namespace) -> str:
    payload: dict[str, object] = {
        "cmd": "form.map",
        "target": args.target,
        "detail": args.detail,
        "includeAccessibility": bool(args.include_accessibility),
        "visibleOnly": not bool(args.all_controls),
    }
    if args.target == "handle":
        if args.handle is None:
            raise ValueError("--handle is required when --target handle is used.")
        payload["handle"] = args.handle
    elif args.target == "name":
        if not args.name:
            raise ValueError("--name is required when --target name is used.")
        payload["name"] = args.name
    return json.dumps(payload, separators=(",", ":"))


def command_bridge_form_map(args: argparse.Namespace) -> int:
    try:
        result = bridge_request(args.pipe_name, build_bridge_form_map_request(args), args.timeout_ms)
        print_json(result)
        return 0 if result.get("ok") is not False else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_bridge_provider_map_request(args: argparse.Namespace) -> str:
    payload: dict[str, object] = {
        "cmd": "provider.map",
        "target": args.target,
        "detail": args.detail,
        "maxDepth": args.max_depth,
        "maxChildren": args.max_children,
    }
    if args.target == "handle":
        if args.handle is None:
            raise ValueError("--handle is required when --target handle is used.")
        payload["handle"] = args.handle
    elif args.target == "name":
        if not args.name:
            raise ValueError("--name is required when --target name is used.")
        payload["name"] = args.name
    return json.dumps(payload, separators=(",", ":"))


def command_bridge_provider_map(args: argparse.Namespace) -> int:
    try:
        result = bridge_request(args.pipe_name, build_bridge_provider_map_request(args), args.timeout_ms)
        print_json(result)
        return 0 if result.get("ok") is not False else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_bridge_control_info_request(args: argparse.Namespace) -> str:
    payload: dict[str, object] = {
        "cmd": "control.info",
        "ref": args.ref,
        "detail": args.detail,
        "includeAccessibility": bool(args.include_accessibility),
    }
    return json.dumps(payload, separators=(",", ":"))


def command_bridge_control_info(args: argparse.Namespace) -> int:
    try:
        result = bridge_request(args.pipe_name, build_bridge_control_info_request(args), args.timeout_ms)
        print_json(result)
        return 0 if result.get("ok") is not False else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_bridge_controls_info_request(args: argparse.Namespace) -> str:
    refs = list(args.ref or [])
    if not refs:
        raise ValueError("Provide at least one --ref value.")
    payload: dict[str, object] = {
        "cmd": "controls.info",
        "refs": refs,
        "detail": args.detail,
        "includeAccessibility": bool(args.include_accessibility),
    }
    return json.dumps(payload, separators=(",", ":"))


def command_bridge_controls_info(args: argparse.Namespace) -> int:
    try:
        result = bridge_request(args.pipe_name, build_bridge_controls_info_request(args), args.timeout_ms)
        print_json(result)
        return 0 if result.get("ok") is not False else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_bridge_control_resolve_request(args: argparse.Namespace) -> str:
    payload: dict[str, object] = {"cmd": "control.resolve", "detail": "target"}
    if args.ref:
        payload["ref"] = args.ref
    else:
        if not args.form_name or not args.control_name:
            raise ValueError("Provide --ref or both --form-name and --control-name.")
        payload["target"] = {"formName": args.form_name, "controlName": args.control_name}
    return json.dumps(payload, separators=(",", ":"))


def concise_control_target(response: dict[str, object]) -> dict[str, object]:
    control = response.get("control")
    if not isinstance(control, dict):
        raise ValueError("Bridge response did not contain a control target.")
    target_points = control.get("targetPoints")
    center = target_points.get("center") if isinstance(target_points, dict) else None
    return {
        "snapshotId": response.get("snapshotId"),
        "ref": control.get("ref"),
        "name": control.get("name"),
        "className": control.get("className"),
        "formName": control.get("formName"),
        "formHandle": control.get("formHandle"),
        "rootHandle": control.get("rootHandle"),
        "visible": control.get("visible"),
        "enabled": control.get("enabled"),
        "formVisible": control.get("formVisible"),
        "formEnabled": control.get("formEnabled"),
        "valid": control.get("valid"),
        "targetPoint": center,
    }


def dispatch_pointer_action(
    action: str,
    point: dict[str, object],
    button: str | None,
    count: int,
    down_ms: int,
    input_guard: Callable[[], int | None] | None = None,
) -> int | None:
    x = int(point["x"])
    y = int(point["y"])
    guard_result = move_cursor(x, y, 0, input_guard)
    if guard_result is not None:
        return guard_result
    if action == "move-to-control":
        return None
    return send_mouse_click(str(button), count, down_ms, input_guard)


def command_semantic_control_action(
    args: argparse.Namespace,
    command_name: str,
    button: str | None,
    count: int,
) -> int:
    before: dict[str, object] | None = None
    action: dict[str, object] = {"name": command_name, "modalSafe": True}
    try:
        request = build_bridge_control_resolve_request(args)
        initial_response = bridge_request(args.pipe_name, request, args.timeout_ms)
        if initial_response.get("ok") is not True:
            return fail(
                str(initial_response.get("message") or "Control resolution failed."),
                2,
                reason=str(initial_response.get("errorCode") or "control-resolve-failed"),
                before=None,
                action=action,
                after={"response": initial_response},
            )
        before = concise_control_target(initial_response)
        root_handle = int(before.get("rootHandle") or 0)
        if root_handle == 0:
            return fail(
                "The resolved control has no activatable root HWND.",
                2,
                reason="missing-root-hwnd",
                before=before,
                action=action,
                after=None,
            )

        root = window_info(int_to_hwnd(root_handle))
        action["requestedRoot"] = root
        guard_result = guard_real_input(
            args,
            require_foreground=False,
            target_pid=int(root["pid"]),
            target_hwnd=root_handle,
        )
        if guard_result is not None:
            return guard_result
        activated_ok, guard_result = activate_hwnd(
            int_to_hwnd(root_handle),
            args.timeout_ms,
            lambda: guard_real_input(
                args,
                require_foreground=False,
                target_pid=int(root["pid"]),
                target_hwnd=root_handle,
            ),
        )
        if guard_result is not None:
            return guard_result
        if not activated_ok:
            return fail(
                "The target root window could not be activated. Input was not sent.",
                2,
                reason="foreground-activation-failed",
                before=before,
                action=action,
                after={"actualForeground": window_info(user32.GetForegroundWindow())},
            )
        root = window_info(int_to_hwnd(root_handle))
        action["activatedRoot"] = root

        refreshed_response = bridge_request(args.pipe_name, request, args.timeout_ms)
        if refreshed_response.get("ok") is not True:
            return fail(
                str(refreshed_response.get("message") or "Control refresh failed."),
                2,
                reason=str(refreshed_response.get("errorCode") or "control-refresh-failed"),
                before=before,
                action=action,
                after={"response": refreshed_response},
            )
        refreshed = concise_control_target(refreshed_response)
        ownership_fields = ("name", "formName", "formHandle", "rootHandle")
        if any(before.get(field) != refreshed.get(field) for field in ownership_fields):
            return fail(
                "The control changed form or root ownership after activation. Input was not sent.",
                2,
                reason="target-ownership-changed",
                before=before,
                action=action,
                after={"target": refreshed},
            )
        actionability_fields = ("visible", "enabled", "formVisible", "formEnabled", "valid")
        if not all(refreshed.get(field) is True for field in actionability_fields):
            return fail(
                "The refreshed control is not visible, enabled, and valid. Input was not sent.",
                2,
                reason="target-not-actionable",
                before=before,
                action=action,
                after={"target": refreshed},
            )
        point = refreshed.get("targetPoint")
        if not isinstance(point, dict) or "x" not in point or "y" not in point:
            return fail(
                "The refreshed control has no target point. Input was not sent.",
                2,
                reason="missing-target-point",
                before=before,
                action=action,
                after={"target": refreshed},
            )

        actual_foreground = window_info(user32.GetForegroundWindow())
        if (
            int(actual_foreground.get("hwnd") or 0) != root_handle
            or int(actual_foreground.get("pid") or 0) != int(root["pid"])
        ):
            return fail(
                "Foreground ownership changed before dispatch. Input was not sent.",
                2,
                reason="foreground-mismatch",
                before=before,
                action=action,
                after={"target": refreshed, "actualForeground": actual_foreground},
            )

        guard_result = guard_real_input(args, target_pid=int(root["pid"]), target_hwnd=root_handle)
        if guard_result is not None:
            return guard_result
        action.update({"button": button, "clickCount": count, "targetPoint": point})
        guard_result = dispatch_pointer_action(
            command_name,
            point,
            button,
            count,
            getattr(args, "down_ms", 40),
            lambda: guard_real_input(args, target_pid=int(root["pid"]), target_hwnd=root_handle),
        )
        if guard_result is not None:
            return guard_result
        print_json(
            {
                "ok": True,
                "command": command_name,
                "before": before,
                "action": action,
                "after": {
                    "target": refreshed,
                    "actualForeground": window_info(user32.GetForegroundWindow()),
                },
                **foreground_session_evidence(args),
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), 2, reason="semantic-action-failed", before=before, action=action, after=None)


def command_move_to_control(args: argparse.Namespace) -> int:
    return command_semantic_control_action(args, "move-to-control", None, 0)


def command_click_control(args: argparse.Namespace) -> int:
    return command_semantic_control_action(args, "click-control", "left", 1)


def command_double_click_control(args: argparse.Namespace) -> int:
    return command_semantic_control_action(args, "double-click-control", "left", 2)


def command_right_click_control(args: argparse.Namespace) -> int:
    return command_semantic_control_action(args, "right-click-control", "right", 1)


def requested_fields(args: argparse.Namespace) -> list[str]:
    return [field.strip() for field in str(getattr(args, "fields", "") or "").split(",") if field.strip()]


def discovery_item_matches(item: dict[str, object], args: argparse.Namespace) -> bool:
    name = getattr(args, "name", None)
    if name and str(item.get("name") or "").lower() != str(name).lower():
        return False
    caption_contains = getattr(args, "caption_contains", None)
    caption = item.get("caption", item.get("title", ""))
    if caption_contains and str(caption_contains).lower() not in str(caption or "").lower():
        return False
    class_name = getattr(args, "class_name", None)
    if class_name and str(item.get("className") or "").lower() != str(class_name).lower():
        return False
    visible = getattr(args, "visible", None)
    if visible is not None and bool(item.get("visible")) != (str(visible).lower() == "true"):
        return False
    value = getattr(args, "value", None)
    if value is not None and str(item.get("value") or "") != str(value):
        return False
    ref = getattr(args, "ref", None)
    if ref and str(item.get("ref") or "") != str(ref):
        return False
    pid = getattr(args, "pid", None)
    if pid is not None and int(item.get("pid") or 0) != int(pid):
        return False
    return True


def filter_and_project(items: list[dict[str, object]], args: argparse.Namespace) -> list[dict[str, object]]:
    fields = requested_fields(args)
    matches = [item for item in items if discovery_item_matches(item, args)]
    if not fields:
        return matches
    return [{field: item.get(field) for field in fields} for item in matches]


def bridge_request_bounded(pipe_name: str, request_text: str, timeout_ms: int) -> dict[str, object]:
    results: queue.Queue[tuple[dict[str, object] | None, BaseException | None]] = queue.Queue(maxsize=1)

    def run_request() -> None:
        try:
            results.put((bridge_request(pipe_name, request_text, timeout_ms), None))
        except BaseException as exc:  # noqa: BLE001 - passed back to the controlling CLI thread
            results.put((None, exc))

    thread = threading.Thread(target=run_request, daemon=True)
    thread.start()
    thread.join(max(1, timeout_ms) / 1000.0)
    if thread.is_alive():
        raise TimeoutError(f"Bridge request exceeded the remaining {timeout_ms} ms deadline.")
    result, error = results.get_nowait()
    if error is not None:
        raise error
    if result is None:
        raise RuntimeError("Bridge request returned no result.")
    return result


def build_bridge_target(args: argparse.Namespace) -> dict[str, object]:
    ref = getattr(args, "ref", None)
    form_name = getattr(args, "form_name", None)
    form_hwnd = getattr(args, "form_hwnd", None)
    control_name = getattr(args, "control_name", None)
    if sum(value is not None for value in (ref, form_name, form_hwnd)) != 1:
        raise ValueError("Provide exactly one of --ref, --form-name, or --form-hwnd.")
    if ref is not None:
        if not ref or control_name is not None:
            raise ValueError("--ref must be non-empty and cannot be combined with --control-name.")
        return {"ref": ref}
    if not control_name:
        raise ValueError("--control-name is required with --form-name or --form-hwnd.")
    if form_name is not None:
        if not form_name:
            raise ValueError("--form-name must be non-empty.")
        return {"target": {"formName": form_name, "controlName": control_name}}
    if not isinstance(form_hwnd, int) or isinstance(form_hwnd, bool) or form_hwnd <= 0:
        raise ValueError("--form-hwnd must be a positive integer.")
    return {"target": {"formHandle": form_hwnd, "controlName": control_name}}


def build_bridge_action_target(args: argparse.Namespace) -> dict[str, object]:
    form_name = getattr(args, "form_name", None)
    form_hwnd = getattr(args, "form_hwnd", None)
    data_module_name = getattr(args, "data_module_name", None)
    component_name = getattr(args, "component_name", None)
    if sum(value is not None for value in (form_name, form_hwnd, data_module_name)) != 1:
        raise ValueError("Provide exactly one action owner.")
    if not component_name:
        raise ValueError("--component-name is required and must be non-empty.")
    if form_name is not None:
        if not form_name:
            raise ValueError("--form-name must be non-empty.")
        return {"target": {"formName": form_name, "componentName": component_name}}
    if form_hwnd is not None:
        if not isinstance(form_hwnd, int) or isinstance(form_hwnd, bool) or form_hwnd <= 0:
            raise ValueError("--form-hwnd must be a positive integer.")
        return {"target": {"formHandle": form_hwnd, "componentName": component_name}}
    if not data_module_name:
        raise ValueError("--data-module-name must be non-empty.")
    return {"target": {"dataModuleName": data_module_name, "componentName": component_name}}


def bridge_remaining_timeout_ms(deadline: float) -> int:
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        raise TimeoutError("Bridge command exceeded its total deadline.")
    return max(1, int(remaining * 1000))


def bridge_typed_request(
    args: argparse.Namespace,
    payload: dict[str, object],
    deadline: float,
) -> dict[str, object]:
    return bridge_request_bounded(
        args.pipe_name,
        json.dumps(payload, separators=(",", ":")),
        bridge_remaining_timeout_ms(deadline),
    )


def require_bridge_v2(
    args: argparse.Namespace,
    deadline: float,
    target: dict[str, object] | None = None,
    required_capability: str | None = None,
) -> None:
    response = bridge_typed_request(args, {"cmd": "hello"}, deadline)
    version = response.get("protocolVersion")
    capabilities = response.get("capabilities")
    if response.get("ok") is not True:
        raise RuntimeError(str(response.get("message") or "Bridge hello failed."))
    if not isinstance(version, int) or isinstance(version, bool) or version < BRIDGE_PROTOCOL_VERSION:
        raise RuntimeError("Typed bridge commands require protocolVersion 2 or newer.")
    if response.get("mutationEnabled") is not True:
        raise RuntimeError("Typed bridge commands require bridge mutations to be enabled.")
    if not isinstance(capabilities, list) or "background-command-mode" not in capabilities:
        raise RuntimeError("Bridge does not advertise background-command-mode.")
    if target is not None:
        capability = "snapshot-refs-v2" if "ref" in target else "atomic-control-targets"
        if capability not in capabilities:
            raise RuntimeError(f"Bridge does not advertise {capability}.")
    if required_capability is not None and required_capability not in capabilities:
        raise RuntimeError(f"Bridge does not advertise {required_capability}.")


def require_background_response(response: dict[str, object], command: str) -> None:
    if response.get("ok") is not True:
        return
    version = response.get("protocolVersion")
    if not isinstance(version, int) or isinstance(version, bool) or version < BRIDGE_PROTOCOL_VERSION:
        raise RuntimeError("Bridge response did not retain protocolVersion 2 evidence.")
    if response.get("cmd") != command:
        raise RuntimeError(f"Bridge response command did not match {command}.")
    if response.get("driveMode") != "background-command":
        raise RuntimeError("Bridge response did not retain background-command drive-mode evidence.")


def run_typed_bridge_mutation(
    args: argparse.Namespace,
    command: str,
    values: dict[str, object] | None = None,
) -> int:
    try:
        deadline = time.monotonic() + max(args.timeout_ms, 1) / 1000.0
        target = build_bridge_target(args)
        require_bridge_v2(args, deadline, target)
        payload = {"cmd": command, **target, **(values or {})}
        response = bridge_typed_request(args, payload, deadline)
        require_background_response(response, command)
        print_json(response)
        return 0 if response.get("ok") is True else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_bridge_invoke(args: argparse.Namespace) -> int:
    operation_id: str | None = None
    last_status: str | None = None
    try:
        deadline = time.monotonic() + max(args.timeout_ms, 1) / 1000.0
        command = getattr(args, "bridge_command", "control.invoke")
        target_builder = getattr(args, "target_builder", build_bridge_target)
        target = target_builder(args)
        capability_target = target if command == "control.invoke" else None
        require_bridge_v2(args, deadline, capability_target, getattr(args, "required_capability", None))
        response = bridge_typed_request(args, {"cmd": command, **target}, deadline)
        require_background_response(response, command)
        if response.get("ok") is not True:
            print_json(response)
            return 2
        operation_id = response.get("operationId") if isinstance(response.get("operationId"), str) else None
        if not operation_id:
            raise RuntimeError("Bridge invoke response did not contain an operationId.")
        if args.async_mode:
            print_json(response)
            return 0

        last_status = str(response.get("status") or "queued")
        while True:
            status_response = bridge_typed_request(
                args,
                {"cmd": "operation.status", "operationId": operation_id, "consume": True},
                deadline,
            )
            require_background_response(status_response, "operation.status")
            if status_response.get("ok") is not True:
                print_json(status_response)
                return 2
            last_status = str(status_response.get("status") or "")
            if status_response.get("terminal") is True or last_status in ("succeeded", "failed"):
                print_json(status_response)
                return 0 if last_status == "succeeded" else 2
            time.sleep(min(BRIDGE_OPERATION_POLL_SECONDS, max(0.0, deadline - time.monotonic())))
    except TimeoutError as exc:
        return fail(
            str(exc),
            2,
            reason="timeout",
            operationId=operation_id,
            lastStatus=last_status,
            consumed=False,
            timeoutMs=args.timeout_ms,
        )
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_bridge_operation_status(args: argparse.Namespace) -> int:
    try:
        deadline = time.monotonic() + max(args.timeout_ms, 1) / 1000.0
        require_bridge_v2(args, deadline)
        response = bridge_typed_request(
            args,
            {"cmd": "operation.status", "operationId": args.operation_id, "consume": not args.no_consume},
            deadline,
        )
        require_background_response(response, "operation.status")
        print_json(response)
        if response.get("ok") is not True or response.get("status") == "failed":
            return 2
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_bridge_set_text(args: argparse.Namespace) -> int:
    return run_typed_bridge_mutation(args, "control.setText", {"text": args.text})


def command_bridge_set_checked(args: argparse.Namespace) -> int:
    return run_typed_bridge_mutation(args, "control.setChecked", {"checked": args.checked})


def command_bridge_select(args: argparse.Namespace) -> int:
    if args.index is not None:
        values = {"index": args.index}
    elif args.text is not None:
        values = {"text": args.text}
    elif args.indices is not None:
        values = {"indices": args.indices}
    elif args.texts is not None:
        values = {"texts": args.texts}
    else:
        values = {"indices": []}
    return run_typed_bridge_mutation(args, "control.select", values)


def command_bridge_focus(args: argparse.Namespace) -> int:
    return run_typed_bridge_mutation(args, "control.focus")


def command_bridge_tab(args: argparse.Namespace) -> int:
    try:
        deadline = time.monotonic() + max(args.timeout_ms, 1) / 1000.0
        require_bridge_v2(args, deadline)
        response = bridge_typed_request(args, {"cmd": "keyboard.tab", "shift": bool(args.shift)}, deadline)
        require_background_response(response, "keyboard.tab")
        print_json(response)
        return 0 if response.get("ok") is True else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_bridge_forms_response(
    args: argparse.Namespace,
    timeout_ms: int,
    bounded: bool = False,
) -> dict[str, object]:
    request = json.dumps({"cmd": "forms.list"}, separators=(",", ":"))
    request_func = bridge_request_bounded if bounded else bridge_request
    response = request_func(args.pipe_name, request, timeout_ms)
    forms = response.get("forms")
    items = [item for item in forms if isinstance(item, dict)] if isinstance(forms, list) else []
    matches = filter_and_project(items, args)
    return {
        "ok": response.get("ok") is True,
        "command": "bridge-forms",
        "count": len(matches),
        "matches": matches,
        "responseError": response.get("errorCode"),
    }


def build_bridge_find_response(
    args: argparse.Namespace,
    timeout_ms: int,
    bounded: bool = False,
) -> dict[str, object]:
    if not getattr(args, "control_name", None) and not getattr(args, "ref", None):
        return build_bridge_forms_response(args, timeout_ms, bounded)
    deadline = time.monotonic() + max(1, timeout_ms) / 1000.0
    request_func = bridge_request_bounded if bounded else bridge_request
    request = build_bridge_control_resolve_request(args)
    response = request_func(args.pipe_name, request, timeout_ms)
    control = response.get("control")
    fields = set(requested_fields(args))
    detail_fields = {"caption", "value", "hint", "accessibleName", "helpText"}
    needs_detail = getattr(args, "value", None) is not None or bool(fields & detail_fields)
    if response.get("ok") is True and isinstance(control, dict) and needs_detail:
        remaining_ms = max(0, round((deadline - time.monotonic()) * 1000))
        if remaining_ms <= 0:
            raise TimeoutError("Control detail enrichment exceeded the remaining discovery deadline.")
        detail_request = json.dumps(
            {
                "cmd": "control.info",
                "ref": control.get("ref"),
                "detail": "full",
                "includeAccessibility": False,
            },
            separators=(",", ":"),
        )
        detail_response = request_func(args.pipe_name, detail_request, remaining_ms)
        detail_control = detail_response.get("control")
        if detail_response.get("ok") is True and isinstance(detail_control, dict):
            control = {**control, **detail_control}
        else:
            response = detail_response
            control = None
    items = [control] if isinstance(control, dict) else []
    matches = filter_and_project(items, args)
    return {
        "ok": response.get("ok") is True,
        "command": "bridge-find",
        "count": len(matches),
        "matches": matches,
        "responseError": response.get("errorCode"),
    }


def build_windows_list_response(args: argparse.Namespace) -> dict[str, object]:
    items: list[dict[str, object]] = []
    for z_order, hwnd in enumerate(enum_top_windows()):
        item = window_info(hwnd)
        if not item.get("visible"):
            continue
        owner = user32.GetWindow(hwnd, GW_OWNER)
        owner_handle = hwnd_to_int(owner)
        root_owner = user32.GetAncestor(hwnd, GA_ROOTOWNER)
        root_owner_handle = hwnd_to_int(root_owner) or int(item["hwnd"])
        owner_enabled = bool(user32.IsWindowEnabled(owner)) if owner_handle else True
        item.update(
            {
                "zOrder": z_order,
                "ownerHwnd": owner_handle,
                "rootOwnerHwnd": root_owner_handle,
                "ownerEnabled": owner_enabled,
                "likelyModal": owner_handle != 0 and not owner_enabled and bool(item.get("enabled")),
            }
        )
        items.append(item)
    matches = filter_and_project(items, args)
    return {"ok": True, "command": "windows-list", "count": len(matches), "matches": matches}


def command_discovery(args: argparse.Namespace, builder) -> int:
    try:
        result = builder(args)
        print_json(result)
        return 0 if result.get("ok") is True else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), 2)


def command_bridge_forms(args: argparse.Namespace) -> int:
    return command_discovery(args, lambda value: build_bridge_forms_response(value, value.timeout_ms))


def command_bridge_find(args: argparse.Namespace) -> int:
    return command_discovery(args, lambda value: build_bridge_find_response(value, value.timeout_ms))


def command_windows_list(args: argparse.Namespace) -> int:
    return command_discovery(args, build_windows_list_response)


def poll_until_match(timeout_ms: int, poll_ms: int, lookup) -> tuple[dict[str, object], int, bool]:
    deadline = time.monotonic() + max(0, timeout_ms) / 1000.0
    attempts = 0
    final_evidence: dict[str, object] = {"ok": False, "count": 0, "matches": []}
    while True:
        remaining_ms = max(0, round((deadline - time.monotonic()) * 1000))
        if remaining_ms <= 0:
            return final_evidence, attempts, True
        attempts += 1
        try:
            final_evidence = lookup(remaining_ms)
        except Exception as exc:  # noqa: BLE001 - retained as final bounded-wait evidence
            final_evidence = {
                "ok": False,
                "count": 0,
                "matches": [],
                "error": str(exc),
                "errorType": type(exc).__name__,
            }
        if final_evidence.get("ok") is True and int(final_evidence.get("count") or 0) > 0:
            return final_evidence, attempts, False
        remaining_ms = max(0, round((deadline - time.monotonic()) * 1000))
        if remaining_ms <= 0:
            return final_evidence, attempts, True
        time.sleep(min(max(1, poll_ms), remaining_ms) / 1000.0)


def print_wait_result(
    command_name: str,
    result: dict[str, object],
    attempts: int,
    timed_out: bool,
    waited_ms: int | float,
) -> int:
    if timed_out:
        return fail(
            f"{command_name} reached its deadline without a match.",
            2,
            command=command_name,
            reason="timeout",
            attempts=attempts,
            waitedMs=round(waited_ms, 3),
            finalEvidence=result,
        )
    print_json(
        {
            "ok": True,
            "command": command_name,
            "attempts": attempts,
            "waitedMs": round(waited_ms, 3),
            "count": result.get("count"),
            "matches": result.get("matches"),
        }
    )
    return 0


def command_wait(args: argparse.Namespace, command_name: str, lookup) -> int:
    started = time.perf_counter()
    try:
        result, attempts, timed_out = poll_until_match(args.timeout_ms, args.poll_ms, lookup)
        return print_wait_result(command_name, result, attempts, timed_out, elapsed_ms_since(started))
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(
            str(exc),
            2,
            command=command_name,
            reason="wait-failed",
            waitedMs=elapsed_ms_since(started),
        )


def command_wait_window(args: argparse.Namespace) -> int:
    return command_wait(args, "wait-window", lambda _remaining: build_windows_list_response(args))


def command_wait_form(args: argparse.Namespace) -> int:
    return command_wait(
        args,
        "wait-form",
        lambda remaining: build_bridge_forms_response(args, remaining, True),
    )


def command_wait_control(args: argparse.Namespace) -> int:
    return command_wait(
        args,
        "wait-control",
        lambda remaining: build_bridge_find_response(args, remaining, True),
    )


def hwnd_to_int(hwnd: object) -> int:
    value = getattr(hwnd, "value", hwnd)
    return int(value or 0)


def int_to_hwnd(value: int) -> wintypes.HWND:
    return wintypes.HWND(int(value))


def get_window_text(hwnd: wintypes.HWND) -> str:
    length = user32.GetWindowTextLengthW(hwnd)
    if length <= 0:
        return ""
    buffer = ctypes.create_unicode_buffer(length + 1)
    user32.GetWindowTextW(hwnd, buffer, len(buffer))
    return buffer.value


def get_class_name(hwnd: wintypes.HWND) -> str:
    buffer = ctypes.create_unicode_buffer(256)
    user32.GetClassNameW(hwnd, buffer, len(buffer))
    return buffer.value


def get_window_pid_and_thread(hwnd: wintypes.HWND) -> tuple[int, int]:
    pid = wintypes.DWORD(0)
    thread_id = user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
    return int(pid.value), int(thread_id)


def get_window_rect(hwnd: wintypes.HWND) -> dict[str, int]:
    rect = RECT()
    if not user32.GetWindowRect(hwnd, ctypes.byref(rect)):
        return {"left": 0, "top": 0, "right": 0, "bottom": 0, "width": 0, "height": 0}
    return {
        "left": int(rect.left),
        "top": int(rect.top),
        "right": int(rect.right),
        "bottom": int(rect.bottom),
        "width": int(rect.right - rect.left),
        "height": int(rect.bottom - rect.top),
    }


def window_info(hwnd: wintypes.HWND, include_title: bool = True) -> dict[str, object]:
    pid, thread_id = get_window_pid_and_thread(hwnd)
    foreground = hwnd_to_int(user32.GetForegroundWindow()) == hwnd_to_int(hwnd)
    return {
        "hwnd": hwnd_to_int(hwnd),
        "pid": pid,
        "threadId": thread_id,
        "title": get_window_text(hwnd) if include_title else "",
        "className": get_class_name(hwnd),
        "visible": bool(user32.IsWindowVisible(hwnd)),
        "enabled": bool(user32.IsWindowEnabled(hwnd)),
        "foreground": foreground,
        "rect": get_window_rect(hwnd),
    }


def enum_top_windows() -> list[wintypes.HWND]:
    windows: list[wintypes.HWND] = []

    @EnumWindowsProc
    def callback(hwnd: wintypes.HWND, _lparam: wintypes.LPARAM) -> bool:
        windows.append(hwnd)
        return True

    if not user32.EnumWindows(callback, 0):
        raise OSError(f"EnumWindows failed: {ctypes.get_last_error()}")
    return windows


def matching_windows(pid: int | None, title_contains: str | None, include_title: bool = True) -> list[dict[str, object]]:
    title_filter = (title_contains or "").lower()
    result: list[dict[str, object]] = []
    for hwnd in enum_top_windows():
        item = window_info(hwnd, include_title or bool(title_filter))
        if not item["visible"]:
            continue
        if pid is not None and item["pid"] != pid:
            continue
        if title_filter and title_filter not in str(item["title"]).lower():
            continue
        result.append(item)
    result.sort(key=lambda item: (not bool(item["title"]), -int(item["rect"]["width"]) * int(item["rect"]["height"])))
    return result


def resolve_target_window(args: argparse.Namespace, include_title: bool = True) -> tuple[dict[str, object], list[dict[str, object]]]:
    if args.hwnd is None and args.pid is None and not args.title_contains:
        raise ValueError("Provide --hwnd, --pid, or --title-contains.")
    if args.hwnd is not None:
        target = window_info(int_to_hwnd(args.hwnd), include_title or bool(args.title_contains))
        return target, [target]
    matches = matching_windows(args.pid, args.title_contains, include_title)
    if not matches:
        raise LookupError("No matching visible top-level window was found.")
    return matches[0], matches


def target_or_foreground_window(
    args: argparse.Namespace,
    include_title: bool = True,
) -> tuple[dict[str, object], list[dict[str, object]]]:
    if getattr(args, "focused", False) or (
        getattr(args, "hwnd", None) is None
        and getattr(args, "pid", None) is None
        and not getattr(args, "title_contains", None)
    ):
        hwnd = user32.GetForegroundWindow()
        target = window_info(hwnd, include_title)
        return target, [target]
    return resolve_target_window(args, include_title)


def hwnd_child_windows(hwnd: wintypes.HWND, max_count: int | None = None) -> list[wintypes.HWND]:
    result: list[wintypes.HWND] = []
    child = user32.GetWindow(hwnd, GW_CHILD)
    seen: set[int] = set()
    while hwnd_to_int(child):
        value = hwnd_to_int(child)
        if value in seen:
            break
        seen.add(value)
        result.append(child)
        if max_count is not None and len(result) >= max_count:
            break
        child = user32.GetWindow(child, GW_HWNDNEXT)
    return result


def point_center(rect: dict[str, int]) -> dict[str, int]:
    return {
        "x": int(rect["left"] + rect["width"] // 2),
        "y": int(rect["top"] + rect["height"] // 2),
    }


def hwnd_map_node(
    hwnd: wintypes.HWND,
    depth: int,
    max_depth: int,
    max_children: int,
    seen: set[int],
    include_title: bool = True,
) -> tuple[dict[str, object], int]:
    hwnd_value = hwnd_to_int(hwnd)
    if hwnd_value in seen:
        return {"hwnd": hwnd_value, "depth": depth, "cycle": True, "children": []}, 0
    seen.add(hwnd_value)

    pid, thread_id = get_window_pid_and_thread(hwnd)
    rect = get_window_rect(hwnd)
    item: dict[str, object] = {
        "hwnd": hwnd_value,
        "depth": depth,
        "pid": pid,
        "threadId": thread_id,
        "className": get_class_name(hwnd),
        "visible": bool(user32.IsWindowVisible(hwnd)),
        "enabled": bool(user32.IsWindowEnabled(hwnd)),
        "rect": rect,
        "targetPoints": {"center": point_center(rect)},
        "children": [],
    }
    if include_title:
        item["title"] = get_window_text(hwnd)

    count = 1
    if depth < max_depth:
        children: list[dict[str, object]] = []
        for child in hwnd_child_windows(hwnd, max_children):
            child_item, child_count = hwnd_map_node(child, depth + 1, max_depth, max_children, seen, include_title)
            children.append(child_item)
            count += child_count
        item["children"] = children
    return item, count


def build_win32_map_response(args: argparse.Namespace) -> dict[str, object]:
    detail = getattr(args, "detail", "full")
    include_title = detail != "geometry"
    target, matches = target_or_foreground_window(args, include_title)
    root, count = hwnd_map_node(
        int_to_hwnd(int(target["hwnd"])),
        0,
        max(0, int(args.max_depth)),
        max(1, int(args.max_children)),
        set(),
        include_title,
    )
    return {
        "ok": True,
        "source": "win32",
        "detail": detail,
        "target": target,
        "nodeCount": count,
        "root": root,
        "matches": matches[:5],
    }


def command_win32_map(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    try:
        result = build_win32_map_response(args)
        result["elapsedMs"] = elapsed_ms_since(started)
        print_json(result)
        return 0
    except LookupError as exc:
        return fail(str(exc), pid=args.pid, titleContains=args.title_contains)
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def build_fast_map_bridge_request(args: argparse.Namespace) -> str:
    validate_fast_map_target(args)
    payload: dict[str, object] = {
        "cmd": "form.map",
        "target": args.target,
        "detail": getattr(args, "detail", "geometry"),
        "includeAccessibility": False,
        "visibleOnly": True,
    }
    if args.target == "handle":
        if args.handle is None:
            raise ValueError("--handle is required when --target handle is used.")
        payload["handle"] = args.handle
    elif args.target == "name":
        if not args.name:
            raise ValueError("--name is required when --target name is used.")
        payload["name"] = args.name
    return json.dumps(payload, separators=(",", ":"))


def default_bridge_pipe_name_for_pid(pid: int | None) -> str | None:
    if pid is None or pid <= 0:
        return None
    return f"MaxLogicAccessibilityAgentBridge.{pid}"


def fast_map_bridge_args_for_handle(args: argparse.Namespace, hwnd: int) -> argparse.Namespace:
    return argparse.Namespace(
        target="handle",
        handle=hwnd,
        name=None,
        pid=getattr(args, "pid", None),
        title_contains=getattr(args, "title_contains", None),
        max_depth=getattr(args, "max_depth", 4),
        max_children=getattr(args, "max_children", 200),
        timeout_ms=getattr(args, "timeout_ms", 5000),
        detail=getattr(args, "detail", "geometry"),
    )


def default_bridge_target_for_fast_map(args: argparse.Namespace) -> tuple[str | None, argparse.Namespace]:
    if args.pid is not None:
        matches = matching_windows(args.pid, args.title_contains, include_title=bool(args.title_contains))
        if matches:
            hwnd = int(matches[0]["hwnd"])
            return default_bridge_pipe_name_for_pid(args.pid), fast_map_bridge_args_for_handle(args, hwnd)
        return default_bridge_pipe_name_for_pid(args.pid), args

    if args.target == "handle" and args.handle is not None:
        pid, _thread_id = get_window_pid_and_thread(int_to_hwnd(args.handle))
        return default_bridge_pipe_name_for_pid(pid), args

    if args.target == "focused" and not args.title_contains:
        hwnd = hwnd_to_int(user32.GetForegroundWindow())
        if hwnd:
            pid, _thread_id = get_window_pid_and_thread(int_to_hwnd(hwnd))
            return default_bridge_pipe_name_for_pid(pid), fast_map_bridge_args_for_handle(args, hwnd)

    if args.title_contains:
        matches = matching_windows(None, args.title_contains, include_title=True)
        if matches:
            hwnd = int(matches[0]["hwnd"])
            return default_bridge_pipe_name_for_pid(int(matches[0]["pid"])), fast_map_bridge_args_for_handle(args, hwnd)

    return None, args


def default_bridge_target_for_fast_semantic_map(args: argparse.Namespace) -> tuple[str | None, argparse.Namespace]:
    if (
        args.pid is not None
        and not args.title_contains
        and args.target == "focused"
        and args.handle is None
        and not args.name
    ):
        return default_bridge_pipe_name_for_pid(args.pid), args

    return default_bridge_target_for_fast_map(args)


def validate_fast_map_target(args: argparse.Namespace) -> None:
    if args.target == "handle" and args.handle is None:
        raise ValueError("--handle is required when --target handle is used.")
    if args.target == "name" and not args.name:
        raise ValueError("--name is required when --target name is used.")


def build_fast_map_win32_args(args: argparse.Namespace) -> argparse.Namespace:
    validate_fast_map_target(args)
    hwnd = args.handle if args.target == "handle" else None
    title_contains = args.title_contains
    if args.target == "name" and args.name and not title_contains:
        title_contains = args.name
    focused = args.target == "focused" and hwnd is None and args.pid is None and not title_contains
    return argparse.Namespace(
        focused=focused,
        hwnd=hwnd,
        pid=args.pid,
        title_contains=title_contains,
        max_depth=args.max_depth,
        max_children=args.max_children,
        detail=getattr(args, "detail", "geometry"),
    )


def command_fast_map(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    attempts: list[dict[str, object]] = []
    try:
        validate_fast_map_target(args)
    except ValueError as exc:
        return fail(str(exc))

    auto_bridge_probe = args.pipe_name is None
    bridge_args = args
    if args.pipe_name:
        bridge_pipe_name = args.pipe_name
    else:
        bridge_pipe_name, bridge_args = default_bridge_target_for_fast_map(args)

    if bridge_pipe_name:
        try:
            bridge_timeout_ms = (
                min(args.timeout_ms, AUTO_BRIDGE_PROBE_TIMEOUT_MS)
                if auto_bridge_probe
                else args.timeout_ms
            )
            result = bridge_request(bridge_pipe_name, build_fast_map_bridge_request(bridge_args), bridge_timeout_ms)
            if result.get("ok") is not False:
                result = dict(result)
                if "elapsedMs" in result:
                    result["bridgeElapsedMs"] = result["elapsedMs"]
                if "elapsedTicks" in result:
                    result["bridgeElapsedTicks"] = result["elapsedTicks"]
                result["mapSource"] = "maxlogic-bridge"
                result["elapsedMs"] = elapsed_ms_since(started)
                print_json(result)
                return 0
            attempts.append({"source": "maxlogic-bridge", "ok": False, "response": result})
        except Exception as exc:  # noqa: BLE001 - fallback boundary
            attempts.append({"source": "maxlogic-bridge", "pipeName": bridge_pipe_name, "ok": False, "error": str(exc)})

    try:
        result = build_win32_map_response(build_fast_map_win32_args(args))
        result["mapSource"] = "win32"
        result["elapsedMs"] = elapsed_ms_since(started)
        if attempts:
            result["fallbackAttempts"] = attempts
        print_json(result)
        return 0
    except LookupError as exc:
        return fail(str(exc), attempts=attempts, pid=args.pid, titleContains=args.title_contains)
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), attempts=attempts)


def build_fast_semantic_uia_args(
    args: argparse.Namespace,
    fallback_attempts: list[dict[str, object]] | None = None,
) -> argparse.Namespace:
    title_contains = getattr(args, "title_contains", None)
    hwnd = None
    pid = getattr(args, "pid", None)
    focused = False

    if args.target == "handle":
        hwnd = args.handle
    elif args.target == "name":
        title_contains = title_contains or args.name
    elif pid is None and not title_contains:
        focused = True

    return argparse.Namespace(
        focused=focused,
        hwnd=hwnd,
        pid=pid,
        title_contains=title_contains,
        max_depth=getattr(args, "max_depth", 3),
        max_children=getattr(args, "max_children", 200),
        detail=getattr(args, "detail", "full"),
        cache=True,
        plain=False,
        timeout_ms=getattr(args, "timeout_ms", 10000),
        fallback_attempts=fallback_attempts or [],
    )


def command_fast_semantic_map(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    attempts: list[dict[str, object]] = []
    try:
        validate_fast_map_target(args)
    except ValueError as exc:
        return fail(str(exc))

    auto_bridge_probe = args.pipe_name is None
    bridge_args = args
    if args.pipe_name:
        bridge_pipe_name = args.pipe_name
    else:
        bridge_pipe_name, bridge_args = default_bridge_target_for_fast_semantic_map(args)

    if bridge_pipe_name:
        try:
            bridge_timeout_ms = (
                min(args.timeout_ms, AUTO_SEMANTIC_BRIDGE_PROBE_TIMEOUT_MS)
                if auto_bridge_probe
                else args.timeout_ms
            )
            result = bridge_request(bridge_pipe_name, build_bridge_provider_map_request(bridge_args), bridge_timeout_ms)
            if result.get("ok") is not False:
                result = dict(result)
                if "elapsedMs" in result:
                    result["bridgeElapsedMs"] = result["elapsedMs"]
                if "elapsedTicks" in result:
                    result["bridgeElapsedTicks"] = result["elapsedTicks"]
                result["mapSource"] = "maxlogic-provider"
                result["semanticBypass"] = True
                result["elapsedMs"] = elapsed_ms_since(started)
                print_json(result)
                return 0
            attempts.append({"source": "maxlogic-provider", "ok": False, "response": result})
        except Exception as exc:  # noqa: BLE001 - fallback boundary
            attempts.append({"source": "maxlogic-provider", "pipeName": bridge_pipe_name, "ok": False, "error": str(exc)})

    return command_uia_cache_map(build_fast_semantic_uia_args(args, attempts))


def activate_hwnd(
    hwnd: wintypes.HWND,
    timeout_ms: int,
    activation_guard: Callable[[], int | None] | None = None,
) -> tuple[bool, int | None]:
    deadline = time.monotonic() + max(timeout_ms, 1) / 1000.0
    current_thread_id = int(kernel32.GetCurrentThreadId())
    while time.monotonic() <= deadline:
        guard_result = activation_guard() if activation_guard is not None else None
        if guard_result is not None:
            return False, guard_result
        foreground_hwnd = user32.GetForegroundWindow()
        _, foreground_thread_id = get_window_pid_and_thread(foreground_hwnd)
        _, target_thread_id = get_window_pid_and_thread(hwnd)
        attached: list[int] = []
        try:
            for thread_id in {foreground_thread_id, target_thread_id}:
                if thread_id and thread_id != current_thread_id:
                    if user32.AttachThreadInput(current_thread_id, thread_id, True):
                        attached.append(thread_id)
            user32.ShowWindow(hwnd, SW_RESTORE)
            user32.BringWindowToTop(hwnd)
            user32.SetForegroundWindow(hwnd)
            if hasattr(user32, "SwitchToThisWindow"):
                user32.SwitchToThisWindow(hwnd, True)
        finally:
            for thread_id in attached:
                user32.AttachThreadInput(current_thread_id, thread_id, False)
        if hwnd_to_int(user32.GetForegroundWindow()) == hwnd_to_int(hwnd):
            return True, None
        time.sleep(0.05)
    return False, None


def command_foreground_window(_args: argparse.Namespace) -> int:
    hwnd = user32.GetForegroundWindow()
    print_json({"ok": hwnd_to_int(hwnd) != 0, "window": window_info(hwnd)})
    return 0


def activatable_root(hwnd: wintypes.HWND) -> wintypes.HWND:
    root = user32.GetAncestor(hwnd, GA_ROOT)
    return root if hwnd_to_int(root) else hwnd


def command_activate_window(args: argparse.Namespace) -> int:
    try:
        target, matches = resolve_target_window(args)
        requested_hwnd = int_to_hwnd(int(target["hwnd"]))
        activated_hwnd = activatable_root(requested_hwnd)
        activated = window_info(activated_hwnd)
        guard_result = guard_real_input(
            args,
            require_foreground=False,
            target_pid=int(activated["pid"]),
            target_hwnd=hwnd_to_int(activated_hwnd),
        )
        if guard_result is not None:
            return guard_result
        ok, guard_result = activate_hwnd(
            activated_hwnd,
            args.timeout_ms,
            lambda: guard_real_input(
                args,
                require_foreground=False,
                target_pid=int(activated["pid"]),
                target_hwnd=hwnd_to_int(activated_hwnd),
            ),
        )
        if guard_result is not None:
            return guard_result
        if ok:
            guard_result = guard_real_input(
                args,
                target_pid=int(activated["pid"]),
                target_hwnd=hwnd_to_int(activated_hwnd),
            )
            if guard_result is not None:
                return guard_result
        payload = {
            "ok": ok,
            "action": "activate-window",
            "target": target,
            "requested": target,
            "activated": activated,
            "resolvedToRoot": hwnd_to_int(requested_hwnd) != hwnd_to_int(activated_hwnd),
            "reason": None if ok else "foreground-activation-failed",
            "foreground": window_info(user32.GetForegroundWindow()),
            "matches": matches[:5],
            **foreground_session_evidence(args),
        }
        print_json(payload)
        return 0 if ok else 2
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def write_bitmap(path: Path, width: int, height: int, pixels: bytes) -> None:
    image_size = len(pixels)
    file_header_size = 14
    dib_header_size = 40
    offset = file_header_size + dib_header_size
    file_size = offset + image_size
    with path.open("wb") as handle:
        handle.write(struct.pack("<2sIHHI", b"BM", file_size, 0, 0, offset))
        handle.write(struct.pack("<IiiHHIIiiII", dib_header_size, width, -height, 1, 32, 0, image_size, 0, 0, 0, 0))
        handle.write(pixels)


def capture_window_bitmap(hwnd: wintypes.HWND, output_path: Path) -> dict[str, object]:
    rect = get_window_rect(hwnd)
    width = int(rect["width"])
    height = int(rect["height"])
    if width <= 0 or height <= 0:
        raise ValueError("Window has no capturable area.")

    source_dc = user32.GetWindowDC(hwnd)
    if not source_dc:
        raise OSError(f"GetWindowDC failed: {ctypes.get_last_error()}")
    memory_dc = 0
    bitmap = 0
    old_bitmap = 0
    try:
        memory_dc = gdi32.CreateCompatibleDC(source_dc)
        if not memory_dc:
            raise OSError(f"CreateCompatibleDC failed: {ctypes.get_last_error()}")
        bitmap = gdi32.CreateCompatibleBitmap(source_dc, width, height)
        if not bitmap:
            raise OSError(f"CreateCompatibleBitmap failed: {ctypes.get_last_error()}")
        old_bitmap = gdi32.SelectObject(memory_dc, bitmap)
        method = "PrintWindow"
        if not user32.PrintWindow(hwnd, memory_dc, PW_RENDERFULLCONTENT):
            method = "BitBlt"
            if not gdi32.BitBlt(memory_dc, 0, 0, width, height, source_dc, 0, 0, SRCCOPY):
                raise OSError(f"BitBlt failed: {ctypes.get_last_error()}")

        info = BITMAPINFO()
        info.bmiHeader.biSize = ctypes.sizeof(BITMAPINFOHEADER)
        info.bmiHeader.biWidth = width
        info.bmiHeader.biHeight = -height
        info.bmiHeader.biPlanes = 1
        info.bmiHeader.biBitCount = 32
        image_size = width * height * 4
        buffer = ctypes.create_string_buffer(image_size)
        scan_lines = gdi32.GetDIBits(memory_dc, bitmap, 0, height, buffer, ctypes.byref(info), 0)
        if scan_lines != height:
            raise OSError(f"GetDIBits failed: {ctypes.get_last_error()}")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        write_bitmap(output_path, width, height, buffer.raw)
        return {"method": method, "width": width, "height": height, "bytes": output_path.stat().st_size}
    finally:
        if old_bitmap:
            gdi32.SelectObject(memory_dc, old_bitmap)
        if bitmap:
            gdi32.DeleteObject(bitmap)
        if memory_dc:
            gdi32.DeleteDC(memory_dc)
        user32.ReleaseDC(hwnd, source_dc)


def command_screenshot_window(args: argparse.Namespace) -> int:
    try:
        target, matches = resolve_target_window(args)
        output_path = Path(args.output).resolve()
        capture = capture_window_bitmap(int_to_hwnd(int(target["hwnd"])), output_path)
        print_json(
            {
                "ok": True,
                "action": "screenshot-window",
                "path": str(output_path),
                "window": target,
                "capture": capture,
                "matches": matches[:5],
            }
        )
        return 0
    except LookupError as exc:
        return fail(str(exc), pid=args.pid, titleContains=args.title_contains)
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def guard_real_input(
    args: argparse.Namespace,
    *,
    require_foreground: bool = True,
    target_pid: int | None = None,
    target_hwnd: int | None = None,
) -> int | None:
    asserted_pid = getattr(args, "require_foreground_pid", None)
    asserted_hwnd = getattr(args, "require_foreground_hwnd", None)
    session_id = getattr(args, "session_id", None)
    if not session_id:
        return fail("A foreground session is required. Input was not sent.", 2, reason="session-required")
    session = read_session(session_state_path(args))
    if session is None:
        return fail("No foreground session is active. Input was not sent.", 2, reason="session-absent")
    if session.get("sessionId") != session_id:
        return fail("The foreground session ID does not match. Input was not sent.", 2, reason="session-mismatch")
    if int(session.get("expiresAtMs") or 0) <= epoch_ms():
        return fail("The foreground session has expired. Input was not sent.", 2, reason="session-expired")
    if not process_alive(int(session.get("controllerPid") or 0)):
        return fail("The foreground session controller has exited. Input was not sent.", 2, reason="session-controller-exited")
    session_pid = int(session.get("targetPid") or 0)
    session_hwnd = int(session.get("targetHwnd") or 0)
    for required_pid in (asserted_pid, target_pid):
        if required_pid is not None and required_pid != session_pid:
            return fail("The required PID does not match the foreground session. Input was not sent.", 2, reason="session-pid-mismatch")
    for required_hwnd in (asserted_hwnd, target_hwnd):
        if required_hwnd is not None and session_hwnd > 0 and required_hwnd != session_hwnd:
            return fail("The required HWND does not match the foreground session. Input was not sent.", 2, reason="session-hwnd-mismatch")
    args._active_foreground_session = {
        "sessionId": session["sessionId"],
        "targetPid": session["targetPid"],
        "targetHwnd": session["targetHwnd"],
        "expiresAtMs": session["expiresAtMs"],
    }
    if not require_foreground:
        return None

    required_pid = target_pid if target_pid is not None else session_pid
    required_hwnd = target_hwnd if target_hwnd is not None else asserted_hwnd
    if required_hwnd is None and session_hwnd > 0:
        required_hwnd = session_hwnd
    actual = window_info(user32.GetForegroundWindow())
    if (
        (required_pid is not None and int(actual["pid"]) != required_pid)
        or (required_hwnd is not None and int(actual["hwnd"]) != required_hwnd)
    ):
        return fail(
            "Foreground requirement was not satisfied. Input was not sent.",
            2,
            reason="foreground-mismatch",
            requiredForegroundPid=required_pid,
            requiredForegroundHwnd=required_hwnd,
            actualForeground=actual,
            sessionId=session_id,
        )
    return None


def foreground_session_evidence(args: argparse.Namespace) -> dict[str, object]:
    session = getattr(args, "_active_foreground_session", None)
    return {"driveMode": "foreground-input", "foregroundSession": session} if session is not None else {}


def move_cursor(
    x: int,
    y: int,
    duration_ms: int,
    input_guard: Callable[[], int | None] | None = None,
) -> int | None:
    duration_ms = max(0, duration_ms)
    if duration_ms == 0:
        guard_result = input_guard() if input_guard is not None else None
        if guard_result is not None:
            return guard_result
        if not user32.SetCursorPos(x, y):
            raise OSError(f"SetCursorPos failed: {ctypes.get_last_error()}")
        return None

    start = POINT()
    if not user32.GetCursorPos(ctypes.byref(start)):
        raise OSError(f"GetCursorPos failed: {ctypes.get_last_error()}")
    steps = max(2, min(120, duration_ms // 16))
    delay = duration_ms / (steps - 1) / 1000.0
    for step in range(steps):
        guard_result = input_guard() if input_guard is not None else None
        if guard_result is not None:
            return guard_result
        next_x = round(start.x + ((x - start.x) * step / (steps - 1)))
        next_y = round(start.y + ((y - start.y) * step / (steps - 1)))
        if not user32.SetCursorPos(next_x, next_y):
            raise OSError(f"SetCursorPos failed: {ctypes.get_last_error()}")
        if step < steps - 1:
            time.sleep(delay)
    return None


def send_mouse_click(
    button: str,
    count: int,
    down_ms: int,
    input_guard: Callable[[], int | None] | None = None,
) -> int | None:
    flags = {
        "left": (MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP),
        "right": (MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP),
        "middle": (MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_MIDDLEUP),
    }
    if button not in flags:
        raise ValueError(f"Unsupported mouse button: {button}")
    if count not in (1, 2):
        raise ValueError("Mouse click count must be 1 or 2.")
    down_flag, up_flag = flags[button]
    for _index in range(count):
        guard_result = input_guard() if input_guard is not None else None
        if guard_result is not None:
            return guard_result
        try:
            user32.mouse_event(down_flag, 0, 0, 0, 0)
            time.sleep(max(0, down_ms) / 1000.0)
        finally:
            user32.mouse_event(up_flag, 0, 0, 0, 0)
    return None


def command_move(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        duration_ms = getattr(args, "duration_ms", 0)
        guard_result = move_cursor(int(args.x), int(args.y), duration_ms, lambda: guard_real_input(args))
        if guard_result is not None:
            return guard_result
        print_json(
            {
                "ok": True,
                "action": "move",
                "x": args.x,
                "y": args.y,
                "durationMs": duration_ms,
                **foreground_session_evidence(args),
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_click(args: argparse.Namespace) -> int:
    if (args.x is None) != (args.y is None):
        return fail("Provide both --x and --y, or neither.")
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        if args.x is not None and args.y is not None:
            guard_result = move_cursor(
                int(args.x),
                int(args.y),
                getattr(args, "duration_ms", 0),
                lambda: guard_real_input(args),
            )
            if guard_result is not None:
                return guard_result
        button = getattr(args, "button", "left")
        count = getattr(args, "count", 1)
        guard_result = send_mouse_click(button, count, args.down_ms, lambda: guard_real_input(args))
        if guard_result is not None:
            return guard_result
        action = getattr(args, "action_name", "click")
        print_json(
            {
                "ok": True,
                "action": action,
                "x": args.x,
                "y": args.y,
                "button": button,
                "count": count,
                **foreground_session_evidence(args),
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_double_click(args: argparse.Namespace) -> int:
    args.count = 2
    args.action_name = "double-click"
    return command_click(args)


def key_flags_for_vk(vk: int, key_up: bool = False) -> int:
    flags = KEYEVENTF_EXTENDEDKEY if vk in EXTENDED_VK_CODES else 0
    if key_up:
        flags |= KEYEVENTF_KEYUP
    return flags


def send_key_input(vk: int, key_up: bool = False) -> None:
    flags = key_flags_for_vk(vk, key_up)
    item = INPUT(type=1, union=INPUTUNION(ki=KEYBDINPUT(vk, 0, flags, 0, 0)))
    sent = user32.SendInput(1, ctypes.byref(item), ctypes.sizeof(item))
    if sent != 1:
        raise OSError(f"SendInput failed: {ctypes.get_last_error()}")


def send_unicode_unit(unit: int, key_up: bool = False) -> None:
    flags = KEYEVENTF_UNICODE | (KEYEVENTF_KEYUP if key_up else 0)
    item = INPUT(type=1, union=INPUTUNION(ki=KEYBDINPUT(0, unit, flags, 0, 0)))
    sent = user32.SendInput(1, ctypes.byref(item), ctypes.sizeof(item))
    if sent != 1:
        raise OSError(f"SendInput failed: {ctypes.get_last_error()}")


def virtual_key_for_name(name: str) -> int:
    normalized = name.strip().lower()
    if normalized in VK_CODES:
        return VK_CODES[normalized]
    if len(normalized) == 1 and normalized.isalnum():
        return ord(normalized.upper())
    raise ValueError(f"Unsupported key: {name}")


def parse_key_chord(chord: str) -> list[int]:
    names = [name.strip() for name in chord.split("+") if name.strip()]
    if not names:
        raise ValueError("Key chord must not be empty.")
    return [virtual_key_for_name(name) for name in names]


def send_key_chord(
    keys: list[int],
    down_ms: int,
    input_guard: Callable[[], int | None] | None = None,
) -> int | None:
    pressed: list[int] = []
    error: BaseException | None = None
    guard_result: int | None = None
    try:
        for vk in keys:
            guard_result = input_guard() if input_guard is not None else None
            if guard_result is not None:
                break
            pressed.append(vk)
            send_key_input(vk, False)
        if guard_result is None:
            time.sleep(max(0, down_ms) / 1000.0)
    except BaseException as exc:  # noqa: BLE001 - all pressed modifiers must still be released
        error = exc
    finally:
        for vk in reversed(pressed):
            try:
                send_key_input(vk, True)
            except BaseException as exc:  # noqa: BLE001 - release every remaining key before reporting
                if error is None:
                    error = exc
    if error is not None:
        raise error
    return guard_result


def type_unicode_text(
    text: str,
    delay_ms: int,
    input_guard: Callable[[], int | None] | None = None,
) -> int | None:
    raw = text.encode("utf-16-le")
    units = [raw[index] | (raw[index + 1] << 8) for index in range(0, len(raw), 2)]
    for unit in units:
        guard_result = input_guard() if input_guard is not None else None
        if guard_result is not None:
            return guard_result
        try:
            send_unicode_unit(unit, False)
        finally:
            send_unicode_unit(unit, True)
        if delay_ms > 0:
            time.sleep(delay_ms / 1000.0)
    return None


def command_press(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        key = args.key.lower()
        guard_result = send_key_chord([virtual_key_for_name(key)], args.down_ms, lambda: guard_real_input(args))
        if guard_result is not None:
            return guard_result
        print_json({"ok": True, "action": "press", "key": key, **foreground_session_evidence(args)})
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_tab(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        keys = [VK_CODES["shift"], VK_CODES["tab"]] if args.shift else [VK_CODES["tab"]]
        guard_result = send_key_chord(keys, 0, lambda: guard_real_input(args))
        if guard_result is not None:
            return guard_result
        print_json({"ok": True, "action": "tab", "shift": args.shift, **foreground_session_evidence(args)})
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_type_text(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        guard_result = type_unicode_text(args.text, args.delay_ms, lambda: guard_real_input(args))
        if guard_result is not None:
            return guard_result
        print_json(
            {"ok": True, "action": "type-text", "length": len(args.text), **foreground_session_evidence(args)}
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_key_chord(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        keys = parse_key_chord(args.keys)
        guard_result = send_key_chord(keys, args.down_ms, lambda: guard_real_input(args))
        if guard_result is not None:
            return guard_result
        print_json(
            {
                "ok": True,
                "action": "key-chord",
                "keys": args.keys,
                "humanEquivalent": True,
                "userInputEventsGenerated": True,
                **foreground_session_evidence(args),
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_clear_and_type(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        guard = lambda: guard_real_input(args)
        guard_result = send_key_chord(parse_key_chord("Ctrl+A"), args.down_ms, guard)
        if guard_result is not None:
            return guard_result
        if args.text:
            guard_result = type_unicode_text(args.text, args.delay_ms, guard)
        else:
            guard_result = send_key_chord([VK_CODES["backspace"]], args.down_ms, guard)
        if guard_result is not None:
            return guard_result
        print_json(
            {
                "ok": True,
                "action": "clear-and-type",
                "length": len(args.text),
                "mutationSemantics": "os-keyboard-input",
                "humanEquivalent": True,
                "userInputEventsGenerated": True,
                **foreground_session_evidence(args),
            }
        )
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def rect_to_dict(rect: object) -> dict[str, int]:
    return {
        "left": int(rect.left),
        "top": int(rect.top),
        "right": int(rect.right),
        "bottom": int(rect.bottom),
        "width": int(rect.right - rect.left),
        "height": int(rect.bottom - rect.top),
    }


def capped_uia_children(control: object, max_children: int) -> tuple[list[object], int, bool]:
    limit = max(0, int(max_children))
    first_child = getattr(control, "GetFirstChildControl", None)
    if callable(first_child):
        try:
            child = first_child()
        except Exception:
            child = None
        children: list[object] = []
        seen = 0
        while child is not None:
            seen += 1
            if seen <= limit:
                children.append(child)
            if seen > limit:
                break

            next_sibling = getattr(child, "GetNextSiblingControl", None)
            if not callable(next_sibling):
                break
            try:
                child = next_sibling()
            except Exception:
                child = None
        return children, seen, seen > limit

    try:
        children = control.GetChildren()
    except Exception:
        children = []
    return children[:limit], len(children), len(children) > limit


def control_to_dict(
    control: object,
    depth: int,
    max_depth: int,
    max_children: int,
    detail: str = "full",
) -> dict[str, object]:
    item: dict[str, object] = {
        "rect": rect_to_dict(getattr(control, "BoundingRectangle")),
        "children": [],
    }
    if detail != "geometry":
        item.update(
            {
                "name": getattr(control, "Name", ""),
                "automationId": getattr(control, "AutomationId", ""),
                "className": getattr(control, "ClassName", ""),
                "controlType": getattr(control, "ControlTypeName", ""),
                "focused": bool(getattr(control, "HasKeyboardFocus", False)),
                "enabled": bool(getattr(control, "IsEnabled", False)),
            }
        )
    if depth >= max_depth:
        return item
    children, child_count, children_truncated = capped_uia_children(control, max_children)
    item["childCount"] = child_count
    item["childrenTruncated"] = children_truncated
    item["children"] = [
        control_to_dict(child, depth + 1, max_depth, max_children, detail)
        for child in children
    ]
    return item


def ps_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def build_uia_cache_map_script(
    hwnd: int,
    focused: bool,
    max_depth: int,
    max_children: int,
    detail: str,
) -> str:
    property_adds = [
        "$lRequest.Add([System.Windows.Automation.AutomationElement]::BoundingRectangleProperty)"
    ]
    semantic_fields = ""
    if detail != "geometry":
        property_adds.extend(
            [
                "$lRequest.Add([System.Windows.Automation.AutomationElement]::NameProperty)",
                "$lRequest.Add([System.Windows.Automation.AutomationElement]::AutomationIdProperty)",
                "$lRequest.Add([System.Windows.Automation.AutomationElement]::ClassNameProperty)",
                "$lRequest.Add([System.Windows.Automation.AutomationElement]::ControlTypeProperty)",
                "$lRequest.Add([System.Windows.Automation.AutomationElement]::HasKeyboardFocusProperty)",
                "$lRequest.Add([System.Windows.Automation.AutomationElement]::IsEnabledProperty)",
            ]
        )
        semantic_fields = """
    $lItem.name = [string](Get-CachedValue $aElement ([System.Windows.Automation.AutomationElement]::NameProperty))
    $lItem.automationId = [string](Get-CachedValue $aElement ([System.Windows.Automation.AutomationElement]::AutomationIdProperty))
    $lItem.className = [string](Get-CachedValue $aElement ([System.Windows.Automation.AutomationElement]::ClassNameProperty))
    $lItem.controlType = Convert-ControlType (Get-CachedValue $aElement ([System.Windows.Automation.AutomationElement]::ControlTypeProperty))
    $lItem.focused = [bool](Get-CachedBool $aElement ([System.Windows.Automation.AutomationElement]::HasKeyboardFocusProperty))
    $lItem.enabled = [bool](Get-CachedBool $aElement ([System.Windows.Automation.AutomationElement]::IsEnabledProperty))
"""

    focused_literal = "$true" if focused else "$false"
    return f"""
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
$lHwnd = [Int64]{int(hwnd)}
$lFocused = {focused_literal}
$lMaxDepth = [Math]::Max(0, [Int32]{int(max_depth)})
$lMaxChildren = [Math]::Max(1, [Int32]{int(max_children)})
$lDetail = {ps_literal(detail)}

$lRequest = [System.Windows.Automation.CacheRequest]::new()
$lRequest.TreeScope = [System.Windows.Automation.TreeScope]::Element
$lRequest.TreeFilter = [System.Windows.Automation.Automation]::ControlViewCondition
$lRequest.AutomationElementMode = [System.Windows.Automation.AutomationElementMode]::Full
{chr(10).join(property_adds)}

function Get-CachedValue($aElement, $aProperty) {{
    try {{
        $lValue = $aElement.GetCachedPropertyValue($aProperty, $true)
        if ([Object]::ReferenceEquals($lValue, [System.Windows.Automation.AutomationElement]::NotSupported)) {{
            return $null
        }}
        return $lValue
    }} catch {{
        return $null
    }}
}}

function Get-CachedBool($aElement, $aProperty) {{
    $lValue = Get-CachedValue $aElement $aProperty
    if ($null -eq $lValue) {{
        return $false
    }}
    return [bool]$lValue
}}

function Convert-Rect($aValue) {{
    if ($null -eq $aValue) {{
        return [ordered]@{{ left = 0; top = 0; right = 0; bottom = 0; width = 0; height = 0 }}
    }}
    $lLeft = [int][Math]::Round([double]$aValue.X)
    $lTop = [int][Math]::Round([double]$aValue.Y)
    $lWidth = [int][Math]::Round([double]$aValue.Width)
    $lHeight = [int][Math]::Round([double]$aValue.Height)
    return [ordered]@{{
        left = $lLeft
        top = $lTop
        right = $lLeft + $lWidth
        bottom = $lTop + $lHeight
        width = $lWidth
        height = $lHeight
    }}
}}

function Convert-ControlType($aValue) {{
    if ($aValue -is [System.Windows.Automation.ControlType]) {{
        return $aValue.ProgrammaticName
    }}
    return ''
}}

function Convert-Element($aElement, [int]$aDepth) {{
    $script:lNodeCount++
    $lItem = [ordered]@{{
        rect = Convert-Rect (Get-CachedValue $aElement ([System.Windows.Automation.AutomationElement]::BoundingRectangleProperty))
        children = @()
    }}
{semantic_fields}
    if ($aDepth -ge $lMaxDepth) {{
        return $lItem
    }}

    $lChildren = [System.Collections.Generic.List[object]]::new()
    $lSeen = 0
    $lChild = $script:lWalker.GetFirstChild($aElement, $script:lRequest)
    while ($null -ne $lChild) {{
        $lSeen++
        if ($lSeen -le $lMaxChildren) {{
            [void]$lChildren.Add((Convert-Element $lChild ($aDepth + 1)))
        }}
        if ($lSeen -gt $lMaxChildren) {{
            break
        }}
        $lChild = $script:lWalker.GetNextSibling($lChild, $script:lRequest)
    }}
    $lItem.childCount = $lSeen
    $lItem.childrenTruncated = $lSeen -gt $lMaxChildren
    $lItem.children = @($lChildren)
    return $lItem
}}

$script:lWalker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
$script:lRequest = $lRequest
$lToken = $lRequest.Activate()
try {{
    if ($lFocused) {{
        $lRoot = [System.Windows.Automation.AutomationElement]::FocusedElement
    }} elseif ($lHwnd -ne 0) {{
        $lRoot = [System.Windows.Automation.AutomationElement]::FromHandle([IntPtr]$lHwnd)
    }} else {{
        $lRoot = [System.Windows.Automation.AutomationElement]::RootElement
    }}

    $lRoot = $lRoot.GetUpdatedCache($lRequest)
    $script:lNodeCount = 0
    $lRootNode = Convert-Element $lRoot 0
}} finally {{
    if ($null -ne $lToken) {{
        $lToken.Dispose()
    }}
}}

[pscustomobject]@{{
    root = $lRootNode
    nodeCount = $script:lNodeCount
}} | ConvertTo-Json -Depth 64 -Compress
"""


def run_powershell_json(script: str, timeout_ms: int) -> dict[str, object]:
    timeout_seconds = max(1, timeout_ms) / 1000.0
    completed = subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script],
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout_seconds,
    )
    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip() or f"PowerShell exited with {completed.returncode}."
        raise RuntimeError(message)

    output = completed.stdout.strip()
    if not output:
        raise RuntimeError("PowerShell UIA cache probe returned no JSON.")
    try:
        value = json.loads(output)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"PowerShell UIA cache probe returned invalid JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise RuntimeError("PowerShell UIA cache probe did not return a JSON object.")
    return value


def command_uia_cache_map(args: argparse.Namespace) -> int:
    started = time.perf_counter()
    try:
        target = None
        matches: list[dict[str, object]] = []
        hwnd = 0
        if (
            not getattr(args, "focused", False)
            and (
                getattr(args, "hwnd", None) is not None
                or getattr(args, "pid", None) is not None
                or getattr(args, "title_contains", None)
            )
        ):
            target, matches = resolve_target_window(args)
            hwnd = int(target["hwnd"])

        detail = getattr(args, "detail", "full")
        timeout_ms = int(getattr(args, "timeout_ms", 10000))
        script = build_uia_cache_map_script(
            hwnd,
            bool(getattr(args, "focused", False)),
            int(getattr(args, "max_depth", 3)),
            int(getattr(args, "max_children", 200)),
            detail,
        )
        payload = run_powershell_json(script, timeout_ms)
        result: dict[str, object] = {
            "ok": True,
            "source": "uia-dotnet-cache",
            "cache": True,
            "detail": detail,
            "slowSemanticPath": True,
            "recommendedFor": "semanticVerification",
            "notRecommendedFor": ["coordinateDiscovery", "broadTargetDiscovery"],
            "fasterAlternatives": FASTER_SEMANTIC_ALTERNATIVES,
            "root": payload.get("root", {}),
            "nodeCount": payload.get("nodeCount", 0),
        }
        result["elapsedMs"] = elapsed_ms_since(started)
        if target is not None:
            result["target"] = target
            result["matches"] = matches[:5]
        fallback_attempts = getattr(args, "fallback_attempts", [])
        if fallback_attempts:
            result["fallbackAttempts"] = fallback_attempts
        print_json(result)
        return 0
    except LookupError as exc:
        return fail(str(exc), pid=getattr(args, "pid", None), titleContains=getattr(args, "title_contains", None))
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def uia_root_control(auto: object, args: argparse.Namespace) -> tuple[object, dict[str, object] | None, list[dict[str, object]]]:
    if getattr(args, "focused", False):
        return auto.GetFocusedControl(), None, []

    if (
        getattr(args, "hwnd", None) is not None
        or getattr(args, "pid", None) is not None
        or getattr(args, "title_contains", None)
    ):
        target, matches = resolve_target_window(args)
        if not hasattr(auto, "ControlFromHandle"):
            raise RuntimeError("uiautomation.ControlFromHandle is not available in this installation.")
        return auto.ControlFromHandle(int(target["hwnd"])), target, matches

    return auto.GetRootControl(), None, []


def command_uia_map(args: argparse.Namespace) -> int:
    if getattr(args, "cache", False) or not getattr(args, "plain", False):
        return command_uia_cache_map(args)

    started = time.perf_counter()
    try:
        import uiautomation as auto  # type: ignore
    except ImportError:
        return fail(
            "Python package 'uiautomation' is not installed.",
            install="python -m pip install uiautomation",
        )

    try:
        control, target, matches = uia_root_control(auto, args)
        max_children = max(0, int(getattr(args, "max_children", 200)))
        detail = getattr(args, "detail", "full")
        root = control_to_dict(control, 0, args.max_depth, max_children, detail)
        result: dict[str, object] = {
            "ok": True,
            "source": "uiautomation",
            "detail": detail,
            "slowSemanticPath": True,
            "recommendedFor": "semanticVerification",
            "notRecommendedFor": ["coordinateDiscovery", "broadTargetDiscovery"],
            "fasterAlternatives": FASTER_SEMANTIC_ALTERNATIVES,
            "root": root,
        }
        result["elapsedMs"] = elapsed_ms_since(started)
        if target is not None:
            result["target"] = target
            result["matches"] = matches[:5]
        print_json(result)
        return 0
    except LookupError as exc:
        return fail(str(exc), pid=getattr(args, "pid", None), titleContains=getattr(args, "title_contains", None))
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def add_foreground_guard_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--require-foreground-pid", type=int)
    parser.add_argument("--require-foreground-hwnd", type=int)
    parser.add_argument("--session-id")
    parser.add_argument("--session-state-path", dest="state_path")


def add_semantic_control_arguments(parser: argparse.ArgumentParser, include_down_ms: bool) -> None:
    parser.add_argument("--pipe-name", required=True)
    parser.add_argument("--form-name")
    parser.add_argument("--control-name")
    parser.add_argument("--ref")
    parser.add_argument("--timeout-ms", type=int, default=3000)
    add_foreground_guard_arguments(parser)
    if include_down_ms:
        parser.add_argument("--down-ms", type=int, default=40)


def add_typed_bridge_arguments(parser: argparse.ArgumentParser, targeted: bool = True) -> None:
    parser.add_argument("--pipe-name", required=True)
    parser.add_argument("--timeout-ms", type=int, default=5000)
    if targeted:
        target = parser.add_mutually_exclusive_group(required=True)
        target.add_argument("--ref")
        target.add_argument("--form-name")
        target.add_argument("--form-hwnd", type=int)
        parser.add_argument("--control-name")


def add_discovery_filter_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--name")
    parser.add_argument("--caption-contains")
    parser.add_argument("--class-name")
    parser.add_argument("--visible", choices=["true", "false"])
    parser.add_argument("--value")
    parser.add_argument("--fields")


def add_wait_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--timeout-ms", type=int, default=5000)
    parser.add_argument("--poll-ms", type=int, default=100)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Safe Windows desktop control helper.")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("announce")
    p.add_argument("--asset", choices=sorted(ANNOUNCEMENTS), required=True)
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=command_announce)

    p = sub.add_parser("takeover")
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=command_takeover)

    p = sub.add_parser("release")
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=command_release)

    p = sub.add_parser("foreground-session")
    session_sub = p.add_subparsers(dest="session_command", required=True)

    session = session_sub.add_parser("start")
    session.add_argument("--target-pid", type=int, required=True)
    session.add_argument("--target-hwnd", type=int, default=0)
    session.add_argument("--controller-pid", type=int, required=True)
    session.add_argument("--ttl-ms", type=int, default=30000)
    session.add_argument("--state-path")
    session.add_argument("--event-path")
    session.add_argument("--dry-run", action="store_true")
    session.set_defaults(func=command_foreground_session_start)

    session = session_sub.add_parser("renew")
    session.add_argument("--session-id", required=True)
    session.add_argument("--ttl-ms", type=int, default=30000)
    session.add_argument("--state-path")
    session.set_defaults(func=command_foreground_session_renew)

    session = session_sub.add_parser("release")
    session.add_argument("--session-id", required=True)
    session.add_argument("--state-path")
    session.add_argument("--event-path")
    session.add_argument("--dry-run", action="store_true")
    session.set_defaults(func=command_foreground_session_release)

    session = session_sub.add_parser("status")
    session.add_argument("--state-path")
    session.set_defaults(func=command_foreground_session_status)

    session = session_sub.add_parser("_watchdog", help=argparse.SUPPRESS)
    session.add_argument("--session-id", required=True)
    session.add_argument("--state-path")
    session.set_defaults(func=command_foreground_session_watchdog)

    p = sub.add_parser("bridge-request")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--request", default="")
    p.add_argument("--request-file")
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_bridge_request)

    p = sub.add_parser("bridge-batch")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--request", action="append", default=[])
    p.add_argument("--request-file", action="append", default=[])
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_bridge_batch)

    p = sub.add_parser("probe-bridge")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_probe_bridge)

    p = sub.add_parser("bridge-window-info")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--target", choices=["focused", "handle", "name"], default="focused")
    p.add_argument("--handle", type=int)
    p.add_argument("--name")
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_bridge_window_info)

    p = sub.add_parser("bridge-form-map")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--target", choices=["focused", "handle", "name"], default="focused")
    p.add_argument("--handle", type=int)
    p.add_argument("--name")
    p.add_argument("--detail", choices=["full", "geometry"], default="geometry")
    p.add_argument("--include-accessibility", action="store_true")
    p.add_argument("--all-controls", action="store_true")
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_bridge_form_map)

    p = sub.add_parser("bridge-provider-map")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--target", choices=["focused", "handle", "name"], default="focused")
    p.add_argument("--handle", type=int)
    p.add_argument("--name")
    p.add_argument("--detail", choices=["full", "geometry"], default="full")
    p.add_argument("--max-depth", type=int, default=3)
    p.add_argument("--max-children", type=int, default=200)
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_bridge_provider_map)

    p = sub.add_parser("bridge-control-info")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--ref", required=True)
    p.add_argument("--detail", choices=["full", "geometry"], default="full")
    p.add_argument("--include-accessibility", action="store_true")
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_bridge_control_info)

    p = sub.add_parser("bridge-controls-info")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--ref", action="append", required=True)
    p.add_argument("--detail", choices=["full", "geometry"], default="full")
    p.add_argument("--include-accessibility", action="store_true")
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_bridge_controls_info)

    p = sub.add_parser("bridge-forms")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--timeout-ms", type=int, default=5000)
    add_discovery_filter_arguments(p)
    p.set_defaults(ref=None, pid=None, func=command_bridge_forms)

    p = sub.add_parser("bridge-find")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--form-name")
    p.add_argument("--control-name")
    p.add_argument("--ref")
    p.add_argument("--timeout-ms", type=int, default=5000)
    add_discovery_filter_arguments(p)
    p.set_defaults(pid=None, func=command_bridge_find)

    p = sub.add_parser("bridge-invoke")
    add_typed_bridge_arguments(p)
    p.add_argument("--async", dest="async_mode", action="store_true")
    p.set_defaults(func=command_bridge_invoke)

    p = sub.add_parser("bridge-action-invoke")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--timeout-ms", type=int, default=5000)
    action_owner = p.add_mutually_exclusive_group(required=True)
    action_owner.add_argument("--form-name")
    action_owner.add_argument("--form-hwnd", type=int)
    action_owner.add_argument("--data-module-name")
    p.add_argument("--component-name", required=True)
    p.add_argument("--async", dest="async_mode", action="store_true")
    p.set_defaults(
        func=command_bridge_invoke,
        bridge_command="action.invoke",
        target_builder=build_bridge_action_target,
        required_capability="action-invoke",
    )

    p = sub.add_parser("bridge-operation-status")
    add_typed_bridge_arguments(p, False)
    p.add_argument("--operation-id", required=True)
    p.add_argument("--no-consume", action="store_true")
    p.set_defaults(func=command_bridge_operation_status)

    p = sub.add_parser("bridge-set-text")
    add_typed_bridge_arguments(p)
    p.add_argument("--text", required=True)
    p.set_defaults(func=command_bridge_set_text)

    p = sub.add_parser("bridge-set-checked")
    add_typed_bridge_arguments(p)
    checked = p.add_mutually_exclusive_group(required=True)
    checked.add_argument("--checked", dest="checked", action="store_true")
    checked.add_argument("--unchecked", dest="checked", action="store_false")
    p.set_defaults(func=command_bridge_set_checked)

    p = sub.add_parser("bridge-select")
    add_typed_bridge_arguments(p)
    selection = p.add_mutually_exclusive_group(required=True)
    selection.add_argument("--index", type=int)
    selection.add_argument("--text")
    selection.add_argument("--indices", nargs="+", type=int)
    selection.add_argument("--texts", nargs="+")
    selection.add_argument("--clear-selection", action="store_true")
    p.set_defaults(func=command_bridge_select)

    p = sub.add_parser("bridge-focus")
    add_typed_bridge_arguments(p)
    p.set_defaults(func=command_bridge_focus)

    p = sub.add_parser("bridge-tab")
    add_typed_bridge_arguments(p, False)
    p.add_argument("--shift", action="store_true")
    p.set_defaults(func=command_bridge_tab)

    p = sub.add_parser("foreground-window")
    p.set_defaults(func=command_foreground_window)

    p = sub.add_parser("windows-list")
    p.add_argument("--pid", type=int)
    add_discovery_filter_arguments(p)
    p.set_defaults(ref=None, func=command_windows_list)

    p = sub.add_parser("wait-window")
    p.add_argument("--pid", type=int)
    add_discovery_filter_arguments(p)
    add_wait_arguments(p)
    p.set_defaults(ref=None, func=command_wait_window)

    p = sub.add_parser("wait-form")
    p.add_argument("--pipe-name", required=True)
    add_discovery_filter_arguments(p)
    add_wait_arguments(p)
    p.set_defaults(ref=None, pid=None, func=command_wait_form)

    p = sub.add_parser("wait-control")
    p.add_argument("--pipe-name", required=True)
    p.add_argument("--form-name")
    p.add_argument("--control-name")
    p.add_argument("--ref")
    add_discovery_filter_arguments(p)
    add_wait_arguments(p)
    p.set_defaults(pid=None, func=command_wait_control)

    p = sub.add_parser("win32-map")
    p.add_argument("--focused", action="store_true")
    p.add_argument("--hwnd", type=int)
    p.add_argument("--pid", type=int)
    p.add_argument("--title-contains")
    p.add_argument("--max-depth", type=int, default=4)
    p.add_argument("--max-children", type=int, default=200)
    p.add_argument("--detail", choices=["full", "geometry"], default="full")
    p.set_defaults(func=command_win32_map)

    p = sub.add_parser("fast-map")
    p.add_argument("--pipe-name")
    p.add_argument("--target", choices=["focused", "handle", "name"], default="focused")
    p.add_argument("--handle", type=int)
    p.add_argument("--name")
    p.add_argument("--pid", type=int)
    p.add_argument("--title-contains")
    p.add_argument("--max-depth", type=int, default=4)
    p.add_argument("--max-children", type=int, default=200)
    p.add_argument("--detail", choices=["geometry", "full"], default="geometry")
    p.add_argument("--timeout-ms", type=int, default=5000)
    p.set_defaults(func=command_fast_map)

    p = sub.add_parser("fast-semantic-map")
    p.add_argument("--pipe-name")
    p.add_argument("--target", choices=["focused", "handle", "name"], default="focused")
    p.add_argument("--handle", type=int)
    p.add_argument("--name")
    p.add_argument("--pid", type=int)
    p.add_argument("--title-contains")
    p.add_argument("--max-depth", type=int, default=3)
    p.add_argument("--max-children", type=int, default=200)
    p.add_argument("--detail", choices=["geometry", "full"], default="full")
    p.add_argument("--timeout-ms", type=int, default=10000)
    p.set_defaults(func=command_fast_semantic_map)

    p = sub.add_parser("activate-window")
    p.add_argument("--hwnd", type=int)
    p.add_argument("--pid", type=int)
    p.add_argument("--title-contains")
    p.add_argument("--timeout-ms", type=int, default=3000)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_activate_window)

    p = sub.add_parser("move-to-control")
    add_semantic_control_arguments(p, False)
    p.set_defaults(func=command_move_to_control)

    p = sub.add_parser("click-control")
    add_semantic_control_arguments(p, True)
    p.set_defaults(func=command_click_control)

    p = sub.add_parser("double-click-control")
    add_semantic_control_arguments(p, True)
    p.set_defaults(func=command_double_click_control)

    p = sub.add_parser("right-click-control")
    add_semantic_control_arguments(p, True)
    p.set_defaults(func=command_right_click_control)

    p = sub.add_parser("screenshot-window")
    p.add_argument("--hwnd", type=int)
    p.add_argument("--pid", type=int)
    p.add_argument("--title-contains")
    p.add_argument("--output", required=True)
    p.set_defaults(func=command_screenshot_window)

    p = sub.add_parser("move")
    p.add_argument("--x", type=int, required=True)
    p.add_argument("--y", type=int, required=True)
    p.add_argument("--duration-ms", type=int, default=0)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_move)

    p = sub.add_parser("click")
    p.add_argument("--x", type=int)
    p.add_argument("--y", type=int)
    p.add_argument("--button", choices=["left", "right", "middle"], default="left")
    p.add_argument("--count", type=int, choices=[1, 2], default=1)
    p.add_argument("--down-ms", type=int, default=40)
    p.add_argument("--duration-ms", type=int, default=0)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_click)

    p = sub.add_parser("double-click")
    p.add_argument("--x", type=int)
    p.add_argument("--y", type=int)
    p.add_argument("--button", choices=["left", "right", "middle"], default="left")
    p.add_argument("--down-ms", type=int, default=40)
    p.add_argument("--duration-ms", type=int, default=0)
    add_foreground_guard_arguments(p)
    p.set_defaults(count=2, func=command_double_click)

    p = sub.add_parser("press")
    p.add_argument("--key", required=True)
    p.add_argument("--down-ms", type=int, default=20)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_press)

    p = sub.add_parser("tab")
    p.add_argument("--shift", action="store_true")
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_tab)

    p = sub.add_parser("type-text")
    p.add_argument("--text", required=True)
    p.add_argument("--delay-ms", type=int, default=0)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_type_text)

    p = sub.add_parser("key-chord")
    p.add_argument("--keys", required=True)
    p.add_argument("--down-ms", type=int, default=20)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_key_chord)

    p = sub.add_parser("clear-and-type")
    p.add_argument("--text", required=True)
    p.add_argument("--delay-ms", type=int, default=0)
    p.add_argument("--down-ms", type=int, default=20)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_clear_and_type)

    p = sub.add_parser("uia-map")
    p.add_argument("--focused", action="store_true")
    p.add_argument("--hwnd", type=int)
    p.add_argument("--pid", type=int)
    p.add_argument("--title-contains")
    p.add_argument("--max-depth", type=int, default=3)
    p.add_argument("--max-children", type=int, default=200)
    p.add_argument("--detail", choices=["full", "geometry"], default="full")
    p.add_argument("--cache", action="store_true")
    p.add_argument("--plain", action="store_true")
    p.add_argument("--timeout-ms", type=int, default=10000)
    p.set_defaults(func=command_uia_map)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
