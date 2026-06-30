unit MaxLogic.Accessibility.ProviderCore;

interface

uses
  System.Classes, System.Generics.Collections, System.Variants, Winapi.ActiveX, Winapi.Windows,
  MaxLogic.Accessibility.UIAutomationCore;

const
  UIA_E_ELEMENTNOTAVAILABLE = HResult($80040201);

type
  IAccessibilityUiaApi = interface
    ['{0D97D749-B366-42C6-BF8B-6418D3931A0A}']
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
    function RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID;
      const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
    function RaiseNotification(const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
      aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
      const aActivityId: WideString): HRESULT;
    function RaiseStructureChanged(const aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
      const aRuntimeId: TArray<Integer>): HRESULT;
    function ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple): LRESULT;
  end;

  IAccessibilityProviderNode = interface
    ['{7D1F126D-C0E6-4422-80FE-912A0AC61222}']
    procedure AddChild(const aChild: IAccessibilityProviderNode);
    procedure Disconnect;
    function FragmentProvider: IRawElementProviderFragment;
    function IsDisconnected: Boolean;
    function RawElementProvider: IRawElementProviderSimple;
    procedure SetProperty(aPropertyId: PROPERTYID; const aValue: OleVariant);
  end;

  IAccessibilityProviderNodeInternal = interface
    ['{DA516143-0A60-4B0C-BF3D-7897E9FA5AF0}']
    function ProviderObject: TObject;
  end;

  TAccessibilityProviderNode = class(TInterfacedObject, IAccessibilityProviderNode,
    IAccessibilityProviderNodeInternal, IRawElementProviderSimple, IRawElementProviderFragment)
  private
    fApi: IAccessibilityUiaApi;
    fChildren: TList<IAccessibilityProviderNode>;
    fDisconnected: Boolean;
    fHwnd: HWND;
    fOwnerLink: TComponent;
    fParent: TAccessibilityProviderNode;
    fProperties: TDictionary<PROPERTYID, OleVariant>;
    fRuntimeId: TArray<Integer>;
    class function FromNode(const aNode: IAccessibilityProviderNode): TAccessibilityProviderNode; static;
    function ChildIndex(aChild: TAccessibilityProviderNode): Integer;
    function CreateRuntimeIdSafeArray: PSafeArray;
    procedure DetachChildrenFromParentDestruction;
    procedure DetachFromParentDestruction;
    function RootNode: TAccessibilityProviderNode;
    procedure SetOwnerLink(aOwnerLink: TComponent);
  protected
    constructor CreateNode(const aRuntimeId: array of Integer; aHwnd: HWND; const aApi: IAccessibilityUiaApi;
      aOwner: TComponent); virtual;
    procedure AssignApiRecursive(const aApi: IAccessibilityUiaApi);
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; virtual;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; virtual;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; virtual;
    function DoSetFocus: HResult; virtual;
    function FindDescendantFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment): Boolean;
    procedure PrepareChildrenForNavigation; virtual;
    procedure RemoveChildNode(const aChild: IAccessibilityProviderNode; aDisconnect: Boolean);
  public
    destructor Destroy; override;
    procedure AddChild(const aChild: IAccessibilityProviderNode);
    procedure Disconnect;
    function FragmentProvider: IRawElementProviderFragment;
    function Get_BoundingRectangle(out aRetVal: UiaRect): HResult; stdcall;
    function Get_FragmentRoot(out aRetVal: IRawElementProviderFragmentRoot): HResult; stdcall;
    function Get_HostRawElementProvider(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_ProviderOptions(out aRetVal: ProviderOptions): HResult; stdcall;
    function GetEmbeddedFragmentRoots(out aRetVal: PSafeArray): HResult; stdcall;
    function GetPatternProvider(aPatternId: PATTERNID; out aRetVal: IUnknown): HResult; stdcall;
    function GetPropertyValue(aPropertyId: PROPERTYID; out aRetVal: OleVariant): HResult; stdcall;
    function GetRuntimeId(out aRetVal: PSafeArray): HResult; stdcall;
    function IsDisconnected: Boolean;
    function Navigate(aDirection: NavigateDirection; out aRetVal: IRawElementProviderFragment): HResult; stdcall;
    function ProviderObject: TObject;
    function RawElementProvider: IRawElementProviderSimple;
    function SetFocus: HResult; stdcall;
    procedure SetProperty(aPropertyId: PROPERTYID; const aValue: OleVariant);
  end;

  TAccessibilityProviderRoot = class(TAccessibilityProviderNode, IRawElementProviderFragmentRoot)
  protected
    function DoElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment): HResult;
      virtual;
    function DoGetFocus(out aProvider: IRawElementProviderFragment): HResult; virtual;
  public
    function ElementProviderFromPoint(aX: Double; aY: Double; out aRetVal: IRawElementProviderFragment): HResult;
      stdcall;
    function GetFocus(out aRetVal: IRawElementProviderFragment): HResult; stdcall;
  end;

  TAccessibilityProviderFactory = record
  public
    class function CreateFragment(const aRuntimeId: array of Integer; const aApi: IAccessibilityUiaApi = nil;
      aOwner: TComponent = nil): IAccessibilityProviderNode; static;
    class function CreateRoot(const aRuntimeId: array of Integer; aHwnd: HWND = 0;
      const aApi: IAccessibilityUiaApi = nil; aOwner: TComponent = nil): IAccessibilityProviderNode; static;
  end;

  TAccessibilityProviderEvents = record
  public
    class function RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID;
      const aApi: IAccessibilityUiaApi = nil): Boolean; static;
    class function RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID;
      const aOldValue: OleVariant; const aNewValue: OleVariant; const aApi: IAccessibilityUiaApi = nil): Boolean; static;
    class function RaiseNotification(const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
      aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString; const aActivityId: WideString;
      const aApi: IAccessibilityUiaApi = nil): Boolean; static;
    class function RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
      aStructureChangeType: StructureChangeType; const aRuntimeId: array of Integer;
      const aApi: IAccessibilityUiaApi = nil): Boolean; static;
  end;

  TAccessibilityProviderWindowMessages = record
  public
    class function TryHandleGetObject(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple; const aApi: IAccessibilityUiaApi;
      out aResult: LRESULT): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  MaxLogic.Accessibility.Diagnostics;

