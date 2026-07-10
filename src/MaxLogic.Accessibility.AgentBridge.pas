unit MaxLogic.Accessibility.AgentBridge;

interface

uses
  MaxLogic.Accessibility.UIAutomationCore;

type
  TAccessibilityAgentBridge = record
  public
    class function Execute(const aRequestJson: string): string; static;
    class function MutationEnabled: Boolean; static;
    class procedure SetMutationEnabled(aValue: Boolean); static;
  end;

  TAccessibilityAgentBridgeInternals = record
  public
    class function SerializeProviderNode(const aProvider: IRawElementProviderSimple; aFullDetail: Boolean;
      aMaxDepth: Integer; aMaxChildren: Integer): string; static;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.Generics.Collections, System.Generics.Defaults, System.JSON,
  System.SysUtils, System.Types, System.TypInfo, System.Variants,
  Winapi.Messages, Winapi.Windows, Vcl.Buttons, Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Grids,
  Vcl.StdCtrls,
  MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.Framework, MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner, MaxLogic.Accessibility.Text,
  MaxLogic.Accessibility.VclAdapters;

type
  TAccessibilityAgentBridgeMapDetail = (abmdFull, abmdGeometry);

  TAgentBridgeCheckBoxAccess = class(TCustomCheckBox);
  TAgentBridgeControlAccess = class(TControl);
  TAgentBridgeWinControlAccess = class(TWinControl);

  TAgentBridgeRttiPropertyCache = class
  private
    fPropsByClass: TObjectDictionary<NativeUInt, TDictionary<string, PPropInfo>>;
  public
    constructor Create;
    destructor Destroy; override;
    function Lookup(aObject: TObject; const aPropertyName: string): PPropInfo;
  end;

  TAccessibilityAgentBridgeState = class(TComponent)
  private
    fControlsByRef: TDictionary<string, TControl>;
    fForm: TCustomForm;
    fNextRefIndex: Integer;
    fObservedControls: TList<TComponent>;
    fRefsByControl: TDictionary<TControl, string>;
    fScreenRectsByControl: TDictionary<TControl, TRect>;
    fSnapshotId: Integer;
    function BuildControlInfo(aControl: TControl; aIncludeAccessibility: Boolean;
      aDetail: TAccessibilityAgentBridgeMapDetail): string;
    function BuildControlsInfo(aRefs: TJSONArray; aIncludeAccessibility: Boolean;
      aDetail: TAccessibilityAgentBridgeMapDetail): string;
    function BuildFormMap(aForm: TCustomForm; aIncludeAccessibility: Boolean; aVisibleOnly: Boolean;
      aDetail: TAccessibilityAgentBridgeMapDetail): string;
    function BuildProviderMap(aForm: TCustomForm; aDetail: TAccessibilityAgentBridgeMapDetail; aMaxDepth: Integer;
      aMaxChildren: Integer): string;
    function ControlAtScreenPoint(aParent: TWinControl; const aPoint: TPoint): TControl;
    function ControlJson(aControl: TControl; const aParentRef: string; aDepth: Integer;
      const aScreenRect: TRect; const aTree: IAccessibilityScanTree; aDetail: TAccessibilityAgentBridgeMapDetail;
      aFocusedHandle: HWND; aRttiCache: TAgentBridgeRttiPropertyCache; out aRef: string): TJSONObject;
    function ControlClientOriginForChildren(aControl: TControl; const aScreenRect: TRect): TPoint;
    function ControlIsVisibleChildInActivePage(aControl: TControl): Boolean;
    function ControlScreenRect(aControl: TControl): TRect;
    function ControlScreenRectFromParentOrigin(aControl: TControl; const aParentClientOrigin: TPoint): TRect;
    function ControlScreenRectFromSnapshot(aControl: TControl): TRect;
    function ExecuteClick(aRequest: TJSONObject): string;
    function ExecuteControlInfo(aRequest: TJSONObject): string;
    function ExecuteControlsInfo(aRequest: TJSONObject): string;
    function ExecuteFocus(aRequest: TJSONObject): string;
    function ExecuteFormMap(aRequest: TJSONObject): string;
    function ExecuteFormsList: string;
    function ExecuteHello: string;
    function ExecuteHitTest(aRequest: TJSONObject): string;
    function ExecuteKeyboardTab(aRequest: TJSONObject): string;
    function ExecuteProviderHotspots: string;
    function ExecuteProviderMap(aRequest: TJSONObject): string;
    function ExecuteSetText(aRequest: TJSONObject; aAppend: Boolean): string;
    function ExecuteWindowInfo(aRequest: TJSONObject): string;
    function Failure(const aErrorCode: string; const aMessage: string): string;
    function FormSummaryJson(aForm: TCustomForm): TJSONObject;
    function HitControlAt(const aPoint: TPoint): TControl;
    procedure AddChildControls(aParent: TWinControl; const aParentRef: string; aDepth: Integer;
      const aParentClientOrigin: TPoint; aControls: TJSONArray; const aTree: IAccessibilityScanTree; aVisibleOnly: Boolean;
      aDetail: TAccessibilityAgentBridgeMapDetail; aFocusedHandle: HWND; aRttiCache: TAgentBridgeRttiPropertyCache);
    procedure AddControlState(aJson: TJSONObject; aControl: TControl; const aTree: IAccessibilityScanTree;
      aRttiCache: TAgentBridgeRttiPropertyCache);
    procedure AddControlTargeting(aJson: TJSONObject; aControl: TControl; const aScreenRect: TRect;
      aFocusedHandle: HWND);
    procedure ClearSnapshot;
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
    function RefForControl(aControl: TControl; out aRef: string): Boolean;
    function RegisterControl(aControl: TControl): string;
    function ResolveControl(aRequest: TJSONObject; out aControl: TControl): Boolean;
    function ResolveForm(aRequest: TJSONObject): TCustomForm;
    function SuccessCommand(const aCommand: string): string;
    function SuccessMutation: string;
    function WindowInfoJson(aForm: TCustomForm): TJSONObject;
    procedure FocusWinControl(aControl: TWinControl);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    function Execute(aRequest: TJSONObject): string;
  end;

var
  gBridgeState: TAccessibilityAgentBridgeState;
  gMutationEnabled: Boolean;

constructor TAgentBridgeRttiPropertyCache.Create;
begin
  inherited Create;
  fPropsByClass := TObjectDictionary<NativeUInt, TDictionary<string, PPropInfo>>.Create([doOwnsValues]);
end;

destructor TAgentBridgeRttiPropertyCache.Destroy;
begin
  fPropsByClass.Free;
  inherited Destroy;
end;

function TAgentBridgeRttiPropertyCache.Lookup(aObject: TObject; const aPropertyName: string): PPropInfo;
var
  lClassInfo: PTypeInfo;
  lClassKey: NativeUInt;
  lProperties: TDictionary<string, PPropInfo>;
begin
  Result := nil;
  if aObject = nil then
  begin
    Exit;
  end;

  lClassInfo := aObject.ClassInfo;
  if lClassInfo = nil then
  begin
    Exit;
  end;

  lClassKey := NativeUInt(lClassInfo);
  if not fPropsByClass.TryGetValue(lClassKey, lProperties) then
  begin
    lProperties := TDictionary<string, PPropInfo>.Create;
    fPropsByClass.Add(lClassKey, lProperties);
  end;

  if not lProperties.TryGetValue(aPropertyName, Result) then
  begin
    TAccessibilityDiagnostics.RecordAgentBridgeRttiPropertyLookup;
    Result := GetPropInfo(lClassInfo, aPropertyName);
    lProperties.Add(aPropertyName, Result);
  end;
end;

function AddBool(aObject: TJSONObject; const aName: string; aValue: Boolean): TJSONObject;
begin
  Result := aObject.AddPair(aName, TJSONBool.Create(aValue));
end;

function AddInt(aObject: TJSONObject; const aName: string; aValue: Int64): TJSONObject;
begin
  Result := aObject.AddPair(aName, TJSONNumber.Create(aValue));
end;

function AddUInt(aObject: TJSONObject; const aName: string; aValue: UInt64): TJSONObject;
begin
  Result := aObject.AddPair(aName, TJSONNumber.Create(aValue));
end;

function JsonObjectToString(aObject: TJSONObject): string;
begin
  try
    Result := aObject.ToJSON;
  finally
    aObject.Free;
  end;
end;

function FailureResponse(const aErrorCode: string; const aMessage: string): string;
var
  lResponse: TJSONObject;
begin
  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', False);
  lResponse.AddPair('errorCode', aErrorCode);
  lResponse.AddPair('message', aMessage);
  Result := JsonObjectToString(lResponse);
end;

function PointJson(const aPoint: TPoint): TJSONObject;
begin
  Result := TJSONObject.Create;
  AddInt(Result, 'x', aPoint.X);
  AddInt(Result, 'y', aPoint.Y);
end;

function RectJson(const aRect: TRect): TJSONObject;
begin
  Result := TJSONObject.Create;
  AddInt(Result, 'left', aRect.Left);
  AddInt(Result, 'top', aRect.Top);
  AddInt(Result, 'right', aRect.Right);
  AddInt(Result, 'bottom', aRect.Bottom);
  AddInt(Result, 'width', aRect.Width);
  AddInt(Result, 'height', aRect.Height);
