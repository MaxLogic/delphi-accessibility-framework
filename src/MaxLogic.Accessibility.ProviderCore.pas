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

  IAccessibilityProviderNativeWindow = interface
    ['{FD5C427A-0B84-441D-9398-1DFA3788A584}']
    function NativeWindowHandle: HWND;
  end;

  IAccessibilityProviderDirectAccess = interface
    ['{962B6E10-54B5-4F13-95EA-0DF6E2143395}']
    function SupportsPatternDirect(aPatternId: PATTERNID): Boolean;
    function TryGetIntegerProperty(aPropertyId: PROPERTYID; out aValue: Integer): Boolean;
    function TryGetNativeWindowHandle(out aValue: HWND): Boolean;
    function TryGetStringProperty(aPropertyId: PROPERTYID; out aValue: string): Boolean;
    function TryGetValueText(out aValue: string): Boolean;
  end;

  IAccessibilityProviderGeometryAccess = interface
    ['{B49967A9-3BD6-48DB-9075-66331A5BB61C}']
    function TryGetBoundingRectangle(out aValue: UiaRect): Boolean;
  end;

  IAccessibilityProviderSpeechAccess = interface
    ['{3AA71304-A8B5-466E-B05B-49D13B102E1F}']
    function TryGetSpeechProperties(out aName: string; out aValueText: string; out aHelpText: string): Boolean;
  end;

  IAccessibilityProviderChildAccess = interface
    ['{A69455DC-A28F-4195-8549-524B7B76D672}']
    function DirectChildAt(aIndex: Integer; out aProvider: IRawElementProviderSimple): HResult;
    function DirectChildCount(out aCount: Integer): HResult;
  end;

  IAccessibilityFocusedItemProvider = interface
    ['{FFE47D9F-23E1-4E9C-8CD9-CA67E5E3E22B}']
    function TryGetFocusedItem(out aProvider: IRawElementProviderSimple; out aName: string): Boolean;
  end;

  IAccessibilityProviderRootAccess = interface
    ['{3C3B52F9-8A8E-44A9-A365-5BA77D3E40CB}']
    function DirectElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderSimple):
      HResult;
  end;

  TAccessibilityProviderNode = class(TInterfacedObject, IAccessibilityProviderNode,
    IAccessibilityProviderNodeInternal, IAccessibilityProviderNativeWindow, IAccessibilityProviderDirectAccess,
    IAccessibilityProviderGeometryAccess, IAccessibilityProviderSpeechAccess, IAccessibilityProviderChildAccess,
    IRawElementProviderSimple, IRawElementProviderFragment)
  private
    fApi: IAccessibilityUiaApi;
    fAutomationIdProperty: string;
    fChildren: TList<IAccessibilityProviderNode>;
    fChildrenPreparedForNavigation: Boolean;
    fClassNameProperty: string;
    fControlTypeProperty: Integer;
    fDisconnected: Boolean;
    fDisconnectNotificationPending: Boolean;
    fDirectChildAccessReadsRemaining: Integer;
    fFrameworkIdProperty: string;
    fFragmentRootNode: TAccessibilityProviderNode;
    fHasAutomationIdProperty: Boolean;
    fHostProviderCacheResult: HResult;
    fHostProviderCacheValid: Boolean;
    fHostRawElementProvider: IRawElementProviderSimple;
    fHasClassNameProperty: Boolean;
    fHasControlTypeProperty: Boolean;
    fHasFrameworkIdProperty: Boolean;
    fHasHelpTextProperty: Boolean;
    fHasItemStatusProperty: Boolean;
    fHasItemTypeProperty: Boolean;
    fHasNameProperty: Boolean;
    fHelpTextProperty: string;
    fHwnd: HWND;
    fItemStatusProperty: string;
    fItemTypeProperty: string;
    fNameProperty: string;
    fOwnerLink: TComponent;
    fOverrideNativeProvider: Boolean;
    fParent: TAccessibilityProviderNode;
    fParentIndex: Integer;
    fPublishNativeWindowHandle: Boolean;
    fProperties: TDictionary<PROPERTYID, OleVariant>;
    fRuntimeId: TArray<Integer>;
    fUseHostRawElementProvider: Boolean;
    class function FromNode(const aNode: IAccessibilityProviderNode): TAccessibilityProviderNode; static;
    function BuildChildRemovalFlags(const aChildren: TArray<IAccessibilityProviderNode>;
      out aRemovedCount: Integer): TArray<Boolean>;
    function ChildCount: Integer;
    function ChildIndex(aChild: TAccessibilityProviderNode): Integer;
    function ChildProviderAt(aIndex: Integer): IAccessibilityProviderNode;
    procedure ClearHostProviderCache;
    procedure ClearRemovedChildParents(aChildren: TList<IAccessibilityProviderNode>;
      const aRemovalFlags: TArray<Boolean>);
    function CreateRetainedChildren(const aRemovalFlags: TArray<Boolean>;
      aRemovedCount: Integer): TList<IAccessibilityProviderNode>;
    function CreateRuntimeIdSafeArray: PSafeArray;
    procedure DetachChildrenFromParentDestruction;
    procedure DetachFromParentDestruction;
    function EnsureChildren: TList<IAccessibilityProviderNode>;
    procedure FinalizeRemovedChildren(aChildren: TList<IAccessibilityProviderNode>;
      const aRemovalFlags: TArray<Boolean>; aDisconnect: Boolean);
    function FragmentRootNode: TAccessibilityProviderNode;
    function FragmentRootNodeCachedOrComputed: TAccessibilityProviderNode;
    procedure MarkDisconnectedRecursive;
    procedure NotifyDisconnectedRecursive(var aFirstException: TObject);
    class procedure RaiseCapturedException(var aException: TObject); static;
    procedure RefreshChildIndexesFrom(aStartIndex: Integer);
    procedure RemoveFallbackProperty(aPropertyId: PROPERTYID);
    procedure SetOwnerLink(aOwnerLink: TComponent);
    procedure SetFallbackProperty(aPropertyId: PROPERTYID; const aValue: OleVariant);
    procedure SetTypedIntegerProperty(aPropertyId: PROPERTYID; const aValue: OleVariant; var aStorage: Integer;
      var aHasStorage: Boolean);
    procedure SetTypedStringProperty(aPropertyId: PROPERTYID; const aValue: OleVariant; var aStorage: string;
      var aHasStorage: Boolean);
    function TryGetFallbackProperty(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
    function TryGetStoredPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
    function TryGetPropertyValueDirect(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
    procedure UpdateFragmentRootCacheRecursive(aNearestRoot: TAccessibilityProviderNode);
  protected
    constructor CreateNode(const aRuntimeId: array of Integer; aHwnd: HWND; const aApi: IAccessibilityUiaApi; //PALOFF WARN43 protected construction enforces provider factories
      aOwner: TComponent); virtual;
    procedure AssignApiRecursive(const aApi: IAccessibilityUiaApi);
    function CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean; virtual;
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; virtual;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; virtual;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; virtual;
    function DoSetFocus: HResult; virtual;
    function FindDescendantFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment): Boolean;
    function HasCurrentChildIndex(aChild: TAccessibilityProviderNode): Boolean;
    procedure InsertChildNode(aIndex: Integer; const aChild: IAccessibilityProviderNode);
    procedure InsertChildIntoList(aChildren: TList<IAccessibilityProviderNode>; aIndex: Integer;
      const aChild: IAccessibilityProviderNode); virtual;
    function ParentRawElementProvider: IRawElementProviderSimple;
    procedure PrepareChildrenForNavigation; virtual;
    procedure RemoveChildNode(const aChild: IAccessibilityProviderNode; aDisconnect: Boolean);
    procedure RemoveChildNodes(const aChildren: TArray<IAccessibilityProviderNode>; aDisconnect: Boolean);
    function RemoveChildNodesByIndexFlags(const aRemovalFlags: TArray<Boolean>;
      aRemovedCount: Integer; aDisconnect: Boolean): Boolean;
    procedure SetOverrideNativeProvider(aValue: Boolean);
    procedure SetPublishNativeWindowHandle(aValue: Boolean);
    procedure SetUseHostRawElementProvider(aValue: Boolean);
  public
    destructor Destroy; override;
    procedure AddChild(const aChild: IAccessibilityProviderNode);
    procedure Disconnect;
    function DirectChildAt(aIndex: Integer; out aProvider: IRawElementProviderSimple): HResult;
    function DirectChildCount(out aCount: Integer): HResult;
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
    function NativeWindowHandle: HWND;
    function ProviderObject: TObject;
    function RawElementProvider: IRawElementProviderSimple;
    function SetFocus: HResult; stdcall;
    function SupportsPatternDirect(aPatternId: PATTERNID): Boolean;
    procedure SetProperty(aPropertyId: PROPERTYID; const aValue: OleVariant);
    function TryGetIntegerProperty(aPropertyId: PROPERTYID; out aValue: Integer): Boolean;
    function TryGetBoundingRectangle(out aValue: UiaRect): Boolean;
    function TryGetNativeWindowHandle(out aValue: HWND): Boolean;
    function TryGetStringProperty(aPropertyId: PROPERTYID; out aValue: string): Boolean;
    function TryGetSpeechProperties(out aName: string; out aValueText: string; out aHelpText: string): Boolean;
    function TryGetValueText(out aValue: string): Boolean; virtual;
  end;

  TAccessibilityProviderRoot = class(TAccessibilityProviderNode, IAccessibilityProviderRootAccess,
    IRawElementProviderFragmentRoot)
  protected
    function DoElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment): HResult;
      virtual;
    function DoGetFocus(out aProvider: IRawElementProviderFragment): HResult; virtual;
  public
    function DirectElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderSimple):
      HResult;
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
    class procedure BeginEventBatch; static;
    class procedure BeginEventBatchWithKnownClientState(aClientsAreListening: Boolean); static;
    class function ClientsAreListening(const aApi: IAccessibilityUiaApi = nil): Boolean; static;
    class procedure EndEventBatch; static;
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
  System.Diagnostics, System.SysUtils,
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