type
  TAccessibilityUiaApi = class(TInterfacedObject, IAccessibilityUiaApi)
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
    function RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID;
      const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
    function RaiseNotification(const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
      aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
      const aActivityId: WideString): HRESULT;
    function RaiseStructureChanged(const aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
      const aRuntimeId: TArray<Integer>): HRESULT;
    function ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple): LRESULT;
  end;

  TAccessibilityProviderOwnerLink = class(TComponent)
  private
    fOwnerComponent: TComponent;
    fProvider: TAccessibilityProviderNode;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    constructor Create(aOwnerComponent: TComponent; aProvider: TAccessibilityProviderNode); reintroduce;
    destructor Destroy; override;
  end;

var
  gDefaultUiaApi: IAccessibilityUiaApi;

function CopyRuntimeId(const aRuntimeId: array of Integer): TArray<Integer>;
var
  i: Integer;
begin
  SetLength(Result, Length(aRuntimeId));
  for i := 0 to High(aRuntimeId) do
  begin
    Result[i] := aRuntimeId[i];
  end;
end;

function DefaultUiaApi: IAccessibilityUiaApi;
begin
  if gDefaultUiaApi = nil then
  begin
    gDefaultUiaApi := TAccessibilityUiaApi.Create;
  end;

  Result := gDefaultUiaApi;
end;

function ResolveApi(const aApi: IAccessibilityUiaApi): IAccessibilityUiaApi;
begin
  Result := aApi;
  if Result = nil then
  begin
    Result := DefaultUiaApi;
  end;
end;

function SignedDWordHex(aValue: Int64): string;
var
  lRawValue: Int64;
begin
  lRawValue := aValue and $00000000FFFFFFFF;
  Result := IntToHex(lRawValue, 8);
end;

function UiaRectContainsPoint(const aRect: UiaRect; aX: Double; aY: Double): Boolean;
begin
  Result := (aRect.Width > 0) and (aRect.Height > 0) and (aX >= aRect.Left) and (aY >= aRect.Top) and
    (aX < aRect.Left + aRect.Width) and (aY < aRect.Top + aRect.Height);