end;

function RequestString(aRequest: TJSONObject; const aName: string): string;
var
  lValue: TJSONValue;
begin
  Result := '';
  lValue := aRequest.GetValue(aName);
  if lValue <> nil then
  begin
    Result := lValue.Value;
  end;
end;

function RequestArray(aRequest: TJSONObject; const aName: string): TJSONArray;
var
  lValue: TJSONValue;
begin
  lValue := aRequest.GetValue(aName);
  if lValue is TJSONArray then
  begin
    Exit(TJSONArray(lValue));
  end;

  Result := nil;
end;

function RequestBool(aRequest: TJSONObject; const aName: string; aDefault: Boolean): Boolean;
var
  lText: string;
  lValue: TJSONValue;
begin
  Result := aDefault;
  lValue := aRequest.GetValue(aName);
  if lValue = nil then
  begin
    Exit;
  end;

  lText := lValue.Value;
  if SameText(lText, 'true') then
  begin
    Exit(True);
  end;

  if SameText(lText, 'false') then
  begin
    Exit(False);
  end;
end;

function RequestInt(aRequest: TJSONObject; const aName: string; out aValue: Integer): Boolean;
var
  lValue: TJSONValue;
begin
  aValue := 0;
  lValue := aRequest.GetValue(aName);
  Result := (lValue <> nil) and TryStrToInt(lValue.Value, aValue);
end;

function RequestUInt64(aRequest: TJSONObject; const aName: string; out aValue: UInt64): Boolean;
var
  lValue: TJSONValue;
begin
  aValue := 0;
  lValue := aRequest.GetValue(aName);
  Result := (lValue <> nil) and TryStrToUInt64(lValue.Value, aValue);
end;

function RequestMapDetail(aRequest: TJSONObject): TAccessibilityAgentBridgeMapDetail;
var
  lDetail: string;
begin
  lDetail := RequestString(aRequest, 'detail');
  if SameText(lDetail, 'geometry') then
  begin
    Exit(abmdGeometry);
  end;

  Result := abmdFull;
end;

function RequestBoundedInt(aRequest: TJSONObject; const aName: string; aDefault: Integer; aMin: Integer;
  aMax: Integer): Integer;
var
  lValue: Integer;
begin
  Result := aDefault;
  if RequestInt(aRequest, aName, lValue) then
  begin
    Result := lValue;
  end;

  if Result < aMin then
  begin
    Result := aMin;
  end else if Result > aMax then
  begin
    Result := aMax;
  end;
end;

function MapDetailName(aDetail: TAccessibilityAgentBridgeMapDetail): string;
begin
  case aDetail of
    abmdGeometry:
      Result := 'geometry';
  else
    Result := 'full';
  end;
end;

function ControlHasDirectCaption(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomForm) or (aControl is TCustomLabel) or (aControl is TStaticText) or
    (aControl is TCustomButton) or (aControl is TCustomCheckBox) or (aControl is TRadioButton) or
    (aControl is TCustomGroupBox) or (aControl is TCustomPanel) or (aControl is TTabSheet) or
    (aControl is TSpeedButton) or (aControl is TToolButton);
end;

function ControlHasKnownEmptyCaption(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomEdit) or (aControl is TCustomComboBox) or (aControl is TCustomListBox) or
    (aControl is TPageControl) or (aControl is TToolBar) or (aControl is TCustomStatusBar) or
    (aControl is TStringGrid) or (aControl is TSplitter);
end;

function ControlHasKnownEmptyText(aControl: TControl): Boolean;
begin
  Result := ControlHasDirectCaption(aControl) or (aControl is TCustomListBox) or (aControl is TPageControl) or
    (aControl is TToolBar) or (aControl is TCustomStatusBar) or (aControl is TStringGrid) or (aControl is TSplitter);
end;

function TryReadDirectStringProperty(aObject: TObject; const aPropertyName: string; out aValue: string): Boolean;
var
  lControl: TControl;
begin
  Result := False;
  aValue := '';
  if not (aObject is TControl) then
  begin
    Exit;
  end;

  lControl := TControl(aObject);
  if (aPropertyName = 'Caption') and ControlHasDirectCaption(lControl) then
  begin
    aValue := TAccessibilityText.Clean(TAgentBridgeControlAccess(lControl).Caption);
    Exit(True);
  end;

  if (aPropertyName = 'Caption') and ControlHasKnownEmptyCaption(lControl) then
  begin
    Exit(True);
  end;

  if (aPropertyName = 'Text') and
    ((lControl is TCustomEdit) or (lControl is TCustomMemo) or (lControl is TCustomComboBox)) then
  begin
    aValue := TAccessibilityText.Clean(TAgentBridgeControlAccess(lControl).Text);
    Exit(True);
  end;

  if (aPropertyName = 'Text') and ControlHasKnownEmptyText(lControl) then
  begin
    Exit(True);
  end;

  if aPropertyName = 'Hint' then
  begin
    aValue := TAccessibilityText.Clean(lControl.Hint);
    Exit(True);
  end;

  if aPropertyName = 'TextHint' then
  begin
    if lControl is TCustomEdit then
    begin
      aValue := TAccessibilityText.Clean(TCustomEdit(lControl).TextHint);
      Exit(True);
    end;

    if lControl is TCustomComboBox then
    begin
      aValue := TAccessibilityText.Clean(TCustomComboBox(lControl).TextHint);
      Exit(True);
    end;
  end;
end;

function ReadStringProperty(aObject: TObject; const aPropertyName: string;
  aRttiCache: TAgentBridgeRttiPropertyCache): string;
var
  lPropInfo: PPropInfo;
begin
  Result := '';
  if TryReadDirectStringProperty(aObject, aPropertyName, Result) then
  begin
    Exit;
  end;

  if aRttiCache <> nil then
  begin
    lPropInfo := aRttiCache.Lookup(aObject, aPropertyName);
  end else begin
    TAccessibilityDiagnostics.RecordAgentBridgeRttiPropertyLookup;
    lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  end;
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    Result := TAccessibilityText.Clean(GetStrProp(aObject, lPropInfo));
  end;
end;

function TryReadBooleanProperty(aObject: TObject; const aPropertyName: string; out aValue: Boolean;
  aRttiCache: TAgentBridgeRttiPropertyCache): Boolean;
var
  lPropInfo: PPropInfo;
begin
  aValue := False;
  if aPropertyName = 'Checked' then
  begin
    if aObject is TCustomCheckBox then
    begin
      aValue := TAgentBridgeCheckBoxAccess(aObject).Checked;
      Exit(True);
    end;

    if aObject is TRadioButton then
    begin
      aValue := TRadioButton(aObject).Checked;
      Exit(True);
    end;
  end;

  if aRttiCache <> nil then
  begin
    lPropInfo := aRttiCache.Lookup(aObject, aPropertyName);
  end else begin
    TAccessibilityDiagnostics.RecordAgentBridgeRttiPropertyLookup;
    lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  end;
  Result := (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration);
  if Result then
  begin
    aValue := GetOrdProp(aObject, lPropInfo) <> 0;
  end;
end;

function TryReadOrdinalProperty(aObject: TObject; const aPropertyName: string; out aValue: Integer;
  aRttiCache: TAgentBridgeRttiPropertyCache): Boolean;
var
  lPropInfo: PPropInfo;
begin
  aValue := 0;
  if (aPropertyName = 'State') and (aObject is TCustomCheckBox) then
  begin
    aValue := Ord(TAgentBridgeCheckBoxAccess(aObject).State);
    Exit(True);
  end;

  if aRttiCache <> nil then
  begin
    lPropInfo := aRttiCache.Lookup(aObject, aPropertyName);
  end else begin
    TAccessibilityDiagnostics.RecordAgentBridgeRttiPropertyLookup;
    lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  end;
  Result := (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkInteger, tkEnumeration]);
  if Result then
  begin
    aValue := GetOrdProp(aObject, lPropInfo);
  end;
end;

function WriteStringProperty(aObject: TObject; const aPropertyName: string; const aValue: string): Boolean;
var
  lPropInfo: PPropInfo;
begin
  Result := False;
  if (aPropertyName = 'Text') and (aObject is TControl) and
    ((aObject is TCustomEdit) or (aObject is TCustomMemo) or (aObject is TCustomComboBox)) then
  begin
    TAgentBridgeControlAccess(aObject).Text := aValue;
    Exit(True);
  end;

  TAccessibilityDiagnostics.RecordAgentBridgeRttiPropertyLookup;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    SetStrProp(aObject, lPropInfo, aValue);
    Result := True;
  end;
end;