threadvar
  gEventBatchClientsAreListening: Boolean;
  gEventBatchDepth: Integer;
  gEventBatchHasClientsAreListening: Boolean;
  gHostProviderBypassHwnd: HWND;

procedure StartProviderBoundaryTiming(out aStopwatch: TStopwatch; out aMetricsEnabled: Boolean);
begin
  aMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if aMetricsEnabled then
  begin
    aStopwatch := TStopwatch.StartNew;
  end;
end;

procedure FinishProviderBoundaryTiming(aCall: TAccessibilityProviderBoundaryCall; const aStopwatch: TStopwatch;
  aMetricsEnabled: Boolean);
begin
  if aMetricsEnabled then
  begin
    TAccessibilityDiagnostics.RecordProviderBoundaryCall(aCall, aStopwatch.ElapsedTicks);
  end;
end;

function DirectStatePropertyForPattern(aPatternId: PATTERNID; out aPropertyId: PROPERTYID): Boolean;
begin
  Result := True;
  case aPatternId of
    UIA_SelectionItemPatternId:
      aPropertyId := UIA_SelectionItemIsSelectedPropertyId;
    UIA_TogglePatternId:
      aPropertyId := UIA_ToggleToggleStatePropertyId;
  else
    aPropertyId := 0;
    Result := False;
  end;
end;

procedure CopyRuntimeIdBlock(const aRuntimeId: array of Integer; var aTarget: TArray<Integer>);
begin
  SetLength(aTarget, Length(aRuntimeId));
  if Length(aRuntimeId) > 0 then
  begin
    Move(aRuntimeId[0], aTarget[0], Length(aRuntimeId) * SizeOf(Integer));
    TAccessibilityDiagnostics.RecordProviderRuntimeIdBlockCopy(Length(aRuntimeId));
  end;
end;

function CopyRuntimeId(const aRuntimeId: array of Integer): TArray<Integer>;
begin
  CopyRuntimeIdBlock(aRuntimeId, Result);
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

function ResolveEventApiAndCheckClientsAreListening(const aApi: IAccessibilityUiaApi;
  out aResolvedApi: IAccessibilityUiaApi): Boolean;
begin
  aResolvedApi := ResolveApi(aApi);
  if gEventBatchDepth <= 0 then
  begin
    Exit(aResolvedApi.ClientsAreListening);
  end;

  if not gEventBatchHasClientsAreListening then
  begin
    gEventBatchClientsAreListening := aResolvedApi.ClientsAreListening;
    gEventBatchHasClientsAreListening := True;
  end;

  Result := gEventBatchClientsAreListening;
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

function TryVariantToStaticInteger(const aValue: OleVariant; out aInteger: Integer): Boolean;
var
  lVarType: TVarType;
begin
  aInteger := 0;
  if VarIsEmpty(aValue) or VarIsNull(aValue) then
  begin
    Exit(False);
  end;

  lVarType := VarType(aValue) and varTypeMask;
  Result := lVarType in [varSmallint, varInteger, varShortInt, varByte, varWord];
  if Result then
  begin
    aInteger := Integer(aValue);
  end;
end;

function TryVariantToStaticString(const aValue: OleVariant; out aText: string): Boolean;
begin
  aText := '';
  Result := VarIsStr(aValue);
  if Result then
  begin
    aText := string(aValue);
  end;
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
begin
  inherited Create;
  if Length(aRuntimeId) = 0 then
  begin
    raise EArgumentException.Create('Runtime ID must not be empty.');
  end;

  fApi := aApi;
  fHostProviderCacheResult := S_FALSE;
  fHwnd := aHwnd;
  fOverrideNativeProvider := aHwnd <> 0;
  fParentIndex := -1;
  fUseHostRawElementProvider := True;
  CopyRuntimeIdBlock(aRuntimeId, fRuntimeId);

  if aOwner <> nil then
  begin
    SetOwnerLink(TAccessibilityProviderOwnerLink.Create(aOwner, Self));
  end;
end;

destructor TAccessibilityProviderNode.Destroy;
begin
  ClearHostProviderCache;
  DetachChildrenFromParentDestruction;
  fOwnerLink.Free;
  fProperties.Free;
  fChildren.Free;
  inherited Destroy;
end;

function TAccessibilityProviderNode.DirectChildAt(aIndex: Integer; out aProvider: IRawElementProviderSimple):
  HResult;
