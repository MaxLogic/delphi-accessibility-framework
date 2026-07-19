unit MaxLogic.Accessibility.StringGrid.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('StringGridAccessibility')]
  TStringGridAccessibilityTests = class
  public
    [Test]
    procedure GridProviderExposesDataGridPatternsAndVisibleCells;
    [Test]
    procedure GridPatternGetItemReturnsValidOffscreenCells;
    [Test]
    procedure GridProviderHitTestingReturnsTheCellUnderThePointer;
    [Test]
    procedure GridProviderHitTestingIgnoresPointsOutsideTheGrid;
    [Test]
    procedure GridProviderHitTestingIgnoresGridOnInactiveTab;
    [Test]
    procedure GridProviderFocusReturnsTheCurrentCell;
    [Test]
    procedure GridProviderFocusReturnsWholeRowForRowSelect;
    [Test]
    procedure GridProviderRowSelectFocusAndSelectionProvidersStayInTree;
    [Test]
    procedure GridProviderDoesNotClaimFocusWhenAnotherControlIsActive;
    [Test]
    procedure GridProviderHitTestingFindsNewlyVisibleCellAfterScroll;
    [Test]
    procedure GridProviderPrunesLazyCellsWhenTheyScrollOutOfView;
    [Test]
    procedure FormRootIgnoresDisconnectedGridHitTestRoots;
  end;

implementation

uses
  System.SysUtils, System.Types, System.Variants, Winapi.ActiveX, Winapi.Windows, Vcl.ComCtrls, Vcl.Controls,
  Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, DUnitX.Assert, MaxLogic.Accessibility.ProviderCore,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

function ScaleValue(aValue: Integer): Integer;
begin
  Result := MulDiv(aValue, Screen.PixelsPerInch, 96);
end;

function ControlScreenCenter(aControl: TControl): TPoint;
begin
  Result := aControl.ClientToScreen(Point(aControl.Width div 2, aControl.Height div 2));
end;

procedure CreateGridFixture(out aForm: TForm; out aGrid: TStringGrid);
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(420), ScaleValue(260));

  aGrid := TStringGrid.Create(aForm);
  aGrid.Name := 'OrdersGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(250), ScaleValue(115));
  aGrid.ColCount := 4;
  aGrid.RowCount := 4;
  aGrid.FixedCols := 1;
  aGrid.FixedRows := 1;
  aGrid.DefaultColWidth := ScaleValue(55);
  aGrid.DefaultRowHeight := ScaleValue(20);
  aGrid.ColWidths[3] := 0;
  aGrid.RowHeights[3] := 0;
  aGrid.Cells[0, 0] := 'ID';
  aGrid.Cells[1, 0] := 'Name';
  aGrid.Cells[2, 0] := 'Status';
  aGrid.Cells[0, 1] := '100';
  aGrid.Cells[1, 1] := 'Alice';
  aGrid.Cells[2, 1] := 'Running';
  aGrid.Cells[0, 2] := '101';
  aGrid.Cells[1, 2] := 'Bob';
  aGrid.Cells[2, 2] := 'Paused';
  aGrid.Cells[3, 3] := 'Hidden far cell';
  aGrid.Col := 2;
  aGrid.Row := 1;
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateScrollableGridFixture(out aForm: TForm; out aGrid: TStringGrid);
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(420), ScaleValue(260));

  aGrid := TStringGrid.Create(aForm);
  aGrid.Name := 'ScrollableGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(165), ScaleValue(75));
  aGrid.ColCount := 8;
  aGrid.RowCount := 8;
  aGrid.FixedCols := 1;
  aGrid.FixedRows := 1;
  aGrid.DefaultColWidth := ScaleValue(50);
  aGrid.DefaultRowHeight := ScaleValue(20);
  aGrid.Cells[6, 6] := 'Scrolled cell';
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

function SimpleProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Assert.IsTrue(Supports(aFragment, IRawElementProviderSimple, Result));
end;

function FragmentRoot(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragmentRoot;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider.RawElementProvider, IRawElementProviderFragmentRoot, Result));
end;

function FragmentFromSimple(const aProvider: IRawElementProviderSimple): IRawElementProviderFragment;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider, IRawElementProviderFragment, Result));
end;

function NavigateFragment(const aFragment: IRawElementProviderFragment; aDirection: NavigateDirection):
  IRawElementProviderFragment;
begin
  Result := nil;
  Assert.AreEqual(S_OK, aFragment.Navigate(aDirection, Result));
