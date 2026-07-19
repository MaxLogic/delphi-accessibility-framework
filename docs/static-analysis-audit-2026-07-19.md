# Static-analysis audit, 2026-07-19

## Policy

Normal actionable reports cover project and repository code only. Third-party
findings remain visible as separate coverage totals but are not work items for
this repository.

- FixInsight excludes the two installed DUnitX source roots by path.
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

The repository analysis entrypoint performs that verification until
DelphiAIKit implements the join centrally. The upstream work is recorded in:

`F:\projects\MaxLogic\DelphiAiKit\issues\active\2026-07-19-pal-module-path-ownership-and-exclusions.md`

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

Until the DelphiAIKit issue is fixed, DAK's generated summary still labels the
7,558 pathless PAL rows as unknown. `scripts\analyze.ps1` rejects any row that
cannot be joined to `Modules.xml`, rejects any joined path inside this
repository, and reports the verified external count separately.

The remaining PAL findings are 137 functions called as procedures, 78
deterministic initializations before out calls, 25 inline-local suggestions, 19
intentional repeat-loop counters, 14 recursive routines, 12 existing interface
parameters where changing `const` would alter signatures, and 13 other
optimization suggestions. None provides a correctness or clarity improvement
worth changing the current code or public API.

## Commands

```powershell
.\scripts\analyze.ps1 -Config Release -Platform Win32
Invoke-ScriptAnalyzer -Path .\scripts\analyze.ps1 -Severity Warning,Error
.\scripts\test.ps1 -Config Debug -Platform Win32
EncodingFixTool path=. preset=delphi-ai scope=git-changed format=json
git diff --check
```
