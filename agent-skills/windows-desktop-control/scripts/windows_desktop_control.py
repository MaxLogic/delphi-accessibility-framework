#!/usr/bin/env python3
"""Windows desktop control helper for Codex agents."""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
import json
from pathlib import Path
import struct
import subprocess
import sys
import time
import winsound


PIPE_PREFIX = "\\\\.\\pipe\\"
AUTO_BRIDGE_PROBE_TIMEOUT_MS = 5
AUTO_SEMANTIC_BRIDGE_PROBE_TIMEOUT_MS = 75
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
PW_RENDERFULLCONTENT = 0x00000002
SRCCOPY = 0x00CC0020
SW_RESTORE = 9
GA_ROOT = 2
GW_HWNDNEXT = 2
GW_CHILD = 5

VK_CODES = {
    "tab": 0x09,
    "enter": 0x0D,
    "esc": 0x1B,
    "escape": 0x1B,
    "space": 0x20,
    "left": 0x25,
    "up": 0x26,
    "right": 0x27,
    "down": 0x28,
    "shift": 0x10,
}
EXTENDED_VK_CODES = {VK_CODES["left"], VK_CODES["up"], VK_CODES["right"], VK_CODES["down"]}

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
user32.AttachThreadInput.argtypes = [wintypes.DWORD, wintypes.DWORD, wintypes.BOOL]
user32.AttachThreadInput.restype = wintypes.BOOL
user32.BringWindowToTop.argtypes = [wintypes.HWND]
user32.BringWindowToTop.restype = wintypes.BOOL
user32.EnumWindows.argtypes = [EnumWindowsProc, wintypes.LPARAM]
user32.EnumWindows.restype = wintypes.BOOL
user32.GetClassNameW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetClassNameW.restype = ctypes.c_int
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


def command_announce(args: argparse.Namespace) -> int:
    try:
        file_name, text, sleep_after = ANNOUNCEMENTS[args.asset]
        path = ANNOUNCEMENT_DIR / file_name
        if not path.exists():
            return fail(f"Announcement asset is missing: {path}")
        if not args.dry_run:
            winsound.PlaySound(str(path), winsound.SND_FILENAME)
            if sleep_after > 0:
                time.sleep(sleep_after)
        print_json({"ok": True, "provider": "asset", "asset": args.asset, "path": str(path), "text": text})
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), provider="asset")


def command_takeover(args: argparse.Namespace) -> int:
    args.asset = "takeover"
    return command_announce(args)


def command_release(args: argparse.Namespace) -> int:
    args.asset = "release"
    return command_announce(args)


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


def activate_hwnd(hwnd: wintypes.HWND, timeout_ms: int) -> bool:
    deadline = time.monotonic() + max(timeout_ms, 1) / 1000.0
    current_thread_id = int(kernel32.GetCurrentThreadId())
    while time.monotonic() <= deadline:
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
            return True
        time.sleep(0.05)
    return False


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
        ok = activate_hwnd(activated_hwnd, args.timeout_ms)
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


def guard_real_input(args: argparse.Namespace) -> int | None:
    required_pid = getattr(args, "require_foreground_pid", None)
    required_hwnd = getattr(args, "require_foreground_hwnd", None)
    if required_pid is None and required_hwnd is None:
        return None

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
        )
    return None


def command_move(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    if not user32.SetCursorPos(int(args.x), int(args.y)):
        return fail("SetCursorPos failed.", win32Error=ctypes.get_last_error())
    print_json({"ok": True, "action": "move", "x": args.x, "y": args.y})
    return 0


def command_click(args: argparse.Namespace) -> int:
    if (args.x is None) != (args.y is None):
        return fail("Provide both --x and --y, or neither.")
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    if args.x is not None and args.y is not None and not user32.SetCursorPos(int(args.x), int(args.y)):
        return fail("SetCursorPos failed.", win32Error=ctypes.get_last_error())
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    time.sleep(args.down_ms / 1000.0)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
    print_json({"ok": True, "action": "click", "x": args.x, "y": args.y})
    return 0


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


def command_press(args: argparse.Namespace) -> int:
    key = args.key.lower()
    if key not in VK_CODES:
        return fail(f"Unsupported key: {args.key}", supported=sorted(VK_CODES))
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        vk = VK_CODES[key]
        send_key_input(vk, False)
        time.sleep(args.down_ms / 1000.0)
        send_key_input(vk, True)
        print_json({"ok": True, "action": "press", "key": key})
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_tab(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        if args.shift:
            send_key_input(VK_CODES["shift"], False)
        send_key_input(VK_CODES["tab"], False)
        send_key_input(VK_CODES["tab"], True)
        if args.shift:
            send_key_input(VK_CODES["shift"], True)
        print_json({"ok": True, "action": "tab", "shift": args.shift})
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


def command_type_text(args: argparse.Namespace) -> int:
    guard_result = guard_real_input(args)
    if guard_result is not None:
        return guard_result
    try:
        raw = args.text.encode("utf-16-le")
        units = [raw[i] | (raw[i + 1] << 8) for i in range(0, len(raw), 2)]
        for unit in units:
            send_unicode_unit(unit, False)
            send_unicode_unit(unit, True)
            if args.delay_ms > 0:
                time.sleep(args.delay_ms / 1000.0)
        print_json({"ok": True, "action": "type-text", "length": len(args.text)})
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

    p = sub.add_parser("foreground-window")
    p.set_defaults(func=command_foreground_window)

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
    p.set_defaults(func=command_activate_window)

    p = sub.add_parser("screenshot-window")
    p.add_argument("--hwnd", type=int)
    p.add_argument("--pid", type=int)
    p.add_argument("--title-contains")
    p.add_argument("--output", required=True)
    p.set_defaults(func=command_screenshot_window)

    p = sub.add_parser("move")
    p.add_argument("--x", type=int, required=True)
    p.add_argument("--y", type=int, required=True)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_move)

    p = sub.add_parser("click")
    p.add_argument("--x", type=int)
    p.add_argument("--y", type=int)
    p.add_argument("--down-ms", type=int, default=40)
    add_foreground_guard_arguments(p)
    p.set_defaults(func=command_click)

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
