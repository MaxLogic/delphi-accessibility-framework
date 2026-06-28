program AccessibilityComplexDemo;

{$R *.res}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IF DEFINED(madExcept) AND DEFINED(DEBUG)}
  Winapi.Windows,
  {$IFEND}
  Vcl.Forms,
  {$IF DEFINED(madExcept) AND DEFINED(DEBUG)}
  madExcept, madLinkDisAsm, madListHardware, madListModules, madListProcesses,
  MaxLogic.MadExcept.AiRunner in '..\lib\MaxLogicFoundation\MaxLogic.MadExcept.AiRunner.pas',
  {$IFEND}
  AccessibilityDemoMainForm in 'AccessibilityDemoMainForm.pas' {AccessibilityDemoMainForm},
  MaxLogic.Accessibility.AgentBridge in '..\src\MaxLogic.Accessibility.AgentBridge.pas',
  MaxLogic.Accessibility.AgentBridge.PipeServer in '..\src\MaxLogic.Accessibility.AgentBridge.PipeServer.pas',
  MaxLogic.Accessibility.Diagnostics in '..\src\MaxLogic.Accessibility.Diagnostics.pas';

const
  cDemoAgentBridgeMutationsSwitch = '--a11y-agent-bridge-mutations';
  cDemoAgentBridgePipePrefix = '--a11y-agent-bridge-pipe=';
  cDemoAgentBridgeSwitch = '--a11y-agent-bridge';

{$IF DEFINED(madExcept) AND DEFINED(DEBUG)}
procedure RunMadExceptAiProbe;
var
  lBugReport: string;
  lExceptionIntf: IMEException;
begin
  try
    raise Exception.Create('MAD_EXCEPT_AI_PROBE');
  except
    on lException: Exception do
    begin
      lExceptionIntf := madExcept.NewException(etNormal, lException, ExceptAddr, False,
        GetCurrentThreadId, 0, 0, nil, MESettings, esManual);
      lBugReport := lExceptionIntf.GetBugReport(True);
      MaxLogic.MadExcept.AiRunner.SaveAiBugReportAndTerminate(lBugReport);
    end;
  end;
end;
{$IFEND}

function HasCommandLineSwitch(const aSwitch: string): Boolean;
var
  i: Integer;
begin
  for i := 1 to ParamCount do
  begin
    if SameText(ParamStr(i), aSwitch) then
    begin
      Exit(True);
    end;
  end;

  Result := False;
end;

function DemoAgentBridgePipeName: string;
var
  i: Integer;
  lParam: string;
begin
  for i := 1 to ParamCount do
  begin
    lParam := ParamStr(i);
    if SameText(Copy(lParam, 1, Length(cDemoAgentBridgePipePrefix)), cDemoAgentBridgePipePrefix) then
    begin
      Exit(Copy(lParam, Succ(Length(cDemoAgentBridgePipePrefix)), MaxInt));
    end;
  end;

  Result := '';
end;

procedure StartDemoAgentBridgeIfRequested;
var
  lPipeName: string;
begin
  if not HasCommandLineSwitch(cDemoAgentBridgeSwitch) then
  begin
    Exit;
  end;

  lPipeName := DemoAgentBridgePipeName;
  TAccessibilityAgentBridgePipeServer.Start(lPipeName);
  TAccessibilityDiagnostics.Log('Agent bridge pipe server started: ' + TAccessibilityAgentBridgePipeServer.PipeName);

  if HasCommandLineSwitch(cDemoAgentBridgeMutationsSwitch) then
  begin
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    TAccessibilityDiagnostics.Log('Agent bridge mutations enabled');
  end;
end;

procedure StopDemoAgentBridge;
begin
  TAccessibilityAgentBridge.SetMutationEnabled(False);
  TAccessibilityAgentBridgePipeServer.Stop;
end;

begin
  {$IF DEFINED(madExcept) AND DEFINED(DEBUG)}
  MaxLogic.MadExcept.AiRunner.ConfigureFromEnvironment;
  if (ParamCount = 1) and SameText(ParamStr(1), '--madexcept-ai-probe') then
  begin
    RunMadExceptAiProbe;
  end;
  {$IFEND}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Accessibility Framework Demo';
  TAccessibilityDiagnostics.Configure(ChangeFileExt(Application.ExeName, '.a11y.log'));
  TAccessibilityDiagnostics.Log('AccessibilityComplexDemo starting');
  Application.CreateForm(TAccessibilityDemoMainForm, AccessibilityDemoMain);
  SetDemoAccessibilityFrameworkEnabled(True);
  StartDemoAgentBridgeIfRequested;
  try
    Application.Run;
  finally
    StopDemoAgentBridge;
    SetDemoAccessibilityFrameworkEnabled(False);
  end;
end.
