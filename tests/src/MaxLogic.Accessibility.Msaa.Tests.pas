unit MaxLogic.Accessibility.Msaa.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Msaa')]
  TAccessibilityMsaaTests = class
  public
    [Test]
    procedure MsaaHitTestReturnsPageControlTabHeader;
    [Test]
    procedure MsaaPageControlTabHeaderExposesSelectionStateAndDefaultAction;
    [Test]
    procedure MsaaGetChildReturnsFailureForProviderExceptions;
    [Test]
    procedure MsaaChildNavigationDoesNotAliasReceiverAndOutParameter;
    [Test]
    procedure MsaaChildEnumerationUsesDirectProviderChildren;
    [Test]
    procedure MsaaFocusUsesDirectFocusedItemProvider;
    [Test]
    procedure MsaaFocusReturnsCurrentStringGridCell;
    [Test]
    procedure MsaaCheckboxAndRadioExposePlatformRoleAndState;
    [Test]
    procedure MsaaStateReadsDirectStatePropertiesWithoutPatternProbes;
    [Test]
    procedure MsaaCommonSpeechPropertiesUseDirectProviderAccess;
    [Test]
    procedure MsaaVclCaptionAndHelpStayCurrent;
    [Test]
    procedure MsaaLocationUsesDirectProviderGeometry;
    [Test]
    procedure MsaaHitTestUsesDirectProviderRootAccess;
    [Test]
    procedure MsaaHitTestMissUsesDirectProviderRootAccess;
    [Test]
    procedure MsaaHitTestUsesDirectNestedProviderRootAccess;
    [Test]
    procedure MsaaDirectAccessIsResolvedOncePerAccessibleWrapper;
    [Test]
    procedure MsaaObjectCacheReusesWrapperUntilCleared;
  end;

implementation

uses
  System.SysUtils, System.Types, System.TypInfo, System.Variants, Winapi.ActiveX, Winapi.oleacc, Winapi.Windows,
  Vcl.ComCtrls, Vcl.Controls, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.Diagnostics,
  MaxLogic.Accessibility.Msaa,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