end;

function FirstChildFragment(const aFragment: IRawElementProviderFragment): IRawElementProviderFragment;
begin
  Result := NavigateFragment(aFragment, NavigateDirection_FirstChild);
  Assert.IsNotNull(Result);
end;

function ProviderIntProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): Integer;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := Integer(lValue);
end;

function ProviderPattern(const aFragment: IRawElementProviderFragment; aPatternId: PATTERNID): IUnknown;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPatternProvider(aPatternId, Result));
end;

function ProviderStringProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := string(lValue);
end;

function VisibleCellCount(aGrid: TStringGrid): Integer;
var
  lCellRect: TRect;
  lCol: Integer;
  lRow: Integer;
begin
  Result := 0;
  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    for lCol := 0 to Pred(aGrid.ColCount) do
    begin
      lCellRect := aGrid.CellRect(lCol, lRow);
      if (lCellRect.Width > 0) and (lCellRect.Height > 0) then
      begin
        Inc(Result);
      end;
    end;
  end;
end;

function CellIsVisible(aGrid: TStringGrid; aCol: Integer; aRow: Integer): Boolean;
var
  lCellRect: TRect;
begin
  lCellRect := aGrid.CellRect(aCol, aRow);
  Result := (lCellRect.Width > 0) and (lCellRect.Height > 0);
end;

function ChildFragmentCount(const aGridFragment: IRawElementProviderFragment): Integer;
var
  lCell: IRawElementProviderFragment;
begin
  Result := 0;
  lCell := NavigateFragment(aGridFragment, NavigateDirection_FirstChild);
  while lCell <> nil do
  begin
    Inc(Result);
    lCell := NavigateFragment(lCell, NavigateDirection_NextSibling);
  end;
end;

function ChildNameExists(const aGridFragment: IRawElementProviderFragment; const aName: string): Boolean;
var
  lCell: IRawElementProviderFragment;
begin
  Result := False;
  lCell := NavigateFragment(aGridFragment, NavigateDirection_FirstChild);
  while lCell <> nil do
  begin
    if ProviderStringProperty(lCell, UIA_NamePropertyId) = aName then
    begin
      Exit(True);
    end;

    lCell := NavigateFragment(lCell, NavigateDirection_NextSibling);
  end;
end;

function ScreenCellCenter(aGrid: TStringGrid; aCol: Integer; aRow: Integer): TPoint;
var
  lCellRect: TRect;
begin
  lCellRect := aGrid.CellRect(aCol, aRow);
  Assert.IsTrue((lCellRect.Width > 0) and (lCellRect.Height > 0));
  Result := aGrid.ClientToScreen(Point((lCellRect.Left + lCellRect.Right) div 2,
    (lCellRect.Top + lCellRect.Bottom) div 2));
end;

procedure AssertCellBounds(aGrid: TStringGrid; aCol: Integer; aRow: Integer;
  const aFragment: IRawElementProviderFragment);
var
  lBounds: UiaRect;
  lCellRect: TRect;
  lTopLeft: TPoint;
begin
  lCellRect := aGrid.CellRect(aCol, aRow);
  lTopLeft := aGrid.ClientToScreen(lCellRect.TopLeft);
  Assert.AreEqual(S_OK, aFragment.Get_BoundingRectangle(lBounds));
  Assert.AreEqual(lTopLeft.X, Integer(Round(lBounds.Left)));
  Assert.AreEqual(lTopLeft.Y, Integer(Round(lBounds.Top)));
  Assert.AreEqual(lCellRect.Width, Integer(Round(lBounds.Width)));
  Assert.AreEqual(lCellRect.Height, Integer(Round(lBounds.Height)));
end;

