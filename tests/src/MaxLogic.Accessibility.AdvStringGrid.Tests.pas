unit MaxLogic.Accessibility.AdvStringGrid.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('AdvStringGridAccessibility')]
  TAdvStringGridAccessibilityTests = class
  public
    [Test]
    procedure DefaultVclRegistryDoesNotApplyTmsSpecificTextHandling;
    [Test]
    procedure OptInProviderExposesDataGridPatternsAndCellText;
    [Test]
    procedure OptInProviderGridPatternGetItemReturnsValidOffscreenCells;
    [Test]
    procedure OptInProviderSelectionReturnsCurrentCell;
    [Test]
    procedure OptInProviderColumnSpanCountsOnlyVisibleMergedColumns;
    [Test]
    procedure OptInProviderRowSpanCountsOnlyVisibleMergedRows;
    [Test]
    procedure OptInProviderRowSpanIgnoresHiddenRowsBeforeMerge;
    [Test]
    procedure OptInProviderUsesVisibleRepresentativeForHiddenMergeBaseColumn;
    [Test]
    procedure OptInProviderUsesVisibleRepresentativeForHiddenMergeBaseRow;
    [Test]
    procedure OptInProviderOmitsFullyHiddenMerge;
    [Test]
    procedure OptInProviderHitTestingReturnsOnlyTheCellUnderThePointer;
    [Test]
    procedure OptInProviderHitTestingIgnoresPointsOutsideTheGrid;
    [Test]
    procedure OptInProviderHitTestingIgnoresGridOnInactiveTab;
    [Test]
    procedure OptInProviderFocusReturnsTheCurrentCell;
    [Test]
    procedure OptInProviderFindsScrolledCellsAndPrunesStaleChildren;
    [Test]
    procedure OptInProviderPrunesScrolledCellsWithoutUiaDisconnect;
  end;

implementation

uses
  System.SysUtils, System.Types, System.Variants, Winapi.ActiveX, Winapi.Windows, Vcl.ComCtrls, Vcl.Controls,
  Vcl.Forms, Vcl.StdCtrls, AdvGrid, DUnitX.Assert, MaxLogic.Accessibility.ProviderCore,
  MaxLogic.Accessibility.Scanner, MaxLogic.Accessibility.TmsAdvStringGridAdapters, MaxLogic.Accessibility.UIAutomationCore,
  MaxLogic.Accessibility.VclAdapters;

type
  IAdvStringGridTestUiaApi = interface(IAccessibilityUiaApi)
    ['{4B10309B-F6EA-4896-B1D0-8C728D163DDE}']
    function DisconnectCalls: Integer;
  end;

  TAdvStringGridTestUiaApi = class(TInterfacedObject, IAdvStringGridTestUiaApi)
  private
    fDisconnectCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectCalls: Integer;
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

function TAdvStringGridTestUiaApi.ClientsAreListening: Boolean;
begin
  Result := False;
end;

function TAdvStringGridTestUiaApi.DisconnectCalls: Integer;
begin
  Result := fDisconnectCalls;
end;

function TAdvStringGridTestUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Inc(fDisconnectCalls);
  Result := S_OK;
end;

function TAdvStringGridTestUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple):
  HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function TAdvStringGridTestUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID): HRESULT;
begin
  Result := S_OK;
end;

function TAdvStringGridTestUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := S_OK;
end;

function TAdvStringGridTestUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Result := S_OK;
end;

function TAdvStringGridTestUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Result := S_OK;
end;

function TAdvStringGridTestUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Result := 0;
end;

function ScaleValue(aValue: Integer): Integer;
begin
  Result := MulDiv(aValue, Screen.PixelsPerInch, 96);
end;

function ControlScreenCenter(aControl: TControl): TPoint;
begin
  Result := aControl.ClientToScreen(Point(aControl.Width div 2, aControl.Height div 2));
end;

