unit MaxLogic.Accessibility.Msaa;

interface

uses
  Winapi.oleacc, Winapi.Windows,
  MaxLogic.Accessibility.UIAutomationCore;

type
  TAccessibilityMsaaBridge = record
  public
    class function CreateAccessible(const aProvider: IRawElementProviderSimple): IAccessible; static;
    class function TryHandleGetObject(aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple; out aResult: LRESULT): Boolean; static;
  end;

implementation

uses
  System.SysUtils, System.Variants, Winapi.ActiveX;

type
  TAccessibilityMsaaProvider = class(TInterfacedObject, IDispatch, IAccessible)
  private
    fProvider: IRawElementProviderSimple;
    function Fragment: IRawElementProviderFragment;
    function ProviderBoolProperty(aPropertyId: PROPERTYID; aDefault: Boolean): Boolean;
    function ProviderIntProperty(aPropertyId: PROPERTYID; aDefault: Integer): Integer;
    function ProviderStringProperty(aPropertyId: PROPERTYID): string;
    function SelectionItemProvider(out aProvider: ISelectionItemProvider): Boolean;
    function SelfChild(const aChild: OleVariant): Boolean;
    function ToggleProvider(out aProvider: IToggleProvider): Boolean;
  public
    constructor Create(const aProvider: IRawElementProviderSimple);
    function Get_accParent(out ppdispParent: IDispatch): HResult; stdcall;
    function Get_accChildCount(out pcountChildren: Integer): HResult; stdcall;
    function Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult; stdcall;
    function Get_accName(varChild: OleVariant; out pszName: WideString): HResult; stdcall;
    function Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult; stdcall;
    function Get_accDescription(varChild: OleVariant; out pszDescription: WideString): HResult; stdcall;
    function Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult; stdcall;
    function Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult; stdcall;
    function Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult; stdcall;
    function Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant; out pidTopic: Integer): HResult;
      stdcall;
    function Get_accKeyboardShortcut(varChild: OleVariant; out pszKeyboardShortcut: WideString): HResult; stdcall;
    function Get_accFocus(out pvarChild: OleVariant): HResult; stdcall;
    function Get_accSelection(out pvarChildren: OleVariant): HResult; stdcall;
    function Get_accDefaultAction(varChild: OleVariant; out pszDefaultAction: WideString): HResult; stdcall;
    function accSelect(flagsSelect: Integer; varChild: OleVariant): HResult; stdcall;
    function accLocation(out pxLeft: Integer; out pyTop: Integer; out pcxWidth: Integer; out pcyHeight: Integer;
      varChild: OleVariant): HResult; stdcall;
    function accNavigate(navDir: Integer; varStart: OleVariant; out pvarEndUpAt: OleVariant): HResult; stdcall;
    function accHitTest(xLeft: Integer; yTop: Integer; out pvarChild: OleVariant): HResult; stdcall;
    function accDoDefaultAction(varChild: OleVariant): HResult; stdcall;
    function Set_accName(varChild: OleVariant; const pszName: WideString): HResult; stdcall;
    function Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount: Integer; LocaleID: Integer;
      DispIDs: Pointer): HRESULT; stdcall;
    function GetTypeInfo(Index: Integer; LocaleID: Integer; out TypeInfo): HRESULT; stdcall;
    function GetTypeInfoCount(out Count: Integer): HRESULT; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params;
      VarResult: Pointer; ExcepInfo: Pointer; ArgErr: Pointer): HRESULT; stdcall;
  end;

function DispatchVariant(const aAccessible: IAccessible): OleVariant;
var
  lDispatch: IDispatch;
begin
  lDispatch := aAccessible as IDispatch;
  Result := lDispatch;
end;