end;

function ProviderPropertyToString(const aProvider: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lProvider: IRawElementProviderSimple;
  lValue: OleVariant;
begin
  Result := '';
  if not Supports(aProvider, IRawElementProviderSimple, lProvider) then
  begin
    Exit;
  end;

  if lProvider.GetPropertyValue(aPropertyId, lValue) <> S_OK then
  begin
    Exit;
  end;

  if VarIsEmpty(lValue) or VarIsNull(lValue) then
  begin
    Exit;
  end;

  Result := VarToStr(lValue);
end;

function ProviderHitTestDescription(const aProvider: IRawElementProviderFragment): string;
var
  lClassName: string;
  lControlType: string;
  lName: string;
begin
  if aProvider = nil then
  begin
    Exit('provider=nil');
  end;

  lName := ProviderPropertyToString(aProvider, UIA_NamePropertyId);
  lClassName := ProviderPropertyToString(aProvider, UIA_ClassNamePropertyId);
  lControlType := ProviderPropertyToString(aProvider, UIA_ControlTypePropertyId);
  Result := Format('provider name="%s" class="%s" controlType="%s"', [lName, lClassName, lControlType]);
end;

function TAccessibilityUiaApi.ClientsAreListening: Boolean;
begin
  Result := UiaClientsAreListening <> BOOL(False);
end;

function TAccessibilityUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Result := UiaDisconnectProvider(aProvider);
end;

function TAccessibilityUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
begin
  Result := UiaHostProviderFromHwnd(aHwnd, aProvider);
end;

function TAccessibilityUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID): HRESULT;
begin
  Result := UiaRaiseAutomationEvent(aProvider, aEventId);
end;

function TAccessibilityUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := UiaRaiseAutomationPropertyChangedEvent(aProvider, aPropertyId, aOldValue, aNewValue);
end;

function TAccessibilityUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Result := UiaRaiseNotificationEvent(aProvider, aNotificationKind, aNotificationProcessing, aDisplayString, aActivityId);
end;

function TAccessibilityUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
var
  lRuntimeId: PInteger;
begin
  lRuntimeId := nil;
  if Length(aRuntimeId) > 0 then
  begin
    lRuntimeId := @aRuntimeId[0];
  end;

  Result := UiaRaiseStructureChangedEvent(aProvider, aStructureChangeType, lRuntimeId, Length(aRuntimeId));
end;

function TAccessibilityUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Result := UiaReturnRawElementProvider(aHwnd, aWParam, aLParam, aProvider);
end;

constructor TAccessibilityProviderOwnerLink.Create(aOwnerComponent: TComponent; aProvider: TAccessibilityProviderNode);
begin
  inherited Create(nil);
  fOwnerComponent := aOwnerComponent;
  fProvider := aProvider;
  if fOwnerComponent <> nil then
  begin
    fOwnerComponent.FreeNotification(Self);
  end;
end;

destructor TAccessibilityProviderOwnerLink.Destroy;
begin
  if fOwnerComponent <> nil then
  begin
    fOwnerComponent.RemoveFreeNotification(Self);
  end;

  inherited Destroy;
end;

procedure TAccessibilityProviderOwnerLink.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent, aOperation);
  if (aOperation = opRemove) and (aComponent = fOwnerComponent) then
  begin
    fOwnerComponent := nil;
    if fProvider <> nil then
    begin
      fProvider.Disconnect;
    end;
  end;
end;

constructor TAccessibilityProviderNode.CreateNode(const aRuntimeId: array of Integer; aHwnd: HWND;
  const aApi: IAccessibilityUiaApi; aOwner: TComponent);
var
  i: Integer;
begin
  inherited Create;
  if Length(aRuntimeId) = 0 then
  begin
    raise EArgumentException.Create('Runtime ID must not be empty.');
  end;

  fApi := aApi;
  fHwnd := aHwnd;
  fChildren := TList<IAccessibilityProviderNode>.Create;
  fProperties := TDictionary<PROPERTYID, OleVariant>.Create;
  SetLength(fRuntimeId, Length(aRuntimeId));
  for i := 0 to High(aRuntimeId) do
  begin
    fRuntimeId[i] := aRuntimeId[i];
  end;

  if aOwner <> nil then
  begin
    SetOwnerLink(TAccessibilityProviderOwnerLink.Create(aOwner, Self));
  end;
