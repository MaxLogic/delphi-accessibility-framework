---
name: windows-desktop-control
description: Control Windows desktop applications from Codex with explicit takeover/release audio announcements, mouse and keyboard input, optional UIA inspection, and optional MaxLogic Accessibility Agent Bridge support. Use when a task asks to drive a local Windows app, test accessibility behavior, collect spoken-screen-reader evidence, move/click/type/tab through controls, or coordinate UIA with an app-specific diagnostic bridge.
---

# Windows Desktop Control

## Core Rule

Before touching the user's mouse or keyboard, announce takeover and wait three seconds. When finished, announce release.

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

If the active Codex runtime exposes a first-class computer-control tool, prefer that for screenshots and pointer control. Still use this skill's announcement workflow, bridge protocol, and evidence rules.

## Decision Order

1. Use the app's MaxLogic bridge if available. It gives process-local form/control maps and coordinates without trusting UIA as the only source.
2. Use UIA to cross-check generic apps or to compare actual accessibility output.
3. Activate and verify the intended foreground window before sending input.
4. Use Win32 pointer/keyboard commands for real user input.
5. Use screenshots/manual coordinates only when bridge and UIA are not enough.

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
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-request --pipe-name MaxLogicAccessibilityAgentBridge.1234 --request '{"cmd":"forms.list"}'

# Foreground safety.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py foreground-window
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py activate-window --pid 12345

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

## MaxLogic Bridge Workflow

Probe first:

```powershell
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py probe-bridge --pipe-name <name>
```

If the response is a successful `hello`, use:

- `{"cmd":"forms.list"}` to identify visible forms.
- `{"cmd":"form.map","target":"focused"}` or `target:name/handle` to get controls, captions, refs, state, screen rectangles, and target points.
- `{"cmd":"hitTest","x":500,"y":300}` to map a screen point back to the framework snapshot.
- Mutation commands only when the app has explicitly enabled them.

For user-realistic tests, prefer OS input for actions (`click`, `type-text`, `tab`) and use bridge responses to choose coordinates and verify state.

Before each OS input batch, use `activate-window --pid <processId>` for the target process and verify `foreground-window` reports that same PID. If activation fails, do not click or type; collect bridge/UIA evidence instead and report the blocker.

## Speech Evidence

If NVDA or another screen reader is involved:

- Keep the takeover/release announcements in the transcript so the user knows when control changed.
- Prefer the user's configured speech log or Shadow Journal database when available.
- Keep logs readable while the app is running; do not require exclusive locks.
- Compare three streams when possible: bridge/control map, UIA view, and spoken transcript.

## Safety

Never control the desktop silently. Do not continue if the takeover announcement fails unless the user explicitly allows a silent run. Do not leave the pointer/keyboard under automation without the release announcement.
