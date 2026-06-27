#!/usr/bin/env python3
"""Windows desktop control helper for Codex agents."""

from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
import urllib.error
import urllib.request


BELLA_VOICE_ID = "EXAVITQu4vr4xnSDxMaL"
DEFAULT_MODEL = "eleven_turbo_v2_5"
PIPE_PREFIX = "\\\\.\\pipe\\"
START_TEXT = (
    "I am taking over control now. Please move away from the mouse and keyboard. "
    "I will begin in three seconds."
)
DONE_TEXT = "Thanks, I am done. You may resume work now."

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
winmm = ctypes.WinDLL("winmm", use_last_error=True)


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


def load_env_file(start: Path) -> None:
    for folder in [start, *start.parents]:
        env_path = folder / ".env"
        if not env_path.exists():
            continue
        for raw_line in env_path.read_text(encoding="utf-8", errors="ignore").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            name, value = line.split("=", 1)
            name = name.strip()
            value = value.strip().strip('"').strip("'")
            if name and name not in os.environ:
                os.environ[name] = value
        return


def cache_dir() -> Path:
    base = os.environ.get("LOCALAPPDATA")
    if base:
        path = Path(base) / "MaxLogic" / "CodexDesktopControl" / "tts-cache"
    else:
        path = Path.cwd() / ".desktop-control-cache"
    path.mkdir(parents=True, exist_ok=True)
    return path


def mci(command: str) -> None:
    buffer = ctypes.create_unicode_buffer(512)
    result = winmm.mciSendStringW(command, buffer, len(buffer), 0)
    if result != 0:
        raise OSError(f"MCI command failed ({result}): {command}")


def play_audio(path: Path) -> None:
    alias = "codex_tts_" + hashlib.sha1(str(path).encode("utf-8")).hexdigest()[:12]
    mci(f'open "{path}" type mpegvideo alias {alias}')
    try:
        mci(f"play {alias} wait")
    finally:
        mci(f"close {alias}")


def sapi_speak(text: str, dry_run: bool) -> None:
    if dry_run:
        return

    script = (
        "Add-Type -AssemblyName System.Speech; "
        "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
        "$s.Rate = 1; $s.Volume = 100; "
        "$s.Speak([Console]::In.ReadToEnd())"
    )
    subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script],
        input=text,
        text=True,
        check=True,
    )


def elevenlabs_speech(text: str, dry_run: bool, allow_sapi_fallback: bool) -> dict[str, object]:
    load_env_file(Path.cwd())
    api_key = os.environ.get("ELEVENLABS_API_KEY")
    settings = {
        "stability": 0.32,
        "similarity_boost": 0.82,
        "style": 0.62,
        "speed": 1.0,
        "use_speaker_boost": True,
    }
    payload = {
        "text": text,
        "model_id": DEFAULT_MODEL,
        "voice_settings": settings,
    }
    cache_key = hashlib.sha256(
        json.dumps({"voice": BELLA_VOICE_ID, "payload": payload}, sort_keys=True).encode("utf-8")
    ).hexdigest()
    output_path = cache_dir() / f"{cache_key}.mp3"

    if dry_run:
        return {"ok": True, "provider": "elevenlabs", "dryRun": True, "path": str(output_path), "text": text}

    if not api_key:
        if not allow_sapi_fallback:
            raise RuntimeError("ELEVENLABS_API_KEY is not set. Pass --allow-sapi-fallback only with user approval.")
        sapi_speak(text, dry_run)
        return {"ok": True, "provider": "sapi", "fallback": True, "text": text}

    if not output_path.exists():
        url = (
            f"https://api.elevenlabs.io/v1/text-to-speech/{BELLA_VOICE_ID}"
            "?output_format=mp3_44100_128"
        )
        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Accept": "audio/mpeg",
                "Content-Type": "application/json",
                "xi-api-key": api_key,
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                output_path.write_bytes(response.read())
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"ElevenLabs request failed: HTTP {exc.code}: {detail}") from exc

    play_audio(output_path)
    return {"ok": True, "provider": "elevenlabs", "path": str(output_path), "text": text}


def command_announce(args: argparse.Namespace) -> int:
    try:
        result = elevenlabs_speech(args.text, args.dry_run, args.allow_sapi_fallback)
        if args.sleep_after > 0 and not args.dry_run:
            time.sleep(args.sleep_after)
        print_json(result)
        return 0
    except Exception as exc:  # noqa: BLE001 - CLI boundary
        return fail(str(exc), provider="elevenlabs")


def command_takeover(args: argparse.Namespace) -> int:
    args.text = START_TEXT
    args.sleep_after = 3
    return command_announce(args)


def command_release(args: argparse.Namespace) -> int:
    args.text = DONE_TEXT
    args.sleep_after = 0
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

    def add_announce_flags(p: argparse.ArgumentParser) -> None:
        p.add_argument("--dry-run", action="store_true")
        p.add_argument("--allow-sapi-fallback", action="store_true")

    p = sub.add_parser("announce")
    p.add_argument("--text", required=True)
    p.add_argument("--sleep-after", type=float, default=0)
    add_announce_flags(p)
    p.set_defaults(func=command_announce)

    p = sub.add_parser("takeover")
    add_announce_flags(p)
    p.set_defaults(func=command_takeover)

    p = sub.add_parser("release")
    add_announce_flags(p)
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
