[CmdletBinding()]
param(
    [ValidateSet('BasicVclControls', 'All')]
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
}

switch ($Scenario) {
    'BasicVclControls' {
        Invoke-BasicVclControlsProbe -Config $Config -Platform $Platform
    }
    'All' {
        Invoke-BasicVclControlsProbe -Config $Config -Platform $Platform
    }
}
