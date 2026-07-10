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
    procedure CleanPlainTextFastPathBeatsPreviousCharAppendLoop;
    [Test]
    procedure CleanStripsAcceleratorsAndTrimsText;
    [Test]
    procedure IconFontOnlyDetectionRequiresPrivateUseGlyphs;
    [Test]
    procedure RemoveLeadingDuplicateAvoidsQuadraticSeparatorTrimming;
    [Test]
    procedure RemoveLeadingDuplicateEmptyDuplicateAvoidsCopy;
    [Test]
    procedure RemoveLeadingDuplicateCleanNonDuplicateAvoidsCopy;
    [Test]
    procedure RemoveLeadingDuplicateLongMismatchAvoidsPrefixCopy;
    [Test]
    procedure RemoveLeadingDuplicateAsciiSharedFirstCharMismatchAvoidsPrefixCopy;
    [Test]
    procedure RemoveLeadingDuplicatePreservesSpeechTextSemantics;
    [Test]
    procedure SplitHintReturnsCleanShortAndLongParts;
  end;

implementation

uses
  System.Diagnostics, System.SysUtils, DUnitX.Assert, MaxLogic.Accessibility.Text;

function SlowCleanLikePreviousImplementation(const aText: string): string;
var
  i: Integer;
begin
  Result := '';
  i := 1;
  while i <= Length(aText) do
  begin
    if aText[i] = '&' then
    begin
      if (i < Length(aText)) and (aText[i + 1] = '&') then
      begin
        Result := Result + '&';
        Inc(i, 2);
      end else begin
        Inc(i);
      end;
    end else begin
      Result := Result + aText[i];
      Inc(i);
    end;
  end;

  Result := Trim(Result);
end;

function SlowRemoveLeadingDuplicateLikePreviousImplementation(const aText: string; const aDuplicate: string): string;
begin
  Result := Trim(aText);
  if (Result = '') or (aDuplicate = '') or (CompareText(Copy(Result, 1, Length(aDuplicate)), aDuplicate) <> 0) then
  begin
    Exit;
  end;

  Delete(Result, 1, Length(aDuplicate));
  Result := Trim(Result);
  while (Result <> '') and CharInSet(Result[1], ['.', ',', ';', ':', '|', '-']) do
  begin
    Delete(Result, 1, 1);
    Result := Trim(Result);
  end;
end;

function SlowRemoveEmptyDuplicateLikeCurrentImplementation(const aText: string): string;
var
  lEndIndex: Integer;
  lStartIndex: Integer;
  lTextLength: Integer;
