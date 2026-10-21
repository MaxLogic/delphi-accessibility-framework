# Commands and examples

Read this when selecting helper arguments or preparing a foreground batch.
Examples use PowerShell from the repository root. For an installed skill, set
`$lTool` to its `scripts/windows_desktop_control.py`. Substitute the verified PID,
pipe, form, and control names; these are separate examples, not one bulk workflow.
`$lRunRoot` means an already allocated, task-owned evidence directory outside
`.agents/`, following the project's storage policy.

## Check command results

Use this wrapper in the examples below. It stops on a failed process, invalid
JSON, or `ok:false`; inspect returned state before dependent actions.

```powershell
$lTool = '.\agent-skills\windows-desktop-control\scripts\windows_desktop_control.py'

function Invoke-DesktopCommand {
    param([Parameter(Mandatory)][string[]]$ArgumentList)
    $lOutput = & python $lTool @ArgumentList
    if ($LASTEXITCODE -ne 0) { throw "Desktop command failed: $lOutput" }
    $lResult = $lOutput | ConvertFrom-Json -ErrorAction Stop
    if ($lResult.ok -ne $true) { throw "Desktop command refused: $lOutput" }
    return $lResult
}
```

## Discover and inspect without activation

```powershell
Invoke-DesktopCommand -ArgumentList @('windows-list', '--pid', '12345')
Invoke-DesktopCommand -ArgumentList @('fast-map', '--pid', '12345', '--detail', 'full')
Invoke-DesktopCommand -ArgumentList @('win32-map', '--pid', '12345', '--max-depth', '4')
Invoke-DesktopCommand -ArgumentList @('fast-semantic-map', '--target', 'handle', '--handle', '123456', '--max-depth', '3', '--max-children', '200')
Invoke-DesktopCommand -ArgumentList @('uia-map', '--hwnd', '123456', '--max-depth', '4', '--max-children', '100')
Invoke-DesktopCommand -ArgumentList @('screenshot-window', '--hwnd', '123456', '--output', (Join-Path $lRunRoot 'window.bmp'))
```

Use `fast-map` geometry for coordinates; `--detail full` adds native captions,
values, hints, and role-specific state without accessibility scanning.
`--pipe-name` selects an explicit bridge; otherwise discovery tries
`MaxLogicAccessibilityAgentBridge.<pid>`. `fast-semantic-map` uses
`--target handle --handle HWND`, not `--hwnd`. Read `elapsedMs`, bridge timing,
and `fallbackAttempts` to distinguish in-process work from external UIA fallback.
`uia-map` defaults to cached .NET UIAutomation; `--plain` requires the optional
Python `uiautomation` package and is for comparison/debugging.

## Background bridge commands

```powershell
$lPipe = 'MaxLogicAccessibilityAgentBridge.12345'
Invoke-DesktopCommand -ArgumentList @('probe-bridge', '--pipe-name', $lPipe)
Invoke-DesktopCommand -ArgumentList @('bridge-window-info', '--pipe-name', $lPipe, '--target', 'handle', '--handle', '123456')
Invoke-DesktopCommand -ArgumentList @('bridge-form-map', '--pipe-name', $lPipe, '--target', 'handle', '--handle', '123456')
Invoke-DesktopCommand -ArgumentList @('bridge-controls-info', '--pipe-name', $lPipe, '--ref', '@s12a1', '--ref', '@s12a2')
Invoke-DesktopCommand -ArgumentList @('bridge-set-text', '--pipe-name', $lPipe, '--form-name', 'MainForm', '--control-name', 'edtSearch', '--text', 'query')
Invoke-DesktopCommand -ArgumentList @('bridge-set-checked', '--pipe-name', $lPipe, '--form-name', 'MainForm', '--control-name', 'chkEnabled', '--checked')
Invoke-DesktopCommand -ArgumentList @('bridge-select', '--pipe-name', $lPipe, '--form-name', 'MainForm', '--control-name', 'lstOptions', '--indices', '1', '3')
Invoke-DesktopCommand -ArgumentList @('bridge-action-invoke', '--pipe-name', $lPipe, '--data-module-name', 'MainDataModule', '--component-name', 'actRefresh')
```

