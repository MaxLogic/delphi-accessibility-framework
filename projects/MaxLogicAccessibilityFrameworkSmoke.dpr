program MaxLogicAccessibilityFrameworkSmoke;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MaxLogic.Accessibility.Framework in '..\src\MaxLogic.Accessibility.Framework.pas';

begin
  try
    Writeln(cAccessibilityFrameworkName);
  except
    on lException: Exception do
    begin
      Writeln(lException.ClassName, ': ', lException.Message);
      System.ExitCode := 1;
    end;
  end;
end.