type
  TFailingMsaaChildProvider = class(TAccessibilityProviderRoot)
  protected
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create;
  end;

  TDirectFocusedMsaaRootProvider = class(TAccessibilityProviderRoot, IAccessibilityFocusedItemProvider)
  private
    fFocusedProvider: IAccessibilityProviderNode;
    fRootGetFocusCount: Integer;
  protected
    function DoGetFocus(out aProvider: IRawElementProviderFragment): HResult; override;
  public
    constructor Create;
    function RootGetFocusCount: Integer;
    function TryGetFocusedItem(out aProvider: IRawElementProviderSimple; out aName: string): Boolean;
  end;

  TCountingMsaaStateProvider = class(TAccessibilityProviderNode)
  private
    fPatternProbeCount: Integer;
    fSelectionPropertyProbeCount: Integer;
    fTogglePropertyProbeCount: Integer;
  protected
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create;
    function PatternProbeCount: Integer;
    function SelectionPropertyProbeCount: Integer;
    function TogglePropertyProbeCount: Integer;
  end;

  TCountingDirectAccessProvider = class(TObject, IInterface, IRawElementProviderSimple,
    IAccessibilityProviderDirectAccess)
  private
    fDirectAccessQueryCount: Integer;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    function DirectAccessQueryCount: Integer;
    function Get_HostRawElementProvider(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_ProviderOptions(out aRetVal: ProviderOptions): HResult; stdcall;
    function GetPatternProvider(aPatternId: PATTERNID; out aRetVal: IUnknown): HResult; stdcall;
    function GetPropertyValue(aPropertyId: PROPERTYID; out aRetVal: OleVariant): HResult; stdcall;
    procedure ResetDirectAccessQueryCount;
    function SupportsPatternDirect(aPatternId: PATTERNID): Boolean;
    function TryGetIntegerProperty(aPropertyId: PROPERTYID; out aValue: Integer): Boolean;
    function TryGetNativeWindowHandle(out aValue: HWND): Boolean;
    function TryGetStringProperty(aPropertyId: PROPERTYID; out aValue: string): Boolean;
    function TryGetValueText(out aValue: string): Boolean;
  end;

constructor TFailingMsaaChildProvider.Create;
begin
  inherited CreateNode([1], 0, nil, nil);
end;

constructor TDirectFocusedMsaaRootProvider.Create;
begin
  inherited CreateNode([914], 0, nil, nil);
  fFocusedProvider := TAccessibilityProviderFactory.CreateFragment([915]);
  fFocusedProvider.SetProperty(UIA_NamePropertyId, 'Focused child');
  AddChild(fFocusedProvider);
end;

function TDirectFocusedMsaaRootProvider.DoGetFocus(out aProvider: IRawElementProviderFragment): HResult;
begin
  Inc(fRootGetFocusCount);
  aProvider := nil;
  Result := S_OK;
end;

function TDirectFocusedMsaaRootProvider.RootGetFocusCount: Integer;
begin
  Result := fRootGetFocusCount;
end;

function TDirectFocusedMsaaRootProvider.TryGetFocusedItem(out aProvider: IRawElementProviderSimple;
  out aName: string): Boolean;
begin
  aProvider := fFocusedProvider.RawElementProvider;
  aName := 'Focused child';
  Result := True;
end;

constructor TCountingMsaaStateProvider.Create;
begin
  inherited CreateNode([932], 0, nil, nil);
end;

function TCountingMsaaStateProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Inc(fPatternProbeCount);
  Result := inherited DoGetPatternProvider(aPatternId);
end;

function TCountingMsaaStateProvider.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_ControlTypePropertyId:
      aValue := UIA_CheckBoxControlTypeId;
    UIA_HasKeyboardFocusPropertyId:
      aValue := False;
    UIA_IsEnabledPropertyId:
      aValue := True;
    UIA_IsKeyboardFocusablePropertyId:
      aValue := True;
    UIA_IsOffscreenPropertyId:
      aValue := False;
    UIA_SelectionItemIsSelectedPropertyId:
      begin
        Inc(fSelectionPropertyProbeCount);
        Result := False;
      end;
    UIA_ToggleToggleStatePropertyId:
      begin
        Inc(fTogglePropertyProbeCount);
        aValue := Integer(ToggleState_On);
      end;
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TCountingMsaaStateProvider.PatternProbeCount: Integer;
begin
  Result := fPatternProbeCount;
end;

function TCountingMsaaStateProvider.SelectionPropertyProbeCount: Integer;
begin
  Result := fSelectionPropertyProbeCount;
end;

function TCountingMsaaStateProvider.TogglePropertyProbeCount: Integer;
begin
  Result := fTogglePropertyProbeCount;
end;

function TCountingDirectAccessProvider._AddRef: Integer;
begin
  Result := -1;
end;

function TCountingDirectAccessProvider._Release: Integer;
begin
  Result := -1;
end;

function TCountingDirectAccessProvider.DirectAccessQueryCount: Integer;
begin
  Result := fDirectAccessQueryCount;
end;

function TCountingDirectAccessProvider.Get_HostRawElementProvider(out aRetVal: IRawElementProviderSimple): HResult;
begin
  aRetVal := nil;
  Result := S_FALSE;
end;

function TCountingDirectAccessProvider.Get_ProviderOptions(out aRetVal: ProviderOptions): HResult;
begin
  aRetVal := ProviderOptions_ServerSideProvider;
  Result := S_OK;
end;

function TCountingDirectAccessProvider.GetPatternProvider(aPatternId: PATTERNID; out aRetVal: IUnknown): HResult;
begin
  aRetVal := nil;
  Result := S_OK;
end;

function TCountingDirectAccessProvider.GetPropertyValue(aPropertyId: PROPERTYID; out aRetVal: OleVariant): HResult;
begin
  aRetVal := Unassigned;
  Result := S_OK;
end;

function TCountingDirectAccessProvider.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
  begin
    if IsEqualGUID(IID, GetTypeData(TypeInfo(IAccessibilityProviderDirectAccess))^.Guid) then
    begin
      Inc(fDirectAccessQueryCount);
    end;

    Exit(S_OK);
  end;

  Result := E_NOINTERFACE;
end;

procedure TCountingDirectAccessProvider.ResetDirectAccessQueryCount;
begin
  fDirectAccessQueryCount := 0;
end;

function TCountingDirectAccessProvider.SupportsPatternDirect(aPatternId: PATTERNID): Boolean;
begin
  Result := aPatternId = UIA_TogglePatternId;
end;

function TCountingDirectAccessProvider.TryGetIntegerProperty(aPropertyId: PROPERTYID; out aValue: Integer): Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_ControlTypePropertyId:
      aValue := UIA_CheckBoxControlTypeId;
    UIA_HasKeyboardFocusPropertyId:
      aValue := 0;
    UIA_IsEnabledPropertyId:
      aValue := 1;
    UIA_IsKeyboardFocusablePropertyId:
      aValue := 1;
    UIA_IsOffscreenPropertyId:
      aValue := 0;
    UIA_SelectionItemIsSelectedPropertyId:
      begin
        aValue := 0;
        Result := False;
      end;
    UIA_ToggleToggleStatePropertyId:
      aValue := Integer(ToggleState_On);
  else
    aValue := 0;
    Result := False;
  end;
end;

function TCountingDirectAccessProvider.TryGetNativeWindowHandle(out aValue: HWND): Boolean;
begin
  aValue := 0;
  Result := False;
end;

function TCountingDirectAccessProvider.TryGetStringProperty(aPropertyId: PROPERTYID; out aValue: string): Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_HelpTextPropertyId:
      aValue := 'Synthetic help';
    UIA_NamePropertyId:
      aValue := 'Synthetic checkbox';
  else
    aValue := '';
    Result := False;
  end;
end;

function TCountingDirectAccessProvider.TryGetValueText(out aValue: string): Boolean;
begin
  aValue := 'Synthetic value';
  Result := True;
end;

procedure CreateCountingDirectAccessProvider(out aProvider: TCountingDirectAccessProvider;
  out aSimple: IRawElementProviderSimple);
begin
  aProvider := TCountingDirectAccessProvider.Create;
  try
    aSimple := aProvider as IRawElementProviderSimple;
  except
    aProvider.Free;
    aProvider := nil;
    raise;
  end;
end;

procedure TFailingMsaaChildProvider.PrepareChildrenForNavigation;
begin
  raise Exception.Create('Synthetic provider failure while navigating MSAA children.');
end;

function FragmentFromProvider(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragment;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider.RawElementProvider, IRawElementProviderFragment, Result));
end;

