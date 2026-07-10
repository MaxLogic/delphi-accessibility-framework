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
2. Use the app's MaxLogic bridge if available. It gives process-local form/control maps, UIA-equivalent roles, native control state, and coordinates without trusting UIA as the only source.
3. For generic HWND-backed applications, use `win32-map` for cheap title/class/rectangle discovery before using UIA.
4. Use UIA to inspect virtual/non-HWND elements, operate UIA patterns, or compare actual accessibility output.
5. Use Win32 messages and UIA patterns for Background Drive Mode when they preserve the app's intended behavior.
6. Activate and verify the intended foreground window before sending real mouse/keyboard input.
7. Use screenshots as evidence and for visual targeting when structured APIs are not enough.

When UIA is the thing under test, do not use UIA as the only source of target coordinates. Prefer bridge `form.map` target points, `win32-map` HWND rectangles, or another non-UIA geometry source, then use UIA only as a cross-check.

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
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-form-map --pipe-name MaxLogicAccessibilityAgentBridge.1234
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-controls-info --pipe-name MaxLogicAccessibilityAgentBridge.1234 --ref @a1 --ref @a2
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py fast-map --pipe-name MaxLogicAccessibilityAgentBridge.1234
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py fast-map --pid 1234
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py fast-semantic-map --pid 1234 --max-depth 3 --max-children 200
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-request --pipe-name MaxLogicAccessibilityAgentBridge.1234 --request '{"cmd":"forms.list"}'
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-batch --pipe-name MaxLogicAccessibilityAgentBridge.1234 --request '{"cmd":"window.info","target":"focused"}' --request '{"cmd":"form.map","target":"focused","detail":"geometry","visibleOnly":true}'

# Foreground safety.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py foreground-window
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py activate-window --pid 12345

# Window screenshot. Does not activate the target window.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py screenshot-window --pid 12345 --output .\.agents\runs\window.bmp
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py screenshot-window --title-contains "Settings" --output .\.agents\runs\settings.bmp

# Generic Win32 HWND tree map. Does not activate the target window.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py win32-map --focused --max-depth 4
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py win32-map --pid 12345 --max-depth 4

# Generic Windows input.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py move --x 500 --y 300
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py click --x 500 --y 300
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py type-text --text "hello"
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py tab
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py tab --shift

