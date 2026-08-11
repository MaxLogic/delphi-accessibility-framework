$ErrorActionPreference = 'Stop'

Describe 'Repository DUnitX test wrapper contract' {
    BeforeAll {
        $lScriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'test.ps1'
        $script:lScriptText = Get-Content -LiteralPath $lScriptPath -Raw
        $lTokens = $null
        $lErrors = $null
        $script:lAst = [System.Management.Automation.Language.Parser]::ParseFile(
            $lScriptPath,
            [ref] $lTokens,
            [ref] $lErrors
        )
        $script:lParseErrors = @($lErrors)
    }

    It 'has valid syntax and an optional log path' {
        $script:lParseErrors.Count | Should -Be 0
        $lParameterNames = @(
            $script:lAst.ParamBlock.Parameters |
                ForEach-Object { $_.Name.VariablePath.UserPath }
        )
        $lParameterNames | Should -Contain 'LogPath'
    }

    It 'streams and retains the same native test output' {
        $script:lScriptText | Should -Match '&\s+\$lTestExe\s+@lArguments\s+2>&1\s+\|\s+Tee-Object\s+-Variable\s+lOutput'
        $script:lScriptText | Should -Match 'Tee-Object\s+-Variable\s+lOutput\s+\|\s+Tee-Object\s+-FilePath\s+\$lResolvedLogPath'
        $script:lScriptText | Should -Match '\$lExitCode\s*=\s*\$LASTEXITCODE'
    }

    It 'keeps zero-test and zero-failure summary enforcement' {
        $script:lScriptText | Should -Match 'DUNITX_RESULT tests='
        $script:lScriptText | Should -Match 'failures=0 errors=0 ignored=0'
        $script:lScriptText | Should -Match 'did not report any discovered tests'
    }
}
