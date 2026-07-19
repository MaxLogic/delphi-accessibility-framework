[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string] $Config = 'Release',

    [ValidateSet('Win32', 'Win64')]
    [string] $Platform = 'Win32',

    [string] $OutPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$lRepoRoot = Split-Path -Parent $PSScriptRoot
$lDakExe = $env:DAK_EXE

if ([string]::IsNullOrWhiteSpace($lDakExe)) {
    throw 'DAK_EXE is not set. Point it to DelphiAIKit.exe before running static analysis.'
}

if (-not (Test-Path -LiteralPath $lDakExe -PathType Leaf)) {
    throw "DAK_EXE does not point to an existing file: $lDakExe"
}

$lProject = Join-Path $lRepoRoot 'tests\MaxLogicAccessibilityFramework.Tests.dproj'
if (-not (Test-Path -LiteralPath $lProject -PathType Leaf)) {
    throw "Project file not found: $lProject"
}

if ([string]::IsNullOrWhiteSpace($OutPath)) {
    $lTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $OutPath = Join-Path $env:TEMP "dak\Accessibility-Framework\static-analysis-$lTimestamp-$PID"
}

$lOutPath = [System.IO.Path]::GetFullPath($OutPath)
$lDUnitXPathMasks = '*\Embarcadero\Studio\23.0\source\DUnitX\*;*\3rdParty\VSoft\DUnitX\Source\*'
$lIgnoredFixInsightCodes = 'C101;C102;C103;O801;O803;O804;W528'
$lArguments = @(
    'analyze'
    '--project', $lProject
    '--delphi', '23.0'
    '--platform', $Platform
    '--config', $Config
    '--out', $lOutPath
    '--fi-formats', 'txt'
    '--fixinsight', 'true'
    '--pascal-analyzer', 'true'
    '--exclude-path-masks', $lDUnitXPathMasks
    '--ignore-warning-ids', $lIgnoredFixInsightCodes
)

Write-Output "Analyzing $lProject [$Platform|$Config]"
$lOutput = & $lDakExe @lArguments 2>&1
$lExitCode = $LASTEXITCODE
$lOutput | ForEach-Object { Write-Output $_ }

if ($lExitCode -ne 0) {
    throw "Static analysis failed with exit code $lExitCode"
}

$lDakRoot = Split-Path -Parent (Split-Path -Parent $lDakExe)
$lPostprocess = Join-Path $lDakRoot 'agentskills\dak-static-analysis\postprocess.py'
if (-not (Test-Path -LiteralPath $lPostprocess -PathType Leaf)) {
    throw "DAK static-analysis postprocessor not found: $lPostprocess"
}

$lPostprocessOutput = & python $lPostprocess $lOutPath 2>&1
$lPostprocessExitCode = $LASTEXITCODE
$lPostprocessOutput | ForEach-Object { Write-Output $_ }
if ($lPostprocessExitCode -ne 0) {
    throw "DAK static-analysis postprocessing failed with exit code $lPostprocessExitCode"
}

$lSummaryPath = Join-Path $lOutPath 'summary.json'
if (-not (Test-Path -LiteralPath $lSummaryPath -PathType Leaf)) {
    throw "Static analysis summary not found: $lSummaryPath"
}

$lSummary = Get-Content -LiteralPath $lSummaryPath -Raw | ConvertFrom-Json
if (($lSummary.analyzers.fixinsight.status -ne 'complete') -or
    ($lSummary.analyzers.pascal_analyzer.status -ne 'complete')) {
    throw 'One or more configured analyzers did not complete.'
}

$lFixInsightPath = Join-Path $lOutPath 'fixinsight\fi-findings.jsonl'
$lDUnitXFindings = @()
if (Test-Path -LiteralPath $lFixInsightPath -PathType Leaf) {
    $lDUnitXFindings = @(
        Get-Content -LiteralPath $lFixInsightPath |
            Where-Object { $_ -match '(?i)[\\/](DUnitX)[\\/]' }
    )
}

