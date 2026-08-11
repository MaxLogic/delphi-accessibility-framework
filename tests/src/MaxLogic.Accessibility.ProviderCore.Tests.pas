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
    procedure DirectChildCountThenIndexedAccessReusesPreparedChildren;
    [Test]
    procedure FragmentSiblingNavigationReusesPreparedChildren;
    [Test]
    procedure FailedChildInsertionLeavesChildDetached;
    [Test]
    procedure FailedBatchDisconnectDetachesEveryRemovedChild;
    [Test]
    procedure FragmentNextSiblingEnumerationScalesLinearly;
    [Test]
    procedure FragmentOwnerDestroyDisconnectsFragmentProvider;
    [Test]
    procedure NestedSubtreeOwnerDestroyDisconnectsEveryProvider;
    [Test]
    procedure OwnerDestroyDisconnectsProviderOnce;
    [Test]
    procedure ProviderPropertiesAndRuntimeIdsAreExposed;
    [Test]
    procedure RuntimeIdCreationAvoidsPerElementSafeArrayCalls;
    [Test]
    procedure ProviderRuntimeIdsAreCopiedByBlock;
    [Test]
    procedure StaticPropertiesUseTypedStorageAndPreserveValues;
    [Test]
    procedure CommonTypedStoragePreservesFallbackVariants;
    [Test]
    procedure LeafProviderCreationDoesNotAllocateChildLists;
    [Test]
    procedure DirectPatternSupportUsesStatePropertiesBeforePatternProvider;
    [Test]
    procedure WindowedProvidersOverrideNativeProxyWithoutPublishingHwnd;
    [Test]
    procedure ProviderBaseClassesCanBeExtended;
    [Test]
    procedure RetainedChildProviderDisconnectsWhenParentIsDestroyed;
    [Test]
    procedure DisconnectedProvidersReturnElementUnavailable;
    [Test]
    procedure PublishedHostProviderLookupDoesNotReenterWmGetObject;
    [Test]
    procedure UnpublishedNativeWindowProvidersDoNotLookupHostProvider;
    [Test]
    procedure NestedFragmentRootUsesNearestFragmentRoot;
    [Test]
    procedure FragmentRootLookupDoesNotScaleWithProviderDepth;
    [Test]
    procedure ElementProviderFromPointDoesNotBuildLogDescriptionWhenDiagnosticsDisabled;
    [Test]
    [Category('Diagnostics')]
    procedure ElementProviderFromPointDoesNotBuildLogDescriptionWhenDiagnosticsEnabled;
    [Test]
    procedure ElementProviderFromPointUsesInternalBoundsWithoutProviderCallback;
    [Test]
    procedure WmGetObjectReturnsRootProviderOnlyForUiaRequests;
    [Test]
    procedure WmGetObjectFallsBackWhenUiaRejectsProvider;
    [Test]
    procedure WmGetObjectLeavesClientObjectRequestsForNativeMsaa;
    [Test]
    procedure AutomationEventsAreRaisedOnlyWhenClientsListen;
    [Test]
    procedure EventHelpersAreGatedForPropertyStructureAndNotification;
    [Test]
    [Category('Diagnostics')]
    procedure SupplementalUiaEventFanoutMetricsCountTypes;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.Generics.Collections, System.IOUtils, System.SysUtils, System.Variants,
  Winapi.ActiveX, Winapi.Windows,
  MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.UIAutomationCore;

type
  IPropertyProbeProvider = interface
    ['{DE586BD4-2E94-4FD5-BC77-BECA33D52749}']
    function PropertyProbeCount: Integer;
  end;

  IPrepareProbeProvider = interface
    ['{8E37E42D-A390-46D8-9B8E-68879723CC1C}']
    function PrepareCount: Integer;
  end;

  ITestUiaApi = interface(IAccessibilityUiaApi)
    ['{BD87F3C7-7C19-489C-9855-03A41E879476}']
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function HostCalls: Integer;
    function LastNotificationKind: NotificationKind;
    function ReturnCalls: Integer;
    function LastEventId: EVENTID;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
    function LastPropertyId: PROPERTYID;
    function LastStructureChangeType: StructureChangeType;
    function NotificationCalls: Integer;
    function PropertyCalls: Integer;
    function ReentrantHandled: Boolean;
    procedure SetRaiseOnDisconnectCall(aValue: Integer);
    function StructureCalls: Integer;
    procedure SetClientsAreListening(aValue: Boolean);
    procedure SetReentrantProvider(const aProvider: IRawElementProviderSimple);
    procedure SetReturnRawElementProviderResult(aValue: LRESULT);
  end;

  TTestUiaApi = class(TInterfacedObject, IAccessibilityUiaApi, ITestUiaApi)
  private
    fClientsAreListening: Boolean;
    fDisconnectCalls: Integer;
    fEventCalls: Integer;
    fHostCalls: Integer;
    fLastEventId: EVENTID;
    fLastHwnd: HWND;
    fLastLParam: LPARAM;
    fLastNotificationKind: NotificationKind;
    fLastPropertyId: PROPERTYID;
    fLastStructureChangeType: StructureChangeType;
    fNotificationCalls: Integer;
    fPropertyCalls: Integer;
    fRaiseOnDisconnectCall: Integer;
    fReentrantHandled: Boolean;
    fReentrantProvider: IRawElementProviderSimple;
    fReturnCalls: Integer;
    fReturnRawElementProviderResult: LRESULT;
    fStructureCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function HostCalls: Integer;
    function LastEventId: EVENTID;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
    function LastNotificationKind: NotificationKind;
    function LastPropertyId: PROPERTYID;
    function LastStructureChangeType: StructureChangeType;
    function NotificationCalls: Integer;
    function PropertyCalls: Integer;
    function ReentrantHandled: Boolean;
    procedure SetRaiseOnDisconnectCall(aValue: Integer);
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
    procedure SetReentrantProvider(const aProvider: IRawElementProviderSimple);
    procedure SetReturnRawElementProviderResult(aValue: LRESULT);
  end;

  TNamedProviderNode = class(TAccessibilityProviderNode)
  protected
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create;
  end;

  TCountingHitTestProviderNode = class(TAccessibilityProviderNode, IPropertyProbeProvider)
  private
    fPropertyProbeCount: Integer;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create;
    function PropertyProbeCount: Integer;
  end;

  TPreparingProviderNode = class(TAccessibilityProviderNode, IPrepareProbeProvider)
  private
    fPrepared: Boolean;
    fPrepareCount: Integer;
  protected
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create;
    function PrepareCount: Integer;
  end;

  TFailingInsertProviderNode = class(TAccessibilityProviderNode)
  private
    fFailNextInsertion: Boolean;
  protected
    procedure InsertChildIntoList(aChildren: TList<IAccessibilityProviderNode>; aIndex: Integer;
      const aChild: IAccessibilityProviderNode); override;
  public
    constructor Create;
  end;

  TBatchRemovalProviderNode = class(TAccessibilityProviderNode)
  public
    constructor Create(const aApi: IAccessibilityUiaApi);
    procedure RemoveChildren(const aFirstChild, aSecondChild: IAccessibilityProviderNode);
  end;

  TPatternProbeProviderNode = class(TAccessibilityProviderNode)
  private
    fPatternProbeCount: Integer;
  protected
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create;
    function PatternProbeCount: Integer;
  end;

  TPublishedWindowProviderNode = class(TAccessibilityProviderNode)
  public
    constructor Create(const aApi: IAccessibilityUiaApi);
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

