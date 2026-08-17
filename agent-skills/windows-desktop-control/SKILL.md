---
name: windows-desktop-control
description: Control Windows desktop applications from Codex in foreground or background mode, with explicit takeover/release announcements for foreground mouse/keyboard control, window screenshots, optional UIA inspection, Win32 input/messages, and optional MaxLogic Accessibility Agent Bridge support. Use when a task asks to drive a local Windows app, inspect or screenshot a window, test accessibility behavior, collect spoken screen-reader evidence, move/click/type/tab through controls, or coordinate UIA with an app-specific diagnostic bridge.
---

# Windows Desktop Control

## Choose the control mode

| Requirement | Mode |
| --- | --- |
| Routine smoke/regression workflow in a bridge-enabled app | **Background Command Mode** |
| Inspect, populate, select, invoke, open/dismiss modal, verify state | **Background Command Mode** |
| Prove actual pointer, key, accelerator, menu, IME, drag/drop, capture, or screen-reader behavior | **Foreground Input Mode** |
| No bridge and no reliable background semantic API | **Foreground Input Mode**, after starting an announced `foreground-session` lease |

Default to **Background Command Mode** for routine testing. Background Command Mode is pseudo-headless: the application remains visible in the user's session, but a compatible bridge performs control directly. Background Command Mode does not activate the target, move the pointer, synthesize mouse or keyboard input, or announce takeover. This is the normal day-to-day path because the user can keep working.

Choose Foreground Input Mode only when real input or foreground-dependent behavior is the subject of the test. Before touching the user's mouse or keyboard, start one bounded `foreground-session`; it announces takeover and waits three seconds. Release it when finished. Every activation, mouse, keyboard, and semantic OS-input command requires the valid lease.

Bridge control is not an NVDA test. Command-mode evidence proves application-semantic state, not real input. Foreground-input evidence proves OS mouse/keyboard behavior, not accessibility output. External UIA behavior requires an external UIA probe. NVDA speech requires a live NVDA pass.

`foreground-session start` plays the takeover announcement and includes the required three-second safety delay; do not add another sleep. Its matching `foreground-session release` plays the release announcement. The lower-level `takeover` and `release` commands exist for explicit announcement-only work, not as lease authorization.

Wrap Foreground Input Mode sessions in `try/finally` and require normal release before deleting lease evidence.

If the active Codex runtime exposes a first-class computer-control tool, prefer that for pointer control when it is safer or more capable. Still use this skill's announcement workflow, bridge protocol, screenshot commands, and evidence rules.

## Decision Order

1. Default routine bridge-enabled work to Background Command Mode; choose Foreground Input Mode only for real input or foreground-dependent behavior.
2. Probe the app's MaxLogic bridge and require protocol version 2, enabled mutations, and the capabilities needed by the selected target shape. An incompatible bridge never silently falls back to Foreground Input Mode.
3. For generic HWND-backed applications, use `win32-map` for cheap title/class/rectangle discovery before using UIA.
4. Use UIA to inspect virtual/non-HWND elements, operate UIA patterns, or compare actual accessibility output.
5. Use explicit bridge commands for Background Command Mode mutations. Read-only Win32/UIA inspection may supplement them when it does not steal focus.
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
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-controls-info --pipe-name MaxLogicAccessibilityAgentBridge.1234 --ref @s12a1 --ref @s12a2
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py fast-map --pipe-name MaxLogicAccessibilityAgentBridge.1234
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py fast-map --pid 1234
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py fast-semantic-map --pid 1234 --max-depth 3 --max-children 200
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-request --pipe-name MaxLogicAccessibilityAgentBridge.1234 --request '{"cmd":"forms.list"}'
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-batch --pipe-name MaxLogicAccessibilityAgentBridge.1234 --request '{"cmd":"window.info","target":"focused"}' --request '{"cmd":"form.map","target":"focused","detail":"geometry","visibleOnly":true}'

# Typed Background Command Mode. Each command validates protocol/capabilities first.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-set-text --pipe-name <name> --form-name MainForm --control-name edtSearch --text "query"
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-set-checked --pipe-name <name> --form-name MainForm --control-name chkEnabled --checked
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-select --pipe-name <name> --form-name MainForm --control-name cmbQueue --text "Ready"
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-focus --pipe-name <name> --form-name MainForm --control-name edtSearch
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-tab --pipe-name <name>
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-invoke --pipe-name <name> --form-name MainForm --control-name btnApply
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-invoke --pipe-name <name> --form-name MainForm --control-name btnShowModal --async
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-operation-status --pipe-name <name> --operation-id <id>

