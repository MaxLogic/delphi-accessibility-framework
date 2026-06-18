unit MaxLogic.Accessibility.ProviderCore.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('ProviderCore')]
  TProviderCoreTests = class
  public
    [Test]
    procedure FragmentNavigationIsDeterministic;
    [Test]
    procedure FragmentOwnerDestroyDisconnectsFragmentProvider;
    [Test]
    procedure NestedSubtreeOwnerDestroyDisconnectsEveryProvider;
    [Test]
    procedure OwnerDestroyDisconnectsProviderOnce;
    [Test]
    procedure ProviderPropertiesAndRuntimeIdsAreExposed;
    [Test]
    procedure ProviderBaseClassesCanBeExtended;
    [Test]
    procedure RetainedChildProviderDisconnectsWhenParentIsDestroyed;
    [Test]
    procedure DisconnectedProvidersReturnElementUnavailable;
    [Test]
    procedure WmGetObjectReturnsRootProviderOnlyForUiaRequests;
    [Test]
    procedure AutomationEventsAreRaisedOnlyWhenClientsListen;
    [Test]
    procedure EventHelpersAreGatedForPropertyStructureAndNotification;
  end;

implementation

uses
  System.Classes, System.SysUtils, Winapi.ActiveX, Winapi.Windows,
  MaxLogic.Accessibility.ProviderCore,
  MaxLogic.Accessibility.UIAutomationCore;

type
  ITestUiaApi = interface(IAccessibilityUiaApi)
    ['{BD87F3C7-7C19-489C-9855-03A41E879476}']
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function LastNotificationKind: NotificationKind;
    function ReturnCalls: Integer;
    function LastEventId: EVENTID;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
    function LastPropertyId: PROPERTYID;
    function LastStructureChangeType: StructureChangeType;
    function NotificationCalls: Integer;
    function PropertyCalls: Integer;
    function StructureCalls: Integer;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  TTestUiaApi = class(TInterfacedObject, ITestUiaApi)
  private
    fClientsAreListening: Boolean;
    fDisconnectCalls: Integer;
    fEventCalls: Integer;
    fLastEventId: EVENTID;
    fLastHwnd: HWND;
    fLastLParam: LPARAM;
    fLastNotificationKind: NotificationKind;
    fLastPropertyId: PROPERTYID;
    fLastStructureChangeType: StructureChangeType;
    fNotificationCalls: Integer;
    fPropertyCalls: Integer;
    fReturnCalls: Integer;
    fStructureCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastEventId: EVENTID;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
    function LastNotificationKind: NotificationKind;
    function LastPropertyId: PROPERTYID;
    function LastStructureChangeType: StructureChangeType;
    function NotificationCalls: Integer;
    function PropertyCalls: Integer;
    function StructureCalls: Integer;
    function RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
    function RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID;
      const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
    function RaiseNotification(const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
      aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
      const aActivityId: WideString): HRESULT;
    function RaiseStructureChanged(const aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
      const aRuntimeId: TArray<Integer>): HRESULT;
    function ReturnCalls: Integer;
    function ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple): LRESULT;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  TNamedProviderNode = class(TAccessibilityProviderNode)
  protected
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create;
  end;

function RuntimeIdValue(const aProvider: IRawElementProviderFragment; aIndex: Integer): Integer;
var
  lArray: PSafeArray;
begin
  lArray := nil;
  Assert.AreEqual(S_OK, aProvider.GetRuntimeId(lArray));
  try
    Assert.IsNotNull(lArray);
    Result := 0;
    Assert.AreEqual(S_OK, SafeArrayGetElement(lArray, aIndex, Result));
  finally
    if lArray <> nil then
    begin
      SafeArrayDestroy(lArray);
    end;
  end;
end;

function TTestUiaApi.ClientsAreListening: Boolean;
begin
  Result := fClientsAreListening;
end;

function TTestUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Inc(fDisconnectCalls);
  Result := S_OK;
end;

function TTestUiaApi.DisconnectCalls: Integer;
begin
  Result := fDisconnectCalls;
end;

function TTestUiaApi.EventCalls: Integer;
begin
  Result := fEventCalls;
end;

function TTestUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function TTestUiaApi.LastEventId: EVENTID;
begin
  Result := fLastEventId;
end;

