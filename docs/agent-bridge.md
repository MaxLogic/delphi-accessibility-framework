# Agent Bridge

`MaxLogic.Accessibility.AgentBridge` exposes a small JSON command executor for diagnostic automation. It is intended for tools that already control the desktop through UIA, Win32, or `SendInput`, but need framework-specific VCL facts that UIA may not expose reliably.

The core executor does not start a transport by itself. Applications can either call `TAccessibilityAgentBridge.Execute` from their own transport on the VCL main thread, or opt in to the built-in named pipe transport from `MaxLogic.Accessibility.AgentBridge.PipeServer`.

## Purpose Boundaries

This repository now serves three separate purposes:

- screen-reader accessibility for Delphi VCL applications, with NVDA as the primary practical target
- application control bridge support for Delphi VCL applications that opt in to framework diagnostics
- agent desktop-control skill guidance for driving Windows applications through UIA, Win32 messages, screenshots, OS input, and the MaxLogic bridge when available

Those purposes share code and evidence, but they should not be collapsed into one concept. Foreground and background are automation modes; they are not screen-reader modes. Foreground mode means the automation drives the application like a human user would, with the target window active and normal mouse/keyboard input. Background mode means the automation avoids taking focus and uses bridge commands, UIA patterns, or Win32 messages where the target application supports that style of control.

Screenshots belong to the desktop-control helper first, not to the Delphi accessibility framework. The bridge provides reliable process-local metadata such as form handles, screen rectangles, client geometry, DPI, and control target points so an agent does not need to depend on UIA for coordinates when UIA is the thing under test.

## Named Pipe Transport

For local diagnostic automation, add the pipe server unit and start it after the VCL application has initialized:

```delphi
uses
  MaxLogic.Accessibility.AgentBridge.PipeServer;

begin
  TAccessibilityAgentBridgePipeServer.Start;
  try
    Application.Run;
  finally
    TAccessibilityAgentBridgePipeServer.Stop;
  end;
end;
```

`Start` and `Stop` are idempotent when repeated for the same pipe name. The default pipe name is process-specific and available through `TAccessibilityAgentBridgePipeServer.DefaultPipeName`; the active pipe path is `\\.\pipe\` plus `TAccessibilityAgentBridgePipeServer.PipeName`.

The pipe protocol is one UTF-8 JSON object per line in, one UTF-8 JSON object per line out. The pipe worker parses the request, synchronizes only VCL/provider capture and detached response-tree construction to the VCL main thread, serializes that detached tree on the pipe worker, and writes one response line before reading the next request. A client may send one request and close, or keep the connection open for a sequential request/response batch. Batching avoids repeated pipe connection setup during automation loops while preserving the bridge rule that VCL state is only touched on the UI thread.

For legacy applications with their own existing shutdown flow, the longer explicit form is fine:

```delphi
TAccessibilityAgentBridgePipeServer.Start('MyApp.AccessibilityBridge');
try
  TAccessibilityManager.Install(Application);
  try
    Application.Run;
  finally
    TAccessibilityManager.Uninstall;
  end;
finally
  TAccessibilityAgentBridgePipeServer.Stop;