function FirstChild(const aFragment: IRawElementProviderFragment): IRawElementProviderFragment;
begin
  Result := nil;
  Assert.AreEqual(S_OK, aFragment.Navigate(NavigateDirection_FirstChild, Result));
  Assert.IsNotNull(Result);
end;

function NextSibling(const aFragment: IRawElementProviderFragment): IRawElementProviderFragment;
begin
  Result := nil;
  Assert.AreEqual(S_OK, aFragment.Navigate(NavigateDirection_NextSibling, Result));
  Assert.IsNotNull(Result);
end;

function SimpleProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Assert.IsTrue(Supports(aFragment, IRawElementProviderSimple, Result));
end;

function AccessibleFromDispatch(const aDispatch: IDispatch): IAccessible;
begin
  Result := nil;
  Assert.IsTrue(Supports(aDispatch, IAccessible, Result));
end;

function AccessibleFromObjectResult(aResult: LRESULT; aWParam: WPARAM): IAccessible;
begin
  Result := nil;
  Assert.IsTrue(aResult <> 0, 'MSAA WM_GETOBJECT did not return an object result.');
  Assert.AreEqual<HRESULT>(S_OK,
    ObjectFromLresult(aResult, IID_IAccessible, aWParam, Result));
  Assert.IsNotNull(Result);
end;

function SameAccessibleIdentity(const aFirst: IAccessible; const aSecond: IAccessible): Boolean;
var
  lFirstIdentity: IUnknown;
  lSecondIdentity: IUnknown;
begin
  lFirstIdentity := aFirst as IUnknown;
  lSecondIdentity := aSecond as IUnknown;
  Result := Pointer(lFirstIdentity) = Pointer(lSecondIdentity);
end;

function AccessibleFromProviderWithCache(const aProvider: IRawElementProviderSimple;
  var aCachedAccessible: IAccessible): IAccessible;
const
  cObjIdClient = LPARAM(OBJID_CLIENT);
var
  lResult: Winapi.Windows.LRESULT;
begin
  Assert.IsTrue(TAccessibilityMsaaBridge.TryHandleGetObject(0, cObjIdClient, aProvider, aCachedAccessible,
    lResult));
  Result := AccessibleFromObjectResult(lResult, 0);
end;

function AccessibleName(const aAccessible: IAccessible): string;
var
  lName: WideString;
begin
  lName := '';
  Assert.AreEqual(S_OK, aAccessible.Get_accName(CHILDID_SELF, lName));
  Result := string(lName);
end;

function AccessibleRole(const aAccessible: IAccessible): Integer;
var
  lRole: OleVariant;
begin
  lRole := Unassigned;
  Assert.AreEqual(S_OK, aAccessible.Get_accRole(CHILDID_SELF, lRole));
  Result := Integer(lRole);
end;

function AccessibleState(const aAccessible: IAccessible): Integer;
var
  lState: OleVariant;
begin
  lState := Unassigned;
  Assert.AreEqual(S_OK, aAccessible.Get_accState(CHILDID_SELF, lState));
  Result := Integer(lState);
end;

function AccessibleHitTestAt(const aAccessible: IAccessible; const aPoint: TPoint): IAccessible;
var
  lHit: OleVariant;
  lHitDispatch: IDispatch;
begin
  lHit := Unassigned;
  Assert.AreEqual(S_OK, aAccessible.accHitTest(aPoint.X, aPoint.Y, lHit));
  Assert.AreEqual(varDispatch, VarType(lHit));

  lHitDispatch := IDispatch(TVarData(lHit).VDispatch);
  Result := AccessibleFromDispatch(lHitDispatch);
end;