function NativeUiaControlTypeId(aControl: TControl): Integer;
begin
  if aControl is TCustomForm then
  begin
    Exit(UIA_WindowControlTypeId);
  end;

  if aControl is TRadioButton then
  begin
    Exit(UIA_RadioButtonControlTypeId);
  end;

  if aControl is TCustomCheckBox then
  begin
    Exit(UIA_CheckBoxControlTypeId);
  end;

  if aControl is TCustomComboBox then
  begin
    Exit(UIA_ComboBoxControlTypeId);
  end;

  if aControl is TCustomListBox then
  begin
    Exit(UIA_ListControlTypeId);
  end;

  if aControl is TCustomStatusBar then
  begin
    Exit(UIA_StatusBarControlTypeId);
  end;

  if aControl is TCustomEdit then
  begin
    Exit(UIA_EditControlTypeId);
  end;

  if (aControl is TSpeedButton) or (aControl is TCustomButton) or (aControl is TToolButton) then
  begin
    Exit(UIA_ButtonControlTypeId);
  end;

  if aControl is TToolBar then
  begin
    Exit(UIA_ToolBarControlTypeId);
  end;

  if aControl is TPageControl then
  begin
    Exit(UIA_TabControlTypeId);
  end;

  if aControl is TCustomGroupBox then
  begin
    Exit(UIA_GroupControlTypeId);
  end;

  if aControl is TStringGrid then
  begin
    Exit(UIA_DataGridControlTypeId);
  end;

  if aControl is TCustomPanel then
  begin
    Exit(UIA_PaneControlTypeId);
  end;

  if aControl is TTabSheet then
  begin
    Exit(UIA_TabItemControlTypeId);
  end;

  Result := UIA_TextControlTypeId;
end;

function NativeUiaControlTypeName(aControlTypeId: Integer): string;
begin
  case aControlTypeId of
    UIA_ButtonControlTypeId:
      Result := 'Button';
    UIA_CheckBoxControlTypeId:
      Result := 'CheckBox';
    UIA_ComboBoxControlTypeId:
      Result := 'ComboBox';
    UIA_DataGridControlTypeId:
      Result := 'DataGrid';
    UIA_EditControlTypeId:
      Result := 'Edit';
    UIA_GroupControlTypeId:
      Result := 'Group';
    UIA_ListControlTypeId:
      Result := 'List';
    UIA_ListItemControlTypeId:
      Result := 'ListItem';
    UIA_PaneControlTypeId:
      Result := 'Pane';
    UIA_RadioButtonControlTypeId:
      Result := 'RadioButton';
    UIA_StatusBarControlTypeId:
      Result := 'StatusBar';
    UIA_TabControlTypeId:
      Result := 'Tab';
    UIA_TabItemControlTypeId:
      Result := 'TabItem';
    UIA_TextControlTypeId:
      Result := 'Text';
    UIA_ToolBarControlTypeId:
      Result := 'ToolBar';
    UIA_WindowControlTypeId:
      Result := 'Window';
  else
    Result := 'Custom';
  end;
end;

function UiaRectJson(const aRect: UiaRect): TJSONObject;
var
  lHeight: Integer;
  lLeft: Integer;
  lTop: Integer;
  lWidth: Integer;
begin
  lLeft := Round(aRect.Left);
  lTop := Round(aRect.Top);
  lWidth := Round(aRect.Width);
  lHeight := Round(aRect.Height);

  Result := TJSONObject.Create;
  AddInt(Result, 'left', lLeft);
  AddInt(Result, 'top', lTop);
  AddInt(Result, 'right', lLeft + lWidth);
  AddInt(Result, 'bottom', lTop + lHeight);
  AddInt(Result, 'width', lWidth);
  AddInt(Result, 'height', lHeight);
end;

function TryVariantToInteger(const aValue: OleVariant; out aInteger: Integer): Boolean;
begin
  aInteger := 0;
  Result := (not VarIsEmpty(aValue)) and (not VarIsNull(aValue)) and TryStrToInt(VarToStr(aValue), aInteger);
end;

function TryProviderStringProperty(const aProvider: IRawElementProviderSimple;
  const aDirectAccess: IAccessibilityProviderDirectAccess; aPropertyId: PROPERTYID; out aValue: string): Boolean;
var
  lValue: OleVariant;
begin
  aValue := '';
  if aProvider = nil then
  begin
    Exit(False);
  end;

  if aDirectAccess <> nil then
  begin
    Exit(aDirectAccess.TryGetStringProperty(aPropertyId, aValue));
  end;

  if aProvider.GetPropertyValue(aPropertyId, lValue) <> S_OK then
  begin
    Exit(False);
  end;

  Result := (not VarIsEmpty(lValue)) and (not VarIsNull(lValue));
  if Result then
  begin
    aValue := VarToStr(lValue);
  end;
end;

function TryProviderIntegerProperty(const aProvider: IRawElementProviderSimple;
  const aDirectAccess: IAccessibilityProviderDirectAccess; aPropertyId: PROPERTYID; out aValue: Integer): Boolean;
var
  lValue: OleVariant;
begin
  aValue := 0;
  if aProvider = nil then
  begin
    Exit(False);
  end;

  if aDirectAccess <> nil then
  begin
    Exit(aDirectAccess.TryGetIntegerProperty(aPropertyId, aValue));
  end;

  if aProvider.GetPropertyValue(aPropertyId, lValue) <> S_OK then
  begin
    Exit(False);
  end;

  Result := TryVariantToInteger(lValue, aValue);
end;

function TryProviderNativeWindowHandle(const aDirectAccess: IAccessibilityProviderDirectAccess;
  out aValue: HWND): Boolean;
begin
  aValue := 0;
  Result := (aDirectAccess <> nil) and aDirectAccess.TryGetNativeWindowHandle(aValue);
end;

function TryProviderValueText(const aDirectAccess: IAccessibilityProviderDirectAccess; out aValue: string): Boolean;
begin
  aValue := '';
  Result := (aDirectAccess <> nil) and aDirectAccess.TryGetValueText(aValue);
end;

function TryProviderBoundingRectangle(const aProvider: IRawElementProviderSimple;
  const aGeometryAccess: IAccessibilityProviderGeometryAccess; out aValue: UiaRect): Boolean;
var
  lFragment: IRawElementProviderFragment;
begin
  aValue := Default(UiaRect);
  if aProvider = nil then
  begin
    Exit(False);
  end;

  if (aGeometryAccess <> nil) and aGeometryAccess.TryGetBoundingRectangle(aValue) then
  begin
    Exit(True);
  end;

  Result := Supports(aProvider, IRawElementProviderFragment, lFragment) and
    (lFragment.Get_BoundingRectangle(aValue) = S_OK);
end;

procedure AddProviderVclInfo(aJson: TJSONObject; const aInfo: IAccessibilityVclControlProviderInfo);
var
  lControl: TControl;
begin
  if aInfo = nil then
  begin
    Exit;
  end;

  lControl := aInfo.Control;
  if lControl = nil then
  begin
    Exit;
  end;

  aJson.AddPair('vclName', lControl.Name);
  aJson.AddPair('vclClassName', lControl.ClassName);
end;

function ProviderNodeJson(const aProvider: IRawElementProviderSimple; aDepth: Integer; aMaxDepth: Integer;
  aMaxChildren: Integer; aDetail: TAccessibilityAgentBridgeMapDetail; var aNodeCount: Integer): TJSONObject;
var
  i: Integer;
  lChild: IRawElementProviderSimple;
  lChildAccess: IAccessibilityProviderChildAccess;
  lChildCount: Integer;
  lChildren: TJSONArray;
  lControlTypeId: Integer;
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lGeometryAccess: IAccessibilityProviderGeometryAccess;
  lHwnd: HWND;
  lRect: UiaRect;
  lText: string;
  lVclInfo: IAccessibilityVclControlProviderInfo;
