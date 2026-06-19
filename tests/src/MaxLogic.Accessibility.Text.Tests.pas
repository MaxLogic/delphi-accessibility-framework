unit MaxLogic.Accessibility.Text.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('TextHelpers')]
  TAccessibilityTextTests = class
  public
    [Test]
    procedure CleanStripsAcceleratorsAndTrimsText;
    [Test]
    procedure IconFontOnlyDetectionRequiresPrivateUseGlyphs;
    [Test]
    procedure SplitHintReturnsCleanShortAndLongParts;
  end;

implementation

uses
  DUnitX.Assert, MaxLogic.Accessibility.Text;

procedure TAccessibilityTextTests.CleanStripsAcceleratorsAndTrimsText;
begin
  Assert.AreEqual('Save & Close', TAccessibilityText.Clean('  &Save && Close  '));
end;

procedure TAccessibilityTextTests.IconFontOnlyDetectionRequiresPrivateUseGlyphs;
begin
  Assert.IsFalse(TAccessibilityText.IsIconFontOnly(''));
  Assert.IsTrue(TAccessibilityText.IsIconFontOnly(' ' + WideChar($E001) + #9));
  Assert.IsFalse(TAccessibilityText.IsIconFontOnly('A' + WideChar($E001)));
end;

procedure TAccessibilityTextTests.SplitHintReturnsCleanShortAndLongParts;
var
  lHelpText: string;
  lName: string;
begin
  TAccessibilityText.SplitHint(' Short &name | Long && help ', lName, lHelpText);
  Assert.AreEqual('Short name', lName);
  Assert.AreEqual('Long & help', lHelpText);

  TAccessibilityText.SplitHint(' &Only && text ', lName, lHelpText);
  Assert.AreEqual('Only & text', lName);
  Assert.AreEqual('Only & text', lHelpText);
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityTextTests);

end.
