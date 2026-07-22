$ErrorActionPreference = 'Stop'

Describe 'Repository static-analysis wrapper contract' {
    BeforeAll {
        $lScriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'analyze.ps1'
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

    It 'has valid syntax and explicit persistent-baseline controls' {
        $script:lParseErrors.Count | Should -Be 0
        $lParameterNames = @(
            $script:lAst.ParamBlock.Parameters |
                ForEach-Object { $_.Name.VariablePath.UserPath }
        )
        $lParameterNames | Should -Contain 'BaselinePath'
        $lParameterNames | Should -Contain 'UpdateBaseline'
        $script:lScriptText | Should -Match 'static-analysis-baseline\.json'
    }

    It 'enables the real DAK gate and restores process environment state' {
        $script:lScriptText | Should -Match '\$env:DAK_GATE\s*=\s*''1'''
        $script:lScriptText | Should -Match '\$env:DAK_BASELINE\s*='
        $script:lScriptText | Should -Match '\$env:DAK_UPDATE_BASELINE\s*='
        $script:lScriptText | Should -Match 'finally\s*\{'
    }

    It 'keeps the JSON baseline without a changing machine-local Markdown sibling' {
        $script:lScriptText | Should -Match 'ChangeExtension\(\$lBaselinePath, ''\.md''\)'
        $script:lScriptText | Should -Match 'Remove-Item -LiteralPath \$lBaselineMarkdown'
    }

    It 'consumes schema v3 projections without duplicating ownership resolution' {
        $script:lScriptText | Should -Match '& python \$lPostprocess \$lOutPath'
        $script:lScriptText | Should -Match '& python \$lPostprocess --verify \$lOutPath'
        $script:lScriptText | Should -Match '\$lSummary\.schema_version\s*-ne\s*3'
        $script:lScriptText | Should -Match '\$lSummary\.counts\.actionable\.fixinsight'
        $script:lScriptText | Should -Match '\$lSummary\.counts\.external\.pascal_analyzer'
        $script:lScriptText | Should -Match '\$lSummary\.counts\.unknown\.total'
        $script:lScriptText | Should -Match '\$lSummary\.status\.policy\s*-ne\s*''pass'''
        $script:lScriptText | Should -Not -Match 'Modules\.xml'
        $script:lScriptText | Should -Not -Match '\$lDUnitXFindings'
    }
}
