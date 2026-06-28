---
name: windows-desktop-control
description: Control Windows desktop applications from Codex in foreground or background mode, with explicit takeover/release announcements for foreground mouse/keyboard control, window screenshots, optional UIA inspection, Win32 input/messages, and optional MaxLogic Accessibility Agent Bridge support. Use when a task asks to drive a local Windows app, inspect or screenshot a window, test accessibility behavior, collect spoken screen-reader evidence, move/click/type/tab through controls, or coordinate UIA with an app-specific diagnostic bridge.
---

# Windows Desktop Control

## Core Rule

Choose the drive mode before acting:

- **Foreground Drive Mode**: the automation uses the application like a human user would. It may activate the target window and use the real mouse and keyboard.
- **Background Drive Mode**: the automation avoids stealing focus. It uses bridge commands, UIA patterns, Win32 messages, and screenshots where those are sufficient.

Before touching the user's mouse or keyboard in Foreground Drive Mode, announce takeover and wait three seconds. When finished, announce release. Background Drive Mode does not need audio announcements because it must not take over the user's input devices.

Use the bundled helper:

```powershell
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py takeover
```

Always wrap control sessions in a `try/finally` pattern:

```powershell
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py takeover
# inspect and control the app
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py release
```

If the active Codex runtime exposes a first-class computer-control tool, prefer that for pointer control when it is safer or more capable. Still use this skill's announcement workflow, bridge protocol, screenshot commands, and evidence rules.

## Decision Order

1. Identify whether the task needs Foreground Drive Mode or Background Drive Mode.
2. Use the app's MaxLogic bridge if available. It gives process-local form/control maps and coordinates without trusting UIA as the only source.
3. Use UIA to inspect and operate generic applications, or to compare actual accessibility output.
4. Use Win32 messages and UIA patterns for Background Drive Mode when they preserve the app's intended behavior.
5. Activate and verify the intended foreground window before sending real mouse/keyboard input.
6. Use screenshots as evidence and for visual targeting when structured APIs are not enough.

When UIA is the thing under test, do not use UIA as the only source of target coordinates. Prefer bridge `form.map` target points or another non-UIA geometry source, then use UIA only as a cross-check.

## Helper Script

`scripts/windows_desktop_control.py` is dependency-light. Critical commands use Python stdlib plus Win32 APIs. UIA enumeration is optional and requires the `uiautomation` Python package.

Useful commands:

```powershell
# Audio safety announcements. Plays bundled Bella WAV assets; no runtime TTS call.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py takeover
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py release
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py announce --asset takeover

# MaxLogic bridge. Pipe name may be either a plain name or \\.\pipe\name.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py probe-bridge --pipe-name MaxLogicAccessibilityAgentBridge.1234
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-window-info --pipe-name MaxLogicAccessibilityAgentBridge.1234 --target focused
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-request --pipe-name MaxLogicAccessibilityAgentBridge.1234 --request '{"cmd":"forms.list"}'

# Foreground safety.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py foreground-window
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py activate-window --pid 12345

# Window screenshot. Does not activate the target window.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py screenshot-window --pid 12345 --output .\.agents\runs\window.bmp
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py screenshot-window --title-contains "Settings" --output .\.agents\runs\settings.bmp

# Generic Windows input.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py move --x 500 --y 300
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py click --x 500 --y 300
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py type-text --text "hello"
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py tab
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py tab --shift

# Optional UIA inspection.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py uia-map --focused --max-depth 4
```

Use `--dry-run` on announcement commands when validating the skill without speaking. The announcement files live in `assets/announcements/` and are generated once with ElevenLabs Bella; the helper must not call ElevenLabs or any other TTS provider at runtime.

## Foreground Drive Mode

Use Foreground Drive Mode when the task needs human-equivalent behavior: normal focus, pointer movement, keyboard input, menus, popups, accelerators, modal flow, or any behavior likely to depend on the active window. This mode is also appropriate for screen-reader verification, but it is not limited to screen-reader work.

