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
    procedure AgentBridgeDocumentationDescribesContract;
    [Test]
    procedure ReadmeDocumentsInstallAndSupportedScenarios;
    [Test]
    procedure DemoContainsWrappedAndUnwrappedMemoTabs;
    [Test]
    procedure DemoShutdownDisarmsAccessibilityHooksAndTimers;
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

procedure RejectText(const aText: string; const aRejected: string; const aContext: string);
begin
  Assert.IsFalse(Pos(aRejected, aText) > 0, Format('%s must not contain "%s".', [aContext, aRejected]));
end;

procedure TAccessibilityDocumentationTests.DemoShutdownDisarmsAccessibilityHooksAndTimers;
var
  lDfmText: string;
  lDprText: string;
  lPasText: string;
begin
  lDfmText := ReadRepoText('demos\AccessibilityDemoMainForm.dfm');
  lDprText := ReadRepoText('demos\AccessibilityComplexDemo.dpr');
  lPasText := ReadRepoText('demos\AccessibilityDemoMainForm.pas');

  RequireText(lDprText, 'try' + sLineBreak + '    Application.Run;' + sLineBreak + '  finally' + sLineBreak +
    '    SetDemoAccessibilityFrameworkEnabled(False);' + sLineBreak + '  end;', 'demo DPR shutdown');
  RequireText(lDfmText, 'OnDestroy = FormDestroy', 'demo DFM shutdown');
  RequireText(lPasText, 'procedure TAccessibilityDemoMainForm.FormDestroy(aSender: TObject);' + sLineBreak +
    'begin' + sLineBreak + '  BalloonHideTimer.Enabled := False;' + sLineBreak + '  BalloonHint.HideHint;' +
    sLineBreak + 'end;', 'demo form shutdown');
end;

procedure TAccessibilityDocumentationTests.AgentBridgeDocumentationDescribesContract;
var
  lReadmeText: string;
  lText: string;
begin
  lReadmeText := ReadRepoText('README.md');
  lText := ReadRepoText('docs\agent-bridge.md');

  RequireText(lReadmeText, 'MaxLogic.Accessibility.AgentBridge', 'README');
  RequireText(lReadmeText, 'MaxLogic.Accessibility.AgentBridge.PipeServer', 'README');
  RequireText(lReadmeText, 'TAccessibilityAgentBridge.Execute', 'README');
  RequireText(lReadmeText, 'TAccessibilityAgentBridgePipeServer.Start', 'README');
  RequireText(lReadmeText, 'control.click', 'README');
  RequireText(lReadmeText, 'keyboard.tab', 'README');
  RequireText(lText, 'TAccessibilityAgentBridgePipeServer.Start', 'agent bridge documentation');
  RequireText(lText, 'one UTF-8 JSON object per line', 'agent bridge documentation');
  RequireText(lText, 'Start` and `Stop` are idempotent', 'agent bridge documentation');
  RequireText(lText, '"cmd":"hello"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"form.map"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"hitTest"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.focus"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.click"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.setText"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.typeText"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"keyboard.tab"', 'agent bridge documentation');
  RequireText(lText, 'snapshotInvalidated', 'agent bridge documentation');
  RequireText(lText, 'VCL main thread', 'agent bridge documentation');
  RequireText(lText, 'should continue with generic UIA/Win32 control', 'agent bridge documentation');
end;

procedure TAccessibilityDocumentationTests.NvdaChecklistDocumentsExpectedSpeech;
var
  lText: string;