begin
  Inc(aNodeCount);
  Result := TJSONObject.Create;
  AddInt(Result, 'depth', aDepth);

  Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess);
  Supports(aProvider, IAccessibilityProviderGeometryAccess, lGeometryAccess);
  if aDetail = abmdFull then
  begin
    Supports(aProvider, IAccessibilityVclControlProviderInfo, lVclInfo);
  end;

  if TryProviderBoundingRectangle(aProvider, lGeometryAccess, lRect) then
  begin
    Result.AddPair('screenRect', UiaRectJson(lRect));
  end else begin
    Result.AddPair('screenRect', RectJson(Rect(0, 0, 0, 0)));
  end;

  if TryProviderIntegerProperty(aProvider, lDirectAccess, UIA_ControlTypePropertyId, lControlTypeId) then
  begin
    AddInt(Result, 'uiaControlTypeId', lControlTypeId);
    Result.AddPair('uiaControlType', NativeUiaControlTypeName(lControlTypeId));
  end else begin
    AddInt(Result, 'uiaControlTypeId', UIA_CustomControlTypeId);
    Result.AddPair('uiaControlType', NativeUiaControlTypeName(UIA_CustomControlTypeId));
  end;

  if TryProviderNativeWindowHandle(lDirectAccess, lHwnd) then
  begin
    AddUInt(Result, 'handle', UInt64(NativeUInt(lHwnd)));
  end else begin
    AddUInt(Result, 'handle', 0);
  end;

  if aDetail = abmdFull then
  begin
    if TryProviderStringProperty(aProvider, lDirectAccess, UIA_NamePropertyId, lText) then
    begin
      Result.AddPair('name', lText);
    end else begin
      Result.AddPair('name', '');
    end;

    if TryProviderStringProperty(aProvider, lDirectAccess, UIA_AutomationIdPropertyId, lText) then
    begin
      Result.AddPair('automationId', lText);
    end else begin
      Result.AddPair('automationId', '');
    end;

    if TryProviderStringProperty(aProvider, lDirectAccess, UIA_ClassNamePropertyId, lText) then
    begin
      Result.AddPair('className', lText);
    end else begin
      Result.AddPair('className', '');
    end;

    if TryProviderStringProperty(aProvider, lDirectAccess, UIA_FrameworkIdPropertyId, lText) then
    begin
      Result.AddPair('frameworkId', lText);
    end else begin
      Result.AddPair('frameworkId', '');
    end;

    if TryProviderStringProperty(aProvider, lDirectAccess, UIA_HelpTextPropertyId, lText) then
    begin
      Result.AddPair('helpText', lText);
    end else begin
      Result.AddPair('helpText', '');
    end;

    if TryProviderValueText(lDirectAccess, lText) then
    begin
      Result.AddPair('value', lText);
    end else begin
      Result.AddPair('value', '');
    end;

    AddProviderVclInfo(Result, lVclInfo);
  end;

  lChildren := TJSONArray.Create;
  Result.AddPair('children', lChildren);
  lChildCount := 0;
  if aDepth >= aMaxDepth then
  begin
    AddInt(Result, 'childCount', lChildCount);
    AddBool(Result, 'childrenTruncated', False);
    AddBool(Result, 'depthTruncated', True);
    Exit;
  end;

  if not Supports(aProvider, IAccessibilityProviderChildAccess, lChildAccess) or
    (lChildAccess.DirectChildCount(lChildCount) <> S_OK) then
  begin
    lChildCount := 0;
    AddInt(Result, 'childCount', lChildCount);
    AddBool(Result, 'childrenTruncated', False);
    Exit;
  end;

  AddInt(Result, 'childCount', lChildCount);
  AddBool(Result, 'childrenTruncated', lChildCount > aMaxChildren);

  for i := 0 to Pred(lChildCount) do
  begin
    if i >= aMaxChildren then
    begin
      Break;
    end;

    if (lChildAccess.DirectChildAt(i, lChild) = S_OK) and (lChild <> nil) then
    begin
      lChildren.AddElement(ProviderNodeJson(lChild, Succ(aDepth), aMaxDepth, aMaxChildren, aDetail, aNodeCount));
    end;
  end;
end;

class function TAccessibilityAgentBridgeInternals.SerializeProviderNode(const aProvider: IRawElementProviderSimple;
  aFullDetail: Boolean; aMaxDepth: Integer; aMaxChildren: Integer): string;
var
  lDetail: TAccessibilityAgentBridgeMapDetail;
  lNodeCount: Integer;
  lRoot: TJSONObject;
begin
  if aFullDetail then
  begin
    lDetail := abmdFull;
  end else begin
    lDetail := abmdGeometry;
  end;

  lNodeCount := 0;
  lRoot := ProviderNodeJson(aProvider, 0, aMaxDepth, aMaxChildren, lDetail, lNodeCount);
  Result := JsonObjectToString(lRoot);
end;

function CheckBoxStateName(aState: Integer; aChecked: Boolean): string;
begin
  case aState of
    1:
      Result := 'on';
    2:
      Result := 'indeterminate';
  else
    if aChecked then
    begin
      Result := 'on';
    end else begin
      Result := 'off';
    end;
  end;
end;

procedure AddNativeControlState(aJson: TJSONObject; aControl: TControl; aRttiCache: TAgentBridgeRttiPropertyCache);
var
  lChecked: Boolean;
  lCheckBox: TCustomCheckBox;
  lComboBox: TCustomComboBox;
  lListBox: TCustomListBox;
  lPageControl: TPageControl;
  lRadioButton: TRadioButton;
  lSelected: Boolean;
  lState: TJSONObject;
  lStateValue: Integer;
begin
  lState := TJSONObject.Create;
  if aControl is TCustomCheckBox then
  begin
    lCheckBox := TCustomCheckBox(aControl);
    TryReadBooleanProperty(lCheckBox, 'Checked', lChecked, aRttiCache);
    if not TryReadOrdinalProperty(lCheckBox, 'State', lStateValue, aRttiCache) then
    begin
      lStateValue := -1;
    end;

    AddBool(lState, 'checked', lChecked);
    lState.AddPair('toggleState', CheckBoxStateName(lStateValue, lChecked));
  end else if aControl is TRadioButton then
  begin
    lRadioButton := TRadioButton(aControl);
    TryReadBooleanProperty(lRadioButton, 'Checked', lSelected, aRttiCache);
    AddBool(lState, 'selected', lSelected);
  end else if aControl is TCustomListBox then
  begin
    lListBox := TCustomListBox(aControl);
    AddInt(lState, 'itemCount', lListBox.Items.Count);
    AddInt(lState, 'itemIndex', lListBox.ItemIndex);
    if (lListBox.ItemIndex >= 0) and (lListBox.ItemIndex < lListBox.Items.Count) then
    begin
      lState.AddPair('selectedText', TAccessibilityText.Clean(lListBox.Items[lListBox.ItemIndex]));
    end else begin
      lState.AddPair('selectedText', '');
    end;
  end else if aControl is TCustomComboBox then
  begin
    lComboBox := TCustomComboBox(aControl);
    AddInt(lState, 'itemCount', lComboBox.Items.Count);
    AddInt(lState, 'itemIndex', lComboBox.ItemIndex);
    if (lComboBox.ItemIndex >= 0) and (lComboBox.ItemIndex < lComboBox.Items.Count) then
    begin
      lState.AddPair('selectedText', TAccessibilityText.Clean(lComboBox.Items[lComboBox.ItemIndex]));
    end else begin
      lState.AddPair('selectedText', TAccessibilityText.Clean(ReadStringProperty(lComboBox, 'Text', aRttiCache)));
    end;
  end else if aControl is TPageControl then
  begin
    lPageControl := TPageControl(aControl);
    AddInt(lState, 'activePageIndex', lPageControl.ActivePageIndex);
    if lPageControl.ActivePage <> nil then
    begin
      lState.AddPair('activePageName', lPageControl.ActivePage.Name);
      lState.AddPair('activePageCaption', TAccessibilityText.Clean(lPageControl.ActivePage.Caption));
    end else begin
      lState.AddPair('activePageName', '');
      lState.AddPair('activePageCaption', '');
    end;
  end;

  aJson.AddPair('state', lState);
end;

function BridgeState: TAccessibilityAgentBridgeState;
begin
  if gBridgeState = nil then
  begin
    gBridgeState := TAccessibilityAgentBridgeState.Create;
  end;
  Result := gBridgeState;
end;

function TAccessibilityAgentBridgeState.BuildControlInfo(aControl: TControl; aIncludeAccessibility: Boolean;
  aDetail: TAccessibilityAgentBridgeMapDetail): string;
var
  lControl: TJSONObject;
  lFocusedHandle: HWND;
  lForm: TCustomForm;
  lIncludeAccessibility: Boolean;
  lRect: TRect;
  lResponse: TJSONObject;
  lRttiCache: TAgentBridgeRttiPropertyCache;
  lTree: IAccessibilityScanTree;
  lRef: string;
begin
  lRttiCache := TAgentBridgeRttiPropertyCache.Create;
  try
    lTree := nil;
    lIncludeAccessibility := aIncludeAccessibility and (aDetail = abmdFull);
    if lIncludeAccessibility then
    begin
      if aControl is TCustomForm then
      begin
        lForm := TCustomForm(aControl);
      end else begin
        lForm := GetParentForm(aControl, False);
      end;

      if lForm <> nil then
      begin
        lTree := TAccessibilityScanner.ScanForm(lForm);
      end else begin
        lIncludeAccessibility := False;
      end;
    end;

    lRect := ControlScreenRectFromSnapshot(aControl);
    TAccessibilityDiagnostics.RecordAgentBridgeFocusProbe;
    lFocusedHandle := GetFocus;
    lControl := ControlJson(aControl, '', 0, lRect, lTree, aDetail, lFocusedHandle, lRttiCache, lRef);
    lResponse := TJSONObject.Create;
    AddBool(lResponse, 'ok', True);
    lResponse.AddPair('cmd', 'control.info');
    AddInt(lResponse, 'protocolVersion', 1);
    AddBool(lResponse, 'includeAccessibility', lIncludeAccessibility);
    lResponse.AddPair('detail', MapDetailName(aDetail));
    AddInt(lResponse, 'snapshotId', fSnapshotId);
    lResponse.AddPair('control', lControl);
    Result := JsonObjectToString(lResponse);
  finally
    lRttiCache.Free;
  end;
end;

function TAccessibilityAgentBridgeState.BuildControlsInfo(aRefs: TJSONArray; aIncludeAccessibility: Boolean;
  aDetail: TAccessibilityAgentBridgeMapDetail): string;
