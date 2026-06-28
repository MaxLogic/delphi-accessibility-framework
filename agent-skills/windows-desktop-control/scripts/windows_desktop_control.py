#!/usr/bin/env python3
"""Windows desktop control helper for Codex agents."""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
import json
from pathlib import Path
import struct
import time
import winsound


PIPE_PREFIX = "\\\\.\\pipe\\"
START_TEXT = (
    "I am taking over control now. Please move away from the mouse and keyboard. "
    "I will begin in three seconds."
)
DONE_TEXT = "Thanks, I am done. You may resume work now."
SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
ANNOUNCEMENT_DIR = SKILL_DIR / "assets" / "announcements"
ANNOUNCEMENTS = {
    "takeover": ("takeover.wav", START_TEXT, 3),
    "release": ("release.wav", DONE_TEXT, 0),
}

KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_UNICODE = 0x0004
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
PW_RENDERFULLCONTENT = 0x00000002
SRCCOPY = 0x00CC0020
SW_RESTORE = 9

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
user32.GetForegroundWindow.argtypes = []
user32.GetForegroundWindow.restype = wintypes.HWND
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


def read_line(handle) -> str:
    chunks: list[bytes] = []
    while True:
        byte = handle.read(1)
        if not byte:
            raise RuntimeError("Pipe closed before a response line was received.")
        if byte == b"\n":
            return b"".join(chunks).decode("utf-8")
        if byte != b"\r":
            chunks.append(byte)


def bridge_request(pipe_name: str, request_text: str, timeout_ms: int) -> dict[str, object]:
    path = normalize_pipe_path(pipe_name)
    if not wait_named_pipe(path, timeout_ms):
        raise RuntimeError(f"Named pipe is not available: {path}")
    with open(path, "r+b", buffering=0) as pipe:
        pipe.write(request_text.encode("utf-8") + b"\n")
        response = read_line(pipe)
    try:
        return json.loads(response)
    except json.JSONDecodeError:
        return {"ok": False, "raw": response, "message": "Response was not JSON."}


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


def window_info(hwnd: wintypes.HWND) -> dict[str, object]:
    pid, thread_id = get_window_pid_and_thread(hwnd)
    foreground = hwnd_to_int(user32.GetForegroundWindow()) == hwnd_to_int(hwnd)
    return {
        "hwnd": hwnd_to_int(hwnd),
        "pid": pid,
        "threadId": thread_id,
        "title": get_window_text(hwnd),
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


def matching_windows(pid: int | None, title_contains: str | None) -> list[dict[str, object]]:
    title_filter = (title_contains or "").lower()
    result: list[dict[str, object]] = []
    for hwnd in enum_top_windows():
        item = window_info(hwnd)
        if not item["visible"]:
            continue
        if pid is not None and item["pid"] != pid:
            continue
        if title_filter and title_filter not in str(item["title"]).lower():
            continue
        result.append(item)
    result.sort(key=lambda item: (not bool(item["title"]), -int(item["rect"]["width"]) * int(item["rect"]["height"])))
    return result


def resolve_target_window(args: argparse.Namespace) -> tuple[dict[str, object], list[dict[str, object]]]:
    if args.hwnd is None and args.pid is None and not args.title_contains:
        raise ValueError("Provide --hwnd, --pid, or --title-contains.")
    if args.hwnd is not None:
        target = window_info(int_to_hwnd(args.hwnd))
        return target, [target]
    matches = matching_windows(args.pid, args.title_contains)
    if not matches:
        raise LookupError("No matching visible top-level window was found.")
    return matches[0], matches


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


def command_activate_window(args: argparse.Namespace) -> int:
    try:
        target, matches = resolve_target_window(args)
        ok = activate_hwnd(int_to_hwnd(int(target["hwnd"])), args.timeout_ms)
        payload = {
            "ok": ok,
            "action": "activate-window",
            "target": target,
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


def command_move(args: argparse.Namespace) -> int:
    if not user32.SetCursorPos(int(args.x), int(args.y)):
        return fail("SetCursorPos failed.", win32Error=ctypes.get_last_error())
    print_json({"ok": True, "action": "move", "x": args.x, "y": args.y})
    return 0


def command_click(args: argparse.Namespace) -> int:
    if (args.x is None) != (args.y is None):
        return fail("Provide both --x and --y, or neither.")
    if args.x is not None and args.y is not None and not user32.SetCursorPos(int(args.x), int(args.y)):
        return fail("SetCursorPos failed.", win32Error=ctypes.get_last_error())
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    time.sleep(args.down_ms / 1000.0)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
    print_json({"ok": True, "action": "click", "x": args.x, "y": args.y})
    return 0


def send_key_input(vk: int, key_up: bool = False) -> None:
    flags = KEYEVENTF_KEYUP if key_up else 0
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


def control_to_dict(control: object, depth: int, max_depth: int) -> dict[str, object]:
    item = {
        "name": getattr(control, "Name", ""),
        "automationId": getattr(control, "AutomationId", ""),
        "className": getattr(control, "ClassName", ""),
        "controlType": getattr(control, "ControlTypeName", ""),
        "focused": bool(getattr(control, "HasKeyboardFocus", False)),
        "enabled": bool(getattr(control, "IsEnabled", False)),
        "rect": rect_to_dict(getattr(control, "BoundingRectangle")),
        "children": [],
    }
    if depth >= max_depth:
        return item
    try:
        children = control.GetChildren()
    except Exception:
        children = []
    item["children"] = [control_to_dict(child, depth + 1, max_depth) for child in children]
    return item


def command_uia_map(args: argparse.Namespace) -> int:
    try:
        import uiautomation as auto  # type: ignore
    except ImportError:
        return fail(
            "Python package 'uiautomation' is not installed.",
            install="python -m pip install uiautomation",
        )

    try:
        control = auto.GetFocusedControl() if args.focused else auto.GetRootControl()
        print_json({"ok": True, "source": "uiautomation", "root": control_to_dict(control, 0, args.max_depth)})
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc))


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

    p = sub.add_parser("foreground-window")
    p.set_defaults(func=command_foreground_window)

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
    p.set_defaults(func=command_move)

    p = sub.add_parser("click")
    p.add_argument("--x", type=int)
    p.add_argument("--y", type=int)
    p.add_argument("--down-ms", type=int, default=40)
    p.set_defaults(func=command_click)

    p = sub.add_parser("press")
    p.add_argument("--key", required=True)
    p.add_argument("--down-ms", type=int, default=20)
    p.set_defaults(func=command_press)

    p = sub.add_parser("tab")
    p.add_argument("--shift", action="store_true")
    p.set_defaults(func=command_tab)

    p = sub.add_parser("type-text")
    p.add_argument("--text", required=True)
    p.add_argument("--delay-ms", type=int, default=0)
    p.set_defaults(func=command_type_text)

    p = sub.add_parser("uia-map")
    p.add_argument("--focused", action="store_true")
    p.add_argument("--max-depth", type=int, default=3)
    p.set_defaults(func=command_uia_map)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
