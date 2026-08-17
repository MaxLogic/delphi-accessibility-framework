#requires -Version 7.0

[CmdletBinding()]
param(
    [ValidateSet('Debug')]
    [string] $Config = 'Debug',

    [ValidateSet('Win32')]
    [string] $Platform = 'Win32',

    [ValidateSet('Background', 'Foreground')]
    [string] $Mode = 'Background',

    [switch] $BuildDemo,

    [switch] $InitializeCandidate,

    [string] $CandidateManifest = '.agents\runs\agent-control-two-mode\candidate.json',

    [string] $EvidenceDirectory = '',

    [ValidateRange(1000, 120000)]
    [int] $TimeoutMs = 15000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Get-DemoExecutablePath {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot
    )

    return Join-Path $RepoRoot 'bin\Win32\Debug\AccessibilityComplexDemo.exe'
}

function Get-DemoBuildArgument {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot
    )

    return @(
        'build'
        '--project'
        (Join-Path $RepoRoot 'demos\AccessibilityComplexDemo.dproj')
        '--delphi'
        '23.0'
        '--platform'
        'Win32'
        '--config'
        'Debug'
        '--target'
        'Rebuild'
        '--dfmcheck'
        '--dfm'
        'AccessibilityDemoMainForm.dfm'
        '--ai'
        '--show-warnings'
        '--show-hints'
    )
}

function Test-CompilerOutputClean {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $Output
    )

    $lCompilerWarningPattern = '(?i)\bwarning\s+(W|H)\d{4}\b|\b(W|H)\d{4}\b|:\s+warning\b|\bwarning\s*:'
    return -not (($Output | Out-String) -match $lCompilerWarningPattern)
}

function Invoke-DemoBuild {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot
    )

    $lDakExe = $env:DAK_EXE
    if ([string]::IsNullOrWhiteSpace($lDakExe) -or -not (Test-Path -LiteralPath $lDakExe -PathType Leaf)) {
        throw 'DAK_EXE must point to an existing DelphiAIKit executable.'
    }

    $lHadMsBuild = Test-Path Env:DAK_DFMCHECK_MSBUILD
    $lPreviousMsBuild = $env:DAK_DFMCHECK_MSBUILD
    try {
        if ([string]::IsNullOrWhiteSpace($env:DAK_DFMCHECK_MSBUILD)) {
            $lCommunityMsBuild = 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
            $lBuildToolsMsBuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe'
            if (Test-Path -LiteralPath $lCommunityMsBuild -PathType Leaf) {
                $env:DAK_DFMCHECK_MSBUILD = $lCommunityMsBuild
            } elseif (Test-Path -LiteralPath $lBuildToolsMsBuild -PathType Leaf) {
                $env:DAK_DFMCHECK_MSBUILD = $lBuildToolsMsBuild
            } else {
                throw 'MSBuild.exe was not found for DFM validation.'
            }
        }

        $lOutput = & $lDakExe @(Get-DemoBuildArgument -RepoRoot $RepoRoot) 2>&1
        $lExitCode = $LASTEXITCODE
        $lOutput | ForEach-Object { Write-Output $_ }
        if ($lExitCode -ne 0) {
            throw "Demo rebuild failed with exit code $lExitCode."
        }
        if (-not (Test-CompilerOutputClean -Output $lOutput)) {
            throw 'Demo rebuild produced compiler warnings or hints.'
        }

        $lDemoPath = Get-DemoExecutablePath -RepoRoot $RepoRoot
        if (-not (Test-Path -LiteralPath $lDemoPath -PathType Leaf)) {
            throw "Demo rebuild did not produce the normal executable: $lDemoPath"
        }
    } finally {
        if ($lHadMsBuild) {
            $env:DAK_DFMCHECK_MSBUILD = $lPreviousMsBuild
        } else {
            Remove-Item Env:DAK_DFMCHECK_MSBUILD -ErrorAction SilentlyContinue
        }
    }
}

function Test-GeneratedUntrackedPath {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $lNormalized = $Path.Replace('\', '/')
    return ($lNormalized -match '(^|/)__pycache__(/|$)' -or $lNormalized -match '\.pyc$')
}

function Get-TextSha256 {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Text
    )

    $lSha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $lBytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return [BitConverter]::ToString($lSha256.ComputeHash($lBytes)).Replace('-', '').ToLowerInvariant()
    } finally {
        $lSha256.Dispose()
    }
}