procedure TAccessibilityMsaaTests.MsaaHitTestReturnsPageControlTabHeader;
var
  lAccessible: IAccessible;
  lForm: TForm;
  lHit: OleVariant;
  lHitAccessible: IAccessible;
  lHitDispatch: IDispatch;
  lPageControl: TPageControl;
  lProvider: IAccessibilityProviderNode;
  lTabOrders: TTabSheet;
  lTabRect: TRect;
  lTabTms: TTabSheet;
  lPoint: TPoint;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lPageControl.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);

    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lPoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);
    lHit := Unassigned;
    Assert.AreEqual(S_OK, lAccessible.accHitTest(lPoint.X, lPoint.Y, lHit));
    Assert.AreEqual(varDispatch, VarType(lHit));

    lHitDispatch := IDispatch(TVarData(lHit).VDispatch);
    lHitAccessible := AccessibleFromDispatch(lHitDispatch);
    Assert.AreEqual('TMS grid', AccessibleName(lHitAccessible));
    Assert.AreEqual(ROLE_SYSTEM_PAGETAB, AccessibleRole(lHitAccessible));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaPageControlTabHeaderExposesSelectionStateAndDefaultAction;
var
  lAccessible: IAccessible;
  lDefaultAction: WideString;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lOrdersAccessible: IAccessible;
  lOrdersRect: TRect;
  lPageControl: TPageControl;
  lProvider: IAccessibilityProviderNode;
  lState: Integer;
  lTabOrders: TTabSheet;
  lTabTms: TTabSheet;
  lTmsAccessible: IAccessible;
  lTmsRect: TRect;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lPageControl.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);

    lOrdersRect := lPageControl.TabRect(lTabOrders.TabIndex);
    lOrdersAccessible := AccessibleHitTestAt(lAccessible, lPageControl.ClientToScreen(lOrdersRect.CenterPoint));
    Assert.AreEqual('Orders', AccessibleName(lOrdersAccessible));
    lState := AccessibleState(lOrdersAccessible);
    Assert.IsTrue((lState and STATE_SYSTEM_SELECTABLE) <> 0);
    Assert.IsTrue((lState and STATE_SYSTEM_SELECTED) <> 0);

    lTmsRect := lPageControl.TabRect(lTabTms.TabIndex);
    lTmsAccessible := AccessibleHitTestAt(lAccessible, lPageControl.ClientToScreen(lTmsRect.CenterPoint));
    Assert.AreEqual('TMS grid', AccessibleName(lTmsAccessible));
    lState := AccessibleState(lTmsAccessible);
    Assert.IsTrue((lState and STATE_SYSTEM_SELECTABLE) <> 0);
    Assert.IsTrue((lState and STATE_SYSTEM_SELECTED) = 0);

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lDefaultAction := '';
      Assert.AreEqual(S_OK, lTmsAccessible.Get_accDefaultAction(CHILDID_SELF, lDefaultAction));
      Assert.AreEqual('Switch', string(lDefaultAction));
      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderGetPatternProviderCount,
        'MSAA tab default action should use direct pattern support checks for framework providers.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;

    Assert.AreEqual(S_OK, lTmsAccessible.accDoDefaultAction(CHILDID_SELF));
    Assert.AreSame(lTabTms, lPageControl.ActivePage);
    Assert.IsTrue((AccessibleState(lTmsAccessible) and STATE_SYSTEM_SELECTED) <> 0);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaGetChildReturnsFailureForProviderExceptions;
var
  lAccessible: IAccessible;
  lDispatch: IDispatch;
  lProvider: IAccessibilityProviderNode;
begin
  lProvider := TFailingMsaaChildProvider.Create as IAccessibilityProviderNode;
  lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);

  lDispatch := nil;
  Assert.AreEqual(E_UNEXPECTED, lAccessible.Get_accChild(1, lDispatch));
  Assert.IsNull(lDispatch);
end;

procedure TAccessibilityMsaaTests.MsaaChildNavigationDoesNotAliasReceiverAndOutParameter;
var
  lAccessible: IAccessible;
  lChildAccessible: IAccessible;
  lChildCount: Integer;
  lChildDispatch: IDispatch;
  lFirstEdit: TEdit;
  lForm: TForm;
  lProvider: IAccessibilityProviderNode;
  lSecondEdit: TEdit;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lFirstEdit := TEdit.Create(lForm);
    lFirstEdit.Name := 'edtFirst';
    lFirstEdit.Text := 'First child';
    lFirstEdit.Parent := lForm;

    lSecondEdit := TEdit.Create(lForm);
    lSecondEdit.Name := 'edtSecond';
    lSecondEdit.Text := 'Second child';
    lSecondEdit.Parent := lForm;

    lForm.HandleNeeded;
    lFirstEdit.HandleNeeded;
    lSecondEdit.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);

    lChildCount := 0;
    Assert.AreEqual(S_OK, lAccessible.Get_accChildCount(lChildCount));
    Assert.AreEqual(2, lChildCount);

    lChildDispatch := nil;
    Assert.AreEqual(S_OK, lAccessible.Get_accChild(2, lChildDispatch));
    lChildAccessible := AccessibleFromDispatch(lChildDispatch);
    Assert.AreEqual('Second child', AccessibleName(lChildAccessible));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaChildEnumerationUsesDirectProviderChildren;
