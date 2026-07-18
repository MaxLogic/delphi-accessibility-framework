# UIA Probe

The UIA probe is the automated integration check for the sample VCL app. Run commands from the repository root. The script defaults to `Debug` and `Win32`, builds the smoke executable, runs a scenario, and verifies that the expected provider behavior prints `UIA_PROBE_OK`.

Run every scenario:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario All
```

The same command can be run as `scripts\run-uia-probe.ps1 -Scenario All` from a PowerShell session that already allows script execution.

Supported scenarios:

- `BasicVclControls`: verifies `TLabel`, `TButton`, `TSpeedButton`, `TCheckBox`, `TPanel`, generic `TGraphicControl`, nested fragments, Invoke/Toggle patterns, and decorative-control omission.
- `Hints`: verifies UIA `HelpText`, visible hint notification text, duplicate throttling, direct balloon hint notifications, and manager-installed balloon hint observation.
- `MemoListStatus`: verifies manager-installed `TMemo` line hit testing, `TListBox` item hover, native-HWND listbox focus speech routing, and `TStatusBar` visible status text hover.
- `TStringGridCells`: verifies the VCL `TStringGrid` DataGrid provider, visible cell providers, `ElementProviderFromPoint` returning only the hovered cell, current-cell focus, hidden-cell omission, and cell-only names.
- `TAdvStringGridCells`: verifies opt-in manager-installed TMS `TAdvStringGrid` DataGrid support, stripped HTML cell text, wide text fallback, hidden-base merged-cell text and visible spans, GridItem coordinates, focus and hit testing, fully hidden merge omission, hidden row/column remapping, hidden-cell omission, and scrolled-cell pruning.

Individual examples:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario BasicVclControls
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario Hints
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario MemoListStatus
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario TStringGridCells
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-uia-probe.ps1 -Scenario TAdvStringGridCells
```

Expected success markers:

```text
UIA_PROBE_OK BasicVclControls:
UIA_PROBE_OK Hints:
UIA_PROBE_OK MemoListStatus:
UIA_PROBE_OK TStringGridCells:
UIA_PROBE_OK TAdvStringGridCells:
```

The probe is not a replacement for a live screen reader pass. It validates provider properties, fragment navigation, hit testing, focus, and notification routing without requiring NVDA to be installed on every build machine.

For broad control discovery or coordinate targeting, prefer the agent bridge `form.map` geometry snapshot or a native Win32 HWND map. Use `win32-map --detail geometry` when HWND coordinates are enough; it avoids UIA traversal and skips per-HWND title reads. A UIA tree walk is a semantic verification tool, not a cheap geometry source: a small node count can still produce hundreds of provider/client boundary calls. When semantic discovery is needed but the external UIA boundary is not the thing under test, use `fast-semantic-map` so bridge-enabled VCL apps answer from the in-process `provider.map` tree and generic apps fall back to cached UIA. When a broad UIA tree sample is required, start from the target HWND instead of the desktop root where possible, cap branch breadth, and use `uia-map --detail geometry` when rectangles and tree shape are enough. For semantic UIA probes, use the default cached `uia-map` path so the helper passes a .NET UIAutomation `CacheRequest` into the TreeWalker child/sibling calls and reads common descendant properties from the cache instead of `Current.*` properties inside the traversal loop. Use `uia-map --plain` only when comparing or debugging the slower Python `uiautomation` traversal.
