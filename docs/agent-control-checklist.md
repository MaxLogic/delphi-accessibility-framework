# Agent-control certification checklist

This checklist proves agent control of a bridge-enabled VCL application. Background Command Mode is the default for routine testing; Foreground Input Mode is reserved for behavior that truly needs the user's foreground, mouse, or keyboard.

## Setup and evidence

- Build and launch the normal Debug demo with the opt-in agent bridge, mutations enabled, and one unique pipe name.
- Fingerprint the source inputs and exact demo executable before either live workflow.
- Use condition-based commands and semantic control names. Do not use copied coordinates or fixed sleeps.
- Store concise command JSON, mode evidence, build identity, and final residue checks under `.agents\runs\`.
- Command-mode evidence does not prove external UIA or NVDA behavior.

## Background Command Mode

Run this section without activating an anchor, moving the cursor, or sending OS input.

1. **Bridge-only agent control** — require protocol version 2, enabled mutations, `background-command-mode`, and the target capability before any mutation. An incompatible bridge is a blocker; never fall back silently to Foreground Input Mode.
2. **Typed daily workflow** — use `bridge-set-text`, `bridge-set-checked`, `bridge-select`, `bridge-focus`, `bridge-tab`, and default-wait `bridge-invoke` as the application requires. Verify resulting VCL/application state through the bridge.
3. **Modal discovery** — call `bridge-invoke --async`, use `wait-form` to find the bridge-visible modal, and invoke its dismiss control by exact form handle. The default-wait dismiss invocation consumes its own terminal operation; consume only the asynchronous opener with `bridge-operation-status`. Do not use synchronous legacy `control.click`.
4. **Slow-form wait** — use `wait-form` or `wait-control` with one overall deadline and retain its attempts/elapsed evidence.
5. **Non-interference** — compare the existing non-target foreground HWND/PID and cursor after every mutation and modal transition. Independent user activity is INCONCLUSIVE, never a bridge failure or PASS.
6. **Clean application shutdown** — close the demo through the bridge, verify the pipe disappears, and prove no demo, bridge operation, helper process, temporary directory, or Python-cache residue remains.

## Foreground Input Mode

Run this section only for actual mouse, keyboard, accelerator, menu, IME, drag/drop, capture, or screen-reader behavior.

1. **Bounded announced lease** — start one `foreground-session` for the target PID, record the session/controller/watchdog identities, and require the lease for every activation and input command.
2. **MDI activation** — resolve an MDI child or child HWND to its activatable root and verify requested and activated identities separately.
3. **Guarded mouse and keyboard input** — use freshly resolved targets and run mouse plus keyboard input under the same lease; each response must show `driveMode:"foreground-input"` and the expected foreground owner.
4. **Foreground modal path** — use guarded real input only when the real opener, menu, accelerator, capture, or focus behavior is under test; re-resolve after every modal transition.
5. **Lease expiry and watchdog release** — test normal release and, when required, controller exit or expiry. Prove one release event plus no lease, lock, or watchdog residue.
6. **Clean application shutdown** — close the exact owned demo, wait for the watchdog to exit after normal release, and retain evidence if release cannot be proven.

## Evidence boundaries

- Bridge commands prove process-local application and VCL behavior.
- A live external UIA probe proves the UIA client/provider boundary; an in-process provider map does not.
- A live NVDA or other screen-reader pass proves screen-reader behavior; bridge state, UIA state, and takeover audio do not.
- Foreground Input Mode proves the guarded OS-input path used in that run; it does not automatically prove NVDA speech.

## Stopping rule

Stop after the selected mode's required scenarios pass or after the requested retry/time budget produces a clear blocker. Release operator control before optional investigation, and report any unproved or inconclusive scenario exactly rather than redefining it as a pass.