procedure CreateAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'AdvOrdersGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(280), ScaleValue(135));
  aGrid.ColCount := 5;
  aGrid.RowCount := 5;
  aGrid.FixedCols := 1;
  aGrid.FixedRows := 1;
  aGrid.DefaultColWidth := ScaleValue(55);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(55);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.Cells[0, 0] := 'ID';
  aGrid.Cells[1, 0] := 'Name';
  aGrid.Cells[2, 0] := 'Notes';
  aGrid.Cells[1, 1] := '<b>Alice</b>';
  aGrid.WideCells[2, 1] := 'Zazolc gesla jazn';
  aGrid.Cells[3, 1] := 'Hidden TMS column';
  aGrid.Cells[4, 1] := 'After hidden TMS column';
  aGrid.MergeCells(1, 2, 2, 1);
  aGrid.Cells[1, 2] := 'Merged TMS cell';
  aGrid.Cells[1, 3] := 'Hidden TMS row';
  aGrid.Cells[1, 4] := 'After hidden TMS row';
  aGrid.HideColumn(3);
  aGrid.HideRow(3);
  aGrid.Col := 2;
  aGrid.Row := 1;
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateScrollableAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'ScrollableAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(170), ScaleValue(82));
  aGrid.ColCount := 8;
  aGrid.RowCount := 8;
  aGrid.FixedCols := 1;
  aGrid.FixedRows := 1;
  aGrid.DefaultColWidth := ScaleValue(50);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(50);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.Cells[6, 6] := 'Scrolled TMS cell';
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateHiddenColumnMergedAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'HiddenColumnMergedAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(260), ScaleValue(95));
  aGrid.ColCount := 5;
  aGrid.RowCount := 3;
  aGrid.FixedCols := 0;
  aGrid.FixedRows := 0;
  aGrid.DefaultColWidth := ScaleValue(50);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(50);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.MergeCells(1, 1, 3, 1);
  aGrid.Cells[1, 1] := 'Merged visible columns';
  aGrid.HideColumn(2);
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateHiddenRowMergedAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'HiddenRowMergedAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(260), ScaleValue(120));
  aGrid.ColCount := 3;
  aGrid.RowCount := 5;
  aGrid.FixedCols := 0;
  aGrid.FixedRows := 0;
  aGrid.DefaultColWidth := ScaleValue(55);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(55);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.MergeCells(1, 1, 1, 3);
  aGrid.Cells[1, 1] := 'Merged visible rows';
  aGrid.HideRow(2);
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateHiddenBeforeMergedRowAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'HiddenBeforeMergedRowAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(260), ScaleValue(140));
  aGrid.ColCount := 3;
  aGrid.RowCount := 6;
  aGrid.FixedCols := 0;
  aGrid.FixedRows := 0;
  aGrid.DefaultColWidth := ScaleValue(55);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(55);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.MergeCells(1, 2, 1, 3);
  aGrid.Cells[1, 2] := 'Merged rows after hidden row';
  aGrid.HideRow(1);
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateHiddenBaseColumnMergedAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'HiddenBaseColumnMergedAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(260), ScaleValue(95));
  aGrid.ColCount := 5;
  aGrid.RowCount := 3;
  aGrid.FixedCols := 0;
  aGrid.FixedRows := 0;
  aGrid.DefaultColWidth := ScaleValue(50);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(50);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.MergeCells(1, 1, 3, 1);
  aGrid.Cells[1, 1] := '<b>Hidden column base text</b>';
  aGrid.HideColumn(1);
  aGrid.Col := 1;
  aGrid.Row := 1;
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateHiddenBaseRowMergedAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'HiddenBaseRowMergedAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(260), ScaleValue(120));
  aGrid.ColCount := 3;
  aGrid.RowCount := 5;
  aGrid.FixedCols := 0;
  aGrid.FixedRows := 0;
  aGrid.DefaultColWidth := ScaleValue(55);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(55);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.MergeCells(1, 2, 1, 3);
  aGrid.WideCells[1, 2] := 'Hidden row base wide text';
  aGrid.HideRow(0);
  aGrid.HideRow(2);
  aGrid.Col := 1;
  aGrid.Row := 1;
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

procedure CreateFullyHiddenMergedAdvGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
var
  lCol: Integer;
  lRow: Integer;
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'FullyHiddenMergedAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(260), ScaleValue(120));
  aGrid.ColCount := 5;
  aGrid.RowCount := 5;
  aGrid.FixedCols := 0;
  aGrid.FixedRows := 0;
  aGrid.DefaultColWidth := ScaleValue(50);
  aGrid.DefaultRowHeight := ScaleValue(22);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    aGrid.ColWidths[lCol] := ScaleValue(50);
  end;

  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    aGrid.RowHeights[lRow] := ScaleValue(22);
  end;

  aGrid.MergeCells(1, 1, 2, 2);
  aGrid.Cells[1, 1] := 'Fully hidden merge text';
  aGrid.HideColumn(1);
  aGrid.HideColumn(2);
  aGrid.HideRow(1);
  aGrid.HideRow(2);
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

function TmsRegistry: IAccessibilityAdapterRegistry;
begin
  Result := TAccessibilityTmsAdvStringGridAdapters.CreateRegistry;
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

function GridItemPattern(const aProvider: IRawElementProviderSimple): IGridItemProvider;
var
  lPattern: IUnknown;
begin
  lPattern := nil;
  Assert.AreEqual(S_OK, aProvider.GetPatternProvider(UIA_GridItemPatternId, lPattern));
  Assert.IsTrue(Supports(lPattern, IGridItemProvider, Result));
end;

function ProviderStringProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := string(lValue);
end;

function AdvCellIsVisible(aGrid: TAdvStringGrid; aCol: Integer; aRow: Integer): Boolean;
var
  lCellRect: TRect;
  lBaseCell: TPoint;
  lExpectedCell: TPoint;
  lHitCell: TPoint;
  lHitCol: Integer;
  lHitPoint: TPoint;
  lHitRow: Integer;
  lRealCell: TPoint;
  lRealHitCell: TPoint;
  lVisibleRect: TRect;
begin
  lRealCell := Point(aGrid.RealColIndex(aCol), aRow);
  if aGrid.IsHiddenColumn(lRealCell.X) or aGrid.IsHiddenRow(aGrid.RealRowIndex(aRow)) or
    aGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
  begin
    Exit(False);
  end;

  lCellRect := aGrid.CellRect(aCol, aRow);
  if not ((lCellRect.Width > 0) and (lCellRect.Height > 0) and
    IntersectRect(lVisibleRect, lCellRect, Rect(0, 0, aGrid.ClientWidth, aGrid.ClientHeight)) and
    (lVisibleRect.Width > 0) and (lVisibleRect.Height > 0)) then
  begin
    Exit(False);
  end;

  lHitPoint := Point((lVisibleRect.Left + lVisibleRect.Right) div 2,
    (lVisibleRect.Top + lVisibleRect.Bottom) div 2);
  lHitPoint := aGrid.ClientToScreen(lHitPoint);
  aGrid.ScreenToCell(lHitPoint, lHitCol, lHitRow);
  lExpectedCell := Point(aCol, aRow);
  lHitCell := Point(lHitCol, lHitRow);
  if (lHitCol >= 0) and (lHitCol < aGrid.ColCount) and (lHitRow >= 0) and (lHitRow < aGrid.RowCount) then
  begin
    lRealHitCell := Point(aGrid.RealColIndex(lHitCol), lHitRow);
    if aGrid.IsMergedNonBaseCell(lRealHitCell.X, lRealHitCell.Y) then
    begin
      lBaseCell := aGrid.BaseCell(lRealHitCell.X, lRealHitCell.Y);
      lHitCell := Point(aGrid.DisplColIndex(lBaseCell.X), lBaseCell.Y);
    end;
  end;

  Result := (lHitCell.X = lExpectedCell.X) and (lHitCell.Y = lExpectedCell.Y);
end;

function VisibleAdvCellCount(aGrid: TAdvStringGrid): Integer;
var
  lCol: Integer;
  lRow: Integer;
begin
  Result := 0;
  for lRow := 0 to Pred(aGrid.RowCount) do
  begin
    for lCol := 0 to Pred(aGrid.ColCount) do
    begin
      if AdvCellIsVisible(aGrid, lCol, lRow) then
      begin
        Inc(Result);
      end;
    end;
  end;
end;