procedure TStringGridAccessibilityTests.GridProviderExposesDataGridPatternsAndVisibleCells;
var
  lCellFragment: IRawElementProviderFragment;
  lCellItem: IGridItemProvider;
  lCellSimple: IRawElementProviderSimple;
  lColumnCount: Integer;
  lContainingGrid: IRawElementProviderSimple;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRowCount: Integer;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    Assert.AreEqual(UIA_DataGridControlTypeId, ProviderIntProperty(lGridFragment, UIA_ControlTypePropertyId));
    Assert.AreEqual('OrdersGrid', ProviderStringProperty(lGridFragment, UIA_NamePropertyId));
    Assert.AreEqual(TStringGrid.ClassName, ProviderStringProperty(lGridFragment, UIA_ClassNamePropertyId));

    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));
    Assert.AreEqual(S_OK, lGridPattern.Get_RowCount(lRowCount));
    Assert.AreEqual(lGrid.RowCount, lRowCount);
    Assert.AreEqual(S_OK, lGridPattern.Get_ColumnCount(lColumnCount));
    Assert.AreEqual(lGrid.ColCount, lColumnCount);
    Assert.IsNotNull(ProviderPattern(lGridFragment, UIA_SelectionPatternId));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lCellSimple));
    Assert.IsNotNull(lCellSimple);
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('Alice', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));
    Assert.AreEqual(UIA_DataItemControlTypeId, ProviderIntProperty(lCellFragment, UIA_ControlTypePropertyId));
    AssertCellBounds(lGrid, 1, 1, lCellFragment);

    lPattern := ProviderPattern(lCellFragment, UIA_GridItemPatternId);
    Assert.IsTrue(Supports(lPattern, IGridItemProvider, lCellItem));
    Assert.AreEqual(S_OK, lCellItem.Get_ContainingGrid(lContainingGrid));
    Assert.IsNotNull(lContainingGrid);

    Assert.AreEqual(VisibleCellCount(lGrid), ChildFragmentCount(lGridFragment));
    Assert.IsTrue(ChildNameExists(lGridFragment, 'Running'));
    Assert.IsFalse(ChildNameExists(lGridFragment, 'Hidden far cell'));
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridPatternGetItemReturnsValidOffscreenCells;
var
  lCellFragment: IRawElementProviderFragment;
  lCellSimple: IRawElementProviderSimple;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