begin
  lTextLength := Length(aText);
  lStartIndex := 1;
  while (lStartIndex <= lTextLength) and CharInSet(aText[lStartIndex], [#0..#32]) do
  begin
    Inc(lStartIndex);
  end;

  lEndIndex := lTextLength;
  while (lEndIndex >= lStartIndex) and CharInSet(aText[lEndIndex], [#0..#32]) do
  begin
    Dec(lEndIndex);
  end;

  if lEndIndex < lStartIndex then
  begin
    Exit('');
  end;

  Result := Copy(aText, lStartIndex, lEndIndex - lStartIndex + 1);
end;

function SlowRemoveCleanNonDuplicateLikeCurrentImplementation(const aText: string; const aDuplicate: string): string;
var
  lEndIndex: Integer;
  lStartIndex: Integer;
  lTextLength: Integer;
begin
  lTextLength := Length(aText);
  lStartIndex := 1;
  while (lStartIndex <= lTextLength) and CharInSet(aText[lStartIndex], [#0..#32]) do
  begin
    Inc(lStartIndex);
  end;

  lEndIndex := lTextLength;
  while (lEndIndex >= lStartIndex) and CharInSet(aText[lEndIndex], [#0..#32]) do
  begin
    Dec(lEndIndex);
  end;

  if lEndIndex < lStartIndex then
  begin
    Exit('');
  end;

  if (lEndIndex - lStartIndex + 1 < Length(aDuplicate)) or
    (CompareText(Copy(aText, lStartIndex, Length(aDuplicate)), aDuplicate) <> 0) then
  begin
    Result := Copy(aText, lStartIndex, lEndIndex - lStartIndex + 1);
    Exit;
  end;

  Exit('');
end;

function SlowRemoveLongMismatchLikeCurrentImplementation(const aText: string; const aDuplicate: string): string;
begin
  if (aText <> '') and (aDuplicate <> '') and
    (not CharInSet(aText[1], [#0..#32])) and (not CharInSet(aText[Length(aText)], [#0..#32])) and
    ((Length(aText) < Length(aDuplicate)) or
    (CompareText(Copy(aText, 1, Length(aDuplicate)), aDuplicate) <> 0)) then
  begin
    Exit(aText);
  end;

  Result := SlowRemoveCleanNonDuplicateLikeCurrentImplementation(aText, aDuplicate);
end;

procedure TAccessibilityTextTests.CleanPlainTextFastPathBeatsPreviousCharAppendLoop;
const
  cIterationCount = 30;
var
  i: Integer;
  lCleanText: string;
  lFastTicks: Int64;
  lSlowTicks: Int64;
  lStopwatch: TStopwatch;
  lText: string;
begin
  lText := StringOfChar('A', 2048);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lCleanText := TAccessibilityText.Clean(lText);
  end;
  lFastTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lCleanText);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lCleanText := SlowCleanLikePreviousImplementation(lText);
  end;
  lSlowTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lCleanText);
  Assert.IsTrue(lFastTicks * 4 < lSlowTicks, Format(
    'Plain text Clean took %d ticks; expected at least 4x faster than the old %d-tick char append loop.',
    [lFastTicks, lSlowTicks]));
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

procedure TAccessibilityTextTests.RemoveLeadingDuplicateAvoidsQuadraticSeparatorTrimming;
const
  cIterationCount = 20;
  cSeparatorCount = 512;
  cSuffixLength = 512;
var
  i: Integer;
  lExpectedText: string;
  lFastTicks: Int64;
  lResultText: string;
  lSlowTicks: Int64;
  lStopwatch: TStopwatch;
  lText: string;
begin
  lExpectedText := StringOfChar('B', cSuffixLength);
  lText := 'Alice' + StringOfChar('-', cSeparatorCount) + lExpectedText;

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, 'Alice');
  end;
  lFastTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lExpectedText, lResultText);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := SlowRemoveLeadingDuplicateLikePreviousImplementation(lText, 'Alice');
  end;
  lSlowTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lExpectedText, lResultText);
  Assert.IsTrue(lFastTicks * 6 < lSlowTicks, Format(
    'Leading duplicate cleanup took %d ticks; expected at least 6x faster than the old %d-tick delete/trim loop.',
    [lFastTicks, lSlowTicks]));
end;

procedure TAccessibilityTextTests.RemoveLeadingDuplicateEmptyDuplicateAvoidsCopy;
const
  cIterationCount = 800;
var
  i: Integer;
  lFastTicks: Int64;
  lResultText: string;
  lSlowTicks: Int64;
  lStopwatch: TStopwatch;
  lText: string;
begin
  lText := StringOfChar('H', 8192);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, '');
  end;
  lFastTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := SlowRemoveEmptyDuplicateLikeCurrentImplementation(lText);
  end;
  lSlowTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(lFastTicks * 3 < lSlowTicks, Format(
    'Empty duplicate cleanup took %d ticks; expected at least 3x faster than the old %d-tick scan/copy path.',
    [lFastTicks, lSlowTicks]));
end;

procedure TAccessibilityTextTests.RemoveLeadingDuplicateCleanNonDuplicateAvoidsCopy;
const
  cIterationCount = 800;
var
  i: Integer;
  lFastTicks: Int64;
  lResultText: string;
  lSlowTicks: Int64;
  lStopwatch: TStopwatch;
  lText: string;
begin
  lText := 'Search current orders ' + StringOfChar('H', 8192);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, 'Alice');
  end;
  lFastTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := SlowRemoveCleanNonDuplicateLikeCurrentImplementation(lText, 'Alice');
  end;
  lSlowTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(lFastTicks * 3 < lSlowTicks, Format(
    'Clean non-duplicate cleanup took %d ticks; expected at least 3x faster than the old %d-tick scan/copy path.',
    [lFastTicks, lSlowTicks]));
end;

procedure TAccessibilityTextTests.RemoveLeadingDuplicateLongMismatchAvoidsPrefixCopy;
const
  cIterationCount = 800;
var
  i: Integer;
  lDuplicate: string;
  lFastTicks: Int64;
  lResultText: string;
  lSlowTicks: Int64;
  lStopwatch: TStopwatch;
  lText: string;
begin
  lDuplicate := StringOfChar('A', 4096);
  lText := StringOfChar('B', 8192);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, lDuplicate);
  end;
  lFastTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := SlowRemoveLongMismatchLikeCurrentImplementation(lText, lDuplicate);
  end;
  lSlowTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(lFastTicks * 4 < lSlowTicks, Format(
    'Long mismatch duplicate cleanup took %d ticks; expected at least 4x faster than the old %d-tick prefix-copy path.',
    [lFastTicks, lSlowTicks]));
end;

procedure TAccessibilityTextTests.RemoveLeadingDuplicateAsciiSharedFirstCharMismatchAvoidsPrefixCopy;
const
  cIterationCount = 800;
var
  i: Integer;
  lDuplicate: string;
  lFastTicks: Int64;
  lResultText: string;
  lSlowTicks: Int64;
  lStopwatch: TStopwatch;
  lText: string;
begin
  lDuplicate := 'A' + StringOfChar('X', 4095);
  lText := 'A' + StringOfChar('B', 8191);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := TAccessibilityText.RemoveLeadingDuplicate(lText, lDuplicate);
  end;
  lFastTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);

  lStopwatch := TStopwatch.StartNew;
  for i := 1 to cIterationCount do
  begin
    lResultText := SlowRemoveLongMismatchLikeCurrentImplementation(lText, lDuplicate);
  end;
  lSlowTicks := lStopwatch.ElapsedTicks;

  Assert.AreEqual(lText, lResultText);
  Assert.IsTrue(lFastTicks * 3 < lSlowTicks, Format(
    'Shared-prefix duplicate cleanup took %d ticks; expected at least 3x faster than the old %d-tick prefix-copy path.',
    [lFastTicks, lSlowTicks]));
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
