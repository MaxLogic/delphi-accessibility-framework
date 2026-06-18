unit MaxLogic.Accessibility.VclAdapters;

interface

uses
  Vcl.Controls, Vcl.Forms,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner;

type
  TAccessibilityVclAdapters = record
  public
    class function CreateDefaultRegistry: IAccessibilityAdapterRegistry; static;
    class procedure RegisterDefaultAdapters(const aRegistry: IAccessibilityAdapterRegistry); static;
  end;

  TAccessibilityVclProviderBuilder = record
  public
    class function BuildForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry = nil):
      IAccessibilityProviderNode; overload; static;
    class function BuildForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry;
      const aApi: IAccessibilityUiaApi):
      IAccessibilityProviderNode; overload; static;
  end;

implementation

uses
  System.Actions, System.SysUtils, System.Types, System.TypInfo, Winapi.Windows, Vcl.Buttons, Vcl.ExtCtrls,
  Vcl.StdCtrls, MaxLogic.Accessibility.UIAutomationCore;

type
  TExplicitTextAdapter = class(TInterfacedObject, IAccessibilityControlAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
  end;

  TPanelAdapter = class(TInterfacedObject, IAccessibilityControlAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
  end;

  TAccessibilityVclControlProvider = class(TAccessibilityProviderNode, IInvokeProvider, IToggleProvider)
  private
    fControl: TControl;
    class function SpeedButtonSupportsToggle(aButton: TSpeedButton): Boolean; static;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
  public
    constructor Create(aControl: TControl; const aRuntimeId: array of Integer; aControlTypeId: Integer;
      const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
    function Get_ToggleState(out aRetVal: ToggleState): HResult; stdcall;
    function Invoke: HResult; stdcall;
    function Toggle: HResult; stdcall;
  end;

function CleanText(const aText: string): string;
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

function IsIconFontOnlyText(const aText: string): Boolean;
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

function ReadObjectProperty(aObject: TObject; const aPropertyName: string): TObject;
var
  lPropInfo: PPropInfo;
begin
  Result := nil;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkClass) then
  begin
    Result := GetObjectProp(aObject, lPropInfo);
  end;
end;

function ReadStringProperty(aObject: TObject; const aPropertyName: string): string;
var
  lPropInfo: PPropInfo;
begin
  Result := '';
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    Result := CleanText(GetStrProp(aObject, lPropInfo));
  end;
end;

procedure SplitHint(const aHint: string; out aName: string; out aHelpText: string);
var
  lDelimiter: Integer;
  lHint: string;
begin
  lHint := Trim(aHint);
  lDelimiter := Pos('|', lHint);
  if lDelimiter > 0 then
  begin
    aName := CleanText(Copy(lHint, 1, Pred(lDelimiter)));
    aHelpText := CleanText(Copy(lHint, lDelimiter + 1, MaxInt));
  end else begin
    aName := CleanText(lHint);
    aHelpText := aName;
  end;
end;

function HasUsefulTextProperty(aControl: TControl; const aPropertyName: string): Boolean;
var
  lText: string;
begin
  lText := ReadStringProperty(aControl, aPropertyName);
  Result := (lText <> '') and not IsIconFontOnlyText(lText);
end;

function HasUsefulExplicitText(aControl: TControl): Boolean;
var
  lAction: TObject;
  lHelpText: string;
  lHintName: string;
begin
  Result := False;
  if aControl = nil then
  begin
    Exit;
  end;

  if HasUsefulTextProperty(aControl, 'AccessibleName') or HasUsefulTextProperty(aControl, 'Caption') or
    HasUsefulTextProperty(aControl, 'Text') then
  begin
    Exit(True);
  end;

  SplitHint(ReadStringProperty(aControl, 'Hint'), lHintName, lHelpText);
  if (lHintName <> '') or (lHelpText <> '') then
  begin
    Exit(True);
  end;

  lAction := ReadObjectProperty(aControl, 'Action');
  if lAction is TContainedAction then
  begin
    if (CleanText(TContainedAction(lAction).Caption) <> '') or
      (CleanText(TContainedAction(lAction).Hint) <> '') then
    begin
      Exit(True);
    end;
  end;
end;

function HasAccessibleDescendant(aControl: TWinControl): Boolean;
var
  i: Integer;
  lChild: TControl;
begin
  Result := False;
  for i := 0 to Pred(aControl.ControlCount) do
  begin
    lChild := aControl.Controls[i];
    if HasUsefulExplicitText(lChild) then
    begin
      Exit(True);
    end;

    if (lChild is TWinControl) and HasAccessibleDescendant(TWinControl(lChild)) then
    begin
      Exit(True);
    end;
  end;
end;

function ControlTypeFor(aControl: TControl): Integer;
begin
  if aControl is TSpeedButton then
  begin
    Exit(UIA_ButtonControlTypeId);
  end;

  if aControl is TCustomPanel then
  begin
    Exit(UIA_PaneControlTypeId);
  end;

  Result := UIA_TextControlTypeId;
end;

function CreateProviderForNode(const aNode: IAccessibilityScanNode; var aNextRuntimeId: Integer;
  const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Inc(aNextRuntimeId);
  Result := TAccessibilityVclControlProvider.Create(aNode.Control, [aNextRuntimeId], ControlTypeFor(aNode.Control),
    aNode.Name, aNode.HelpText, aApi) as IAccessibilityProviderNode;
end;

procedure AddProviderChildren(const aProvider: IAccessibilityProviderNode; const aScanNode: IAccessibilityScanNode;
  var aNextRuntimeId: Integer; const aApi: IAccessibilityUiaApi);
var
  i: Integer;
  lChildProvider: IAccessibilityProviderNode;
begin
  for i := 0 to Pred(aScanNode.ChildCount) do
  begin
    lChildProvider := CreateProviderForNode(aScanNode.Child(i), aNextRuntimeId, aApi);
    aProvider.AddChild(lChildProvider);
    AddProviderChildren(lChildProvider, aScanNode.Child(i), aNextRuntimeId, aApi);
  end;
end;

function TExplicitTextAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if HasUsefulExplicitText(aControl) then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TPanelAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if HasUsefulExplicitText(aControl) then
  begin
    Exit(TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText));
  end;

  if (aControl is TWinControl) and HasAccessibleDescendant(TWinControl(aControl)) then
  begin
    Exit(TAccessibilityControlInfo.Include(aControl, '', ''));
  end;

  Result := TAccessibilityControlInfo.Omit;
end;

constructor TAccessibilityVclControlProvider.Create(aControl: TControl; const aRuntimeId: array of Integer;
  aControlTypeId: Integer; const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, aControl);
  fControl := aControl;
  SetProperty(UIA_NamePropertyId, aName);
  SetProperty(UIA_ControlTypePropertyId, aControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aControl.ClassName);
  SetProperty(UIA_HelpTextPropertyId, aHelpText);
end;

function TAccessibilityVclControlProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lPoint: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fControl = nil) or IsDisconnected then
  begin
    Exit;
  end;

  lPoint := fControl.ClientToScreen(Point(0, 0));
  aValue.Left := lPoint.X;
  aValue.Top := lPoint.Y;
  aValue.Width := fControl.Width;
  aValue.Height := fControl.Height;
  Result := True;
end;

function TAccessibilityVclControlProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Result := nil;
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit;
  end;

  if aPatternId = UIA_InvokePatternId then
  begin
    Exit(Self as IInvokeProvider);
  end;

  if (aPatternId = UIA_TogglePatternId) and SpeedButtonSupportsToggle(TSpeedButton(fControl)) then
  begin
    Exit(Self as IToggleProvider);
  end;
end;

function TAccessibilityVclControlProvider.Get_ToggleState(out aRetVal: ToggleState): HResult;
begin
  aRetVal := ToggleState_Off;
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if TSpeedButton(fControl).Down then
  begin
    aRetVal := ToggleState_On;
  end;

  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Invoke: HResult;
begin
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  TSpeedButton(fControl).Click;
  Result := S_OK;
end;

class function TAccessibilityVclControlProvider.SpeedButtonSupportsToggle(aButton: TSpeedButton): Boolean;
begin
  Result := (aButton <> nil) and ((aButton.GroupIndex <> 0) or aButton.AllowAllUp or aButton.Down);
end;

function TAccessibilityVclControlProvider.Toggle: HResult;
var
  lButton: TSpeedButton;
begin
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lButton := TSpeedButton(fControl);
  if not SpeedButtonSupportsToggle(lButton) then
  begin
    Exit(E_NOTIMPL);
  end;

  if lButton.Down and not lButton.AllowAllUp then
  begin
    lButton.Down := True;
  end else begin
    lButton.Down := not lButton.Down;
  end;

  lButton.Click;
  Result := S_OK;
end;

class function TAccessibilityVclAdapters.CreateDefaultRegistry: IAccessibilityAdapterRegistry;
begin
  Result := TAccessibilityAdapterRegistry.Create;
  RegisterDefaultAdapters(Result);
end;

class procedure TAccessibilityVclAdapters.RegisterDefaultAdapters(const aRegistry: IAccessibilityAdapterRegistry);
begin
  if aRegistry = nil then
  begin
    raise EArgumentException.Create('Adapter registry must not be nil.');
  end;

  aRegistry.RegisterAdapter(TCustomLabel, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TSpeedButton, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TCustomPanel, TPanelAdapter.Create);
  aRegistry.RegisterAdapter(TGraphicControl, TExplicitTextAdapter.Create);
end;

class function TAccessibilityVclProviderBuilder.BuildForm(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry): IAccessibilityProviderNode;
begin
  Result := BuildForm(aForm, aRegistry, nil);
end;

class function TAccessibilityVclProviderBuilder.BuildForm(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
var
  lNextRuntimeId: Integer;
  lRegistry: IAccessibilityAdapterRegistry;
  lTree: IAccessibilityScanTree;
begin
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  lRegistry := aRegistry;
  if lRegistry = nil then
  begin
    lRegistry := TAccessibilityVclAdapters.CreateDefaultRegistry;
  end;

  lTree := TAccessibilityScanner.ScanForm(aForm, lRegistry);
  Result := TAccessibilityProviderFactory.CreateRoot([1], aForm.Handle, aApi, aForm);
  Result.SetProperty(UIA_NamePropertyId, lTree.Root.Name);
  Result.SetProperty(UIA_ControlTypePropertyId, UIA_PaneControlTypeId);
  Result.SetProperty(UIA_ClassNamePropertyId, aForm.ClassName);
  Result.SetProperty(UIA_HelpTextPropertyId, lTree.Root.HelpText);

  lNextRuntimeId := 1;
  AddProviderChildren(Result, lTree.Root, lNextRuntimeId, aApi);
end;

end.