if ($lDUnitXFindings.Count -ne 0) {
    throw "FixInsight retained $($lDUnitXFindings.Count) excluded DUnitX findings."
}

$lVerifyOutput = & python $lPostprocess --verify $lOutPath 2>&1
$lVerifyExitCode = $LASTEXITCODE
$lVerifyOutput | ForEach-Object { Write-Output $_ }
if ($lVerifyExitCode -ne 0) {
    throw "DAK static-analysis artifact verification failed with exit code $lVerifyExitCode"
}

$lFixInsightOwned = $lSummary.counts.fixinsight.ownership.project +
    $lSummary.counts.fixinsight.ownership.repository
$lPalOwned = $lSummary.counts.pascal_analyzer.ownership.project +
    $lSummary.counts.pascal_analyzer.ownership.repository
$lPalExternal = $lSummary.counts.pascal_analyzer.ownership.third_party
$lPalUnknown = $lSummary.counts.pascal_analyzer.ownership.unknown

$lResolvedExternal = 0
if ($lPalUnknown -gt 0) {
    $lPalFindingsPath = Join-Path $lOutPath 'pascal-analyzer\pal-findings.jsonl'
    $lModulesPath = Get-ChildItem -LiteralPath (Join-Path $lOutPath 'pascal-analyzer') -Recurse -Filter 'Modules.xml' |
        Select-Object -First 1 -ExpandProperty FullName
    if ([string]::IsNullOrWhiteSpace($lModulesPath)) {
        throw 'PAL reported pathless findings, but Modules.xml was not found.'
    }

    [xml] $lModules = Get-Content -LiteralPath $lModulesPath -Raw
    $lModuleSection = @($lModules.report.section) |
        Where-Object { $_.name -eq 'Module information' } |
        Select-Object -First 1
    if ($null -eq $lModuleSection) {
        throw 'PAL Modules.xml does not contain the Module information section.'
    }

    $lModulePaths = @{}
    foreach ($lModule in $lModuleSection.module) {
        $lName = [string] $lModule.name
        $lPath = [string] $lModule.path
        if ([string]::IsNullOrWhiteSpace($lName) -or [string]::IsNullOrWhiteSpace($lPath)) {
            continue
        }

        $lKey = $lName.ToLowerInvariant()
        if ($lModulePaths.ContainsKey($lKey) -and ($lModulePaths[$lKey] -ne $lPath)) {
            $lModulePaths[$lKey] = ''
        } else {
            $lModulePaths[$lKey] = $lPath
        }
    }

    $lUnresolved = 0
    $lRepoPrefix = $lRepoRoot.TrimEnd('\') + '\'
    Get-Content -LiteralPath $lPalFindingsPath | ForEach-Object {
        $lFinding = $_ | ConvertFrom-Json
        if ($lFinding.ownership -ne 'unknown') {
            return
        }

        $lModuleName = ([string] $lFinding.module -split '[\\/]')[0].ToLowerInvariant()
        $lModulePath = $lModulePaths[$lModuleName]
        if ([string]::IsNullOrWhiteSpace($lModulePath)) {
            $lUnresolved++
        } elseif ($lModulePath.StartsWith($lRepoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "PAL misclassified a project module as unknown: $lModulePath"
        } else {
            $lResolvedExternal++
        }
    }

    if ($lUnresolved -ne 0) {
        throw "PAL retained $lUnresolved findings whose ownership could not be resolved from Modules.xml."
    }

    $lPalExternal += $lResolvedExternal
    $lPalUnknown = 0
}

Write-Output "ANALYSIS_COUNTS fixinsight_owned=$lFixInsightOwned pal_owned=$lPalOwned pal_third_party=$lPalExternal pal_unknown=$lPalUnknown"
Write-Output "ANALYSIS_RAW pal_pathless_resolved_external=$lResolvedExternal"
Write-Output "ANALYSIS_POLICY fixinsight_ignored_codes=$lIgnoredFixInsightCodes"
Write-Output "ANALYSIS_ARTIFACTS $lOutPath"
Write-Output 'ANALYSIS_OK'
