unit MaxLogic.Accessibility.Text;

interface

type
  TAccessibilityText = record
  public
    class function Clean(const aText: string): string; static;
    class function IsIconFontOnly(const aText: string): Boolean; static;
    class function RemoveLeadingDuplicate(const aText: string; const aDuplicate: string): string; static;
    class procedure SplitHint(const aHint: string; out aName: string; out aHelpText: string); static;
  end;

implementation

uses
  System.SysUtils;

function TextStartsWithIgnoreCase(const aText: string; aStartIndex: Integer; const aPrefix: string): Boolean;
var
  i: Integer;
  lPrefixChar: Char;
  lPrefixLength: Integer;
  lTextChar: Char;
begin
  lPrefixLength := Length(aPrefix);
  if lPrefixLength = 0 then
  begin
    Exit(True);
  end;

  if (aStartIndex < 1) or (aStartIndex + lPrefixLength - 1 > Length(aText)) then
  begin
    Exit(False);
  end;

  for i := 0 to Pred(lPrefixLength) do
  begin
    lTextChar := aText[aStartIndex + i];
    lPrefixChar := aPrefix[Succ(i)];
    if (Ord(lTextChar) > 127) or (Ord(lPrefixChar) > 127) then
    begin
      Exit(CompareText(Copy(aText, aStartIndex, lPrefixLength), aPrefix) = 0);
    end;

    if UpCase(lTextChar) <> UpCase(lPrefixChar) then
    begin
      Exit(False);
    end;
  end;

  Result := True;
end;

class function TAccessibilityText.Clean(const aText: string): string;
var
  i: Integer;
  lHasAccelerator: Boolean;
  lWriteIndex: Integer;
begin
  if aText = '' then
  begin
    Exit('');
  end;

  lHasAccelerator := Pos('&', aText) > 0;
  if (not lHasAccelerator) and (not CharInSet(aText[1], [#0..#32])) and
    (not CharInSet(aText[Length(aText)], [#0..#32])) then
  begin
    Result := aText;
    Exit;
  end;

  if not lHasAccelerator then
  begin
    Exit(Trim(aText));
  end;

  SetLength(Result, Length(aText));
  lWriteIndex := 0;
  i := 1;
  while i <= Length(aText) do
  begin
    if aText[i] = '&' then
    begin
      if (i < Length(aText)) and (aText[i + 1] = '&') then
      begin
        Inc(lWriteIndex);
        Result[lWriteIndex] := '&';
        Inc(i, 2);
      end else begin
        Inc(i);
      end;
    end else begin
      Inc(lWriteIndex);
      Result[lWriteIndex] := aText[i];
      Inc(i);
    end;
  end;

  SetLength(Result, lWriteIndex);
  Result := Trim(Result);
end;

class function TAccessibilityText.IsIconFontOnly(const aText: string): Boolean;
var
  i: Integer;
  lHasGlyph: Boolean;
begin
  lHasGlyph := False;
  for i := 1 to Length(aText) do
  begin
    if not CharInSet(aText[i], [#0..#32]) then
    begin
      if (Ord(aText[i]) < $E000) or (Ord(aText[i]) > $F8FF) then
      begin
        Exit(False);
      end;

      lHasGlyph := True;
    end;
  end;

  Result := lHasGlyph;
end;

class function TAccessibilityText.RemoveLeadingDuplicate(const aText: string; const aDuplicate: string): string;
var
  lDuplicateLength: Integer;
  lEndIndex: Integer;
  lStartIndex: Integer;
  lTextLength: Integer;
begin
  if aText = '' then
  begin
    Exit('');
  end;

  if aDuplicate = '' then
  begin
    if (not CharInSet(aText[1], [#0..#32])) and (not CharInSet(aText[Length(aText)], [#0..#32])) then
    begin
      Exit(aText);
    end;

    Exit(Trim(aText));
  end;

  lTextLength := Length(aText);
  lDuplicateLength := Length(aDuplicate);
  if (not CharInSet(aText[1], [#0..#32])) and (not CharInSet(aText[lTextLength], [#0..#32])) and
    ((lTextLength < lDuplicateLength) or not TextStartsWithIgnoreCase(aText, 1, aDuplicate)) then
  begin
    Exit(aText);
  end;

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

  if (lEndIndex - lStartIndex + 1 < lDuplicateLength) or
    not TextStartsWithIgnoreCase(aText, lStartIndex, aDuplicate) then
  begin
    Result := Copy(aText, lStartIndex, lEndIndex - lStartIndex + 1);
    Exit;
  end;

  Inc(lStartIndex, lDuplicateLength);
  while (lStartIndex <= lEndIndex) and CharInSet(aText[lStartIndex], [#0..#32]) do
  begin
    Inc(lStartIndex);
  end;

  while (lStartIndex <= lEndIndex) and CharInSet(aText[lStartIndex], ['.', ',', ';', ':', '|', '-']) do
  begin
    Inc(lStartIndex);
    while (lStartIndex <= lEndIndex) and CharInSet(aText[lStartIndex], [#0..#32]) do
    begin
      Inc(lStartIndex);
    end;
  end;

  if lEndIndex < lStartIndex then
  begin
    Exit('');
  end;

  Result := Copy(aText, lStartIndex, lEndIndex - lStartIndex + 1);
end;

class procedure TAccessibilityText.SplitHint(const aHint: string; out aName: string; out aHelpText: string);
var
  lDelimiter: Integer;
  lHint: string;
begin
  // Scanner fallback semantics: a hint without "|" supplies both name and help text.
  lHint := Trim(aHint);
  lDelimiter := Pos('|', lHint);
  if lDelimiter > 0 then
  begin
    aName := Clean(Copy(lHint, 1, Pred(lDelimiter)));
    aHelpText := Clean(Copy(lHint, lDelimiter + 1, MaxInt));
  end else begin
    aName := Clean(lHint);
    aHelpText := aName;
  end;
end;

end.