function AdvCellDebug(aGrid: TAdvStringGrid; aCol: Integer; aRow: Integer): string;
var
  lCellRect: TRect;
  lHitCol: Integer;
  lHitPoint: TPoint;
  lHitRow: Integer;
  lVisibleRect: TRect;
begin
  lCellRect := aGrid.CellRect(aCol, aRow);
  if IntersectRect(lVisibleRect, lCellRect, Rect(0, 0, aGrid.ClientWidth, aGrid.ClientHeight)) and
    (lVisibleRect.Width > 0) and (lVisibleRect.Height > 0) then
  begin
    lHitPoint := Point((lVisibleRect.Left + lVisibleRect.Right) div 2,
      (lVisibleRect.Top + lVisibleRect.Bottom) div 2);
    lHitPoint := aGrid.ClientToScreen(lHitPoint);
    aGrid.ScreenToCell(lHitPoint, lHitCol, lHitRow);
  end else begin
    lHitCol := -1;
    lHitRow := -1;
  end;

  Result := Format('CellRect=(%d,%d,%d,%d), Client=%dx%d, LeftCol=%d, TopRow=%d, Hit=%d:%d',
    [lCellRect.Left, lCellRect.Top, lCellRect.Right, lCellRect.Bottom, aGrid.ClientWidth, aGrid.ClientHeight,
    aGrid.LeftCol, aGrid.TopRow, lHitCol, lHitRow]);
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

function ScreenAdvCellCenter(aGrid: TAdvStringGrid; aCol: Integer; aRow: Integer): TPoint;
var
  lCellRect: TRect;
  lVisibleRect: TRect;
begin
  lCellRect := aGrid.CellRect(aCol, aRow);
  Assert.IsTrue(IntersectRect(lVisibleRect, lCellRect, Rect(0, 0, aGrid.ClientWidth, aGrid.ClientHeight)) and
    (lVisibleRect.Width > 0) and (lVisibleRect.Height > 0));
  Result := aGrid.ClientToScreen(Point((lVisibleRect.Left + lVisibleRect.Right) div 2,
    (lVisibleRect.Top + lVisibleRect.Bottom) div 2));
end;

function SelectedFragment(const aGridFragment: IRawElementProviderFragment): IRawElementProviderFragment;
var
  lPattern: IUnknown;
  lSelectedSimple: IRawElementProviderSimple;
  lSelectedUnknown: IUnknown;
  lSelection: PSafeArray;
  lSelectionIndex: LongInt;
  lSelectionProvider: ISelectionProvider;
begin
  Result := nil;
  lPattern := ProviderPattern(aGridFragment, UIA_SelectionPatternId);
  Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelectionProvider));
  lSelection := nil;
  Assert.AreEqual(S_OK, lSelectionProvider.GetSelection(lSelection));
  try
    Assert.IsNotNull(lSelection);
    lSelectionIndex := 0;
    Assert.AreEqual(S_OK, SafeArrayGetElement(lSelection, lSelectionIndex, lSelectedUnknown));
    Assert.IsTrue(Supports(lSelectedUnknown, IRawElementProviderSimple, lSelectedSimple));
    Result := FragmentFromSimple(lSelectedSimple);
  finally
    if lSelection <> nil then
    begin
      SafeArrayDestroy(lSelection);
    end;
  end;
end;

function SameProvider(const aLeft: IInterface; const aRight: IInterface): Boolean;
var
  lLeftUnknown: IUnknown;
  lRightUnknown: IUnknown;
begin
  Result := Supports(aLeft, IUnknown, lLeftUnknown) and Supports(aRight, IUnknown, lRightUnknown) and
    (Pointer(lLeftUnknown) = Pointer(lRightUnknown));
end;

procedure TAdvStringGridAccessibilityTests.DefaultVclRegistryDoesNotApplyTmsSpecificTextHandling;
var
  lCellFragment: IRawElementProviderFragment;
  lCellSimple: IRawElementProviderSimple;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