function Get-CandidateSourceState {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot
    )

    $lTrackedLines = @(& git -C $RepoRoot -c core.quotePath=false ls-files --stage)
    if ($LASTEXITCODE -ne 0) {
        throw 'git ls-files failed while enumerating tracked candidate files.'
    }
    $lGitLinks = [System.Collections.Generic.Dictionary[string, string]]::new(
        [System.StringComparer]::Ordinal
    )
    $lTracked = @()
    foreach ($lLine in $lTrackedLines) {
        if ($lLine -notmatch '^(?<mode>\d+) (?<object>[0-9a-f]+) (?<stage>\d)\t(?<path>.*)$') {
            throw "Unexpected git index entry: $lLine"
        }
        if ($Matches.stage -ne '0') {
            throw "Candidate index contains an unresolved staged conflict: $($Matches.path)"
        }
        $lTracked += $Matches.path
        if ($Matches.mode -eq '160000') {
            $lGitLinks.Add($Matches.path, $Matches.object)
        }
    }
    $lUntracked = @(& git -C $RepoRoot -c core.quotePath=false ls-files --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) {
        throw 'git ls-files failed while enumerating untracked candidate files.'
    }
    $lPaths = @($lTracked + @($lUntracked | Where-Object { -not (Test-GeneratedUntrackedPath -Path $_) }))
    $lPaths = @($lPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    [Array]::Sort($lPaths, [System.StringComparer]::Ordinal)

    $lFiles = @()
    $lText = [System.Text.StringBuilder]::new()
    foreach ($lRelativePath in $lPaths) {
        $lFullPath = Join-Path $RepoRoot $lRelativePath
        if ($lGitLinks.ContainsKey($lRelativePath)) {
            $lGitMarker = Join-Path $lFullPath '.git'
            if (Test-Path -LiteralPath $lGitMarker) {
                $lHead = @(& git -C $lFullPath rev-parse HEAD)
                if ($LASTEXITCODE -ne 0 -or $lHead.Count -ne 1 -or
                    -not $lHead[0].Equals($lGitLinks[$lRelativePath], [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Candidate submodule revision differs from its gitlink: $lRelativePath"
                }
                $lSubmoduleStatus = @(& git -C $lFullPath -c core.quotePath=false status --porcelain=v1 `
                    --untracked-files=normal --ignore-submodules=none)
                if ($LASTEXITCODE -ne 0) {
                    throw "git status failed for candidate submodule: $lRelativePath"
                }
                if ($lSubmoduleStatus.Count -ne 0) {
                    throw "Candidate submodule has tracked or untracked changes: $lRelativePath"
                }
            }
            $lHash = Get-TextSha256 -Text ('gitlink:' + $lGitLinks[$lRelativePath])
        } elseif (-not (Test-Path -LiteralPath $lFullPath -PathType Leaf)) {
            throw "Candidate file is not a regular file: $lRelativePath"
        } else {
            $lHash = (Get-FileHash -LiteralPath $lFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        $lNormalizedPath = $lRelativePath.Replace('\', '/')
        $lFiles += [pscustomobject] @{ Path = $lNormalizedPath; Sha256 = $lHash }
        $null = $lText.Append($lNormalizedPath).Append("`0").Append($lHash).Append("`n")
    }

    $lFingerprint = Get-TextSha256 -Text $lText.ToString()
    return [pscustomobject] @{ Fingerprint = $lFingerprint; Files = $lFiles }
}

function Get-CandidateState {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $DemoPath
    )

    if (-not (Test-Path -LiteralPath $DemoPath -PathType Leaf)) {
        throw "Demo executable not found: $DemoPath"
    }
    $lSource = Get-CandidateSourceState -RepoRoot $RepoRoot
    return [pscustomobject] @{
        SchemaVersion = 1
        SourceFingerprint = $lSource.Fingerprint
        SourceFiles = $lSource.Files
        DemoPath = [System.IO.Path]::GetFullPath($DemoPath)
        DemoSha256 = (Get-FileHash -LiteralPath $DemoPath -Algorithm SHA256).Hash.ToLowerInvariant()
        CreatedUtc = [DateTime]::UtcNow.ToString('o')
    }
}

function Confirm-Candidate {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $DemoPath,

        [Parameter(Mandatory)]
        [string] $ManifestPath,

        [switch] $Initialize
    )

    $lCurrent = Get-CandidateState -RepoRoot $RepoRoot -DemoPath $DemoPath
    if ($Initialize) {
        $lParent = Split-Path -Parent $ManifestPath
        if (-not (Test-Path -LiteralPath $lParent -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $lParent -Force
        }
        $lTemporaryManifest = $ManifestPath + '.new.' + [Guid]::NewGuid().ToString('N')
        try {
            $lCurrent | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $lTemporaryManifest -Encoding utf8
            Move-Item -LiteralPath $lTemporaryManifest -Destination $ManifestPath -Force
        } finally {
            if (Test-Path -LiteralPath $lTemporaryManifest) {
                Remove-Item -LiteralPath $lTemporaryManifest -Force
            }
        }
        return $lCurrent
    }
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Candidate manifest not found: $ManifestPath"
    }

    $lExpected = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if ($lExpected.SourceFingerprint -ne $lCurrent.SourceFingerprint) {
        throw 'Candidate source fingerprint changed.'
    }
    if ($lExpected.DemoSha256 -ne $lCurrent.DemoSha256) {
        throw 'Candidate demo executable hash changed.'
    }
    if ([System.IO.Path]::GetFullPath($lExpected.DemoPath) -ne [System.IO.Path]::GetFullPath($lCurrent.DemoPath)) {
        throw 'Candidate demo executable path changed.'
    }
    return $lCurrent
}

function Get-BackgroundSnapshotVerdict {
    param(
        [Parameter(Mandatory)]
        [psobject] $Expected,

        [Parameter(Mandatory)]
        [psobject] $Actual,

        [Parameter(Mandatory)]
        [int] $DemoPid
    )

    if (
        [int64] $Actual.Hwnd -eq 0 -or
        [int] $Actual.Pid -eq $DemoPid -or
        [int64] $Expected.Hwnd -ne [int64] $Actual.Hwnd -or
        [int] $Expected.Pid -ne [int] $Actual.Pid -or
        [int] $Expected.CursorX -ne [int] $Actual.CursorX -or
        [int] $Expected.CursorY -ne [int] $Actual.CursorY
    ) {
        return 'inconclusive'
    }
    return 'pass'
}

function Write-CertificationOutcome {
    param(
        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [Parameter(Mandatory)]
        [string] $Mode,

        [Parameter(Mandatory)]
        [ValidateSet('PASS', 'FAIL', 'INCONCLUSIVE')]
        [string] $Outcome,

        [Parameter(Mandatory)]
        [string] $Message
    )

    $lParent = Split-Path -Parent $EvidencePath
    if (-not (Test-Path -LiteralPath $lParent -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $lParent -Force
    }
    [pscustomobject] @{
        Utc = [DateTime]::UtcNow.ToString('o')
        Mode = $Mode
        Outcome = $Outcome
        Message = $Message
    } | ConvertTo-Json -Compress | Add-Content -LiteralPath $EvidencePath -Encoding utf8
}

function Invoke-ControlHelper {
    param(
        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $Arguments,

        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [ValidateRange(1, 180000)]
        [int] $ProcessTimeoutMs = 30000,

        [switch] $AllowFailure
    )

    $lPython = (Get-Command python -ErrorAction Stop).Path
    $lStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $lStartInfo.FileName = $lPython
    $lStartInfo.UseShellExecute = $false
    $lStartInfo.CreateNoWindow = $true
    $lStartInfo.RedirectStandardOutput = $true
    $lStartInfo.RedirectStandardError = $true
    $null = $lStartInfo.ArgumentList.Add($HelperPath)
    foreach ($lArgument in $Arguments) {
        $null = $lStartInfo.ArgumentList.Add($lArgument)
    }
    $lProcess = [System.Diagnostics.Process]::new()
    $lProcess.StartInfo = $lStartInfo
    if (-not $lProcess.Start()) {
        throw 'Control helper process did not start.'
    }
    $lStandardOutput = $lProcess.StandardOutput.ReadToEndAsync()
    $lStandardError = $lProcess.StandardError.ReadToEndAsync()
    $lTimedOut = -not $lProcess.WaitForExit($ProcessTimeoutMs)
    if ($lTimedOut) {
        try {
            $lProcess.Kill($true)
        } catch {
            $lProcess.Kill()
        }
        $lProcess.WaitForExit()
    }
    $lText = $lStandardOutput.GetAwaiter().GetResult()
    $lErrorText = $lStandardError.GetAwaiter().GetResult()
    if (-not [string]::IsNullOrWhiteSpace($lErrorText)) {
        $lText = ($lText.TrimEnd(), $lErrorText.TrimEnd() | Where-Object { $_ }) -join [Environment]::NewLine
    }
    $lExitCode = if ($lTimedOut) { -1 } else { $lProcess.ExitCode }
    $lProcess.Dispose()
    if ($lTimedOut) {
        [pscustomobject] @{
            Utc = [DateTime]::UtcNow.ToString('o')
            Arguments = $Arguments
            ExitCode = $lExitCode
            Error = "Helper process exceeded its $ProcessTimeoutMs ms deadline."
        } | ConvertTo-Json -Compress -Depth 5 | Add-Content -LiteralPath $EvidencePath -Encoding utf8
        throw "Control helper process exceeded its $ProcessTimeoutMs ms deadline."
    }
    try {
        $lPayload = $lText | ConvertFrom-Json
    } catch {
        throw "Control helper returned non-JSON output: $lText"
    }
    [pscustomobject] @{
        Utc = [DateTime]::UtcNow.ToString('o')
        Arguments = $Arguments
        ExitCode = $lExitCode
        Payload = $lPayload
    } | ConvertTo-Json -Compress -Depth 8 | Add-Content -LiteralPath $EvidencePath -Encoding utf8
    if ($lExitCode -ne 0 -and -not $AllowFailure) {
        throw "Control helper failed with exit code ${lExitCode}: $lText"
    }
    return [pscustomobject] @{ ExitCode = $lExitCode; Payload = $lPayload }
}

function Get-DesktopSnapshot {
    param(
        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [string] $EvidencePath
    )

    Add-Type -AssemblyName System.Windows.Forms
    $lWindow = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @('foreground-window') -EvidencePath $EvidencePath
    $lCursor = [System.Windows.Forms.Cursor]::Position
    return [pscustomobject] @{
        Hwnd = [int64] $lWindow.Payload.window.hwnd
        Pid = [int] $lWindow.Payload.window.pid
        CursorX = [int] $lCursor.X
        CursorY = [int] $lCursor.Y
    }
}

function Wait-BridgeReady {
    param(
        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [string] $PipeName,

        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [Parameter(Mandatory)]
        [int] $Timeout
    )

    $lDeadline = [DateTime]::UtcNow.AddMilliseconds($Timeout)
    do {
        $lResult = $null
        try {
            $lResult = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
                'probe-bridge', '--pipe-name', $PipeName, '--timeout-ms', '250'
            ) -EvidencePath $EvidencePath -ProcessTimeoutMs 1000 -AllowFailure
        } catch {
            if (-not $_.Exception.Message.StartsWith('Control helper process exceeded')) {
                throw
            }
        }
        if ($null -ne $lResult -and $lResult.ExitCode -eq 0 -and $lResult.Payload.ok) {
            return
        }
        Start-Sleep -Milliseconds 50
    } while ([DateTime]::UtcNow -lt $lDeadline)
    throw 'Bridge did not become ready before the deadline.'
}

function Wait-StableBackgroundAnchor {
    param(
        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [Parameter(Mandatory)]
        [int] $DemoPid,

        [Parameter(Mandatory)]
        [int] $Timeout
    )

    $lDeadline = [DateTime]::UtcNow.AddMilliseconds($Timeout)
    do {
        $lFirst = Get-DesktopSnapshot -HelperPath $HelperPath -EvidencePath $EvidencePath
        Start-Sleep -Milliseconds 200
        $lSecond = Get-DesktopSnapshot -HelperPath $HelperPath -EvidencePath $EvidencePath
        if ((Get-BackgroundSnapshotVerdict -Expected $lFirst -Actual $lSecond -DemoPid $DemoPid) -eq 'pass') {
            return $lSecond
        }
    } while ([DateTime]::UtcNow -lt $lDeadline)
    throw 'INCONCLUSIVE: no stable non-demo foreground and cursor anchor was observed.'
}

function Confirm-BackgroundStable {
    param(
        [Parameter(Mandatory)]
        [psobject] $Expected,

        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [Parameter(Mandatory)]
        [int] $DemoPid,

        [Parameter(Mandatory)]
        [string] $Step
    )

    $lActual = Get-DesktopSnapshot -HelperPath $HelperPath -EvidencePath $EvidencePath
    [pscustomobject] @{ Step = $Step; Expected = $Expected; Actual = $lActual } |
        ConvertTo-Json -Compress -Depth 5 | Add-Content -LiteralPath $EvidencePath -Encoding utf8
    if ((Get-BackgroundSnapshotVerdict -Expected $Expected -Actual $lActual -DemoPid $DemoPid) -ne 'pass') {
        throw "INCONCLUSIVE: foreground HWND/PID or cursor changed during $Step."
    }
}

function Wait-BridgeOperation {
    param(
        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [string] $PipeName,

        [Parameter(Mandatory)]
        [string] $OperationId,

        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [Parameter(Mandatory)]
        [int] $Timeout
    )

    $lDeadline = [DateTime]::UtcNow.AddMilliseconds($Timeout)
    do {
        $lStatus = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
            'bridge-operation-status', '--pipe-name', $PipeName, '--operation-id', $OperationId,
            '--no-consume', '--timeout-ms', '1000'
        ) -EvidencePath $EvidencePath -AllowFailure
        if ($lStatus.Payload.terminal) {
            $lConsumed = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
                'bridge-operation-status', '--pipe-name', $PipeName, '--operation-id', $OperationId,
                '--timeout-ms', '1000'
            ) -EvidencePath $EvidencePath -AllowFailure
            if (-not $lConsumed.Payload.consumed) {
                throw "Bridge operation $OperationId did not consume cleanly."
            }
            return $lConsumed.Payload
        }
        if ($lStatus.ExitCode -ne 0) {
            throw "Bridge operation $OperationId failed."
        }
        Start-Sleep -Milliseconds 50
    } while ([DateTime]::UtcNow -lt $lDeadline)
    throw "Bridge operation $OperationId did not finish before the deadline."
}

function Invoke-BackgroundWorkflow {
    param(
        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [string] $PipeName,

        [Parameter(Mandatory)]
        [int] $DemoPid,

        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [Parameter(Mandatory)]
        [int] $Timeout
    )

    $lAnchor = Wait-StableBackgroundAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Timeout $Timeout
    $lCommon = @('--pipe-name', $PipeName, '--form-name', 'AccessibilityDemoMainForm')

    $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments (@(
        'bridge-set-text') + $lCommon + @('--control-name', 'edtSearch', '--text', 'Background command proof')) `
        -EvidencePath $EvidencePath
    Confirm-BackgroundStable -Expected $lAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Step 'set-text'

    $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments (@(
        'bridge-select') + $lCommon + @('--control-name', 'cmbQueue', '--index', '1')) `
        -EvidencePath $EvidencePath
    Confirm-BackgroundStable -Expected $lAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Step 'select'

    $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments (@(
        'bridge-invoke') + $lCommon + @('--control-name', 'btnApplyFilters', '--timeout-ms', $Timeout.ToString())) `
        -EvidencePath $EvidencePath -ProcessTimeoutMs ($Timeout + 5000)
    Confirm-BackgroundStable -Expected $lAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Step 'invoke'

    $lOpen = Invoke-ControlHelper -HelperPath $HelperPath -Arguments (@(
        'bridge-invoke') + $lCommon + @('--control-name', 'btnShowModal', '--async')) `
        -EvidencePath $EvidencePath
    Confirm-BackgroundStable -Expected $lAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Step 'queue-modal'

    $lModal = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
        'wait-form', '--pipe-name', $PipeName, '--class-name', 'TMessageForm', '--visible', 'true',
        '--fields', 'name,className,handle', '--timeout-ms', $Timeout.ToString(), '--poll-ms', '50'
    ) -EvidencePath $EvidencePath -ProcessTimeoutMs ($Timeout + 5000)
    Confirm-BackgroundStable -Expected $lAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Step 'modal-open'
    $lModalHandle = [int64] $lModal.Payload.matches[0].handle
    if ($lModalHandle -eq 0) {
        throw 'The bridge-visible modal did not provide a form handle.'
    }

    $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
        'bridge-invoke', '--pipe-name', $PipeName, '--form-hwnd', $lModalHandle.ToString(),
        '--control-name', 'OK', '--timeout-ms', $Timeout.ToString()
    ) -EvidencePath $EvidencePath -ProcessTimeoutMs ($Timeout + 5000)
    Confirm-BackgroundStable -Expected $lAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Step 'modal-dismiss'

    $lOpenStatus = Wait-BridgeOperation -HelperPath $HelperPath -PipeName $PipeName `
        -OperationId ([string] $lOpen.Payload.operationId) -EvidencePath $EvidencePath -Timeout $Timeout
    if ($lOpenStatus.status -ne 'succeeded') {
        throw 'The modal opener operation did not succeed.'
    }
    Confirm-BackgroundStable -Expected $lAnchor -HelperPath $HelperPath -EvidencePath $EvidencePath `
        -DemoPid $DemoPid -Step 'modal-complete'
}

function Invoke-ForegroundWorkflow {
    param(
        [Parameter(Mandatory)]
        [string] $HelperPath,

        [Parameter(Mandatory)]
        [string] $PipeName,

        [Parameter(Mandatory)]
        [int] $DemoPid,

        [Parameter(Mandatory)]
        [string] $TempPath,

        [Parameter(Mandatory)]
        [string] $EvidencePath,

        [Parameter(Mandatory)]
        [int] $Timeout
    )

    $lForm = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
        'bridge-forms', '--pipe-name', $PipeName, '--name', 'AccessibilityDemoMainForm',
        '--fields', 'name,handle', '--timeout-ms', $Timeout.ToString()
    ) -EvidencePath $EvidencePath
    if ([int] $lForm.Payload.count -ne 1) {
        throw 'The foreground proof did not find exactly one main demo form.'
    }
    $lHwnd = [int64] $lForm.Payload.matches[0].handle

    $lMissingLease = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
        'click-control', '--pipe-name', $PipeName, '--form-name', 'AccessibilityDemoMainForm',
        '--control-name', 'edtSearch'
    ) -EvidencePath $EvidencePath -AllowFailure
    if ($lMissingLease.ExitCode -eq 0 -or $lMissingLease.Payload.reason -ne 'session-required') {
        throw 'Foreground input was not rejected without a lease.'
    }

    $lStatePath = Join-Path $TempPath 'foreground-lease.json'
    $lEventPath = Join-Path $TempPath 'foreground-events.jsonl'
    $lReleaseMarker = Join-Path $TempPath 'release-unproven'
    Set-Content -LiteralPath $lReleaseMarker -Value 'Foreground lease release has not been verified.' -Encoding utf8
    $lSessionId = $null
    $lWatchdogPid = 0
    $lLeaseTtlMs = [Math]::Max(60000, $Timeout + 60000)
    try {
        $lStarted = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
            'foreground-session', 'start', '--target-pid', $DemoPid.ToString(), '--target-hwnd', $lHwnd.ToString(),
            '--controller-pid', $PID.ToString(), '--ttl-ms', $lLeaseTtlMs.ToString(), '--state-path', $lStatePath,
            '--event-path', $lEventPath
        ) -EvidencePath $EvidencePath
        $lSessionId = [string] $lStarted.Payload.sessionId
        $lWatchdogPid = [int] $lStarted.Payload.watchdogPid
        $lGuard = @(
            '--session-id', $lSessionId, '--session-state-path', $lStatePath,
            '--require-foreground-pid', $DemoPid.ToString(), '--require-foreground-hwnd', $lHwnd.ToString()
        )
        $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments (@(
            'activate-window', '--hwnd', $lHwnd.ToString(), '--timeout-ms', '3000'
        ) + $lGuard) -EvidencePath $EvidencePath
        $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
            'foreground-session', 'renew', '--session-id', $lSessionId, '--ttl-ms', $lLeaseTtlMs.ToString(),
            '--state-path', $lStatePath
        ) -EvidencePath $EvidencePath
        $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments (@(
            'click-control', '--pipe-name', $PipeName, '--form-name', 'AccessibilityDemoMainForm',
            '--control-name', 'edtSearch'
        ) + $lGuard) -EvidencePath $EvidencePath
        $lText = 'Foreground input proof'
        $null = Invoke-ControlHelper -HelperPath $HelperPath -Arguments (@(
            'clear-and-type', '--text', $lText
        ) + $lGuard) -EvidencePath $EvidencePath
        $lVerified = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
            'bridge-find', '--pipe-name', $PipeName, '--form-name', 'AccessibilityDemoMainForm',
            '--control-name', 'edtSearch', '--value', $lText, '--fields', 'name,value',
            '--timeout-ms', $Timeout.ToString()
        ) -EvidencePath $EvidencePath
        if ([int] $lVerified.Payload.count -ne 1) {
            throw 'The bridge did not observe the text entered through real mouse and keyboard input.'
        }
    } finally {
        if (-not [string]::IsNullOrWhiteSpace($lSessionId)) {
            $lReleased = Invoke-ControlHelper -HelperPath $HelperPath -Arguments @(
                'foreground-session', 'release', '--session-id', $lSessionId, '--state-path', $lStatePath,
                '--event-path', $lEventPath
            ) -EvidencePath $EvidencePath -AllowFailure
            if (
                $lReleased.ExitCode -ne 0 -or
                $lReleased.Payload.alreadyReleased -eq $true -or
                $lReleased.Payload.announcementPlayed -ne $true
            ) {
                throw 'Foreground lease release and its normal announcement were not proven.'
            }
            Wait-ProcessExit -ProcessId $lWatchdogPid -Timeout 5000
            if (Test-Path -LiteralPath $lStatePath) {
                throw 'Foreground lease state remains after normal release.'
            }
            $lNormalReleaseEvents = @(
                Get-Content -LiteralPath $lEventPath |
                    ForEach-Object { $_ | ConvertFrom-Json } |
                    Where-Object { $_.event -eq 'release' -and $_.reason -eq 'normal' }
            )
            if ($lNormalReleaseEvents.Count -ne 1) {
                throw 'Foreground normal-release evidence was not recorded exactly once.'
            }
            Remove-Item -LiteralPath $lReleaseMarker -Force
        }
    }
}

function Wait-ProcessExit {
    param(
        [Parameter(Mandatory)]
        [int] $ProcessId,

        [Parameter(Mandatory)]
        [int] $Timeout
    )

    if ($ProcessId -le 0) {
        throw 'A valid watchdog process ID was not recorded.'
    }
    $lDeadline = [DateTime]::UtcNow.AddMilliseconds($Timeout)
    while ((Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) -and [DateTime]::UtcNow -lt $lDeadline) {
        Start-Sleep -Milliseconds 25
    }
    if (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) {
        throw "Process $ProcessId did not exit before the deadline."
    }
}

function Stop-OwnedDemoProcess {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [System.Diagnostics.Process] $Process,

        [Parameter(Mandatory)]
        [string] $DemoPath
    )

    if ($null -eq $Process -or $Process.HasExited) {
        return
    }
    $lExpectedPath = [System.IO.Path]::GetFullPath($DemoPath)
    $lActualPath = [System.IO.Path]::GetFullPath($Process.Path)
    if ($lActualPath -ne $lExpectedPath) {
        throw "Refusing to stop an unexpected process path: $lActualPath"
    }
    if (-not $PSCmdlet.ShouldProcess($lActualPath, "Stop owned demo process $($Process.Id)")) {
        return
    }
    Stop-Process -Id $Process.Id -Force
    if (-not $Process.WaitForExit(5000)) {
        throw "Owned demo process $($Process.Id) did not exit."
    }
}

function Remove-AgentControlResidue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $TempPath
    )

    foreach ($lPath in @(
        (Join-Path $RepoRoot 'agent-skills\windows-desktop-control\scripts\__pycache__'),
        (Join-Path $RepoRoot 'agent-skills\windows-desktop-control\tests\__pycache__')
    )) {
        if (Test-Path -LiteralPath $lPath) {
            if ($PSCmdlet.ShouldProcess($lPath, 'Remove owned certification residue')) {
                Remove-Item -LiteralPath $lPath -Recurse -Force
                if (Test-Path -LiteralPath $lPath) {
                    throw "Owned residue remains: $lPath"
                }
            }
        }
    }
    if (Test-Path -LiteralPath (Join-Path $TempPath 'release-unproven')) {
        throw "Foreground release was not proven; retained lease evidence at $TempPath"
    }
    if ((Test-Path -LiteralPath $TempPath) -and $PSCmdlet.ShouldProcess($TempPath, 'Remove owned certification residue')) {
        Remove-Item -LiteralPath $TempPath -Recurse -Force
        if (Test-Path -LiteralPath $TempPath) {
            throw "Owned residue remains: $TempPath"
        }
    }
}

function Invoke-AgentControlCertification {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $SelectedMode,

        [Parameter(Mandatory)]
        [string] $ManifestPath,

        [Parameter(Mandatory)]
        [string] $SelectedEvidenceDirectory,

        [switch] $Build,

        [switch] $Initialize,

        [Parameter(Mandatory)]
        [int] $Timeout
    )

    $lDemoPath = Get-DemoExecutablePath -RepoRoot $RepoRoot
    if ($Build) {
        Invoke-DemoBuild -RepoRoot $RepoRoot
    }
    $null = Confirm-Candidate -RepoRoot $RepoRoot -DemoPath $lDemoPath -ManifestPath $ManifestPath `
        -Initialize:$Initialize

    if (-not (Test-Path -LiteralPath $SelectedEvidenceDirectory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $SelectedEvidenceDirectory -Force
    }
    $lEvidencePath = Join-Path $SelectedEvidenceDirectory ($SelectedMode.ToLowerInvariant() + '.jsonl')
    $lTempPath = Join-Path ([System.IO.Path]::GetTempPath()) ('agent-control-cert-' + [Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $lTempPath
    $lPipeName = 'MaxLogic.Accessibility.AgentBridge.Cert.' + [Guid]::NewGuid().ToString('N')
    $lHelperPath = Join-Path $RepoRoot 'agent-skills\windows-desktop-control\scripts\windows_desktop_control.py'
    $lProcess = $null
    try {
        $lProcess = Start-Process -FilePath $lDemoPath -ArgumentList @(
            '--a11y-agent-bridge', "--a11y-agent-bridge-pipe=$lPipeName", '--a11y-agent-bridge-mutations'
        ) -PassThru
        Wait-BridgeReady -HelperPath $lHelperPath -PipeName $lPipeName -EvidencePath $lEvidencePath -Timeout $Timeout
        if ($SelectedMode -eq 'Background') {
            Invoke-BackgroundWorkflow -HelperPath $lHelperPath -PipeName $lPipeName -DemoPid $lProcess.Id `
                -EvidencePath $lEvidencePath -Timeout $Timeout
        } else {
            Invoke-ForegroundWorkflow -HelperPath $lHelperPath -PipeName $lPipeName -DemoPid $lProcess.Id `
                -TempPath $lTempPath -EvidencePath $lEvidencePath -Timeout $Timeout
        }
    } finally {
        try {
            Stop-OwnedDemoProcess -Process $lProcess -DemoPath $lDemoPath
        } finally {
            Remove-AgentControlResidue -RepoRoot $RepoRoot -TempPath $lTempPath
        }
    }

    if ($null -eq $lProcess -or -not $lProcess.HasExited) {
        throw 'Owned demo process residue remains after certification.'
    }
    $lPipeResidue = Invoke-ControlHelper -HelperPath $lHelperPath -Arguments @(
        'probe-bridge', '--pipe-name', $lPipeName, '--timeout-ms', '100'
    ) -EvidencePath $lEvidencePath -ProcessTimeoutMs 1000 -AllowFailure
    if ($lPipeResidue.ExitCode -eq 0) {
        throw 'Owned bridge pipe residue remains after certification.'
    }
    $null = Confirm-Candidate -RepoRoot $RepoRoot -DemoPath $lDemoPath -ManifestPath $ManifestPath
    Write-CertificationOutcome -EvidencePath $lEvidencePath -Mode $SelectedMode -Outcome 'PASS' `
        -Message 'Both candidate and mode-specific certification checks passed.'
    [pscustomobject] @{
        Ok = $true
        Mode = $SelectedMode
        CandidateManifest = $ManifestPath
        Evidence = $lEvidencePath
        DemoPath = $lDemoPath
    } | ConvertTo-Json -Depth 4
}

if ($MyInvocation.InvocationName -ne '.') {
    $lRepoRoot = Split-Path -Parent $PSScriptRoot
    if ($Config -ne 'Debug' -or $Platform -ne 'Win32') {
        throw 'Certification requires the normal Win32 Debug demo candidate.'
    }
    $lManifestPath = Resolve-RepoPath -RepoRoot $lRepoRoot -Path $CandidateManifest
    if ([string]::IsNullOrWhiteSpace($EvidenceDirectory)) {
        $lEvidenceDirectory = Join-Path $lRepoRoot '.agents\runs\agent-control-two-mode\evidence'
    } else {
        $lEvidenceDirectory = Resolve-RepoPath -RepoRoot $lRepoRoot -Path $EvidenceDirectory
    }
    $lEvidencePath = Join-Path $lEvidenceDirectory ($Mode.ToLowerInvariant() + '.jsonl')
    try {
        Invoke-AgentControlCertification -RepoRoot $lRepoRoot -SelectedMode $Mode -ManifestPath $lManifestPath `
            -SelectedEvidenceDirectory $lEvidenceDirectory -Build:$BuildDemo -Initialize:$InitializeCandidate `
            -Timeout $TimeoutMs
    } catch {
        $lCertificationError = $_
        $lOutcome = if ($lCertificationError.Exception.Message.StartsWith(
            'INCONCLUSIVE:', [System.StringComparison]::Ordinal)) {
            'INCONCLUSIVE'
        } else {
            'FAIL'
        }
        try {
            Write-CertificationOutcome -EvidencePath $lEvidencePath -Mode $Mode -Outcome $lOutcome `
                -Message $lCertificationError.Exception.Message
        } catch {
            Write-Warning 'The terminal certification outcome could not be written to evidence.'
        }
        Write-Error $lCertificationError -ErrorAction Continue
        if ($lOutcome -eq 'INCONCLUSIVE') {
            exit 3
        }
        exit 1
    }
}
