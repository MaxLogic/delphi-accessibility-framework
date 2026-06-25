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
    procedure MsaaFocusReturnsCurrentStringGridCell;
    [Test]
    procedure MsaaCheckboxAndRadioExposePlatformRoleAndState;
  end;

implementation

uses
  System.SysUtils, System.Variants, Winapi.ActiveX, Winapi.oleacc, Winapi.Windows, Vcl.ComCtrls, Vcl.Controls,
  Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.Msaa, MaxLogic.Accessibility.ProviderCore,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

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

    lDefaultAction := '';
    Assert.AreEqual(S_OK, lTmsAccessible.Get_accDefaultAction(CHILDID_SELF, lDefaultAction));
    Assert.AreEqual('Switch', string(lDefaultAction));
    Assert.AreEqual(S_OK, lTmsAccessible.accDoDefaultAction(CHILDID_SELF));
    Assert.AreSame(lTabTms, lPageControl.ActivePage);
    Assert.IsTrue((AccessibleState(lTmsAccessible) and STATE_SYSTEM_SELECTED) <> 0);
  finally
    lForm.Free;
  end;
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

    lFocus := Unassigned;
    Assert.AreEqual(S_OK, lAccessible.Get_accFocus(lFocus));
    Assert.AreEqual(varDispatch, VarType(lFocus));

    lCellDispatch := IDispatch(TVarData(lFocus).VDispatch);
    lCellAccessible := AccessibleFromDispatch(lCellDispatch);
    Assert.AreEqual('Contoso', AccessibleName(lCellAccessible));
    Assert.AreEqual(ROLE_SYSTEM_CELL, AccessibleRole(lCellAccessible));
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

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityMsaaTests);

end.