begin
  CreateAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    Assert.AreEqual(UIA_DataGridControlTypeId, ProviderIntProperty(lGridFragment, UIA_ControlTypePropertyId));
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));
    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lCellSimple));
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('<b>Alice</b>', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderColumnSpanCountsOnlyVisibleMergedColumns;
var
  lColumnSpan: Integer;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridItem: IGridItemProvider;
  lGridPattern: IGridProvider;
  lMergedSimple: IRawElementProviderSimple;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRowSpan: Integer;
begin
  CreateHiddenColumnMergedAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lMergedSimple));
    Assert.IsNotNull(lMergedSimple);
    lGridItem := GridItemPattern(lMergedSimple);

    Assert.AreEqual(S_OK, lGridItem.Get_ColumnSpan(lColumnSpan));
    Assert.AreEqual(2, lColumnSpan);
    Assert.AreEqual(S_OK, lGridItem.Get_RowSpan(lRowSpan));
    Assert.AreEqual(1, lRowSpan);
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderExposesDataGridPatternsAndCellText;
var
  lCellFragment: IRawElementProviderFragment;
  lCellSimple: IRawElementProviderSimple;
  lColumnSpan: Integer;
  lColumnCount: Integer;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridItem: IGridItemProvider;
  lGridPattern: IGridProvider;
  lMergedSimple: IRawElementProviderSimple;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRowSpan: Integer;
  lRowCount: Integer;
begin
  CreateAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    Assert.AreEqual(UIA_DataGridControlTypeId, ProviderIntProperty(lGridFragment, UIA_ControlTypePropertyId));
    Assert.AreEqual('AdvOrdersGrid', ProviderStringProperty(lGridFragment, UIA_NamePropertyId));
    Assert.AreEqual(TAdvStringGrid.ClassName, ProviderStringProperty(lGridFragment, UIA_ClassNamePropertyId));

    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));
    Assert.AreEqual(S_OK, lGridPattern.Get_RowCount(lRowCount));
    Assert.AreEqual(lGrid.RowCount, lRowCount);
    Assert.AreEqual(S_OK, lGridPattern.Get_ColumnCount(lColumnCount));
    Assert.AreEqual(lGrid.ColCount, lColumnCount);
    Assert.IsNotNull(ProviderPattern(lGridFragment, UIA_SelectionPatternId));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lCellSimple));
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('Alice', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));
    Assert.AreEqual(UIA_DataItemControlTypeId, ProviderIntProperty(lCellFragment, UIA_ControlTypePropertyId));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 2, lCellSimple));
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('Zazolc gesla jazn', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 3, lCellSimple));
    Assert.AreEqual('After hidden TMS column',
      ProviderStringProperty(FragmentFromSimple(lCellSimple), UIA_NamePropertyId));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(3, 1, lCellSimple));
    Assert.AreEqual('After hidden TMS row', ProviderStringProperty(FragmentFromSimple(lCellSimple),
      UIA_NamePropertyId));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(2, 2, lMergedSimple));
    Assert.AreEqual('Merged TMS cell', ProviderStringProperty(FragmentFromSimple(lMergedSimple), UIA_NamePropertyId));
    lGridItem := GridItemPattern(lMergedSimple);
    Assert.AreEqual(S_OK, lGridItem.Get_ColumnSpan(lColumnSpan));
    Assert.AreEqual(2, lColumnSpan);
    Assert.AreEqual(S_OK, lGridItem.Get_RowSpan(lRowSpan));
    Assert.AreEqual(1, lRowSpan);
    Assert.AreEqual(VisibleAdvCellCount(lGrid), ChildFragmentCount(lGridFragment));
    Assert.IsTrue(ChildNameExists(lGridFragment, 'Merged TMS cell'));
    Assert.IsFalse(ChildNameExists(lGridFragment, 'Hidden TMS column'));
    Assert.IsTrue(ChildNameExists(lGridFragment, 'After hidden TMS column'));
    Assert.IsFalse(ChildNameExists(lGridFragment, 'Hidden TMS row'));
    Assert.IsTrue(ChildNameExists(lGridFragment, 'After hidden TMS row'));
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderSelectionReturnsCurrentCell;
var
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lSelectedFragment: IRawElementProviderFragment;
  lSelectedSimple: IRawElementProviderSimple;
  lSelectedUnknown: IUnknown;
  lSelection: PSafeArray;
  lSelectionIndex: LongInt;
  lSelectionProvider: ISelectionProvider;
