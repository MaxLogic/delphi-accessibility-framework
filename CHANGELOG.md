# Changelog

## 2026-06-18
### Fixed
- TMS `TAdvStringGrid` merged-cell UIA spans now count only visible rows and columns when hidden coordinates are inside the merged range.
- Custom/balloon hint announcements now use the final hint text after a control mutates `Hint` in `OnMouseEnter`.
- Disabled `TSpeedButton` UIA Invoke/Toggle automation no longer triggers button clicks or toggles `Down`.

### Added
- Added custom adapter registry overloads for `TAccessibilityManager.Install(Application, Registry)` and `Install(Form, Registry)`, enabling opt-in TMS `TAdvStringGrid` support through the manager path.
- Added adoption documentation, UIA probe documentation, and an NVDA manual checklist for the current VCL accessibility coverage.
- Added opt-in UIA DataGrid/cell provider support for TMS `TAdvStringGrid`, including stripped HTML text, wide text fallback, per-cell hit testing, current-cell focus, hidden row/column remapping, and scrolled-cell pruning.
- Added UIA DataGrid/cell provider support for VCL `TStringGrid`, including per-cell hit testing, current-cell focus, and hidden-cell omission.
- Added UIA notification support for VCL hints and balloon hints, including app-wide/scoped install wiring and duplicate-speech suppression.
- Added UIA-first VCL adapters and probe coverage for labels, speed buttons, panels, and generic graphic controls.
- Added a VCL form scanner, adapter registry, text extraction fallback pipeline, and runtime control-change observer.
- Added `TAccessibilityManager.Install(Application)` and `Install(Form)` entry points for app-wide and scoped form accessibility installation.
- Added UI Automation provider core support for fragments, runtime IDs, lifecycle disconnects, and gated UIA events.
- Added Delphi UI Automation core bindings for the first provider implementation slices.
