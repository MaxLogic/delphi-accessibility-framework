[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string] $Config = 'Debug',

    [ValidateSet('Win32', 'Win64')]
    [string] $Platform = 'Win32',

    [string] $Filter = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$lRepoRoot = Split-Path -Parent $PSScriptRoot

& (Join-Path $PSScriptRoot 'build.ps1') -Config $Config -Platform $Platform

$lTestExe = Join-Path $lRepoRoot "bin\$Platform\$Config\MaxLogicAccessibilityFramework.Tests.exe"
if (-not (Test-Path -LiteralPath $lTestExe -PathType Leaf)) {
    throw "Test executable not found: $lTestExe"
}

$lArguments = @()
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $lArguments += "--include:$Filter"
}

Write-Output "Running $lTestExe"
$lOutput = & $lTestExe @lArguments 2>&1
$lExitCode = $LASTEXITCODE

$lOutput | ForEach-Object { Write-Output $_ }

if ($lExitCode -ne 0) {
    throw "Test executable failed with exit code $lExitCode"
}

$lSummary = $lOutput | Select-String -Pattern '^DUNITX_RESULT tests=(\d+) passed=(\d+) failures=0 errors=0 ignored=0$'
if (-not $lSummary) {
    throw 'DUnitX summary did not report zero failures, zero errors, and zero ignored tests.'
}

$lMatch = [regex]::Match($lSummary.Line, '^DUNITX_RESULT tests=(\d+)')
if (-not $lMatch.Success -or [int] $lMatch.Groups[1].Value -le 0) {
    throw 'DUnitX did not report any discovered tests.'
}

Write-Output 'TEST_OK'