begin
  CreateAdvGridFixture(lForm, lGrid);
  try
    lGrid.Col := 1;
    lGrid.Row := 1;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_SelectionPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelectionProvider));

    lSelection := nil;
    Assert.AreEqual(S_OK, lSelectionProvider.GetSelection(lSelection));
    try
      Assert.IsNotNull(lSelection);
      lSelectionIndex := 0;
      Assert.AreEqual(S_OK, SafeArrayGetElement(lSelection, lSelectionIndex, lSelectedUnknown));
      Assert.IsTrue(Supports(lSelectedUnknown, IRawElementProviderSimple, lSelectedSimple));
      lSelectedFragment := FragmentFromSimple(lSelectedSimple);
      Assert.AreEqual('Alice', ProviderStringProperty(lSelectedFragment, UIA_NamePropertyId));
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

procedure TAdvStringGridAccessibilityTests.OptInProviderGridPatternGetItemReturnsValidOffscreenCells;
var
  lCellFragment: IRawElementProviderFragment;
  lCellSimple: IRawElementProviderSimple;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
begin
  CreateScrollableAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(6, 6, lCellSimple));
    Assert.IsNotNull(lCellSimple);
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('Scrolled TMS cell', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));
    Assert.AreEqual(UIA_DataItemControlTypeId, ProviderIntProperty(lCellFragment, UIA_ControlTypePropertyId));
    Assert.AreEqual(VisibleAdvCellCount(lGrid), ChildFragmentCount(lGridFragment));
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderRowSpanCountsOnlyVisibleMergedRows;
var
  lColumnSpan: Integer;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridItem: IGridItemProvider;
  lGridPattern: IGridProvider;
  lMergedSimple: IRawElementProviderSimple;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRowSpan: Integer;
begin
  CreateHiddenRowMergedAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lMergedSimple));
    Assert.IsNotNull(lMergedSimple);
    lGridItem := GridItemPattern(lMergedSimple);

    Assert.AreEqual(S_OK, lGridItem.Get_RowSpan(lRowSpan));
    Assert.AreEqual(2, lRowSpan);
    Assert.AreEqual(S_OK, lGridItem.Get_ColumnSpan(lColumnSpan));
    Assert.AreEqual(1, lColumnSpan);
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderRowSpanIgnoresHiddenRowsBeforeMerge;
var
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridItem: IGridItemProvider;
  lGridPattern: IGridProvider;
  lMergedSimple: IRawElementProviderSimple;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRowSpan: Integer;
begin
  CreateHiddenBeforeMergedRowAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lMergedSimple));
    Assert.IsNotNull(lMergedSimple);
    lGridItem := GridItemPattern(lMergedSimple);

    Assert.AreEqual(S_OK, lGridItem.Get_RowSpan(lRowSpan));
    Assert.AreEqual(3, lRowSpan);
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderUsesVisibleRepresentativeForHiddenMergeBaseColumn;
var
  lCellFragment: IRawElementProviderFragment;
  lCellSimple: IRawElementProviderSimple;
  lColumn: Integer;
  lColumnSpan: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridItem: IGridItemProvider;
  lGridPattern: IGridProvider;
  lHit: IRawElementProviderFragment;
  lPattern: IUnknown;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lRow: Integer;
  lRowSpan: Integer;
  lSelected: IRawElementProviderFragment;