# Modal round trip: retain the opener operationId and the discovered form handle.
$lOpen = python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-invoke --pipe-name <name> --form-name MainForm --control-name btnShowModal --async | ConvertFrom-Json
$lModal = python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py wait-form --pipe-name <name> --class-name TMessageForm --visible true --fields name,className,handle | ConvertFrom-Json
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-invoke --pipe-name <name> --form-hwnd $lModal.matches[0].handle --control-name OK
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py bridge-operation-status --pipe-name <name> --operation-id $lOpen.operationId

# Foreground safety.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py foreground-window
$lStatePath = '.\.agents\runs\foreground-lease.json'
$lEventPath = '.\.agents\runs\foreground-events.jsonl'
$lLease = python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py foreground-session start --target-pid 12345 --controller-pid $PID --ttl-ms 60000 --state-path $lStatePath --event-path $lEventPath | ConvertFrom-Json
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py activate-window --pid 12345 --session-id $lLease.sessionId --session-state-path $lStatePath
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py foreground-session renew --session-id $lLease.sessionId --ttl-ms 60000 --state-path $lStatePath

# Fresh semantic actions. Pass the active session ID and state path for real input.
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py move-to-control --pipe-name <name> --form-name MainForm --control-name btnRun --session-id $lLease.sessionId --session-state-path $lStatePath --require-foreground-pid 12345
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py click-control --pipe-name <name> --form-name MainForm --control-name btnRun --session-id $lLease.sessionId --session-state-path $lStatePath --require-foreground-pid 12345
python .\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py foreground-session release --session-id $lLease.sessionId --state-path $lStatePath --event-path $lEventPath

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

## Foreground Input Mode

Use Foreground Input Mode when the task needs human-equivalent behavior: actual mouse, keyboard, accelerator, menu, IME, drag/drop, capture, or screen-reader behavior. Modal behavior needs this mode only when the real opener/input path is itself under test; routine modal application workflows stay command-driven.

Workflow:

1. Start one bounded `foreground-session`; it announces takeover once and starts an independent release watchdog.
2. Start or identify the target app.
3. Use `activate-window --pid <processId>` or `--hwnd <handle>`.
4. Verify `foreground-window` reports the expected target before every input batch.
5. Prefer `move-to-control`, `click-control`, `double-click-control`, or `right-click-control`; each resolves, activates, resolves again, checks actionability and foreground ownership, then dispatches OS input.
6. Pass the same session ID to guarded `move`, `click`, `press`, `tab`, `key-chord`, `clear-and-type`, or semantic control actions.
7. Renew only around a bounded wait, then release the session normally. The detached watchdog releases independently on expiry or controller exit.

By default a session guards the target PID and permits that application's foreground HWND to change across owned or modal windows. Add `--target-hwnd` only when the interaction must remain on one exact window.

Activation failure is a hard stop. Do not click or type after it. Report the blocker and continue with Background Command Mode evidence if that can still answer the task.

Treat refs and geometry as expired after activation, window movement, DPI change, mutation, tab/page change, form creation, modal transition, or any response with `snapshotInvalidated:true`. Resolve the named control again immediately before input; never reuse copied coordinates across those transitions.

Do not invoke modal-opening controls through synchronous legacy `control.click`. In Foreground Input Mode use a guarded OS click. In Background Command Mode use `bridge-invoke --async`, discover the modal with `wait-form`, dismiss it through `bridge-invoke`, then consume the opener with `bridge-operation-status`.

`control.setText` is raw property assignment. It does not prove key events, `OnChange` behavior, accelerators, or human-equivalent typing. Use guarded `clear-and-type` or `type-text` when those semantics matter.

Use a bounded best-effort stopping rule: stop after the requested outcome is proved, a reproduced product failure is captured with its required persistence checks, or the agreed retry/time budget is exhausted. Release the session before optional lower-priority exploration.

## Background Command Mode

Use Background Command Mode when the user should be able to keep working while automation inspects or drives a bridge-enabled application. This is the default for routine state inspection, workflow smoke tests, form filling, selection, invocation, focus, tab navigation, and modal application workflows.

Background Command Mode uses:

- Typed `bridge-focus`, `bridge-set-text`, `bridge-set-checked`, `bridge-select`, `bridge-tab`, and `bridge-invoke` commands after a protocol-v2 capability check.
- `bridge-invoke` waiting for terminal completion by default; use `--async` only when the caller must keep controlling an open modal, then finish with `bridge-operation-status`.
- `form.map`, `control.resolve`, and other process-local bridge reads for state and target discovery.
- `win32-map` for fast HWND-backed title/class/rectangle discovery without UIA traversal.
- `screenshot-window` for visual evidence without activating the target window.

If hello reports protocol version 1, disabled mutations, or missing `background-command-mode`, stop the command workflow and report the incompatibility. Targeted helpers additionally require `snapshot-refs-v2` for `--ref` or `atomic-control-targets` for `--form-name`/`--form-hwnd`; `bridge-tab` and operation status need no target capability. The workflow never silently falls back to Foreground Input Mode.

Do not claim command-mode results are human-equivalent input, external UIA, or NVDA proof. Some applications intentionally behave differently when inactive; actual focus, capture, menus, accelerators, IME, drag/drop, and screen-reader tracking need Foreground Input Mode.

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

For user-realistic Foreground Input Mode tests, use OS input for actions (`click`, `type-text`, `tab`) and bridge responses to choose coordinates and verify state. For Background Command Mode, use typed bridge commands when mutations are explicitly enabled and the test goal is application control rather than human-equivalent input.

Before each OS input batch, use `activate-window --pid <processId>` for the target process and verify `foreground-window` reports that same PID. If activation fails, do not click or type; collect bridge/UIA evidence instead and report the blocker.

## Generic Win32 Map

Use `win32-map` before `uia-map` when the target likely uses HWND-backed controls. It walks the native child-window tree with User32 calls and returns class, enabled/visible state, rectangles, center target points, PID/thread, and children. Use `--detail geometry` when coordinates are enough; it skips per-HWND title reads because `GetWindowText` on another process can block on window messages. Use the default `--detail full` when titles are needed. This is usually much faster than UIA `TreeWalker` because it avoids per-property UIA provider/client round trips.

Limitations:

- It only sees real HWNDs. WPF, WinUI, browser content, owner-drawn virtual rows, and UIA-only fragments may be missing or too coarse.
- It gives native window geometry, not screen-reader-facing names, roles, patterns, or states.
- Use UIA after `win32-map` when the task needs accessibility semantics, not just coordinates or HWND identity.

## Speech Evidence

If NVDA or another screen reader is involved:

- Prefer NVDA's built-in Speech Viewer when exact NVDA text is needed. Open it from **NVDA Menu > Tools > Speech Viewer** before the tested interaction. If the agent must open it, do so inside the announced foreground session.
- Keep Speech Viewer open, unfocused, and away from the pointer while driving the target application. Hovering over it or focusing inside it pauses incoming updates, and focusing it also changes application focus. Move to it only after the interaction and a bounded settling period; the pause is then useful for freezing the evidence before copying it.
- Capture a baseline tail or before-snapshot, then copy the relevant final text from Speech Viewer after the interaction. Store the tested action, approximate time, and copied text together so older viewer history is not mistaken for current speech.
- Treat Speech Viewer as evidence of text generated by NVDA, not proof of final audio pronunciation, timing, volume, or uninterrupted playback. Use audible observation or an audio recording when the requirement specifically concerns what was heard.
- The helper's takeover and release announcements are WAV files played outside NVDA and therefore do not appear in Speech Viewer. Keep their session events or timestamps beside the NVDA transcript instead of claiming they are part of it.
- Prefer another configured speech log or screen-reader transcript when Speech Viewer is unavailable. Keep transcript sources readable while the app is running; do not require exclusive locks.
- Compare three streams when possible: bridge/control state, the external UIA view, and the NVDA Speech Viewer or other spoken transcript. Report disagreements rather than treating one stream as a substitute for another.
- Do not mention machine-local evidence stores in this skill; keep the instructions portable across machines.

## Safety

Never control the desktop silently in Foreground Input Mode. Do not continue if the takeover announcement fails unless the user explicitly allows a silent run. Do not leave the pointer/keyboard under automation without the release announcement. In Background Command Mode, do not activate the application or move the cursor; target current bridge refs, form names, or exact form handles.
