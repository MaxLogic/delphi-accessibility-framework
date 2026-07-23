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
    procedure ReleaseProjectsUseCompilerCompatibleDebugInformationSetting;
    [Test]
    procedure DemoContainsWrappedAndUnwrappedMemoTabs;
    [Test]
    procedure DemoDocumentsAndWiresAgentBridgeDiagnosticSwitch;
    [Test]
    procedure DemoFileDiagnosticsAreOptIn;
    [Test]
    procedure DemoBuildIsReproducibleForExactCandidateCertification;
    [Test]
    procedure AgentBridgeDocumentationSeparatesAccessibilityControlAndAgentModes;
    [Test]
    procedure DemoShutdownDisarmsAccessibilityHooksAndTimers;
    [Test]
    procedure TmsAdvStringGridSelectionArrayAvoidsPerElementSafeArrayPutElement;
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

  RequireText(lDprText, 'Application.Run;', 'demo DPR shutdown');
  RequireText(lDprText, 'TAccessibilityAgentBridgePipeServer.Stop;', 'demo DPR shutdown');
  RequireText(lDprText, 'SetDemoAccessibilityFrameworkEnabled(False);', 'demo DPR shutdown');
  RequireText(lDfmText, 'OnDestroy = FormDestroy', 'demo DFM shutdown');
  RequireText(lPasText, 'procedure TAccessibilityDemoMainForm.FormDestroy(aSender: TObject);' + sLineBreak +
    'begin' + sLineBreak + '  BalloonHideTimer.Enabled := False;' + sLineBreak +
    '  DynamicContentTimer.Enabled := False;' + sLineBreak + '  BalloonHint.HideHint;' + sLineBreak + 'end;',
    'demo form shutdown');
end;

procedure TAccessibilityDocumentationTests.DemoBuildIsReproducibleForExactCandidateCertification;
var
  lProjectText: string;
begin
  lProjectText := ReadRepoText('demos\AccessibilityComplexDemo.dproj');

  RequireText(lProjectText, '<VerInfo_AutoIncVersion>false</VerInfo_AutoIncVersion>',
    'demo exact-candidate build');
end;

procedure TAccessibilityDocumentationTests.TmsAdvStringGridSelectionArrayAvoidsPerElementSafeArrayPutElement;
var
  lText: string;
begin
  lText := ReadRepoText('src\MaxLogic.Accessibility.TmsAdvStringGridAdapters.pas');

  RequireText(lText, 'SafeArrayAccessData', 'TMS AdvStringGrid selection SAFEARRAY hot path');
  RejectText(lText, 'SafeArrayPutElement', 'TMS AdvStringGrid selection SAFEARRAY hot path');
end;

procedure TAccessibilityDocumentationTests.DemoDocumentsAndWiresAgentBridgeDiagnosticSwitch;
var
  lDocText: string;
  lDprText: string;
begin
  lDocText := ReadRepoText('docs\agent-bridge.md');
  lDprText := ReadRepoText('demos\AccessibilityComplexDemo.dpr');

  RequireText(lDprText, '--a11y-agent-bridge', 'demo DPR bridge switch');
  RequireText(lDprText, '--a11y-agent-bridge-pipe=', 'demo DPR bridge switch');
  RequireText(lDprText, '--a11y-agent-bridge-mutations', 'demo DPR bridge switch');
  RequireText(lDprText, 'TAccessibilityAgentBridgePipeServer.Start', 'demo DPR bridge switch');
  RequireText(lDprText, 'TAccessibilityAgentBridgePipeServer.Stop', 'demo DPR bridge switch');
  RequireText(lDprText, 'TAccessibilityAgentBridge.SetMutationEnabled(True)', 'demo DPR bridge switch');
  RequireText(lDocText, 'AccessibilityComplexDemo.exe --a11y-agent-bridge', 'agent bridge demo docs');
  RequireText(lDocText, '--a11y-agent-bridge-pipe=MaxLogicAccessibilityDemo', 'agent bridge demo docs');
  RequireText(lDocText, '--a11y-agent-bridge-mutations', 'agent bridge demo docs');
end;

procedure TAccessibilityDocumentationTests.DemoFileDiagnosticsAreOptIn;
var
  lDocText: string;
  lDprText: string;
