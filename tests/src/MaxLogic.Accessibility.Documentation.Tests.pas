unit MaxLogic.Accessibility.Documentation.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Documentation')]
  TAccessibilityDocumentationTests = class
  public
    [Test]
    procedure ReadmeDocumentsInstallAndSupportedScenarios;
    [Test]
    procedure UiaProbeDocumentationListsRunnableScenarios;
    [Test]
    procedure NvdaChecklistDocumentsExpectedSpeech;
  end;

implementation

uses
  System.IOUtils, System.SysUtils,
  DUnitX.Assert;

function RepoRoot: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\..'));
end;

function ReadRepoText(const aRelativePath: string): string;
var
  lPath: string;
begin
  lPath := TPath.Combine(RepoRoot, aRelativePath);
  Assert.IsTrue(TFile.Exists(lPath), aRelativePath + ' is missing.');
  Result := TFile.ReadAllText(lPath, TEncoding.UTF8);
end;

procedure RequireText(const aText: string; const aExpected: string; const aContext: string);
begin
  Assert.IsTrue(Pos(aExpected, aText) > 0, Format('%s must contain "%s".', [aContext, aExpected]));
end;

procedure TAccessibilityDocumentationTests.NvdaChecklistDocumentsExpectedSpeech;
var
  lText: string;
begin
  lText := ReadRepoText('docs\nvda-checklist.md');

  RequireText(lText, 'TLabel', 'NVDA checklist');
  RequireText(lText, 'TSpeedButton', 'NVDA checklist');
  RequireText(lText, 'TPanel', 'NVDA checklist');
  RequireText(lText, 'visible hint', 'NVDA checklist');
  RequireText(lText, 'balloon hint', 'NVDA checklist');
  RequireText(lText, 'TStringGrid', 'NVDA checklist');
  RequireText(lText, 'TAdvStringGrid', 'NVDA checklist');
  RequireText(lText, 'TAccessibilityTmsAdvStringGridAdapters.CreateRegistry', 'NVDA checklist');
  RequireText(lText, 'cell text only', 'NVDA checklist');
end;

procedure TAccessibilityDocumentationTests.ReadmeDocumentsInstallAndSupportedScenarios;
var
  lText: string;
begin
  lText := ReadRepoText('README.md');

  RequireText(lText, 'TAccessibilityManager.Install(Application)', 'README');
  RequireText(lText, 'TAccessibilityManager.Install(Form)', 'README');
  RequireText(lText, 'all current `Screen.Forms`', 'README');
  RequireText(lText, 'future active forms', 'README');
  RequireText(lText, 'BasicVclControls', 'README');
  RequireText(lText, 'Hints', 'README');
  RequireText(lText, 'TStringGridCells', 'README');
  RequireText(lText, 'TAdvStringGridCells', 'README');
  RequireText(lText, 'Known limits', 'README');
  RequireText(lText, 'MaxLogicFoundation', 'README');
  RequireText(lText, 'does not depend on this framework', 'README');
  RequireText(lText, 'old overlay/static-text approach', 'README');
  RequireText(lText, 'TMS', 'README');
  RequireText(lText, 'TAccessibilityTmsAdvStringGridAdapters.CreateRegistry', 'README');
  RequireText(lText, 'Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry)', 'README');
  RequireText(lText, 'Use the direct provider builder only for diagnostics', 'README');
end;

procedure TAccessibilityDocumentationTests.UiaProbeDocumentationListsRunnableScenarios;
var
  lText: string;
begin
  lText := ReadRepoText('docs\uia-probe.md');

  RequireText(lText, 'scripts\run-uia-probe.ps1 -Scenario All', 'UIA probe documentation');
  RequireText(lText, 'BasicVclControls', 'UIA probe documentation');
  RequireText(lText, 'Hints', 'UIA probe documentation');
  RequireText(lText, 'TStringGridCells', 'UIA probe documentation');
  RequireText(lText, 'TAdvStringGridCells', 'UIA probe documentation');
  RequireText(lText, 'UIA_PROBE_OK', 'UIA probe documentation');
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityDocumentationTests);

end.