# Optional UIA inspection.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py fast-semantic-map --hwnd <handle> --max-depth 3 --max-children 200
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py uia-map --focused --max-depth 4
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py uia-map --hwnd <handle> --max-depth 4 --max-children 100
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py uia-map --hwnd <handle> --detail geometry --max-depth 4
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py uia-map --hwnd <handle> --plain --max-depth 4
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-provider-map --pipe-name <name> --target handle --handle <handle> --max-depth 3 --max-children 200
```

Use `--dry-run` on announcement commands when validating the skill without speaking. The announcement files live in `assets/announcements/` and are generated once with ElevenLabs Bella; the helper must not call ElevenLabs or any other TTS provider at runtime.

Use `fast-map` as the default broad target-discovery command when speed matters. With `--pipe-name`, it asks the MaxLogic bridge for one `form.map` snapshot; the default is geometry (`detail:"geometry"`, `includeAccessibility:false`, `visibleOnly:true`). Use `fast-map --detail full` when a bridge-enabled app needs visible captions, values, hints, roles, and role-specific native state without a UIA tree walk; it still uses process-local VCL/RTL reads and cached RTTI fallback with `includeAccessibility:false`. Without an explicit pipe name, it derives the process-specific default pipe `MaxLogicAccessibilityAgentBridge.<pid>` from `--pid`, a `--target handle` HWND, the focused window, or a `--title-contains` match. PID and title matches are first resolved to a native HWND, then sent to the bridge as a handle-targeted `form.map`, so background mode does not depend on whichever app currently has focus. The automatic `fast-map` default-pipe probe is intentionally tiny; `fast-semantic-map` uses a modestly longer semantic bridge probe so a busy bridge-enabled app can still answer from in-process `provider.map` instead of falling through to slow UIA. Pass `--pipe-name` for custom bridge pipe names or when a known bridge target needs the normal command timeout. Without a bridge pipe, it falls back to the native Win32 HWND map using the same `--detail` setting; `geometry` skips per-HWND text reads and does not call UIA. It reports helper wall time as `elapsedMs`; bridge responses also keep the process-local timing as `bridgeElapsedMs` and `bridgeElapsedTicks`. Use `fast-semantic-map` as the bridge-first semantic discovery command: it auto-tries the MaxLogic provider bridge for the selected PID, HWND, title, or focused window, returns the in-process `provider.map` tree when available, and falls back to cached external UIA when the target has no bridge. If fallback happens, the cached UIA result includes `fallbackAttempts` so logs show which bridge pipe was tried and why the native semantic bypass was not used. Use `bridge-provider-map` when a bridge-enabled app needs a fast UIA-like semantic provider tree, including virtual framework children, but the task does not require validating the external UIA client/provider boundary. It walks the MaxLogic provider model in-process with `IAccessibilityProviderChildAccess`, reports `source:"maxlogic-provider"`, and should be preferred over `uia-map` for diagnostic discovery. Use `uia-map` only when validating the actual UIA tree or inspecting UIA-only virtual controls in applications without a MaxLogic bridge provider map; its output is marked `slowSemanticPath`, `recommendedFor:"semanticVerification"`, and includes faster alternatives for coordinate discovery. `uia-map` defaults to the cached .NET UIAutomation path; `--cache` is accepted for explicitness, and `--plain` opts into the slower Python `uiautomation` traversal only for comparison or debugging. When using `uia-map`, prefer `--hwnd`, `--pid`, or `--title-contains` over a desktop-root walk, cap broad branches with `--max-children`, and use `--detail geometry` when rectangle/tree shape is enough and names, AutomationIds, class names, roles, focus state, and enabled state are not needed.

For semantic UIA snapshots, use `uia-map` without `--plain`. The default cache path uses the built-in .NET UIAutomation `CacheRequest` through PowerShell, so common properties are fetched with the returned elements instead of via separate `Current.Name`, `Current.ClassName`, `Current.ControlType`, and similar calls. It is still a semantic verification path, not a coordinate-discovery path.

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
- `win32-map` for fast HWND-backed title/class/rectangle discovery without UIA traversal.
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
- Use `bridge-form-map --pipe-name <name>` for high-speed broad control/coordinate discovery in the current visible view. It sends `{"cmd":"form.map","target":"focused","detail":"geometry","includeAccessibility":false,"visibleOnly":true}` and returns refs, roles, handles, rectangles, and target points without UIA traversal, accessibility scanning, text/state reads, or RTTI fallback.
- Use `fast-map --pipe-name <name> --detail full` or `fast-map --pid <pid> --detail full` when the visible map needs captions, values, hints, and native checked/selected/list state. This is still a UIA bypass for bridge-enabled VCL apps because the bridge uses process-local VCL/RTL reads and cached RTTI fallback with `includeAccessibility:false`.
- Use `fast-semantic-map --pid <pid>` or `fast-semantic-map --target handle --handle <hwnd>` when diagnostics need a semantic provider tree but should bypass UIA whenever the MaxLogic bridge is available. It auto-probes the default bridge pipe, returns `provider.map` with `semanticBypass:true` on bridge-enabled VCL apps, and falls back to cached UIA for generic applications.
- Use `bridge-provider-map --pipe-name <name>` when diagnostics need a UIA-like provider tree with framework virtual children but do not need to prove what an external UIA client receives. It sends `{"cmd":"provider.map","target":"focused","detail":"full","maxDepth":3,"maxChildren":200}` by default and walks provider direct-child access in-process instead of using UIA TreeWalker.
- Use `bridge-control-info --pipe-name <name> --ref <ref>` after a geometry map when only one or a few controls need caption, value, hint, or native role-specific state. It sends `{"cmd":"control.info","ref":"<ref>","detail":"full","includeAccessibility":false}` by default, so it enriches the selected ref through process-local VCL/RTL reads and RTTI fallback without scanning the whole form. Add `--include-accessibility` only when validating accessible names or help text.
- Use `bridge-controls-info --pipe-name <name> --ref <ref1> --ref <ref2>` when several mapped controls need detail. It sends one `controls.info` request and avoids repeated pipe setup, repeated focus reads, and repeated per-request RTTI-cache warmup.
- Use `bridge-batch` for repeated bridge reads or command sequences. It keeps one pipe connection open and sends newline-delimited requests sequentially, avoiding repeated process/pipe setup while still waiting for one response before sending the next request.
- Prefer `bridge-form-map` over `uia-map` for MaxLogic framework-enabled applications when the task is target discovery, coordinates, or background control. Prefer `fast-semantic-map` or `bridge-provider-map` when the task needs fast semantic provider-tree diagnostics but not external UIA-boundary validation. UIA tree walking is a verification path and can make hundreds of client/provider boundary calls even for a small tree. If diagnostics show tiny provider elapsed ticks but a slow external UIA sample, bypass UIA with `bridge-form-map`, `fast-semantic-map`, `bridge-provider-map`, or `win32-map`; do not spend time micro-optimizing process-local Delphi property reads. If `fast-semantic-map` falls back to UIA, read `fallbackAttempts` first; it records the bridge pipe and error so the slow sample is not mistaken for the preferred path. When UIA semantics themselves must be sampled through the external UIA stack, use the default cached `uia-map` path and reserve `--plain` for comparing the slower Python `uiautomation` traversal.
- Use `{"cmd":"form.map","target":"focused"}` or `target:name/handle` with full detail to get controls, captions, UIA-equivalent role IDs/names, refs, native state, screen rectangles, and target points when the task is validating accessibility metadata or needs all controls.
- Use `{"cmd":"form.map","target":"focused","includeAccessibility":false,"visibleOnly":true}` for a native full-detail map when captions, hints, values, and role-specific state are useful but accessible-name/help-text scanning is not.
- `{"cmd":"hitTest","x":500,"y":300}` to map a screen point back to the framework snapshot.
- Mutation commands only when the app has explicitly enabled them.

For user-realistic Foreground Drive Mode tests, prefer OS input for actions (`click`, `type-text`, `tab`) and use bridge responses to choose coordinates and verify state. For Background Drive Mode, bridge mutation commands are acceptable when mutations are explicitly enabled and the test goal is application control rather than human-equivalent input.

Before each OS input batch, use `activate-window --pid <processId>` for the target process and verify `foreground-window` reports that same PID. If activation fails, do not click or type; collect bridge/UIA evidence instead and report the blocker.

## Generic Win32 Map

Use `win32-map` before `uia-map` when the target likely uses HWND-backed controls. It walks the native child-window tree with User32 calls and returns class, enabled/visible state, rectangles, center target points, PID/thread, and children. Use `--detail geometry` when coordinates are enough; it skips per-HWND title reads because `GetWindowText` on another process can block on window messages. Use the default `--detail full` when titles are needed. This is usually much faster than UIA `TreeWalker` because it avoids per-property UIA provider/client round trips.

Limitations:

- It only sees real HWNDs. WPF, WinUI, browser content, owner-drawn virtual rows, and UIA-only fragments may be missing or too coarse.
- It gives native window geometry, not screen-reader-facing names, roles, patterns, or states.
- Use UIA after `win32-map` when the task needs accessibility semantics, not just coordinates or HWND identity.

## Speech Evidence

If NVDA or another screen reader is involved:

- Keep the takeover/release announcements in the transcript so the user knows when control changed.
- Prefer the user's configured speech log or screen-reader transcript source when available.
- Keep logs readable while the app is running; do not require exclusive locks.
- Compare three streams when possible: bridge/control map, UIA view, and spoken transcript.
- Do not mention machine-local evidence stores in this skill; keep the instructions portable across machines.

## Safety

Never control the desktop silently in Foreground Drive Mode. Do not continue if the takeover announcement fails unless the user explicitly allows a silent run. Do not leave the pointer/keyboard under automation without the release announcement. In Background Drive Mode, avoid focus stealing and prefer commands that target explicit HWNDs, PIDs, bridge refs, or UIA elements.
