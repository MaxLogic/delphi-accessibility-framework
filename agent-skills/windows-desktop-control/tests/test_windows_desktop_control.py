import json
import ctypes
from contextlib import redirect_stdout
import importlib.util
from io import StringIO
import os
import subprocess
import sys
import tempfile
from types import SimpleNamespace
from pathlib import Path
from unittest import mock
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

    def test_real_input_commands_refuse_mismatched_foreground_before_dispatch(self) -> None:
        helper = load_helper_module()
        calls = []

        class FakeUser32:
            # Real foreground ownership and SendInput are nondeterministic and unsafe in this unit test.
            @staticmethod
            def GetForegroundWindow():
                return helper.int_to_hwnd(101)

            @staticmethod
            def SetCursorPos(x, y):
                calls.append(("move", x, y))
                return True

            @staticmethod
            def mouse_event(*args):
                calls.append(("mouse", *args))

        commands = [
            (helper.command_move, SimpleNamespace(x=10, y=20)),
            (helper.command_click, SimpleNamespace(x=10, y=20, down_ms=0)),
            (helper.command_press, SimpleNamespace(key="enter", down_ms=0)),
            (helper.command_tab, SimpleNamespace(shift=False)),
            (helper.command_type_text, SimpleNamespace(text="x", delay_ms=0)),
        ]
        original_user32 = helper.user32
        original_window_info = helper.window_info
        original_send_key_input = helper.send_key_input
        original_send_unicode_unit = helper.send_unicode_unit
        try:
            helper.user32 = FakeUser32()
            helper.window_info = lambda _hwnd: {"hwnd": 101, "pid": 202, "title": "Other application"}
            helper.send_key_input = lambda *args: calls.append(("key", *args))
            helper.send_unicode_unit = lambda *args: calls.append(("unicode", *args))

            guards = [(303, None, "requiredForegroundPid", 303), (None, 404, "requiredForegroundHwnd", 404)]
            for required_pid, required_hwnd, field, expected in guards:
                for command, args in commands:
                    with self.subTest(command=command.__name__, guard=field):
                        args.require_foreground_pid = required_pid
                        args.require_foreground_hwnd = required_hwnd
                        output = StringIO()
                        with redirect_stdout(output):
                            result = command(args)

                        self.assertEqual(2, result)
                        payload = json.loads(output.getvalue())
                        self.assertFalse(payload["ok"])
                        self.assertEqual(expected, payload[field])
                        self.assertEqual(202, payload["actualForeground"]["pid"])
                        self.assertEqual([], calls)
        finally:
            helper.user32 = original_user32
            helper.window_info = original_window_info
            helper.send_key_input = original_send_key_input
            helper.send_unicode_unit = original_send_unicode_unit

    def test_real_input_guard_allows_matching_pid_and_hwnd(self) -> None:
        helper = load_helper_module()
        calls = []

        class FakeUser32:
            # Real cursor movement is unsafe in this unit test; the guard itself uses real Win32-shaped values.
            @staticmethod
            def GetForegroundWindow():
                return helper.int_to_hwnd(101)

            @staticmethod
            def SetCursorPos(x, y):
                calls.append((x, y))
                return True

        original_user32 = helper.user32
        original_window_info = helper.window_info
        try:
            helper.user32 = FakeUser32()
            helper.window_info = lambda _hwnd: {"hwnd": 101, "pid": 202, "title": "Expected application"}
            args = SimpleNamespace(
                x=10,
                y=20,
                require_foreground_pid=202,
                require_foreground_hwnd=101,
            )

            self.assertEqual(0, helper.command_move(args))
            self.assertEqual([(10, 20)], calls)
        finally:
            helper.user32 = original_user32
            helper.window_info = original_window_info

    def test_real_input_command_help_documents_foreground_guards(self) -> None:
        for command in ["move", "click", "press", "tab", "type-text"]:
            with self.subTest(command=command):
                result = self.run_helper(command, "--help")

                self.assertEqual(0, result.returncode, result.stderr)
                self.assertIn("--require-foreground-pid", result.stdout)
                self.assertIn("--require-foreground-hwnd", result.stdout)

    def test_activate_window_resolves_child_to_activatable_root(self) -> None:
        helper = load_helper_module()
        activated = []
        requested = {"hwnd": 501, "pid": 42, "title": "MDI child", "className": "TEditorForm"}
        root = {"hwnd": 500, "pid": 42, "title": "KFZMeister", "className": "TApplication"}

        class FakeUser32:
            # Real MDI activation is session-dependent, so this test fixes only the Win32 identity boundary.
            @staticmethod
            def GetAncestor(hwnd, flag):
                self.assertEqual(2, flag)
                return helper.int_to_hwnd(500 if helper.hwnd_to_int(hwnd) == 501 else 0)

            @staticmethod
            def GetForegroundWindow():
                return helper.int_to_hwnd(500)

        original_user32 = helper.user32
        original_resolve_target_window = helper.resolve_target_window
        original_activate_hwnd = helper.activate_hwnd
        original_window_info = helper.window_info
        try:
            helper.user32 = FakeUser32()
            helper.resolve_target_window = lambda _args: (requested, [requested])
            helper.activate_hwnd = lambda hwnd, _timeout: activated.append(helper.hwnd_to_int(hwnd)) or True
            helper.window_info = lambda hwnd: root if helper.hwnd_to_int(hwnd) == 500 else requested
            args = SimpleNamespace(hwnd=501, pid=None, title_contains=None, timeout_ms=100)
            output = StringIO()
            with redirect_stdout(output):
                result = helper.command_activate_window(args)

            self.assertEqual(0, result)
            self.assertEqual([500], activated)
            payload = json.loads(output.getvalue())
            self.assertEqual(501, payload["requested"]["hwnd"])
            self.assertEqual(500, payload["activated"]["hwnd"])
            self.assertTrue(payload["resolvedToRoot"])
        finally:
            helper.user32 = original_user32
            helper.resolve_target_window = original_resolve_target_window
            helper.activate_hwnd = original_activate_hwnd
            helper.window_info = original_window_info

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

    def test_bridge_form_map_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("bridge-form-map", result.stdout)

    def test_bridge_provider_map_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("bridge-provider-map", result.stdout)

    def test_uia_map_cache_option_is_documented_in_help(self) -> None:
        result = self.run_helper("uia-map", "--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("--cache", result.stdout)
        self.assertIn("--plain", result.stdout)

    def test_uia_map_defaults_to_dotnet_cache_path(self) -> None:
        helper = load_helper_module()
        calls = []

        def fake_command_uia_cache_map(args):
            calls.append(args)
            return 42

        original_command_uia_cache_map = helper.command_uia_cache_map
        helper.command_uia_cache_map = fake_command_uia_cache_map
        try:
            args = type("Args", (), {"cache": False, "plain": False})()

            result = helper.command_uia_map(args)
        finally:
            helper.command_uia_cache_map = original_command_uia_cache_map

        self.assertEqual(42, result)
        self.assertEqual([args], calls)

    def test_bridge_control_info_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("bridge-control-info", result.stdout)

    def test_bridge_controls_info_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("bridge-controls-info", result.stdout)

    def test_bridge_batch_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("bridge-batch", result.stdout)

    def test_win32_map_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("win32-map", result.stdout)

    def test_hwnd_child_windows_stops_at_max_count(self) -> None:
        helper = load_helper_module()
        calls = []

        class FakeUser32:
            def GetWindow(self, hwnd, command):
                value = helper.hwnd_to_int(hwnd)
                calls.append((value, command))
                if command == helper.GW_CHILD:
                    return helper.int_to_hwnd(101)
                if command == helper.GW_HWNDNEXT and value < 110:
                    return helper.int_to_hwnd(value + 1)
                return helper.int_to_hwnd(0)

        original_user32 = helper.user32
        helper.user32 = FakeUser32()
        try:
            children = helper.hwnd_child_windows(helper.int_to_hwnd(100), max_count=3)
        finally:
            helper.user32 = original_user32

        self.assertEqual([101, 102, 103], [helper.hwnd_to_int(child) for child in children])
        self.assertEqual(
            [(100, helper.GW_CHILD), (101, helper.GW_HWNDNEXT), (102, helper.GW_HWNDNEXT)],
            calls,
        )

    def test_fast_map_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("fast-map", result.stdout)

    def test_fast_semantic_map_command_is_documented_in_help(self) -> None:
        result = self.run_helper("--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("fast-semantic-map", result.stdout)

    def test_fast_map_detail_option_is_documented_in_help(self) -> None:
        result = self.run_helper("fast-map", "--help")

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("--detail", result.stdout)

    def test_bridge_window_info_request_uses_handle_target(self) -> None:
        helper = load_helper_module()
        args = type("Args", (), {"target": "handle", "handle": 1234, "name": None})()

        payload = json.loads(helper.build_bridge_window_info_request(args))

        self.assertEqual({"cmd": "window.info", "target": "handle", "handle": 1234}, payload)

    def test_bridge_form_map_request_defaults_to_fast_geometry_visible(self) -> None:
        helper = load_helper_module()
        args = type(
            "Args",
            (),
            {
                "target": "focused",
                "handle": None,
                "name": None,
                "detail": "geometry",
                "include_accessibility": False,
                "all_controls": False,
            },
        )()

        payload = json.loads(helper.build_bridge_form_map_request(args))

        self.assertEqual(
            {
                "cmd": "form.map",
                "target": "focused",
                "detail": "geometry",
                "includeAccessibility": False,
                "visibleOnly": True,
            },
            payload,
        )

    def test_bridge_provider_map_request_defaults_to_bounded_semantic_tree(self) -> None:
        helper = load_helper_module()
        args = type(
            "Args",
            (),
            {
                "target": "handle",
                "handle": 1234,
                "name": None,
                "detail": "full",
                "max_depth": 3,
                "max_children": 200,
            },
        )()

        payload = json.loads(helper.build_bridge_provider_map_request(args))

        self.assertEqual(
            {
                "cmd": "provider.map",
                "target": "handle",
                "handle": 1234,
                "detail": "full",
                "maxDepth": 3,
                "maxChildren": 200,
            },
            payload,
        )

    def test_bridge_control_info_request_defaults_to_native_full_detail(self) -> None:
        helper = load_helper_module()
        args = type(
            "Args",
            (),
            {"ref": "@a2", "detail": "full", "include_accessibility": False},
        )()

        payload = json.loads(helper.build_bridge_control_info_request(args))

        self.assertEqual(
            {
                "cmd": "control.info",
                "ref": "@a2",
                "detail": "full",
                "includeAccessibility": False,
            },
            payload,
        )

    def test_bridge_controls_info_request_batches_refs(self) -> None:
        helper = load_helper_module()
        args = type(
            "Args",
            (),
            {"ref": ["@a1", "@a2"], "detail": "full", "include_accessibility": False},
        )()

        payload = json.loads(helper.build_bridge_controls_info_request(args))

        self.assertEqual(
            {
                "cmd": "controls.info",
                "refs": ["@a1", "@a2"],
                "detail": "full",
                "includeAccessibility": False,
            },
            payload,
        )

    def test_bridge_request_retries_when_pipe_is_between_instances(self) -> None:
        helper = load_helper_module()
        wait_results = [False, False, True]
        writes = []

        class FakePipe:
            def __init__(self) -> None:
                self.response = b'{"ok":true}\n'

            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                return False

            def write(self, data):
                writes.append(data)

            def read(self, size):
                if not self.response:
                    return b""
                data = self.response[:size]
                self.response = self.response[size:]
                return data

            def readline(self):
                data = self.response
                self.response = b""
                return data

        def fake_wait_named_pipe(path, timeout_ms):
            self.assertEqual(r"\\.\pipe\Bridge", path)
            self.assertGreaterEqual(timeout_ms, 0)
            return wait_results.pop(0)

        original_wait_named_pipe = helper.wait_named_pipe
        original_sleep = helper.time.sleep
        helper.wait_named_pipe = fake_wait_named_pipe
        helper.time.sleep = lambda _seconds: None
        try:
            with mock.patch("builtins.open", return_value=FakePipe()):
                result = helper.bridge_request("Bridge", '{"cmd":"hello"}', 1000)
        finally:
            helper.wait_named_pipe = original_wait_named_pipe
            helper.time.sleep = original_sleep

        self.assertEqual({"ok": True}, result)
        self.assertEqual([], wait_results)
        self.assertEqual([b'{"cmd":"hello"}\n'], writes)

    def test_bridge_request_reads_large_response_with_single_line_read(self) -> None:
        helper = load_helper_module()
        writes = []
        byte_reads = []
        line_reads = []
        response = ('{"ok":true,"payload":"' + ("x" * 65536) + '"}\r\n').encode("utf-8")

        class FakePipe:
            def __init__(self) -> None:
                self.response = response

            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                return False

            def write(self, data):
                writes.append(data)

            def read(self, size):
                byte_reads.append(size)
                if not self.response:
                    return b""
                data = self.response[:size]
                self.response = self.response[size:]
                return data

            def readline(self):
                line_reads.append(True)
                data = self.response
                self.response = b""
                return data

        original_wait_named_pipe = helper.wait_named_pipe
        helper.wait_named_pipe = lambda _path, _timeout_ms: True
        try:
            with mock.patch("builtins.open", return_value=FakePipe()):
                result = helper.bridge_request("Bridge", '{"cmd":"map"}', 1000)
        finally:
            helper.wait_named_pipe = original_wait_named_pipe

        self.assertEqual(True, result["ok"])
        self.assertEqual(65536, len(result["payload"]))
        self.assertEqual([b'{"cmd":"map"}\n'], writes)
        self.assertEqual([True], line_reads)
        self.assertEqual([], byte_reads)

    def test_wait_named_pipe_short_timeout_does_not_sleep_past_deadline(self) -> None:
        helper = load_helper_module()
        sleeps = []
        clock = [100.000]

        def fake_sleep(seconds):
            sleeps.append(seconds)
            clock[0] += seconds

        original_wait_named_pipe = helper.wait_named_pipe
        original_monotonic = helper.time.monotonic
        original_sleep = helper.time.sleep
        helper.wait_named_pipe = lambda _path, _timeout_ms: False
        helper.time.monotonic = lambda: clock[0]
        helper.time.sleep = fake_sleep
        try:
            result = helper.wait_named_pipe_until_available(r"\\.\pipe\Missing", 5)
        finally:
            helper.wait_named_pipe = original_wait_named_pipe
            helper.time.monotonic = original_monotonic
            helper.time.sleep = original_sleep

        self.assertFalse(result)
        self.assertTrue(sleeps)
        self.assertLessEqual(max(sleeps), 0.005)

    def test_fast_map_prefers_bridge_geometry_when_pipe_name_available(self) -> None:
        helper = load_helper_module()
        calls = []
        printed = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            calls.append((pipe_name, json.loads(request), timeout_ms))
            return {"ok": True, "cmd": "form.map", "controls": []}

        original_bridge_request = helper.bridge_request
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": "MaxLogicAccessibilityAgentBridge.1234",
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 4,
                    "max_children": 200,
                    "timeout_ms": 123,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(
            [
                (
                    "MaxLogicAccessibilityAgentBridge.1234",
                    {
                        "cmd": "form.map",
                        "target": "focused",
                        "detail": "geometry",
                        "includeAccessibility": False,
                        "visibleOnly": True,
                    },
                    123,
                )
            ],
            calls,
        )
        self.assertEqual("maxlogic-bridge", printed[0]["mapSource"])
        self.assertIn("elapsedMs", printed[0])
        self.assertGreaterEqual(printed[0]["elapsedMs"], 0)

    def test_fast_map_preserves_bridge_elapsed_time(self) -> None:
        helper = load_helper_module()
        printed = []

        def fake_bridge_request(_pipe_name, _request, _timeout_ms):
            return {"ok": True, "cmd": "form.map", "controls": [], "elapsedMs": 4, "elapsedTicks": 40000}

        original_bridge_request = helper.bridge_request
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": "MaxLogicAccessibilityAgentBridge.1234",
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 4,
                    "max_children": 200,
                    "timeout_ms": 123,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(4, printed[0]["bridgeElapsedMs"])
        self.assertGreaterEqual(printed[0]["elapsedMs"], 0)

    def test_fast_map_full_detail_uses_bridge_native_full_snapshot(self) -> None:
        helper = load_helper_module()
        calls = []
        printed = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            calls.append((pipe_name, json.loads(request), timeout_ms))
            return {"ok": True, "cmd": "form.map", "controls": []}

        original_bridge_request = helper.bridge_request
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": "MaxLogicAccessibilityAgentBridge.1234",
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 4,
                    "max_children": 200,
                    "timeout_ms": 123,
                    "detail": "full",
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(
            [
                (
                    "MaxLogicAccessibilityAgentBridge.1234",
                    {
                        "cmd": "form.map",
                        "target": "focused",
                        "detail": "full",
                        "includeAccessibility": False,
                        "visibleOnly": True,
                    },
                    123,
                )
            ],
            calls,
        )
        self.assertEqual("maxlogic-bridge", printed[0]["mapSource"])

    def test_fast_semantic_map_prefers_bridge_provider_tree_when_pipe_name_available(self) -> None:
        helper = load_helper_module()
        calls = []
        printed = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            calls.append((pipe_name, json.loads(request), timeout_ms))
            return {"ok": True, "cmd": "provider.map", "source": "maxlogic-provider", "nodeCount": 12}

        original_bridge_request = helper.bridge_request
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": "MaxLogicAccessibilityAgentBridge.1234",
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 3,
                    "max_children": 200,
                    "timeout_ms": 123,
                    "detail": "full",
                },
            )()

            result = helper.command_fast_semantic_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(
            [
                (
                    "MaxLogicAccessibilityAgentBridge.1234",
                    {
                        "cmd": "provider.map",
                        "target": "focused",
                        "detail": "full",
                        "maxDepth": 3,
                        "maxChildren": 200,
                    },
                    123,
                )
            ],
            calls,
        )
        self.assertEqual("maxlogic-provider", printed[0]["mapSource"])
        self.assertIn("elapsedMs", printed[0])

    def test_fast_semantic_map_falls_back_to_cached_uia_when_bridge_unavailable(self) -> None:
        helper = load_helper_module()
        calls = []

        def fake_bridge_request(_pipe_name, _request, _timeout_ms):
            raise TimeoutError("bridge not available")

        def fake_command_uia_cache_map(args):
            calls.append(args)
            return 77

        original_bridge_request = helper.bridge_request
        original_command_uia_cache_map = helper.command_uia_cache_map
        helper.bridge_request = fake_bridge_request
        helper.command_uia_cache_map = fake_command_uia_cache_map
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": "MaxLogicAccessibilityAgentBridge.1234",
                    "target": "handle",
                    "handle": 4321,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 3,
                    "max_children": 100,
                    "timeout_ms": 123,
                    "detail": "geometry",
                },
            )()

            result = helper.command_fast_semantic_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.command_uia_cache_map = original_command_uia_cache_map

        self.assertEqual(77, result)
        self.assertEqual(1, len(calls))
        self.assertFalse(calls[0].focused)
        self.assertEqual(4321, calls[0].hwnd)
        self.assertEqual("geometry", calls[0].detail)
        self.assertEqual(100, calls[0].max_children)
        self.assertEqual(
            [
                {
                    "source": "maxlogic-provider",
                    "pipeName": "MaxLogicAccessibilityAgentBridge.1234",
                    "ok": False,
                    "error": "bridge not available",
                }
            ],
            calls[0].fallback_attempts,
        )

    def test_fast_semantic_map_auto_bridge_probe_allows_provider_snapshot_time(self) -> None:
        helper = load_helper_module()
        bridge_calls = []
        uia_calls = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            bridge_calls.append((pipe_name, json.loads(request), timeout_ms))
            raise TimeoutError("bridge busy")

        def fake_command_uia_cache_map(args):
            uia_calls.append(args)
            return 77

        original_bridge_request = helper.bridge_request
        original_command_uia_cache_map = helper.command_uia_cache_map
        original_matching_windows = helper.matching_windows
        helper.bridge_request = fake_bridge_request
        helper.command_uia_cache_map = fake_command_uia_cache_map
        helper.matching_windows = lambda _pid, _title_contains, include_title=True: []
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": 4321,
                    "title_contains": None,
                    "max_depth": 3,
                    "max_children": 200,
                    "timeout_ms": 5000,
                    "detail": "full",
                },
            )()

            result = helper.command_fast_semantic_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.command_uia_cache_map = original_command_uia_cache_map
            helper.matching_windows = original_matching_windows

        self.assertEqual(77, result)
        self.assertEqual(1, len(bridge_calls))
        self.assertGreaterEqual(bridge_calls[0][2], 50)
        self.assertEqual(1, len(uia_calls))

    def test_fast_semantic_map_pid_probe_skips_window_enumeration_without_title_filter(self) -> None:
        helper = load_helper_module()
        calls = []
        printed = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            calls.append((pipe_name, json.loads(request), timeout_ms))
            return {"ok": True, "cmd": "provider.map", "source": "maxlogic-provider", "nodeCount": 12}

        def fail_matching_windows(_pid, _title_contains, include_title=True):
            raise AssertionError("PID-only semantic bridge probing should not enumerate native windows.")

        original_bridge_request = helper.bridge_request
        original_matching_windows = helper.matching_windows
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.matching_windows = fail_matching_windows
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": 4321,
                    "title_contains": None,
                    "max_depth": 3,
                    "max_children": 200,
                    "timeout_ms": 5000,
                    "detail": "full",
                },
            )()

            result = helper.command_fast_semantic_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.matching_windows = original_matching_windows
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(
            [
                (
                    "MaxLogicAccessibilityAgentBridge.4321",
                    {
                        "cmd": "provider.map",
                        "target": "focused",
                        "detail": "full",
                        "maxDepth": 3,
                        "maxChildren": 200,
                    },
                    75,
                )
            ],
            calls,
        )
        self.assertTrue(printed[0]["semanticBypass"])

    def test_fast_map_auto_tries_default_bridge_pipe_for_pid(self) -> None:
        helper = load_helper_module()
        calls = []
        printed = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            calls.append((pipe_name, json.loads(request), timeout_ms))
            return {"ok": True, "cmd": "form.map", "controls": []}

        original_bridge_request = helper.bridge_request
        original_matching_windows = helper.matching_windows
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.matching_windows = lambda pid, _title_contains, include_title=True: [
            {"hwnd": 9876, "pid": pid, "title": "Background app"}
        ]
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": 4321,
                    "title_contains": None,
                    "max_depth": 4,
                    "max_children": 200,
                    "timeout_ms": 123,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.matching_windows = original_matching_windows
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(
            [
                (
                    "MaxLogicAccessibilityAgentBridge.4321",
                    {
                        "cmd": "form.map",
                        "target": "handle",
                        "detail": "geometry",
                        "includeAccessibility": False,
                        "visibleOnly": True,
                        "handle": 9876,
                    },
                    5,
                )
            ],
            calls,
        )
        self.assertEqual("maxlogic-bridge", printed[0]["mapSource"])

    def test_fast_map_auto_bridge_fallback_uses_short_probe_timeout(self) -> None:
        helper = load_helper_module()
        bridge_calls = []
        win32_calls = []
        printed = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            bridge_calls.append((pipe_name, json.loads(request), timeout_ms))
            raise RuntimeError("Named pipe is not available.")

        def fake_build_win32_map_response(args):
            win32_calls.append(args)
            return {"ok": True, "source": "win32", "nodeCount": 1, "root": {"hwnd": 42}}

        original_bridge_request = helper.bridge_request
        original_build_win32_map_response = helper.build_win32_map_response
        original_matching_windows = helper.matching_windows
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.build_win32_map_response = fake_build_win32_map_response
        helper.matching_windows = lambda _pid, _title_contains, include_title=True: []
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": 4321,
                    "title_contains": None,
                    "max_depth": 4,
                    "max_children": 200,
                    "timeout_ms": 5000,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.build_win32_map_response = original_build_win32_map_response
            helper.matching_windows = original_matching_windows
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(1, len(bridge_calls))
        self.assertLessEqual(bridge_calls[0][2], 5)
        self.assertEqual(1, len(win32_calls))
        self.assertEqual("win32", printed[0]["mapSource"])
        self.assertEqual("geometry", win32_calls[0].detail)

    def test_fast_map_auto_tries_default_bridge_pipe_for_handle_target(self) -> None:
        helper = load_helper_module()
        calls = []
        printed = []

        def fake_bridge_request(pipe_name, request, timeout_ms):
            calls.append((pipe_name, json.loads(request), timeout_ms))
            return {"ok": True, "cmd": "form.map", "controls": []}

        original_bridge_request = helper.bridge_request
        original_get_window_pid_and_thread = helper.get_window_pid_and_thread
        original_print_json = helper.print_json
        helper.bridge_request = fake_bridge_request
        helper.get_window_pid_and_thread = lambda _hwnd: (2468, 9)
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "handle",
                    "handle": 1234,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 4,
                    "max_children": 200,
                    "timeout_ms": 123,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.get_window_pid_and_thread = original_get_window_pid_and_thread
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual(
            [
                (
                    "MaxLogicAccessibilityAgentBridge.2468",
                    {
                        "cmd": "form.map",
                        "target": "handle",
                        "detail": "geometry",
                        "includeAccessibility": False,
                        "visibleOnly": True,
                        "handle": 1234,
                    },
                    5,
                )
            ],
            calls,
        )
        self.assertEqual("maxlogic-bridge", printed[0]["mapSource"])

    def test_fast_map_auto_tries_default_bridge_pipe_for_focused_window(self) -> None:
        helper = load_helper_module()
        calls = []
        printed = []

        class FakeUser32:
            @staticmethod
            def GetForegroundWindow():
                return 3456

        def fake_bridge_request(pipe_name, request, timeout_ms):
            calls.append((pipe_name, json.loads(request), timeout_ms))
            return {"ok": True, "cmd": "form.map", "controls": []}

        original_bridge_request = helper.bridge_request
        original_get_window_pid_and_thread = helper.get_window_pid_and_thread
        original_print_json = helper.print_json
        original_user32 = helper.user32
        helper.bridge_request = fake_bridge_request
        helper.get_window_pid_and_thread = lambda _hwnd: (1357, 9)
        helper.print_json = lambda payload: printed.append(payload)
        helper.user32 = FakeUser32()
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 4,
                    "max_children": 200,
                    "timeout_ms": 123,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.bridge_request = original_bridge_request
            helper.get_window_pid_and_thread = original_get_window_pid_and_thread
            helper.print_json = original_print_json
            helper.user32 = original_user32

        self.assertEqual(0, result)
        self.assertEqual(
            [
                (
                    "MaxLogicAccessibilityAgentBridge.1357",
                    {
                        "cmd": "form.map",
                        "target": "handle",
                        "detail": "geometry",
                        "includeAccessibility": False,
                        "visibleOnly": True,
                        "handle": 3456,
                    },
                    5,
                )
            ],
            calls,
        )
        self.assertEqual("maxlogic-bridge", printed[0]["mapSource"])

    def test_fast_map_uses_win32_without_bridge_pipe(self) -> None:
        helper = load_helper_module()
        printed = []
        calls = []

        def fake_build_win32_map_response(args):
            calls.append(args)
            return {"ok": True, "source": "win32", "nodeCount": 1, "root": {"hwnd": 42}}

        original_build_win32_map_response = helper.build_win32_map_response
        original_print_json = helper.print_json
        helper.build_win32_map_response = fake_build_win32_map_response
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 3,
                    "max_children": 50,
                    "timeout_ms": 5000,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.build_win32_map_response = original_build_win32_map_response
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual("win32", printed[0]["mapSource"])
        self.assertIn("elapsedMs", printed[0])
        self.assertGreaterEqual(printed[0]["elapsedMs"], 0)
        self.assertEqual(1, printed[0]["nodeCount"])
        self.assertEqual("geometry", calls[0].detail)

    def test_fast_map_full_detail_preserves_detail_for_win32_fallback(self) -> None:
        helper = load_helper_module()
        printed = []
        calls = []

        def fake_build_win32_map_response(args):
            calls.append(args)
            return {"ok": True, "source": "win32", "detail": args.detail, "nodeCount": 1, "root": {"hwnd": 42}}

        original_build_win32_map_response = helper.build_win32_map_response
        original_print_json = helper.print_json
        helper.build_win32_map_response = fake_build_win32_map_response
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "focused",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 3,
                    "max_children": 50,
                    "timeout_ms": 5000,
                    "detail": "full",
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.build_win32_map_response = original_build_win32_map_response
            helper.print_json = original_print_json

        self.assertEqual(0, result)
        self.assertEqual("win32", printed[0]["mapSource"])
        self.assertEqual("full", calls[0].detail)
        self.assertEqual("full", printed[0]["detail"])

    def test_win32_map_geometry_detail_skips_window_text(self) -> None:
        helper = load_helper_module()
        target_include_title = []

        class FakeUser32:
            @staticmethod
            def IsWindowVisible(_hwnd):
                return True

            @staticmethod
            def IsWindowEnabled(_hwnd):
                return True

        def fake_get_window_text(_hwnd):
            raise AssertionError("geometry win32 maps should not read HWND text")

        def fake_target_or_foreground_window(args, include_title=True):
            target_include_title.append(include_title)
            return {"hwnd": 42, "pid": 7, "threadId": 8, "title": "", "className": "Root"}, []

        original_user32 = helper.user32
        original_get_window_text = helper.get_window_text
        original_target_or_foreground_window = helper.target_or_foreground_window
        original_get_window_pid_and_thread = helper.get_window_pid_and_thread
        original_get_window_rect = helper.get_window_rect
        original_get_class_name = helper.get_class_name
        original_hwnd_child_windows = helper.hwnd_child_windows
        helper.user32 = FakeUser32()
        helper.get_window_text = fake_get_window_text
        helper.target_or_foreground_window = fake_target_or_foreground_window
        helper.get_window_pid_and_thread = lambda _hwnd: (7, 8)
        helper.get_window_rect = lambda _hwnd: {"left": 1, "top": 2, "right": 11, "bottom": 22, "width": 10, "height": 20}
        helper.get_class_name = lambda _hwnd: "FakeClass"
        helper.hwnd_child_windows = lambda _hwnd, _max_count=None: []
        try:
            args = type(
                "Args",
                (),
                {
                    "focused": False,
                    "hwnd": 42,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 1,
                    "max_children": 20,
                    "detail": "geometry",
                },
            )()

            payload = helper.build_win32_map_response(args)
        finally:
            helper.user32 = original_user32
            helper.get_window_text = original_get_window_text
            helper.target_or_foreground_window = original_target_or_foreground_window
            helper.get_window_pid_and_thread = original_get_window_pid_and_thread
            helper.get_window_rect = original_get_window_rect
            helper.get_class_name = original_get_class_name
            helper.hwnd_child_windows = original_hwnd_child_windows

        self.assertEqual("geometry", payload["detail"])
        self.assertEqual([False], target_include_title)
        self.assertNotIn("title", payload["root"])

    def test_uia_map_payload_marks_slow_semantic_path(self) -> None:
        helper = load_helper_module()
        printed = []

        class FakeRect:
            left = 1
            top = 2
            right = 11
            bottom = 22

        class FakeControl:
            Name = "Root"
            AutomationId = "root"
            ClassName = "FakeWindow"
            ControlTypeName = "WindowControl"
            HasKeyboardFocus = True
            IsEnabled = True
            BoundingRectangle = FakeRect()

            def GetChildren(self):
                return []

        class FakeAutomation:
            @staticmethod
            def GetFocusedControl():
                return FakeControl()

            @staticmethod
            def GetRootControl():
                return FakeControl()

        original_module = sys.modules.get("uiautomation")
        original_print_json = helper.print_json
        sys.modules["uiautomation"] = FakeAutomation
        helper.print_json = lambda payload: printed.append(payload)
        try:
            args = type("Args", (), {"focused": True, "max_depth": 1, "plain": True})()

            result = helper.command_uia_map(args)
        finally:
            helper.print_json = original_print_json
            if original_module is None:
                del sys.modules["uiautomation"]
            else:
                sys.modules["uiautomation"] = original_module

        self.assertEqual(0, result)
        self.assertTrue(printed[0]["slowSemanticPath"])
        self.assertEqual("semanticVerification", printed[0]["recommendedFor"])
        self.assertIn("coordinateDiscovery", printed[0]["notRecommendedFor"])
        self.assertIn("fast-map", printed[0]["fasterAlternatives"])
        self.assertIn("bridge-form-map", printed[0]["fasterAlternatives"])
        self.assertIn("bridge-provider-map", printed[0]["fasterAlternatives"])
        self.assertIn("win32-map --detail geometry", printed[0]["fasterAlternatives"])
        self.assertIn("elapsedMs", printed[0])
        self.assertGreaterEqual(printed[0]["elapsedMs"], 0)

    def test_uia_map_elapsed_time_includes_tree_materialization(self) -> None:
        helper = load_helper_module()
        printed = []
        elapsed_started = [False]
        tree_materialized = [False]
        control_calls = []

        class FakeControl:
            pass

        class FakeAutomation:
            @staticmethod
            def GetFocusedControl():
                return FakeControl()

        def fake_control_to_dict(control, depth, max_depth, max_children, detail="full"):
            control_calls.append((control, depth, max_depth, max_children, detail))
            tree_materialized[0] = True
            return {"name": "Root", "children": []}

        def fake_perf_counter():
            if not elapsed_started[0]:
                elapsed_started[0] = True
                return 1.0
            if tree_materialized[0]:
                return 1.5
            return 1.1

        original_module = sys.modules.get("uiautomation")
        original_print_json = helper.print_json
        original_perf_counter = helper.time.perf_counter
        original_control_to_dict = helper.control_to_dict
        sys.modules["uiautomation"] = FakeAutomation
        helper.print_json = lambda payload: printed.append(payload)
        helper.time.perf_counter = fake_perf_counter
        helper.control_to_dict = fake_control_to_dict
        try:
            args = type("Args", (), {"focused": True, "max_depth": 1, "max_children": 20, "plain": True})()

            result = helper.command_uia_map(args)
        finally:
            helper.print_json = original_print_json
            helper.time.perf_counter = original_perf_counter
            helper.control_to_dict = original_control_to_dict
            if original_module is None:
                del sys.modules["uiautomation"]
            else:
                sys.modules["uiautomation"] = original_module

        self.assertEqual(0, result)
        self.assertEqual(500.0, printed[0]["elapsedMs"])
        self.assertEqual(1, len(control_calls))
        self.assertEqual("full", control_calls[0][4])

    def test_uia_map_can_start_from_resolved_hwnd(self) -> None:
        helper = load_helper_module()
        printed = []
        calls = []

        class FakeRect:
            left = 1
            top = 2
            right = 11
            bottom = 22

        class FakeControl:
            Name = "FromHandle"
            AutomationId = "from-handle"
            ClassName = "FakeWindow"
            ControlTypeName = "WindowControl"
            HasKeyboardFocus = False
            IsEnabled = True
            BoundingRectangle = FakeRect()

            def GetChildren(self):
                return []

        class FakeAutomation:
            @staticmethod
            def ControlFromHandle(hwnd):
                calls.append(hwnd)
                return FakeControl()

        def fake_resolve_target_window(args):
            return {"hwnd": 1234}, [{"hwnd": 1234}]

        original_module = sys.modules.get("uiautomation")
        original_print_json = helper.print_json
        original_resolve_target_window = helper.resolve_target_window
        sys.modules["uiautomation"] = FakeAutomation
        helper.print_json = lambda payload: printed.append(payload)
        helper.resolve_target_window = fake_resolve_target_window
        try:
            args = type(
                "Args",
                (),
                {
                    "focused": False,
                    "hwnd": 1234,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 1,
                    "max_children": 20,
                    "plain": True,
                },
            )()

            result = helper.command_uia_map(args)
        finally:
            helper.print_json = original_print_json
            helper.resolve_target_window = original_resolve_target_window
            if original_module is None:
                del sys.modules["uiautomation"]
            else:
                sys.modules["uiautomation"] = original_module

        self.assertEqual(0, result)
        self.assertEqual([1234], calls)
        self.assertEqual("FromHandle", printed[0]["root"]["name"])
        self.assertEqual([{"hwnd": 1234}], printed[0]["matches"])

    def test_uia_map_command_passes_geometry_detail_to_tree_materialization(self) -> None:
        helper = load_helper_module()
        printed = []
        details = []

        class FakeControl:
            pass

        class FakeAutomation:
            @staticmethod
            def GetFocusedControl():
                return FakeControl()

        def fake_control_to_dict(control, depth, max_depth, max_children, detail="full"):
            details.append(detail)
            return {"rect": {"left": 1, "top": 2, "right": 11, "bottom": 22, "width": 10, "height": 20}}

        original_module = sys.modules.get("uiautomation")
        original_print_json = helper.print_json
        original_control_to_dict = helper.control_to_dict
        sys.modules["uiautomation"] = FakeAutomation
        helper.print_json = lambda payload: printed.append(payload)
        helper.control_to_dict = fake_control_to_dict
        try:
            args = type(
                "Args",
                (),
                {"focused": True, "max_depth": 1, "max_children": 20, "detail": "geometry", "plain": True},
            )()

            result = helper.command_uia_map(args)
        finally:
            helper.print_json = original_print_json
            helper.control_to_dict = original_control_to_dict
            if original_module is None:
                del sys.modules["uiautomation"]
            else:
                sys.modules["uiautomation"] = original_module

        self.assertEqual(0, result)
        self.assertEqual(["geometry"], details)
        self.assertEqual("geometry", printed[0]["detail"])

    def test_uia_map_cache_mode_uses_dotnet_cache_request(self) -> None:
        helper = load_helper_module()
        printed = []
        calls = []

        def fake_resolve_target_window(args):
            return {"hwnd": 1234}, [{"hwnd": 1234}]

        def fake_run(command, check, capture_output, text, timeout):
            calls.append((command, check, capture_output, text, timeout))
            return subprocess.CompletedProcess(
                command,
                0,
                stdout='{"root":{"name":"CachedRoot"},"nodeCount":1}',
                stderr="",
            )

        original_print_json = helper.print_json
        original_resolve_target_window = helper.resolve_target_window
        original_run = helper.subprocess.run
        helper.print_json = lambda payload: printed.append(payload)
        helper.resolve_target_window = fake_resolve_target_window
        helper.subprocess.run = fake_run
        try:
            args = type(
                "Args",
                (),
                {
                    "cache": True,
                    "focused": False,
                    "hwnd": 1234,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 2,
                    "max_children": 20,
                    "detail": "full",
                    "timeout_ms": 2500,
                },
            )()

            result = helper.command_uia_map(args)
        finally:
            helper.print_json = original_print_json
            helper.resolve_target_window = original_resolve_target_window
            helper.subprocess.run = original_run

        self.assertEqual(0, result)
        self.assertEqual(1, len(calls))
        self.assertIn("powershell", calls[0][0][0].lower())
        self.assertIn("CacheRequest", calls[0][0][-1])
        self.assertEqual(2.5, calls[0][4])
        self.assertEqual("uia-dotnet-cache", printed[0]["source"])
        self.assertTrue(printed[0]["cache"])
        self.assertEqual("CachedRoot", printed[0]["root"]["name"])
        self.assertEqual(1, printed[0]["nodeCount"])
        self.assertEqual({"hwnd": 1234}, printed[0]["target"])
        self.assertEqual([{"hwnd": 1234}], printed[0]["matches"])

    def test_uia_cache_map_exposes_fallback_attempts(self) -> None:
        helper = load_helper_module()
        printed = []

        def fake_run(command, check, capture_output, text, timeout):
            return subprocess.CompletedProcess(
                command,
                0,
                stdout='{"root":{"name":"CachedRoot"},"nodeCount":1}',
                stderr="",
            )

        original_print_json = helper.print_json
        original_run = helper.subprocess.run
        helper.print_json = lambda payload: printed.append(payload)
        helper.subprocess.run = fake_run
        try:
            args = type(
                "Args",
                (),
                {
                    "focused": True,
                    "max_depth": 2,
                    "max_children": 20,
                    "detail": "full",
                    "timeout_ms": 2500,
                    "fallback_attempts": [{"source": "maxlogic-provider", "ok": False, "error": "timeout"}],
                },
            )()

            result = helper.command_uia_cache_map(args)
        finally:
            helper.print_json = original_print_json
            helper.subprocess.run = original_run

        self.assertEqual(0, result)
        self.assertEqual([{"source": "maxlogic-provider", "ok": False, "error": "timeout"}],
                         printed[0]["fallbackAttempts"])

    def test_uia_cache_map_geometry_script_skips_semantic_property_cache(self) -> None:
        helper = load_helper_module()

        script = helper.build_uia_cache_map_script(1234, False, 2, 20, "geometry")

        self.assertIn("BoundingRectangleProperty", script)
        self.assertNotIn("NameProperty", script)
        self.assertNotIn("AutomationIdProperty", script)
        self.assertNotIn("ClassNameProperty", script)
        self.assertNotIn("ControlTypeProperty", script)
        self.assertNotIn("HasKeyboardFocusProperty", script)
        self.assertNotIn("IsEnabledProperty", script)

    def test_uia_cache_map_script_passes_cache_request_to_tree_walker(self) -> None:
        helper = load_helper_module()

        script = helper.build_uia_cache_map_script(1234, False, 2, 20, "full")

        self.assertIn("$script:lRequest = $lRequest", script)
        self.assertIn("$script:lWalker.GetFirstChild($aElement, $script:lRequest)", script)
        self.assertIn("$script:lWalker.GetNextSibling($lChild, $script:lRequest)", script)
        self.assertNotIn("$script:lWalker.GetFirstChild($aElement)\n", script)
        self.assertNotIn("$script:lWalker.GetNextSibling($lChild)\n", script)

    def test_uia_map_caps_children_per_node(self) -> None:
        helper = load_helper_module()

        class FakeRect:
            left = 1
            top = 2
            right = 11
            bottom = 22

        class FakeControl:
            def __init__(self, name, children=None):
                self.Name = name
                self.AutomationId = name.lower()
                self.ClassName = "Fake"
                self.ControlTypeName = "PaneControl"
                self.HasKeyboardFocus = False
                self.IsEnabled = True
                self.BoundingRectangle = FakeRect()
                self._children = children or []

            def GetChildren(self):
                return self._children

        root = FakeControl("Root", [FakeControl("One"), FakeControl("Two"), FakeControl("Three")])

        payload = helper.control_to_dict(root, 0, 1, 2)

        self.assertEqual(["One", "Two"], [child["name"] for child in payload["children"]])
        self.assertEqual(3, payload["childCount"])
        self.assertTrue(payload["childrenTruncated"])

    def test_uia_map_stops_sibling_walk_after_max_children(self) -> None:
        helper = load_helper_module()
        visited_siblings = []

        class FakeRect:
            left = 1
            top = 2
            right = 11
            bottom = 22

        class FakeControl:
            BoundingRectangle = FakeRect()

            def __init__(self, name, children=None):
                self.name = name
                self._children = children or []
                self._next = None
                for index, child in enumerate(self._children):
                    child._next = self._children[index + 1] if index + 1 < len(self._children) else None

            def GetChildren(self):
                raise AssertionError("Capped UIA maps should not materialize every child before truncating.")

            def GetFirstChildControl(self):
                if not self._children:
                    return None
                return self._children[0]

            def GetNextSiblingControl(self):
                visited_siblings.append(self.name)
                return self._next

        root = FakeControl(
            "Root",
            [
                FakeControl("One"),
                FakeControl("Two"),
                FakeControl("Three"),
                FakeControl("Four"),
            ],
        )

        payload = helper.control_to_dict(root, 0, 1, 2, "geometry")

        self.assertEqual(3, payload["childCount"])
        self.assertTrue(payload["childrenTruncated"])
        self.assertEqual(2, len(payload["children"]))
        self.assertEqual(["One", "Two"], visited_siblings)

    def test_uia_map_geometry_detail_skips_semantic_property_reads(self) -> None:
        helper = load_helper_module()
        semantic_accesses = []

        class FakeRect:
            left = 1
            top = 2
            right = 11
            bottom = 22

        class FakeControl:
            BoundingRectangle = FakeRect()

            def __init__(self, children=None):
                self._children = children or []

            @property
            def Name(self):
                semantic_accesses.append("Name")
                raise AssertionError("Geometry detail should not read UIA Name.")

            @property
            def AutomationId(self):
                semantic_accesses.append("AutomationId")
                raise AssertionError("Geometry detail should not read UIA AutomationId.")

            @property
            def ClassName(self):
                semantic_accesses.append("ClassName")
                raise AssertionError("Geometry detail should not read UIA ClassName.")

            @property
            def ControlTypeName(self):
                semantic_accesses.append("ControlTypeName")
                raise AssertionError("Geometry detail should not read UIA ControlTypeName.")

            @property
            def HasKeyboardFocus(self):
                semantic_accesses.append("HasKeyboardFocus")
                raise AssertionError("Geometry detail should not read UIA focus state.")

            @property
            def IsEnabled(self):
                semantic_accesses.append("IsEnabled")
                raise AssertionError("Geometry detail should not read UIA enabled state.")

            def GetChildren(self):
                return self._children

        root = FakeControl([FakeControl()])

        payload = helper.control_to_dict(root, 0, 1, 20, "geometry")

        self.assertEqual([], semantic_accesses)
        self.assertEqual({"left": 1, "top": 2, "right": 11, "bottom": 22, "width": 10, "height": 20}, payload["rect"])
        self.assertEqual(1, payload["childCount"])
        self.assertEqual(1, len(payload["children"]))
        self.assertNotIn("name", payload)
        self.assertNotIn("automationId", payload)

    def test_fast_map_rejects_missing_handle_target(self) -> None:
        helper = load_helper_module()
        calls = []

        def fake_build_win32_map_response(args):
            calls.append(args)
            return {"ok": True, "source": "win32"}

        original_build_win32_map_response = helper.build_win32_map_response
        helper.build_win32_map_response = fake_build_win32_map_response
        try:
            args = type(
                "Args",
                (),
                {
                    "pipe_name": None,
                    "target": "handle",
                    "handle": None,
                    "name": None,
                    "pid": None,
                    "title_contains": None,
                    "max_depth": 3,
                    "max_children": 50,
                    "timeout_ms": 5000,
                },
            )()

            result = helper.command_fast_map(args)
        finally:
            helper.build_win32_map_response = original_build_win32_map_response

        self.assertEqual(1, result)
        self.assertEqual([], calls)

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

    def test_win32_map_returns_foreground_hwnd_tree(self) -> None:
        foreground = self.run_helper("foreground-window")
        self.assertEqual(0, foreground.returncode, foreground.stderr)
        window = json.loads(foreground.stdout)["window"]

        result = self.run_helper("win32-map", "--focused", "--max-depth", "1")

        self.assertEqual(0, result.returncode, result.stderr)
        payload = json.loads(result.stdout)
        self.assertTrue(payload["ok"])
        self.assertEqual("win32", payload["source"])
        self.assertEqual(window["hwnd"], payload["root"]["hwnd"])
        self.assertGreaterEqual(payload["nodeCount"], 1)
        self.assertIn("children", payload["root"])


if __name__ == "__main__":
    unittest.main()