Workflow:

1. Run `takeover`.
2. Start or identify the target app.
3. Use `activate-window --pid <processId>` or `--hwnd <handle>`.
4. Verify `foreground-window` reports the expected target before every input batch.
5. Use bridge/UIA/window screenshots to choose coordinates.
6. Use `move`, `click`, `press`, `tab`, or `type-text`.
7. Run `release` in a `finally` block.

If foreground activation fails, do not click or type. Report the blocker and continue with Background Drive Mode evidence if that can still answer the task.

## Background Drive Mode

Use Background Drive Mode when the user should be able to keep working while automation inspects or drives the target application. Prefer this mode for non-disruptive state inspection, workflow smoke tests, form filling, and deterministic bridge/UIA operations.

Background Drive Mode can use:

- MaxLogic bridge requests such as `form.map`, `hitTest`, `control.focus`, `control.click`, `control.setText`, `control.typeText`, and `keyboard.tab` when mutations are explicitly enabled.
- UIA patterns such as Invoke, Toggle, SelectionItem, Value, and Text when available.
- Win32 messages for HWND-backed controls when the app is known to behave correctly without foreground focus.
- `screenshot-window` for visual evidence without activating the target window.

Do not claim background results are human-equivalent. Some applications intentionally behave differently when inactive; focus, capture, menus, accelerators, IME, and screen-reader tracking often need Foreground Drive Mode.

## Screenshots

Use target-window screenshots rather than full desktop screenshots when possible. Prefer:

```powershell
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py screenshot-window --hwnd <handle> --output <path>
```

The command returns JSON with the selected window metadata, capture method, size, and output path. Store screenshots under a predictable artifact folder such as `.agents\runs\`. If the MaxLogic bridge is available, use `forms.list` or `form.map` to get the HWND and control rectangles, then capture the window through the helper.

## MaxLogic Bridge Workflow

Probe first:

```powershell
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py probe-bridge --pipe-name <name>
```

If the response is a successful `hello`, use:

- `{"cmd":"forms.list"}` to identify visible forms.
- `bridge-window-info` or `{"cmd":"window.info","target":"focused"}` to get form handle, screen/client rectangles, DPI, and window state for screenshots and coordinate-sensitive automation.
- `{"cmd":"form.map","target":"focused"}` or `target:name/handle` to get controls, captions, refs, state, screen rectangles, and target points.
- `{"cmd":"hitTest","x":500,"y":300}` to map a screen point back to the framework snapshot.
- Mutation commands only when the app has explicitly enabled them.

For user-realistic Foreground Drive Mode tests, prefer OS input for actions (`click`, `type-text`, `tab`) and use bridge responses to choose coordinates and verify state. For Background Drive Mode, bridge mutation commands are acceptable when mutations are explicitly enabled and the test goal is application control rather than human-equivalent input.

Before each OS input batch, use `activate-window --pid <processId>` for the target process and verify `foreground-window` reports that same PID. If activation fails, do not click or type; collect bridge/UIA evidence instead and report the blocker.

## Speech Evidence

If NVDA or another screen reader is involved:

- Keep the takeover/release announcements in the transcript so the user knows when control changed.
- Prefer the user's configured speech log or screen-reader transcript source when available.
- Keep logs readable while the app is running; do not require exclusive locks.
- Compare three streams when possible: bridge/control map, UIA view, and spoken transcript.
- Do not mention machine-local evidence stores in this skill; keep the instructions portable across machines.

## Safety

Never control the desktop silently in Foreground Drive Mode. Do not continue if the takeover announcement fails unless the user explicitly allows a silent run. Do not leave the pointer/keyboard under automation without the release announcement. In Background Drive Mode, avoid focus stealing and prefer commands that target explicit HWNDs, PIDs, bridge refs, or UIA elements.