var
  i: Integer;
  lControl: TControl;
  lControls: TJSONArray;
  lForm: TCustomForm;
  lFocusedHandle: HWND;
  lIgnoredRef: string;
  lIncludeAccessibility: Boolean;
  lRect: TRect;
  lRef: string;
  lResolvedControls: TList<TControl>;
  lResponse: TJSONObject;
  lRttiCache: TAgentBridgeRttiPropertyCache;
  lTree: IAccessibilityScanTree;
begin
  if (aRefs = nil) or (aRefs.Count = 0) then
  begin
    Exit(Failure('invalid_request', 'controls.info requires at least one ref.'));
  end;

  lResolvedControls := TList<TControl>.Create;
  try
    for i := 0 to Pred(aRefs.Count) do
    begin
      lRef := aRefs.Items[i].Value;
      if (lRef = '') or (not fControlsByRef.TryGetValue(lRef, lControl)) or (lControl = nil) or
        (csDestroying in lControl.ComponentState) then
      begin
        Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive: ' + lRef));
      end;
      lResolvedControls.Add(lControl);
    end;

    lRttiCache := TAgentBridgeRttiPropertyCache.Create;
    try
      lTree := nil;
      lIncludeAccessibility := aIncludeAccessibility and (aDetail = abmdFull);
      if lIncludeAccessibility then
      begin
        lForm := fForm;
        if lForm = nil then
        begin
          lControl := lResolvedControls[0];
          if lControl is TCustomForm then
          begin
            lForm := TCustomForm(lControl);
          end else begin
            lForm := GetParentForm(lControl, False);
          end;
        end;

        if lForm <> nil then
        begin
          lTree := TAccessibilityScanner.ScanForm(lForm);
        end else begin
          lIncludeAccessibility := False;
        end;
      end;

      TAccessibilityDiagnostics.RecordAgentBridgeFocusProbe;
      lFocusedHandle := GetFocus;
      lControls := TJSONArray.Create;
      for i := 0 to Pred(lResolvedControls.Count) do
      begin
        lControl := lResolvedControls[i];
        lRect := ControlScreenRectFromSnapshot(lControl);
        lControls.AddElement(ControlJson(lControl, '', 0, lRect, lTree, aDetail, lFocusedHandle, lRttiCache,
          lIgnoredRef));
      end;

      lResponse := TJSONObject.Create;
      AddBool(lResponse, 'ok', True);
      lResponse.AddPair('cmd', 'controls.info');
      AddInt(lResponse, 'protocolVersion', 1);
      AddBool(lResponse, 'includeAccessibility', lIncludeAccessibility);
      lResponse.AddPair('detail', MapDetailName(aDetail));
      AddInt(lResponse, 'snapshotId', fSnapshotId);
      lResponse.AddPair('controls', lControls);
      Result := JsonObjectToString(lResponse);
    finally
      lRttiCache.Free;
    end;
  finally
    lResolvedControls.Free;
  end;
end;

constructor TAccessibilityAgentBridgeState.Create;
begin
  inherited Create(nil);
  fControlsByRef := TDictionary<string, TControl>.Create;
  fObservedControls := TList<TComponent>.Create;
  fRefsByControl := TDictionary<TControl, string>.Create;
  fScreenRectsByControl := TDictionary<TControl, TRect>.Create;
end;

destructor TAccessibilityAgentBridgeState.Destroy;
begin
  ClearSnapshot;
  fScreenRectsByControl.Free;
  fRefsByControl.Free;
  fObservedControls.Free;
  fControlsByRef.Free;
  inherited Destroy;
end;

procedure TAccessibilityAgentBridgeState.AddChildControls(aParent: TWinControl; const aParentRef: string;
  aDepth: Integer; const aParentClientOrigin: TPoint; aControls: TJSONArray; const aTree: IAccessibilityScanTree;
  aVisibleOnly: Boolean; aDetail: TAccessibilityAgentBridgeMapDetail; aFocusedHandle: HWND;
  aRttiCache: TAgentBridgeRttiPropertyCache);
var
  i: Integer;
  lChild: TControl;
  lChildClientOrigin: TPoint;
  lChildRef: string;
  lChildRect: TRect;
  lWinControl: TWinControl;
begin
  for i := 0 to Pred(aParent.ControlCount) do
  begin
    lChild := aParent.Controls[i];
    if aVisibleOnly and not ControlIsVisibleChildInActivePage(lChild) then
    begin
      Continue;
    end;

    lChildRect := ControlScreenRectFromParentOrigin(lChild, aParentClientOrigin);
    aControls.AddElement(ControlJson(lChild, aParentRef, aDepth, lChildRect, aTree, aDetail, aFocusedHandle,
      aRttiCache, lChildRef));
    if lChild is TWinControl then
    begin
      lWinControl := TWinControl(lChild);
      if lWinControl.ControlCount > 0 then
      begin
        lChildClientOrigin := ControlClientOriginForChildren(lWinControl, lChildRect);
        AddChildControls(lWinControl, lChildRef, Succ(aDepth), lChildClientOrigin, aControls, aTree, aVisibleOnly,
          aDetail, aFocusedHandle, aRttiCache);
      end;
    end;
  end;
end;

procedure TAccessibilityAgentBridgeState.AddControlState(aJson: TJSONObject; aControl: TControl;
  const aTree: IAccessibilityScanTree; aRttiCache: TAgentBridgeRttiPropertyCache);
var
  lNode: IAccessibilityScanNode;
begin
  aJson.AddPair('caption', ReadStringProperty(aControl, 'Caption', aRttiCache));
  aJson.AddPair('value', ReadStringProperty(aControl, 'Text', aRttiCache));
  aJson.AddPair('hint', TAccessibilityText.Clean(aControl.Hint));

  lNode := nil;
  if aTree <> nil then
  begin
    lNode := aTree.FindNode(aControl);
  end;
  if lNode <> nil then
  begin
    aJson.AddPair('accessibleName', lNode.Name);
    aJson.AddPair('helpText', lNode.HelpText);
  end else begin
    aJson.AddPair('accessibleName', '');
    aJson.AddPair('helpText', '');
  end;

  AddNativeControlState(aJson, aControl, aRttiCache);
end;

procedure TAccessibilityAgentBridgeState.AddControlTargeting(aJson: TJSONObject; aControl: TControl;
  const aScreenRect: TRect; aFocusedHandle: HWND);
var
  lControlTypeId: Integer;
  lTargetPoints: TJSONObject;
  lWindowHandle: HWND;
begin
  aJson.AddPair('name', aControl.Name);
  aJson.AddPair('className', aControl.ClassName);
  lControlTypeId := NativeUiaControlTypeId(aControl);
  AddInt(aJson, 'uiaControlTypeId', lControlTypeId);
  aJson.AddPair('uiaControlType', NativeUiaControlTypeName(lControlTypeId));
  AddBool(aJson, 'visible', aControl.Visible);
  AddBool(aJson, 'enabled', aControl.Enabled);

  lWindowHandle := 0;
  if aControl is TWinControl then
  begin
    if TWinControl(aControl).HandleAllocated then
    begin
      lWindowHandle := TAgentBridgeWinControlAccess(aControl).WindowHandle;
    end;
    AddBool(aJson, 'focused', (lWindowHandle <> 0) and (lWindowHandle = aFocusedHandle));
    AddBool(aJson, 'tabStop', TWinControl(aControl).TabStop);
    AddInt(aJson, 'tabOrder', TWinControl(aControl).TabOrder);
    AddUInt(aJson, 'handle', UInt64(NativeUInt(lWindowHandle)));
  end else begin
    AddBool(aJson, 'focused', False);
    AddBool(aJson, 'tabStop', False);
    AddInt(aJson, 'tabOrder', -1);
    AddUInt(aJson, 'handle', 0);
  end;

  aJson.AddPair('screenRect', RectJson(aScreenRect));

  lTargetPoints := TJSONObject.Create;
  lTargetPoints.AddPair('center',
    PointJson(Point(aScreenRect.Left + (aScreenRect.Width div 2), aScreenRect.Top + (aScreenRect.Height div 2))));
  aJson.AddPair('targetPoints', lTargetPoints);
end;

function TAccessibilityAgentBridgeState.BuildFormMap(aForm: TCustomForm; aIncludeAccessibility: Boolean;
  aVisibleOnly: Boolean; aDetail: TAccessibilityAgentBridgeMapDetail): string;
var
  lControls: TJSONArray;
  lFocusedHandle: HWND;
  lFormClientOrigin: TPoint;
  lIncludeAccessibility: Boolean;
  lFormRef: string;
  lResponse: TJSONObject;
  lRttiCache: TAgentBridgeRttiPropertyCache;
  lRoot: TJSONObject;
  lRootRect: TRect;
  lStopwatch: TStopwatch;
  lTree: IAccessibilityScanTree;