begin
  lDocText := ReadRepoText('docs\agent-bridge.md');
  lDprText := ReadRepoText('demos\AccessibilityComplexDemo.dpr');

  RequireText(lDprText, 'cDemoDiagnosticsSwitch = ''--a11y-diagnostics'';', 'demo diagnostics switch');
  RequireText(lDprText, 'if HasCommandLineSwitch(cDemoDiagnosticsSwitch) then', 'demo diagnostics switch');
  RequireText(lDprText, 'TAccessibilityDiagnostics.Disable;', 'demo diagnostics shutdown');
  RequireText(lDocText, 'AccessibilityComplexDemo.exe --a11y-diagnostics', 'demo diagnostics documentation');
  RequireText(lDocText, '8 MiB', 'demo diagnostics documentation');
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
  RequireText(lText, 'sequential request/response batch', 'agent bridge documentation');
  RequireText(lText, 'Start` and `Stop` are idempotent', 'agent bridge documentation');
  RequireText(lText, '"cmd":"hello"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"window.info"', 'agent bridge documentation');
  RequireText(lText, 'clientScreenRect', 'agent bridge documentation');
  RequireText(lText, 'pixelsPerInch', 'agent bridge documentation');
  RequireText(lText, '"cmd":"form.map"', 'agent bridge documentation');
  RequireText(lText, '"detail":"geometry"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"controls.info"', 'agent bridge documentation');
  RequireText(lText, 'hundreds or thousands of client/provider boundary calls', 'agent bridge documentation');
  RequireText(lText, 'CacheRequest', 'agent bridge documentation');
  RequireText(lText, '"cmd":"hitTest"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.focus"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.click"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.setText"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"control.typeText"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"keyboard.tab"', 'agent bridge documentation');
  RequireText(lText, '"cmd":"diagnostics.providerHotspots"', 'agent bridge documentation');
  RequireText(lText, 'snapshotInvalidated', 'agent bridge documentation');
  RequireText(lText, 'VCL main thread', 'agent bridge documentation');
  RequireText(lText, 'should continue with generic UIA/Win32 control', 'agent bridge documentation');
end;

procedure TAccessibilityDocumentationTests.AgentBridgeDocumentationSeparatesAccessibilityControlAndAgentModes;
var
  lBridgeText: string;
  lSkillText: string;
begin
  lBridgeText := ReadRepoText('docs\agent-bridge.md');
  lSkillText := ReadRepoText('agent-skills\windows-desktop-control\SKILL.md');

  RequireText(lBridgeText, 'separate purposes', 'agent bridge documentation');
  RequireText(lBridgeText, 'screen-reader accessibility', 'agent bridge documentation');
  RequireText(lBridgeText, 'application control bridge', 'agent bridge documentation');
  RequireText(lBridgeText, 'agent desktop-control skill', 'agent bridge documentation');
  RequireText(lBridgeText, 'Foreground and background are automation modes', 'agent bridge documentation');
  RequireText(lBridgeText, 'Screenshots belong to the desktop-control helper first', 'agent bridge documentation');
  RequireText(lBridgeText, 'window.info', 'agent bridge documentation');
  RequireText(lSkillText, 'Foreground Drive Mode', 'desktop-control skill');
  RequireText(lSkillText, 'Background Drive Mode', 'desktop-control skill');
  RequireText(lSkillText, 'screenshot-window', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-window-info', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-controls-info', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-batch', 'desktop-control skill');
  RequireText(lSkillText, 'Prefer `bridge-form-map` over `uia-map`', 'desktop-control skill');
  RequireText(lSkillText, 'Do not mention machine-local evidence stores', 'desktop-control skill');
  RejectText(lSkillText, 'Shadow Journal', 'desktop-control skill');
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
  RequireText(lText, 'Next runtime sync step', 'NVDA checklist');
  RequireText(lText, 'add an explicitly labeled edit', 'NVDA checklist');
  RequireText(lText, 'recreate the `TStringGrid` and form HWNDs', 'NVDA checklist');
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

procedure TAccessibilityDocumentationTests.ReleaseProjectsUseCompilerCompatibleDebugInformationSetting;
const
  cNumericSetting = '<DCC_DebugInformation>0</DCC_DebugInformation>';
  cRejectedSetting = '<DCC_DebugInformation>false</DCC_DebugInformation>';
var
  lText: string;
begin
  lText := ReadRepoText('projects\MaxLogicAccessibilityFrameworkSmoke.dproj');
  RequireText(lText, cNumericSetting, 'smoke Release project');
  RejectText(lText, cRejectedSetting, 'smoke Release project');

  lText := ReadRepoText('tests\MaxLogicAccessibilityFramework.Tests.dproj');
  RequireText(lText, cNumericSetting, 'test Release project');
  RejectText(lText, cRejectedSetting, 'test Release project');

  lText := ReadRepoText('demos\AccessibilityComplexDemo.dproj');
  RequireText(lText, cNumericSetting, 'demo Release project');
  RejectText(lText, cRejectedSetting, 'demo Release project');
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
  RequireText(lText, 'native-HWND listbox focus speech routing', 'UIA probe documentation');
  RequireText(lText, 'TStringGridCells', 'UIA probe documentation');
  RequireText(lText, 'TAdvStringGridCells', 'UIA probe documentation');
  RequireText(lText, 'UIA_PROBE_OK', 'UIA probe documentation');
  RequireText(lText, 'CacheRequest', 'UIA probe documentation');
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityDocumentationTests);

end.
