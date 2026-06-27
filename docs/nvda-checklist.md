# NVDA Checklist

Use this checklist on a real VCL application or on a manual sample built from the same controls as the smoke probe. The automated UIA probe should pass before this manual pass starts.

## Setup

- Build the application with `TAccessibilityManager.Install(Application)` for app-wide coverage, or `TAccessibilityManager.Install(Form)` for the form under test.
- For `TAdvStringGrid`, include `MaxLogic.Accessibility.TmsAdvStringGridAdapters` and install with `TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry)` or the equivalent form-scoped overload.
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
- `TAdvStringGrid`: after scrolling, a newly visible cell should be announced and the old scrolled-out cell should no longer be exposed as visible.

## Regression checks

- App-wide install should cover forms that already exist when `TAccessibilityManager.Install(Application)` runs.
- A form installed with `TAccessibilityManager.Install(Form)` should be accessible without enabling app-wide discovery.
- Screen reader output should stay quiet for decorative labels, empty panels, and empty graphic controls.
- Hint and balloon hint output should not speak the same text repeatedly from one hover.
