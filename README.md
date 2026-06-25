# MaxLogic Delphi Accessibility Framework

UIA-first accessibility helpers for Delphi 12 VCL applications.

The framework exposes normally invisible or weakly exposed VCL controls through Microsoft UI Automation provider fragments. It does not use the old overlay/static-text approach as the main design; providers are attached to forms and returned through `WM_GETOBJECT`.

## Install

For normal application-wide adoption, install once after the application creates its initial forms:

```delphi
uses
  Vcl.Forms,
  MaxLogic.Accessibility.Manager;

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  TAccessibilityManager.Install(Application);
  Application.Run;
end.
```

`TAccessibilityManager.Install(Application)` scans all current `Screen.Forms`, installs each form once, observes VCL hint and balloon hint activity, and hooks `Screen.OnActiveFormChange` so future active forms are discovered and installed. Existing `OnActiveFormChange` handlers are chained.

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
    TAccessibilityManager.Install(Application);
  end;
  Application.Run;
end.
```

`TAccessibilityScreenReaderDetector.Detect` reports both underlying signals. `SPI_GETSCREENREADER` is the Windows screen-reader system parameter, but not every reader sets it. `UiaClientsAreListening` means a UI Automation client subscribed to events; that is useful for enabling provider/event work, but it is not a guaranteed screen-reader identity.

## Current Coverage

The default VCL adapter registry covers:

- `TLabel`: UIA text fragment with caption-derived name and hint-derived help text.
- `TButton`: UIA button fragment with caption-derived name, hint-derived help text, native window handle, and Invoke support.
- `TSpeedButton`: UIA button fragment with Invoke and toggle support when the button has toggle semantics.
- `TComboBox`: UIA combo-box fragment with associated label/name, value text, help text, and native window handle.
- `TCheckBox`: UIA checkbox fragment with caption-derived name, hint-derived help text, native window handle, Toggle support, and MSAA checkbutton state. Mouse-over uses platform object/state events instead of framework-injected state words so screen readers can localize role and state.
- `TRadioButton`: UIA radio-button fragment with caption-derived name, hint-derived help text, native window handle, SelectionItem support, and MSAA radio-button selected state. Radio buttons intentionally do not expose TogglePattern.
- `TGroupBox` and `TRadioGroup`: UIA group fragments for named option regions.
- `TPanel`: UIA pane when the panel has useful text or accessible children; decorative empty panels are omitted.
- `TPageControl` and `TTabSheet`: UIA tab/tab-item fragments for page-control tab headers.
- `TToolBar` and `TToolButton`: UIA toolbar/button fragments for toolbar commands.
- Generic `TGraphicControl`: text fallback for caption/text/hint-style controls.
- VCL hints: control `Hint` is exposed as UIA `HelpText`, and visible hint text raises a UIA notification when UIA clients are listening.
- VCL balloon hints: title and description are exposed through UIA notification text without requiring MaxLogicFoundation.
- `TMemo`: UIA edit provider with per-line mouse hit testing while keyboard caret navigation remains with the native edit behavior.
- `TListBox`: UIA list/list-item providers for mouse hit testing, selection, and arrow-key item focus.
- `TStatusBar`: UIA status-bar provider using the visible simple-panel or panel text.
- `TStringGrid`: UIA DataGrid/DataItem providers for visible cells, per-cell hit testing, current-cell focus, and hidden-cell omission.

TMS `TAdvStringGrid` support is available in the opt-in unit `MaxLogic.Accessibility.TmsAdvStringGridAdapters`. It keeps ordinary applications from compiling TMS units unless they explicitly include the adapter.

For app-wide TMS support, install with the opt-in registry:

```delphi
uses
  Vcl.Forms,
  MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.TmsAdvStringGridAdapters;

begin
  TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
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

The opt-in TMS registry includes the default VCL adapters plus `TAdvStringGrid` DataGrid/DataItem support for stripped HTML text, wide text fallback, per-cell hit testing, current-cell focus, hidden column and hidden row remapping, merged-cell spans that count visible coordinates, and scrolled-cell pruning.

MaxLogicFoundation remains independent. The framework can be used without MaxLogicFoundation, and MaxLogicFoundation does not depend on this framework.

## Native Fallback

The manager only returns framework providers for controls that are part of the framework scan tree or for non-focusable containers needed to hit-test descendant providers. Focusable windowed controls without a framework adapter are left unhooked so their native `WM_GETOBJECT`/MSAA/UIA implementation can still answer screen readers.

For controls such as `TVirtualStringTree` that already provide their own accessibility, do not register a framework adapter unless the framework is meant to replace that native tree. If a custom adapter is registered, it becomes the explicit accessibility surface for that control.

## Diagnostics

Canonical commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario All
```

UIA probe scenarios:

- `BasicVclControls`: labels, buttons, speed buttons, checkboxes, panels, generic graphic controls, and decorative-control omission.
- `Hints`: help text, visible hint notifications, duplicate throttling, and balloon hint notifications.
- `MemoListStatus`: manager-installed memo line hit testing, listbox item hover/focus notifications, and statusbar text hover.
- `TStringGridCells`: VCL `TStringGrid` DataGrid provider, visible cell providers, per-cell hit testing, current-cell focus, hidden-cell omission, and cell-only names.
- `TAdvStringGridCells`: opt-in TMS `TAdvStringGrid` DataGrid provider, stripped HTML text, wide text fallback, per-cell hit testing, focus, hidden row/column remapping, hidden-cell omission, and scrolled-cell pruning.

The smoke app lives in `projects\MaxLogicAccessibilityFrameworkSmoke.dpr`. The probe script builds it before executing each scenario and expects `UIA_PROBE_OK` output for success.

See also:

- `docs\uia-probe.md`
- `docs\nvda-checklist.md`

## Known limits

- Windows VCL and Microsoft UI Automation are the first supported target. The framework includes an MSAA bridge for supported provider fragments when screen readers enter through classic accessibility APIs. FMX and non-Windows platforms are deferred.
- `TAccessibilityManager.Install(Application)` discovers future forms when `Screen.OnActiveFormChange` fires. Forms that are created and never become active should call `TAccessibilityManager.Install(Form)` explicitly after their controls exist.
- Changing the app-wide or form-scoped adapter registry after accessibility is installed requires `TAccessibilityManager.Uninstall` first. This avoids silently mixing default and custom provider trees.
- Registry compatibility is instance-based. Repeated custom installs should reuse the same registry instance, or call `TAccessibilityManager.Uninstall` before switching to another registry.
- Automatic label-to-input relationships such as `LabeledBy` inference are not implemented yet.
- TMS merged cells whose base cell is hidden are omitted rather than promoted from a visible merged fragment, because TMS stores text and span metadata on the hidden base coordinate.
- Screen-reader speech varies by reader and settings. The UIA probe is automated proof of provider behavior; the NVDA checklist remains the manual acceptance pass for spoken output.