function InterfacesAreSame(const aLeft: IInterface; const aRight: IInterface): Boolean;
var
  lLeft: IUnknown;
  lRight: IUnknown;
begin
  if (aLeft = nil) or (aRight = nil) then
  begin
    Exit(aLeft = aRight);
  end;

  lLeft := aLeft as IUnknown;
  lRight := aRight as IUnknown;
  Result := lLeft = lRight;
end;

function MeasureNextSiblingEnumerationTicks(aChildCount: Integer): Int64;
var
  i: Integer;
  lCurrent: IRawElementProviderFragment;
  lNext: IRawElementProviderFragment;
  lRoot: IAccessibilityProviderNode;
  lStopwatch: TStopwatch;
begin
  lRoot := TAccessibilityProviderFactory.CreateRoot([100], 0);
  for i := 1 to aChildCount do
  begin
    lRoot.AddChild(TAccessibilityProviderFactory.CreateFragment([1000 + i]));
  end;

  Assert.AreEqual(S_OK, lRoot.FragmentProvider.Navigate(NavigateDirection_FirstChild, lCurrent));
  lStopwatch := TStopwatch.StartNew;
  for i := 2 to aChildCount do
  begin
    Assert.AreEqual(S_OK, lCurrent.Navigate(NavigateDirection_NextSibling, lNext));
    Assert.IsNotNull(lNext);
    lCurrent := lNext;
  end;
  lStopwatch.Stop;

  Result := lStopwatch.ElapsedTicks;
  if Result < 1 then
  begin
    Result := 1;
  end;
end;

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

function BuildRuntimeId(aLength: Integer; aBase: Integer): TArray<Integer>;
var
  i: Integer;
begin
  SetLength(Result, aLength);
  for i := 0 to High(Result) do
  begin
    Result[i] := aBase + i;
  end;
end;

function MeasureRuntimeIdCreationTicks(aRuntimeIdLength: Integer; aIterations: Integer): Int64;
var
  i: Integer;
  lArray: PSafeArray;
  lProvider: IAccessibilityProviderNode;
  lRuntimeId: TArray<Integer>;
  lStopwatch: TStopwatch;
begin
  lRuntimeId := BuildRuntimeId(aRuntimeIdLength, 500);
  lProvider := TAccessibilityProviderFactory.CreateFragment(lRuntimeId);
  lStopwatch := TStopwatch.StartNew;
  for i := 1 to aIterations do
  begin
    lArray := nil;
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.GetRuntimeId(lArray));
    Assert.IsNotNull(lArray);
    SafeArrayDestroy(lArray);
  end;
  lStopwatch.Stop;
  Result := lStopwatch.ElapsedTicks;
  if Result < 1 then
  begin
    Result := 1;
  end;
end;

function MeasureFragmentRootLookupTicks(aDepth: Integer; aIterations: Integer): Int64;
var
  i: Integer;
  lChild: IAccessibilityProviderNode;
  lFragment: IRawElementProviderFragment;
  lParent: IAccessibilityProviderNode;
  lRoot: IAccessibilityProviderNode;
  lRootProvider: IRawElementProviderFragmentRoot;
  lStopwatch: TStopwatch;
begin
  lRoot := TAccessibilityProviderFactory.CreateRoot([1], HWND(10));
  lParent := lRoot;
  for i := 1 to aDepth do
  begin
    lChild := TAccessibilityProviderFactory.CreateFragment([1000 + i]);
    lParent.AddChild(lChild);
    lParent := lChild;
  end;

  lFragment := lParent.FragmentProvider;
  lStopwatch := TStopwatch.StartNew;
  for i := 1 to aIterations do
  begin
    Assert.AreEqual(S_OK, lFragment.Get_FragmentRoot(lRootProvider));
    Assert.IsNotNull(lRootProvider);
  end;
  lStopwatch.Stop;

  Result := lStopwatch.ElapsedTicks;
  if Result < 1 then
  begin
    Result := 1;
  end;
end;

