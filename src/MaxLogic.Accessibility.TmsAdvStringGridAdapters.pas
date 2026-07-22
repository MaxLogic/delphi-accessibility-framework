unit MaxLogic.Accessibility.TmsAdvStringGridAdapters;

interface

uses
  MaxLogic.Accessibility.Scanner;

type
  TAccessibilityTmsAdvStringGridAdapters = record
  public
    class function CreateRegistry: IAccessibilityAdapterRegistry; static;
    class procedure RegisterAdapters(const aRegistry: IAccessibilityAdapterRegistry); static;
  end;

implementation

uses
  System.Diagnostics, System.Generics.Collections, System.Math, System.SysUtils, System.Types, System.Variants,
  Winapi.ActiveX, Winapi.Windows, Vcl.ComCtrls, Vcl.Controls, Vcl.Forms, AdvGrid, AdvHTML,
  MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.UIAutomationCore,
  MaxLogic.Accessibility.VclAdapters;

type
  TAdvStringGridAdapter = class(TInterfacedObject, IAccessibilityControlAdapter, IAccessibilityVclProviderAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TAccessibilityAdvStringGridProvider = class;

  TAccessibilityAdvStringGridCellProvider = class(TAccessibilityProviderNode, IGridItemProvider,
    ISelectionItemProvider)
  private
    fCol: Integer;
    fGrid: TAdvStringGrid;
    fGridProvider: TAccessibilityAdvStringGridProvider;
    fRow: Integer;
    function CellText: string;
    function IsVisibleCell: Boolean;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aGridProvider: TAccessibilityAdvStringGridProvider; aGrid: TAdvStringGrid; aCol: Integer;
      aRow: Integer; const aRuntimeId: array of Integer; const aApi: IAccessibilityUiaApi);
    function AddToSelection: HResult; stdcall;
    function Get_Column(out aRetVal: Integer): HResult; stdcall;
    function Get_ColumnSpan(out aRetVal: Integer): HResult; stdcall;
    function Get_ContainingGrid(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_IsSelected(out aRetVal: BOOL): HResult; stdcall;
    function Get_Row(out aRetVal: Integer): HResult; stdcall;
    function Get_RowSpan(out aRetVal: Integer): HResult; stdcall;
    function Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function RemoveFromSelection: HResult; stdcall;
    function Select: HResult; stdcall;
  end;

  TAccessibilityAdvStringGridProvider = class(TAccessibilityProviderNode, IAccessibilityVclControlProviderInfo,
    IAccessibilityFocusedItemProvider, IRawElementProviderFragmentRoot, IGridProvider, ISelectionProvider)
  private
    fCells: TDictionary<Int64, IAccessibilityProviderNode>;
    fGrid: TAdvStringGrid;
    fHelpText: string;
    fLiveHelpText: Boolean;
    fLiveName: Boolean;
    fName: string;
    fPreparedClientHeight: Integer;
    fPreparedClientWidth: Integer;
    fPreparedColCount: Integer;
    fPreparedFixedCols: Integer;
    fPreparedFixedRows: Integer;
    fPreparedHandle: HWND;
    fPreparedLeftCol: Integer;
    fPreparedRowCount: Integer;
    fPreparedTopRow: Integer;
    fPreparedValid: Boolean;
    fPreparedVisibleColCount: Integer;
    fPreparedVisibleRowCount: Integer;
    fResolvedCurrentCell: TPoint;
    fResolvedCurrentColCount: Integer;
    fResolvedCurrentGridCol: Integer;
    fResolvedCurrentGridRow: Integer;
    fResolvedCurrentRowCount: Integer;
    fResolvedCurrentValid: Boolean;
    fProviderRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    function CellBelongsToMerge(aCol: Integer; aRow: Integer; const aBaseCell: TPoint): Boolean;
    function CellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function CellText(aCol: Integer; aRow: Integer): string;
    function ChildrenPreparationIsCurrent: Boolean;
    function CurrentProviderCell: TPoint;
    function CreateSelectionArray(const aProvider: IRawElementProviderSimple): PSafeArray;
    function EnsureCellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function EnsureCellProviderDirect(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    procedure EnsureVisibleCellProvider(aCol: Integer; aRow: Integer; aMetricsEnabled: Boolean;
      var aCellProbeCount: Integer; var aCreatedCount: Integer);
    function GridOwnsFocus: Boolean;
    function HitCell(const aPoint: TPoint; aCol: Integer; aRow: Integer): TPoint;
    function IsAccessibleCell(aCol: Integer; aRow: Integer): Boolean;
    function IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
    function MergeBaseCell(aCol: Integer; aRow: Integer): TPoint;
    function MergeBaseIsVisible(const aBaseCell: TPoint): Boolean;
    function MergeRepresentativeForMarker(aCol: Integer; aRow: Integer): TPoint;
    function NormalizedCell(aCol: Integer; aRow: Integer): TPoint;
    function PointHitsCell(const aPoint: TPoint; const aExpectedCell: TPoint): Boolean;
    function RealCell(aCol: Integer; aRow: Integer): TPoint;
    function VisibleCellRect(aCol: Integer; aRow: Integer; out aRect: TRect): Boolean;
    function VisibleColumnSpan(aCol: Integer; aRow: Integer): Integer;
    function VisibleRowSpan(aCol: Integer; aRow: Integer): Integer;
    procedure RefreshVisibleCells;
    procedure RememberChildrenPreparation;
  protected
    function CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean; override;
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create(aGrid: TAdvStringGrid; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    destructor Destroy; override;
    function Control: TControl;
    function ElementProviderFromPoint(aX: Double; aY: Double; out aRetVal: IRawElementProviderFragment):
      HResult; stdcall;
    function GetFocus(out aRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetItem(aRow: Integer; aColumn: Integer; out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_ColumnCount(out aRetVal: Integer): HResult; stdcall;
    function Get_CanSelectMultiple(out aRetVal: BOOL): HResult; stdcall;
    function Get_IsSelectionRequired(out aRetVal: BOOL): HResult; stdcall;
    function Get_RowCount(out aRetVal: Integer): HResult; stdcall;
    function GetSelection(out aRetVal: PSafeArray): HResult; stdcall;
    function TryGetFocusedItem(out aProvider: IRawElementProviderSimple; out aName: string): Boolean;
  end;

function CellKey(aCol: Integer; aRow: Integer): Int64;
begin
  Result := (Int64(aRow) shl 32) or Cardinal(aCol); //PALOFF WARN63 explicit row/column key packing
end;

function CellKeyCol(aKey: Int64): Integer;
begin
  Result := Integer(aKey and Int64($00000000FFFFFFFF));
end;

function CellKeyRow(aKey: Int64): Integer;
begin
  Result := Integer(aKey shr 32);
end;

function IsNonEmptyRect(const aRect: TRect): Boolean;
begin
  Result := (aRect.Width > 0) and (aRect.Height > 0);
end;

function ControlIsInActiveVisibleTree(aControl: TControl): Boolean;
var
  lControl: TControl;
  lTabSheet: TTabSheet;
begin
  TAccessibilityDiagnostics.RecordActiveVisibleTreeProbe;
  Result := False;
  lControl := aControl;
  while lControl <> nil do
  begin
    if not (lControl is TCustomForm) and not lControl.Visible then
    begin
      Exit;
    end;

    if lControl is TTabSheet then
    begin
      lTabSheet := TTabSheet(lControl);
      if (lTabSheet.PageControl <> nil) and (lTabSheet.PageControl.ActivePage <> lTabSheet) then
      begin
        Exit;
      end;
    end;

    lControl := lControl.Parent;
  end;

  Result := True;
end;

function WindowUnderPointMatchesControl(aControl: TControl; const aPoint: TPoint): Boolean;
var
  lControl: TWinControl;
  lWindow: TWinControl;
begin
  Result := True;
  if not (aControl is TWinControl) then
  begin
    Exit;
  end;

  lControl := TWinControl(aControl); //PALOFF STWA6 guarded by is TWinControl
  if not lControl.HandleAllocated or not IsWindowVisible(lControl.Handle) then
  begin
    Exit;
  end;

  lWindow := FindVCLWindow(aPoint);
  Result := (lWindow = lControl) or ((lWindow <> nil) and lControl.ContainsControl(lWindow));
end;

function TAdvStringGridAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if aControl is TAdvStringGrid then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TAdvStringGridAdapter.CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Result := TAccessibilityAdvStringGridProvider.Create(TAdvStringGrid(aControl), aRuntimeId, aName, aHelpText, //PALOFF STWA6 guarded by Supports
    aApi) as IAccessibilityProviderNode;
end;

function TAccessibilityAdvStringGridCellProvider.AddToSelection: HResult;
begin
  Result := Select;
end;

function TAccessibilityAdvStringGridCellProvider.CellText: string;
begin
  if fGridProvider = nil then
  begin
    Exit('');
  end;

  Result := fGridProvider.CellText(fCol, fRow);
end;

constructor TAccessibilityAdvStringGridCellProvider.Create(aGridProvider: TAccessibilityAdvStringGridProvider;
  aGrid: TAdvStringGrid; aCol: Integer; aRow: Integer; const aRuntimeId: array of Integer;
  const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, aGrid);
  fGridProvider := aGridProvider;
  fGrid := aGrid;
  fCol := aCol;
  fRow := aRow;
  SetProperty(UIA_ControlTypePropertyId, UIA_DataItemControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, 'TAdvStringGridCell');
  SetProperty(UIA_HelpTextPropertyId, '');
end;

function TAccessibilityAdvStringGridCellProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lCellRect: TRect;
  lTopLeft: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fGrid = nil) or IsDisconnected or not IsVisibleCell then
  begin
    Exit;
  end;

  if not fGridProvider.VisibleCellRect(fCol, fRow, lCellRect) then
  begin
    Exit;
  end;

  lTopLeft := fGrid.ClientToScreen(lCellRect.TopLeft);
  aValue.Left := lTopLeft.X;
  aValue.Top := lTopLeft.Y;
  aValue.Width := lCellRect.Width;
  aValue.Height := lCellRect.Height;
  Result := True;
end;

function TAccessibilityAdvStringGridCellProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Result := nil;
  if IsDisconnected then
  begin
    Exit;
  end;

  if aPatternId = UIA_GridItemPatternId then
  begin
    Exit(Self as IGridItemProvider);
  end;

  if aPatternId = UIA_SelectionItemPatternId then
  begin
    Exit(Self as ISelectionItemProvider);
  end;
end;

function TAccessibilityAdvStringGridCellProvider.DoGetPropertyValue(aPropertyId: PROPERTYID;
  out aValue: OleVariant): Boolean;
var
  lCurrentCell: TPoint;
begin
  Result := True;
  case aPropertyId of
    UIA_NamePropertyId:
      aValue := CellText;
    UIA_IsOffscreenPropertyId:
      aValue := not IsVisibleCell;
    UIA_HasKeyboardFocusPropertyId:
      begin
        if fGridProvider = nil then
        begin
          aValue := False;
        end else begin
          lCurrentCell := fGridProvider.CurrentProviderCell;
          aValue := fGridProvider.GridOwnsFocus and
            (lCurrentCell.X = fCol) and (lCurrentCell.Y = fRow);
        end;
      end;
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TAccessibilityAdvStringGridCellProvider.Get_Column(out aRetVal: Integer): HResult;
begin
  aRetVal := fCol;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridCellProvider.Get_ColumnSpan(out aRetVal: Integer): HResult;
begin
  aRetVal := 1;
  if IsDisconnected or (fGrid = nil) or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGridProvider.VisibleColumnSpan(fCol, fRow);
  Result := S_OK;
end;

function TAccessibilityAdvStringGridCellProvider.Get_ContainingGrid(out aRetVal: IRawElementProviderSimple):
  HResult;
begin
  aRetVal := nil;
  if IsDisconnected or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGridProvider.RawElementProvider;
  Result := S_OK;
end;

function TAccessibilityAdvStringGridCellProvider.Get_IsSelected(out aRetVal: BOOL): HResult;
var
  lCurrentCell: TPoint;
begin
  aRetVal := False;
  if IsDisconnected or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lCurrentCell := fGridProvider.CurrentProviderCell;
  if (lCurrentCell.X = fCol) and (lCurrentCell.Y = fRow) then
  begin
    aRetVal := True;
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridCellProvider.Get_Row(out aRetVal: Integer): HResult;
begin
  aRetVal := fRow;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridCellProvider.Get_RowSpan(out aRetVal: Integer): HResult;
begin
  aRetVal := 1;
  if IsDisconnected or (fGrid = nil) or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGridProvider.VisibleRowSpan(fCol, fRow);
  Result := S_OK;
end;

function TAccessibilityAdvStringGridCellProvider.Get_SelectionContainer(out aRetVal: IRawElementProviderSimple):
  HResult;
begin
  Result := Get_ContainingGrid(aRetVal);
end;

function TAccessibilityAdvStringGridCellProvider.IsVisibleCell: Boolean;
begin
  Result := (fGridProvider <> nil) and fGridProvider.IsVisibleCell(fCol, fRow);
end;

function TAccessibilityAdvStringGridCellProvider.RemoveFromSelection: HResult;
begin
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := E_NOTIMPL;
end;

function TAccessibilityAdvStringGridCellProvider.Select: HResult;
begin
  if IsDisconnected or (fGrid = nil) or not IsVisibleCell then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  fGrid.GotoCell(fCol, fRow);
  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.CellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
begin
  if not fCells.TryGetValue(CellKey(aCol, aRow), Result) then
  begin
    Result := nil;
  end else if Result.IsDisconnected then
  begin
    Result := nil;
  end;
end;

function TAccessibilityAdvStringGridProvider.CellBelongsToMerge(aCol: Integer; aRow: Integer;
  const aBaseCell: TPoint): Boolean;
var
  lCandidateBase: TPoint;
  lMarkerCell: TPoint;
  lRealCell: TPoint;
begin
  Result := False;
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  if fGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
  begin
    lMarkerCell := fGrid.BaseCell(lRealCell.X, lRealCell.Y);
    lCandidateBase := Point(lMarkerCell.X, fGrid.RealRowIndex(aRow) - (aRow - lMarkerCell.Y));
  end else begin
    lCandidateBase := Point(lRealCell.X, fGrid.RealRowIndex(aRow));
  end;

  Result := (lCandidateBase.X = aBaseCell.X) and (lCandidateBase.Y = aBaseCell.Y);
end;

function TAccessibilityAdvStringGridProvider.CellText(aCol: Integer; aRow: Integer): string;
var
  lBaseCell: TPoint;
  lDisplayRow: Integer;
begin
  Result := '';
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lBaseCell := MergeBaseCell(aCol, aRow);
  lDisplayRow := fGrid.DisplRowIndex(lBaseCell.Y);
  if fGrid.IsHiddenColumn(lBaseCell.X) or fGrid.IsHiddenRow(lBaseCell.Y) then
  begin
    Result := Trim(AdvHTML.HTMLStrip(string(fGrid.AllCells[lBaseCell.X, lBaseCell.Y])));
  end else begin
    Result := Trim(string(fGrid.StrippedCells[lBaseCell.X, lDisplayRow]));
  end;

  if Result = '' then
  begin
    Result := Trim(string(fGrid.AllWideCells[lBaseCell.X, lBaseCell.Y]));
  end;
end;

constructor TAccessibilityAdvStringGridProvider.Create(aGrid: TAdvStringGrid; aRuntimeId: Integer;
  const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
var
  lTextInfo: TAccessibilityTextInfo;
begin
  inherited CreateNode([aRuntimeId], aGrid.Handle, aApi, aGrid);
  SetPublishNativeWindowHandle(True);
  fCells := TDictionary<Int64, IAccessibilityProviderNode>.Create;
  fGrid := aGrid;
  fHelpText := aHelpText;
  fName := aName;
  lTextInfo := TAccessibilityTextExtractor.Extract(aGrid);
  fLiveHelpText := SameText(fHelpText, lTextInfo.HelpText);
  fLiveName := SameText(fName, lTextInfo.Name);
  fProviderRuntimeId := aRuntimeId;
  fUiaApi := aApi;
  SetProperty(UIA_ControlTypePropertyId, UIA_DataGridControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aGrid.ClassName);
  RefreshVisibleCells;
  RememberChildrenPreparation;
end;

function TAccessibilityAdvStringGridProvider.CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode):
  Boolean;
begin
  Result := ChildrenPreparationIsCurrent and HasCurrentChildIndex(aChild);
end;

function TAccessibilityAdvStringGridProvider.ChildrenPreparationIsCurrent: Boolean;
begin
  Result := False;
  if (fGrid = nil) or (not fPreparedValid) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) then
  begin
    Exit;
  end;

  Result := (fPreparedHandle = fGrid.Handle) and (fPreparedClientWidth = fGrid.ClientWidth) and
    (fPreparedClientHeight = fGrid.ClientHeight) and (fPreparedColCount = fGrid.ColCount) and
    (fPreparedRowCount = fGrid.RowCount) and (fPreparedFixedCols = fGrid.FixedCols) and
    (fPreparedFixedRows = fGrid.FixedRows) and (fPreparedLeftCol = fGrid.LeftCol) and
    (fPreparedTopRow = fGrid.TopRow) and (fPreparedVisibleColCount = fGrid.VisibleColCount) and
    (fPreparedVisibleRowCount = fGrid.VisibleRowCount);
end;

function TAccessibilityAdvStringGridProvider.CreateSelectionArray(
  const aProvider: IRawElementProviderSimple): PSafeArray;
var
  lData: Pointer;
  lUnknown: IUnknown;
begin
  if aProvider = nil then
  begin
    Exit(SafeArrayCreateVector(VT_UNKNOWN, 0, 0));
  end;

  Result := SafeArrayCreateVector(VT_UNKNOWN, 0, 1);
  if Result = nil then
  begin
    Exit;
  end;

  lUnknown := aProvider as IUnknown;
  lData := nil;
  if (SafeArrayAccessData(Result, lData) <> S_OK) or (lData = nil) then
  begin
    SafeArrayDestroy(Result);
    Result := nil;
    Exit;
  end;

  try
    PPointer(lData)^ := Pointer(lUnknown);
    lUnknown._AddRef;
  finally
    SafeArrayUnaccessData(Result);
  end;
end;

function TAccessibilityAdvStringGridProvider.CurrentProviderCell: TPoint;
var
  lRealCell: TPoint;
  lRepresentative: TPoint;
begin
  Result := Point(-1, -1);
  if fGrid = nil then
  begin
    Exit;
  end;

  if fResolvedCurrentValid and (fResolvedCurrentGridCol = fGrid.Col) and
    (fResolvedCurrentGridRow = fGrid.Row) and (fResolvedCurrentColCount = fGrid.ColCount) and
    (fResolvedCurrentRowCount = fGrid.RowCount) then
  begin
    Exit(fResolvedCurrentCell);
  end;

  Result := NormalizedCell(fGrid.Col, fGrid.Row);
  lRealCell := RealCell(fGrid.Col, fGrid.Row);
  if not fGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
  begin
    lRepresentative := MergeRepresentativeForMarker(fGrid.Col, fGrid.Row);
    if (lRepresentative.X >= 0) and (lRepresentative.Y >= 0) then
    begin
      Result := lRepresentative;
    end;
  end;

  fResolvedCurrentCell := Result;
  fResolvedCurrentColCount := fGrid.ColCount;
  fResolvedCurrentGridCol := fGrid.Col;
  fResolvedCurrentGridRow := fGrid.Row;
  fResolvedCurrentRowCount := fGrid.RowCount;
  fResolvedCurrentValid := True;
end;

destructor TAccessibilityAdvStringGridProvider.Destroy;
begin
  fCells.Free;
  inherited Destroy;
end;

function TAccessibilityAdvStringGridProvider.Control: TControl;
begin
  Result := fGrid;
end;

function TAccessibilityAdvStringGridProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lTopLeft: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fGrid = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) then
  begin
    Exit;
  end;

  lTopLeft := fGrid.ClientToScreen(Point(0, 0));
  aValue.Left := lTopLeft.X;
  aValue.Top := lTopLeft.Y;
  aValue.Width := fGrid.Width;
  aValue.Height := fGrid.Height;
  Result := True;
end;

function TAccessibilityAdvStringGridProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Result := nil;
  if IsDisconnected then
  begin
    Exit;
  end;

  if aPatternId = UIA_GridPatternId then
  begin
    Exit(Self as IGridProvider);
  end;

  if aPatternId = UIA_SelectionPatternId then
  begin
    Exit(Self as ISelectionProvider);
  end;
end;

function TAccessibilityAdvStringGridProvider.DoGetPropertyValue(aPropertyId: PROPERTYID;
  out aValue: OleVariant): Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_HelpTextPropertyId:
      if fLiveHelpText then
      begin
        aValue := TAccessibilityTextExtractor.Extract(fGrid).HelpText;
      end else begin
        aValue := fHelpText;
      end;
    UIA_HasKeyboardFocusPropertyId:
      aValue := GridOwnsFocus;
    UIA_IsEnabledPropertyId:
      aValue := fGrid.Enabled;
    UIA_IsKeyboardFocusablePropertyId:
      aValue := fGrid.TabStop;
    UIA_IsOffscreenPropertyId:
      aValue := not ControlIsInActiveVisibleTree(fGrid);
    UIA_NamePropertyId:
      if fLiveName then
      begin
        aValue := TAccessibilityTextExtractor.Extract(fGrid).Name;
      end else begin
        aValue := fName;
      end;
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TAccessibilityAdvStringGridProvider.ElementProviderFromPoint(aX: Double; aY: Double;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lCell: IAccessibilityProviderNode;
  lCol: Integer;
  lClientPoint: TPoint;
  lPoint: TPoint;
  lRow: Integer;
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lPoint := Point(Integer(Round(aX)), Integer(Round(aY)));
  lClientPoint := fGrid.ScreenToClient(lPoint);
  if not ControlIsInActiveVisibleTree(fGrid) or not WindowUnderPointMatchesControl(fGrid, lPoint) then
  begin
    Exit(S_OK);
  end;

  if not PtInRect(Rect(0, 0, fGrid.ClientWidth, fGrid.ClientHeight), lClientPoint) then
  begin
    Exit(S_OK);
  end;

  fGrid.ScreenToCell(lPoint, lCol, lRow);
  lClientPoint := HitCell(lClientPoint, lCol, lRow);
  lCol := lClientPoint.X;
  lRow := lClientPoint.Y;
  lCell := EnsureCellProvider(lCol, lRow);
  if lCell <> nil then
  begin
    aRetVal := lCell.FragmentProvider;
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.EnsureCellProvider(aCol: Integer; aRow: Integer):
  IAccessibilityProviderNode;
var
  lCell: TPoint;
begin
  if (fGrid <> nil) and ChildrenPreparationIsCurrent then
  begin
    lCell := NormalizedCell(aCol, aRow);
    Result := CellProvider(lCell.X, lCell.Y);
    if Result <> nil then
    begin
      Exit;
    end;
  end;

  RefreshVisibleCells;
  fPreparedValid := False;
  Result := EnsureCellProviderDirect(aCol, aRow);
end;

function TAccessibilityAdvStringGridProvider.EnsureCellProviderDirect(aCol: Integer; aRow: Integer):
  IAccessibilityProviderNode;
var
  lCell: TPoint;
  lKey: Int64;
begin
  lCell := NormalizedCell(aCol, aRow);
  lKey := CellKey(lCell.X, lCell.Y);
  Result := CellProvider(lCell.X, lCell.Y);
  if Result = nil then
  begin
    fCells.Remove(lKey);
  end;

  if (Result = nil) and IsAccessibleCell(lCell.X, lCell.Y) then
  begin
    Result := TAccessibilityAdvStringGridCellProvider.Create(Self, fGrid, lCell.X, lCell.Y,
      [fProviderRuntimeId, lCell.Y, lCell.X], fUiaApi) as IAccessibilityProviderNode;
    AddChild(Result);
    fCells.Add(lKey, Result);
  end;
end;

procedure TAccessibilityAdvStringGridProvider.EnsureVisibleCellProvider(aCol: Integer; aRow: Integer;
  aMetricsEnabled: Boolean; var aCellProbeCount: Integer; var aCreatedCount: Integer);
var
  lCell: IAccessibilityProviderNode;
  lCellRect: TRect;
begin
  if aMetricsEnabled then
  begin
    Inc(aCellProbeCount);
  end;

  if VisibleCellRect(aCol, aRow, lCellRect) and (CellProvider(aCol, aRow) = nil) then
  begin
    lCell := TAccessibilityAdvStringGridCellProvider.Create(Self, fGrid, aCol, aRow,
      [fProviderRuntimeId, aRow, aCol], fUiaApi) as IAccessibilityProviderNode;
    AddChild(lCell);
    fCells.Add(CellKey(aCol, aRow), lCell);
    if aMetricsEnabled then
    begin
      Inc(aCreatedCount);
    end;
  end;
end;

function TAccessibilityAdvStringGridProvider.GetFocus(out aRetVal: IRawElementProviderFragment): HResult;
var
  lCell: IAccessibilityProviderNode;
  lCurrentCell: TPoint;
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) or not ControlIsInActiveVisibleTree(fGrid) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if not GridOwnsFocus then
  begin
    Exit(S_OK);
  end;

  lCurrentCell := CurrentProviderCell;
  lCell := EnsureCellProvider(lCurrentCell.X, lCurrentCell.Y);
  if lCell <> nil then
  begin
    aRetVal := lCell.FragmentProvider;
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.GetItem(aRow: Integer; aColumn: Integer;
  out aRetVal: IRawElementProviderSimple): HResult;
var
  lCell: IAccessibilityProviderNode;
begin
  aRetVal := nil;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lCell := EnsureCellProvider(aColumn, aRow);
  if lCell <> nil then
  begin
    aRetVal := lCell.RawElementProvider;
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.Get_ColumnCount(out aRetVal: Integer): HResult;
begin
  aRetVal := 0;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGrid.ColCount;
  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.Get_CanSelectMultiple(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.Get_IsSelectionRequired(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.Get_RowCount(out aRetVal: Integer): HResult;
begin
  aRetVal := 0;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGrid.RowCount;
  Result := S_OK;
end;

function TAccessibilityAdvStringGridProvider.GetSelection(out aRetVal: PSafeArray): HResult;
var
  lCell: IAccessibilityProviderNode;
  lCurrentCell: TPoint;
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lCurrentCell := CurrentProviderCell;
  lCell := EnsureCellProvider(lCurrentCell.X, lCurrentCell.Y);
  if lCell = nil then
  begin
    aRetVal := CreateSelectionArray(nil);
  end else begin
    aRetVal := CreateSelectionArray(lCell.RawElementProvider);
  end;

  if aRetVal = nil then
  begin
    Result := E_UNEXPECTED;
  end else begin
    Result := S_OK;
  end;
end;

function TAccessibilityAdvStringGridProvider.TryGetFocusedItem(out aProvider: IRawElementProviderSimple;
  out aName: string): Boolean;
var
  lCurrentCell: TPoint;
  lItem: IAccessibilityProviderNode;
begin
  aProvider := nil;
  aName := '';
  Result := False;
  if IsDisconnected or (fGrid = nil) or not ControlIsInActiveVisibleTree(fGrid) or not GridOwnsFocus then
  begin
    Exit;
  end;

  lCurrentCell := CurrentProviderCell;
  lItem := EnsureCellProviderDirect(lCurrentCell.X, lCurrentCell.Y);
  if lItem = nil then
  begin
    Exit;
  end;

  aName := CellText(lCurrentCell.X, lCurrentCell.Y);
  aProvider := lItem.RawElementProvider;
  Result := aProvider <> nil;
end;

function TAccessibilityAdvStringGridProvider.GridOwnsFocus: Boolean;
var
  lActiveControl: TWinControl;
  lForm: TCustomForm;
begin
  Result := False;
  if fGrid = nil then
  begin
    Exit;
  end;

  if fGrid.Focused then
  begin
    Exit(True);
  end;

  lForm := GetParentForm(fGrid);
  if lForm = nil then
  begin
    Exit;
  end;

  lActiveControl := lForm.ActiveControl;
  Result := (lActiveControl = fGrid) or ((lActiveControl <> nil) and fGrid.ContainsControl(lActiveControl));
end;

function TAccessibilityAdvStringGridProvider.HitCell(const aPoint: TPoint; aCol: Integer;
  aRow: Integer): TPoint;
var
  lCellRect: TRect;
  lRepresentative: TPoint;
begin
  Result := NormalizedCell(aCol, aRow);
  lRepresentative := MergeRepresentativeForMarker(aCol, aRow);
  if (lRepresentative.X >= 0) and (lRepresentative.Y >= 0) then
  begin
    lCellRect := fGrid.CellRect(lRepresentative.X, lRepresentative.Y);
    if PtInRect(lCellRect, aPoint) then
    begin
      Result := lRepresentative;
      Exit;
    end;
  end;
end;

function TAccessibilityAdvStringGridProvider.IsAccessibleCell(aCol: Integer; aRow: Integer): Boolean;
var
  lNormalizedCell: TPoint;
  lRealCell: TPoint;
begin
  Result := False;
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lNormalizedCell := NormalizedCell(aCol, aRow);
  if (lNormalizedCell.X <> aCol) or (lNormalizedCell.Y <> aRow) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  Result := not fGrid.IsHiddenColumn(lRealCell.X) and not fGrid.IsHiddenRow(fGrid.RealRowIndex(aRow));
end;

function TAccessibilityAdvStringGridProvider.IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
var
  lCellRect: TRect;
begin
  if not ControlIsInActiveVisibleTree(fGrid) then
  begin
    Exit(False);
  end;

  Result := VisibleCellRect(aCol, aRow, lCellRect);
end;

function TAccessibilityAdvStringGridProvider.MergeBaseCell(aCol: Integer; aRow: Integer): TPoint;
var
  lMarkerCell: TPoint;
  lRealCell: TPoint;
begin
  Result := Point(aCol, aRow);
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  lMarkerCell := fGrid.BaseCell(lRealCell.X, lRealCell.Y);
  Result := Point(lMarkerCell.X, fGrid.RealRowIndex(lMarkerCell.Y));
  if fGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
  begin
    Result.Y := fGrid.RealRowIndex(aRow) - (aRow - lMarkerCell.Y);
  end;
end;

function TAccessibilityAdvStringGridProvider.MergeBaseIsVisible(const aBaseCell: TPoint): Boolean;
var
  lDisplayRow: Integer;
  lSpan: TPoint;
begin
  Result := False;
  if (fGrid = nil) or (aBaseCell.X < 0) or (aBaseCell.X >= fGrid.AllColCount) or
    (aBaseCell.Y < 0) or (aBaseCell.Y >= fGrid.AllRowCount) or fGrid.IsHiddenColumn(aBaseCell.X) or
    fGrid.IsHiddenRow(aBaseCell.Y) then
  begin
    Exit;
  end;

  lDisplayRow := fGrid.DisplRowIndex(aBaseCell.Y);
  if (lDisplayRow < 0) or (lDisplayRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lSpan := fGrid.CellSpan(aBaseCell.X, lDisplayRow);
  Result := (lSpan.X > 0) or (lSpan.Y > 0);
end;

function TAccessibilityAdvStringGridProvider.MergeRepresentativeForMarker(aCol: Integer;
  aRow: Integer): TPoint;
var
  lBaseCell: TPoint;
  lCandidateBase: TPoint;
  lCol: Integer;
  lFirstScrollableCol: Integer;
  lFirstScrollableRow: Integer;
  lFixedColCount: Integer;
  lFixedRowCount: Integer;
  lLastScrollableCol: Integer;
  lLastScrollableRow: Integer;
  lMarkerCell: TPoint;
  lPair: TPair<Int64, IAccessibilityProviderNode>;
  lRealCell: TPoint;
  lRepresentative: TPoint;
  lRow: Integer;
  function FindInRange(aFirstCol: Integer; aLastCol: Integer; aFirstRow: Integer;
    aLastRow: Integer; out aRepresentative: TPoint): Boolean;
  var
    lRangeBaseCell: TPoint;
    lRangeCandidateBase: TPoint;
    lRangeCol: Integer;
    lRangeRealCell: TPoint;
    lRangeRow: Integer;
  begin
    aRepresentative := Point(-1, -1);
    Result := False;
    if (aFirstCol > aLastCol) or (aFirstRow > aLastRow) then
    begin
      Exit;
    end;

    for lRangeRow := aFirstRow to aLastRow do
    begin
      for lRangeCol := aFirstCol to aLastCol do
      begin
        lRangeRealCell := RealCell(lRangeCol, lRangeRow);
        if fGrid.IsMergedNonBaseCell(lRangeRealCell.X, lRangeRealCell.Y) then
        begin
          lRangeCandidateBase := fGrid.BaseCell(lRangeRealCell.X, lRangeRealCell.Y);
          if (lRangeCandidateBase.X = lMarkerCell.X) and (lRangeCandidateBase.Y = lMarkerCell.Y) then
          begin
            lRangeBaseCell := MergeBaseCell(lRangeCol, lRangeRow);
            if fGrid.IsHiddenColumn(lRangeBaseCell.X) or fGrid.IsHiddenRow(lRangeBaseCell.Y) then
            begin
              aRepresentative := NormalizedCell(lRangeCol, lRangeRow);
              Exit(True);
            end;
          end;
        end;
      end;
    end;
  end;
begin
  Result := Point(-1, -1);
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or
    (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  lMarkerCell := Point(lRealCell.X, aRow);
  for lPair in fCells do
  begin
    lCol := CellKeyCol(lPair.Key);
    lRow := CellKeyRow(lPair.Key);
    lRealCell := RealCell(lCol, lRow);
    if fGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
    begin
      lCandidateBase := fGrid.BaseCell(lRealCell.X, lRealCell.Y);
      if (lCandidateBase.X = lMarkerCell.X) and (lCandidateBase.Y = lMarkerCell.Y) then
      begin
        lBaseCell := MergeBaseCell(lCol, lRow);
        if fGrid.IsHiddenColumn(lBaseCell.X) or fGrid.IsHiddenRow(lBaseCell.Y) then
        begin
          Exit(NormalizedCell(lCol, lRow));
        end;
      end;
    end;
  end;

  lFixedColCount := Min(fGrid.FixedCols, fGrid.ColCount);
  lFixedRowCount := Min(fGrid.FixedRows, fGrid.RowCount);
  lFirstScrollableCol := EnsureRange(fGrid.LeftCol, 0, Pred(fGrid.ColCount));
  if lFirstScrollableCol < lFixedColCount then
  begin
    lFirstScrollableCol := lFixedColCount;
  end;
  lLastScrollableCol := Min(Pred(fGrid.ColCount),
    lFirstScrollableCol + Max(0, fGrid.VisibleColCount) + 1);
  lFirstScrollableRow := EnsureRange(fGrid.TopRow, 0, Pred(fGrid.RowCount));
  if lFirstScrollableRow < lFixedRowCount then
  begin
    lFirstScrollableRow := lFixedRowCount;
  end;
  lLastScrollableRow := Min(Pred(fGrid.RowCount),
    lFirstScrollableRow + Max(0, fGrid.VisibleRowCount) + 1);
  if FindInRange(0, Pred(lFixedColCount), 0, Pred(lFixedRowCount), lRepresentative) or
    FindInRange(lFirstScrollableCol, lLastScrollableCol, 0, Pred(lFixedRowCount), lRepresentative) or
    FindInRange(0, Pred(lFixedColCount), lFirstScrollableRow, lLastScrollableRow, lRepresentative) or
    FindInRange(lFirstScrollableCol, lLastScrollableCol, lFirstScrollableRow, lLastScrollableRow,
      lRepresentative) then
  begin
    Result := lRepresentative;
  end;
end;

function TAccessibilityAdvStringGridProvider.NormalizedCell(aCol: Integer; aRow: Integer): TPoint;
var
  lBaseCell: TPoint;
  lCol: Integer;
  lRealCell: TPoint;
  lRow: Integer;
  lSpan: TPoint;
begin
  Result := Point(aCol, aRow);
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  lSpan := fGrid.CellSpan(lRealCell.X, lRealCell.Y);
  if not fGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) and (lSpan.X <= 0) and (lSpan.Y <= 0) then
  begin
    Exit;
  end;

  lBaseCell := MergeBaseCell(aCol, aRow);
  if MergeBaseIsVisible(lBaseCell) then
  begin
    Exit(Point(fGrid.DisplColIndex(lBaseCell.X), fGrid.DisplRowIndex(lBaseCell.Y)));
  end;

  for lRow := 0 to Pred(fGrid.RowCount) do
  begin
    for lCol := 0 to Pred(fGrid.ColCount) do
    begin
      if CellBelongsToMerge(lCol, lRow, lBaseCell) then
      begin
        Exit(Point(lCol, lRow));
      end;
    end;
  end;

  Result := Point(-1, -1);
end;

function TAccessibilityAdvStringGridProvider.PointHitsCell(const aPoint: TPoint;
  const aExpectedCell: TPoint): Boolean;
var
  lBaseCell: TPoint;
  lCellRect: TRect;
  lExpectedRealCell: TPoint;
  lHitCell: TPoint;
  lHitCol: Integer;
  lHitPoint: TPoint;
  lHitRealCell: TPoint;
  lHitRow: Integer;
begin
  Result := False;
  if fGrid = nil then
  begin
    Exit;
  end;

  lHitPoint := fGrid.ClientToScreen(aPoint);
  fGrid.ScreenToCell(lHitPoint, lHitCol, lHitRow);
  lHitCell := NormalizedCell(lHitCol, lHitRow);
  Result := (lHitCell.X = aExpectedCell.X) and (lHitCell.Y = aExpectedCell.Y);
  if Result then
  begin
    Exit;
  end;

  lExpectedRealCell := RealCell(aExpectedCell.X, aExpectedCell.Y);
  if not fGrid.IsMergedNonBaseCell(lExpectedRealCell.X, lExpectedRealCell.Y) then
  begin
    Exit;
  end;

  lBaseCell := fGrid.BaseCell(lExpectedRealCell.X, lExpectedRealCell.Y);
  lHitRealCell := RealCell(lHitCol, lHitRow);
  lCellRect := fGrid.CellRect(aExpectedCell.X, aExpectedCell.Y);
  Result := (lBaseCell.X = lHitRealCell.X) and (lBaseCell.Y = lHitRow) and
    PtInRect(lCellRect, aPoint);
end;

function TAccessibilityAdvStringGridProvider.RealCell(aCol: Integer; aRow: Integer): TPoint;
begin
  Result := Point(aCol, aRow);
  if (fGrid <> nil) and (aCol >= 0) and (aCol < fGrid.ColCount) and (aRow >= 0) and (aRow < fGrid.RowCount) then
  begin
    Result := Point(fGrid.RealColIndex(aCol), aRow);
  end;
end;

function TAccessibilityAdvStringGridProvider.VisibleCellRect(aCol: Integer; aRow: Integer;
  out aRect: TRect): Boolean;
var
  lCellRect: TRect;
  lClientRect: TRect;
  lBottom: Integer;
  lHitPoint: TPoint;
  lExpectedCell: TPoint;
  lLeft: Integer;
  lRealCell: TPoint;
  lRight: Integer;
  lTop: Integer;
  lVisibleRect: TRect;
begin
  aRect := TRect.Empty;
  Result := False;
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lExpectedCell := NormalizedCell(aCol, aRow);
  if (lExpectedCell.X <> aCol) or (lExpectedCell.Y <> aRow) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  if fGrid.IsHiddenColumn(lRealCell.X) or fGrid.IsHiddenRow(fGrid.RealRowIndex(aRow)) then
  begin
    Exit;
  end;

  lCellRect := fGrid.CellRect(aCol, aRow);
  lClientRect := Rect(0, 0, fGrid.ClientWidth, fGrid.ClientHeight);
  if not (IsNonEmptyRect(lCellRect) and IntersectRect(lVisibleRect, lCellRect, lClientRect) and
    IsNonEmptyRect(lVisibleRect)) then
  begin
    Exit;
  end;

  lHitPoint := Point((lVisibleRect.Left + lVisibleRect.Right) div 2,
    (lVisibleRect.Top + lVisibleRect.Bottom) div 2);
  if not PointHitsCell(lHitPoint, lExpectedCell) then
  begin
    lLeft := lVisibleRect.Left;
    lRight := Pred(lVisibleRect.Right);
    lTop := lVisibleRect.Top;
    lBottom := Pred(lVisibleRect.Bottom);
    if lRight > lLeft then
    begin
      Inc(lLeft);
      Dec(lRight);
    end;

    if lBottom > lTop then
    begin
      Inc(lTop);
      Dec(lBottom);
    end;

    if not (PointHitsCell(Point(lLeft, lTop), lExpectedCell) or
      PointHitsCell(Point(lRight, lTop), lExpectedCell) or
      PointHitsCell(Point(lLeft, lBottom), lExpectedCell) or
      PointHitsCell(Point(lRight, lBottom), lExpectedCell)) then
    begin
      Exit;
    end;
  end;

  aRect := lVisibleRect;
  Result := True;
end;

function TAccessibilityAdvStringGridProvider.VisibleColumnSpan(aCol: Integer; aRow: Integer): Integer;
var
  lBaseCell: TPoint;
  lCol: Integer;
  lRepresentative: TPoint;
begin
  Result := 1;
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRepresentative := NormalizedCell(aCol, aRow);
  lBaseCell := MergeBaseCell(aCol, aRow);
  if not CellBelongsToMerge(lRepresentative.X, lRepresentative.Y, lBaseCell) then
  begin
    Exit;
  end;

  Result := 0;
  for lCol := 0 to Pred(fGrid.ColCount) do
  begin
    if CellBelongsToMerge(lCol, lRepresentative.Y, lBaseCell) then
    begin
      Inc(Result);
    end;
  end;

  if Result = 0 then
  begin
    Result := 1;
  end;
end;

function TAccessibilityAdvStringGridProvider.VisibleRowSpan(aCol: Integer; aRow: Integer): Integer;
var
  lBaseCell: TPoint;
  lRepresentative: TPoint;
  lRow: Integer;
begin
  Result := 1;
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRepresentative := NormalizedCell(aCol, aRow);
  lBaseCell := MergeBaseCell(aCol, aRow);
  if not CellBelongsToMerge(lRepresentative.X, lRepresentative.Y, lBaseCell) then
  begin
    Exit;
  end;

  Result := 0;
  for lRow := 0 to Pred(fGrid.RowCount) do
  begin
    if CellBelongsToMerge(lRepresentative.X, lRow, lBaseCell) then
    begin
      Inc(Result);
    end;
  end;

  if Result = 0 then
  begin
    Result := 1;
  end;
end;

procedure TAccessibilityAdvStringGridProvider.PrepareChildrenForNavigation;
begin
  inherited PrepareChildrenForNavigation;
  if ChildrenPreparationIsCurrent then
  begin
    Exit;
  end;

  RefreshVisibleCells;
  RememberChildrenPreparation;
end;

procedure TAccessibilityAdvStringGridProvider.RefreshVisibleCells;
var
  lCell: IAccessibilityProviderNode;
  lCellRect: TRect;
  lCellProbeCount: Integer;
  lCol: Integer;
  lCreatedCount: Integer;
  lFixedColCount: Integer;
  lFixedRowCount: Integer;
  lFirstScrollableCol: Integer;
  lFirstScrollableRow: Integer;
  lKey: Int64;
  lKeysToRemove: TList<Int64>;
  lLastScrollableCol: Integer;
  lLastScrollableRow: Integer;
  lMetricsEnabled: Boolean;
  lPair: TPair<Int64, IAccessibilityProviderNode>;
  lRow: Integer;
  lStopwatch: TStopwatch;
begin
  fResolvedCurrentValid := False;
  if (fGrid = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) or (fGrid.ColCount <= 0) or
    (fGrid.RowCount <= 0) then
  begin
    Exit;
  end;

  lCellProbeCount := 0;
  lCreatedCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  lKeysToRemove := nil;
  try
    for lPair in fCells do
    begin
      if lPair.Value.IsDisconnected or not VisibleCellRect(CellKeyCol(lPair.Key), CellKeyRow(lPair.Key), lCellRect) then
      begin
        if lKeysToRemove = nil then
        begin
          lKeysToRemove := TList<Int64>.Create;
          if lMetricsEnabled then
          begin
            TAccessibilityDiagnostics.RecordTmsAdvStringGridRefreshScratchListAllocation(1);
          end;
        end;
        lKeysToRemove.Add(lPair.Key);
      end;
    end;

    if lKeysToRemove <> nil then
    begin
      for lKey in lKeysToRemove do
      begin
        if fCells.TryGetValue(lKey, lCell) then
        begin
          RemoveChildNode(lCell, False);
          fCells.Remove(lKey);
        end;
      end;
    end;
  finally
    lKeysToRemove.Free;
  end;

  lFixedColCount := Min(fGrid.FixedCols, fGrid.ColCount);
  lFixedRowCount := Min(fGrid.FixedRows, fGrid.RowCount);
  lFirstScrollableCol := EnsureRange(fGrid.LeftCol, 0, Pred(fGrid.ColCount));
  lLastScrollableCol := Min(Pred(fGrid.ColCount), lFirstScrollableCol + Max(0, fGrid.VisibleColCount) + 1);
  lFirstScrollableRow := EnsureRange(fGrid.TopRow, 0, Pred(fGrid.RowCount));
  lLastScrollableRow := Min(Pred(fGrid.RowCount), lFirstScrollableRow + Max(0, fGrid.VisibleRowCount) + 1);

  for lRow := 0 to Pred(lFixedRowCount) do
  begin
    for lCol := 0 to Pred(lFixedColCount) do
    begin
      EnsureVisibleCellProvider(lCol, lRow, lMetricsEnabled, lCellProbeCount, lCreatedCount);
    end;

    for lCol := lFirstScrollableCol to lLastScrollableCol do
    begin
      if lCol >= lFixedColCount then
      begin
        EnsureVisibleCellProvider(lCol, lRow, lMetricsEnabled, lCellProbeCount, lCreatedCount);
      end;
    end;
  end;

  for lRow := lFirstScrollableRow to lLastScrollableRow do
  begin
    if lRow >= lFixedRowCount then
    begin
      for lCol := 0 to Pred(lFixedColCount) do
      begin
        EnsureVisibleCellProvider(lCol, lRow, lMetricsEnabled, lCellProbeCount, lCreatedCount);
      end;

      for lCol := lFirstScrollableCol to lLastScrollableCol do
      begin
        if lCol >= lFixedColCount then
        begin
          EnsureVisibleCellProvider(lCol, lRow, lMetricsEnabled, lCellProbeCount, lCreatedCount);
        end;
      end;
    end;
  end;

  if lMetricsEnabled then
  begin
    TAccessibilityDiagnostics.RecordTmsAdvStringGridRefresh(lCellProbeCount, lCreatedCount,
      lStopwatch.ElapsedTicks);
  end;
end;

procedure TAccessibilityAdvStringGridProvider.RememberChildrenPreparation;
begin
  fPreparedValid := False;
  if (fGrid = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) then
  begin
    Exit;
  end;

  fPreparedHandle := fGrid.Handle;
  fPreparedClientWidth := fGrid.ClientWidth;
  fPreparedClientHeight := fGrid.ClientHeight;
  fPreparedColCount := fGrid.ColCount;
  fPreparedRowCount := fGrid.RowCount;
  fPreparedFixedCols := fGrid.FixedCols;
  fPreparedFixedRows := fGrid.FixedRows;
  fPreparedLeftCol := fGrid.LeftCol;
  fPreparedTopRow := fGrid.TopRow;
  fPreparedVisibleColCount := fGrid.VisibleColCount;
  fPreparedVisibleRowCount := fGrid.VisibleRowCount;
  fPreparedValid := True;
end;

class function TAccessibilityTmsAdvStringGridAdapters.CreateRegistry: IAccessibilityAdapterRegistry;
begin
  Result := TAccessibilityVclAdapters.CreateDefaultRegistry;
  RegisterAdapters(Result);
end;

class procedure TAccessibilityTmsAdvStringGridAdapters.RegisterAdapters(
  const aRegistry: IAccessibilityAdapterRegistry);
begin
  if aRegistry <> nil then
  begin
    aRegistry.RegisterAdapter(TAdvStringGrid, TAdvStringGridAdapter.Create);
  end;
end;

end.
