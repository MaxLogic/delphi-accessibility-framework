#!/usr/bin/env python3
"""Windows desktop control helper for Codex agents."""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
import json
from pathlib import Path
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
user32 = ctypes.WinDLL("user32", use_last_error=True)


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [
        ("wVk", wintypes.WORD),
        ("wScan", wintypes.WORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ctypes.c_size_t),
    ]


class INPUTUNION(ctypes.Union):
    _fields_ = [("ki", KEYBDINPUT)]


class INPUT(ctypes.Structure):
    _fields_ = [("type", wintypes.DWORD), ("union", INPUTUNION)]


def print_json(value: object) -> None:
    print(json.dumps(value, ensure_ascii=False, indent=2))


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
