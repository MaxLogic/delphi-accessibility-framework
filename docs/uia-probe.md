# UIA Probe

The UIA probe is the automated integration check for the sample VCL app. Run commands from the repository root. The script defaults to `Debug` and `Win32`, builds the smoke executable, runs a scenario, and verifies that the expected provider behavior prints `UIA_PROBE_OK`.

Run every scenario:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario All
```

The same command can be run as `scripts\run-uia-probe.ps1 -Scenario All` from a PowerShell session that already allows script execution.

Supported scenarios:

- `BasicVclControls`: verifies `TLabel`, `TSpeedButton`, `TPanel`, generic `TGraphicControl`, nested fragments, Invoke/Toggle patterns, and decorative-control omission.
- `Hints`: verifies UIA `HelpText`, visible hint notification text, duplicate throttling, direct balloon hint notifications, and manager-installed balloon hint observation.
- `TStringGridCells`: verifies the VCL `TStringGrid` DataGrid provider, visible cell providers, `ElementProviderFromPoint` returning only the hovered cell, current-cell focus, hidden-cell omission, and cell-only names.
- `TAdvStringGridCells`: verifies opt-in manager-installed TMS `TAdvStringGrid` DataGrid support, stripped HTML cell text, wide text fallback, hidden row/column remapping, per-cell hit testing, current-cell focus, hidden-cell omission, and scrolled-cell pruning.

Individual examples:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario BasicVclControls
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario Hints
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario TStringGridCells
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario TAdvStringGridCells
```

Expected success markers:

```text
UIA_PROBE_OK BasicVclControls:
UIA_PROBE_OK Hints:
UIA_PROBE_OK TStringGridCells:
UIA_PROBE_OK TAdvStringGridCells:
```

The probe is not a replacement for a live screen reader pass. It validates provider properties, fragment navigation, hit testing, focus, and notification routing without requiring NVDA to be installed on every build machine.