function RoleForControlType(aControlTypeId: Integer): Integer;
begin
  case aControlTypeId of
    UIA_ButtonControlTypeId:
      Result := ROLE_SYSTEM_PUSHBUTTON;
    UIA_CheckBoxControlTypeId:
      Result := ROLE_SYSTEM_CHECKBUTTON;
    UIA_ComboBoxControlTypeId:
      Result := ROLE_SYSTEM_COMBOBOX;
    UIA_CustomControlTypeId:
      Result := ROLE_SYSTEM_CLIENT;
    UIA_DataGridControlTypeId:
      Result := ROLE_SYSTEM_TABLE;
    UIA_DataItemControlTypeId:
      Result := ROLE_SYSTEM_CELL;
    UIA_EditControlTypeId:
      Result := ROLE_SYSTEM_TEXT;
    UIA_ListControlTypeId:
      Result := ROLE_SYSTEM_LIST;
    UIA_ListItemControlTypeId:
      Result := ROLE_SYSTEM_LISTITEM;
    UIA_PaneControlTypeId:
      Result := ROLE_SYSTEM_PANE;
    UIA_RadioButtonControlTypeId:
      Result := ROLE_SYSTEM_RADIOBUTTON;
    UIA_StatusBarControlTypeId:
      Result := ROLE_SYSTEM_STATUSBAR;
    UIA_TabControlTypeId:
      Result := ROLE_SYSTEM_PAGETABLIST;
    UIA_TabItemControlTypeId:
      Result := ROLE_SYSTEM_PAGETAB;
    UIA_TextControlTypeId:
      Result := ROLE_SYSTEM_STATICTEXT;
    UIA_ToolBarControlTypeId:
      Result := ROLE_SYSTEM_TOOLBAR;
    UIA_ToolTipControlTypeId:
      Result := ROLE_SYSTEM_TOOLTIP;
    UIA_GroupControlTypeId:
      Result := ROLE_SYSTEM_GROUPING;
  else
    Result := ROLE_SYSTEM_CLIENT;
  end;
end;

const
  cTabDefaultAction = 'Switch';

constructor TAccessibilityMsaaProvider.Create(const aProvider: IRawElementProviderSimple);
begin
  inherited Create;
  fProvider := aProvider;
end;

function TAccessibilityMsaaProvider.Fragment: IRawElementProviderFragment;
begin
  Result := nil;
  Supports(fProvider, IRawElementProviderFragment, Result);
end;

function TAccessibilityMsaaProvider.ProviderBoolProperty(aPropertyId: PROPERTYID; aDefault: Boolean): Boolean;
var
  lValue: OleVariant;
begin
  Result := aDefault;
  if (fProvider <> nil) and (fProvider.GetPropertyValue(aPropertyId, lValue) = S_OK) and
    not (VarIsEmpty(lValue) or VarIsNull(lValue)) then
  begin
    Result := Boolean(lValue);
  end;
end;

function TAccessibilityMsaaProvider.ProviderIntProperty(aPropertyId: PROPERTYID; aDefault: Integer): Integer;
var
  lValue: OleVariant;
begin
  Result := aDefault;
  if (fProvider <> nil) and (fProvider.GetPropertyValue(aPropertyId, lValue) = S_OK) and
    not (VarIsEmpty(lValue) or VarIsNull(lValue)) then
  begin
    Result := Integer(lValue);
  end;
end;