function TTestUiaApi.LastHwnd: HWND;
begin
  Result := fLastHwnd;
end;

function TTestUiaApi.LastLParam: LPARAM;
begin
  Result := fLastLParam;
end;

function TTestUiaApi.LastNotificationKind: NotificationKind;
begin
  Result := fLastNotificationKind;
end;

function TTestUiaApi.LastPropertyId: PROPERTYID;
begin
  Result := fLastPropertyId;
end;

function TTestUiaApi.LastStructureChangeType: StructureChangeType;
begin
  Result := fLastStructureChangeType;
end;

function TTestUiaApi.NotificationCalls: Integer;
begin
  Result := fNotificationCalls;
end;

function TTestUiaApi.PropertyCalls: Integer;
begin
  Result := fPropertyCalls;
end;

function TTestUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
begin
  Inc(fEventCalls);
  fLastEventId := aEventId;
  Result := S_OK;
end;

function TTestUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Inc(fPropertyCalls);
  fLastPropertyId := aPropertyId;
  Result := S_OK;
end;

function TTestUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Inc(fNotificationCalls);
  fLastNotificationKind := aNotificationKind;
  Result := S_OK;
end;

function TTestUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Inc(fStructureCalls);
  fLastStructureChangeType := aStructureChangeType;
  Result := S_OK;
end;

function TTestUiaApi.ReturnCalls: Integer;
begin
  Result := fReturnCalls;
end;

function TTestUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Inc(fReturnCalls);
  fLastHwnd := aHwnd;
  fLastLParam := aLParam;
  Result := 4242;
end;

procedure TTestUiaApi.SetClientsAreListening(aValue: Boolean);
begin
  fClientsAreListening := aValue;
end;

function TTestUiaApi.StructureCalls: Integer;
begin
  Result := fStructureCalls;
end;

constructor TNamedProviderNode.Create;
begin
  inherited CreateNode([909], 0, nil, nil);
end;

function TNamedProviderNode.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  if aPatternId = UIA_InvokePatternId then
  begin
    Exit(RawElementProvider as IUnknown);
  end;

  Result := inherited DoGetPatternProvider(aPatternId);
end;

function TNamedProviderNode.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
begin
  Result := aPropertyId = UIA_NamePropertyId;
  if Result then
  begin
    aValue := 'Subclass';
  end else begin
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

procedure TProviderCoreTests.AutomationEventsAreRaisedOnlyWhenClientsListen;
var
  lApi: ITestUiaApi;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lProvider := TAccessibilityProviderFactory.CreateRoot([10], 0, lApi);

  lApi.SetClientsAreListening(False);
  Assert.IsFalse(TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider.RawElementProvider,
    UIA_Invoke_InvokedEventId, lApi));
  Assert.AreEqual(0, lApi.EventCalls);

  lApi.SetClientsAreListening(True);
  Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider.RawElementProvider,
    UIA_Invoke_InvokedEventId, lApi));
  Assert.AreEqual(1, lApi.EventCalls);
  Assert.AreEqual(UIA_Invoke_InvokedEventId, lApi.LastEventId);
end;

procedure TProviderCoreTests.DisconnectedProvidersReturnElementUnavailable;
var
  lArray: PSafeArray;
  lFragment: IRawElementProviderFragment;
  lFragmentRoot: IRawElementProviderFragmentRoot;
  lProvider: IAccessibilityProviderNode;
  lValue: OleVariant;
begin
  lProvider := TAccessibilityProviderFactory.CreateRoot([10], 0);
  lProvider.SetProperty(UIA_NamePropertyId, 'Gone');
  lProvider.Disconnect;

  lArray := nil;
  Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
    lProvider.RawElementProvider.GetPropertyValue(UIA_NamePropertyId, lValue));
  Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lProvider.FragmentProvider.GetRuntimeId(lArray));
  Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
    lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lFragment));
  Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lProvider.FragmentProvider.Get_FragmentRoot(lFragmentRoot));
end;