function TTestUiaApi.ClientsAreListening: Boolean;
begin
  Result := fClientsAreListening;
end;

function TTestUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Inc(fDisconnectCalls);
  if fDisconnectCalls = fRaiseOnDisconnectCall then
  begin
    raise EOutOfMemory.Create('Controlled disconnect failure.');
  end;
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
var
  lMessageResult: LRESULT;
begin
  Inc(fHostCalls);
  if fReentrantProvider <> nil then
  begin
    fReentrantHandled := TAccessibilityProviderWindowMessages.TryHandleGetObject(aHwnd, 0, UiaRootObjectId,
      fReentrantProvider, Self as IAccessibilityUiaApi, lMessageResult);
  end;

  aProvider := nil;
  Result := S_FALSE;
end;

function TTestUiaApi.HostCalls: Integer;
begin
  Result := fHostCalls;
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

function TTestUiaApi.ReentrantHandled: Boolean;
begin
  Result := fReentrantHandled;
end;

procedure TTestUiaApi.SetRaiseOnDisconnectCall(aValue: Integer);
begin
  fRaiseOnDisconnectCall := aValue;
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
  if fReturnRawElementProviderResult <> 0 then
  begin
    Result := fReturnRawElementProviderResult;
  end else begin
    Result := 4242;
  end;
end;

procedure TTestUiaApi.SetClientsAreListening(aValue: Boolean);
begin
  fClientsAreListening := aValue;
end;

procedure TTestUiaApi.SetReentrantProvider(const aProvider: IRawElementProviderSimple);
begin
  fReentrantProvider := aProvider;
  fReentrantHandled := False;
end;

procedure TTestUiaApi.SetReturnRawElementProviderResult(aValue: LRESULT);
begin
  fReturnRawElementProviderResult := aValue;
end;

function TTestUiaApi.StructureCalls: Integer;
begin
  Result := fStructureCalls;
end;

constructor TNamedProviderNode.Create;
begin
  inherited CreateNode([909], 0, nil, nil);
end;

constructor TCountingHitTestProviderNode.Create;
begin
  inherited CreateNode([911], 0, nil, nil);
end;

constructor TPatternProbeProviderNode.Create;
begin
  inherited CreateNode([912], 0, nil, nil);
end;

constructor TPublishedWindowProviderNode.Create(const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode([910], HWND(100), aApi, nil);
  SetPublishNativeWindowHandle(True);
end;

function TCountingHitTestProviderNode.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
begin
  aValue.Left := 0;
  aValue.Top := 0;
  aValue.Width := 100;
  aValue.Height := 100;
  Result := True;
end;

function TCountingHitTestProviderNode.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
begin
  Inc(fPropertyProbeCount);
  Result := inherited DoGetPropertyValue(aPropertyId, aValue);
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

function TPatternProbeProviderNode.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Inc(fPatternProbeCount);
  if (aPatternId = UIA_TogglePatternId) or (aPatternId = UIA_SelectionItemPatternId) then
  begin
    Exit(RawElementProvider as IUnknown);
  end;

  Result := inherited DoGetPatternProvider(aPatternId);
end;

function TPatternProbeProviderNode.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_SelectionItemIsSelectedPropertyId:
      aValue := True;
    UIA_ToggleToggleStatePropertyId:
      aValue := Integer(ToggleState_On);
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TCountingHitTestProviderNode.PropertyProbeCount: Integer;
begin
  Result := fPropertyProbeCount;
end;

constructor TPreparingProviderNode.Create;
begin
  inherited CreateNode([900], 0, nil, nil);
end;

constructor TFailingInsertProviderNode.Create;
begin
  inherited CreateNode([903], 0, nil, nil);
  fFailNextInsertion := True;
end;

constructor TBatchRemovalProviderNode.Create(const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode([906], 0, aApi, nil);
end;

procedure TBatchRemovalProviderNode.RemoveChildren(const aFirstChild,
  aSecondChild: IAccessibilityProviderNode);
begin
  RemoveChildNodes([aFirstChild, aSecondChild], True);
end;

procedure TFailingInsertProviderNode.InsertChildIntoList(aChildren: TList<IAccessibilityProviderNode>;
  aIndex: Integer; const aChild: IAccessibilityProviderNode);
begin
  inherited InsertChildIntoList(aChildren, aIndex, aChild);
  if fFailNextInsertion then
  begin
    fFailNextInsertion := False;
    raise EOutOfMemory.Create('Controlled child insertion failure.');
  end;
end;

function TPreparingProviderNode.PrepareCount: Integer;
begin
  Result := fPrepareCount;
end;

procedure TPreparingProviderNode.PrepareChildrenForNavigation;
begin
  inherited PrepareChildrenForNavigation;
  Inc(fPrepareCount);
  if fPrepared then
  begin
    Exit;
  end;

  fPrepared := True;
  AddChild(TAccessibilityProviderFactory.CreateFragment([901]));
  AddChild(TAccessibilityProviderFactory.CreateFragment([902]));
end;

function TPatternProbeProviderNode.PatternProbeCount: Integer;
begin
  Result := fPatternProbeCount;
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
  lArray: PSafeArray; //PALOFF WARN46 output argument verifies unavailable selection behavior
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

procedure TProviderCoreTests.SupplementalUiaEventFanoutMetricsCountTypes;
var
  lApi: ITestUiaApi;
  lJson: string;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lProvider := TAccessibilityProviderFactory.CreateRoot([10], 0, lApi);
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider.RawElementProvider,
      UIA_AutomationFocusChangedEventId, lApi));
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider.RawElementProvider,
      UIA_SelectionItem_ElementSelectedEventId, lApi));
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider.RawElementProvider,
      UIA_Invoke_InvokedEventId, lApi));
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(lProvider.RawElementProvider,
      UIA_ToggleToggleStatePropertyId, ToggleState_Off, ToggleState_On, lApi));
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(lProvider.RawElementProvider,
      UIA_SelectionItemIsSelectedPropertyId, False, True, lApi));
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(lProvider.RawElementProvider,
      UIA_NamePropertyId, 'old', 'new', lApi));
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseNotification(lProvider.RawElementProvider,
      NotificationKind_Other, NotificationProcessing_All, 'Visible text', 'activity', lApi));
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseStructureChanged(lProvider.RawElementProvider,
      StructureChangeType_ChildAdded, [10, 11], lApi));

    lApi.SetClientsAreListening(False);
    Assert.IsFalse(TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider.RawElementProvider,
      UIA_Invoke_InvokedEventId, lApi));

    lJson := TAccessibilityDiagnostics.ProviderHotspotMetrics.ToJson('event-fanout', 'ProviderCore test');
    Assert.IsTrue(Pos('"supplementalUiaEventCount":8', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaAutomationEventCount":3', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaFocusEventCount":1', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaSelectionEventCount":1', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaOtherAutomationEventCount":1', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaPropertyChangedEventCount":3', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaTogglePropertyChangedEventCount":1', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaSelectionPropertyChangedEventCount":1', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaOtherPropertyChangedEventCount":1', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaNotificationEventCount":1', lJson) > 0, lJson);
    Assert.IsTrue(Pos('"supplementalUiaStructureChangedEventCount":1', lJson) > 0, lJson);
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TProviderCoreTests.PublishedHostProviderLookupDoesNotReenterWmGetObject;
var
  lApi: ITestUiaApi;
  lCachedHost: IRawElementProviderSimple;
  lNativeWindow: IAccessibilityProviderNativeWindow;
  lRootHost: IRawElementProviderSimple;
  lRootProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lRootProvider := TPublishedWindowProviderNode.Create(lApi) as IAccessibilityProviderNode;
  lApi.SetReentrantProvider(lRootProvider.RawElementProvider);

  Assert.IsTrue(Supports(lRootProvider.RawElementProvider, IAccessibilityProviderNativeWindow, lNativeWindow));
  Assert.AreEqual(HWND(100), lNativeWindow.NativeWindowHandle);
  Assert.AreEqual(S_FALSE, lRootProvider.RawElementProvider.Get_HostRawElementProvider(lRootHost));
  Assert.AreEqual(1, lApi.HostCalls);
  Assert.AreEqual(S_FALSE, lRootProvider.RawElementProvider.Get_HostRawElementProvider(lCachedHost));
  Assert.AreEqual(1, lApi.HostCalls, 'Published providers should cache host-provider lookup per HWND.');
  Assert.IsFalse(lApi.ReentrantHandled);
  Assert.AreEqual(0, lApi.ReturnCalls);
