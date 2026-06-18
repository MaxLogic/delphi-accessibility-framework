unit MaxLogic.Accessibility.Smoke.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Smoke')]
  TAccessibilitySmokeTests = class
  public
    [Test]
    procedure FrameworkNameIsAvailable;
  end;

implementation

uses
  MaxLogic.Accessibility.Framework;

procedure TAccessibilitySmokeTests.FrameworkNameIsAvailable;
begin
  Assert.AreEqual('MaxLogic Delphi Accessibility Framework', cAccessibilityFrameworkName);
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilitySmokeTests);

end.
