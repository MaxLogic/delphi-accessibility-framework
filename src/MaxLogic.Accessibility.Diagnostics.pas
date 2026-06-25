unit MaxLogic.Accessibility.Diagnostics;

interface

type
  TAccessibilityDiagnostics = record
  public
    class procedure Configure(const aLogFile: string); static;
    class procedure Disable; static;
    class function Enabled: Boolean; static;
    class procedure Log(const aMessage: string); static;
  end;

implementation

uses
  System.IOUtils, System.SysUtils, Winapi.Windows;

var
  gDiagnosticsLock: TObject;
  gLogFile: string;

class procedure TAccessibilityDiagnostics.Configure(const aLogFile: string);
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gLogFile := aLogFile;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.Disable;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gLogFile := '';
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnostics.Enabled: Boolean;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    Result := gLogFile <> '';
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.Log(const aMessage: string);
var
  lDirectory: string;
  lLine: string;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    if gLogFile = '' then
    begin
      Exit;
    end;

    lDirectory := ExtractFilePath(gLogFile);
    if lDirectory <> '' then
    begin
      ForceDirectories(lDirectory);
    end;

    lLine := Format('%s pid=%d tid=%d %s%s',
      [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now), GetCurrentProcessId, GetCurrentThreadId, aMessage,
      sLineBreak]);
    TFile.AppendAllText(gLogFile, lLine, TEncoding.UTF8);
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

initialization
  gDiagnosticsLock := TObject.Create;

finalization
  gDiagnosticsLock.Free;

end.