end;

procedure TProviderCoreTests.UnpublishedNativeWindowProvidersDoNotLookupHostProvider;
var
  lApi: ITestUiaApi;
  lRootHost: IRawElementProviderSimple;
  lRootProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lRootProvider := TAccessibilityProviderFactory.CreateRoot([1], HWND(100), lApi);

  Assert.AreEqual(S_FALSE, lRootProvider.RawElementProvider.Get_HostRawElementProvider(lRootHost));
  Assert.AreEqual(0, lApi.HostCalls);
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

procedure TProviderCoreTests.DirectChildCountThenIndexedAccessReusesPreparedChildren;
var
  lAccess: IAccessibilityProviderChildAccess;
  lChild: IRawElementProviderSimple; //PALOFF WARN46 output argument verifies navigation behavior
  lCount: Integer;
  lPrepareProbe: IPrepareProbeProvider;
  lProvider: IAccessibilityProviderNode;
begin
  lProvider := TPreparingProviderNode.Create as IAccessibilityProviderNode;
  Assert.IsTrue(Supports(lProvider.RawElementProvider, IAccessibilityProviderChildAccess, lAccess));
  Assert.IsTrue(Supports(lProvider, IPrepareProbeProvider, lPrepareProbe));

  Assert.AreEqual(S_OK, lAccess.DirectChildCount(lCount));
  Assert.AreEqual(2, lCount);
  Assert.AreEqual(S_OK, lAccess.DirectChildAt(0, lChild));
  Assert.IsNotNull(lChild);
  Assert.AreEqual(S_OK, lAccess.DirectChildAt(1, lChild));
  Assert.IsNotNull(lChild);
  Assert.AreEqual(1, lPrepareProbe.PrepareCount,
    'Direct child count and indexed reads should share one prepared child snapshot.');

  Assert.AreEqual(S_OK, lAccess.DirectChildAt(0, lChild));
  Assert.AreEqual(2, lPrepareProbe.PrepareCount,
    'The indexed-read snapshot should be consumed instead of becoming a stale long-lived cache.');
end;

procedure TProviderCoreTests.FragmentSiblingNavigationReusesPreparedChildren;
var
  lFirst: IRawElementProviderFragment;
  lPrepareProbe: IPrepareProbeProvider;
  lProvider: IAccessibilityProviderNode;
  lSecond: IRawElementProviderFragment;
begin
  lProvider := TPreparingProviderNode.Create as IAccessibilityProviderNode;
  Assert.IsTrue(Supports(lProvider, IPrepareProbeProvider, lPrepareProbe));

  Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lFirst));
  Assert.IsNotNull(lFirst);
  Assert.AreEqual(1, lPrepareProbe.PrepareCount);

  Assert.AreEqual(S_OK, lFirst.Navigate(NavigateDirection_NextSibling, lSecond));
  Assert.IsNotNull(lSecond);
  Assert.AreEqual(1, lPrepareProbe.PrepareCount,
    'Next sibling navigation should reuse the prepared child snapshot while child indexes remain current.');

  Assert.AreEqual(S_OK, lSecond.Navigate(NavigateDirection_PreviousSibling, lFirst));
  Assert.IsNotNull(lFirst);
  Assert.AreEqual(1, lPrepareProbe.PrepareCount,
    'Previous sibling navigation should reuse the prepared child snapshot while child indexes remain current.');