var
  lChild: IAccessibilityProviderNode;
begin
  aProvider := nil;
  if aIndex < 0 then
  begin
    Exit(E_INVALIDARG);
  end;

  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if fDirectChildAccessReadsRemaining > 0 then
  begin
    Dec(fDirectChildAccessReadsRemaining);
  end else begin
    PrepareChildrenForNavigation;
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;
  end;

  if aIndex >= ChildCount then
  begin
    Exit(S_FALSE);
  end;

  lChild := ChildProviderAt(aIndex);
  if lChild = nil then
  begin
    Exit(S_FALSE);
  end;

  aProvider := lChild.RawElementProvider;
  Result := S_OK;
end;

function TAccessibilityProviderNode.DirectChildCount(out aCount: Integer): HResult;
begin
  aCount := 0;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  PrepareChildrenForNavigation;
  if fDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aCount := ChildCount;
  fDirectChildAccessReadsRemaining := aCount;
  Result := S_OK;
end;

procedure TAccessibilityProviderNode.AddChild(const aChild: IAccessibilityProviderNode);
begin
  InsertChildNode(ChildCount, aChild);
end;

procedure TAccessibilityProviderNode.InsertChildNode(aIndex: Integer;
  const aChild: IAccessibilityProviderNode);
var
  lChild: TAccessibilityProviderNode;
  lChildren: TList<IAccessibilityProviderNode>;
  lInsertedIndex: Integer;
begin
  lChild := FromNode(aChild);
  if lChild.fParent <> nil then
  begin
    raise EInvalidOperation.Create('Provider node already has a parent.');
  end;

  lChildren := EnsureChildren;
  if (aIndex < 0) or (aIndex > lChildren.Count) then
  begin
    raise EArgumentOutOfRangeException.CreateFmt('Child index %d is outside 0..%d.',
      [aIndex, lChildren.Count]);
  end;

  fDirectChildAccessReadsRemaining := 0;
  try
    InsertChildIntoList(lChildren, aIndex, aChild);
    lChild.AssignApiRecursive(fApi);
    lChild.UpdateFragmentRootCacheRecursive(FragmentRootNodeCachedOrComputed);
    lChild.fParent := Self;
    RefreshChildIndexesFrom(aIndex);
  except
    lChild.fParent := nil;
    lChild.fParentIndex := -1;
    lChild.UpdateFragmentRootCacheRecursive(nil);
    lInsertedIndex := lChildren.IndexOf(aChild);
    if lInsertedIndex >= 0 then
    begin
      lChildren.Delete(lInsertedIndex);
      RefreshChildIndexesFrom(lInsertedIndex);
    end;
    raise;
  end;
end;

procedure TAccessibilityProviderNode.InsertChildIntoList(aChildren: TList<IAccessibilityProviderNode>;
  aIndex: Integer; const aChild: IAccessibilityProviderNode);
begin
  aChildren.Insert(aIndex, aChild);
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
  if fChildren = nil then
  begin
    Exit;
  end;

  for lChild in fChildren do
  begin
    FromNode(lChild).AssignApiRecursive(lEffectiveApi);
  end;
end;

procedure TAccessibilityProviderNode.ClearHostProviderCache;
begin
  fHostRawElementProvider := nil;
  fHostProviderCacheResult := S_FALSE;
  fHostProviderCacheValid := False;
end;

function TAccessibilityProviderNode.ChildCount: Integer;
begin
  if fChildren = nil then
  begin
    Exit(0);
  end;

  Result := fChildren.Count;
end;

function TAccessibilityProviderNode.ChildIndex(aChild: TAccessibilityProviderNode): Integer;
var
  i: Integer;
begin
  if (aChild = nil) or (fChildren = nil) then
  begin
    if aChild <> nil then
    begin
      aChild.fParentIndex := -1;
    end;
    Exit(-1);
  end;

  Result := aChild.fParentIndex;
  if (Result >= 0) and (Result < fChildren.Count) and (FromNode(fChildren[Result]) = aChild) then
  begin
    Exit;
  end;

  for i := 0 to Pred(fChildren.Count) do
  begin
    if FromNode(fChildren[i]) = aChild then
    begin
      aChild.fParentIndex := i;
      Exit(i);
    end;
  end;

  aChild.fParentIndex := -1;
  Result := -1;
end;

function TAccessibilityProviderNode.ChildProviderAt(aIndex: Integer): IAccessibilityProviderNode;
begin
  if (fChildren = nil) or (aIndex < 0) or (aIndex >= fChildren.Count) then
  begin
    Exit(nil);
  end;

  Result := fChildren[aIndex];
end;

function TAccessibilityProviderNode.CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean;
begin
  Result := fChildrenPreparedForNavigation and HasCurrentChildIndex(aChild);
end;

function TAccessibilityProviderNode.HasCurrentChildIndex(aChild: TAccessibilityProviderNode): Boolean;
begin
  Result := (fChildren <> nil) and (aChild <> nil) and (aChild.fParent = Self) and (aChild.fParentIndex >= 0) and
    (aChild.fParentIndex < fChildren.Count) and (FromNode(fChildren[aChild.fParentIndex]) = aChild);
end;

function TAccessibilityProviderNode.ParentRawElementProvider: IRawElementProviderSimple;
begin
  Result := nil;
  if fDisconnected or (fParent = nil) then
  begin
    Exit;
  end;

  Result := fParent.RawElementProvider;
end;

function TAccessibilityProviderNode.CreateRuntimeIdSafeArray: PSafeArray;
var
  lData: Pointer;
begin
  Result := SafeArrayCreateVector(VT_I4, 0, Length(fRuntimeId) + 1);
  if Result = nil then
  begin
    Exit;
  end;

  lData := nil;
  if (SafeArrayAccessData(Result, lData) <> S_OK) or (lData = nil) then
  begin
    SafeArrayDestroy(Result);
    Exit(nil);
  end;

  try
    PInteger(lData)^ := UiaAppendRuntimeId;
    if Length(fRuntimeId) > 0 then
    begin
      Move(fRuntimeId[0], PInteger(NativeUInt(lData) + SizeOf(Integer))^, Length(fRuntimeId) * SizeOf(Integer));
    end;
  finally
    SafeArrayUnaccessData(Result);
  end;
end;

procedure TAccessibilityProviderNode.DetachChildrenFromParentDestruction;
var
  lChild: IAccessibilityProviderNode;
begin
  fChildrenPreparedForNavigation := False;
  if fChildren = nil then
  begin
    Exit;
  end;

  for lChild in fChildren do
  begin
    FromNode(lChild).DetachFromParentDestruction;
  end;
end;

procedure TAccessibilityProviderNode.DetachFromParentDestruction;
begin
  fParent := nil;
  fParentIndex := -1;
  fFragmentRootNode := nil;
  fDisconnected := True;
  fChildrenPreparedForNavigation := False;
  fDirectChildAccessReadsRemaining := 0;
  ClearHostProviderCache;
  DetachChildrenFromParentDestruction;
end;

procedure TAccessibilityProviderNode.Disconnect;
var
  lFirstException: TObject;