begin
  lText := ReadRepoText('docs\nvda-checklist.md');

  RequireText(lText, 'TLabel', 'NVDA checklist');
  RequireText(lText, 'TButton', 'NVDA checklist');
  RequireText(lText, 'TSpeedButton', 'NVDA checklist');
  RequireText(lText, 'TComboBox', 'NVDA checklist');
  RequireText(lText, 'TCheckBox', 'NVDA checklist');
  RequireText(lText, 'TRadioButton', 'NVDA checklist');
  RequireText(lText, 'TGroupBox', 'NVDA checklist');
  RequireText(lText, 'TRadioGroup', 'NVDA checklist');
  RequireText(lText, 'TPageControl', 'NVDA checklist');
  RequireText(lText, 'TTabSheet', 'NVDA checklist');
  RequireText(lText, 'TToolBar', 'NVDA checklist');
  RequireText(lText, 'TToolButton', 'NVDA checklist');
  RequireText(lText, 'framework-injected English state', 'NVDA checklist');
  RequireText(lText, 'TPanel', 'NVDA checklist');
  RequireText(lText, 'visible hint', 'NVDA checklist');
  RequireText(lText, 'balloon hint', 'NVDA checklist');
  RequireText(lText, 'TStringGrid', 'NVDA checklist');
  RequireText(lText, 'TAdvStringGrid', 'NVDA checklist');
  RequireText(lText, 'TAccessibilityTmsAdvStringGridAdapters.CreateRegistry', 'NVDA checklist');
  RequireText(lText, 'cell text only', 'NVDA checklist');
  RequireText(lText, 'TAccessibilityScreenReaderDetector', 'NVDA checklist');
  RequireText(lText, 'SPI_GETSCREENREADER', 'NVDA checklist');
  RequireText(lText, 'UiaClientsAreListening', 'NVDA checklist');
  RequireText(lText, 'not a guaranteed screen-reader identity', 'NVDA checklist');
end;

procedure TAccessibilityDocumentationTests.DemoContainsWrappedAndUnwrappedMemoTabs;
var
  lDfmText: string;
  lPasText: string;
begin
  lDfmText := ReadRepoText('demos\AccessibilityDemoMainForm.dfm');
  lPasText := ReadRepoText('demos\AccessibilityDemoMainForm.pas');

  RequireText(lDfmText, 'Caption = ''Memo no wrap''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Memo wrap''', 'demo DFM');
  RequireText(lDfmText, 'object memoDetailsUnwrapped: TMemo', 'demo DFM');
  RequireText(lDfmText, 'WordWrap = False', 'demo DFM');
  RequireText(lDfmText, 'object memoDetailsWrapped: TMemo', 'demo DFM');
  RequireText(lDfmText, 'WordWrap = True', 'demo DFM');
  RequireText(lPasText, 'memoDetailsUnwrapped: TMemo;', 'demo form class');
  RequireText(lPasText, 'memoDetailsWrapped: TMemo;', 'demo form class');
  RequireText(lDfmText, 'object btnShowRegularHint: TButton', 'demo DFM');
  RequireText(lDfmText, 'object chkAccessibilityEnabled: TCheckBox', 'demo DFM');
  RequireText(lDfmText, 'object btnApplyFilters: TButton', 'demo DFM');
  RequireText(lDfmText, 'object btnClose: TButton', 'demo DFM');
  RequireText(lDfmText, 'object chkIncludeArchived: TCheckBox', 'demo DFM');
  RequireText(lDfmText, 'object grpViewMode: TGroupBox', 'demo DFM');
  RequireText(lDfmText, 'object rbViewCompact: TRadioButton', 'demo DFM');
  RequireText(lDfmText, 'object rbViewDetailed: TRadioButton', 'demo DFM');
  RequireText(lDfmText, 'object radioGroupDensity: TRadioGroup', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Regular Hint''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Accessibility enabled''', 'demo DFM');
  RequireText(lDfmText, 'Checked = True', 'demo DFM');
  RequireText(lDfmText, 'OnClick = chkAccessibilityEnabledClick', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Apply Filters''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Close''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Include archived rows''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''View mode''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Compact''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Detailed''', 'demo DFM');
  RequireText(lDfmText, 'Caption = ''Density''', 'demo DFM');
  RequireText(lDfmText, 'Hint = ''Includes archived rows in the demo grids''', 'demo DFM');
  RequireText(lPasText, 'grpViewMode: TGroupBox;', 'demo form class');
  RequireText(lPasText, 'rbViewCompact: TRadioButton;', 'demo form class');
  RequireText(lPasText, 'rbViewDetailed: TRadioButton;', 'demo form class');
  RequireText(lPasText, 'radioGroupDensity: TRadioGroup;', 'demo form class');
  RequireText(lPasText, 'chkAccessibilityEnabled: TCheckBox;', 'demo form class');
  RequireText(lPasText, 'procedure chkAccessibilityEnabledClick(aSender: TObject);', 'demo form class');
  RequireText(lPasText, 'procedure SetDemoAccessibilityFrameworkEnabled(aEnabled: Boolean);',
    'demo form startup helper');
  RequireText(ReadRepoText('demos\AccessibilityComplexDemo.dpr'), 'SetDemoAccessibilityFrameworkEnabled(True);',
    'demo DPR');
