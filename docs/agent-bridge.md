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

The pipe protocol is one UTF-8 JSON object per line in, one UTF-8 JSON object per line out. The server accepts one request per connection, executes `TAccessibilityAgentBridge.Execute` on the VCL main thread, writes the response line, then disconnects. This keeps the transport small while preserving the bridge rule that VCL state is only touched on the UI thread.

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
{"cmd":"form.map","target":"handle","handle":123456}
{"cmd":"form.map","target":"name","name":"MainForm"}
{"cmd":"hitTest","x":500,"y":300}
```

`window.info` returns the selected form's name, class, caption, visibility, enabled and active state, native handle, `screenRect`, `clientRect`, `clientScreenRect`, `pixelsPerInch`, and `windowState`. Use this before taking screenshots or doing coordinate-sensitive automation because it reports process-local VCL geometry.

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

Commands must run on the VCL main thread. The built-in pipe server does this marshalling before calling `Execute`; custom pipe, HTTP, or window-message transports must do the same. The bridge intentionally rejects background-thread calls instead of touching VCL controls off-thread.
