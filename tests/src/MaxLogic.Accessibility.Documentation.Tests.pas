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
    [Category('AgentBridgeDocumentation')]
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
    [Category('AgentBridgeDocumentation')]
    procedure AgentBridgeDocumentationSeparatesAccessibilityControlAndAgentModes;
    [Test]
    [Category('AgentBridgeDocumentation')]
    procedure AgentBridgeDocumentationDefinesSafeControlWorkflow;
    [Test]
    [Category('AgentBridgeDocumentation')]
    procedure AgentBridgeDocumentationMakesBackgroundCommandModeDefault;
    [Test]
    [Category('AgentBridgeDocumentation')]
    procedure DemoProvidesAgentControlModalScenario;
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
  RequireText(lText, '"cmd":"control.resolve"', 'agent bridge documentation');
  RequireText(lText, 'mutationSemantics', 'agent bridge documentation');
  RequireText(lText, 'raw-property-assignment', 'agent bridge documentation');
  RequireText(lText, 'userInputEventsGenerated', 'agent bridge documentation');
  RequireText(lText, 'mayBlockSynchronously', 'agent bridge documentation');
  RequireText(lText, 'recommendedFallback', 'agent bridge documentation');
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
  RequireText(lText, 'Read-only generic UIA/Win32 inspection may continue', 'agent bridge documentation');
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
  RequireText(lSkillText, 'Foreground Input Mode', 'desktop-control skill');
  RequireText(lSkillText, 'Background Command Mode', 'desktop-control skill');
  RequireText(lSkillText, 'screenshot-window', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-window-info', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-controls-info', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-batch', 'desktop-control skill');
  RequireText(lSkillText, 'Prefer `bridge-form-map` over `uia-map`', 'desktop-control skill');
  RequireText(lSkillText, 'Do not mention machine-local evidence stores', 'desktop-control skill');
  RejectText(lSkillText, 'Shadow Journal', 'desktop-control skill');
end;

procedure TAccessibilityDocumentationTests.AgentBridgeDocumentationDefinesSafeControlWorkflow;
var
  lBridgeText: string;
  lChecklistText: string;
  lSkillText: string;
begin
  lBridgeText := ReadRepoText('docs\agent-bridge.md');
  lChecklistText := ReadRepoText('docs\agent-control-checklist.md');
  lSkillText := ReadRepoText('agent-skills\windows-desktop-control\SKILL.md');

  RequireText(lSkillText, 'Bridge control is not an NVDA test', 'desktop-control skill');
  RequireText(lSkillText, '`foreground-session start` plays the takeover announcement and includes the ' +
    'required three-second safety delay', 'desktop-control skill');
  RequireText(lSkillText, 'Activation failure is a hard stop', 'desktop-control skill');
  RequireText(lSkillText, 'Treat refs and geometry as expired', 'desktop-control skill');
  RequireText(lSkillText, '`control.setText` is raw property assignment', 'desktop-control skill');
  RequireText(lSkillText, 'Do not invoke modal-opening controls through synchronous legacy `control.click`',
    'desktop-control skill');
  RequireText(lSkillText, '`foreground-session`', 'desktop-control skill');
  RequireText(lSkillText, 'bounded best-effort stopping rule', 'desktop-control skill');
  RequireText(lBridgeText, 'Bridge evidence is not NVDA evidence', 'agent bridge documentation');
  RequireText(lBridgeText, 'refs and geometry expire', 'agent bridge documentation');
  RequireText(lBridgeText, 'modal opener', 'agent bridge documentation');
  RequireText(lChecklistText, 'Bridge-only agent control', 'agent-control checklist');
  RequireText(lChecklistText, 'Slow-form wait', 'agent-control checklist');
  RequireText(lChecklistText, 'MDI activation', 'agent-control checklist');
  RequireText(lChecklistText, 'Modal discovery', 'agent-control checklist');
  RequireText(lChecklistText, 'Guarded mouse and keyboard input', 'agent-control checklist');
  RequireText(lChecklistText, 'Lease expiry and watchdog release', 'agent-control checklist');
  RequireText(lChecklistText, 'Clean application shutdown', 'agent-control checklist');
end;

procedure TAccessibilityDocumentationTests.AgentBridgeDocumentationMakesBackgroundCommandModeDefault;
var
  lBridgeText: string;
  lChangelogText: string;
  lChecklistText: string;
  lOpenAiText: string;
  lReadmeText: string;
  lSkillText: string;
begin
  lBridgeText := ReadRepoText('docs\agent-bridge.md');
  lChangelogText := ReadRepoText('CHANGELOG.md');
  lChecklistText := ReadRepoText('docs\agent-control-checklist.md');
  lOpenAiText := ReadRepoText('agent-skills\windows-desktop-control\agents\openai.yaml');
  lReadmeText := ReadRepoText('README.md');
  lSkillText := ReadRepoText('agent-skills\windows-desktop-control\SKILL.md');

  RequireText(lSkillText, '## Choose the control mode', 'desktop-control skill');
  RequireText(lSkillText, 'Routine smoke/regression workflow in a bridge-enabled app',
    'desktop-control skill');
  RequireText(lSkillText, 'Inspect, populate, select, invoke controls or named actions/menu commands, ' +
    'open/dismiss modal, verify state',
    'desktop-control skill');
  RequireText(lSkillText, 'Prove actual pointer, key, accelerator, menu, IME, drag/drop, capture, or ' +
    'screen-reader behavior', 'desktop-control skill');
  RequireText(lSkillText, 'No bridge and no reliable background semantic API', 'desktop-control skill');
  RequireText(lSkillText, 'Background Command Mode is pseudo-headless', 'desktop-control skill');
  RequireText(lSkillText, 'Default to **Background Command Mode** for routine testing',
    'desktop-control skill');
  RequireText(lSkillText, 'bridge-invoke', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-set-text', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-set-checked', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-select', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-focus', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-tab', 'desktop-control skill');
  RequireText(lSkillText, 'bridge-operation-status', 'desktop-control skill');
  RequireText(lSkillText, '`--async`', 'desktop-control skill');
  RequireText(lSkillText, 'operationId', 'desktop-control skill');
  RequireText(lSkillText, 'wait-form', 'desktop-control skill');
  RequireText(lSkillText, '--form-hwnd', 'desktop-control skill');
  RequireText(lSkillText, 'never silently falls back to Foreground Input Mode', 'desktop-control skill');
  RequireText(lSkillText, 'after starting an announced `foreground-session` lease',
    'desktop-control skill');
  RequireText(lSkillText, 'capabilities needed by the selected target shape',
    'desktop-control skill');
  RequireText(lSkillText, '`snapshot-refs-v2` for `--ref`', 'desktop-control skill');
  RequireText(lSkillText, '`atomic-control-targets` for `--form-name`/`--form-hwnd`',
    'desktop-control skill');
  RequireText(lSkillText, 'Every activation, mouse, keyboard, and semantic OS-input command requires ' +
    'the valid lease.', 'desktop-control skill');
  RequireText(lSkillText, 'Background Command Mode does not activate the target, move the pointer, ' +
    'synthesize mouse or keyboard input, or announce takeover.', 'desktop-control skill');
  RequireText(lSkillText, 'actual mouse, keyboard, accelerator, menu, IME, drag/drop, capture, or ' +
    'screen-reader behavior', 'desktop-control skill');
  RequireText(lSkillText, 'Command-mode evidence proves application-semantic state, not real input.',
    'desktop-control skill');
  RequireText(lSkillText, 'Foreground-input evidence proves OS mouse/keyboard behavior, not ' +
    'accessibility output.', 'desktop-control skill');
  RequireText(lSkillText, 'External UIA behavior requires an external UIA probe.',
    'desktop-control skill');
  RequireText(lSkillText, 'NVDA speech requires a live NVDA pass.', 'desktop-control skill');
  RejectText(lSkillText, 'Foreground Drive Mode', 'desktop-control skill');
  RejectText(lSkillText, 'Background Drive Mode', 'desktop-control skill');
  RejectText(lSkillText, '@a1', 'desktop-control skill');
  Assert.IsTrue(Pos('## Choose the control mode', lSkillText) < Pos('## Helper Script', lSkillText),
    'The two-mode decision must precede helper details.');

  RequireText(lOpenAiText, 'Background Command Mode by default', 'desktop-control OpenAI prompt');
  RequireText(lOpenAiText, 'Foreground Input Mode only', 'desktop-control OpenAI prompt');
  RejectText(lOpenAiText, 'announce takeover, inspect the target app', 'desktop-control OpenAI prompt');

  RequireText(lBridgeText, 'background-command-mode', 'agent bridge documentation');
  RequireText(lBridgeText, 'snapshot-refs-v2', 'agent bridge documentation');
  RequireText(lBridgeText, 'atomic-control-targets', 'agent bridge documentation');
  RequireText(lBridgeText, 'intentional protocol-version-2 compatibility breaks',
    'agent bridge documentation');
  RequireText(lBridgeText, 'protocol-v2 refs, atomic targets, and operation-status Boolean fields use ' +
    'strict JSON types', 'agent bridge documentation');
  RequireText(lBridgeText, 'default-wait dismiss invocation already consumes its terminal operation',
    'agent bridge documentation');
  RequireText(lBridgeText, 'consume only the asynchronous opener operation with ' +
    '`bridge-operation-status`', 'agent bridge documentation');
  RequireText(lBridgeText, 'Raw `bridge-request` remains the deliberate escape hatch',
    'agent bridge documentation');
  RequireText(lBridgeText, '"cmd":"control.invoke"', 'agent bridge documentation');
  RequireText(lBridgeText, '"cmd":"control.setChecked"', 'agent bridge documentation');
  RequireText(lBridgeText, '"cmd":"control.select"', 'agent bridge documentation');
  RequireText(lBridgeText, '"cmd":"operation.status"', 'agent bridge documentation');
  RejectText(lBridgeText, '"@a', 'agent bridge documentation');

  RequireText(lChecklistText, '## Background Command Mode', 'agent-control checklist');
  RequireText(lChecklistText, '## Foreground Input Mode', 'agent-control checklist');
  RequireText(lChecklistText, 'Command-mode evidence does not prove external UIA or NVDA behavior.',
    'agent-control checklist');
  RequireText(lChecklistText, '`bridge-invoke --async`', 'agent-control checklist');
  RequireText(lChecklistText, '`wait-form`', 'agent-control checklist');
  RequireText(lChecklistText, 'The default-wait dismiss invocation consumes its own terminal ' +
    'operation', 'agent-control checklist');
  RequireText(lChecklistText, 'consume only the asynchronous opener with ' +
    '`bridge-operation-status`', 'agent-control checklist');
  RequireText(lChecklistText, 'require the lease for every activation and input command',
    'agent-control checklist');
  RequireText(lChecklistText, 'Independent user activity is INCONCLUSIVE',
    'agent-control checklist');
  Assert.IsTrue(Pos('## Background Command Mode', lChecklistText) <
    Pos('## Foreground Input Mode', lChecklistText), 'The background checklist must come first.');

  RequireText(lReadmeText, 'Background Command Mode is the default', 'README');
  RequireText(lReadmeText, 'bridge-invoke', 'README');
  RequireText(lReadmeText, 'Foreground Input Mode', 'README');
  RequireText(lReadmeText, 'Typed helpers fail closed when required protocol or capabilities are ' +
    'unavailable and never escalate to Foreground Input Mode.', 'README');
  RequireText(lReadmeText, 'not human-equivalent input, the external UIA boundary, or NVDA output',
    'README');
  RejectText(lReadmeText, '`@a1`', 'README');
  RequireText(lChangelogText, 'documentation now defaults routine bridge-enabled testing to ' +
    'Background Command Mode', 'changelog');
  RequireText(lChangelogText, 'Generationless snapshot refs and lease-less foreground commands are ' +
    'no longer accepted', 'changelog');
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
  RequireText(lText, 'TAccessibilityTmsAdvStringGridAdapters.RegisterAdapters', 'NVDA checklist');
  RejectText(lText, 'TAccessibilityTmsAdvStringGridAdapters.CreateRegistry', 'NVDA checklist');
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

procedure TAccessibilityDocumentationTests.DemoProvidesAgentControlModalScenario;
var
  lDfmText: string;
  lPasText: string;
begin
  lDfmText := ReadRepoText('demos\AccessibilityDemoMainForm.dfm');
  lPasText := ReadRepoText('demos\AccessibilityDemoMainForm.pas');

  RequireText(lDfmText, 'object btnShowModal: TButton', 'demo modal scenario');
  RequireText(lDfmText, 'Caption = ''Modal dialog''', 'demo modal scenario');
  RequireText(lDfmText, 'OnClick = btnShowModalClick', 'demo modal scenario');
  RequireText(lPasText, 'procedure TAccessibilityDemoMainForm.btnShowModalClick(aSender: TObject);',
    'demo modal scenario');
  RequireText(lPasText, 'GC(lDialog, CreateMessageDialog(rsAgentControlModalMessage, mtInformation, [mbOK]), g);',
    'demo modal scenario');
  RequireText(lPasText, 'lDialog.ShowModal;',
    'demo modal scenario');
  RejectText(lPasText, 'MessageDlg(rsAgentControlModalMessage, mtInformation, [mbOK], 0);',
    'demo modal scenario');
end;

procedure TAccessibilityDocumentationTests.ReadmeDocumentsInstallAndSupportedScenarios;
var
  lText: string;
begin
  lText := ReadRepoText('README.md');

  RequireText(lText, '## Overview', 'README');
  RequireText(lText, 'two complementary capabilities', 'README');
  RequireText(lText, '### AI agent application control', 'README');
  RequireText(lText, '### Screen-reader accessibility', 'README');
  Assert.IsTrue(Pos('### AI agent application control', lText) <
    Pos('### Screen-reader accessibility', lText),
    'AI agent application control must be presented before screen-reader accessibility.');
  Assert.IsTrue(Pos('### Screen-reader accessibility', lText) < Pos('## Screen-reader installation', lText),
    'The dual-purpose overview must precede installation details.');
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
  RequireText(lText, 'Microsoft UI Automation provider fragments attached to forms and returned through ' +
    '`WM_GETOBJECT`', 'README');
  RejectText(lText, 'old overlay/static-text approach', 'README');
  RejectText(lText, 'The older `control.click`', 'README');
  RejectText(lText, 'large legacy application', 'README');
  RequireText(lText, 'TMS', 'README');
  RequireText(lText, 'TAccessibilityTmsAdvStringGridAdapters.RegisterAdapters', 'README');
  RequireText(lText, 'TAccessibilityAdapterRegistry.Compose', 'README');
  RejectText(lText, 'TAccessibilityTmsAdvStringGridAdapters.CreateRegistry', 'README');
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
