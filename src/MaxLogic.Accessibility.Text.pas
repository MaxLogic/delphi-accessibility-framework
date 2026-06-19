unit MaxLogic.Accessibility.Text;

interface

type
  TAccessibilityText = record
  public
    class function Clean(const aText: string): string; static;
    class function IsIconFontOnly(const aText: string): Boolean; static;
    class procedure SplitHint(const aHint: string; out aName: string; out aHelpText: string); static;
  end;

implementation

uses
  System.SysUtils;

class function TAccessibilityText.Clean(const aText: string): string;
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