function TAccessibilityMsaaProvider.ProviderStringProperty(aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Result := '';
  if (fProvider <> nil) and (fProvider.GetPropertyValue(aPropertyId, lValue) = S_OK) and
    not (VarIsEmpty(lValue) or VarIsNull(lValue)) then
  begin
    Result := VarToStr(lValue);
  end;
end;

function TAccessibilityMsaaProvider.SelectionItemProvider(out aProvider: ISelectionItemProvider): Boolean;
var
  lPattern: IUnknown;
begin
  aProvider := nil;
  Result := (fProvider <> nil) and (fProvider.GetPatternProvider(UIA_SelectionItemPatternId, lPattern) = S_OK) and
    Supports(lPattern, ISelectionItemProvider, aProvider);
end;

function TAccessibilityMsaaProvider.SelfChild(const aChild: OleVariant): Boolean;
begin
  Result := VarIsNumeric(aChild) and (Integer(aChild) = CHILDID_SELF);
end;

function TAccessibilityMsaaProvider.ToggleProvider(out aProvider: IToggleProvider): Boolean;
var
  lPattern: IUnknown;
begin
  aProvider := nil;
  Result := (fProvider <> nil) and (fProvider.GetPatternProvider(UIA_TogglePatternId, lPattern) = S_OK) and
    Supports(lPattern, IToggleProvider, aProvider);
end;

function TAccessibilityMsaaProvider.Get_accParent(out ppdispParent: IDispatch): HResult;
var
  lParent: IRawElementProviderFragment;
  lFragment: IRawElementProviderFragment;
begin
  ppdispParent := nil;
  lFragment := Fragment;
  if (lFragment = nil) or (lFragment.Navigate(NavigateDirection_Parent, lParent) <> S_OK) or (lParent = nil) then
  begin
    Exit(S_FALSE);
  end;

  ppdispParent := TAccessibilityMsaaBridge.CreateAccessible(lParent as IRawElementProviderSimple) as IDispatch;
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.Get_accChildCount(out pcountChildren: Integer): HResult;
var
  lChild: IRawElementProviderFragment;
  lFragment: IRawElementProviderFragment;
begin
  pcountChildren := 0;
  lFragment := Fragment;
  if lFragment = nil then
  begin
    Exit(S_OK);
  end;

  if lFragment.Navigate(NavigateDirection_FirstChild, lChild) <> S_OK then
  begin
    Exit(S_FALSE);
  end;

  while lChild <> nil do
  begin
    Inc(pcountChildren);
    if lChild.Navigate(NavigateDirection_NextSibling, lChild) <> S_OK then
    begin
      Break;
    end;
  end;
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult;
var
  i: Integer;
  lChild: IRawElementProviderFragment;
  lFragment: IRawElementProviderFragment;
begin
  ppdispChild := nil;
  if not VarIsNumeric(varChild) or (Integer(varChild) <= CHILDID_SELF) then
  begin
    Exit(E_INVALIDARG);
  end;

  lFragment := Fragment;
  if (lFragment = nil) or (lFragment.Navigate(NavigateDirection_FirstChild, lChild) <> S_OK) then
  begin
    Exit(S_FALSE);
  end;

  for i := 2 to Integer(varChild) do
  begin
    if (lChild = nil) or (lChild.Navigate(NavigateDirection_NextSibling, lChild) <> S_OK) then
    begin
      Exit(S_FALSE);
    end;
  end;

  if lChild = nil then
  begin
    Exit(S_FALSE);
  end;

  ppdispChild := TAccessibilityMsaaBridge.CreateAccessible(lChild as IRawElementProviderSimple) as IDispatch;
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.Get_accName(varChild: OleVariant; out pszName: WideString): HResult;
begin
  pszName := '';
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  pszName := ProviderStringProperty(UIA_NamePropertyId);
  if pszName = '' then
  begin
    Result := S_FALSE;
  end else begin
    Result := S_OK;
  end;
end;

function TAccessibilityMsaaProvider.Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult;
var
  lPattern: IUnknown;
  lValueProvider: IValueProvider;
begin
  pszValue := '';
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  if (fProvider = nil) or (fProvider.GetPatternProvider(UIA_ValuePatternId, lPattern) <> S_OK) or
    not Supports(lPattern, IValueProvider, lValueProvider) then
  begin
    Exit(S_FALSE);
  end;

  Result := lValueProvider.Get_Value(pszValue);
end;

function TAccessibilityMsaaProvider.Get_accDescription(varChild: OleVariant; out pszDescription: WideString): HResult;
begin
  Result := Get_accHelp(varChild, pszDescription);
end;

function TAccessibilityMsaaProvider.Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult;
begin
  pvarRole := Unassigned;
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  pvarRole := RoleForControlType(ProviderIntProperty(UIA_ControlTypePropertyId, UIA_CustomControlTypeId));
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult;
var
  lControlType: Integer;
  lIsSelected: BOOL;
  lSelectionItemProvider: ISelectionItemProvider;
  lState: Integer;
  lToggleProvider: IToggleProvider;
  lToggleState: ToggleState;
begin
  pvarState := Unassigned;
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  lState := STATE_SYSTEM_NORMAL;
  lControlType := ProviderIntProperty(UIA_ControlTypePropertyId, UIA_CustomControlTypeId);
  if not ProviderBoolProperty(UIA_IsEnabledPropertyId, True) then
  begin
    lState := lState or STATE_SYSTEM_UNAVAILABLE;
  end;

  if ProviderBoolProperty(UIA_IsKeyboardFocusablePropertyId, False) then
  begin
    lState := lState or STATE_SYSTEM_FOCUSABLE;
  end;

  if ProviderBoolProperty(UIA_HasKeyboardFocusPropertyId, False) then
  begin
    lState := lState or STATE_SYSTEM_FOCUSED;
  end;

  if ProviderBoolProperty(UIA_IsOffscreenPropertyId, False) then
  begin
    lState := lState or STATE_SYSTEM_OFFSCREEN;
  end;

  if SelectionItemProvider(lSelectionItemProvider) then
  begin
    lState := lState or STATE_SYSTEM_SELECTABLE;
    if (lSelectionItemProvider.Get_IsSelected(lIsSelected) = S_OK) and lIsSelected then
    begin
      lState := lState or STATE_SYSTEM_SELECTED;
      if lControlType = UIA_RadioButtonControlTypeId then
      begin
        lState := lState or STATE_SYSTEM_CHECKED;
      end;
    end;
  end;

  if ToggleProvider(lToggleProvider) and (lToggleProvider.Get_ToggleState(lToggleState) = S_OK) then
  begin
    case lToggleState of
      ToggleState_On:
        lState := lState or STATE_SYSTEM_CHECKED;
      ToggleState_Indeterminate:
        lState := lState or STATE_SYSTEM_MIXED;
    end;
  end;

  pvarState := lState;
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult;
begin
  pszHelp := '';
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  pszHelp := ProviderStringProperty(UIA_HelpTextPropertyId);
  if pszHelp = '' then
  begin
    Result := S_FALSE;
  end else begin
    Result := S_OK;
  end;
end;

function TAccessibilityMsaaProvider.Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant;
  out pidTopic: Integer): HResult;