Replace example refs with fresh values from a current map. A control mutation
uses either `--ref`, or `--form-name`/`--form-hwnd` plus `--control-name`.
`bridge-select --texts 'One' 'Three'` replaces a multi-selection;
`--clear-selection` clears it. Single-select lists/combos use `--index` or `--text`.

For a modal opener, use `bridge-invoke --async` and retain `operationId`.
Use `wait-form` with a narrow name/class filter and require exactly one match;
invoke its dismiss control using `--form-hwnd` and finish with
`bridge-operation-status --operation-id ID`. Inspect terminal status and failure
details; a queued response is not completion. Native `#32770` dialogs may require
`windows-list`/`wait-window` discovery outside the bridge.

Use `bridge-request`/`bridge-batch` only with understood protocol requests:
`forms.list`, `window.info`, `form.map`, `control.resolve`, `control.info`,
`controls.info`, `provider.map`, and `hitTest` are discovery routes. Raw commands
can also mutate. Batch independent reads; inspect mutations before dependent
actions and resolve new refs after invalidation.

## Foreground batch

Run only when the action needs foreground input. The start command announces
takeover and includes the three-second delay. Do not ask for confirmation, add
another sleep, or wait for the user to open the harness.

Keep the helper's shared default lease path for start, input, renewal, and
release. Do not create per-agent state paths to bypass an existing lease.
If an established workflow requires a custom state path, all participants must
share it: use `--state-path` for session commands and `--session-state-path`
for input commands. An event log may be task-specific.

This example performs one named click and releases even if the click fails.
Extend the `try` body with the prepared input sequence and immediate result
verification. Reuse a live lease across related steps; keep the controller
PowerShell process alive through the batch.

```powershell
$lLease = $null
try {
    $lLease = Invoke-DesktopCommand -ArgumentList @(
        'foreground-session', 'start', '--target-pid', '12345',
        '--controller-pid', "$PID", '--ttl-ms', '60000'
    )
    Invoke-DesktopCommand -ArgumentList @(
        'click-control', '--pipe-name', 'MaxLogicAccessibilityAgentBridge.12345',
        '--form-name', 'MainForm', '--control-name', 'btnRun',
        '--session-id', $lLease.sessionId, '--require-foreground-pid', '12345'
    )
}
finally {
    if ($null -ne $lLease) {
        Invoke-DesktopCommand -ArgumentList @(
            'foreground-session', 'release', '--session-id', $lLease.sessionId
        )
    }
}
```

`click-control`, `double-click-control`, `right-click-control`, and
`move-to-control` perform guarded activation and fresh targeting themselves.
For generic input, first call guarded `activate-window`, verify
`foreground-window`, then pass `--session-id` and the PID/HWND guard to each
`move`, `click`, `press`, `tab`, `key-chord`, `clear-and-type`, or `type-text`.
Use `--help` for exact arguments. A session ID is required at runtime even where
the parser lists it as optional. Never use bare pointer or typing commands as
an alternative to guarded input.

Renew with `foreground-session renew --session-id ID --ttl-ms 60000` before
expiry only while the bounded batch is still needed. Do not steal or clear another
session's state. If acquisition fails, send no input; inspect
`foreground-session status` and retain the error. Failed startup can leave state
for watchdog recovery. Report release failures and check status before claiming
control has been returned. Do not delete active lease state as cleanup.

For documentation checks, parse arguments without dispatch. `takeover --dry-run`
suppresses audio but still delays; `foreground-session start --dry-run` also
writes state and starts a watchdog. Never assume a dry-run lease makes later
input commands harmless.
