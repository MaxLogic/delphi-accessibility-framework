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
  MaxLogic.Accessibility.Diagnostics in '..\src\MaxLogic.Accessibility.Diagnostics.pas';

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
  Application.Run;
end.