begin
  pszHelpFile := '';
  pidTopic := 0;
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.Get_accKeyboardShortcut(varChild: OleVariant;
  out pszKeyboardShortcut: WideString): HResult;
begin
  pszKeyboardShortcut := '';
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.Get_accFocus(out pvarChild: OleVariant): HResult;
var
  lFocus: IRawElementProviderFragment;
  lRoot: IRawElementProviderFragmentRoot;
begin
  pvarChild := CHILDID_SELF;
  if (fProvider <> nil) and Supports(fProvider, IRawElementProviderFragmentRoot, lRoot) and
    (lRoot.GetFocus(lFocus) = S_OK) and (lFocus <> nil) then
  begin
    pvarChild := DispatchVariant(TAccessibilityMsaaBridge.CreateAccessible(lFocus as IRawElementProviderSimple));
  end;

  Result := S_OK;
end;

function TAccessibilityMsaaProvider.Get_accSelection(out pvarChildren: OleVariant): HResult;
begin
  pvarChildren := Unassigned;
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.Get_accDefaultAction(varChild: OleVariant;
  out pszDefaultAction: WideString): HResult;
var
  lSelectionItemProvider: ISelectionItemProvider;
begin
  pszDefaultAction := '';
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  if (ProviderIntProperty(UIA_ControlTypePropertyId, UIA_CustomControlTypeId) = UIA_TabItemControlTypeId) and
    SelectionItemProvider(lSelectionItemProvider) then
  begin
    pszDefaultAction := cTabDefaultAction;
    Exit(S_OK);
  end;

  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.accSelect(flagsSelect: Integer; varChild: OleVariant): HResult;
var
  lSelectionItemProvider: ISelectionItemProvider;
begin
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  if not SelectionItemProvider(lSelectionItemProvider) then
  begin
    Exit(DISP_E_MEMBERNOTFOUND);
  end;

  if (flagsSelect and SELFLAG_REMOVESELECTION) <> 0 then
  begin
    Exit(lSelectionItemProvider.RemoveFromSelection);
  end;

  if (flagsSelect and (SELFLAG_TAKESELECTION or SELFLAG_ADDSELECTION or SELFLAG_TAKEFOCUS)) <> 0 then
  begin
    Exit(lSelectionItemProvider.Select);
  end;

  Result := S_OK;
