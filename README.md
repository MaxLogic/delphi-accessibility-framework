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

## Current Coverage

The default VCL adapter registry covers:

- `TLabel`: UIA text fragment with caption-derived name and hint-derived help text.
- `TSpeedButton`: UIA button fragment with Invoke and toggle support when the button has toggle semantics.
- `TPanel`: UIA pane when the panel has useful text or accessible children; decorative empty panels are omitted.
- Generic `TGraphicControl`: text fallback for caption/text/hint-style controls.
- VCL hints: control `Hint` is exposed as UIA `HelpText`, and visible hint text raises a UIA notification when UIA clients are listening.
- VCL balloon hints: title and description are exposed through UIA notification text without requiring MaxLogicFoundation.
- `TStringGrid`: UIA DataGrid/DataItem providers for visible cells, per-cell hit testing, current-cell focus, and hidden-cell omission.

TMS `TAdvStringGrid` support is available in the opt-in unit `MaxLogic.Accessibility.TmsAdvStringGridAdapters`. It keeps ordinary applications from compiling TMS units unless they explicitly include the adapter.

The current TMS adapter is a provider-builder diagnostic path and custom provider construction path. It is not yet wired into `TAccessibilityManager.Install(Application)` or `TAccessibilityManager.Install(Form)`, so the custom-registry manager install path is deferred. Use the default manager install for VCL-only forms; use the builder path below when validating or embedding a custom provider root yourself:

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

## Diagnostics

Canonical commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario All
```

UIA probe scenarios:

- `BasicVclControls`: labels, speed buttons, panels, generic graphic controls, and decorative-control omission.
- `Hints`: help text, visible hint notifications, duplicate throttling, and balloon hint notifications.
- `TStringGridCells`: VCL `TStringGrid` DataGrid provider, visible cell providers, per-cell hit testing, current-cell focus, hidden-cell omission, and cell-only names.
- `TAdvStringGridCells`: opt-in TMS `TAdvStringGrid` DataGrid provider, stripped HTML text, wide text fallback, per-cell hit testing, focus, hidden row/column remapping, hidden-cell omission, and scrolled-cell pruning.

The smoke app lives in `projects\MaxLogicAccessibilityFrameworkSmoke.dpr`. The probe script builds it before executing each scenario and expects `UIA_PROBE_OK` output for success.

See also:

- `docs\uia-probe.md`
- `docs\nvda-checklist.md`

## Known limits

- Windows VCL and Microsoft UI Automation are the first supported target. FMX, non-Windows platforms, and an MSAA compatibility bridge are deferred.
- `TAccessibilityManager.Install(Application)` discovers future forms when `Screen.OnActiveFormChange` fires. Forms that are created and never become active should call `TAccessibilityManager.Install(Form)` explicitly after their controls exist.
- The public manager API currently uses the default VCL registry. TMS `TAdvStringGrid` support is opt-in through `MaxLogic.Accessibility.TmsAdvStringGridAdapters`, and the custom-registry manager install path is deferred.
- Automatic label-to-input relationships such as `LabeledBy` inference are not implemented yet.
- TMS merged cells whose base cell is hidden are omitted rather than promoted from a visible merged fragment, because TMS stores text and span metadata on the hidden base coordinate.
- Screen-reader speech varies by reader and settings. The UIA probe is automated proof of provider behavior; the NVDA checklist remains the manual acceptance pass for spoken output.
