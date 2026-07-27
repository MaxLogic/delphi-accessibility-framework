# Agent-control certification checklist

This checklist proves agent control of a bridge-enabled VCL application. It is not an NVDA or screen-reader test.

## Setup and evidence

- Build and launch the normal Debug demo with the opt-in agent bridge and one unique pipe name.
- Start one bounded foreground session for the demo PID. Record the session ID, target identity, controller PID, watchdog PID, and event-log path.
- Use condition-based commands and semantic control names. Do not use copied coordinates or fixed sleeps.
- Store concise command JSON, screenshots, event logs, build identity, and final residue checks under `.agents\runs\`.

## Required scenarios

1. **Bridge-only agent control** — prove `hello`, `forms.list`, narrow `control.resolve`, and process-local state without describing the result as NVDA evidence.
2. **Slow-form wait** — use `wait-form` or `wait-control` with one overall deadline and retain its attempts/elapsed evidence.
3. **MDI activation** — resolve an MDI child or child HWND to its activatable root and verify requested and activated identities separately.
4. **Modal discovery** — invoke the modal opener through guarded OS input, return before inspecting it, then use `windows-list` or a bounded wait to prove the enabled modal and disabled owner relationship. Never use synchronous bridge `control.click` for the opener.
5. **Guarded mouse and keyboard input** — run fresh semantic left/right/double or move actions plus keyboard input under the same lease; each response must show the current lease and expected foreground owner.
6. **Lease expiry and watchdog release** — terminate the controller or allow the lease to expire, hear the independent release announcement, and prove one release event plus no lease, lock, or watchdog residue.
7. **Clean application shutdown** — close the demo normally, verify the bridge pipe disappears, and prove no demo, bridge worker, controller, watchdog, or Python-cache residue remains.

## Stopping rule

Stop after all required scenarios pass or after the requested retry/time budget produces a clear blocker. Release operator control before optional investigation, and report any unproved scenario exactly rather than redefining it as a pass.