const
  cChildCount = 64;
var
  i: Integer;
  lAccessible: IAccessible;
  lChild: IAccessibilityProviderNode;
  lChildAccessible: IAccessible;
  lChildCount: Integer;
  lChildDispatch: IDispatch;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProvider: IAccessibilityProviderNode;
begin
  lProvider := TAccessibilityProviderFactory.CreateRoot([1], 0);
  for i := 1 to cChildCount do
  begin
    lChild := TAccessibilityProviderFactory.CreateFragment([1000 + i]);
    lChild.SetProperty(UIA_NamePropertyId, Format('Child %.2d', [i]));
    lProvider.AddChild(lChild);
  end;

  lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    lChildCount := 0;
    Assert.AreEqual(S_OK, lAccessible.Get_accChildCount(lChildCount));
    Assert.AreEqual(cChildCount, lChildCount);

    lChildDispatch := nil;
    Assert.AreEqual(S_OK, lAccessible.Get_accChild(cChildCount, lChildDispatch));
    lChildAccessible := AccessibleFromDispatch(lChildDispatch);
    Assert.AreEqual('Child 64', AccessibleName(lChildAccessible));

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
      'MSAA child enumeration should use direct provider-child access, not UIA Navigate callbacks.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaFocusUsesDirectFocusedItemProvider;
var
  lAccessible: IAccessible;
  lDirectRoot: TDirectFocusedMsaaRootProvider;
  lFocus: OleVariant;
  lFocusAccessible: IAccessible;
  lFocusDispatch: IDispatch;
  lProvider: IAccessibilityProviderNode;
begin
  lDirectRoot := TDirectFocusedMsaaRootProvider.Create;
  lProvider := lDirectRoot as IAccessibilityProviderNode; //PALOFF WARN53 test also inspects the concrete root
  lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);

  lFocus := Unassigned;
  Assert.AreEqual(S_OK, lAccessible.Get_accFocus(lFocus));
  Assert.AreEqual(varDispatch, VarType(lFocus));

  lFocusDispatch := IDispatch(TVarData(lFocus).VDispatch);
  lFocusAccessible := AccessibleFromDispatch(lFocusDispatch);
  Assert.AreEqual('Focused child', AccessibleName(lFocusAccessible));
  Assert.AreEqual(0, lDirectRoot.RootGetFocusCount,
    'MSAA focus should use direct focused-item access before generic root GetFocus traversal.');
end;

procedure TAccessibilityMsaaTests.MsaaFocusReturnsCurrentStringGridCell;
var
  lAccessible: IAccessible;
  lCellAccessible: IAccessible;
  lCellDispatch: IDispatch;
  lFocus: OleVariant;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.SetBounds(12, 12, 260, 120);
    lGrid.ColCount := 2;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Cells[1, 1] := 'Alice';
    lGrid.Cells[1, 2] := 'Contoso';
    lGrid.Col := 1;
    lGrid.Row := 2;
    lForm.ActiveControl := lGrid;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lGridFragment := FirstChild(FragmentFromProvider(lProvider));
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lGridFragment));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lFocus := Unassigned;
      Assert.AreEqual(S_OK, lAccessible.Get_accFocus(lFocus));
      Assert.AreEqual(varDispatch, VarType(lFocus));

      lCellDispatch := IDispatch(TVarData(lFocus).VDispatch);
      lCellAccessible := AccessibleFromDispatch(lCellDispatch);
      Assert.AreEqual('Contoso', AccessibleName(lCellAccessible));
      Assert.AreEqual(ROLE_SYSTEM_CELL, AccessibleRole(lCellAccessible));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderRootGetFocusCount,
        'MSAA grid focus should use the provider direct focused-item path, not generic root GetFocus traversal.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaCheckboxAndRadioExposePlatformRoleAndState;
