$ErrorActionPreference = 'Stop'

Describe 'Two-mode agent-control certification contract' {
    BeforeAll {
        $script:lRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:lScriptPath = Join-Path $script:lRepoRoot 'scripts\certify-agent-control.ps1'
        $script:lScriptText = Get-Content -LiteralPath $script:lScriptPath -Raw
        $lTokens = $null
        $lErrors = $null
        $script:lAst = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:lScriptPath,
            [ref] $lTokens,
            [ref] $lErrors
        )
        $script:lParseErrors = @($lErrors)
        . $script:lScriptPath
    }

    It 'has valid syntax and the exact public certification controls' {
        $script:lParseErrors.Count | Should -Be 0
        $lParameterNames = @(
            $script:lAst.ParamBlock.Parameters |
                ForEach-Object { $_.Name.VariablePath.UserPath }
        )
        foreach ($lName in @('Config', 'Platform', 'Mode', 'BuildDemo', 'InitializeCandidate', 'CandidateManifest')) {
            $lParameterNames | Should -Contain $lName
        }
        $script:lScriptText | Should -Match 'bin\\Win32\\Debug\\AccessibilityComplexDemo\.exe'
    }

    It 'uses the warning-enforced normal Debug demo rebuild arguments' {
        $lArguments = Get-DemoBuildArgument -RepoRoot $script:lRepoRoot

        $lArguments | Should -Contain '--target'
        $lArguments | Should -Contain 'Rebuild'
        $lArguments | Should -Contain '--dfmcheck'
        $lArguments | Should -Contain '--dfm'
        $lArguments | Should -Contain 'AccessibilityDemoMainForm.dfm'
        $lArguments | Should -Contain '--show-warnings'
        $lArguments | Should -Contain '--show-hints'
        ($lArguments -join ' ') | Should -Match '--config Debug'
        ($lArguments -join ' ') | Should -Match '--platform Win32'
    }

    It 'rejects compiler warnings and hints but accepts clean output' {
        Test-CompilerOutputClean -Output @('SUCCESS', 'Result: OK') | Should -BeTrue
        Test-CompilerOutputClean -Output @('Unit.pas(4): warning W1000 Symbol deprecated') | Should -BeFalse
        Test-CompilerOutputClean -Output @('Unit.pas(4): H2164 Variable is declared but never used') | Should -BeFalse
        Test-CompilerOutputClean -Output @('warning: unsafe result') | Should -BeFalse
    }

    It 'restores the caller DFM-check MSBuild environment after a build' {
        $lRoot = Join-Path $TestDrive 'build-repo'
        $lDemo = Join-Path $lRoot 'bin\Win32\Debug\AccessibilityComplexDemo.exe'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $lDemo) -Force
        Set-Content -LiteralPath $lDemo -Value 'demo'
        $lFakeDak = Join-Path $TestDrive 'dak.cmd'
        Set-Content -LiteralPath $lFakeDak -Value "@echo SUCCESS.`r`n@exit /b 0`r`n" -Encoding ascii
        $lHadDak = Test-Path Env:DAK_EXE
        $lPreviousDak = $env:DAK_EXE
        $lHadMsBuild = Test-Path Env:DAK_DFMCHECK_MSBUILD
        $lPreviousMsBuild = $env:DAK_DFMCHECK_MSBUILD
        try {
            $env:DAK_EXE = $lFakeDak
            Remove-Item Env:DAK_DFMCHECK_MSBUILD -ErrorAction SilentlyContinue

            Invoke-DemoBuild -RepoRoot $lRoot

            Test-Path Env:DAK_DFMCHECK_MSBUILD | Should -BeFalse
        } finally {
            if ($lHadDak) { $env:DAK_EXE = $lPreviousDak } else { Remove-Item Env:DAK_EXE -ErrorAction SilentlyContinue }
            if ($lHadMsBuild) {
                $env:DAK_DFMCHECK_MSBUILD = $lPreviousMsBuild
            } else {
                Remove-Item Env:DAK_DFMCHECK_MSBUILD -ErrorAction SilentlyContinue
            }
        }
    }

    It 'fingerprints tracked and nonignored untracked files deterministically' {
        $lRoot = Join-Path $TestDrive 'candidate-repo'
        New-Item -ItemType Directory -Path $lRoot | Out-Null
        & git -C $lRoot init --quiet
        Set-Content -LiteralPath (Join-Path $lRoot '.gitignore') -Value "ignored.txt`n__pycache__/`n"
        Set-Content -LiteralPath (Join-Path $lRoot 'tracked.txt') -Value 'tracked'
        & git -C $lRoot add .gitignore tracked.txt
        & git -C $lRoot update-index --add --cacheinfo 160000,1111111111111111111111111111111111111111,lib/module
        Set-Content -LiteralPath (Join-Path $lRoot 'untracked.txt') -Value 'untracked'
        Set-Content -LiteralPath (Join-Path $lRoot 'source.res') -Value 'resource input'
        Set-Content -LiteralPath (Join-Path $lRoot 'runtime.dll') -Value 'runtime input'
        Set-Content -LiteralPath (Join-Path $lRoot 'ignored.txt') -Value 'ignored'
        New-Item -ItemType Directory -Path (Join-Path $lRoot '__pycache__') | Out-Null
        Set-Content -LiteralPath (Join-Path $lRoot '__pycache__\cache.pyc') -Value 'cache'

        $lFirst = Get-CandidateSourceState -RepoRoot $lRoot
        $lSecond = Get-CandidateSourceState -RepoRoot $lRoot
        $lFirst.Fingerprint | Should -Be $lSecond.Fingerprint
        $lFirst.Files.Path | Should -Contain 'tracked.txt'
        $lFirst.Files.Path | Should -Contain 'untracked.txt'
        $lFirst.Files.Path | Should -Contain 'lib/module'
        $lFirst.Files.Path | Should -Contain 'source.res'
        $lFirst.Files.Path | Should -Contain 'runtime.dll'
        $lFirst.Files.Path | Should -Not -Contain 'ignored.txt'
        ($lFirst.Files.Path -join '|') | Should -Not -Match '__pycache__|\.pyc'

        Set-Content -LiteralPath (Join-Path $lRoot 'untracked.txt') -Value 'changed'
        (Get-CandidateSourceState -RepoRoot $lRoot).Fingerprint | Should -Not -Be $lFirst.Fingerprint
    }

    It 'rejects tracked and untracked changes in an initialized submodule' {
        $lDependency = Join-Path $TestDrive 'dependency-repo'
        New-Item -ItemType Directory -Path $lDependency | Out-Null
        & git -C $lDependency init --quiet
        Set-Content -LiteralPath (Join-Path $lDependency 'dependency.pas') -Value 'unit Dependency; end.'
        & git -C $lDependency add dependency.pas
        & git -C $lDependency -c user.name=Test -c user.email=test@example.invalid commit --quiet -m initial

        $lRoot = Join-Path $TestDrive 'submodule-candidate-repo'
        New-Item -ItemType Directory -Path $lRoot | Out-Null
        & git -C $lRoot init --quiet
        & git -C $lRoot -c protocol.file.allow=always submodule add --quiet $lDependency lib/dependency
        & git -C $lRoot add .gitmodules lib/dependency
        { Get-CandidateSourceState -RepoRoot $lRoot } | Should -Not -Throw

        $lDependencyFile = Join-Path $lRoot 'lib\dependency\dependency.pas'
        Set-Content -LiteralPath $lDependencyFile -Value 'unit Dependency; interface implementation end.'
        { Get-CandidateSourceState -RepoRoot $lRoot } | Should -Throw '*submodule*'

        Set-Content -LiteralPath $lDependencyFile -Value 'unit Dependency; end.'
        Set-Content -LiteralPath (Join-Path $lRoot 'lib\dependency\untracked.inc') -Value 'dirty'
        { Get-CandidateSourceState -RepoRoot $lRoot } | Should -Throw '*submodule*'
    }

    It 'initializes and compares one source and demo candidate' {
        $lRoot = Join-Path $TestDrive 'manifest-repo'
        New-Item -ItemType Directory -Path $lRoot | Out-Null
        & git -C $lRoot init --quiet
        Set-Content -LiteralPath (Join-Path $lRoot '.gitignore') -Value ".agents/`n*.exe`n"
        Set-Content -LiteralPath (Join-Path $lRoot 'source.txt') -Value 'source'
        & git -C $lRoot add .gitignore source.txt
        $lDemo = Join-Path $lRoot 'demo.exe'
        Set-Content -LiteralPath $lDemo -Value 'demo'
        $lManifest = Join-Path $lRoot '.agents\candidate.json'

        Confirm-Candidate -RepoRoot $lRoot -DemoPath $lDemo -ManifestPath $lManifest -Initialize
        { Confirm-Candidate -RepoRoot $lRoot -DemoPath $lDemo -ManifestPath $lManifest } | Should -Not -Throw
        Set-Content -LiteralPath (Join-Path $lRoot 'source.txt') -Value 'changed'
        { Confirm-Candidate -RepoRoot $lRoot -DemoPath $lDemo -ManifestPath $lManifest } | Should -Throw '*source fingerprint*'
        Set-Content -LiteralPath (Join-Path $lRoot 'source.txt') -Value 'source'
        Set-Content -LiteralPath $lDemo -Value 'changed demo'
        { Confirm-Candidate -RepoRoot $lRoot -DemoPath $lDemo -ManifestPath $lManifest } | Should -Throw '*demo executable hash*'
        { Confirm-Candidate -RepoRoot $lRoot -DemoPath $lDemo -ManifestPath $lManifest -Initialize } |
            Should -Not -Throw
        { Confirm-Candidate -RepoRoot $lRoot -DemoPath $lDemo -ManifestPath $lManifest } | Should -Not -Throw
    }

    It 'classifies only an unchanged non-demo foreground and cursor as stable' {
        $lAnchor = [pscustomobject] @{ Hwnd = 100; Pid = 10; CursorX = 20; CursorY = 30 }
        Get-BackgroundSnapshotVerdict -Expected $lAnchor -Actual $lAnchor -DemoPid 99 | Should -Be 'pass'
        Get-BackgroundSnapshotVerdict -Expected $lAnchor -Actual ([pscustomobject] @{
            Hwnd = 101; Pid = 10; CursorX = 20; CursorY = 30
        }) -DemoPid 99 | Should -Be 'inconclusive'
        Get-BackgroundSnapshotVerdict -Expected $lAnchor -Actual ([pscustomobject] @{
            Hwnd = 100; Pid = 99; CursorX = 20; CursorY = 30
        }) -DemoPid 99 | Should -Be 'inconclusive'
        Get-BackgroundSnapshotVerdict -Expected $lAnchor -Actual ([pscustomobject] @{
            Hwnd = 100; Pid = 10; CursorX = 21; CursorY = 30
        }) -DemoPid 99 | Should -Be 'inconclusive'
    }

    It 'keeps background orchestration bridge-only and includes the real modal round trip' {
        $lBackground = [regex]::Match(
            $script:lScriptText,
            '(?s)function Invoke-BackgroundWorkflow.*?(?=function Invoke-ForegroundWorkflow)'
        ).Value
        $lBackground | Should -Match 'bridge-set-text'
        $lBackground | Should -Match 'bridge-select'
        $lBackground | Should -Match 'bridge-invoke'
        $lBackground | Should -Match 'wait-form'
        $lBackground | Should -Match 'Wait-BridgeOperation'
        $script:lScriptText | Should -Match 'bridge-operation-status'
        $lBackground | Should -Not -Match 'activate-window|click-control|clear-and-type|SetCursorPos|SendInput'
    }

    It 'implements leased foreground proof and exact owned-residue cleanup' {
        $lForeground = [regex]::Match(
            $script:lScriptText,
            '(?s)function Invoke-ForegroundWorkflow.*?(?=function Wait-ProcessExit)'
        ).Value
        $script:lScriptText | Should -Match 'foreground-session.*start'
        $script:lScriptText | Should -Match 'foreground-session.*release'
        $script:lScriptText | Should -Match 'activate-window'
        $script:lScriptText | Should -Match 'click-control'
        $lForeground | Should -Match "'clear-and-type'"
        $lForeground | Should -Match "'clear-and-type'.*'--delay-ms'"
        $lForeground | Should -Not -Match "'type-text'"
        $lForeground | Should -Match '\[char\]\s*0x017B'
        $script:lScriptText | Should -Match 'scripts\\__pycache__'
        $script:lScriptText | Should -Match 'tests\\__pycache__'
        $script:lScriptText | Should -Match 'finally\s*\{'
    }

    It 'bounds a genuinely hanging helper subprocess' {
        $lHelper = Join-Path $TestDrive 'hang.py'
        Set-Content -LiteralPath $lHelper -Value "import time`ntime.sleep(10)`n"
        $lEvidence = Join-Path $TestDrive 'hang.jsonl'
        $lStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        {
            Invoke-ControlHelper -HelperPath $lHelper -Arguments @() -EvidencePath $lEvidence `
                -ProcessTimeoutMs 100
        } | Should -Throw '*deadline*'

        $lStopwatch.Stop()
        $lStopwatch.ElapsedMilliseconds | Should -BeLessThan 3000
    }

    It 'retries a timed-out readiness probe within the workflow deadline' {
        $lHelper = Join-Path $TestDrive 'slow-first-probe.py'
        Set-Content -LiteralPath $lHelper -Value @'
import json
import pathlib
import time

marker = pathlib.Path(__file__).with_suffix('.marker')
if not marker.exists():
    marker.write_text('started', encoding='utf-8')
    time.sleep(10)
else:
    print(json.dumps({'ok': True}))
'@
        $lEvidence = Join-Path $TestDrive 'slow-first-probe.jsonl'

        {
            Wait-BridgeReady -HelperPath $lHelper -PipeName 'ignored' -EvidencePath $lEvidence -Timeout 2500
        } | Should -Not -Throw
    }

    It 'consumes a failed terminal bridge operation before reporting it' {
        $lHelper = Join-Path $TestDrive 'failed-operation.py'
        Set-Content -LiteralPath $lHelper -Value @'
import json
import pathlib
import sys

counter = pathlib.Path(__file__).with_suffix('.count')
count = int(counter.read_text(encoding='utf-8')) + 1 if counter.exists() else 1
counter.write_text(str(count), encoding='utf-8')
print(json.dumps({
    'ok': True,
    'cmd': 'operation.status',
    'status': 'failed',
    'terminal': True,
    'consumed': count > 1,
    'operationErrorCode': 'fixture_failure'
}))
sys.exit(2)
'@
        $lEvidence = Join-Path $TestDrive 'failed-operation.jsonl'

        $lResult = Wait-BridgeOperation -HelperPath $lHelper -PipeName 'ignored' -OperationId 'op1' `
            -EvidencePath $lEvidence -Timeout 2000

        $lResult.status | Should -Be 'failed'
        $lResult.consumed | Should -BeTrue
        Get-Content -LiteralPath ([IO.Path]::ChangeExtension($lHelper, '.count')) | Should -Be '2'
    }

    It 'removes only owned cache/temp residue and preserves unproven lease evidence' {
        $lRoot = Join-Path $TestDrive 'cleanup-repo'
        $lScriptsCache = Join-Path $lRoot 'agent-skills\windows-desktop-control\scripts\__pycache__'
        $lTestsCache = Join-Path $lRoot 'agent-skills\windows-desktop-control\tests\__pycache__'
        $lTemp = Join-Path $TestDrive 'owned-temp'
        $lEvidence = Join-Path $TestDrive 'evidence\result.jsonl'
        $null = New-Item -ItemType Directory -Path $lScriptsCache -Force
        $null = New-Item -ItemType Directory -Path $lTestsCache -Force
        $null = New-Item -ItemType Directory -Path $lTemp -Force
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $lEvidence) -Force
        Set-Content -LiteralPath $lEvidence -Value 'evidence'

        Remove-AgentControlResidue -RepoRoot $lRoot -TempPath $lTemp
        Test-Path -LiteralPath $lScriptsCache | Should -BeFalse
        Test-Path -LiteralPath $lTestsCache | Should -BeFalse
        Test-Path -LiteralPath $lTemp | Should -BeFalse
        Test-Path -LiteralPath $lEvidence | Should -BeTrue

        $null = New-Item -ItemType Directory -Path $lTemp -Force
        Set-Content -LiteralPath (Join-Path $lTemp 'release-unproven') -Value 'retain'
        { Remove-AgentControlResidue -RepoRoot $lRoot -TempPath $lTemp } | Should -Throw '*release*not proven*'
        Test-Path -LiteralPath $lTemp | Should -BeTrue
    }

    It 'records explicit terminal certification outcomes' {
        $lEvidence = Join-Path $TestDrive 'terminal\background.jsonl'
        Write-CertificationOutcome -EvidencePath $lEvidence -Mode 'Background' -Outcome 'PASS' -Message 'complete'
        Write-CertificationOutcome -EvidencePath $lEvidence -Mode 'Background' -Outcome 'INCONCLUSIVE' `
            -Message 'independent cursor movement'

        $lRecords = @(Get-Content -LiteralPath $lEvidence | ForEach-Object { $_ | ConvertFrom-Json })
        $lRecords.Count | Should -Be 2
        $lRecords[0].Outcome | Should -Be 'PASS'
        $lRecords[1].Outcome | Should -Be 'INCONCLUSIVE'
    }

    It 'returns after success and preserves explicit failure exit codes' {
        $lEntrypoint = [regex]::Match(
            $script:lScriptText,
            '(?s)if \(\$MyInvocation\.InvocationName -ne ''\.''\).*\z'
        ).Value

        $lEntrypoint | Should -Not -Match 'exit 0'
        $lEntrypoint | Should -Match 'Write-Error \$lCertificationError -ErrorAction Continue'
        $lEntrypoint | Should -Match 'if \(\$lOutcome -eq ''INCONCLUSIVE''\)\s*\{\s*exit 3'
        $lEntrypoint | Should -Match 'exit 1'
    }

    It 'refuses a mismatched process path and stops only the exact owned executable' {
        $lSleeper = Join-Path $TestDrive 'sleeper.py'
        Set-Content -LiteralPath $lSleeper -Value "import time`ntime.sleep(30)`n"
        $lPython = (Get-Command python -ErrorAction Stop).Path
        $lProcess = Start-Process -FilePath $lPython -ArgumentList $lSleeper -PassThru -WindowStyle Hidden
        try {
            { Stop-OwnedDemoProcess -Process $lProcess -DemoPath (Join-Path $TestDrive 'other.exe') } |
                Should -Throw '*unexpected process path*'
            $lProcess.HasExited | Should -BeFalse

            Stop-OwnedDemoProcess -Process $lProcess -DemoPath $lPython
            $lProcess.HasExited | Should -BeTrue
        } finally {
            if (-not $lProcess.HasExited) {
                Stop-Process -Id $lProcess.Id -Force
                $null = $lProcess.WaitForExit(5000)
            }
            $lProcess.Dispose()
        }
    }
}