end;

procedure TProviderCoreTests.FailedChildInsertionLeavesChildDetached;
var
  lAttached: Boolean;
  lChild: IAccessibilityProviderNode;
  lChildAccess: IAccessibilityProviderChildAccess;
  lChildCount: Integer;
  lFailingParent: IAccessibilityProviderNode;
  lInsertionFailed: Boolean;
  lSecondParent: IAccessibilityProviderNode;
begin
  lFailingParent := TFailingInsertProviderNode.Create;
  lSecondParent := TAccessibilityProviderFactory.CreateFragment([904]);
  lChild := TAccessibilityProviderFactory.CreateFragment([905]);
  lInsertionFailed := False;
  try
    lFailingParent.AddChild(lChild);
  except
    on EOutOfMemory do
    begin
      lInsertionFailed := True;
    end;
  end;
  Assert.IsTrue(lInsertionFailed, 'The controlled child insertion must fail.');
  Assert.IsTrue(Supports(lFailingParent.RawElementProvider, IAccessibilityProviderChildAccess, lChildAccess));
  Assert.AreEqual(S_OK, lChildAccess.DirectChildCount(lChildCount));
  Assert.AreEqual(0, lChildCount, 'A failed insertion must not leave the child in the failed parent.');

  lAttached := True;
  try
    lSecondParent.AddChild(lChild);
  except
    on Exception do
    begin
      lAttached := False;
    end;
  end;
  Assert.IsTrue(lAttached, 'A failed insertion must leave the child detached and reusable.');
  Assert.IsTrue(Supports(lSecondParent.RawElementProvider, IAccessibilityProviderChildAccess, lChildAccess));
  Assert.AreEqual(S_OK, lChildAccess.DirectChildCount(lChildCount));
  Assert.AreEqual(1, lChildCount, 'The reused child must be attached exactly once.');
end;

procedure TProviderCoreTests.FailedBatchDisconnectDetachesEveryRemovedChild;
var
  lApi: ITestUiaApi;
  lDisconnectFailed: Boolean;
  lFirstChild: IAccessibilityProviderNode;
  lOptions: ProviderOptions;
  lParent: IAccessibilityProviderNode;
  lSecondChild: IAccessibilityProviderNode;
  lSecondParent: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lApi.SetRaiseOnDisconnectCall(1);
  lParent := TBatchRemovalProviderNode.Create(lApi);
  lFirstChild := TAccessibilityProviderFactory.CreateFragment([907]);
  lSecondChild := TAccessibilityProviderFactory.CreateFragment([908]);
  lSecondParent := TAccessibilityProviderFactory.CreateFragment([909]);
  lParent.AddChild(lFirstChild);
  lParent.AddChild(lSecondChild);

  lDisconnectFailed := False;
  try
    TBatchRemovalProviderNode((lParent as IAccessibilityProviderNodeInternal).ProviderObject).RemoveChildren(
      lFirstChild, lSecondChild);
  except
    on EOutOfMemory do
    begin
      lDisconnectFailed := True;
    end;
  end;
  Assert.IsTrue(lDisconnectFailed, 'The controlled first-child disconnect must fail.');
  Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lFirstChild.RawElementProvider.Get_ProviderOptions(lOptions),
    'The child whose callback failed must remain disconnected.');
  Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lSecondChild.RawElementProvider.Get_ProviderOptions(lOptions),
    'Every later removed child must be disconnected before callbacks begin.');
  Assert.AreEqual(2, lApi.DisconnectCalls,
    'A failed callback must not prevent later removed providers from notifying UIA.');

  try
    lSecondParent.AddChild(lSecondChild);
  except
    on EInvalidOperation do
    begin
      Assert.Fail('Every removed child must detach before the first disconnect callback can raise.');
    end;
  end;
end;

procedure TProviderCoreTests.FragmentNextSiblingEnumerationScalesLinearly;
const
  cGrowthFactor = 4;
  cMaxTickGrowth = 8;
  cSampleCount = 5;
  cSmallChildCount = 512;
var
  lLargeSampleTicks: Int64;
  lLargeTicks: Int64;
  lSamplesRemaining: Integer;
  lSmallSampleTicks: Int64;
  lSmallTicks: Int64;
begin
  lLargeTicks := High(Int64);
  lSmallTicks := High(Int64);
  lSamplesRemaining := cSampleCount;
  repeat
    lSmallSampleTicks := MeasureNextSiblingEnumerationTicks(cSmallChildCount);
    if lSmallSampleTicks < lSmallTicks then
    begin
      lSmallTicks := lSmallSampleTicks;
    end;

    lLargeSampleTicks := MeasureNextSiblingEnumerationTicks(cSmallChildCount * cGrowthFactor);
    if lLargeSampleTicks < lLargeTicks then
    begin
      lLargeTicks := lLargeSampleTicks;
    end;

    Dec(lSamplesRemaining);
  until lSamplesRemaining = 0;

  Assert.IsTrue(lLargeTicks <= lSmallTicks * cMaxTickGrowth,
    Format('NextSibling enumeration grew from %d to %d ticks for %dx children.', [lSmallTicks, lLargeTicks,
    cGrowthFactor]));
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

procedure TProviderCoreTests.RuntimeIdCreationAvoidsPerElementSafeArrayCalls;
const
  cIterations = 20000;
  cLongRuntimeIdLength = 32;
  cMaxLongPercentOfShort = 250;