begin
  lRttiCache := TAgentBridgeRttiPropertyCache.Create;
  try
    lStopwatch := TStopwatch.StartNew;
    ClearSnapshot;
    Inc(fSnapshotId);
    fForm := aForm;
    fNextRefIndex := 0;
    lTree := nil;
    lIncludeAccessibility := aIncludeAccessibility and (aDetail = abmdFull);
    if lIncludeAccessibility then
    begin
      lTree := TAccessibilityScanner.ScanForm(aForm);
    end;

    lRootRect := ControlScreenRect(aForm);
    TAccessibilityDiagnostics.RecordAgentBridgeFocusProbe;
    lFocusedHandle := GetFocus;
    lRoot := ControlJson(aForm, '', 0, lRootRect, lTree, aDetail, lFocusedHandle, lRttiCache, lFormRef);
    lFormClientOrigin := ControlClientOriginForChildren(aForm, lRootRect);
    lControls := TJSONArray.Create;
    AddChildControls(aForm, lFormRef, 1, lFormClientOrigin, lControls, lTree, aVisibleOnly, aDetail,
      lFocusedHandle, lRttiCache);

    lResponse := TJSONObject.Create;
    AddBool(lResponse, 'ok', True);
    lResponse.AddPair('cmd', 'form.map');
    AddInt(lResponse, 'protocolVersion', 1);
    AddBool(lResponse, 'includeAccessibility', lIncludeAccessibility);
    AddBool(lResponse, 'visibleOnly', aVisibleOnly);
    lResponse.AddPair('detail', MapDetailName(aDetail));
    AddInt(lResponse, 'snapshotId', fSnapshotId);
    lResponse.AddPair('refModel', 'snapshot');
    AddInt(lResponse, 'elapsedMs', lStopwatch.ElapsedMilliseconds);
    AddInt(lResponse, 'elapsedTicks', lStopwatch.ElapsedTicks);
    AddInt(lResponse, 'stopwatchFrequency', TStopwatch.Frequency);
    lResponse.AddPair('form', lRoot);
    lResponse.AddPair('controls', lControls);
    Result := JsonObjectToString(lResponse);
  finally
    lRttiCache.Free;
  end;
end;

function TAccessibilityAgentBridgeState.BuildProviderMap(aForm: TCustomForm; aDetail: TAccessibilityAgentBridgeMapDetail;
  aMaxDepth: Integer; aMaxChildren: Integer): string;
var
  lNodeCount: Integer;
  lOwnsProvider: Boolean;
  lProvider: IAccessibilityProviderNode;
  lProviderSource: string;
  lRawProvider: IRawElementProviderSimple;
  lResponse: TJSONObject;
  lRoot: TJSONObject;
  lStopwatch: TStopwatch;
begin
  lStopwatch := TStopwatch.StartNew;
  lProvider := nil;
  lOwnsProvider := False;
  if TAccessibilityManagerInternals.TryGetInstalledFormProvider(aForm, lRawProvider) then
  begin
    lProviderSource := 'installed';
  end else begin
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(aForm);
    lRawProvider := lProvider.RawElementProvider;
    lProviderSource := 'transient';
    lOwnsProvider := True;
  end;
  try
    lNodeCount := 0;
    lRoot := ProviderNodeJson(lRawProvider, 0, aMaxDepth, aMaxChildren, aDetail, lNodeCount);

    lResponse := TJSONObject.Create;
    AddBool(lResponse, 'ok', True);
    lResponse.AddPair('cmd', 'provider.map');
    AddInt(lResponse, 'protocolVersion', 1);
    lResponse.AddPair('source', 'maxlogic-provider');
    lResponse.AddPair('providerTreeSource', lProviderSource);
    lResponse.AddPair('detail', MapDetailName(aDetail));
    AddInt(lResponse, 'maxDepth', aMaxDepth);
    AddInt(lResponse, 'maxChildren', aMaxChildren);
    AddInt(lResponse, 'nodeCount', lNodeCount);
    AddInt(lResponse, 'elapsedMs', lStopwatch.ElapsedMilliseconds);
    AddInt(lResponse, 'elapsedTicks', lStopwatch.ElapsedTicks);
    AddInt(lResponse, 'stopwatchFrequency', TStopwatch.Frequency);
    lResponse.AddPair('root', lRoot);
    Result := JsonObjectToString(lResponse);
  finally
    if lOwnsProvider and (lProvider <> nil) then
    begin
      lProvider.Disconnect;
    end;
  end;
end;

procedure TAccessibilityAgentBridgeState.ClearSnapshot;
var
  i: Integer;
begin
  for i := 0 to Pred(fObservedControls.Count) do
  begin
    fObservedControls[i].RemoveFreeNotification(Self);
  end;

  fObservedControls.Clear;
  fControlsByRef.Clear;
  fRefsByControl.Clear;
  fScreenRectsByControl.Clear;
  fForm := nil;
  fNextRefIndex := 0;
end;

function TAccessibilityAgentBridgeState.ControlAtScreenPoint(aParent: TWinControl; const aPoint: TPoint): TControl;
var
  i: Integer;
  lChild: TControl;
  lChildRect: TRect;
  lNested: TControl;
begin
  Result := nil;
  if (aParent = nil) or (not aParent.Visible and not (aParent is TCustomForm)) then
  begin
    Exit;
  end;

  for i := Pred(aParent.ControlCount) downto 0 do
  begin
    lChild := aParent.Controls[i];
    if not lChild.Visible then
    begin
      Continue;
    end;

    lChildRect := ControlScreenRectFromSnapshot(lChild);
    if not lChildRect.Contains(aPoint) then
    begin
      Continue;
    end;

    if lChild is TWinControl then
    begin
      lNested := ControlAtScreenPoint(TWinControl(lChild), aPoint);
      if lNested <> nil then
      begin
        Exit(lNested);
      end;
    end;

    Exit(lChild);
  end;

  if ControlScreenRectFromSnapshot(aParent).Contains(aPoint) then
  begin
    Result := aParent;
  end;
end;

function TAccessibilityAgentBridgeState.ControlIsVisibleChildInActivePage(aControl: TControl): Boolean;
var
  lTabSheet: TTabSheet;
begin
  Result := False;

  if aControl = nil then
  begin
    Exit;
  end;

  if not (aControl is TCustomForm) and not aControl.Visible then
  begin
    Exit;
  end;

  if aControl is TTabSheet then
  begin
    lTabSheet := TTabSheet(aControl);
    if (lTabSheet.PageControl <> nil) and (lTabSheet.PageControl.ActivePage <> lTabSheet) then
    begin
      Exit;
    end;
  end;

  Result := True;
end;

function TAccessibilityAgentBridgeState.ControlJson(aControl: TControl; const aParentRef: string; aDepth: Integer;
  const aScreenRect: TRect; const aTree: IAccessibilityScanTree; aDetail: TAccessibilityAgentBridgeMapDetail;
  aFocusedHandle: HWND; aRttiCache: TAgentBridgeRttiPropertyCache; out aRef: string): TJSONObject;
begin
  aRef := RegisterControl(aControl);
  fScreenRectsByControl.Remove(aControl);
  fScreenRectsByControl.Add(aControl, aScreenRect);
  Result := TJSONObject.Create;
  Result.AddPair('ref', aRef);
  if aParentRef <> '' then
  begin
    Result.AddPair('parentRef', aParentRef);
  end;
  AddInt(Result, 'depth', aDepth);
  AddControlTargeting(Result, aControl, aScreenRect, aFocusedHandle);
  if aDetail = abmdFull then
  begin
    AddControlState(Result, aControl, aTree, aRttiCache);
  end;
end;

function TAccessibilityAgentBridgeState.ControlClientOriginForChildren(aControl: TControl;
  const aScreenRect: TRect): TPoint;
begin
  if aControl is TCustomPanel then
  begin
    Exit(aScreenRect.TopLeft);
  end;

  if (aControl is TWinControl) and TWinControl(aControl).HandleAllocated then
  begin
    TAccessibilityDiagnostics.RecordAgentBridgeChildClientOriginProbe;
    Exit(aControl.ClientToScreen(Point(0, 0)));
  end;

  Result := aScreenRect.TopLeft;
end;

function TAccessibilityAgentBridgeState.ControlScreenRect(aControl: TControl): TRect;
var
  lControl: TControl;
  lForm: TCustomForm;
  lLeft: Integer;
  lOrigin: TPoint;
  lTop: Integer;
begin
  if aControl = nil then
  begin
    Exit(Rect(0, 0, 0, 0));
  end;

  TAccessibilityDiagnostics.RecordAgentBridgeScreenRectProbe;
  if (aControl is TCustomForm) or ((aControl is TWinControl) and TWinControl(aControl).HandleAllocated) then
  begin
    Exit(aControl.ClientToScreen(Rect(0, 0, aControl.Width, aControl.Height)));
  end;

  lForm := GetParentForm(aControl, False);
  if (lForm = nil) or not lForm.HandleAllocated then
  begin
    Exit(Rect(aControl.Left, aControl.Top, aControl.Left + aControl.Width, aControl.Top + aControl.Height));
  end;

  lLeft := 0;
  lTop := 0;
  lControl := aControl;
  while (lControl <> nil) and (lControl <> lForm) do
  begin
    Inc(lLeft, lControl.Left);
    Inc(lTop, lControl.Top);
    lControl := lControl.Parent;
  end;

  lOrigin := lForm.ClientToScreen(Point(0, 0));
  Result := Rect(lOrigin.X + lLeft, lOrigin.Y + lTop, lOrigin.X + lLeft + aControl.Width,
    lOrigin.Y + lTop + aControl.Height);
