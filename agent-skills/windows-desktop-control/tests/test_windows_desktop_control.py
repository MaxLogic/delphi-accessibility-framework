import json
import ctypes
import importlib.util
import os
import subprocess
import sys
import tempfile
from pathlib import Path
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "windows_desktop_control.py"


def load_helper_module():
    spec = importlib.util.spec_from_file_location("windows_desktop_control", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load helper module.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class WindowsDesktopControlTests(unittest.TestCase):
    def run_helper(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            check=False,
            capture_output=True,
            encoding="utf-8",
        )

    def test_foreground_window_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("foreground-window", result.stdout)

    def test_foreground_window_returns_json_payload(self) -> None:
        result = self.run_helper("foreground-window")

        self.assertEqual(0, result.returncode, result.stderr)
        payload = json.loads(result.stdout)
        self.assertTrue(payload["ok"])
        self.assertIn("pid", payload["window"])
        self.assertIn("title", payload["window"])

    def test_send_input_structure_matches_win32_layout(self) -> None:
        helper = load_helper_module()
        expected_size = 40 if ctypes.sizeof(ctypes.c_void_p) == 8 else 28

        self.assertEqual(expected_size, ctypes.sizeof(helper.INPUT))

    def test_arrow_keys_use_extended_key_flag(self) -> None:
        helper = load_helper_module()

        self.assertEqual(helper.KEYEVENTF_EXTENDEDKEY, helper.key_flags_for_vk(helper.VK_CODES["down"], False))
        self.assertEqual(
            helper.KEYEVENTF_EXTENDEDKEY | helper.KEYEVENTF_KEYUP,
            helper.key_flags_for_vk(helper.VK_CODES["down"], True),
        )

    def test_screenshot_window_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("screenshot-window", result.stdout)

    def test_bridge_window_info_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("bridge-window-info", result.stdout)

    def test_bridge_window_info_request_uses_handle_target(self) -> None:
        helper = load_helper_module()
        args = type("Args", (), {"target": "handle", "handle": 1234, "name": None})()

        payload = json.loads(helper.build_bridge_window_info_request(args))

        self.assertEqual({"cmd": "window.info", "target": "handle", "handle": 1234}, payload)

    def test_bridge_window_info_request_rejects_missing_name(self) -> None:
        helper = load_helper_module()
        args = type("Args", (), {"target": "name", "handle": None, "name": None})()

        with self.assertRaises(ValueError):
            helper.build_bridge_window_info_request(args)

    def test_screenshot_window_captures_foreground_window(self) -> None:
        foreground = self.run_helper("foreground-window")
        self.assertEqual(0, foreground.returncode, foreground.stderr)
        window = json.loads(foreground.stdout)["window"]
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "window.bmp"

            result = self.run_helper("screenshot-window", "--hwnd", str(window["hwnd"]), "--output", str(output))

            self.assertEqual(0, result.returncode, result.stderr)
            payload = json.loads(result.stdout)
            self.assertTrue(payload["ok"])
            self.assertEqual(str(output), payload["path"])
            self.assertGreater(os.path.getsize(output), 54)
            self.assertEqual(b"BM", output.read_bytes()[:2])


if __name__ == "__main__":
    unittest.main()
