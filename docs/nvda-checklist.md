# NVDA Checklist

Use this checklist on a real VCL application or on a manual sample built from the same controls as the smoke probe. The automated UIA probe should pass before this manual pass starts.

## Setup

- Build the application with `TAccessibilityManager.Install(Application)` for app-wide coverage, or `TAccessibilityManager.Install(Form)` for the form under test.
- `TAdvStringGrid NVDA checks require a custom provider root` or the diagnostic sample path until the custom-registry manager install task is implemented. The default manager install is VCL-only today.
- Start NVDA.
- Keep mouse tracking enabled when validating hover and grid-cell behavior.
- Keep speech viewer open if exact text needs to be captured.

## Controls

- `TLabel`: using mouse review or object navigation exposes the caption without accelerator markers. Example: `&Customer` is spoken as `Customer`. The long hint should be available as help text when NVDA queries details. `TLabel` is not a tab-focusable control.
- `TSpeedButton`: NVDA reports a button name such as `Run` or `Pinned`. Invoke should activate the button. Toggleable speed buttons should expose on/off state changes.
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