var
  lLongTicks: Int64;
  lShortTicks: Int64;
begin
  lShortTicks := MeasureRuntimeIdCreationTicks(1, cIterations);
  lLongTicks := MeasureRuntimeIdCreationTicks(cLongRuntimeIdLength, cIterations);

  Assert.IsTrue(lLongTicks * 100 <= lShortTicks * cMaxLongPercentOfShort,
    Format('Runtime ID SAFEARRAY creation should avoid one SafeArrayPutElement call per value; short=%d long=%d ticks.',
    [lShortTicks, lLongTicks]));
end;

procedure TProviderCoreTests.ProviderRuntimeIdsAreCopiedByBlock;
const
  cProviderCount = 40;
  cRuntimeIdLength = 64;
var
  i: Integer;
  lApi: ITestUiaApi;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProvider: IAccessibilityProviderNode;
  lRuntimeId: TArray<Integer>;
begin
  lApi := TTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lRuntimeId := BuildRuntimeId(cRuntimeIdLength, 9000);

  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    for i := 1 to cProviderCount do
    begin
      lProvider := TAccessibilityProviderFactory.CreateFragment(lRuntimeId, lApi);
    end;

    Assert.IsTrue(TAccessibilityProviderEvents.RaiseStructureChanged(lProvider.RawElementProvider,
      StructureChangeType_ChildAdded, lRuntimeId, lApi));

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(cProviderCount + 1, lMetrics.ProviderRuntimeIdBlockCopyCount,
      'Provider runtime ids should be copied with one native block copy per destination array.');
    Assert.AreEqual((cProviderCount + 1) * cRuntimeIdLength, lMetrics.ProviderRuntimeIdBlockCopyElementCount,
      'Runtime id block-copy diagnostics should record the copied element volume.');
    Assert.AreEqual(0, lMetrics.ProviderRuntimeIdElementCopyCount,
      'Provider runtime ids should not be copied one Integer assignment at a time.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TProviderCoreTests.StaticPropertiesUseTypedStorageAndPreserveValues;
var
  lProvider: IAccessibilityProviderNode;
  lSourceText: string;
  lValue: OleVariant;
begin
  lSourceText := ReadRepoText('src\MaxLogic.Accessibility.ProviderCore.pas');

  Assert.IsFalse(Pos('fAutomationIdProperty: OleVariant', lSourceText) > 0,
    'Common string provider properties should use typed storage, not OleVariant fields.');
  Assert.IsFalse(Pos('fClassNameProperty: OleVariant', lSourceText) > 0,
    'Common string provider properties should use typed storage, not OleVariant fields.');
  Assert.IsFalse(Pos('fControlTypeProperty: OleVariant', lSourceText) > 0,
    'Common integer provider properties should use typed storage, not OleVariant fields.');
  Assert.IsFalse(Pos('fFrameworkIdProperty: OleVariant', lSourceText) > 0,
    'Common string provider properties should use typed storage, not OleVariant fields.');
  Assert.IsFalse(Pos('fHelpTextProperty: OleVariant', lSourceText) > 0,
    'Common string provider properties should use typed storage, not OleVariant fields.');
  Assert.IsFalse(Pos('fItemStatusProperty: OleVariant', lSourceText) > 0,
    'Common string provider properties should use typed storage, not OleVariant fields.');
  Assert.IsFalse(Pos('fItemTypeProperty: OleVariant', lSourceText) > 0,
    'Common string provider properties should use typed storage, not OleVariant fields.');
  Assert.IsFalse(Pos('fNameProperty: OleVariant', lSourceText) > 0,
    'Common string provider properties should use typed storage, not OleVariant fields.');
  Assert.Contains(lSourceText,
    'SetTypedStringProperty(aPropertyId, aValue, fAutomationIdProperty, fHasAutomationIdProperty)',
    'AutomationId must bypass the fallback property dictionary.');
  Assert.Contains(lSourceText, 'SetTypedStringProperty(aPropertyId, aValue, fClassNameProperty, fHasClassNameProperty)',
    'ClassName must bypass the fallback property dictionary.');
  Assert.Contains(lSourceText,
    'SetTypedIntegerProperty(aPropertyId, aValue, fControlTypeProperty, fHasControlTypeProperty)',
    'ControlType must bypass the fallback property dictionary.');
  Assert.Contains(lSourceText,
    'SetTypedStringProperty(aPropertyId, aValue, fFrameworkIdProperty, fHasFrameworkIdProperty)',
    'FrameworkId must bypass the fallback property dictionary.');
  Assert.Contains(lSourceText, 'SetTypedStringProperty(aPropertyId, aValue, fHelpTextProperty, fHasHelpTextProperty)',
    'HelpText must bypass the fallback property dictionary.');
  Assert.Contains(lSourceText,
    'SetTypedStringProperty(aPropertyId, aValue, fItemStatusProperty, fHasItemStatusProperty)',
    'ItemStatus must bypass the fallback property dictionary.');
  Assert.Contains(lSourceText, 'SetTypedStringProperty(aPropertyId, aValue, fItemTypeProperty, fHasItemTypeProperty)',
    'ItemType must bypass the fallback property dictionary.');
  Assert.Contains(lSourceText, 'SetTypedStringProperty(aPropertyId, aValue, fNameProperty, fHasNameProperty)',
    'Name must bypass the fallback property dictionary.');

  lProvider := TAccessibilityProviderFactory.CreateFragment([1]);
  lProvider.SetProperty(UIA_AutomationIdPropertyId, 'SaveButton');
  lProvider.SetProperty(UIA_FrameworkIdPropertyId, 'MaxLogic');
  lProvider.SetProperty(UIA_ItemStatusPropertyId, 'Ready');
  lProvider.SetProperty(UIA_ItemTypePropertyId, 'Action');

  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_AutomationIdPropertyId, lValue));
  Assert.AreEqual('SaveButton', string(lValue));
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_FrameworkIdPropertyId, lValue));
  Assert.AreEqual('MaxLogic', string(lValue));
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_ItemStatusPropertyId, lValue));
  Assert.AreEqual('Ready', string(lValue));
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_ItemTypePropertyId, lValue));
  Assert.AreEqual('Action', string(lValue));
