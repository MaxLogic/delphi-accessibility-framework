import json
import ctypes
import importlib.util
import subprocess
import sys
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


if __name__ == "__main__":
    unittest.main()
