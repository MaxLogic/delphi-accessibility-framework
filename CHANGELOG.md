# Changelog

## 2026-06-26
### Added
- Added `TAccessibilityManager.Run(Application)` as a one-call app-wide lifecycle helper that installs accessibility, runs the VCL message loop, and uninstalls on shutdown.
- Added `MaxLogic.Accessibility.AgentBridge`, a VCL-main-thread JSON command executor for diagnostic automation with framework handshake, form maps, VCL hit testing, and gated mutation commands.
- Added `MaxLogic.Accessibility.AgentBridge.PipeServer`, an opt-in local named pipe transport for the agent bridge.

### Fixed
- `TCheckBox` and standalone `TRadioButton` hover now keep the native HWND accessibility path, raise a state-capable UIA focus event from the framework provider, and nudge the native HWND with focus/state WinEvents so screen readers can query localized checked/selected state without framework-injected English state text.
- `TGroupBox` hover now handles non-client mouse movement over the frame/caption.
- `TRadioGroup` internal button hover now routes to the framework radio-item provider instead of preserving the private child `TRadioButton` native path, so the item caption/state surface is reachable under the mouse.

## 2026-06-24
### Added
- Added `TAccessibilityScreenReaderDetector` for optional framework activation based on Windows `SPI_GETSCREENREADER` and UIA client-listener signals.
- The demo now includes a `TGroupBox` with two `TRadioButton` controls and a separate `TRadioGroup` for radio-button role/state testing.
- The demo now includes a checked-by-default `Accessibility enabled` checkbox that can disable and re-enable the framework at runtime.

### Fixed
- The demo now uninstalls accessibility hooks after `Application.Run` and disables its balloon timer during form destruction, preventing shutdown-time callbacks into torn-down VCL state.
- `TCheckBox` mouse-over now raises platform object/state events instead of plain notification-only speech, while checkbox state is exposed through UIA TogglePattern and MSAA checked/mixed flags so screen readers can localize it.
- `TRadioButton` providers now expose UIA RadioButton/SelectionItem semantics and MSAA radio-button checked state.
- Standard VCL combo boxes, page controls, group boxes, radio groups, toolbars, tool buttons, and status bars now resolve to intentional UIA/MSAA roles instead of generic text/client fallbacks where a standard role exists.

### Changed
- The demo checkbox hint now says `Includes archived rows in the demo grids` instead of procedural toggle text.

## 2026-06-23
### Changed
- Row-select `TStringGrid` row announcements now expose visible cells as `Column header: value` pairs separated by blank lines, improving the grouping screen readers receive for whole-row selection.

### Fixed
- `TButton` mouse-over now exposes caption and hint text through the framework, covering the demo's `Apply Filters`, `Regular Hint`, and `Close` buttons.
- `TCheckBox` mouse-over now exposes caption and help text, and checkbox providers expose UIA Toggle support plus platform state.
- Unsupported focusable windowed controls without a framework adapter now keep their native `WM_GETOBJECT` accessibility path, preserving controls that already provide their own accessibility such as `TVirtualStringTree`.
- `TMemo` mouse-over now exposes the text line under the pointer through UIA instead of falling back to the memo container.
- `TListBox` mouse-over and arrow-key selection changes now announce the individual item text.
- `TListBox` selection providers now expose all selected items for multi-select lists and tolerate item removal after a UIA item was cached.
- `TStatusBar` mouse-over now exposes the visible status text instead of only announcing a generic status-bar control name.

### Added
- The demo now includes separate no-wrap and wrapped `TMemo` tabs for comparing NVDA mouse-over behavior.

## 2026-06-22
### Added
- The demo now has separate regular `TStringGrid` tabs for row-select and cell-select keyboard testing.
- Debug demo builds can write a madExcept AI `bugreport.txt` when launched with `MAXLOGIC_MADEXCEPT_AI=1`.

