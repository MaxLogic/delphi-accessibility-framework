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
    procedure CleanPlainTextFastPathReusesInputBuffer;
    [Test]
    procedure CleanStripsAcceleratorsAndTrimsText;
    [Test]
    procedure IconFontOnlyDetectionRequiresPrivateUseGlyphs;
    [Test]
    procedure RemoveLeadingDuplicateUsesIndexScanForSeparatorRuns;
    [Test]
    procedure RemoveLeadingDuplicateNoOpPathsReuseInputBuffer;
    [Test]
    procedure RemoveLeadingDuplicatePreservesSpeechTextSemantics;
    [Test]
    procedure SplitHintReturnsCleanShortAndLongParts;
  end;

implementation

uses
  System.IOUtils, System.SysUtils, DUnitX.Assert, MaxLogic.Accessibility.Text;

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

procedure TAccessibilityTextTests.CleanPlainTextFastPathReusesInputBuffer;
var
  lCleanText: string;
  lText: string;
begin
  lText := StringOfChar('A', 2048);
  lCleanText := TAccessibilityText.Clean(lText);
  Assert.AreEqual(lText, lCleanText);
  Assert.IsTrue(PChar(lCleanText) = PChar(lText), 'Clean plain text should return the original string buffer.');
end;

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

procedure TAccessibilityTextTests.RemoveLeadingDuplicateUsesIndexScanForSeparatorRuns;
const
  cSeparatorCount = 512;
  cSuffixLength = 512;
var
  lExpectedText: string;
  lResultText: string;
  lSourceText: string;
  lText: string;
begin
  lExpectedText := StringOfChar('B', cSuffixLength);
  lText := 'Alice' + StringOfChar('-', cSeparatorCount) + lExpectedText;
  lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, 'Alice');
  Assert.AreEqual(lExpectedText, lResultText);

  lSourceText := ReadRepoText('src\MaxLogic.Accessibility.Text.pas');
  Assert.DoesNotContain(lSourceText, 'Delete(Result, 1, 1)',
    'Separator trimming must advance indexes instead of repeatedly shifting the result string.');
  Assert.Contains(lSourceText, 'Result := Copy(aText, lStartIndex, lEndIndex - lStartIndex + 1);',
    'Separator trimming should materialize the final result in one copy.');
end;

procedure TAccessibilityTextTests.RemoveLeadingDuplicateNoOpPathsReuseInputBuffer;
var
  lDuplicate: string;
  lResultText: string;
  lText: string;
begin
  lText := StringOfChar('H', 8192);
  lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, '');
  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(PChar(lResultText) = PChar(lText), 'An empty duplicate should return the original string buffer.');

  lText := 'Search current orders ' + StringOfChar('H', 8192);
  lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, 'Alice');
  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(PChar(lResultText) = PChar(lText), 'A clean non-match should return the original string buffer.');

  lDuplicate := StringOfChar('A', 4096);
  lText := StringOfChar('B', 8192);
  lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, lDuplicate);
  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(PChar(lResultText) = PChar(lText), 'A long first-character mismatch should not copy the input.');

  lDuplicate := 'A' + StringOfChar('X', 4095);
  lText := 'A' + StringOfChar('B', 8191);
  lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, lDuplicate);
  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(PChar(lResultText) = PChar(lText), 'A shared-first-character mismatch should not copy the input.');
end;

procedure TAccessibilityTextTests.RemoveLeadingDuplicatePreservesSpeechTextSemantics;
begin
  Assert.AreEqual('Search current orders', TAccessibilityText.RemoveLeadingDuplicate(
    ' Alice -- Search current orders ', 'alice'));
  Assert.AreEqual('Search current orders', TAccessibilityText.RemoveLeadingDuplicate(
    'Alice | - : Search current orders', 'Alice'));
  Assert.AreEqual('Search current orders', TAccessibilityText.RemoveLeadingDuplicate(
    'Search current orders', 'Alice'));
  Assert.AreEqual('', TAccessibilityText.RemoveLeadingDuplicate('Alice ---', 'Alice'));
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
