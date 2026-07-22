[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string] $Config = 'Release',

    [ValidateSet('Win32', 'Win64')]
    [string] $Platform = 'Win32',

    [string] $OutPath = '',

    [string] $BaselinePath = '',

    [switch] $UpdateBaseline
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

if ([string]::IsNullOrWhiteSpace($BaselinePath)) {
    $BaselinePath = Join-Path $PSScriptRoot 'static-analysis-baseline.json'
}

$lOutPath = [System.IO.Path]::GetFullPath($OutPath)
$lBaselinePath = [System.IO.Path]::GetFullPath($BaselinePath)
$lBaselineMarkdown = [System.IO.Path]::ChangeExtension($lBaselinePath, '.md')
$lBaselineParent = Split-Path -Parent $lBaselinePath
if (-not (Test-Path -LiteralPath $lBaselineParent -PathType Container)) {
    throw "Static-analysis baseline directory not found: $lBaselineParent"
}

if ((-not $UpdateBaseline) -and
    (-not (Test-Path -LiteralPath $lBaselinePath -PathType Leaf))) {
    throw "Static-analysis baseline not found: $lBaselinePath. Use -UpdateBaseline to establish it intentionally."
}

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

$lDakRoot = Split-Path -Parent (Split-Path -Parent $lDakExe)
$lPostprocess = Join-Path $lDakRoot 'agentskills\dak-static-analysis\postprocess.py'
if (-not (Test-Path -LiteralPath $lPostprocess -PathType Leaf)) {
    throw "DAK static-analysis postprocessor not found: $lPostprocess"
}

$lPreviousEnvironment = @{
    DAK_BASELINE = [Environment]::GetEnvironmentVariable('DAK_BASELINE', 'Process')
    DAK_GATE = [Environment]::GetEnvironmentVariable('DAK_GATE', 'Process')
    DAK_UPDATE_BASELINE = [Environment]::GetEnvironmentVariable('DAK_UPDATE_BASELINE', 'Process')
}

Write-Output "Analyzing $lProject [$Platform|$Config]"
try {
    $env:DAK_BASELINE = $lBaselinePath
    $env:DAK_GATE = if ($UpdateBaseline) { '0' } else { '1' }
    $env:DAK_UPDATE_BASELINE = if ($UpdateBaseline) { '1' } else { '0' }

    $lOutput = & $lDakExe @lArguments 2>&1
    $lExitCode = $LASTEXITCODE
    $lOutput | ForEach-Object { Write-Output $_ }

    if ($lExitCode -ne 0) {
        throw "Static analysis failed with exit code $lExitCode"
    }

    $lPostprocessOutput = & python $lPostprocess $lOutPath 2>&1
    $lPostprocessExitCode = $LASTEXITCODE
    $lPostprocessOutput | ForEach-Object { Write-Output $_ }
    if ($lPostprocessExitCode -ne 0) {
        throw "DAK static-analysis postprocessing or its evaluated policy failed with exit code $lPostprocessExitCode"
    }
} finally {
    foreach ($lName in $lPreviousEnvironment.Keys) {
        $lValue = $lPreviousEnvironment[$lName]
        if ($null -eq $lValue) {
            Remove-Item -LiteralPath "Env:$lName" -ErrorAction SilentlyContinue
        } else {
            Set-Item -LiteralPath "Env:$lName" -Value $lValue
        }
    }

    if (Test-Path -LiteralPath $lBaselineMarkdown -PathType Leaf) {
        Remove-Item -LiteralPath $lBaselineMarkdown
    }
}

if (-not $UpdateBaseline) {
    $lVerifyOutput = & python $lPostprocess --verify $lOutPath 2>&1
    $lVerifyExitCode = $LASTEXITCODE
    $lVerifyOutput | ForEach-Object { Write-Output $_ }
    if ($lVerifyExitCode -ne 0) {
        throw "DAK static-analysis artifact verification failed with exit code $lVerifyExitCode"
    }
}

$lSummaryPath = Join-Path $lOutPath 'summary.json'
if (-not (Test-Path -LiteralPath $lSummaryPath -PathType Leaf)) {
    throw "Static analysis summary not found: $lSummaryPath"
}

$lSummary = Get-Content -LiteralPath $lSummaryPath -Raw | ConvertFrom-Json
if ($lSummary.schema_version -ne 3) {
    throw "Unsupported DAK static-analysis schema: $($lSummary.schema_version)"
}

if (($lSummary.status.finalization -ne 'complete') -or
    ($lSummary.status.ownership_resolution -ne 'complete') -or
    ($lSummary.status.postprocessor -ne 'complete') -or
    ($lSummary.analyzers.fixinsight.status -ne 'complete') -or
    ($lSummary.analyzers.pascal_analyzer.status -ne 'complete')) {
    throw 'DAK static-analysis infrastructure, ownership resolution, or an analyzer did not complete.'
}

$lExpectedPolicy = if ($UpdateBaseline) { 'not_evaluated' } else { 'pass' }
if ($lSummary.status.policy -ne $lExpectedPolicy) {
    throw "DAK static-analysis policy did not pass: $($lSummary.status.policy)"
}

$lUnknown = $lSummary.counts.unknown.total
if ($lUnknown -ne 0) {
    throw "DAK retained $lUnknown findings with unknown ownership."
}

$lFixInsightOwned = $lSummary.counts.actionable.fixinsight.ownership.project +
    $lSummary.counts.actionable.fixinsight.ownership.repository
$lPalOwned = $lSummary.counts.actionable.pascal_analyzer.ownership.project +
    $lSummary.counts.actionable.pascal_analyzer.ownership.repository
$lPalExternal = $lSummary.counts.external.pascal_analyzer.total
$lPalStrong = $lSummary.counts.actionable.pascal_analyzer.strong_warnings
$lIgnored = $lSummary.counts.ignored.total
$lAdvisory = $lSummary.counts.advisory_metrics.total
$lDakHash = $lSummary.compatibility.context.dak.executable_sha256
$lDakHead = $lSummary.compatibility.context.dak.head

Write-Output "ANALYSIS_SCHEMA version=$($lSummary.schema_version)"
Write-Output "ANALYSIS_COUNTS actionable_total=$($lSummary.counts.actionable.total) fixinsight_owned=$lFixInsightOwned pal_owned=$lPalOwned pal_strong=$lPalStrong"
Write-Output "ANALYSIS_PROJECTIONS ignored=$lIgnored external_pal=$lPalExternal advisory_metrics=$lAdvisory unknown=$lUnknown"
Write-Output "ANALYSIS_GATE status=$($lSummary.status.policy) baseline=$lBaselinePath updated=$($UpdateBaseline.IsPresent)"
Write-Output "ANALYSIS_TOOL dak_sha256=$lDakHash dak_head=$lDakHead"
Write-Output "ANALYSIS_POLICY fixinsight_ignored_codes=$lIgnoredFixInsightCodes"
Write-Output "ANALYSIS_ARTIFACTS $lOutPath"
Write-Output 'ANALYSIS_OK'
