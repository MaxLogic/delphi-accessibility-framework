# NVDA Checklist

Use this checklist on a real VCL application or on a manual sample built from the same controls as the smoke probe. The automated UIA probe should pass before this manual pass starts.

## Setup

- Build the application with `TAccessibilityManager.Install(Application)` for app-wide coverage, or `TAccessibilityManager.Install(Form)` for the form under test.
- For `TAdvStringGrid`, include `MaxLogic.Accessibility.TmsAdvStringGridAdapters` and install with `TAccessibilityManager.Install(Application, [TAccessibilityTmsAdvStringGridAdapters.RegisterAdapters])` or the equivalent form-scoped overload.
- Start NVDA.
- Keep mouse tracking enabled when validating hover and grid-cell behavior.
- Keep speech viewer open if exact text needs to be captured.
- Optional: applications can call `TAccessibilityScreenReaderDetector` from `MaxLogic.Accessibility.ScreenReaders` before installing the framework. Treat `SPI_GETSCREENREADER` as one Windows accessibility-aid signal and `UiaClientsAreListening` as a UIA client-listener signal; UIA listener activity is not a guaranteed screen-reader identity.

## Controls

- `TLabel`: using mouse review or object navigation exposes the caption without accelerator markers. Example: `&Customer` is spoken as `Customer`. The long hint should be available as help text when NVDA queries details. `TLabel` is not a tab-focusable control.
- `TButton`: mouse-over should report the button caption and useful hint text, for example `Apply Filters. Apply the selected filters`. Invoke should activate the button.
- `TSpeedButton`: NVDA reports a button name such as `Run` or `Pinned`. Invoke should activate the button. Toggleable speed buttons should expose on/off state changes.
- `TComboBox`: tab focus and mouse-over should report the associated label/name and current value.
- `TCheckBox`: mouse-over, tab focus, click, and space should report the caption plus NVDA's localized checkbox state. The framework must not add framework-injected English state words such as `checked` or `not checked`, and it must not replace the checkbox HWND accessibility path. Framework tree traversal still exposes UIA TogglePattern plus MSAA checked/mixed flags; hover raises a UIA focus event from that provider and nudges the native HWND with focus/state WinEvents.
- `TRadioButton`: mouse-over, tab focus, click, and arrow-key selection should report the caption plus NVDA's localized selected state. Framework tree traversal still exposes UIA SelectionItem plus MSAA radio-button state; standalone radio-button hover raises a UIA focus event from that provider and nudges the native HWND with focus/state WinEvents. Radio buttons must not expose TogglePattern.
- `TGroupBox` and `TRadioGroup`: mouse-over and object navigation should report named option groups. `TRadioGroup` item hover should report the item caption/state rather than the group caption.
- `TPageControl`/`TTabSheet`: mouse-over on tab buttons should report the tab caption, not only the page-control container.
- `TToolBar`/`TToolButton`: toolbar commands should expose toolbar/button roles and the command caption or hint text.
- `TPanel`: decorative empty panels should not be spoken. A panel with accessible child controls may appear as a pane/group and should let NVDA reach the child text.
- Generic graphic controls: text-like custom `TGraphicControl` descendants with caption or hint text should expose readable text; empty decorative graphics should be omitted.

## Label relationships

- In the complex demo's filter area, tab to `Search text`, `Queue`, and `TLabeledEdit reference`. In the framework provider tree or an external `AutomationFocusChanged` event sender, UIA `LabeledBy` should resolve respectively to the geometrically inferred `TStaticText`, explicit `TLabel.FocusControl`, and bound `TLabeledEdit.EditLabel` provider. A separate `AutomationElement.FocusedElement` query can resolve the native HWND proxy for controls whose native accessibility is preserved; do not treat that proxy's independent label heuristic as the framework fragment.
- NVDA should announce each current label once with the input value, without duplicating the label because the accessible Name fallback is also retained.
- `Ambiguous label sample` has two equally plausible same-parent labels and `Unlabeled sample` has none. Neither input should expose `LabeledBy` or acquire an incorrect label announcement.
- Change an associated label caption at runtime and query the input again. The same `LabeledBy` provider should expose the new caption without rebuilding the relationship.

## Dynamic content