end;

function TAccessibilityMsaaProvider.accLocation(out pxLeft: Integer; out pyTop: Integer; out pcxWidth: Integer;
  out pcyHeight: Integer; varChild: OleVariant): HResult;
var
  lBounds: UiaRect;
  lFragment: IRawElementProviderFragment;
begin
  pxLeft := 0;
  pyTop := 0;
  pcxWidth := 0;
  pcyHeight := 0;
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  lFragment := Fragment;
  if (lFragment = nil) or (lFragment.Get_BoundingRectangle(lBounds) <> S_OK) then
  begin
    Exit(S_FALSE);
  end;

  pxLeft := Round(lBounds.Left);
  pyTop := Round(lBounds.Top);
  pcxWidth := Round(lBounds.Width);
  pcyHeight := Round(lBounds.Height);
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.accNavigate(navDir: Integer; varStart: OleVariant;
  out pvarEndUpAt: OleVariant): HResult;
begin
  pvarEndUpAt := Unassigned;
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.accHitTest(xLeft: Integer; yTop: Integer; out pvarChild: OleVariant): HResult;
var
  lHit: IRawElementProviderFragment;
  lRoot: IRawElementProviderFragmentRoot;
begin
  pvarChild := Unassigned;
  if (fProvider <> nil) and Supports(fProvider, IRawElementProviderFragmentRoot, lRoot) and
    (lRoot.ElementProviderFromPoint(xLeft, yTop, lHit) = S_OK) and (lHit <> nil) then
  begin
    pvarChild := DispatchVariant(TAccessibilityMsaaBridge.CreateAccessible(lHit as IRawElementProviderSimple));
    Exit(S_OK);
  end;

  pvarChild := CHILDID_SELF;
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.accDoDefaultAction(varChild: OleVariant): HResult;
var
  lSelectionItemProvider: ISelectionItemProvider;
begin
  if not SelfChild(varChild) then
  begin
    Exit(E_INVALIDARG);
  end;

  if (ProviderIntProperty(UIA_ControlTypePropertyId, UIA_CustomControlTypeId) = UIA_TabItemControlTypeId) and
    SelectionItemProvider(lSelectionItemProvider) then
  begin
    Exit(lSelectionItemProvider.Select);
  end;

  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.Set_accName(varChild: OleVariant; const pszName: WideString): HResult;
begin
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult;
begin
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TAccessibilityMsaaProvider.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount: Integer;
  LocaleID: Integer; DispIDs: Pointer): HRESULT;
begin
  Result := E_NOTIMPL;
end;

function TAccessibilityMsaaProvider.GetTypeInfo(Index: Integer; LocaleID: Integer; out TypeInfo): HRESULT;
begin
  Pointer(TypeInfo) := nil;
  Result := E_NOTIMPL;
end;

function TAccessibilityMsaaProvider.GetTypeInfoCount(out Count: Integer): HRESULT;
begin
  Count := 0;
  Result := S_OK;
end;

function TAccessibilityMsaaProvider.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
  var Params; VarResult: Pointer; ExcepInfo: Pointer; ArgErr: Pointer): HRESULT;
begin
  Result := DISP_E_MEMBERNOTFOUND;
end;

class function TAccessibilityMsaaBridge.CreateAccessible(
  const aProvider: IRawElementProviderSimple): IAccessible;
begin
  Result := TAccessibilityMsaaProvider.Create(aProvider) as IAccessible;
end;

class function TAccessibilityMsaaBridge.TryHandleGetObject(aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple; out aResult: LRESULT): Boolean;
var
  lAccessible: IAccessible;
begin
  aResult := 0;
  Result := False;
  if (aLParam <> LPARAM(OBJID_CLIENT)) or (aProvider = nil) then
  begin
    Exit;
  end;

  lAccessible := CreateAccessible(aProvider);
  aResult := LresultFromObject(IID_IAccessible, aWParam, lAccessible);
  Result := aResult <> 0;
end;

end.
