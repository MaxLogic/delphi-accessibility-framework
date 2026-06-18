[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string] $Config = 'Debug',

    [ValidateSet('Win32', 'Win64')]
    [string] $Platform = 'Win32'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$lRepoRoot = Split-Path -Parent $PSScriptRoot
$lDakExe = $env:DAK_EXE

if ([string]::IsNullOrWhiteSpace($lDakExe)) {
    throw 'DAK_EXE is not set. Point it to DelphiAIKit.exe before running the build.'
}

if (-not (Test-Path -LiteralPath $lDakExe -PathType Leaf)) {
    throw "DAK_EXE does not point to an existing file: $lDakExe"
}

$lProjects = @(
    Join-Path $lRepoRoot 'projects\MaxLogicAccessibilityFrameworkSmoke.dproj'
    Join-Path $lRepoRoot 'tests\MaxLogicAccessibilityFramework.Tests.dproj'
)

foreach ($lProject in $lProjects) {
    if (-not (Test-Path -LiteralPath $lProject -PathType Leaf)) {
        throw "Project file not found: $lProject"
    }

    Write-Output "Building $lProject [$Platform|$Config]"
    $lOutput = & $lDakExe build --project $lProject --delphi 23.0 --platform $Platform --config $Config --target Build --ai --show-warnings --show-hints 2>&1
    $lExitCode = $LASTEXITCODE

    $lOutput | ForEach-Object { Write-Output $_ }

    if ($lExitCode -ne 0) {
        throw "Build failed for $lProject with exit code $lExitCode"
    }

    $lCompilerWarningPattern = '(?i)\bwarning\s+(W|H)\d{4}\b|\b(W|H)\d{4}\b|:\s+warning\b'
    if (($lOutput | Out-String) -match $lCompilerWarningPattern) {
        throw "Build produced warnings or hints for $lProject"
    }
}

Write-Output 'BUILD_OK'