end;

function TAccessibilityAgentBridgeState.ControlScreenRectFromParentOrigin(aControl: TControl;
  const aParentClientOrigin: TPoint): TRect;
begin
  if aControl = nil then
  begin
    Exit(Rect(0, 0, 0, 0));
  end;

  Result := Rect(aParentClientOrigin.X + aControl.Left, aParentClientOrigin.Y + aControl.Top,
    aParentClientOrigin.X + aControl.Left + aControl.Width, aParentClientOrigin.Y + aControl.Top + aControl.Height);
end;

function TAccessibilityAgentBridgeState.ControlScreenRectFromSnapshot(aControl: TControl): TRect;
begin
  if (aControl <> nil) and fScreenRectsByControl.TryGetValue(aControl, Result) then
  begin
    Exit;
  end;

  Result := ControlScreenRect(aControl);
end;

function TAccessibilityAgentBridgeState.Execute(aRequest: TJSONObject): string;
var
  lCommand: string;
begin
  lCommand := RequestString(aRequest, 'cmd');
  if lCommand = 'hello' then
  begin
    Result := ExecuteHello;
  end else if lCommand = 'forms.list' then
  begin
    Result := ExecuteFormsList;
  end else if lCommand = 'window.info' then
  begin
    Result := ExecuteWindowInfo(aRequest);
  end else if lCommand = 'form.map' then
  begin
    Result := ExecuteFormMap(aRequest);
  end else if lCommand = 'provider.map' then
  begin
    Result := ExecuteProviderMap(aRequest);
  end else if lCommand = 'control.info' then
  begin
    Result := ExecuteControlInfo(aRequest);
  end else if lCommand = 'controls.info' then
  begin
    Result := ExecuteControlsInfo(aRequest);
  end else if lCommand = 'hitTest' then
  begin
    Result := ExecuteHitTest(aRequest);
  end else if lCommand = 'control.focus' then
  begin
    Result := ExecuteFocus(aRequest);
  end else if lCommand = 'control.click' then
  begin
    Result := ExecuteClick(aRequest);
  end else if lCommand = 'control.setText' then
  begin
    Result := ExecuteSetText(aRequest, False);
  end else if lCommand = 'control.typeText' then
  begin
    Result := ExecuteSetText(aRequest, True);
  end else if lCommand = 'keyboard.tab' then
  begin
    Result := ExecuteKeyboardTab(aRequest);
  end else if lCommand = 'diagnostics.providerHotspots' then
  begin
    Result := ExecuteProviderHotspots;
  end else if lCommand = 'diagnostics.providerHotspots.enable' then
  begin
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    Result := SuccessCommand(lCommand);
  end else if lCommand = 'diagnostics.providerHotspots.reset' then
  begin
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    Result := SuccessCommand(lCommand);
  end else if lCommand = 'diagnostics.providerHotspots.disable' then
  begin
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    Result := SuccessCommand(lCommand);
  end else begin
    Result := Failure('unknown_command', 'Unknown agent bridge command: ' + lCommand);
  end;
end;

function TAccessibilityAgentBridgeState.ExecuteClick(aRequest: TJSONObject): string;
var
  lControl: TControl;
  lMouseParam: LPARAM;
  lPoint: TPoint;
  lWinControl: TWinControl;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  if not ResolveControl(aRequest, lControl) then
  begin
    Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive.'));
  end;

  if lControl is TButton then
  begin
    TButton(lControl).Click;
    Exit(SuccessMutation);
  end;

  if not (lControl is TWinControl) then
  begin
    Exit(Failure('unsupported_control', 'Control does not support diagnostic click.'));
  end;

  lWinControl := TWinControl(lControl);
  lWinControl.HandleNeeded;
  lPoint := Point(lWinControl.Width div 2, lWinControl.Height div 2);
  lMouseParam := MakeLParam(Word(lPoint.X), Word(lPoint.Y));
  lWinControl.Perform(WM_LBUTTONDOWN, MK_LBUTTON, lMouseParam);
  lWinControl.Perform(WM_LBUTTONUP, 0, lMouseParam);
  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.ExecuteControlInfo(aRequest: TJSONObject): string;
var
  lControl: TControl;
begin
  if not ResolveControl(aRequest, lControl) then
  begin
    Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive.'));
  end;

  Result := BuildControlInfo(lControl, RequestBool(aRequest, 'includeAccessibility', False),
    RequestMapDetail(aRequest));
end;

function TAccessibilityAgentBridgeState.ExecuteControlsInfo(aRequest: TJSONObject): string;
begin
  Result := BuildControlsInfo(RequestArray(aRequest, 'refs'), RequestBool(aRequest, 'includeAccessibility', False),
    RequestMapDetail(aRequest));
end;

function TAccessibilityAgentBridgeState.ExecuteFocus(aRequest: TJSONObject): string;
var
  lControl: TControl;
  lWinControl: TWinControl;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  if not ResolveControl(aRequest, lControl) then
  begin
    Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive.'));
  end;

  if not (lControl is TWinControl) then
  begin
    Exit(Failure('unsupported_control', 'Control does not support focus.'));
  end;

  lWinControl := TWinControl(lControl);
  FocusWinControl(lWinControl);

  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.ExecuteFormMap(aRequest: TJSONObject): string;
var
  lForm: TCustomForm;
begin
  lForm := ResolveForm(aRequest);
  if lForm = nil then
  begin
    Exit(Failure('form_not_found', 'Requested form was not found.'));
  end;

  Result := BuildFormMap(lForm, RequestBool(aRequest, 'includeAccessibility', True),
    RequestBool(aRequest, 'visibleOnly', False), RequestMapDetail(aRequest));
end;

function TAccessibilityAgentBridgeState.ExecuteProviderMap(aRequest: TJSONObject): string;
var
  lForm: TCustomForm;
begin
  lForm := ResolveForm(aRequest);
  if lForm = nil then
  begin
    Exit(Failure('form_not_found', 'Requested form was not found.'));
  end;

  Result := BuildProviderMap(lForm, RequestMapDetail(aRequest), RequestBoundedInt(aRequest, 'maxDepth', 3, 0, 16),
    RequestBoundedInt(aRequest, 'maxChildren', 200, 1, 2000));
end;

function TAccessibilityAgentBridgeState.ExecuteFormsList: string;
var
  i: Integer;
  lForms: TJSONArray;
  lResponse: TJSONObject;
begin
  lForms := TJSONArray.Create;
  for i := 0 to Pred(Screen.CustomFormCount) do
  begin
    if Screen.CustomForms[i].Visible then
    begin
      lForms.AddElement(FormSummaryJson(Screen.CustomForms[i]));
    end;
  end;

  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'forms.list');
  AddInt(lResponse, 'protocolVersion', 1);
  lResponse.AddPair('forms', lForms);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.ExecuteHello: string;
var
  lResponse: TJSONObject;
begin
  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'hello');
  AddInt(lResponse, 'protocolVersion', 1);
  lResponse.AddPair('frameworkName', cAccessibilityFrameworkName);
  AddUInt(lResponse, 'processId', GetCurrentProcessId);
  AddBool(lResponse, 'mutationEnabled', gMutationEnabled);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.ExecuteHitTest(aRequest: TJSONObject): string;
var
  lControl: TControl;
  lPoint: TPoint;
  lRef: string;
  x: Integer;
  y: Integer;
  lResponse: TJSONObject;
begin
  if (not RequestInt(aRequest, 'x', x)) or (not RequestInt(aRequest, 'y', y)) then
  begin
    Exit(Failure('invalid_request', 'hitTest requires integer x and y.'));
  end;

  lPoint := Point(x, y);
  lControl := HitControlAt(lPoint);
  if lControl = nil then
  begin
    Exit(Failure('no_hit', 'No VCL control was found at the requested point.'));
  end;

  if not RefForControl(lControl, lRef) then
  begin
    Exit(Failure('no_snapshot_ref', 'Hit control is not part of the current snapshot.'));
  end;

  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'hitTest');
  AddInt(lResponse, 'snapshotId', fSnapshotId);
  lResponse.AddPair('ref', lRef);
  lResponse.AddPair('name', lControl.Name);
  lResponse.AddPair('className', lControl.ClassName);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.ExecuteKeyboardTab(aRequest: TJSONObject): string;
var
  lForm: TCustomForm;
  lForward: Boolean;
  lShift: string;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  lForm := fForm;
  if lForm = nil then
  begin
    lForm := Screen.ActiveCustomForm;
  end;
  if lForm = nil then
  begin
    Exit(Failure('form_not_found', 'No form is available for keyboard.tab.'));
  end;

  lShift := LowerCase(RequestString(aRequest, 'shift'));
  lForward := not ((lShift = 'true') or (lShift = '1'));
  TAgentBridgeWinControlAccess(lForm).SelectNext(lForm.ActiveControl, lForward, True);
  if lForm.ActiveControl = nil then
  begin
    Exit(Failure('no_tab_target', 'No tab-stop controls were found.'));
  end;

  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.ExecuteProviderHotspots: string;
