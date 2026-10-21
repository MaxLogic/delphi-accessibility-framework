---
name: windows-desktop-control
description: Control Windows apps, inspect windows and UI Automation, capture screenshots, and gather accessibility evidence. Prefer background operations that leave the user's keyboard, mouse, and foreground window alone. Announce necessary foreground control and proceed without waiting for confirmation.
metadata:
  author: Pawel Piotrowski
---

# Windows Desktop Control

## Default: work in the background

Use an available app API, CLI, automation object model, compatible MaxLogic
bridge, or non-activating UIA pattern. A missing bridge does not require taking
control of the desktop. Background operations must leave the user's foreground
window, keyboard, mouse, and clipboard undisturbed; the target can remain visible.

Use foreground input only when the required action has no usable background
route, or the task specifically tests real input or foreground behavior. Apply
this choice per action. Routine inspection, screenshots, form filling, selection,
and supported menu/modal commands should normally stay in the background.

**Announce and proceed; do not ask for confirmation or wait for a reply.**
`foreground-session start` plays the audible takeover announcement and waits
three seconds before input. This is the normal notice; it requires no harness
visit or approval click. Do not add a separate explanation or approval step.
If useful, add a short status such as "I'm taking the mouse and keyboard briefly
in Designer." Respect an explicit user instruction forbidding takeover.

Use the same rules with every computer-control tool. Switching tools must not
bypass announcements, leases, or target guards.

## Choose the next operation

1. Identify the intended PID/HWND without activation. Prefer explicit targets
   over `--focused`, which can refer to the user's current application. Reuse
   settled authorization and keep discovery within the requested app.
2. Use a supported background command and read back its result. Prefer direct
   control addressing over focus or Tab navigation. UIA `Value`, `Invoke`,
   `SelectionItem`, `Toggle`, and `ExpandCollapse` are candidates when the
   provider supports them without activation or global input. The bundled
   helper's UIA commands inspect only; mutations need another available API.
3. If a route is unavailable, check other plausible background capabilities
   briefly. A stale target requires rediscovery; a transient failure permits a
   bounded retry. Read state before retrying a mutation with an uncertain result.
   Do not run an open-ended search just to avoid a necessary foreground step.
4. If the action still requires real input, use the foreground workflow below.
   A missing bridge, convenience, or a faster coordinate click alone is not a
   reason to take over. Never bypass disabled mutations or authorization limits.
5. Verify through the evidence channel the task needs, then stop. A successful
   command exit does not by itself prove application state, UIA output, or speech.

Judge background safety by effects. A semantic invoke or app launch can activate
a window through application code. Use known non-activating behavior; when an
operation is known to activate the target, announce foreground control first.
For uncertain provider behavior, check available documentation or prior proof
and compare `foreground-window` before and after the operation. If it unexpectedly
steals focus, stop further mutations and inspect read-only. Do not fight the user
by repeatedly activating windows. `SetFocus`, `click_input`, global typing, and
clipboard replacement are not background operations.

## Helper and discovery

Use `scripts/windows_desktop_control.py` relative to this skill directory.
Read [commands and examples](references/commands.md) when choosing arguments or
preparing a foreground batch; use `<command> --help` for less common options.
Core commands use Python's standard library and Win32. Cached UIA inspection uses
Windows PowerShell/.NET; only `uia-map --plain` needs `uiautomation`
(`python -m pip install uiautomation`, if that diagnostic path is needed).

| Need | Command |
| --- | --- |
| Targeted window/form/control discovery | `windows-list`, `bridge-forms`, `bridge-find`; bounded `wait-window`, `wait-form`, `wait-control` |
| Fast geometry or native state | `fast-map --pid PID`; add `--detail full` for captions, values, and list/checked state |
| Native HWND tree | `win32-map --pid PID`; `--detail geometry` skips text reads |
| Fast semantic diagnostics | `fast-semantic-map --pid PID` or `bridge-provider-map` |
| Actual external UIA view | `uia-map --hwnd HWND --max-depth 4 --max-children 100` |
| Non-activating image | `screenshot-window --hwnd HWND --output PATH` |

`fast-map` tries the process-specific bridge, then native Win32. Use an explicit
`--pipe-name` for custom pipes or a known busy bridge needing the normal timeout.
`fast-semantic-map` prefers the in-process provider map, then cached external UIA;
read `fallbackAttempts` before attributing a slow result to the bridge.
`uia-map --plain` is the slower comparison/debug path. Limit tree depth and width.
Native HWND maps omit virtual controls; in-process provider maps do not prove
external UIA behavior. When UIA is under test, obtain targeting geometry from the
bridge or Win32 and use UIA only as a cross-check.

## Background commands

Probe the MaxLogic bridge first. Typed mutation commands require protocol v2,
enabled mutations, and `background-command-mode`. `--ref` additionally requires
`snapshot-refs-v2`; atomic form/control targets require `atomic-control-targets`;
named actions require `action-invoke`. Stop an incompatible bridge mutation
workflow; do not silently substitute foreground input.