end;

destructor TAccessibilityProviderNode.Destroy;
begin
  DetachChildrenFromParentDestruction;
  fOwnerLink.Free;
  fProperties.Free;
  fChildren.Free;
  inherited Destroy;
end;

procedure TAccessibilityProviderNode.AddChild(const aChild: IAccessibilityProviderNode);
var
  lChild: TAccessibilityProviderNode;
begin
  lChild := FromNode(aChild);
  if lChild.fParent <> nil then
  begin
    raise EInvalidOperation.Create('Provider node already has a parent.');
  end;

  lChild.fParent := Self;
  lChild.AssignApiRecursive(fApi);
  fChildren.Add(aChild);
end;

procedure TAccessibilityProviderNode.AssignApiRecursive(const aApi: IAccessibilityUiaApi);
var
  lChild: IAccessibilityProviderNode;
  lEffectiveApi: IAccessibilityUiaApi;
begin
  if fApi = nil then
  begin
    fApi := aApi;
  end;

  lEffectiveApi := fApi;
  for lChild in fChildren do
  begin
    FromNode(lChild).AssignApiRecursive(lEffectiveApi);
  end;
end;

function TAccessibilityProviderNode.ChildIndex(aChild: TAccessibilityProviderNode): Integer;
var
  i: Integer;
begin
  for i := 0 to Pred(fChildren.Count) do
  begin
    if FromNode(fChildren[i]) = aChild then
    begin
      Exit(i);
    end;
  end;

  Result := -1;
end;

function TAccessibilityProviderNode.CreateRuntimeIdSafeArray: PSafeArray;
var
  i: Integer;
  lIndex: Integer;
  lValue: Integer;
begin
  Result := SafeArrayCreateVector(VT_I4, 0, Length(fRuntimeId) + 1);
  if Result = nil then
  begin
    Exit;
  end;

  lIndex := 0;
  lValue := UiaAppendRuntimeId;
  if SafeArrayPutElement(Result, lIndex, lValue) <> S_OK then
  begin
    SafeArrayDestroy(Result);
    Exit(nil);
  end;

  for i := 0 to High(fRuntimeId) do
  begin
    lIndex := i + 1;
    lValue := fRuntimeId[i];
    if SafeArrayPutElement(Result, lIndex, lValue) <> S_OK then
    begin
      SafeArrayDestroy(Result);
      Exit(nil);
    end;
  end;
end;

procedure TAccessibilityProviderNode.DetachChildrenFromParentDestruction;
var
  lChild: IAccessibilityProviderNode;
begin
  for lChild in fChildren do
  begin
    FromNode(lChild).DetachFromParentDestruction;
  end;
end;

procedure TAccessibilityProviderNode.DetachFromParentDestruction;
begin
  fParent := nil;
  fDisconnected := True;
  DetachChildrenFromParentDestruction;
end;

procedure TAccessibilityProviderNode.Disconnect;
var
  lChild: IAccessibilityProviderNode;
begin
  if fDisconnected then
  begin
    Exit;
  end;

  fDisconnected := True;
  for lChild in fChildren do
  begin
    lChild.Disconnect;
  end;

  if fApi <> nil then
  begin
    fApi.DisconnectProvider(RawElementProvider);
  end;
end;

function TAccessibilityProviderNode.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
begin
  aValue := Default(UiaRect);
  Result := False;
end;

function TAccessibilityProviderNode.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Result := nil;
end;

function TAccessibilityProviderNode.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
begin
  aValue := Unassigned;
  Result := True;
  case aPropertyId of
    UIA_NativeWindowHandlePropertyId:
      aValue := NativeInt(fHwnd);
  else
    Result := False;
  end;
end;

function TAccessibilityProviderNode.DoSetFocus: HResult;
begin
  Result := S_OK;
end;

function TAccessibilityProviderNode.FragmentProvider: IRawElementProviderFragment;
begin
  Result := Self as IRawElementProviderFragment;