procedure TProviderCoreTests.EventHelpersAreGatedForPropertyStructureAndNotification;
var
  lApi: ITestUiaApi;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lProvider := TAccessibilityProviderFactory.CreateRoot([10], 0, lApi);

  lApi.SetClientsAreListening(False);
  Assert.IsFalse(TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(lProvider.RawElementProvider,
    UIA_NamePropertyId, 'old', 'new', lApi));
  Assert.IsFalse(TAccessibilityProviderEvents.RaiseStructureChanged(lProvider.RawElementProvider,
    StructureChangeType_ChildAdded, [10, 11], lApi));
  Assert.IsFalse(TAccessibilityProviderEvents.RaiseNotification(lProvider.RawElementProvider, NotificationKind_Other,
    NotificationProcessing_All, 'Visible text', 'activity', lApi));
  Assert.AreEqual(0, lApi.PropertyCalls);
  Assert.AreEqual(0, lApi.StructureCalls);
  Assert.AreEqual(0, lApi.NotificationCalls);

  lApi.SetClientsAreListening(True);
  Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(lProvider.RawElementProvider,
    UIA_NamePropertyId, 'old', 'new', lApi));
  Assert.IsTrue(TAccessibilityProviderEvents.RaiseStructureChanged(lProvider.RawElementProvider,
    StructureChangeType_ChildAdded, [10, 11], lApi));
  Assert.IsTrue(TAccessibilityProviderEvents.RaiseNotification(lProvider.RawElementProvider, NotificationKind_Other,
    NotificationProcessing_All, 'Visible text', 'activity', lApi));
  Assert.AreEqual(UIA_NamePropertyId, lApi.LastPropertyId);
  Assert.AreEqual(StructureChangeType_ChildAdded, lApi.LastStructureChangeType);
  Assert.AreEqual(NotificationKind_Other, lApi.LastNotificationKind);
end;

procedure TProviderCoreTests.FragmentOwnerDestroyDisconnectsFragmentProvider;
var
  lApi: ITestUiaApi;
  lOwner: TComponent;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lOwner := TComponent.Create(nil);
  try
    lProvider := TAccessibilityProviderFactory.CreateFragment([22], lApi, lOwner);
    Assert.IsFalse(lProvider.IsDisconnected);
  finally
    lOwner.Free;
  end;

  Assert.IsTrue(lProvider.IsDisconnected);
  Assert.AreEqual(1, lApi.DisconnectCalls);
end;

procedure TProviderCoreTests.FragmentNavigationIsDeterministic;
var
  lFirst: IRawElementProviderFragment;
  lRoot: IAccessibilityProviderNode;
  lSecond: IRawElementProviderFragment;
begin
  lRoot := TAccessibilityProviderFactory.CreateRoot([100], 0);
  lRoot.AddChild(TAccessibilityProviderFactory.CreateFragment([201]));
  lRoot.AddChild(TAccessibilityProviderFactory.CreateFragment([202]));

  Assert.AreEqual(S_OK, lRoot.FragmentProvider.Navigate(NavigateDirection_FirstChild, lFirst));
  Assert.AreEqual(201, RuntimeIdValue(lFirst, 1));
  Assert.AreEqual(S_OK, lFirst.Navigate(NavigateDirection_NextSibling, lSecond));
  Assert.AreEqual(202, RuntimeIdValue(lSecond, 1));
  Assert.AreEqual(S_OK, lSecond.Navigate(NavigateDirection_PreviousSibling, lFirst));
  Assert.AreEqual(201, RuntimeIdValue(lFirst, 1));
  Assert.AreEqual(S_OK, lSecond.Navigate(NavigateDirection_Parent, lFirst));
  Assert.AreEqual(100, RuntimeIdValue(lFirst, 1));
end;

procedure TProviderCoreTests.NestedSubtreeOwnerDestroyDisconnectsEveryProvider;
var
  lApi: ITestUiaApi;
  lGroup: IAccessibilityProviderNode;
  lLeaf: IAccessibilityProviderNode;
  lOwner: TComponent;
  lRoot: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lOwner := TComponent.Create(nil);
  lLeaf := TAccessibilityProviderFactory.CreateFragment([3]);
  lGroup := TAccessibilityProviderFactory.CreateFragment([2]);
  lGroup.AddChild(lLeaf);
  try
    lRoot := TAccessibilityProviderFactory.CreateRoot([1], 0, lApi, lOwner);
    lRoot.AddChild(lGroup);
  finally
    lOwner.Free;
  end;

  Assert.IsTrue(lRoot.IsDisconnected);
  Assert.IsTrue(lGroup.IsDisconnected);
  Assert.IsTrue(lLeaf.IsDisconnected);
  Assert.AreEqual(3, lApi.DisconnectCalls);