- Use `bridge-set-text`, `bridge-set-checked`, and `bridge-select` to address
  controls directly. Text assignment does not prove key events or `OnChange`.
- For single selection, use `--index` or exact `--text`. Multi-select lists use
  `--indices`, `--texts`, or `--clear-selection`; text must uniquely match an item.
- Use `bridge-invoke` for a control and `bridge-action-invoke` for a uniquely named
  form/data-module `TCustomAction` or `TMenuItem`. Named menus need no proxy button.
- `bridge-focus` and `bridge-tab` change app focus. Use them only when needed and
  when they preserve the user's foreground window and input destination.
- Invocations wait for terminal completion by default. For a modal opener, use
  `--async`, discover it with `wait-form`, dismiss it through `bridge-invoke`, then
  consume the opener with `bridge-operation-status`. Do not use synchronous
  legacy `control.click` for modal openers.
- Use narrow `bridge-control-info`/`bridge-controls-info` reads after mapping;
  add `--include-accessibility` only when those properties are needed.
  `bridge-batch` reuses a connection but raw requests may mutate. Inspect each
  result before dependent actions; never parallelize actions on changing UI.

Refs and geometry expire after activation, movement, DPI changes, mutations,
tab/page changes, form creation, modal transitions, or `snapshotInvalidated:true`.
Resolve fresh targets instead of reusing old refs or coordinates.

## Foreground workflow

Read the checked example in [commands and examples](references/commands.md#foreground-batch).

1. Prepare the input-dependent batch and identify the target before takeover.
   A launching app that takes focus is itself a foreground operation; do not
   disguise it as background preparation.
2. Start one bounded `foreground-session`. Its audible announcement and built-in
   three-second delay are sufficient; proceed automatically after success.
   Announcement failure stops input unless the user already authorized silence.
3. Use the session ID on every activation/input command and keep all commands
   on the same lease state path, preferably the shared default.
   `activate-window` must succeed and the intended window must own foreground
   before input. Semantic pointer commands such as `click-control` resolve,
   activate, resolve again, and check ownership before dispatch. For generic
   input, verify `foreground-window` and use PID/HWND guards.
4. Keep one lease across the related input steps, short waits, and immediate
   verification. Renew before expiry if the bounded batch is still running;
   do not release and reacquire for every click. The default lease follows one
   PID across modal HWNDs; add `--target-hwnd` only for exact-window locking.
5. Release in `finally` on success or failure. Release promptly when the batch
   ends, the user resumes input or asks to stop, or a safety check fails. Release
   before lengthy preparation, waiting for the user, unrelated work, or further
   work that can run in the background. The watchdog is recovery for expiry or
   controller exit, not a substitute for normal release.

The matching release plays the audible hand-back announcement. Never leave a
session running for the entire time the user is away. A restarted process with a
new PID needs a new lease. Activation failure means no clicking or typing;
continue with background evidence if useful. Lower-level `takeover`/`release`
commands only play audio and do not authorize input. Bundled WAV files are used
locally; do not add runtime TTS calls. `--dry-run` is not an input safety sandbox:
a session can still write state and start a watchdog.

After opening a dialog or an unchanged input result, inspect native windows as
well as the bridge. Standard `#32770` message boxes can be absent from bridge
maps; a matching PID does not prove the parent can receive input. Handle the
enabled modal first, rediscover its HWND, and retain the current lease where valid.
If fast typing triggers barcode-scanner handling, inspect that modal, then use
human-speed typing such as `--delay-ms 150` and verify the resulting field text.

## Evidence and completion

Prefer target-window screenshots over the whole desktop. Capture does not
activate the window, but `PrintWindow`/`BitBlt` can return incomplete images for
obscured or minimized windows. Inspect the image; use another background evidence
source before taking over solely to get a usable capture. Keep screenshots and
lease/event files in the project's evidence location or an owned run directory
under its storage policy, outside `.agents/`.

Keep application state, external UIA, real input, and NVDA evidence distinct.
For screen-reader work:

- Read an existing transcript in the background when possible. Otherwise use
  NVDA's **Tools > Speech Viewer**; opening or focusing it through desktop input
  belongs inside an announced lease for that process.
- Keep Speech Viewer unfocused and away from the pointer during the interaction.
  Focus or hover pauses updates. Collect a baseline and the relevant new text
  with the tested action and approximate time; old history is not current proof.
- Viewer text proves generated speech text, not pronunciation, timing, volume,
  or uninterrupted audio. Use audible observation/recording for those claims.
  Takeover/release WAVs are outside NVDA; retain their timestamps separately.
- Compare bridge state, external UIA, and speech where relevant; report
  disagreements. Prefer another configured transcript if Speech Viewer is
  unavailable; do not require exclusive locks or inspect unrelated history.

Stop when the requested result is verified, the reproduced failure and required
persistence checks are captured, or the retry/time budget is exhausted. Report
the result, evidence paths, material failures or untested boundaries, and release
status if foreground control was used.