end;

procedure TProviderCoreTests.CommonTypedStoragePreservesFallbackVariants;
var
  lControlType: Integer;
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lProvider: IAccessibilityProviderNode;
  lText: string;
  lValue: OleVariant;
begin
  lProvider := TAccessibilityProviderFactory.CreateFragment([1]);
  Assert.IsTrue(Supports(lProvider.RawElementProvider, IAccessibilityProviderDirectAccess, lDirectAccess));

  lProvider.SetProperty(UIA_NamePropertyId, Null);
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_NamePropertyId, lValue));
  Assert.IsTrue(VarIsNull(lValue), 'Fallback storage should preserve Null string-property values.');
  Assert.IsFalse(lDirectAccess.TryGetStringProperty(UIA_NamePropertyId, lText),
    'Direct string access should reject Null fallback values.');

  lProvider.SetProperty(UIA_NamePropertyId, 'Save');
  Assert.IsTrue(lDirectAccess.TryGetStringProperty(UIA_NamePropertyId, lText));
  Assert.AreEqual('Save', lText);

  lProvider.SetProperty(UIA_ControlTypePropertyId, Null);
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_ControlTypePropertyId, lValue));
  Assert.IsTrue(VarIsNull(lValue), 'Fallback storage should preserve Null integer-property values.');
  Assert.IsFalse(lDirectAccess.TryGetIntegerProperty(UIA_ControlTypePropertyId, lControlType),
    'Direct integer access should reject Null fallback values.');

  lProvider.SetProperty(UIA_ControlTypePropertyId, UIA_ButtonControlTypeId);
  Assert.IsTrue(lDirectAccess.TryGetIntegerProperty(UIA_ControlTypePropertyId, lControlType));
  Assert.AreEqual(UIA_ButtonControlTypeId, lControlType);
end;

procedure TProviderCoreTests.LeafProviderCreationDoesNotAllocateChildLists;
const
  cProviderCount = 256;
var
  i: Integer;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProvider: IAccessibilityProviderNode;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    for i := 1 to cProviderCount do
    begin
      lProvider := TAccessibilityProviderFactory.CreateFragment([1000 + i]);
      lProvider.SetProperty(UIA_NamePropertyId, 'Leaf');
    end;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lMetrics.ProviderChildListAllocationCount,
      'Leaf provider creation should not allocate child-list storage.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TProviderCoreTests.DirectPatternSupportUsesStatePropertiesBeforePatternProvider;
var
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lProvider: TPatternProbeProviderNode;
begin
  lProvider := TPatternProbeProviderNode.Create;
  Assert.IsTrue(Supports(lProvider.RawElementProvider, IAccessibilityProviderDirectAccess, lDirectAccess));

  Assert.IsTrue(lDirectAccess.SupportsPatternDirect(UIA_TogglePatternId));
  Assert.IsTrue(lDirectAccess.SupportsPatternDirect(UIA_SelectionItemPatternId));
  Assert.AreEqual(0, lProvider.PatternProbeCount,
    'Direct state-pattern checks should use in-process state properties before querying pattern providers.');
end;

procedure TProviderCoreTests.WindowedProvidersOverrideNativeProxyWithoutPublishingHwnd;
var
  lNativeWindow: IAccessibilityProviderNativeWindow;
  lProvider: IAccessibilityProviderNode;
  lProviderOptions: ProviderOptions;
  lValue: OleVariant;
begin
  lProvider := TAccessibilityProviderFactory.CreateRoot([77], HWND(123));

  Assert.AreEqual(S_OK, lProvider.RawElementProvider.Get_ProviderOptions(lProviderOptions));
  Assert.AreEqual(Integer(ProviderOptions_ServerSideProvider or ProviderOptions_OverrideProvider),
    Integer(lProviderOptions));
  Assert.IsTrue(Supports(lProvider.RawElementProvider, IAccessibilityProviderNativeWindow, lNativeWindow));
  Assert.AreEqual(HWND(123), lNativeWindow.NativeWindowHandle);
  Assert.AreEqual(S_OK, lProvider.RawElementProvider.GetPropertyValue(UIA_NativeWindowHandlePropertyId, lValue));
  Assert.IsTrue(VarIsEmpty(lValue));
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

procedure TProviderCoreTests.NestedFragmentRootUsesNearestFragmentRoot;
var
  lActualRoot: IRawElementProviderFragmentRoot;
  lChild: IAccessibilityProviderNode;
  lExpectedRoot: IRawElementProviderFragmentRoot;
  lInnerRoot: IAccessibilityProviderNode;
  lOuterRoot: IAccessibilityProviderNode;
begin
  lOuterRoot := TAccessibilityProviderFactory.CreateRoot([1], HWND(10));
  lInnerRoot := TAccessibilityProviderFactory.CreateRoot([2], HWND(20));
  lChild := TAccessibilityProviderFactory.CreateFragment([3]);

  lOuterRoot.AddChild(lInnerRoot);
  lInnerRoot.AddChild(lChild);

  Assert.IsTrue(Supports(lInnerRoot.RawElementProvider, IRawElementProviderFragmentRoot, lExpectedRoot));
  Assert.AreEqual(S_OK, lChild.FragmentProvider.Get_FragmentRoot(lActualRoot));
  Assert.IsTrue(InterfacesAreSame(lExpectedRoot, lActualRoot));