var
  lCheckedAccessible: IAccessible;
  lCheckedBox: TCheckBox;
  lCheckedFragment: IRawElementProviderFragment;
  lForm: TForm;
  lMixedAccessible: IAccessible;
  lMixedBox: TCheckBox;
  lMixedFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lRadioAccessible: IAccessible;
  lRadioFragment: IRawElementProviderFragment;
  lRadioSelected: TRadioButton;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lCheckedBox := TCheckBox.Create(lForm);
    lCheckedBox.Caption := 'Include archived rows';
    lCheckedBox.Checked := True;
    lCheckedBox.Parent := lForm;

    lMixedBox := TCheckBox.Create(lForm);
    lMixedBox.Caption := 'Partially available';
    lMixedBox.AllowGrayed := True;
    lMixedBox.State := cbGrayed;
    lMixedBox.Parent := lForm;

    lRadioSelected := TRadioButton.Create(lForm);
    lRadioSelected.Caption := 'Compact';
    lRadioSelected.Checked := True;
    lRadioSelected.Parent := lForm;

    lForm.HandleNeeded;
    lCheckedBox.HandleNeeded;
    lMixedBox.HandleNeeded;
    lRadioSelected.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lCheckedFragment := FirstChild(FragmentFromProvider(lProvider));
    lMixedFragment := NextSibling(lCheckedFragment);
    lRadioFragment := NextSibling(lMixedFragment);

    lCheckedAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lCheckedFragment));
    Assert.AreEqual('Include archived rows', AccessibleName(lCheckedAccessible));
    Assert.AreEqual(ROLE_SYSTEM_CHECKBUTTON, AccessibleRole(lCheckedAccessible));
    Assert.IsTrue((AccessibleState(lCheckedAccessible) and STATE_SYSTEM_CHECKED) <> 0);

    lMixedAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lMixedFragment));
    Assert.AreEqual(ROLE_SYSTEM_CHECKBUTTON, AccessibleRole(lMixedAccessible));
    Assert.IsTrue((AccessibleState(lMixedAccessible) and STATE_SYSTEM_MIXED) <> 0);

    lRadioAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lRadioFragment));
    Assert.AreEqual('Compact', AccessibleName(lRadioAccessible));
    Assert.AreEqual(ROLE_SYSTEM_RADIOBUTTON, AccessibleRole(lRadioAccessible));
    Assert.IsTrue((AccessibleState(lRadioAccessible) and STATE_SYSTEM_CHECKED) <> 0);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaStateReadsDirectStatePropertiesWithoutPatternProbes;
var
  lAccessible: IAccessible;
  lProvider: TCountingMsaaStateProvider;
  lState: OleVariant;
begin
  lProvider := TCountingMsaaStateProvider.Create;
  lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);
  lState := Unassigned;

  Assert.AreEqual(S_OK, lAccessible.Get_accState(CHILDID_SELF, lState));

  Assert.IsTrue((Integer(lState) and STATE_SYSTEM_CHECKED) <> 0);
  Assert.AreEqual(1, lProvider.SelectionPropertyProbeCount,
    'MSAA state composition should test SelectionItem state with one direct property read.');
  Assert.AreEqual(1, lProvider.TogglePropertyProbeCount,
    'MSAA state composition should read Toggle state once, not once for support and again for state.');
  Assert.AreEqual(0, lProvider.PatternProbeCount,
    'MSAA state composition should not probe UIA pattern providers when direct state properties are available.');
end;

procedure TAccessibilityMsaaTests.MsaaCommonSpeechPropertiesUseDirectProviderAccess;
var
  lCheckBox: TCheckBox;
  lCheckBoxAccessible: IAccessible;
  lCheckBoxFragment: IRawElementProviderFragment;
  lEdit: TEdit;
  lEditAccessible: IAccessible;
  lEditFragment: IRawElementProviderFragment;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lName: WideString;
  lProvider: IAccessibilityProviderNode;
  lRole: OleVariant;
  lState: OleVariant;
  lValue: WideString;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lEdit := TEdit.Create(lForm);
    lEdit.Text := 'Search value';
    lEdit.Parent := lForm;

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Checked := True;
    lCheckBox.Parent := lForm;

    lForm.HandleNeeded;
    lEdit.HandleNeeded;
    lCheckBox.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lEditFragment := FirstChild(FragmentFromProvider(lProvider));
    lCheckBoxFragment := NextSibling(lEditFragment);
    lEditAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lEditFragment));
    lCheckBoxAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lCheckBoxFragment));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lValue := '';
      Assert.AreEqual(S_OK, lEditAccessible.Get_accValue(CHILDID_SELF, lValue));
      Assert.AreEqual('Search value', string(lValue));

      lName := '';
      Assert.AreEqual(S_OK, lCheckBoxAccessible.Get_accName(CHILDID_SELF, lName));
      Assert.AreEqual('Include archived rows', string(lName));
      lRole := Unassigned;
      Assert.AreEqual(S_OK, lCheckBoxAccessible.Get_accRole(CHILDID_SELF, lRole));
      Assert.AreEqual(ROLE_SYSTEM_CHECKBUTTON, Integer(lRole));
      lState := Unassigned;
      Assert.AreEqual(S_OK, lCheckBoxAccessible.Get_accState(CHILDID_SELF, lState));
      Assert.IsTrue((Integer(lState) and STATE_SYSTEM_CHECKED) <> 0);

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderGetPropertyValueCount,
        'MSAA speech properties should read framework provider properties in-process.');
      Assert.AreEqual(0, lMetrics.ProviderGetPatternProviderCount,
        'MSAA speech properties should read framework provider patterns in-process.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaLocationUsesDirectProviderGeometry;
var
  lAccessible: IAccessible;
  lButton: TButton;
  lButtonFragment: IRawElementProviderFragment;
  lForm: TForm;
  lHeight: Integer;
  lLeft: Integer; //PALOFF WARN46 output argument verifies the API call path
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProvider: IAccessibilityProviderNode;
  lTop: Integer; //PALOFF WARN46 output argument verifies the API call path
  lWidth: Integer;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lButton := TButton.Create(lForm);
    lButton.Caption := 'Apply';
    lButton.SetBounds(24, 32, 88, 28);
    lButton.Parent := lForm;

    lForm.HandleNeeded;
    lButton.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lButtonFragment := FirstChild(FragmentFromProvider(lProvider));
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lButtonFragment));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lLeft := 0;
      lTop := 0;
      lWidth := 0;
      lHeight := 0;
      Assert.AreEqual(S_OK, lAccessible.accLocation(lLeft, lTop, lWidth, lHeight, CHILDID_SELF));
      Assert.IsTrue(lWidth > 0, 'MSAA location should expose a positive width.');
      Assert.IsTrue(lHeight > 0, 'MSAA location should expose a positive height.');

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderGetBoundingRectangleCount,
        'MSAA accLocation should read provider bounds through direct geometry access.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaVclCaptionAndHelpStayCurrent;
var
  lAccessible: IAccessible;
  lButton: TButton;
  lButtonFragment: IRawElementProviderFragment;
  lForm: TForm;
  lHelp: WideString;
  lName: WideString;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lButton := TButton.Create(lForm);
    lButton.Caption := 'Button initial';
    lButton.Hint := 'Button initial hint';
    lButton.Parent := lForm;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lButtonFragment := FirstChild(FragmentFromProvider(lProvider));
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(SimpleProvider(lButtonFragment));

    lButton.Caption := 'Button updated';
    lButton.Hint := 'Button updated hint';

    lName := '';
    Assert.AreEqual(S_OK, lAccessible.Get_accName(CHILDID_SELF, lName));
    Assert.AreEqual('Button updated', string(lName));
    lHelp := '';
    Assert.AreEqual(S_OK, lAccessible.Get_accHelp(CHILDID_SELF, lHelp));
    Assert.AreEqual('Button updated hint', string(lHelp));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaHitTestUsesDirectProviderRootAccess;
var
  lAccessible: IAccessible;
  lButton: TButton;
  lForm: TForm;
  lHit: OleVariant;
  lHitAccessible: IAccessible;
  lHitDispatch: IDispatch;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lButton := TButton.Create(lForm);
    lButton.Caption := 'Apply';
    lButton.SetBounds(24, 32, 88, 28);
    lButton.Parent := lForm;

    lForm.HandleNeeded;
    lButton.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);
    lPoint := lButton.ClientToScreen(Point(lButton.Width div 2, lButton.Height div 2));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lHit := Unassigned;
      Assert.AreEqual(S_OK, lAccessible.accHitTest(lPoint.X, lPoint.Y, lHit));
      Assert.AreEqual(varDispatch, VarType(lHit));

      lHitDispatch := IDispatch(TVarData(lHit).VDispatch);
      lHitAccessible := AccessibleFromDispatch(lHitDispatch);
      Assert.AreEqual('Apply', AccessibleName(lHitAccessible));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderRootElementProviderFromPointCount,
        'MSAA hit testing should use direct framework root access instead of the public UIA hit-test callback.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaHitTestMissUsesDirectProviderRootAccess;
var
  lAccessible: IAccessible;
  lButton: TButton;
  lForm: TForm;
  lHit: OleVariant;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lButton := TButton.Create(lForm);
    lButton.Caption := 'Apply';
    lButton.SetBounds(24, 32, 88, 28);
    lButton.Parent := lForm;

    lForm.HandleNeeded;
    lButton.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);
    lPoint := lForm.ClientToScreen(Point(220, 100));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lHit := Unassigned;
      Assert.AreEqual(S_OK, lAccessible.accHitTest(lPoint.X, lPoint.Y, lHit));
      Assert.AreEqual(CHILDID_SELF, Integer(lHit));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderRootElementProviderFromPointCount,
        'MSAA hit-test misses should not fall back to the public UIA root hit-test callback.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaHitTestUsesDirectNestedProviderRootAccess;