begin
  CreateHiddenBaseColumnMergedAdvGridFixture(lForm, lGrid);
  try
    lForm.ActiveControl := lGrid;
    lGrid.Col := 1;
    lGrid.Row := 1;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lRoot := FragmentRoot(lProvider);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lCellSimple));
    Assert.IsNotNull(lCellSimple);
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('Hidden column base text', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));
    lGridItem := GridItemPattern(lCellSimple);
    Assert.AreEqual(S_OK, lGridItem.Get_Column(lColumn));
    Assert.AreEqual(1, lColumn);
    Assert.AreEqual(S_OK, lGridItem.Get_Row(lRow));
    Assert.AreEqual(1, lRow);
    Assert.AreEqual(S_OK, lGridItem.Get_ColumnSpan(lColumnSpan));
    Assert.AreEqual(2, lColumnSpan);
    Assert.AreEqual(S_OK, lGridItem.Get_RowSpan(lRowSpan));
    Assert.AreEqual(1, lRowSpan);

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    Assert.IsTrue(SameProvider(lCellFragment, lFocus), 'Focus should resolve to the column representative.');
    lSelected := SelectedFragment(lGridFragment);
    Assert.IsTrue(SameProvider(lCellFragment, lSelected), 'Selection should resolve to the column representative.');
    lPoint := ScreenAdvCellCenter(lGrid, 1, 1);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.IsTrue(SameProvider(lCellFragment, lHit), 'Hit testing should resolve to the column representative.');
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderUsesVisibleRepresentativeForHiddenMergeBaseRow;
var
  lCellFragment: IRawElementProviderFragment;
  lCellSimple: IRawElementProviderSimple;
  lColumn: Integer;
  lColumnSpan: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridItem: IGridItemProvider;
  lGridPattern: IGridProvider;
  lHit: IRawElementProviderFragment;
  lPattern: IUnknown;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lRow: Integer;
  lRowSpan: Integer;
  lSelected: IRawElementProviderFragment;
begin
  CreateHiddenBaseRowMergedAdvGridFixture(lForm, lGrid);
  try
    lForm.ActiveControl := lGrid;
    lGrid.Col := 1;
    lGrid.Row := 1;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lRoot := FragmentRoot(lProvider);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);
    lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));

    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lCellSimple));
    Assert.IsNotNull(lCellSimple);
    lCellFragment := FragmentFromSimple(lCellSimple);
    Assert.AreEqual('Hidden row base wide text', ProviderStringProperty(lCellFragment, UIA_NamePropertyId));
    lGridItem := GridItemPattern(lCellSimple);
    Assert.AreEqual(S_OK, lGridItem.Get_Column(lColumn));
    Assert.AreEqual(1, lColumn);
    Assert.AreEqual(S_OK, lGridItem.Get_Row(lRow));
    Assert.AreEqual(1, lRow);
    Assert.AreEqual(S_OK, lGridItem.Get_ColumnSpan(lColumnSpan));
    Assert.AreEqual(1, lColumnSpan);
    Assert.AreEqual(S_OK, lGridItem.Get_RowSpan(lRowSpan));
    Assert.AreEqual(2, lRowSpan);

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    lGridItem := GridItemPattern(SimpleProvider(lFocus));
    Assert.AreEqual(S_OK, lGridItem.Get_Column(lColumn));
    Assert.AreEqual(S_OK, lGridItem.Get_Row(lRow));
    Assert.AreEqual(1, lColumn, 'Focus should expose the representative column.');
    Assert.AreEqual(1, lRow, 'Focus should expose the representative row.');
    Assert.IsTrue(SameProvider(lCellFragment, lFocus), 'Focus should resolve to the row representative.');
    lSelected := SelectedFragment(lGridFragment);
    Assert.IsTrue(SameProvider(lCellFragment, lSelected), 'Selection should resolve to the row representative.');
    lPoint := ScreenAdvCellCenter(lGrid, 1, 1);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.IsTrue(SameProvider(lCellFragment, lHit), 'Hit testing should resolve to the row representative.');
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderOmitsFullyHiddenMerge;
var
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
begin
  CreateFullyHiddenMergedAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    Assert.IsFalse(ChildNameExists(lGridFragment, 'Fully hidden merge text'));
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderFindsScrolledCellsAndPrunesStaleChildren;
var
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateScrollableAdvGridFixture(lForm, lGrid);
  try
    Assert.IsFalse(AdvCellIsVisible(lGrid, 6, 6),
      'Scrolled cell should start outside the visible viewport. ' + AdvCellDebug(lGrid, 6, 6));
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lRoot := FragmentRoot(lProvider);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    lGrid.ScrollInView(6, 6);
    Assert.IsTrue(AdvCellIsVisible(lGrid, 6, 6), 'Scrolled cell should become visible after ScrollInView.');
    lPoint := ScreenAdvCellCenter(lGrid, 6, 6);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Scrolled TMS cell', ProviderStringProperty(lHit, UIA_NamePropertyId));

    lGrid.ScrollInView(1, 1);
    Assert.IsFalse(AdvCellIsVisible(lGrid, 6, 6), 'Scrolled cell should leave the visible viewport after scrolling away.');
    Assert.AreEqual(VisibleAdvCellCount(lGrid), ChildFragmentCount(lGridFragment));
    Assert.IsFalse(ChildNameExists(lGridFragment, 'Scrolled TMS cell'),
      'Scrolled-out cell should be pruned from child navigation.');
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderPrunesScrolledCellsWithoutUiaDisconnect;
var
  lBounds: UiaRect;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lUiaApi: IAdvStringGridTestUiaApi;