begin
  if fDisconnected then
  begin
    Exit;
  end;

  lFirstException := nil;
  MarkDisconnectedRecursive;
  try
    NotifyDisconnectedRecursive(lFirstException);
    RaiseCapturedException(lFirstException);
  finally
    lFirstException.Free;
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
      if fPublishNativeWindowHandle and (fHwnd <> 0) then
      begin
        aValue := NativeInt(fHwnd);
      end else begin
        Result := False;
      end;
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
  lChildCount: Integer;
  lDeeperProvider: IRawElementProviderFragment;
begin
  aProvider := nil;
  Result := False;
  if fDisconnected then
  begin
    Exit;
  end;

  PrepareChildrenForNavigation;
  lChildCount := ChildCount;
  for i := Pred(lChildCount) downto 0 do
  begin
    lChild := FromNode(ChildProviderAt(i));
    if lChild.IsDisconnected or not lChild.DoGetBoundingRectangle(lBounds) or
      not UiaRectContainsPoint(lBounds, aX, aY) then
    begin
      Continue;
    end;

    if lChild.FindDescendantFromPoint(aX, aY, lDeeperProvider) then
    begin
      aProvider := lDeeperProvider;
    end else begin
      aProvider := lChild.FragmentProvider; //PALOFF WARN53 internal node exposes its UIA interface
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

function TAccessibilityProviderNode.FragmentRootNode: TAccessibilityProviderNode;
var
  lCandidate: TAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lCandidate := Self;
  while lCandidate <> nil do
  begin
    if Supports(lCandidate, IRawElementProviderFragmentRoot, lRoot) then
    begin
      Exit(lCandidate);
    end;

    lCandidate := lCandidate.fParent;
  end;

  Result := nil;
end;

function TAccessibilityProviderNode.FragmentRootNodeCachedOrComputed: TAccessibilityProviderNode;
begin
  Result := fFragmentRootNode;
  if Result = nil then
  begin
    Result := FragmentRootNode;
  end;
end;

function TAccessibilityProviderNode.EnsureChildren: TList<IAccessibilityProviderNode>;
begin
  if fChildren = nil then
  begin
    fChildren := TList<IAccessibilityProviderNode>.Create;
    TAccessibilityDiagnostics.RecordProviderChildListAllocation;
  end;

  Result := fChildren;
end;

