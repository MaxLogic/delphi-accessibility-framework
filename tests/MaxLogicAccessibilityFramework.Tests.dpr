program MaxLogicAccessibilityFramework.Tests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  DUnitX.TestRunner,
  MaxLogic.Accessibility.Hints.Tests in 'src\MaxLogic.Accessibility.Hints.Tests.pas',
  MaxLogic.Accessibility.Manager.Tests in 'src\MaxLogic.Accessibility.Manager.Tests.pas',
  MaxLogic.Accessibility.ProviderCore.Tests in 'src\MaxLogic.Accessibility.ProviderCore.Tests.pas',
  MaxLogic.Accessibility.Scanner.Tests in 'src\MaxLogic.Accessibility.Scanner.Tests.pas',
  MaxLogic.Accessibility.Smoke.Tests in 'src\MaxLogic.Accessibility.Smoke.Tests.pas',
  MaxLogic.Accessibility.UIAutomationCore.Tests in 'src\MaxLogic.Accessibility.UIAutomationCore.Tests.pas',
  MaxLogic.Accessibility.VclAdapters.Tests in 'src\MaxLogic.Accessibility.VclAdapters.Tests.pas';

var
  lLogger: ITestLogger;
  lResults: IRunResults;
  lRunner: ITestRunner;

begin
  try
    TDUnitX.CheckCommandLine;

    lRunner := TDUnitX.CreateRunner;
    lRunner.UseRTTI := True;
    lRunner.FailsOnNoAsserts := True;

    lLogger := TDUnitXConsoleLogger.Create(False);
    lRunner.AddLogger(lLogger);

    lResults := lRunner.Execute;
    Writeln(Format('DUNITX_RESULT tests=%d passed=%d failures=%d errors=%d ignored=%d',
      [lResults.TestCount, lResults.PassCount, lResults.FailureCount, lResults.ErrorCount, lResults.IgnoredCount]));

    if (not lResults.AllPassed) or (lResults.IgnoredCount > 0) or (lResults.TestCount <= 0) then
    begin
      System.ExitCode := 1;
    end;
  except
    on lException: Exception do
    begin
      Writeln(lException.ClassName, ': ', lException.Message);
      System.ExitCode := 1;
    end;
  end;
end.
