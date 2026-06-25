[CmdletBinding()]
param(
    [ValidateSet('BasicVclControls', 'Hints', 'MemoListStatus', 'TStringGridCells', 'TAdvStringGridCells', 'All')]
    [string] $Scenario = 'BasicVclControls',

    [ValidateSet('Debug', 'Release')]
    [string] $Config = 'Debug',

    [ValidateSet('Win32', 'Win64')]
    [string] $Platform = 'Win32'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-BasicVclControlsProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Debug', 'Release')]
        [string] $Config,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Win32', 'Win64')]
        [string] $Platform
    )

    $lBuildScript = Join-Path $PSScriptRoot 'build.ps1'
    & $lBuildScript -Config $Config -Platform $Platform

    $lRepoRoot = Split-Path -Parent $PSScriptRoot
    $lSmokeExe = Join-Path $lRepoRoot "bin\$Platform\$Config\MaxLogicAccessibilityFrameworkSmoke.exe"
    if (-not (Test-Path -LiteralPath $lSmokeExe -PathType Leaf)) {
        throw "Smoke executable not found: $lSmokeExe"
    }

    $lOutput = & $lSmokeExe --uia-probe BasicVclControls 2>&1
    $lOutput | ForEach-Object { Write-Output $_ }

    $lText = $lOutput | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "BasicVclControls probe failed with exit code $LASTEXITCODE."
    }

    if ($lText -notmatch 'UIA_PROBE_OK BasicVclControls:') {
        throw 'BasicVclControls provider probe did not confirm UIA fragment properties.'
    }

    if ($lText -notmatch 'install-path=manager-wm-getobject') {
        throw 'BasicVclControls provider probe did not enter through TAccessibilityManager.Install(Form) and WM_GETOBJECT.'
    }
}

function Invoke-HintsProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Debug', 'Release')]
        [string] $Config,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Win32', 'Win64')]
        [string] $Platform
    )

    $lBuildScript = Join-Path $PSScriptRoot 'build.ps1'
    & $lBuildScript -Config $Config -Platform $Platform

    $lRepoRoot = Split-Path -Parent $PSScriptRoot
    $lSmokeExe = Join-Path $lRepoRoot "bin\$Platform\$Config\MaxLogicAccessibilityFrameworkSmoke.exe"
    if (-not (Test-Path -LiteralPath $lSmokeExe -PathType Leaf)) {
        throw "Smoke executable not found: $lSmokeExe"
    }

    $lOutput = & $lSmokeExe --uia-probe Hints 2>&1
    $lOutput | ForEach-Object { Write-Output $_ }

    $lText = $lOutput | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Hints probe failed with exit code $LASTEXITCODE."
    }

    if ($lText -notmatch 'UIA_PROBE_OK Hints:') {
        throw 'Hints provider probe did not confirm help text and hint notifications.'
    }
}

function Invoke-TStringGridCellsProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Debug', 'Release')]
        [string] $Config,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Win32', 'Win64')]
        [string] $Platform
    )

    $lBuildScript = Join-Path $PSScriptRoot 'build.ps1'
    & $lBuildScript -Config $Config -Platform $Platform

    $lRepoRoot = Split-Path -Parent $PSScriptRoot
    $lSmokeExe = Join-Path $lRepoRoot "bin\$Platform\$Config\MaxLogicAccessibilityFrameworkSmoke.exe"
    if (-not (Test-Path -LiteralPath $lSmokeExe -PathType Leaf)) {
        throw "Smoke executable not found: $lSmokeExe"
    }

    $lOutput = & $lSmokeExe --uia-probe TStringGridCells 2>&1
    $lOutput | ForEach-Object { Write-Output $_ }

    $lText = $lOutput | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "TStringGridCells probe failed with exit code $LASTEXITCODE."
    }

    if ($lText -notmatch 'UIA_PROBE_OK TStringGridCells:') {
        throw 'TStringGridCells provider probe did not confirm per-cell hit testing and names.'
    }
}

function Invoke-MemoListStatusProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Debug', 'Release')]
        [string] $Config,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Win32', 'Win64')]
        [string] $Platform
    )

    $lBuildScript = Join-Path $PSScriptRoot 'build.ps1'
    & $lBuildScript -Config $Config -Platform $Platform

    $lRepoRoot = Split-Path -Parent $PSScriptRoot
    $lSmokeExe = Join-Path $lRepoRoot "bin\$Platform\$Config\MaxLogicAccessibilityFrameworkSmoke.exe"
    if (-not (Test-Path -LiteralPath $lSmokeExe -PathType Leaf)) {
        throw "Smoke executable not found: $lSmokeExe"
    }

    $lOutput = & $lSmokeExe --uia-probe MemoListStatus 2>&1
    $lOutput | ForEach-Object { Write-Output $_ }

    $lText = $lOutput | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "MemoListStatus probe failed with exit code $LASTEXITCODE."
    }

    if ($lText -notmatch 'UIA_PROBE_OK MemoListStatus:') {
        throw 'MemoListStatus provider probe did not confirm memo, listbox, and statusbar accessibility.'
    }
}

function Invoke-TAdvStringGridCellsProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Debug', 'Release')]
        [string] $Config,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Win32', 'Win64')]
        [string] $Platform
    )

    $lBuildScript = Join-Path $PSScriptRoot 'build.ps1'
    & $lBuildScript -Config $Config -Platform $Platform

    $lRepoRoot = Split-Path -Parent $PSScriptRoot
    $lSmokeExe = Join-Path $lRepoRoot "bin\$Platform\$Config\MaxLogicAccessibilityFrameworkSmoke.exe"
    if (-not (Test-Path -LiteralPath $lSmokeExe -PathType Leaf)) {
        throw "Smoke executable not found: $lSmokeExe"
    }

    $lOutput = & $lSmokeExe --uia-probe TAdvStringGridCells 2>&1
    $lOutput | ForEach-Object { Write-Output $_ }

    $lText = $lOutput | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "TAdvStringGridCells probe failed with exit code $LASTEXITCODE."
    }

    if ($lText -notmatch 'UIA_PROBE_OK TAdvStringGridCells:') {
        throw 'TAdvStringGridCells provider probe did not confirm TMS opt-in cell accessibility.'
    }
}

switch ($Scenario) {
    'BasicVclControls' {
        Invoke-BasicVclControlsProbe -Config $Config -Platform $Platform
    }
    'Hints' {
        Invoke-HintsProbe -Config $Config -Platform $Platform
    }
    'MemoListStatus' {
        Invoke-MemoListStatusProbe -Config $Config -Platform $Platform
    }
    'TStringGridCells' {
        Invoke-TStringGridCellsProbe -Config $Config -Platform $Platform
    }
    'TAdvStringGridCells' {
        Invoke-TAdvStringGridCellsProbe -Config $Config -Platform $Platform
    }
    'All' {
        Invoke-BasicVclControlsProbe -Config $Config -Platform $Platform
        Invoke-HintsProbe -Config $Config -Platform $Platform
        Invoke-MemoListStatusProbe -Config $Config -Platform $Platform
        Invoke-TStringGridCellsProbe -Config $Config -Platform $Platform
        Invoke-TAdvStringGridCellsProbe -Config $Config -Platform $Platform
    }
}