end;

function TAccessibilityProviderNode.FindDescendantFromPoint(aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): Boolean;
var
  i: Integer;
  lBounds: UiaRect;
  lChild: TAccessibilityProviderNode;
  lDeeperProvider: IRawElementProviderFragment;
begin
  aProvider := nil;
  Result := False;
  if fDisconnected then
  begin
    Exit;
  end;

  PrepareChildrenForNavigation;
  for i := Pred(fChildren.Count) downto 0 do
  begin
    lChild := FromNode(fChildren[i]);
    if lChild.IsDisconnected or (lChild.Get_BoundingRectangle(lBounds) <> S_OK) or
      not UiaRectContainsPoint(lBounds, aX, aY) then
    begin
      Continue;
    end;

    if lChild.FindDescendantFromPoint(aX, aY, lDeeperProvider) then
    begin
      aProvider := lDeeperProvider;
    end else begin
      aProvider := lChild.FragmentProvider;
    end;
    Exit(True);
  end;
end;

class function TAccessibilityProviderNode.FromNode(const aNode: IAccessibilityProviderNode): TAccessibilityProviderNode;
var
  lInternal: IAccessibilityProviderNodeInternal;
begin
  if not Supports(aNode, IAccessibilityProviderNodeInternal, lInternal) then
  begin
    raise EInvalidCast.Create('Unknown accessibility provider node implementation.');
  end;

  Result := TAccessibilityProviderNode(lInternal.ProviderObject);
end;

function TAccessibilityProviderNode.Get_BoundingRectangle(out aRetVal: UiaRect): HResult;
begin
  aRetVal := Default(UiaRect);
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  DoGetBoundingRectangle(aRetVal);
  Result := S_OK;
end;

function TAccessibilityProviderNode.Get_FragmentRoot(out aRetVal: IRawElementProviderFragmentRoot): HResult;
begin
  aRetVal := nil;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if Supports(RootNode, IRawElementProviderFragmentRoot, aRetVal) then
  begin
    Result := S_OK;
  end else begin
    Result := S_FALSE;
  end;
end;

function TAccessibilityProviderNode.Get_HostRawElementProvider(out aRetVal: IRawElementProviderSimple): HResult;
begin
  aRetVal := nil;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if (fHwnd = 0) or (fApi = nil) then
  begin
    Exit(S_FALSE);
  end;

  Result := fApi.HostProviderFromHwnd(fHwnd, aRetVal);
end;

function TAccessibilityProviderNode.Get_ProviderOptions(out aRetVal: ProviderOptions): HResult;
begin
  aRetVal := ProviderOptions_ServerSideProvider;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityProviderNode.GetEmbeddedFragmentRoots(out aRetVal: PSafeArray): HResult;
begin
  aRetVal := nil;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityProviderNode.GetPatternProvider(aPatternId: PATTERNID; out aRetVal: IUnknown): HResult;
begin
  aRetVal := nil;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := DoGetPatternProvider(aPatternId);
  Result := S_OK;
end;

function TAccessibilityProviderNode.GetPropertyValue(aPropertyId: PROPERTYID; out aRetVal: OleVariant): HResult;
var
  lValue: OleVariant;
begin
  aRetVal := Unassigned;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if fProperties.TryGetValue(aPropertyId, lValue) or DoGetPropertyValue(aPropertyId, lValue) then
  begin
    aRetVal := lValue;
  end;

  Result := S_OK;
end;

function TAccessibilityProviderNode.GetRuntimeId(out aRetVal: PSafeArray): HResult;
begin
  aRetVal := nil;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := CreateRuntimeIdSafeArray;
  if aRetVal = nil then
  begin
    Result := E_UNEXPECTED;
  end else begin
    Result := S_OK;
  end;
end;

function TAccessibilityProviderNode.IsDisconnected: Boolean;
begin
  Result := fDisconnected;
end;

