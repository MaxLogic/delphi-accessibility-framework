# MaxLogic Delphi Accessibility Framework

UIA-first accessibility helpers for Delphi 12 VCL applications.

The framework exposes normally invisible or weakly exposed VCL controls through Microsoft UI Automation provider fragments. It does not use the old overlay/static-text approach as the main design; providers are attached to forms and returned through `WM_GETOBJECT`.

## Install

For normal application-wide adoption, create the initial forms as usual and replace the VCL `Application.Run` line:

```delphi
uses
  Vcl.Forms,
  MaxLogic.Accessibility.Manager;

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  TAccessibilityManager.Run(Application);
end.
```

`TAccessibilityManager.Run(Application)` installs the framework, runs the normal VCL message loop, and uninstalls the framework in a `finally` block when `Application.Run` returns.

If the application already owns the `Application.Run` block, for example because it has existing startup/shutdown code around it, use the explicit lifecycle instead:

```delphi
TAccessibilityManager.Install(Application);
try
  Application.Run;
finally
  TAccessibilityManager.Uninstall;
end;
```

`TAccessibilityManager.Install(Application)` scans all current `Screen.Forms`, installs each form once, observes VCL hint and balloon hint activity, and hooks `Screen.OnActiveFormChange` so future active forms are discovered and installed. Existing `OnActiveFormChange` handlers are chained. Both `TAccessibilityManager.Install` and `TAccessibilityManager.Uninstall` are idempotent when repeated with the same active adapter registry.

For a scoped rollout, install one form only:

```delphi
uses
  MaxLogic.Accessibility.Manager;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TAccessibilityManager.Install(Self);
end;
```

`TAccessibilityManager.Install(Form)` installs accessibility for that form and its controls without enabling app-wide form discovery.

Installed VCL form providers automatically reconcile controls added, removed, or reparented at runtime. Lookup, navigation, and hit testing reflect the current hierarchy without reinstalling the form, retained providers for removed controls become unavailable, controls may be freed before the next idle reconciliation without stale-cache access violations, and retained form/control providers release destroyed UIA HWND mappings before following replacement HWNDs created by VCL window recreation.

Call `TAccessibilityManager.Uninstall` to remove the framework hooks, hint observers, and installed form providers. The complex demo exposes this as an `Accessibility enabled` checkbox so manual NVDA testing can compare the framework-on and framework-off behavior in the same process.

Applications that want to enable the framework only when assistive technology is likely active can use the screen-reader detector:

```delphi
uses
  Vcl.Forms,
  MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.ScreenReaders;

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  if TAccessibilityScreenReaderDetector.IsLikelyActive then
  begin
    TAccessibilityManager.Run(Application);
  end else begin
    Application.Run;
  end;
end.
```

`TAccessibilityScreenReaderDetector.Detect` reports both underlying signals. `SPI_GETSCREENREADER` is the Windows screen-reader system parameter, but not every reader sets it. `UiaClientsAreListening` means a UI Automation client subscribed to events; that is useful for enabling provider/event work, but it is not a guaranteed screen-reader identity.

## Current Coverage

The default VCL adapter registry covers:

- `TLabel`: UIA text fragment with caption-derived name and hint-derived help text.
- `TButton`: UIA button fragment with caption-derived name, hint-derived help text, native window handle, and Invoke support.
- `TSpeedButton`: UIA button fragment with Invoke and toggle support when the button has toggle semantics.
- `TEdit`, `TLabeledEdit`, and `TComboBox`: UIA input fragments with associated label/name, value text, help text, and native window handles where applicable. `UIA_LabeledByPropertyId` returns the exact visible label provider for explicit `TCustomLabel.FocusControl` and `TLabeledEdit.EditLabel` relationships, or for one unambiguous adjacent same-parent label above or beside the input. Installed providers refresh that relationship after runtime association, movement, addition, removal, or reparenting, and the existing accessible Name fallback remains available.
- `TCheckBox`: UIA checkbox fragment with caption-derived name, hint-derived help text, native window handle, Toggle support, and MSAA checkbutton state when reached through the framework tree. The manager preserves the real checkbox HWND accessibility path. On hover it also raises a UIA focus event from the framework provider and emits native HWND focus/state WinEvents, so screen readers can query state without framework-injected English state text.
- `TRadioButton`: UIA radio-button fragment with caption-derived name, hint-derived help text, native window handle, SelectionItem support, and MSAA radio-button selected state when reached through the framework tree. The manager preserves the real standalone radio-button HWND accessibility path. On hover it also raises a UIA focus event from the framework provider and emits native HWND focus/state WinEvents. Radio buttons intentionally do not expose TogglePattern.
- `TGroupBox` and `TRadioGroup`: UIA group fragments for named option regions. `TRadioGroup` internal button hover is routed to the framework radio-item provider instead of treating the private child buttons as standalone radio controls.
- `TPanel`: UIA pane when the panel has useful text or accessible children; decorative empty panels are omitted.
- `TPageControl` and `TTabSheet`: UIA tab/tab-item fragments for page-control tab headers.
- `TToolBar` and `TToolButton`: UIA toolbar/button fragments for toolbar commands.
- Generic `TGraphicControl`: text fallback for caption/text/hint-style controls.
- VCL hints: control `Hint` is exposed as UIA `HelpText`, and visible hint text raises a UIA notification when UIA clients are listening.
- Runtime properties: installed providers expose current Name, HelpText, Value, enabled/offscreen state, and bounds for supported VCL forms and controls, and publish corresponding UIA property changes and MSAA notifications when those effective values change. This includes status-bar HelpText and `TStringGrid`/opt-in `TAdvStringGrid` root Name and HelpText.
- VCL balloon hints: title and description are exposed through UIA notification text without requiring MaxLogicFoundation.
- `TMemo`: UIA edit provider with per-line mouse hit testing while keyboard caret navigation remains with the native edit behavior.
- `TListBox`: UIA list/list-item providers remain available in the framework form tree for mouse hit testing and selection queries, while the real listbox HWND keeps the native accessibility path for fast arrow-key item focus speech.
- `TStatusBar`: UIA status-bar provider using the visible simple-panel or panel text.
- `TStringGrid`: UIA DataGrid/DataItem providers for visible cells, per-cell hit testing, current-cell focus, hidden-cell omission, and runtime cell-value and row/column reconciliation.

TMS `TAdvStringGrid` support is available in the opt-in unit `MaxLogic.Accessibility.TmsAdvStringGridAdapters`. It keeps ordinary applications from compiling TMS units unless they explicitly include the adapter.

For app-wide TMS support or another custom adapter registry, use the explicit lifecycle:

```delphi
uses
  Vcl.Forms,
  MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.TmsAdvStringGridAdapters;

begin
  TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
  try
    Application.Run;
  finally
    TAccessibilityManager.Uninstall;
  end;
end;
```

For one form, use the scoped overload:

```delphi
uses
  MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.TmsAdvStringGridAdapters;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TAccessibilityManager.Install(Self, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
end;
```

Use the direct provider builder only for diagnostics or for applications that intentionally embed a custom provider root themselves:

```delphi
uses
  MaxLogic.Accessibility.TmsAdvStringGridAdapters,
  MaxLogic.Accessibility.VclAdapters;

lProvider := TAccessibilityVclProviderBuilder.BuildForm(
  Form,
  TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
```

The opt-in TMS registry includes the default VCL adapters plus `TAdvStringGrid` DataGrid/DataItem support for stripped HTML text, wide text fallback, per-cell hit testing, current-cell focus, hidden column and hidden row remapping, visible representatives for merged ranges whose base row or column is hidden, merged-cell spans that count visible coordinates, fully hidden merge omission, scrolled-cell pruning, and runtime cell-value and row/column reconciliation.

MaxLogicFoundation remains independent. The framework can be used without MaxLogicFoundation, and MaxLogicFoundation does not depend on this framework.

## Native Fallback

The manager only returns framework providers for controls that are part of the framework scan tree or for non-focusable containers needed to hit-test descendant providers. Focusable windowed controls without a framework adapter are left unhooked so their native `WM_GETOBJECT`/MSAA/UIA implementation can still answer screen readers. Standard VCL `TCheckBox`, standalone `TRadioButton`, `TListBox`, and `TCheckListBox` controls remain on their native HWND accessibility path even though the framework keeps provider fragments for form-tree traversal; their child window hook observes hover/focus but does not answer `WM_GETOBJECT` for those native-HWND paths.

For controls such as `TVirtualStringTree` that already provide their own accessibility, do not register a framework adapter unless the framework is meant to replace that native tree. If a custom adapter is registered, it becomes the explicit accessibility surface for that control.

Negative hover caching is conservative for custom providers. Built-in form, panel, and group-box providers implement `IAccessibilityVclHoverGeometryPartition` only when their direct VCL child rectangles fully describe every possible hover target. A custom provider with virtual or non-VCL children should not implement this optional interface. A custom provider may opt in by implementing it and returning `True` only when the same direct-child geometry guarantee holds; otherwise the manager resolves every hover point so virtual targets cannot be hidden by a stale miss.