end;

procedure TProviderCoreTests.FragmentRootLookupDoesNotScaleWithProviderDepth;
const
  cIterations = 10000;
  cLargeDepth = 256;
  cMaxLargePercentOfShallow = 500;
  cShallowDepth = 1;
var
  lDeepTicks: Int64;
  lShallowTicks: Int64;
begin
  lShallowTicks := MeasureFragmentRootLookupTicks(cShallowDepth, cIterations);
  lDeepTicks := MeasureFragmentRootLookupTicks(cLargeDepth, cIterations);

  Assert.IsTrue(lDeepTicks * 100 <= lShallowTicks * cMaxLargePercentOfShallow,
    Format('Repeated Get_FragmentRoot should use a cached nearest root instead of walking parents; shallow=%d deep=%d.',
    [lShallowTicks, lDeepTicks]));
end;

procedure TProviderCoreTests.ElementProviderFromPointDoesNotBuildLogDescriptionWhenDiagnosticsDisabled;
var
  lHit: IRawElementProviderFragment;
  lProbe: IPropertyProbeProvider;
  lRoot: IAccessibilityProviderNode;
begin
  TAccessibilityDiagnostics.Disable;
  lRoot := TAccessibilityProviderFactory.CreateRoot([1], 0);
  lProbe := TCountingHitTestProviderNode.Create as IPropertyProbeProvider;
  lRoot.AddChild(lProbe as IAccessibilityProviderNode);

  Assert.AreEqual(S_OK, (lRoot.FragmentProvider as IRawElementProviderFragmentRoot).ElementProviderFromPoint(10, 10,
    lHit));
  Assert.IsNotNull(lHit);
  Assert.AreEqual(0, lProbe.PropertyProbeCount,
    'Mouse hit testing must not query provider properties only to build discarded diagnostics text.');
end;

procedure TProviderCoreTests.ElementProviderFromPointDoesNotBuildLogDescriptionWhenDiagnosticsEnabled;
var
  lHit: IRawElementProviderFragment;
  lLogFile: string;
  lProbe: IPropertyProbeProvider;
  lRoot: IAccessibilityProviderNode;
begin
  lLogFile := TPath.GetTempFileName;
  try
    TAccessibilityDiagnostics.Configure(lLogFile);
    lRoot := TAccessibilityProviderFactory.CreateRoot([1], 0);
    lProbe := TCountingHitTestProviderNode.Create as IPropertyProbeProvider;
    lRoot.AddChild(lProbe as IAccessibilityProviderNode);

    Assert.AreEqual(S_OK, (lRoot.FragmentProvider as IRawElementProviderFragmentRoot).ElementProviderFromPoint(10, 10,
      lHit));
    Assert.IsNotNull(lHit);
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.FlushLog(5000), 'Diagnostics did not become idle.');
    Assert.AreEqual(0, lProbe.PropertyProbeCount,
      'Enabled hit-test logging must not query provider properties solely to describe a trace line.');
  finally
    TAccessibilityDiagnostics.Disable;
    if TFile.Exists(lLogFile) then
    begin
      TFile.Delete(lLogFile);
    end;
  end;
end;

procedure TProviderCoreTests.ElementProviderFromPointUsesInternalBoundsWithoutProviderCallback;
var
  lHit: IRawElementProviderFragment;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProbe: IPropertyProbeProvider;
  lRoot: IAccessibilityProviderNode;
begin
  lRoot := TAccessibilityProviderFactory.CreateRoot([1], 0);
  lProbe := TCountingHitTestProviderNode.Create as IPropertyProbeProvider;
  lRoot.AddChild(lProbe as IAccessibilityProviderNode);

  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    Assert.AreEqual(S_OK, (lRoot.FragmentProvider as IRawElementProviderFragmentRoot).ElementProviderFromPoint(10, 10,
      lHit));
    Assert.IsNotNull(lHit);

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(1, lMetrics.ProviderRootElementProviderFromPointCount);
    Assert.AreEqual(0, lMetrics.ProviderGetBoundingRectangleCount,
      'Internal hit-test descent should call provider bounds directly instead of re-entering the UIA boundary wrapper.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
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

procedure TProviderCoreTests.WmGetObjectFallsBackWhenUiaRejectsProvider;
var
  lApi: ITestUiaApi;
  lHandled: Boolean;
  lMessageResult: LRESULT;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lApi.SetReturnRawElementProviderResult(LRESULT(E_FAIL));
  lProvider := TAccessibilityProviderFactory.CreateRoot([10], HWND(100), lApi);

  lHandled := TAccessibilityProviderWindowMessages.TryHandleGetObject(HWND(100), 7, UiaRootObjectId,
    lProvider.RawElementProvider, lApi, lMessageResult);

  Assert.IsFalse(lHandled);
  Assert.AreEqual(0, Integer(lMessageResult));
  Assert.AreEqual(1, lApi.ReturnCalls);
end;

procedure TProviderCoreTests.WmGetObjectLeavesClientObjectRequestsForNativeMsaa;
const
  cObjIdClient = LPARAM(-4);
var
  lApi: ITestUiaApi;
  lHandled: Boolean;
  lMessageResult: LRESULT;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TTestUiaApi.Create;
  lProvider := TAccessibilityProviderFactory.CreateRoot([10], HWND(100), lApi);

  lHandled := TAccessibilityProviderWindowMessages.TryHandleGetObject(HWND(100), 7, cObjIdClient,
    lProvider.RawElementProvider, lApi, lMessageResult);

  Assert.IsFalse(lHandled);
  Assert.AreEqual(0, Integer(lMessageResult));
  Assert.AreEqual(0, lApi.ReturnCalls);
end;

initialization
  TDUnitX.RegisterTestFixture(TProviderCoreTests);

end.