end;

procedure TProviderCoreTests.OwnerDestroyDisconnectsProviderOnce;
var
  lApi: ITestUiaApi;
  lOwner: TComponent;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lOwner := TComponent.Create(nil);
  try
    lProvider := TAccessibilityProviderFactory.CreateRoot([10], 0, lApi, lOwner);
    Assert.IsFalse(lProvider.IsDisconnected);
  finally
    lOwner.Free;
  end;

  Assert.IsTrue(lProvider.IsDisconnected);
  Assert.AreEqual(1, lApi.DisconnectCalls);

  lProvider.Disconnect;
  Assert.AreEqual(1, lApi.DisconnectCalls);
end;

procedure TProviderCoreTests.ProviderPropertiesAndRuntimeIdsAreExposed;
var
  lProvider: IAccessibilityProviderNode;
  lProviderOptions: ProviderOptions;
  lValue: OleVariant;
begin
  lProvider := TAccessibilityProviderFactory.CreateRoot([77], 0);
  lProvider.SetProperty(UIA_NamePropertyId, 'Save');
  lProvider.SetProperty(UIA_ControlTypePropertyId, UIA_ButtonControlTypeId);

  Assert.AreEqual(S_OK, lProvider.RawElementProvider.Get_ProviderOptions(lProviderOptions));
  Assert.AreEqual(ProviderOptions_ServerSideProvider, lProviderOptions);
  Assert.AreEqual(UiaAppendRuntimeId, RuntimeIdValue(lProvider.FragmentProvider, 0));
  Assert.AreEqual(77, RuntimeIdValue(lProvider.FragmentProvider, 1));

  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_NamePropertyId, lValue));
  Assert.AreEqual('Save', string(lValue));
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_ControlTypePropertyId, lValue));
  Assert.AreEqual(UIA_ButtonControlTypeId, Integer(lValue));
end;

procedure TProviderCoreTests.ProviderBaseClassesCanBeExtended;
var
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lValue: OleVariant;
begin
  lProvider := TNamedProviderNode.Create as IAccessibilityProviderNode;

  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_NamePropertyId, lValue));
  Assert.AreEqual('Subclass', string(lValue));
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPatternProvider(UIA_InvokePatternId, lPattern));
  Assert.IsNotNull(lPattern);
end;

procedure TProviderCoreTests.RetainedChildProviderDisconnectsWhenParentIsDestroyed;
var
  lChildFragment: IRawElementProviderFragment;
  lChildNode: IAccessibilityProviderNode;
  lParent: IRawElementProviderFragment;
  lRoot: IAccessibilityProviderNode;
begin
  lRoot := TAccessibilityProviderFactory.CreateRoot([1], 0);
  lChildNode := TAccessibilityProviderFactory.CreateFragment([2]);
  lRoot.AddChild(lChildNode);
  lChildFragment := lChildNode.FragmentProvider;

  lChildNode := nil;
  lRoot := nil;

  Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
    lChildFragment.Navigate(NavigateDirection_Parent, lParent));
end;

procedure TProviderCoreTests.WmGetObjectReturnsRootProviderOnlyForUiaRequests;
var
  lApi: ITestUiaApi;
  lHandled: Boolean;
  lMessageResult: LRESULT;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lProvider := TAccessibilityProviderFactory.CreateRoot([10], HWND(100), lApi);

  lHandled := TAccessibilityProviderWindowMessages.TryHandleGetObject(HWND(100), 7, 12345, lProvider.RawElementProvider,
    lApi, lMessageResult);
  Assert.IsFalse(lHandled);
  Assert.AreEqual(0, lApi.ReturnCalls);

  lHandled := TAccessibilityProviderWindowMessages.TryHandleGetObject(HWND(100), 7, UiaRootObjectId,
    lProvider.RawElementProvider, lApi, lMessageResult);
  Assert.IsTrue(lHandled);
  Assert.AreEqual(4242, Integer(lMessageResult));
  Assert.AreEqual(1, lApi.ReturnCalls);
  Assert.AreEqual(HWND(100), lApi.LastHwnd);
  Assert.AreEqual(LPARAM(UiaRootObjectId), lApi.LastLParam);
end;

initialization
  TDUnitX.RegisterTestFixture(TProviderCoreTests);

end.