- Open the complex demo's `Dynamic content` tab and note the current cycle number for its `TStaticText`, `TLabel`, `TEdit`, `TButton`, and `TBitBtn` samples.
- Wait at least 10 seconds, then revisit the samples with mouse review, object navigation, and Tab where applicable. NVDA and the UIA properties should expose the new cycle number in every caption/edit value and hint; none should retain a value from the earlier cycle.
- After observing at least two timer cycles, use `Next runtime sync step` to advance one isolated transition at a time. Capture the displayed `Step NN` state before continuing.
- Steps 1-5 change form/control properties, add an explicitly labeled edit, reparent it, and remove it. Confirm current names, values, hints, enabled/visible/bounds state, exact label association, provider identity, and one structure/reorder event for each hierarchy transition.
- Steps 6-9 change the ambiguous sample into one geometrically inferred relationship and back, then remove and restore the `TLabeledEdit` label. Confirm the current label is announced once and ambiguous/unlabeled inputs never acquire a false relationship.
- Steps 10-11 change cell values, grow both `TStringGrid` and `TAdvStringGrid`, then shrink and restore their original data. Confirm new edge cells appear once, removed cells disappear, and the restored TMS hidden-base merges retain correct text and spans.
- Steps 12-13 recreate the `TStringGrid` and form HWNDs. Compare the displayed old/new handles with bridge, provider, and external UIA maps; focus, selection, hit testing, `WM_GETOBJECT`, and the current form name must continue without reinstalling accessibility.
- Reset the walkthrough after Step 13. The original form caption, timer, label relationships, layout, and grid data should return.

## Hints

- `visible hint`: when the control's VCL hint appears, NVDA should receive the shown hint text once, not repeated on every duplicate notification. If speech is inconclusive, verify with Speech Viewer or a UIA event inspection tool because NVDA notification settings can affect spoken output.
- `balloon hint`: when a VCL balloon hint appears, NVDA should receive title plus description as one useful notification, for example `Upload complete: 5 files were processed`. If speech is inconclusive, verify with Speech Viewer or a UIA event inspection tool.
- Controls with `Short|Long` hints should prefer the long part for help text and visible notification speech.

## Grids

- `TStringGrid`: mouse over a visible cell should expose a UIA provider whose name is the cell text only by default. NVDA may add role or position details from its own settings, but it should not read neighboring cells, whole rows, or row/column text added by this framework.
- `TStringGrid`: hidden columns, hidden rows, and scrolled-out cells should not be announced as visible cells.
- `TStringGrid`: keyboard focus inside the grid should expose the current cell.
- `TAdvStringGrid`: mouse over a visible TMS cell should expose a UIA provider whose name is the cell text only by default. NVDA may add role or position details from its own settings, but it should not read neighboring cells, whole rows, or row/column text added by this framework.
- `TAdvStringGrid`: HTML text should be stripped before speech, wide text fallback should be preserved, and hidden row/column remapping should not expose hidden cells.
- `TAdvStringGrid`: when a merged range still has visible cells after its base row or column is hidden, NVDA should announce the hidden base text once from the first visible representative. Keyboard focus, selection, mouse hit testing, GridItem coordinates, and visible row/column spans should all resolve to that representative; a fully hidden merge should not be exposed.
- `TAdvStringGrid`: after scrolling, a newly visible cell should be announced and the old scrolled-out cell should no longer be exposed as visible.

## Event fanout diagnostics

- Enable `diagnostics.providerHotspots` only for a focused measurement run.
- Reset the metrics immediately before one mouse, focus, click, Space, or arrow-key interaction.
- Capture the metrics immediately afterward and correlate them with NVDA Speech Viewer or another configured speech transcript.
- Treat framework UIA counters as successful helper calls and framework MSAA counters as WinEvent attempts. VCL/Windows events emitted outside the framework wrapper are not included.
- Do not remove an event because its count appears duplicated. Require live caption and state evidence for every affected input path, including delayed or coalesced speech, before consolidation.
- Disable provider-hotspot metrics after the run so ordinary callback paths retain the minimal disabled fast path.

## Regression checks

- App-wide install should cover forms that already exist when `TAccessibilityManager.Install(Application)` runs.
- A form installed with `TAccessibilityManager.Install(Form)` should be accessible without enabling app-wide discovery.
- Screen reader output should stay quiet for decorative labels, empty panels, and empty graphic controls.
- Hint and balloon hint output should not speak the same text repeatedly from one hover.
