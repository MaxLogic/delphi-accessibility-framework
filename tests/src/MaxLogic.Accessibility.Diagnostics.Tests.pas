unit MaxLogic.Accessibility.Diagnostics.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Diagnostics')]
  TAccessibilityDiagnosticsTests = class
  public
    [Test]
    procedure EnabledDiagnosticsAppendTimestampedLinesToConfiguredLog;
  end;

implementation

uses
  System.IOUtils, System.SysUtils, Winapi.Windows,
  MaxLogic.Accessibility.Diagnostics;

procedure TAccessibilityDiagnosticsTests.EnabledDiagnosticsAppendTimestampedLinesToConfiguredLog;
var
  lLogFile: string;
  lLogText: string;
begin
  lLogFile := TPath.Combine(TPath.GetTempPath, Format('maxlogic-a11y-diagnostics-%d.log', [GetTickCount]));
  try
    TAccessibilityDiagnostics.Configure(lLogFile);
    TAccessibilityDiagnostics.Log('diagnostic probe message');

    Assert.IsTrue(TFile.Exists(lLogFile), 'Diagnostics did not create a log file.');
    lLogText := TFile.ReadAllText(lLogFile, TEncoding.UTF8);
    Assert.Contains(lLogText, 'diagnostic probe message');
    Assert.Contains(lLogText, 'T');
  finally
    TAccessibilityDiagnostics.Disable;
    TFile.Delete(lLogFile);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityDiagnosticsTests);

end.