## Diagnostics

### Agent Bridge

`MaxLogic.Accessibility.AgentBridge` exposes a JSON command executor for diagnostic automation. It supports a `hello` probe, visible form listing, `form.map` snapshots with Playwright-style refs such as `@a1`, VCL coordinate hit testing, and gated mutation commands including `control.focus`, `control.click`, `control.setText`, `control.typeText`, and `keyboard.tab`. For fast automation coordinate discovery, `form.map` also supports `detail:"geometry"` with `visibleOnly:true`, returning process-local VCL roles, handles, rectangles, and target points without UIA traversal or accessibility/text-state scanning.

`MaxLogic.Accessibility.AgentBridge.PipeServer` provides the built-in local named pipe transport. `TAccessibilityAgentBridgePipeServer.Start` opens a process-specific pipe by default, accepts one or more sequential UTF-8 JSON request lines per connection, marshals each command onto the VCL main thread, and returns one UTF-8 JSON response line per request. `Start` and `Stop` are idempotent for the same pipe name.

A large legacy application can still expose the core executor through its own pipe, local HTTP endpoint, or debug window-message handler and call `TAccessibilityAgentBridge.Execute` on the VCL main thread. Mutations are disabled by default and require `TAccessibilityAgentBridge.SetMutationEnabled(True)`.

See `docs\agent-bridge.md` for the command contract.

Canonical commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario All
```

UIA probe scenarios:

- `BasicVclControls`: labels, buttons, speed buttons, checkboxes, panels, generic graphic controls, explicit/`TLabeledEdit`/inferred `LabeledBy` relationships, ambiguous and unlabeled rejection, and decorative-control omission.
- `Hints`: help text, visible hint notifications, duplicate throttling, and balloon hint notifications.
- `MemoListStatus`: manager-installed memo line hit testing, listbox item provider coverage through the framework tree, native-HWND listbox focus speech, and statusbar text hover.
- `TStringGridCells`: VCL `TStringGrid` DataGrid provider, visible cell providers, per-cell hit testing, current-cell focus, hidden-cell omission, and cell-only names.
- `TAdvStringGridCells`: opt-in TMS `TAdvStringGrid` DataGrid provider, stripped HTML text, wide text fallback, hidden-base merged-cell text and spans, GridItem coordinates, per-cell hit testing, focus, fully hidden merge omission, hidden row/column remapping, hidden-cell omission, and scrolled-cell pruning.

The smoke app lives in `projects\MaxLogicAccessibilityFrameworkSmoke.dpr`. The probe script builds it before executing each scenario and expects `UIA_PROBE_OK` output for success.

The complex demo's `Dynamic content` tab also provides a deterministic `Next runtime sync step` walkthrough for live NVDA correlation. Its isolated steps cover runtime form/control properties, control add/reparent/remove, explicit/inferred/`TLabeledEdit` relationship changes, `TStringGrid` and `TAdvStringGrid` value/shape changes, and control/form HWND recreation. See `docs\nvda-checklist.md` for the expected sequence.

See also:

- `docs\uia-probe.md`
- `docs\nvda-checklist.md`

## Known limits

- Windows VCL with Microsoft UI Automation is the supported target. The framework includes an MSAA bridge for supported provider fragments when screen readers enter through classic accessibility APIs. FMX and non-Windows platforms are out of scope.
- `TAccessibilityManager.Install(Application)` discovers future forms when `Screen.OnActiveFormChange` fires. Forms that are created and never become active should call `TAccessibilityManager.Install(Form)` explicitly after their controls exist.
- Changing the app-wide or form-scoped adapter registry after accessibility is installed requires `TAccessibilityManager.Uninstall` first. This avoids silently mixing default and custom provider trees.
- Registry compatibility is instance-based. Repeated custom installs should reuse the same registry instance, or call `TAccessibilityManager.Uninstall` before switching to another registry.
- Screen-reader speech varies by reader and settings. The UIA probe is automated proof of provider behavior; the NVDA checklist remains the manual acceptance pass for spoken output.
- For HWND-backed controls whose native accessibility is intentionally preserved, an external `AutomationElement.FocusedElement` query can resolve the native Win32 proxy rather than the framework fragment. Validate framework-specific properties such as inferred `LabeledBy` through the framework provider tree or the external `AutomationFocusChanged` event sender; the native proxy's independent label heuristic is outside the framework's control.
