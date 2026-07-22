# Static-analysis audit, 2026-07-19

## Policy

Normal actionable reports cover project and repository code only. Third-party
findings remain visible as separate coverage totals but are not work items for
this repository.

- FixInsight retains the complete raw report while the actionable projection
  excludes the two installed DUnitX source roots by path.
- FixInsight complexity and style-only rules `C101`, `C102`, `C103`, `O801`,
  `O803`, `O804`, and `W528` remain available in the raw report but are omitted
  from the actionable report.
- PAL continues to parse TMS source because excluding it with `/X` removes
  semantic information needed at our call sites.
- Reviewed PAL false positives use line-specific `PALOFF` markers with the
  applicable section code and a reason. No PAL report category is disabled
  globally.

## Ownership correction

PAL warning rows identify a module and line, not a source filename. The same
run's `Modules.xml` does provide the full filename. Joining those reports
resolved all 7,558 formerly unknown findings to installed TMS VCL UI Pack
source, with zero missing or project-owned resolutions.

DelphiAIKit schema v3 now performs that join centrally before report policy is
applied. `scripts\analyze.ps1` consumes its actionable, ignored, external,
advisory-metric, and unknown projections and no longer duplicates the
`Modules.xml` resolver. Raw JSONL and full SARIF evidence remain complete.

A control run using `/X=F:\TMS-SmartSetUp\Products<+>` removed TMS from PAL's
semantic model and introduced nine false project findings: eight unknown values
written by TMS out parameters and one adapter cast warning. `/X` and `/XF`
therefore remain explicit coverage controls, not automatic ownership filters.

## Reviewed results

The original report contained 269 project-owned and 131 DUnitX FixInsight
findings, plus 467 project-owned and 7,558 pathless TMS PAL findings.

Worthwhile changes:

- renamed six private fields that shadowed ancestor or provider-base fields;
- explicitly initialized three COM navigation helper results and one named-pipe
  reader result;
- documented exact intentional pointer guards, guarded casts, Win32 packing,
  interface/object bridges, external out parameters, lifecycle exits, and test
  output variables with PAL section suppressions.

The final repository entrypoint reports:

- FixInsight: 3 reviewed lifecycle/UI findings (`W508` once and `W515` twice);
- PAL: 298 style/metric findings and zero strong warnings;
- external PAL coverage: 7,558 findings, all resolved to installed TMS source;
- DUnitX FixInsight findings: 0;
- genuinely unresolved findings: 0.

The remaining actionable PAL findings are 137 functions called as procedures, 78
deterministic initializations before out calls, 25 inline-local suggestions, 19
intentional repeat-loop counters, 14 recursive routines, 12 existing interface
parameters where changing `const` would alter signatures, and 13 other
optimization suggestions. None provides a correctness or clarity improvement
worth changing the current code or public API.

## Persistent gate

`scripts\static-analysis-baseline.json` is the reviewed Release Win32 baseline.
The wrapper enables `DAK_GATE=1` on every run, requires schema v3, fails closed
on analyzer, finalization, ownership, compatibility, verification, or policy
failure, and restores the caller's process environment afterward. The baseline
is not replaced during normal analysis; `-UpdateBaseline` is the explicit
maintenance operation used to establish or intentionally replace it.

The certification tool candidate is pinned by executable SHA-256
`627b66844894d4d5840ba8f60812e8edc5e7bf36ff64792fbbbe8e822763b189`.
Its `dak.ini`, PAL rule map, and schema-v3 postprocessor are frozen with it for
the complete gate, so a dirty DelphiAIKit development checkout cannot alter the
candidate during certification.

## Commands

```powershell
.\scripts\analyze.ps1 -Config Release -Platform Win32
$lResult = Invoke-Pester -Path .\scripts\tests\analyze.Tests.ps1 -PassThru; if ($lResult.FailedCount -ne 0) { exit 1 }
Invoke-ScriptAnalyzer -Path .\scripts\analyze.ps1 -Severity Warning,Error
.\scripts\test.ps1 -Config Debug -Platform Win32
EncodingFixTool path=. preset=delphi-ai scope=git-changed format=json
git diff --check
```