function TAccessibilityProviderNode.Navigate(aDirection: NavigateDirection;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lIndex: Integer;
  lParent: TAccessibilityProviderNode;
begin
  aRetVal := nil;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  case aDirection of
    NavigateDirection_Parent:
      if fParent <> nil then
      begin
        aRetVal := fParent.FragmentProvider;
      end;
    NavigateDirection_NextSibling:
      if fParent <> nil then
      begin
        lParent := fParent;
        lParent.PrepareChildrenForNavigation;
        if fDisconnected or (fParent <> lParent) then
        begin
          Exit(S_OK);
        end;

        lIndex := lParent.ChildIndex(Self);
        if (lIndex >= 0) and (lIndex < Pred(lParent.fChildren.Count)) then
        begin
          aRetVal := lParent.fChildren[lIndex + 1].FragmentProvider;
        end;
      end;
    NavigateDirection_PreviousSibling:
      if fParent <> nil then
      begin
        lParent := fParent;
        lParent.PrepareChildrenForNavigation;
        if fDisconnected or (fParent <> lParent) then
        begin
          Exit(S_OK);
        end;

        lIndex := lParent.ChildIndex(Self);
        if lIndex > 0 then
        begin
          aRetVal := lParent.fChildren[lIndex - 1].FragmentProvider;
        end;
      end;
    NavigateDirection_FirstChild:
      begin
        PrepareChildrenForNavigation;
        if fChildren.Count > 0 then
        begin
          aRetVal := fChildren[0].FragmentProvider;
        end;
      end;
    NavigateDirection_LastChild:
      begin
        PrepareChildrenForNavigation;
        if fChildren.Count > 0 then
        begin
          aRetVal := fChildren[Pred(fChildren.Count)].FragmentProvider;
        end;
      end;
  else
    Result := E_INVALIDARG;
    Exit;
  end;

  Result := S_OK;
end;

function TAccessibilityProviderNode.ProviderObject: TObject;
begin
  Result := Self;
end;

procedure TAccessibilityProviderNode.PrepareChildrenForNavigation;
begin
end;

procedure TAccessibilityProviderNode.RemoveChildNode(const aChild: IAccessibilityProviderNode;
  aDisconnect: Boolean);
var
  lChild: TAccessibilityProviderNode;
  lIndex: Integer;
begin
  if aChild = nil then
  begin
    Exit;
  end;

  lChild := FromNode(aChild);
  lIndex := ChildIndex(lChild);
  if lIndex < 0 then
  begin
    Exit;
  end;

  fChildren.Delete(lIndex);
  lChild.fParent := nil;
  if aDisconnect then
  begin
    aChild.Disconnect;
  end else begin
    lChild.DetachFromParentDestruction;
  end;
end;

function TAccessibilityProviderNode.RawElementProvider: IRawElementProviderSimple;
begin
  Result := Self as IRawElementProviderSimple;
end;

function TAccessibilityProviderNode.RootNode: TAccessibilityProviderNode;
begin
  Result := Self;
  while Result.fParent <> nil do
  begin
    Result := Result.fParent;
  end;
end;

function TAccessibilityProviderNode.SetFocus: HResult;
begin
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := DoSetFocus;
end;

procedure TAccessibilityProviderNode.SetOwnerLink(aOwnerLink: TComponent);
begin
  fOwnerLink.Free;
  fOwnerLink := aOwnerLink;
end;

procedure TAccessibilityProviderNode.SetProperty(aPropertyId: PROPERTYID; const aValue: OleVariant);
begin
  fProperties.AddOrSetValue(aPropertyId, aValue);
end;

function TAccessibilityProviderRoot.DoElementProviderFromPoint(aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): HResult;
begin
  aProvider := nil;
  FindDescendantFromPoint(aX, aY, aProvider);
  Result := S_OK;
end;

function TAccessibilityProviderRoot.DoGetFocus(out aProvider: IRawElementProviderFragment): HResult;
begin
  aProvider := nil;
  Result := S_OK;
end;

function TAccessibilityProviderRoot.ElementProviderFromPoint(aX: Double; aY: Double;
  out aRetVal: IRawElementProviderFragment): HResult;
begin
  aRetVal := nil;
  if IsDisconnected then
  begin
    TAccessibilityDiagnostics.Log(Format('UIA ElementProviderFromPoint x=%.0f y=%.0f result=UIA_E_ELEMENTNOTAVAILABLE',
      [aX, aY]));
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := DoElementProviderFromPoint(aX, aY, aRetVal);
  TAccessibilityDiagnostics.Log(Format('UIA ElementProviderFromPoint x=%.0f y=%.0f hresult=$%s %s',
    [aX, aY, SignedDWordHex(Result), ProviderHitTestDescription(aRetVal)]));
end;

function TAccessibilityProviderRoot.GetFocus(out aRetVal: IRawElementProviderFragment): HResult;
begin
  aRetVal := nil;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := DoGetFocus(aRetVal);
end;

class function TAccessibilityProviderFactory.CreateFragment(const aRuntimeId: array of Integer;
  const aApi: IAccessibilityUiaApi; aOwner: TComponent): IAccessibilityProviderNode;
begin
  Result := TAccessibilityProviderNode.CreateNode(aRuntimeId, 0, aApi, aOwner);
end;

class function TAccessibilityProviderFactory.CreateRoot(const aRuntimeId: array of Integer; aHwnd: HWND;
  const aApi: IAccessibilityUiaApi; aOwner: TComponent): IAccessibilityProviderNode;
begin
  Result := TAccessibilityProviderRoot.CreateNode(aRuntimeId, aHwnd, ResolveApi(aApi), aOwner);
end;

class function TAccessibilityProviderEvents.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID; const aApi: IAccessibilityUiaApi): Boolean;
var
  lApi: IAccessibilityUiaApi;