var
  lMetrics: TJSONValue;
  lResponse: TJSONObject;
begin
  lMetrics := TJSONObject.ParseJSONValue(
    TAccessibilityDiagnostics.ProviderHotspotMetrics.ToJson('agent-bridge', 'diagnostics'), True, True);
  if not (lMetrics is TJSONObject) then
  begin
    lMetrics.Free;
    Exit(Failure('metrics_json_error', 'Provider hotspot metrics could not be serialized.'));
  end;

  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'diagnostics.providerHotspots');
  AddInt(lResponse, 'protocolVersion', 1);
  lResponse.AddPair('metrics', lMetrics);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.ExecuteSetText(aRequest: TJSONObject; aAppend: Boolean): string;
var
  lControl: TControl;
  lCurrentText: string;
  lText: string;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  if not ResolveControl(aRequest, lControl) then
  begin
    Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive.'));
  end;

  lText := RequestString(aRequest, 'text');
  if aAppend then
  begin
    lCurrentText := ReadStringProperty(lControl, 'Text', nil);
    lText := lCurrentText + lText;
  end;

  if not WriteStringProperty(lControl, 'Text', lText) then
  begin
    Exit(Failure('unsupported_control', 'Control does not expose a writable Text property.'));
  end;

  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.ExecuteWindowInfo(aRequest: TJSONObject): string;
var
  lForm: TCustomForm;
  lResponse: TJSONObject;
begin
  lForm := ResolveForm(aRequest);
  if lForm = nil then
  begin
    Exit(Failure('form_not_found', 'Requested form was not found.'));
  end;

  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'window.info');
  AddInt(lResponse, 'protocolVersion', 1);
  lResponse.AddPair('window', WindowInfoJson(lForm));
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.Failure(const aErrorCode: string; const aMessage: string): string;
begin
  Result := FailureResponse(aErrorCode, aMessage);
end;

function TAccessibilityAgentBridgeState.FormSummaryJson(aForm: TCustomForm): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', aForm.Name);
  Result.AddPair('className', aForm.ClassName);
  Result.AddPair('caption', TAccessibilityText.Clean(aForm.Caption));
  AddBool(Result, 'visible', aForm.Visible);
  AddBool(Result, 'enabled', aForm.Enabled);
  AddBool(Result, 'active', Screen.ActiveCustomForm = aForm);
  AddUInt(Result, 'handle', UInt64(NativeUInt(aForm.Handle)));
  Result.AddPair('screenRect', RectJson(ControlScreenRect(aForm)));
end;

procedure TAccessibilityAgentBridgeState.FocusWinControl(aControl: TWinControl);
var
  lForm: TCustomForm;
begin
  lForm := GetParentForm(aControl, False);
  if lForm <> nil then
  begin
    lForm.ActiveControl := aControl;
  end;

  if aControl.CanFocus then
  begin
    aControl.SetFocus;
  end;
end;

function TAccessibilityAgentBridgeState.HitControlAt(const aPoint: TPoint): TControl;
var
  lForm: TCustomForm;
  lWindow: TWinControl;
begin
  Result := nil;
  if fForm <> nil then
  begin
    Result := ControlAtScreenPoint(fForm, aPoint);
    if Result <> nil then
    begin
      Exit;
    end;
  end;

  lWindow := FindVCLWindow(aPoint);
  if lWindow = nil then
  begin
    Exit;
  end;

  lForm := GetParentForm(lWindow, False);
  if lForm <> nil then
  begin
    Result := ControlAtScreenPoint(lForm, aPoint);
  end else begin
    Result := lWindow;
  end;
end;

procedure TAccessibilityAgentBridgeState.Notification(aComponent: TComponent; aOperation: TOperation);
var
  lControl: TControl;
  lRef: string;
begin
  inherited Notification(aComponent, aOperation);
  if (aOperation <> opRemove) or not (aComponent is TControl) then
  begin
    Exit;
  end;

  lControl := TControl(aComponent);
  if fRefsByControl.TryGetValue(lControl, lRef) then
  begin
    fRefsByControl.Remove(lControl);
    fControlsByRef.Remove(lRef);
    fScreenRectsByControl.Remove(lControl);
  end;
  fObservedControls.Remove(aComponent);

  if aComponent = fForm then
  begin
    fForm := nil;
  end;
end;

function TAccessibilityAgentBridgeState.RefForControl(aControl: TControl; out aRef: string): Boolean;
begin
  aRef := '';
  Result := (aControl <> nil) and fRefsByControl.TryGetValue(aControl, aRef);
end;

function TAccessibilityAgentBridgeState.RegisterControl(aControl: TControl): string;
begin
  if fRefsByControl.TryGetValue(aControl, Result) then
  begin
    Exit;
  end;

  Result := '@a' + IntToStr(fNextRefIndex);
  Inc(fNextRefIndex);
  fControlsByRef.Add(Result, aControl);
  fRefsByControl.Add(aControl, Result);
  aControl.FreeNotification(Self);
  fObservedControls.Add(aControl);
end;

function TAccessibilityAgentBridgeState.ResolveControl(aRequest: TJSONObject; out aControl: TControl): Boolean;
var
  lRef: string;
begin
  aControl := nil;
  lRef := RequestString(aRequest, 'ref');
  Result := (lRef <> '') and fControlsByRef.TryGetValue(lRef, aControl) and (aControl <> nil) and
    not (csDestroying in aControl.ComponentState);
end;

function TAccessibilityAgentBridgeState.ResolveForm(aRequest: TJSONObject): TCustomForm;
var
  i: Integer;
  lHandle: UInt64;
  lTarget: string;
  lWinControl: TWinControl;
begin
  Result := nil;
  lTarget := RequestString(aRequest, 'target');

  if lTarget = 'handle' then
  begin
    if not RequestUInt64(aRequest, 'handle', lHandle) then
    begin
      Exit(nil);
    end;
    lWinControl := FindControl(HWND(NativeUInt(lHandle)));
    if lWinControl <> nil then
    begin
      Result := GetParentForm(lWinControl, False);
      if Result = nil then
      begin
        if lWinControl is TCustomForm then
        begin
          Result := TCustomForm(lWinControl);
        end;
      end;
    end;
    Exit;
  end;

  if lTarget = 'name' then
  begin
    lTarget := RequestString(aRequest, 'name');
    for i := 0 to Pred(Screen.CustomFormCount) do
    begin
      if SameText(Screen.CustomForms[i].Name, lTarget) then
      begin
        Exit(Screen.CustomForms[i]);
      end;
    end;
    Exit;
  end;

  Result := Screen.ActiveCustomForm;
  if (Result = nil) and (Application.MainForm <> nil) then
  begin
    Result := Application.MainForm;
  end;
end;

function TAccessibilityAgentBridgeState.SuccessCommand(const aCommand: string): string;
var
  lResponse: TJSONObject;
begin
  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', aCommand);
  AddInt(lResponse, 'protocolVersion', 1);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.SuccessMutation: string;
var
  lResponse: TJSONObject;
begin
  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  AddBool(lResponse, 'snapshotInvalidated', True);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.WindowInfoJson(aForm: TCustomForm): TJSONObject;
var
  lClientRect: TRect;
  lClientScreenRect: TRect;
begin
  Result := FormSummaryJson(aForm);
  AddInt(Result, 'pixelsPerInch', aForm.PixelsPerInch);
  Result.AddPair('windowState', GetEnumName(TypeInfo(TWindowState), Ord(aForm.WindowState)));

  lClientRect := Rect(0, 0, aForm.ClientWidth, aForm.ClientHeight);
  lClientScreenRect := aForm.ClientToScreen(lClientRect);
  Result.AddPair('clientRect', RectJson(lClientRect));
  Result.AddPair('clientScreenRect', RectJson(lClientScreenRect));
end;

class function TAccessibilityAgentBridge.Execute(const aRequestJson: string): string;
var
  lRequest: TJSONObject;
  lValue: TJSONValue;
begin
  if GetCurrentThreadId <> MainThreadID then
  begin
    Exit(FailureResponse('wrong_thread', 'Agent bridge commands must run on the VCL main thread.'));
  end;

  lValue := nil;
  try
    try
      try
        lValue := TJSONObject.ParseJSONValue(aRequestJson, True, True);
      except
        on lException: Exception do
        begin
          Exit(FailureResponse('invalid_json', lException.Message));
        end;
      end;

      if not (lValue is TJSONObject) then
      begin
        Exit(FailureResponse('invalid_request', 'Agent bridge request must be a JSON object.'));
      end;

      lRequest := TJSONObject(lValue);
      Result := BridgeState.Execute(lRequest);
    except
      on lException: Exception do
      begin
        Result := FailureResponse('exception', lException.Message);
      end;
    end;
  finally
    lValue.Free;
  end;
end;

class function TAccessibilityAgentBridge.MutationEnabled: Boolean;
begin
  Result := gMutationEnabled;
end;

class procedure TAccessibilityAgentBridge.SetMutationEnabled(aValue: Boolean);
begin
  gMutationEnabled := aValue;
end;

initialization

finalization
  FreeAndNil(gBridgeState);

end.