end;

procedure TAccessibilityDocumentationTests.ReadmeDocumentsInstallAndSupportedScenarios;
var
  lText: string;
begin
  lText := ReadRepoText('README.md');

  RequireText(lText, 'TAccessibilityManager.Run(Application)', 'README');
  RequireText(lText, 'TAccessibilityManager.Install(Application)', 'README');
  RequireText(lText, 'TAccessibilityManager.Install(Form)', 'README');
  RequireText(lText, 'TAccessibilityManager.Uninstall', 'README');
  RequireText(lText, 'already owns the `Application.Run` block', 'README');
  RequireText(lText, 'idempotent', 'README');
  RequireText(lText, 'Accessibility enabled', 'README');
  RequireText(lText, 'MaxLogic.Accessibility.ScreenReaders', 'README');
  RequireText(lText, 'TAccessibilityScreenReaderDetector.IsLikelyActive', 'README');
  RequireText(lText, 'SPI_GETSCREENREADER', 'README');
  RequireText(lText, 'UiaClientsAreListening', 'README');
  RequireText(lText, 'not a guaranteed screen-reader identity', 'README');
  RequireText(lText, 'TButton', 'README');
  RequireText(lText, 'TComboBox', 'README');
  RequireText(lText, 'TCheckBox', 'README');
  RequireText(lText, 'TRadioButton', 'README');
  RequireText(lText, 'TGroupBox', 'README');
  RequireText(lText, 'TRadioGroup', 'README');
  RequireText(lText, 'TPageControl', 'README');
  RequireText(lText, 'TTabSheet', 'README');
  RequireText(lText, 'TToolBar', 'README');
  RequireText(lText, 'TToolButton', 'README');
  RequireText(lText, 'MSAA', 'README');
  RequireText(lText, 'MSAA bridge', 'README');
  RejectText(lText, 'MSAA compatibility bridge are deferred', 'README');
  RequireText(lText, 'all current `Screen.Forms`', 'README');
  RequireText(lText, 'future active forms', 'README');
  RequireText(lText, 'BasicVclControls', 'README');
  RequireText(lText, 'Hints', 'README');
  RequireText(lText, 'MemoListStatus', 'README');
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
  RequireText(lText, 'Native Fallback', 'README');
  RequireText(lText, 'TVirtualStringTree', 'README');
end;

procedure TAccessibilityDocumentationTests.UiaProbeDocumentationListsRunnableScenarios;
var
  lText: string;
begin
  lText := ReadRepoText('docs\uia-probe.md');

  RequireText(lText, 'scripts\run-uia-probe.ps1 -Scenario All', 'UIA probe documentation');
  RequireText(lText, 'BasicVclControls', 'UIA probe documentation');
  RequireText(lText, 'TButton', 'UIA probe documentation');
  RequireText(lText, 'TCheckBox', 'UIA probe documentation');
  RequireText(lText, 'Hints', 'UIA probe documentation');
  RequireText(lText, 'MemoListStatus', 'UIA probe documentation');
  RequireText(lText, 'TStringGridCells', 'UIA probe documentation');
  RequireText(lText, 'TAdvStringGridCells', 'UIA probe documentation');
  RequireText(lText, 'UIA_PROBE_OK', 'UIA probe documentation');
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityDocumentationTests);

end.