### Fixed
- Keyboard focus on `TEdit`, `TComboBox`, and `TLabeledEdit` now announces the same name/value/help surface used by mouse-over hit testing.
- Windows UIA object-under-mouse hit testing now returns `TTabSheet` tab items for page-control tab captions and active tab header `TLabel` providers above the grids instead of the generic `PageControl` container.
- `TPageControl` tab captions now raise tab-caption hover notifications through the installed runtime hook path.
- Labels inside active tab-sheet header panels now raise label hover notifications on mouse-over without stealing grid cell speech.
- Row-select `TStringGrid` keyboard movement now announces the whole selected row while cell-select grids continue to announce the focused cell.

## 2026-06-21
### Fixed
- `TStringGrid` and TMS `TAdvStringGrid` keyboard navigation now emit the current row/cell notification from the focused cell provider and suppress the grid HWND focus event that could make NVDA append the grid name after each move.
- Active `TTabSheet` providers now expose tab-header-only bounds, while form-root hit testing still reaches visible active-tab content and keeps inactive-tab grids hidden.
- `TPageControl` tab headers now expose MSAA selectable/selected state and a default switch action, giving NVDA a cleaner page-tab object on hover.
- Text inputs now expose associated labels as their UIA name and their entered/selected text through UIA ValuePattern, improving mouse-over and tab-focus announcements for `TEdit`, `TComboBox`, and `TLabeledEdit`.
- `TStringGrid` and TMS `TAdvStringGrid` hit testing now ignores grids hidden by inactive tab pages and verifies the real VCL window under the pointer before returning cell providers.
- Focused controls now raise UIA notifications for hint text and `TEdit.TextHint`, and grid current-cell changes raise UIA focus/selection wiring for the new current cell.
- Windowed input focus now raises a UIA focus-changed event from the installed child provider, restoring keyboard tab announcements for associated-label inputs.
- `TEdit` providers now use the UIA Edit control type and include `TextHint` placeholder text in help text.
- Empty `TEdit` providers now expose `TextHint` through UIA ValuePattern as a placeholder fallback.
- `TPageControl` tab-header hit testing now prioritizes the actual tab header under the mouse, so the active tab page no longer masks sibling tab buttons.
- Keyboard focus on windowed inputs now emits a classic MSAA focus WinEvent on the default runtime path, improving NVDA announcements when it enters through MSAA instead of UIA.
- Windowed VCL providers now expose their native HWND so screen readers can resolve installed child providers from native controls.
- The demo balloon hint timer now closes the visible balloon directly instead of leaving the sample hint open.

### Changed
- The demo includes icon-only glyph `TSpeedButton` samples with explicit short/long hints for screen-reader testing.

## 2026-06-20
### Fixed
- Grid hit testing now ignores points outside the grid bounds, preventing inactive grids from stealing mouse-over results from labels, buttons, panels, or another grid.
- Framework `WM_GETOBJECT` handling now answers `OBJID_CLIENT` requests as well as UIA root requests, allowing screen readers that enter through the client-object path to receive framework providers.
- Child window `WM_GETOBJECT` handling now returns framework UIA providers, so windowed controls such as `TLabeledEdit`, `TStringGrid`, and `TAdvStringGrid` do not fall back to native edit/row providers.
- Container child windows now route UIA hit testing through the form root, allowing non-windowed labels inside panels and tab pages to resolve to the deepest label fragment under the pointer.
- Form-root hit testing now walks the provider tree by bounding rectangle and returns the deepest matching fragment.
- `TLabeledEdit` text extraction now uses `EditLabel.Caption` before the edit text.

### Changed
- The demo now writes `AccessibilityComplexDemo.a11y.log` beside the EXE with framework `WM_GETOBJECT` and UIA hit-test diagnostics for NVDA correlation.
- The demo no longer uses grid mouse-move hint notifications for per-cell speech; it relies on the framework UIA providers instead.
- The demo balloon hint now auto-hides after a short interval.

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
