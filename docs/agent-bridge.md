# Agent Bridge

`MaxLogic.Accessibility.AgentBridge` exposes a small JSON command executor for diagnostic automation. It is intended for tools that already control the desktop through UIA, Win32, or `SendInput`, but need framework-specific VCL facts that UIA may not expose reliably.

The bridge does not start a pipe, HTTP server, or window-message listener by itself. Applications or test harnesses choose the transport and call `TAccessibilityAgentBridge.Execute` on the VCL main thread.

## Handshake

```json
{"cmd":"hello"}
```

The response includes `ok`, `protocolVersion`, `frameworkName`, `processId`, and `mutationEnabled`. A generic computer-control tool should probe this first. If the probe fails, it should continue with generic UIA/Win32 control.

## Snapshots

```json
{"cmd":"forms.list"}
{"cmd":"form.map","target":"focused"}
{"cmd":"form.map","target":"handle","handle":123456}
{"cmd":"form.map","target":"name","name":"MainForm"}
{"cmd":"hitTest","x":500,"y":300}
```

`form.map` returns a snapshot with refs such as `@a0`, `@a1`, and `@a2`. Refs are scoped to the latest snapshot, like browser automation element refs. Controls include VCL name, class, caption, value, hint, accessible name/help text, enabled/visible/focus state, tab metadata, native handle, screen rectangle, and a center target point.

`hitTest` uses VCL control geometry from the current process, not UIA, and returns the matching snapshot ref. This is useful when UIA is the thing being tested and should not be the only coordinate source.

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

Mutation responses include `snapshotInvalidated: true`. Automation should request a fresh `form.map` after a mutation before making coordinate-sensitive decisions.

Framework mutations are diagnostic helpers. End-to-end acceptance tests should still prefer real OS input for user actions, then use the bridge to cross-check coordinates, labels, focus state, and logs.

## Threading

Commands must run on the VCL main thread. A future pipe or HTTP transport should marshal requests onto the UI thread before calling `Execute`; the bridge intentionally rejects background-thread calls instead of touching VCL controls off-thread.