end;
```

Mutation commands still require `TAccessibilityAgentBridge.SetMutationEnabled(True)`.

## Demo Diagnostic Switch

The complex demo exposes the bridge only when started with an explicit diagnostic switch:

```powershell
.\bin\Win32\Debug\AccessibilityComplexDemo.exe --a11y-agent-bridge --a11y-agent-bridge-pipe=MaxLogicAccessibilityDemo
```

Add `--a11y-agent-bridge-mutations` only when the automation run should use bridge mutation commands. Without that switch, the demo still allows snapshots and hit testing, but mutation commands remain disabled. The demo stops the pipe server before uninstalling the accessibility framework when `Application.Run` exits.

Verbose file diagnostics are a separate opt-in and are not enabled merely because the bridge is active:

```powershell
.\bin\Win32\Debug\AccessibilityComplexDemo.exe --a11y-diagnostics
```

The switch creates a fresh `AccessibilityComplexDemo.a11y.log` beside the executable. Log calls enqueue to a bounded background writer instead of performing file I/O on the VCL or UIA caller thread. Each run is capped at 8 MiB, queue or size-limit drops are summarized in the log, and the active file permits readers that share read and write access. The demo drains and closes diagnostics during its normal shutdown path.

## Handshake

```json
{"cmd":"hello"}
```

The response includes `ok`, `protocolVersion`, `frameworkName`, `processId`, and `mutationEnabled`. A generic computer-control tool should probe this first. If the probe fails, it should continue with generic UIA/Win32 control.

## Snapshots

```json
{"cmd":"forms.list"}
{"cmd":"window.info","target":"focused"}
{"cmd":"window.info","target":"handle","handle":123456}
{"cmd":"window.info","target":"name","name":"MainForm"}
{"cmd":"form.map","target":"focused"}
{"cmd":"form.map","target":"focused","includeAccessibility":false}
{"cmd":"form.map","target":"focused","includeAccessibility":false,"visibleOnly":true}
{"cmd":"form.map","target":"focused","detail":"geometry","visibleOnly":true}
{"cmd":"form.map","target":"handle","handle":123456}
{"cmd":"form.map","target":"name","name":"MainForm"}
{"cmd":"provider.map","target":"focused","detail":"full","maxDepth":3,"maxChildren":200}
{"cmd":"control.info","ref":"@a2"}
{"cmd":"control.info","ref":"@a2","includeAccessibility":true}
{"cmd":"controls.info","refs":["@a1","@a2","@a3"]}
{"cmd":"control.resolve","target":{"formName":"MainForm","controlName":"SaveButton"},"detail":"target"}
{"cmd":"control.resolve","ref":"@a2","detail":"target"}
{"cmd":"hitTest","x":500,"y":300}
```

`window.info` returns the selected form's name, class, caption, visibility, enabled and active state, native handle, `screenRect`, `clientRect`, `clientScreenRect`, `pixelsPerInch`, and `windowState`. Use this before taking screenshots or doing coordinate-sensitive automation because it reports process-local VCL geometry.

`form.map` returns a snapshot with refs such as `@a0`, `@a1`, and `@a2`. Refs are scoped to the latest snapshot, like browser automation element refs. Controls include VCL name, class, UIA-equivalent control type, caption, value, hint, accessible name/help text, enabled/visible/focus state, tab metadata, native handle, role-specific native state such as checkbox toggle state or selected list item, screen rectangle, and a center target point. `handle` is `0` when a control has not allocated a HWND yet; the bridge does not create hidden or lazy control windows just to report a snapshot.

`includeAccessibility` defaults to `true`. Set it to `false` for high-speed native VCL coordinate/state discovery: the bridge skips the accessibility scanner and returns process-local VCL fields only, with `accessibleName` and `helpText` blank. Use the default full snapshot when validating accessible naming, label association, or screen-reader-facing metadata.

`visibleOnly` defaults to `false`. Set it to `true` when an automation run only needs controls in the currently visible active form state. The bridge skips hidden controls and inactive tab-sheet descendants, reducing snapshot size and JSON work on large tabbed legacy forms.

`detail` defaults to `full`. Set it to `geometry` for the cheapest control-targeting map: the bridge returns refs, names, classes, UIA-equivalent role IDs/names, enabled/visible/focus state, tab metadata, native handles, screen rectangles, and center target points. Geometry detail forces `includeAccessibility:false` and skips caption/value/hint reads, accessible-name/help-text scanning, and role-specific native state. Use it when automation only needs coordinates or control identity. Use `full` when the run needs captions, hints, values, checkbox/list state, or screen-reader-facing metadata.

`form.map` is bounded by default to depth 16, 500 children per parent, and 2,000 returned controls. Requests may lower those limits or raise them only up to depth 64, 2,000 children per parent, and 10,000 controls. The response reports `maxDepth`, `maxChildren`, `maxControls`, `controlCount`, `depthTruncated`, `childrenTruncated`, and `controlsTruncated`. These bounds cap bridge traversal and response construction. A full map with `includeAccessibility:true` still performs the accessibility scan before applying output bounds; use `detail:"geometry"` or `includeAccessibility:false` when an automation request does not need scanner metadata.

For framework-enabled VCL applications, prefer `form.map` with `detail:"geometry"` over an external UIA tree walk when the task is target discovery, coordinates, or background control. The bridge reads process-local VCL state through normal RTL/VCL APIs such as `ControlCount`, `Controls[]`, `HandleAllocated`, `ClientToScreen`, and direct control properties. It deliberately avoids RTTI on the fast geometry path; RTTI is only a fallback for less common properties where no cheap typed VCL access exists.

`provider.map` returns a capped in-process snapshot of the framework provider tree. Use it when automation or diagnostics need UIA-like semantic nodes, including virtual provider children such as visible listbox items, memo lines, radio-group items, and grid cells, but do not need to validate the external UIA client/provider boundary. It walks `IAccessibilityProviderChildAccess` directly and reads common properties from provider direct-access interfaces, so it avoids PowerShell/.NET UIAutomation startup, COM marshaling, TreeWalker `Navigate` calls, and per-property external UIA round trips. For forms already installed through `TAccessibilityManager`, it reuses the live provider tree and reports `providerTreeSource:"installed"`; otherwise it builds a temporary tree and reports `providerTreeSource:"transient"`. The response includes `source:"maxlogic-provider"`, `nodeCount`, timing fields, `screenRect`, UIA-equivalent control type fields, and VCL metadata such as `vclName`/`vclClassName` when a provider maps to a VCL control. `maxDepth` defaults to 3 and is capped at 16; `maxChildren` defaults to 200 and is capped at 2,000.

The desktop-control helper's `fast-semantic-map` command automatically tries the framework default pipe name and asks `provider.map` for a semantic provider-tree snapshot before falling back to cached external UIA. Its automatic bridge probe is longer than `fast-map`'s geometry probe because missing a busy but available provider bridge is much more expensive than waiting briefly. Use it when an agent needs UIA-like semantic discovery across arbitrary Windows applications: bridge-enabled VCL apps stay on process-local provider/RTL reads, while generic applications still get the normal UIA snapshot. Bridge responses include `mapSource:"maxlogic-provider"` and `semanticBypass:true`. Cached UIA fallback responses include `fallbackAttempts`, so diagnostics can show which bridge pipe was tried and why the process-local semantic bypass was not used.

The desktop-control helper's `fast-map` command automatically tries the framework default pipe name `MaxLogicAccessibilityAgentBridge.<processId>` before falling back to the generic Win32 map. It can derive the process id from `--pid`, a `--target handle` HWND, the focused window, or a `--title-contains` match. For PID and title-based discovery, it resolves the visible top-level HWND with native Win32 enumeration and sends that handle to `form.map`, so background automation can target the intended form without depending on foreground focus. The automatic `fast-map` default-pipe probe is intentionally short; pass `--pipe-name` for custom pipe names or when a known bridge target should get the normal command timeout. The default `fast-map` detail is `geometry`; use `fast-map --detail full` when a bridge-enabled VCL app needs visible captions, values, hints, roles, and native checked/selected/list state without walking UIA. Helper wall time is reported as `elapsedMs`; when the bridge is used, the original in-process bridge timing is preserved as `bridgeElapsedMs` and `bridgeElapsedTicks`. Use that command when the agent knows the process or window target but has not separately discovered the pipe name.

Use `control.info` after a geometry map when automation needs details for only one or a few controls. It resolves a current snapshot `ref` and returns the same process-local targeting fields plus caption, value, hint, and native role-specific state for that control only. `includeAccessibility` defaults to `false` for this command, so the common enrichment path uses direct VCL/RTL reads and RTTI fallbacks without scanning the whole form. Set `includeAccessibility:true` only when validating accessible names or help text.

Use `controls.info` after a geometry map when automation needs details for several known refs. It returns a `controls` array in request order and shares one focused-HWND read, one RTTI cache, and, when `includeAccessibility:true` is requested, one accessibility scan for the batch. The default remains `includeAccessibility:false`, so the fast path enriches selected controls through process-local VCL/RTL reads without UIA traversal.

Use `control.resolve` when automation already knows a VCL form and control name and does not need a complete form map. An identity lookup replaces the current snapshot and returns one fresh ref; a current-ref lookup retains the snapshot. The target response includes form/control identity, HWND and root HWND, DPI, current screen rectangle and center point, direct visibility/enabled state, effective `canFocus`, active-form state, MDI-child state, and validity. Re-resolve after activation, movement, modal transitions, or any mutation before using coordinates.

A UIA `TreeWalker` sample is still useful when validating what UIA exposes, but the node count is not the real cost. Even a small visible tree can trigger hundreds or thousands of client/provider boundary calls (`Navigate`, `GetPropertyValue`, `GetProviderOptions`, `GetRuntimeId`, and host-provider queries), plus helper process startup when the probe is launched from a one-shot script. Provider-hotspot elapsed ticks measure only our in-process callback work; if those ticks are tiny while the external sample is slow, the correct optimization is to bypass the UIA tree walk with `form.map`, `fast-semantic-map`, `provider.map`, or `win32-map --detail geometry`, not to micro-optimize Delphi property reads. If `fast-semantic-map` returns a slow cached UIA result, inspect `fallbackAttempts` before treating the result as the preferred path. When a UIA tree really must be sampled, start from the target HWND, cap branch breadth, and use the desktop-control helper's default cached `uia-map` path so .NET UIAutomation passes a `CacheRequest` into the TreeWalker child/sibling calls and reads common descendant properties from cache instead of reading `Current.Name`, `Current.ClassName`, and similar properties one by one in the traversal loop. Use `uia-map --plain` only when comparing or debugging the slower Python `uiautomation` traversal.

`hitTest` uses VCL control geometry from the current process, not UIA, and returns the matching snapshot ref. This is useful when UIA is the thing being tested and should not be the only coordinate source.

## Diagnostics

Provider-hotspot diagnostics can be enabled while an external UIA or Win32 probe drives the application:

```json
{"cmd":"diagnostics.providerHotspots.enable"}
{"cmd":"diagnostics.providerHotspots.reset"}
{"cmd":"diagnostics.providerHotspots"}
{"cmd":"diagnostics.providerHotspots.disable"}
```

`diagnostics.providerHotspots` returns the current metrics as JSON, including provider boundary call counts such as `providerNavigateCount`, `providerGetPropertyValueCount`, `providerGetRuntimeIdCount`, `providerGetBoundingRectangleCount`, and `providerGetHostRawElementProviderCount`, plus matching `...TotalElapsedTicks` fields. It also exposes focused provider hotspots such as `stringGridCellProbeCount`, `stringGridRowProbeCount`, `tmsAdvStringGridCellProbeCount`, `memoLineProbeCount`, `listBoxSelectionItemProbeCount`, `agentBridgeChildClientOriginProbeCount`, `agentBridgeFocusProbeCount`, `providerFocusAnnouncementTextLastElapsedTicks`, `providerNotificationLastElapsedTicks`, `managerRetainedHookPassivateCount`, `managerRetainedHookLinearScanCount`, `providerRuntimeIdBlockCopyCount`, `providerRuntimeIdBlockCopyElementCount`, and `providerRuntimeIdElementCopyCount`. Use this to separate expensive UIA client/provider round trips from cheap process-local VCL reads, and to distinguish speech text construction from UIA notification dispatch when focus or hover speech feels delayed.

Supplemental event fanout is available through these counters:

- `supplementalUiaEventCount`, split into automation, property-changed, notification, and structure-changed totals
- UIA automation splits for focus, selection, and other events
- UIA property splits for toggle state, selection state, and other properties
- `supplementalMsaaEventCount`, split into focus, state-change, selection, and other WinEvents

UIA counters record successful calls made through the framework event helpers. MSAA counters record framework attempts made through the central `NotifyWinEvent` wrapper because Win32 does not report delivery success. Native events emitted directly by VCL or Windows are outside these supplemental counters. Enable the metrics only for a measurement run, reset immediately before each interaction, read the snapshot after the interaction, and disable the metrics when finished. The disabled path performs no synchronous I/O; enabled collection uses the existing in-memory diagnostics lock.

## Mutations

Mutations are disabled by default:

```delphi
TAccessibilityAgentBridge.SetMutationEnabled(True);
```

Supported mutation commands:

```json
{"cmd":"control.focus","ref":"@a1"}
{"cmd":"control.click","ref":"@a2"}
{"cmd":"control.setText","ref":"@a1","text":"exact text"}
{"cmd":"control.typeText","ref":"@a1","text":" appended text"}
{"cmd":"keyboard.tab"}
```

Mutation responses include `snapshotInvalidated: true`, `mutationSemantics`, `humanEquivalent`, `userInputEventsGenerated`, and `mayBlockSynchronously`. Automation should resolve again after a mutation before making coordinate-sensitive decisions.

`control.setText` and the historically named `control.typeText` both report `mutationSemantics:"raw-property-assignment"`. The latter appends to the VCL `Text` property; neither command represents human typing or guarantees keyboard input events (`userInputEventsGenerated:false`). Use guarded operating-system input when normal key processing is part of the proof.

`control.click` invokes VCL behavior synchronously and reports `mayBlockSynchronously:true`; do not use it to open a modal dialog on a pipe connection that must remain responsive. Use guarded operating-system input and discover the modal through a separate request instead. `keyboard.tab` performs keyboard-equivalent VCL navigation but does not synthesize a Tab key.

A failed `control.focus` returns `focus_failed` with a fresh narrow `control` target, relevant `ancestors`, and a `recommendedFallback`. Treat it as a refusal: inspect disabled/hidden parent or form state, activate the reported root HWND, resolve again, and use a guarded OS click only when the refreshed target is actionable.

Framework mutations are diagnostic helpers. End-to-end acceptance tests should still prefer real OS input for user actions, then use the bridge to cross-check coordinates, labels, focus state, and logs.

## Agent-control safety boundary

Bridge evidence is not NVDA evidence. The bridge can prove native VCL state and help an agent control an application, but it does not observe or certify screen-reader speech. Audible desktop-control takeover and release announcements protect the human operator; they are not application accessibility output.

For foreground input, use the desktop-control helper's bounded `foreground-session` lease. Keep one session for one short logical interaction, pass its session ID to every real-input command, and renew it only around a bounded condition wait. The detached watchdog announces release if the lease expires or its controller exits.

After activation, movement, DPI changes, page changes, mutations, form creation, or modal transitions, refs and geometry expire. Resolve the target again and verify current root PID/HWND, visibility, enabled state, ownership, and foreground state immediately before input.

Never call `control.click` for a modal opener when the same sequential pipe must inspect the resulting dialog. Invoke the opener through guarded OS input, let that helper command return, then use a separate bounded discovery request. Raw `control.setText` and `control.typeText` remain property assignment; use guarded keyboard input when event-producing behavior is under test.

## Threading

`TAccessibilityAgentBridge.Execute` remains a main-thread-only API and rejects calls from other threads. Custom transports must marshal the call or reproduce the built-in transport split without allowing VCL controls, provider interfaces, or scanner objects to escape the main thread.

The built-in pipe transport performs request parsing and response serialization on its worker. Its synchronized callback captures VCL/provider state and builds an owned JSON value tree containing only detached values. After the callback returns, the worker serializes that tree without dereferencing VCL or provider objects.

Every built-in transport response includes high-resolution phase telemetry:

- `parseElapsedMs` / `parseElapsedTicks`: request JSON parsing on the pipe worker
- `captureBuildElapsedMs` / `captureBuildElapsedTicks`: VCL/provider capture and detached response construction on the main thread
- `synchronizedElapsedMs` / `synchronizedElapsedTicks`: total work inside the synchronized callback, excluding time queued waiting for the VCL thread
- `serializationElapsedMs` / `serializationElapsedTicks`: detached response-body serialization on the pipe worker
- `elapsedMs` / `elapsedTicks`: parsing, synchronization queue wait, synchronized work, and body serialization; it excludes pipe I/O and final timing-suffix construction
- `stopwatchFrequency`, `parseThreadId`, `captureThreadId`, and `serializationThreadId`: conversion and thread-ownership evidence

For direct `Execute` calls, capture and serialization both occur on the calling VCL thread. For pipe requests, `captureThreadId` must be the VCL main thread and `parseThreadId`/`serializationThreadId` must be the pipe worker.