function TAccessibilityProviderNode.Get_BoundingRectangle(out aRetVal: UiaRect): HResult;
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := Default(UiaRect);
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    DoGetBoundingRectangle(aRetVal);
    Result := S_OK;
  finally
    FinishProviderBoundaryTiming(pbcGetBoundingRectangle, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.Get_FragmentRoot(out aRetVal: IRawElementProviderFragmentRoot): HResult;
var
  lMetricsEnabled: Boolean;
  lRootNode: TAccessibilityProviderNode;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := nil;
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    lRootNode := FragmentRootNodeCachedOrComputed;
    if (lRootNode <> nil) and Supports(lRootNode, IRawElementProviderFragmentRoot, aRetVal) then
    begin
      Result := S_OK;
    end else begin
      Result := S_FALSE;
    end;
  finally
    FinishProviderBoundaryTiming(pbcGetFragmentRoot, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.Get_HostRawElementProvider(out aRetVal: IRawElementProviderSimple): HResult;
var
  lMetricsEnabled: Boolean;
  lPreviousBypassHwnd: HWND;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := nil;
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    if (not fPublishNativeWindowHandle) or (not fUseHostRawElementProvider) or (fHwnd = 0) or (fApi = nil) then
    begin
      Exit(S_FALSE);
    end;

    if fHostProviderCacheValid then
    begin
      aRetVal := fHostRawElementProvider;
      Exit(fHostProviderCacheResult);
    end;

    lPreviousBypassHwnd := gHostProviderBypassHwnd;
    gHostProviderBypassHwnd := fHwnd;
    try
      Result := fApi.HostProviderFromHwnd(fHwnd, aRetVal);
      fHostProviderCacheResult := Result;
      fHostRawElementProvider := aRetVal;
      fHostProviderCacheValid := True;
    finally
      gHostProviderBypassHwnd := lPreviousBypassHwnd;
    end;
  finally
    FinishProviderBoundaryTiming(pbcGetHostRawElementProvider, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.Get_ProviderOptions(out aRetVal: ProviderOptions): HResult;
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := ProviderOptions_ServerSideProvider;
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    if fOverrideNativeProvider and (fHwnd <> 0) then
    begin
      aRetVal := aRetVal or ProviderOptions_OverrideProvider;
    end;

    Result := S_OK;
  finally
    FinishProviderBoundaryTiming(pbcGetProviderOptions, lStopwatch, lMetricsEnabled);
  end;
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
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := nil;
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    aRetVal := DoGetPatternProvider(aPatternId);
    Result := S_OK;
  finally
    FinishProviderBoundaryTiming(pbcGetPatternProvider, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.GetPropertyValue(aPropertyId: PROPERTYID; out aRetVal: OleVariant): HResult;
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
  lValue: OleVariant;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := Unassigned;
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    if TryGetPropertyValueDirect(aPropertyId, lValue) then
    begin
      aRetVal := lValue;
    end;

    Result := S_OK;
  finally
    FinishProviderBoundaryTiming(pbcGetPropertyValue, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.GetRuntimeId(out aRetVal: PSafeArray): HResult;
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
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
  finally
    FinishProviderBoundaryTiming(pbcGetRuntimeId, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.IsDisconnected: Boolean;
begin
  Result := fDisconnected;
end;

function TAccessibilityProviderNode.Navigate(aDirection: NavigateDirection;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lChildCount: Integer;
  lIndex: Integer;
  lMetricsEnabled: Boolean;
  lParent: TAccessibilityProviderNode;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
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
          if not lParent.CanUsePreparedSiblingNavigation(Self) then
          begin
            lParent.PrepareChildrenForNavigation;
            if fDisconnected or (fParent <> lParent) then
            begin
              Exit(S_OK);
            end;
          end;

          lIndex := lParent.ChildIndex(Self);
          lChildCount := lParent.ChildCount;
          if (lIndex >= 0) and (lIndex < Pred(lChildCount)) then
          begin
            aRetVal := lParent.ChildProviderAt(lIndex + 1).FragmentProvider; //PALOFF WARN53 internal node exposes its UIA interface
          end;
        end;
      NavigateDirection_PreviousSibling:
        if fParent <> nil then
        begin
          lParent := fParent;
          if not lParent.CanUsePreparedSiblingNavigation(Self) then
          begin
            lParent.PrepareChildrenForNavigation;
            if fDisconnected or (fParent <> lParent) then
            begin
              Exit(S_OK);
            end;
          end;

          lIndex := lParent.ChildIndex(Self);
          if lIndex > 0 then
          begin
            aRetVal := lParent.ChildProviderAt(lIndex - 1).FragmentProvider; //PALOFF WARN53 internal node exposes its UIA interface
          end;
        end;
      NavigateDirection_FirstChild:
        begin
          PrepareChildrenForNavigation;
          if ChildCount > 0 then
          begin
            aRetVal := ChildProviderAt(0).FragmentProvider;
          end;
        end;
      NavigateDirection_LastChild:
        begin
          PrepareChildrenForNavigation;
          lChildCount := ChildCount;
          if lChildCount > 0 then
          begin
            aRetVal := ChildProviderAt(Pred(lChildCount)).FragmentProvider;
          end;
        end;
    else
      Result := E_INVALIDARG;
      Exit;
    end;

    Result := S_OK;
  finally
    FinishProviderBoundaryTiming(pbcNavigate, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.NativeWindowHandle: HWND;
begin
  Result := fHwnd;
end;

function TAccessibilityProviderNode.ProviderObject: TObject;
begin
  Result := Self;
end;

procedure TAccessibilityProviderNode.PrepareChildrenForNavigation;
begin
  fChildrenPreparedForNavigation := True;
end;

function TAccessibilityProviderNode.BuildChildRemovalFlags(
  const aChildren: TArray<IAccessibilityProviderNode>; out aRemovedCount: Integer): TArray<Boolean>;
var
  lChild: IAccessibilityProviderNode;
  lChildNode: TAccessibilityProviderNode;
  lIndex: Integer;
begin
  SetLength(Result, fChildren.Count);
  aRemovedCount := 0;
  for lChild in aChildren do
  begin
    if lChild = nil then
    begin
      Continue;
    end;

    lChildNode := FromNode(lChild);
    if lChildNode.fParent <> Self then
    begin
      Continue;
    end;
    lIndex := ChildIndex(lChildNode);
    if (lIndex >= 0) and not Result[lIndex] then
    begin
      Result[lIndex] := True;
      Inc(aRemovedCount);
    end;
  end;
end;

procedure TAccessibilityProviderNode.ClearRemovedChildParents(
  aChildren: TList<IAccessibilityProviderNode>; const aRemovalFlags: TArray<Boolean>);
var
  i: Integer;
  lChildNode: TAccessibilityProviderNode;
begin
  for i := 0 to Pred(aChildren.Count) do
  begin
    if aRemovalFlags[i] then
    begin
      lChildNode := FromNode(aChildren[i]);
      lChildNode.fParent := nil;
      lChildNode.fParentIndex := -1;
    end;
  end;
end;

function TAccessibilityProviderNode.CreateRetainedChildren(
  const aRemovalFlags: TArray<Boolean>; aRemovedCount: Integer): TList<IAccessibilityProviderNode>;
var
  i: Integer;
begin
  Result := TList<IAccessibilityProviderNode>.Create;
  try
    Result.Capacity := fChildren.Count - aRemovedCount;
    for i := 0 to Pred(fChildren.Count) do
    begin
      if not aRemovalFlags[i] then
      begin
        Result.Add(fChildren[i]);
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TAccessibilityProviderNode.FinalizeRemovedChildren(
  aChildren: TList<IAccessibilityProviderNode>; const aRemovalFlags: TArray<Boolean>;
  aDisconnect: Boolean);
var
  i: Integer;
  lChild: IAccessibilityProviderNode;
  lFirstException: TObject;
begin
  if aDisconnect then
  begin
    for i := 0 to Pred(aChildren.Count) do
    begin
      if aRemovalFlags[i] then
      begin
        FromNode(aChildren[i]).MarkDisconnectedRecursive;
      end;
    end;

    lFirstException := nil;
    try
      for i := 0 to Pred(aChildren.Count) do
      begin
        if aRemovalFlags[i] then
        begin
          FromNode(aChildren[i]).NotifyDisconnectedRecursive(lFirstException);
        end;
      end;
      RaiseCapturedException(lFirstException);
    finally
      lFirstException.Free;
    end;
    Exit;
  end;

  for i := 0 to Pred(aChildren.Count) do
  begin
    if aRemovalFlags[i] then
    begin
      lChild := aChildren[i]; //PALOFF WARN53 interface ownership is retained by the scan graph
      FromNode(lChild).DetachFromParentDestruction;
    end;
  end;
end;

procedure TAccessibilityProviderNode.MarkDisconnectedRecursive;
var
  lChild: IAccessibilityProviderNode;
begin
  if fDisconnected then
  begin
    Exit;
  end;

  fDisconnected := True;
  fDisconnectNotificationPending := fApi <> nil;
  fFragmentRootNode := nil;
  fChildrenPreparedForNavigation := False;
  fDirectChildAccessReadsRemaining := 0;
  ClearHostProviderCache;
  if fChildren <> nil then
  begin
    for lChild in fChildren do
    begin
      FromNode(lChild).MarkDisconnectedRecursive;
    end;
  end;
end;

procedure TAccessibilityProviderNode.NotifyDisconnectedRecursive(var aFirstException: TObject);
var
  lChild: IAccessibilityProviderNode;
begin
  if fChildren <> nil then
  begin
    for lChild in fChildren do
    begin
      FromNode(lChild).NotifyDisconnectedRecursive(aFirstException);
    end;
  end;

  if not fDisconnectNotificationPending then
  begin
    Exit;
  end;

  fDisconnectNotificationPending := False;
  try
    fApi.DisconnectProvider(RawElementProvider);
  except
    if aFirstException = nil then
    begin
      aFirstException := AcquireExceptionObject;
    end;
  end;
end;

class procedure TAccessibilityProviderNode.RaiseCapturedException(var aException: TObject);
var
  lException: TObject;
begin
  lException := aException;
  aException := nil;
  if lException <> nil then
  begin
    raise lException;
  end;
end;

procedure TAccessibilityProviderNode.RemoveChildNode(const aChild: IAccessibilityProviderNode;
  aDisconnect: Boolean);
var
  lChild: TAccessibilityProviderNode;
  lIndex: Integer;
begin
  if (aChild = nil) or (fChildren = nil) then
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
  fChildrenPreparedForNavigation := False;
  fDirectChildAccessReadsRemaining := 0;
  lChild.fParent := nil;
  lChild.fParentIndex := -1;
  RefreshChildIndexesFrom(lIndex);
  if aDisconnect then
  begin
    aChild.Disconnect;
  end else begin
    lChild.DetachFromParentDestruction;
  end;
end;

procedure TAccessibilityProviderNode.RemoveChildNodes(const aChildren: TArray<IAccessibilityProviderNode>;
  aDisconnect: Boolean);
var
  lRemovalFlags: TArray<Boolean>;
  lRemovedCount: Integer;
begin
  if (Length(aChildren) = 0) or (fChildren = nil) then
  begin
    Exit;
  end;

  lRemovalFlags := BuildChildRemovalFlags(aChildren, lRemovedCount);
  if lRemovedCount = 0 then
  begin
    Exit;
  end;

  if not RemoveChildNodesByIndexFlags(lRemovalFlags, lRemovedCount, aDisconnect) then
  begin
    raise EInvalidOperation.Create('Provider child removal flags no longer match the child list.');
  end;
end;

function TAccessibilityProviderNode.RemoveChildNodesByIndexFlags(
  const aRemovalFlags: TArray<Boolean>; aRemovedCount: Integer; aDisconnect: Boolean): Boolean;
var
  lOldChildren: TList<IAccessibilityProviderNode>;
  lRetainedChildren: TList<IAccessibilityProviderNode>;
begin
  Result := (fChildren <> nil) and (aRemovedCount >= 0) and
    (aRemovedCount <= fChildren.Count) and
    (Length(aRemovalFlags) = fChildren.Count);
  if not Result or (aRemovedCount = 0) then
  begin
    Exit;
  end;

  lRetainedChildren := nil;
  try
    lRetainedChildren := CreateRetainedChildren(aRemovalFlags, aRemovedCount);
    lOldChildren := fChildren;
    fChildren := lRetainedChildren;
    lRetainedChildren := nil;
    try
      ClearRemovedChildParents(lOldChildren, aRemovalFlags);
      fChildrenPreparedForNavigation := False;
      fDirectChildAccessReadsRemaining := 0;
      RefreshChildIndexesFrom(0);
      FinalizeRemovedChildren(lOldChildren, aRemovalFlags, aDisconnect);
    finally
      lOldChildren.Free;
    end;
  finally
    lRetainedChildren.Free;
  end;
end;

procedure TAccessibilityProviderNode.RefreshChildIndexesFrom(aStartIndex: Integer);
var
  i: Integer;
begin
  if fChildren = nil then
  begin
    Exit;
  end;

  for i := aStartIndex to Pred(fChildren.Count) do
  begin
    FromNode(fChildren[i]).fParentIndex := i;
  end;
end;

function TAccessibilityProviderNode.RawElementProvider: IRawElementProviderSimple;
begin
  Result := Self as IRawElementProviderSimple;
end;

function TAccessibilityProviderNode.SetFocus: HResult;
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    if fDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    Result := DoSetFocus;
  finally
    FinishProviderBoundaryTiming(pbcSetFocus, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderNode.SupportsPatternDirect(aPatternId: PATTERNID): Boolean;
var
  lPattern: IUnknown;
  lPropertyId: PROPERTYID;
  lValue: OleVariant;
begin
  Result := False;
  if fDisconnected then
  begin
    Exit;
  end;

  if DirectStatePropertyForPattern(aPatternId, lPropertyId) and TryGetPropertyValueDirect(lPropertyId, lValue) and
    (not VarIsEmpty(lValue)) and (not VarIsNull(lValue)) then
  begin
    Exit(True);
  end;

  lPattern := DoGetPatternProvider(aPatternId);
  Result := lPattern <> nil;
end;

procedure TAccessibilityProviderNode.SetOwnerLink(aOwnerLink: TComponent);
begin
  fOwnerLink.Free;
  fOwnerLink := aOwnerLink;
end;

procedure TAccessibilityProviderNode.RemoveFallbackProperty(aPropertyId: PROPERTYID);
begin
  if fProperties <> nil then
  begin
    fProperties.Remove(aPropertyId);
  end;
end;

procedure TAccessibilityProviderNode.SetFallbackProperty(aPropertyId: PROPERTYID; const aValue: OleVariant);
begin
  if fProperties = nil then
  begin
    fProperties := TDictionary<PROPERTYID, OleVariant>.Create;
  end;

  fProperties.AddOrSetValue(aPropertyId, aValue);
end;

procedure TAccessibilityProviderNode.SetTypedIntegerProperty(aPropertyId: PROPERTYID; const aValue: OleVariant;
  var aStorage: Integer; var aHasStorage: Boolean);
var
  lValue: Integer;
begin
  if TryVariantToStaticInteger(aValue, lValue) then
  begin
    aStorage := lValue;
    aHasStorage := True;
    RemoveFallbackProperty(aPropertyId);
  end else begin
    aStorage := 0;
    aHasStorage := False;
    SetFallbackProperty(aPropertyId, aValue);
  end;
end;

procedure TAccessibilityProviderNode.SetTypedStringProperty(aPropertyId: PROPERTYID; const aValue: OleVariant;
  var aStorage: string; var aHasStorage: Boolean);
var
  lValue: string;
begin
  if TryVariantToStaticString(aValue, lValue) then
  begin
    aStorage := lValue;
    aHasStorage := True;
    RemoveFallbackProperty(aPropertyId);
  end else begin
    aStorage := '';
    aHasStorage := False;
    SetFallbackProperty(aPropertyId, aValue);
  end;
end;

function TAccessibilityProviderNode.TryGetFallbackProperty(aPropertyId: PROPERTYID; out aValue: OleVariant):
  Boolean;
begin
  Result := (fProperties <> nil) and fProperties.TryGetValue(aPropertyId, aValue);
end;

procedure TAccessibilityProviderNode.SetOverrideNativeProvider(aValue: Boolean);
begin
  fOverrideNativeProvider := aValue;
end;

procedure TAccessibilityProviderNode.SetPublishNativeWindowHandle(aValue: Boolean);
begin
  if fPublishNativeWindowHandle <> aValue then
  begin
    ClearHostProviderCache;
  end;

  if aValue then
  begin
    SetOverrideNativeProvider(True);
  end;

  fPublishNativeWindowHandle := aValue;
end;

procedure TAccessibilityProviderNode.SetUseHostRawElementProvider(aValue: Boolean);
begin
  if fUseHostRawElementProvider <> aValue then
  begin
    ClearHostProviderCache;
  end;

  fUseHostRawElementProvider := aValue;
end;

procedure TAccessibilityProviderNode.SetProperty(aPropertyId: PROPERTYID; const aValue: OleVariant);
begin
  case aPropertyId of
    UIA_AutomationIdPropertyId:
      SetTypedStringProperty(aPropertyId, aValue, fAutomationIdProperty, fHasAutomationIdProperty);
    UIA_ClassNamePropertyId:
      SetTypedStringProperty(aPropertyId, aValue, fClassNameProperty, fHasClassNameProperty);
    UIA_ControlTypePropertyId:
      SetTypedIntegerProperty(aPropertyId, aValue, fControlTypeProperty, fHasControlTypeProperty);
    UIA_FrameworkIdPropertyId:
      SetTypedStringProperty(aPropertyId, aValue, fFrameworkIdProperty, fHasFrameworkIdProperty);
    UIA_HelpTextPropertyId:
      SetTypedStringProperty(aPropertyId, aValue, fHelpTextProperty, fHasHelpTextProperty);
    UIA_ItemStatusPropertyId:
      SetTypedStringProperty(aPropertyId, aValue, fItemStatusProperty, fHasItemStatusProperty);
    UIA_ItemTypePropertyId:
      SetTypedStringProperty(aPropertyId, aValue, fItemTypeProperty, fHasItemTypeProperty);
    UIA_NamePropertyId:
      SetTypedStringProperty(aPropertyId, aValue, fNameProperty, fHasNameProperty);
  else
    SetFallbackProperty(aPropertyId, aValue);
  end;
end;

procedure TAccessibilityProviderNode.UpdateFragmentRootCacheRecursive(aNearestRoot: TAccessibilityProviderNode);
var
  lChild: IAccessibilityProviderNode;
  lRootNode: TAccessibilityProviderNode;
begin
  lRootNode := aNearestRoot;
  if Self is TAccessibilityProviderRoot then
  begin
    lRootNode := Self;
  end;

  fFragmentRootNode := lRootNode;
  if fChildren = nil then
  begin
    Exit;
  end;

  for lChild in fChildren do
  begin
    FromNode(lChild).UpdateFragmentRootCacheRecursive(lRootNode);
  end;
end;

function TAccessibilityProviderNode.TryGetIntegerProperty(aPropertyId: PROPERTYID; out aValue: Integer): Boolean;
var
  lValue: OleVariant;
begin
  aValue := 0;
  if (aPropertyId = UIA_ControlTypePropertyId) and fHasControlTypeProperty then
  begin
    aValue := fControlTypeProperty;
    Exit(True);
  end;

  Result := TryGetPropertyValueDirect(aPropertyId, lValue) and not VarIsEmpty(lValue) and not VarIsNull(lValue);
  if Result then
  begin
    aValue := Integer(lValue);
  end;
end;

function TAccessibilityProviderNode.TryGetBoundingRectangle(out aValue: UiaRect): Boolean;
begin
  aValue := Default(UiaRect);
  Result := not fDisconnected;
  if Result then
  begin
    DoGetBoundingRectangle(aValue);
  end;
end;

function TAccessibilityProviderNode.TryGetNativeWindowHandle(out aValue: HWND): Boolean;
begin
  aValue := 0;
  Result := (not fDisconnected) and (fHwnd <> 0);
  if Result then
  begin
    aValue := fHwnd;
  end;
end;

function TAccessibilityProviderNode.TryGetStoredPropertyValue(aPropertyId: PROPERTYID;
  out aValue: OleVariant): Boolean;
begin
  aValue := Unassigned;
  case aPropertyId of
    UIA_AutomationIdPropertyId:
      begin
        Result := fHasAutomationIdProperty;
        if Result then
        begin
          aValue := fAutomationIdProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
    UIA_ClassNamePropertyId:
      begin
        Result := fHasClassNameProperty;
        if Result then
        begin
          aValue := fClassNameProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
    UIA_ControlTypePropertyId:
      begin
        Result := fHasControlTypeProperty;
        if Result then
        begin
          aValue := fControlTypeProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
    UIA_FrameworkIdPropertyId:
      begin
        Result := fHasFrameworkIdProperty;
        if Result then
        begin
          aValue := fFrameworkIdProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
    UIA_HelpTextPropertyId:
      begin
        Result := fHasHelpTextProperty;
        if Result then
        begin
          aValue := fHelpTextProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
    UIA_ItemStatusPropertyId:
      begin
        Result := fHasItemStatusProperty;
        if Result then
        begin
          aValue := fItemStatusProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
    UIA_ItemTypePropertyId:
      begin
        Result := fHasItemTypeProperty;
        if Result then
        begin
          aValue := fItemTypeProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
    UIA_NamePropertyId:
      begin
        Result := fHasNameProperty;
        if Result then
        begin
          aValue := fNameProperty;
        end else begin
          Result := TryGetFallbackProperty(aPropertyId, aValue);
        end;
      end;
  else
    Result := TryGetFallbackProperty(aPropertyId, aValue);
  end;
end;

function TAccessibilityProviderNode.TryGetPropertyValueDirect(aPropertyId: PROPERTYID; out aValue: OleVariant):
  Boolean;
var
  lValue: OleVariant;
begin
  aValue := Unassigned;
  if fDisconnected then
  begin
    Exit(False);
  end;

  Result := TryGetStoredPropertyValue(aPropertyId, lValue) or DoGetPropertyValue(aPropertyId, lValue);
  if Result then
  begin
    aValue := lValue;
  end;
end;

function TAccessibilityProviderNode.TryGetStringProperty(aPropertyId: PROPERTYID; out aValue: string): Boolean;
var
  lValue: OleVariant;
begin
  aValue := '';
  case aPropertyId of
    UIA_AutomationIdPropertyId:
      if fHasAutomationIdProperty then
      begin
        aValue := fAutomationIdProperty;
        Exit(True);
      end;
    UIA_ClassNamePropertyId:
      if fHasClassNameProperty then
      begin
        aValue := fClassNameProperty;
        Exit(True);
      end;
    UIA_FrameworkIdPropertyId:
      if fHasFrameworkIdProperty then
      begin
        aValue := fFrameworkIdProperty;
        Exit(True);
      end;
    UIA_HelpTextPropertyId:
      if fHasHelpTextProperty then
      begin
        aValue := fHelpTextProperty;
        Exit(True);
      end;
    UIA_ItemStatusPropertyId:
      if fHasItemStatusProperty then
      begin
        aValue := fItemStatusProperty;
        Exit(True);
      end;
    UIA_ItemTypePropertyId:
      if fHasItemTypeProperty then
      begin
        aValue := fItemTypeProperty;
        Exit(True);
      end;
    UIA_NamePropertyId:
      if fHasNameProperty then
      begin
        aValue := fNameProperty;
        Exit(True);
      end;
  end;

  Result := TryGetPropertyValueDirect(aPropertyId, lValue) and not VarIsEmpty(lValue) and not VarIsNull(lValue);
  if Result then
  begin
    aValue := string(lValue);
  end;
end;

function TAccessibilityProviderNode.TryGetSpeechProperties(out aName: string; out aValueText: string;
  out aHelpText: string): Boolean;
begin
  aName := '';
  aValueText := '';
  aHelpText := '';
  Result := not fDisconnected;
  if not Result then
  begin
    Exit;
  end;

  if fHasNameProperty then
  begin
    aName := fNameProperty;
  end else begin
    TryGetStringProperty(UIA_NamePropertyId, aName);
  end;

  TryGetValueText(aValueText);
  if fHasHelpTextProperty then
  begin
    aHelpText := fHelpTextProperty;
  end else begin
    TryGetStringProperty(UIA_HelpTextPropertyId, aHelpText);
  end;
end;

function TAccessibilityProviderNode.TryGetValueText(out aValue: string): Boolean;
var
  lPattern: IUnknown;
  lValue: WideString;
  lValueProvider: IValueProvider;
begin
  aValue := '';
  Result := False;
  if fDisconnected then
  begin
    Exit;
  end;

  lPattern := DoGetPatternProvider(UIA_ValuePatternId);
  if not Supports(lPattern, IValueProvider, lValueProvider) then
  begin
    Exit;
  end;

  lValue := '';
  Result := lValueProvider.Get_Value(lValue) = S_OK;
  if Result then
  begin
    aValue := string(lValue);
  end;
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

function TAccessibilityProviderRoot.DirectElementProviderFromPoint(aX: Double; aY: Double;
  out aProvider: IRawElementProviderSimple): HResult;
var
  lProvider: IRawElementProviderFragment;
begin
  aProvider := nil;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lProvider := nil;
  Result := DoElementProviderFromPoint(aX, aY, lProvider);
  if (Result = S_OK) and (lProvider <> nil) and not Supports(lProvider, IRawElementProviderSimple, aProvider) then
  begin
    Result := E_NOINTERFACE;
  end;
end;

function TAccessibilityProviderRoot.ElementProviderFromPoint(aX: Double; aY: Double;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := nil;
    if IsDisconnected then
    begin
      if TAccessibilityDiagnostics.Enabled then
      begin
        TAccessibilityDiagnostics.Log(Format(
          'UIA ElementProviderFromPoint x=%.0f y=%.0f result=UIA_E_ELEMENTNOTAVAILABLE', [aX, aY]));
      end;
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    Result := DoElementProviderFromPoint(aX, aY, aRetVal);
    if TAccessibilityDiagnostics.Enabled then
    begin
      TAccessibilityDiagnostics.Log(Format(
        'UIA ElementProviderFromPoint x=%.0f y=%.0f hresult=$%s providerPresent=%s',
        [aX, aY, SignedDWordHex(Result), BoolToStr(aRetVal <> nil, True)]));
    end;
  finally
    FinishProviderBoundaryTiming(pbcRootElementProviderFromPoint, lStopwatch, lMetricsEnabled);
  end;
end;

function TAccessibilityProviderRoot.GetFocus(out aRetVal: IRawElementProviderFragment): HResult;
var
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  StartProviderBoundaryTiming(lStopwatch, lMetricsEnabled);
  try
    aRetVal := nil;
    if IsDisconnected then
    begin
      Exit(UIA_E_ELEMENTNOTAVAILABLE);
    end;

    Result := DoGetFocus(aRetVal);
  finally
    FinishProviderBoundaryTiming(pbcRootGetFocus, lStopwatch, lMetricsEnabled);
  end;
end;

class function TAccessibilityProviderFactory.CreateFragment(const aRuntimeId: array of Integer;
  const aApi: IAccessibilityUiaApi; aOwner: TComponent): IAccessibilityProviderNode;
begin
  Result := TAccessibilityProviderNode.CreateNode(aRuntimeId, 0, aApi, aOwner);
end;

class function TAccessibilityProviderFactory.CreateRoot(const aRuntimeId: array of Integer; aHwnd: HWND;
  const aApi: IAccessibilityUiaApi; aOwner: TComponent): IAccessibilityProviderNode;
var
  lRootNode: TAccessibilityProviderNode;
begin
  lRootNode := TAccessibilityProviderRoot.CreateNode(aRuntimeId, aHwnd, ResolveApi(aApi), aOwner);
  lRootNode.UpdateFragmentRootCacheRecursive(nil);
  Result := lRootNode; //PALOFF WARN53 factory returns the node interface
end;

class procedure TAccessibilityProviderEvents.BeginEventBatch;
begin
  if gEventBatchDepth = 0 then
  begin
    gEventBatchClientsAreListening := False;
    gEventBatchHasClientsAreListening := False;
    TAccessibilityDiagnostics.RecordProviderEventBatch;
  end;

  Inc(gEventBatchDepth);
end;

class procedure TAccessibilityProviderEvents.BeginEventBatchWithKnownClientState(aClientsAreListening: Boolean);
begin
  BeginEventBatch;
  if gEventBatchDepth = 1 then
  begin
    gEventBatchClientsAreListening := aClientsAreListening;
    gEventBatchHasClientsAreListening := True;
  end;
end;

class function TAccessibilityProviderEvents.ClientsAreListening(const aApi: IAccessibilityUiaApi): Boolean;
var
  lApi: IAccessibilityUiaApi;
begin
  Result := ResolveEventApiAndCheckClientsAreListening(aApi, lApi);
end;

class procedure TAccessibilityProviderEvents.EndEventBatch;
begin
  if gEventBatchDepth <= 0 then
  begin
    Exit;
  end;

  Dec(gEventBatchDepth);
  if gEventBatchDepth = 0 then
  begin
    gEventBatchClientsAreListening := False;
    gEventBatchHasClientsAreListening := False;
  end;
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

  if not ResolveEventApiAndCheckClientsAreListening(aApi, lApi) then
  begin
    Exit;
  end;

  Result := lApi.RaiseAutomationEvent(aProvider, aEventId) = S_OK;
  if Result then
  begin
    TAccessibilityDiagnostics.RecordSupplementalUiaAutomationEvent(aEventId);
  end;
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

  if not ResolveEventApiAndCheckClientsAreListening(aApi, lApi) then
  begin
    Exit;
  end;

  Result := lApi.RaiseAutomationPropertyChanged(aProvider, aPropertyId, aOldValue, aNewValue) = S_OK;
  if Result then
  begin
    TAccessibilityDiagnostics.RecordSupplementalUiaPropertyChangedEvent(aPropertyId);
  end;
end;

class function TAccessibilityProviderEvents.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString; const aApi: IAccessibilityUiaApi): Boolean;
var
  lApi: IAccessibilityUiaApi;
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  if not ResolveEventApiAndCheckClientsAreListening(aApi, lApi) then
  begin
    Exit;
  end;

  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;
  try
    Result := lApi.RaiseNotification(aProvider, aNotificationKind, aNotificationProcessing, aDisplayString,
      aActivityId) = S_OK;
  finally
    if lMetricsEnabled then
    begin
      TAccessibilityDiagnostics.RecordProviderNotification(lStopwatch.ElapsedTicks);
    end;
  end;
  if Result then
  begin
    TAccessibilityDiagnostics.RecordSupplementalUiaNotificationEvent;
  end;
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

  if not ResolveEventApiAndCheckClientsAreListening(aApi, lApi) then
  begin
    Exit;
  end;

  Result := lApi.RaiseStructureChanged(aProvider, aStructureChangeType, CopyRuntimeId(aRuntimeId)) = S_OK;
  if Result then
  begin
    TAccessibilityDiagnostics.RecordSupplementalUiaStructureChangedEvent;
  end;
end;

class function TAccessibilityProviderWindowMessages.TryHandleGetObject(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple; const aApi: IAccessibilityUiaApi; out aResult: LRESULT): Boolean;
var
  lApi: IAccessibilityUiaApi;
begin
  aResult := 0;
  Result := False;
  if (aLParam = LPARAM(UiaRootObjectId)) and (gHostProviderBypassHwnd <> 0) and
    (aHwnd = gHostProviderBypassHwnd) then
  begin
    if TAccessibilityDiagnostics.Enabled then
    begin
      TAccessibilityDiagnostics.Log(Format('WM_GETOBJECT bypassed for native host provider hwnd=%d', [aHwnd]));
    end;
    Exit;
  end;

  if (aLParam <> LPARAM(UiaRootObjectId)) or (aProvider = nil) then
  begin
    if TAccessibilityDiagnostics.Enabled then
    begin
      TAccessibilityDiagnostics.Log(Format('WM_GETOBJECT ignored hwnd=%d lParam=%d providerPresent=%s',
        [aHwnd, aLParam, BoolToStr(aProvider <> nil, True)]));
    end;
    Exit;
  end;

  lApi := ResolveApi(aApi);
  aResult := lApi.ReturnRawElementProvider(aHwnd, aWParam, aLParam, aProvider);
  if TAccessibilityDiagnostics.Enabled then
  begin
    TAccessibilityDiagnostics.Log(Format(
      'WM_GETOBJECT returned framework provider hwnd=%d wParam=%d lParam=%d lResult=$%s',
      [aHwnd, aWParam, aLParam, SignedDWordHex(aResult)])); //PALOFF WARN63 WinAPI result formatting
  end;
  if aResult < 0 then
  begin
    if TAccessibilityDiagnostics.Enabled then
    begin
      TAccessibilityDiagnostics.Log(Format('WM_GETOBJECT framework provider rejected hwnd=%d; falling back to native',
        [aHwnd]));
    end;
    aResult := 0;
    Exit;
  end;

  Result := True;
end;

end.