begin
  CreateScrollableAdvGridFixture(lForm, lGrid);
  try
    lUiaApi := TAdvStringGridTestUiaApi.Create;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry, lUiaApi);
    lRoot := FragmentRoot(lProvider);
    lGridFragment := FirstChildFragment(lProvider.FragmentProvider);

    lGrid.ScrollInView(6, 6);
    lPoint := ScreenAdvCellCenter(lGrid, 6, 6);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Scrolled TMS cell', ProviderStringProperty(lHit, UIA_NamePropertyId));

    lGrid.ScrollInView(1, 1);
    Assert.AreEqual(VisibleAdvCellCount(lGrid), ChildFragmentCount(lGridFragment));
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lHit.Get_BoundingRectangle(lBounds),
      'Retained stale cell provider should report unavailable after it is pruned.');
    Assert.AreEqual(0, lUiaApi.DisconnectCalls,
      'Transient grid cell pruning should not call UIA disconnect for providers not handed to UIA.');
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderFocusReturnsTheCurrentCell;
var
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateAdvGridFixture(lForm, lGrid);
  try
    lForm.ActiveControl := lGrid;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lRoot := FragmentRoot(lProvider);

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    Assert.AreEqual('Zazolc gesla jazn', ProviderStringProperty(lFocus, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderHitTestingReturnsOnlyTheCellUnderThePointer;
var
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lRoot := FragmentRoot(lProvider);
    lPoint := ScreenAdvCellCenter(lGrid, 1, 1);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Alice', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.IsFalse(Pos('row', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) > 0);
    Assert.IsFalse(Pos('column', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) > 0);
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderHitTestingIgnoresPointsOutsideTheGrid;
var
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  CreateAdvGridFixture(lForm, lGrid);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lRoot := FragmentRoot(lProvider);
    lPoint := lForm.ClientToScreen(Point(lGrid.Left + lGrid.Width + ScaleValue(20),
      lGrid.Top + lGrid.Height + ScaleValue(20)));

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNull(lHit);
  finally
    lForm.Free;
  end;
end;

procedure TAdvStringGridAccessibilityTests.OptInProviderHitTestingIgnoresGridOnInactiveTab;
var
  lActiveTab: TTabSheet;
  lForm: TForm;
  lGrid: TAdvStringGrid;
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
    lGridTab.Caption := 'Hidden TMS grid';
    lGridTab.PageControl := lPageControl;

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Visible active tab label';
    lLabel.Parent := lActiveTab;
    lLabel.SetBounds(ScaleValue(30), ScaleValue(34), ScaleValue(180), ScaleValue(24));

    lGrid := TAdvStringGrid.Create(lForm);
    lGrid.Name := 'InactiveAdvGrid';
    lGrid.Parent := lGridTab;
    lGrid.SetBounds(ScaleValue(20), ScaleValue(20), ScaleValue(260), ScaleValue(130));
    lGrid.ColCount := 2;
    lGrid.RowCount := 2;
    lGrid.Cells[1, 1] := 'Hidden inactive TMS cell';

    lPageControl.ActivePage := lActiveTab;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TmsRegistry);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lLabel);

    Assert.IsFalse(lGrid.Showing, 'Inactive tab TMS grid must not be considered showing.');
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Visible active tab label', ProviderStringProperty(lHit, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAdvStringGridAccessibilityTests);

end.