begin
  CreateScrollableGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(6, 6, lCellSimple));
    Assert.IsNotNull(lCellSimple);
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('Scrolled cell', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));
    Assert.AreEqual(UIA_DataItemControlTypeId, ProviderIntProperty(lCellFragment, UIA_ControlTypePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderFocusReturnsTheCurrentCell;
var
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lForm.ActiveControl := lGrid;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    Assert.AreEqual('Running', ProviderStringProperty(lFocus, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderFocusReturnsWholeRowForRowSelect;
var
  lExpectedName: string;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lExpectedName := 'ID: 101' + sLineBreak + sLineBreak + 'Name: Bob' + sLineBreak + sLineBreak +
      'Status: Paused';
    lGrid.Options := lGrid.Options + [goRowSelect];
    lGrid.Col := 1;
    lGrid.Row := 2;
    lForm.ActiveControl := lGrid;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    Assert.AreEqual(lExpectedName, ProviderStringProperty(lFocus, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderRowSelectFocusAndSelectionProvidersStayInTree;
var
  lExpectedName: string;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lParent: IRawElementProviderFragment;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lSelected: IRawElementProviderFragment;
  lSelection: PSafeArray;
  lSelectionIndex: LongInt;
  lSelectionProvider: ISelectionProvider;
  lSelectedUnknown: IUnknown;
  lSelectedSimple: IRawElementProviderSimple;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lExpectedName := 'ID: 101' + sLineBreak + sLineBreak + 'Name: Bob' + sLineBreak + sLineBreak +
      'Status: Paused';
    lGrid.Options := lGrid.Options + [goRowSelect];
    lGrid.Col := 1;
    lGrid.Row := 2;
    lForm.ActiveControl := lGrid;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    lParent := NavigateFragment(lFocus, NavigateDirection_Parent);
    Assert.IsNotNull(lParent);
    Assert.AreEqual('OrdersGrid', ProviderStringProperty(lParent, UIA_NamePropertyId));

    lPattern := ProviderPattern(lGridFragment, UIA_SelectionPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelectionProvider));
    lSelection := nil;
    Assert.AreEqual(S_OK, lSelectionProvider.GetSelection(lSelection));
    try
      Assert.IsNotNull(lSelection);
      lSelectionIndex := 0;
      lSelectedUnknown := nil;
      Assert.AreEqual(S_OK, SafeArrayGetElement(lSelection, lSelectionIndex, lSelectedUnknown));
      Assert.IsNotNull(lSelectedUnknown);
      Assert.IsTrue(Supports(lSelectedUnknown, IRawElementProviderSimple, lSelectedSimple));
      lSelected := FragmentFromSimple(lSelectedSimple);
      Assert.AreEqual(lExpectedName, ProviderStringProperty(lSelected, UIA_NamePropertyId));
      lParent := NavigateFragment(lSelected, NavigateDirection_Parent);
      Assert.IsNotNull(lParent);
      Assert.AreEqual('OrdersGrid', ProviderStringProperty(lParent, UIA_NamePropertyId));
    finally
      if lSelection <> nil then
      begin
        SafeArrayDestroy(lSelection);
      end;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderDoesNotClaimFocusWhenAnotherControlIsActive;
var
  lEdit: TEdit;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.SetBounds(ScaleValue(280), ScaleValue(8), ScaleValue(100), ScaleValue(24));
    lForm.ActiveControl := lEdit;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNull(lFocus);
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderHitTestingFindsNewlyVisibleCellAfterScroll;
var
  lForm: TForm;
  lGrid: TStringGrid;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateScrollableGridFixture(lForm, lGrid);
  try
    Assert.IsFalse(CellIsVisible(lGrid, 6, 6));

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    lGrid.LeftCol := 5;
    lGrid.TopRow := 5;
    Assert.IsTrue(CellIsVisible(lGrid, 6, 6));
    lPoint := ScreenCellCenter(lGrid, 6, 6);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Scrolled cell', ProviderStringProperty(lHit, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderPrunesLazyCellsWhenTheyScrollOutOfView;
var
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateScrollableGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    lGrid.LeftCol := 5;
    lGrid.TopRow := 5;
    lPoint := ScreenCellCenter(lGrid, 6, 6);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Scrolled cell', ProviderStringProperty(lHit, UIA_NamePropertyId));

    lGrid.LeftCol := 1;
    lGrid.TopRow := 1;
    Assert.IsFalse(CellIsVisible(lGrid, 6, 6));

    Assert.AreEqual(VisibleCellCount(lGrid), ChildFragmentCount(lGridFragment));
    Assert.IsFalse(ChildNameExists(lGridFragment, 'Scrolled cell'));
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderHitTestingReturnsTheCellUnderThePointer;
var
  lForm: TForm;
  lGrid: TStringGrid;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ScreenCellCenter(lGrid, 1, 1);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Alice', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.IsFalse(Pos('row', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) > 0);
    Assert.IsFalse(Pos('column', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) > 0);
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderHitTestingIgnoresPointsOutsideTheGrid;
var
  lForm: TForm;
  lGrid: TStringGrid;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := lForm.ClientToScreen(Point(lGrid.Left + lGrid.Width + ScaleValue(20),
      lGrid.Top + lGrid.Height + ScaleValue(20)));

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNull(lHit);
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.GridProviderHitTestingIgnoresGridOnInactiveTab;
var
  lActiveTab: TTabSheet;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridTab: TTabSheet;
  lHit: IRawElementProviderFragment;
  lLabel: TLabel;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(460), ScaleValue(320));

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(400), ScaleValue(250));

    lActiveTab := TTabSheet.Create(lForm);
    lActiveTab.Caption := 'Standard grid';
    lActiveTab.PageControl := lPageControl;

    lGridTab := TTabSheet.Create(lForm);
    lGridTab.Caption := 'Hidden grid';
    lGridTab.PageControl := lPageControl;

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Visible active tab label';
    lLabel.Parent := lActiveTab;
    lLabel.SetBounds(ScaleValue(30), ScaleValue(34), ScaleValue(180), ScaleValue(24));

    lGrid := TStringGrid.Create(lForm);
    lGrid.Name := 'InactiveGrid';
    lGrid.Parent := lGridTab;
    lGrid.SetBounds(ScaleValue(20), ScaleValue(20), ScaleValue(260), ScaleValue(130));
    lGrid.ColCount := 2;
    lGrid.RowCount := 2;
    lGrid.Cells[1, 1] := 'Hidden inactive grid cell';

    lPageControl.ActivePage := lActiveTab;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lLabel);

    Assert.IsFalse(lGrid.Showing, 'Inactive tab grid must not be considered showing.');
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Visible active tab label', ProviderStringProperty(lHit, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TStringGridAccessibilityTests.FormRootIgnoresDisconnectedGridHitTestRoots;
var
  lForm: TForm;
  lGrid: TStringGrid; //PALOFF WARN46 form-owned fixture setup is intentional
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := lForm.ClientToScreen(Point(ScaleValue(300), ScaleValue(200)));

    lGrid.Free;
    lGrid := nil;

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNull(lHit);
  finally
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TStringGridAccessibilityTests);

end.