begin
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  lApi := ResolveApi(aApi);
  if not lApi.ClientsAreListening then
  begin
    Exit;
  end;

  Result := lApi.RaiseAutomationEvent(aProvider, aEventId) = S_OK;
end;

class function TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(
  const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID; const aOldValue: OleVariant;
  const aNewValue: OleVariant; const aApi: IAccessibilityUiaApi): Boolean;
var
  lApi: IAccessibilityUiaApi;
begin
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  lApi := ResolveApi(aApi);
  if not lApi.ClientsAreListening then
  begin
    Exit;
  end;

  Result := lApi.RaiseAutomationPropertyChanged(aProvider, aPropertyId, aOldValue, aNewValue) = S_OK;
end;

class function TAccessibilityProviderEvents.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString; const aApi: IAccessibilityUiaApi): Boolean;
var
  lApi: IAccessibilityUiaApi;
begin
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  lApi := ResolveApi(aApi);
  if not lApi.ClientsAreListening then
  begin
    Exit;
  end;

  Result := lApi.RaiseNotification(aProvider, aNotificationKind, aNotificationProcessing, aDisplayString,
    aActivityId) = S_OK;
end;

class function TAccessibilityProviderEvents.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: array of Integer;
  const aApi: IAccessibilityUiaApi): Boolean;
var
  lApi: IAccessibilityUiaApi;
begin
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  lApi := ResolveApi(aApi);
  if not lApi.ClientsAreListening then
  begin
    Exit;
  end;

  Result := lApi.RaiseStructureChanged(aProvider, aStructureChangeType, CopyRuntimeId(aRuntimeId)) = S_OK;
end;

class function TAccessibilityProviderWindowMessages.TryHandleGetObject(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple; const aApi: IAccessibilityUiaApi; out aResult: LRESULT): Boolean;
var
  lApi: IAccessibilityUiaApi;
begin
  aResult := 0;
  Result := False;
  if (aLParam <> LPARAM(UiaRootObjectId)) or (aProvider = nil) then
  begin
    TAccessibilityDiagnostics.Log(Format('WM_GETOBJECT ignored hwnd=%d lParam=%d providerPresent=%s',
      [aHwnd, aLParam, BoolToStr(aProvider <> nil, True)]));
    Exit;
  end;

  lApi := ResolveApi(aApi);
  aResult := lApi.ReturnRawElementProvider(aHwnd, aWParam, aLParam, aProvider);
  TAccessibilityDiagnostics.Log(Format('WM_GETOBJECT returned framework provider hwnd=%d wParam=%d lParam=%d lResult=$%s',
    [aHwnd, aWParam, aLParam, SignedDWordHex(aResult)]));
  Result := True;
end;

end.