var
  lAccessible: IAccessible;
  lCellRect: TRect;
  lForm: TForm;
  lGrid: TStringGrid;
  lHit: OleVariant;
  lHitAccessible: IAccessible;
  lHitDispatch: IDispatch;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.SetBounds(12, 12, 260, 120);
    lGrid.ColCount := 2;
    lGrid.RowCount := 2;
    lGrid.Cells[1, 1] := 'Grid item';

    lForm.HandleNeeded;
    lGrid.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lProvider.RawElementProvider);
    lCellRect := lGrid.CellRect(1, 1);
    lPoint := lGrid.ClientToScreen(lCellRect.CenterPoint);

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lHit := Unassigned;
      Assert.AreEqual(S_OK, lAccessible.accHitTest(lPoint.X, lPoint.Y, lHit));
      Assert.AreEqual(varDispatch, VarType(lHit));

      lHitDispatch := IDispatch(TVarData(lHit).VDispatch);
      lHitAccessible := AccessibleFromDispatch(lHitDispatch);
      Assert.AreEqual('Grid item', AccessibleName(lHitAccessible));
      Assert.AreEqual(ROLE_SYSTEM_CELL, AccessibleRole(lHitAccessible));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderRootElementProviderFromPointCount,
        'MSAA nested hit testing should stay on direct framework root access.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaDirectAccessIsResolvedOncePerAccessibleWrapper;
var
  lAccessible: IAccessible;
  lHelp: WideString;
  lName: WideString;
  lProvider: TCountingDirectAccessProvider;
  lRole: OleVariant;
  lSimple: IRawElementProviderSimple;
  lState: OleVariant;
  lValue: WideString;
begin
  CreateCountingDirectAccessProvider(lProvider, lSimple);
  try
    lAccessible := TAccessibilityMsaaBridge.CreateAccessible(lSimple);
    lProvider.ResetDirectAccessQueryCount;

    lName := '';
    Assert.AreEqual(S_OK, lAccessible.Get_accName(CHILDID_SELF, lName));
    Assert.AreEqual('Synthetic checkbox', string(lName));

    lRole := Unassigned;
    Assert.AreEqual(S_OK, lAccessible.Get_accRole(CHILDID_SELF, lRole));
    Assert.AreEqual(ROLE_SYSTEM_CHECKBUTTON, Integer(lRole));

    lState := Unassigned;
    Assert.AreEqual(S_OK, lAccessible.Get_accState(CHILDID_SELF, lState));
    Assert.IsTrue((Integer(lState) and STATE_SYSTEM_CHECKED) <> 0);

    lValue := '';
    Assert.AreEqual(S_OK, lAccessible.Get_accValue(CHILDID_SELF, lValue));
    Assert.AreEqual('Synthetic value', string(lValue));

    lHelp := '';
    Assert.AreEqual(S_OK, lAccessible.Get_accHelp(CHILDID_SELF, lHelp));
    Assert.AreEqual('Synthetic help', string(lHelp));

    Assert.AreEqual(0, lProvider.DirectAccessQueryCount,
      'MSAA wrapper should cache direct provider access instead of querying the same interface per property.');
  finally
    lAccessible := nil;
    lSimple := nil;
    lProvider.Free;
  end;
end;

procedure TAccessibilityMsaaTests.MsaaObjectCacheReusesWrapperUntilCleared;
var
  lCachedAccessible: IAccessible;
  lCoInit: HRESULT;
  lFirst: IAccessible;
  lProvider: TCountingDirectAccessProvider;
  lSecond: IAccessible;
  lSimple: IRawElementProviderSimple;
  lThird: IAccessible;
begin
  lCachedAccessible := nil;
  lCoInit := CoInitialize(nil);
  CreateCountingDirectAccessProvider(lProvider, lSimple);
  try
    Assert.IsTrue((lCoInit = S_OK) or (lCoInit = S_FALSE) or (lCoInit = RPC_E_CHANGED_MODE));
    lProvider.ResetDirectAccessQueryCount;

    lFirst := AccessibleFromProviderWithCache(lSimple, lCachedAccessible);
    lSecond := AccessibleFromProviderWithCache(lSimple, lCachedAccessible);
    Assert.IsTrue(SameAccessibleIdentity(lFirst, lSecond));
    Assert.AreEqual(1, lProvider.DirectAccessQueryCount,
      'Repeated requests must not resolve wrapper interfaces again.');

    lCachedAccessible := nil;
    lThird := AccessibleFromProviderWithCache(lSimple, lCachedAccessible);
    Assert.IsFalse(SameAccessibleIdentity(lFirst, lThird));
    Assert.AreEqual(2, lProvider.DirectAccessQueryCount,
      'Clearing the cache must release its wrapper and create one replacement on demand.');
  finally
    lCachedAccessible := nil;
    lFirst := nil;
    lSecond := nil;
    lSimple := nil;
    lThird := nil;
    lProvider.Free;
    if (lCoInit = S_OK) or (lCoInit = S_FALSE) then
    begin
      CoUninitialize;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityMsaaTests);

end.
