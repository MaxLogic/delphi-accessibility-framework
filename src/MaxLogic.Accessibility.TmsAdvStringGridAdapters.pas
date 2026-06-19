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
  System.Generics.Collections, System.SysUtils, System.Types, System.Variants, Winapi.ActiveX, Winapi.Windows,
  Vcl.Controls, Vcl.Forms, AdvGrid, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.UIAutomationCore,
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

  TAccessibilityAdvStringGridProvider = class(TAccessibilityProviderNode, IRawElementProviderFragmentRoot,
    IGridProvider, ISelectionProvider)
  private
    fCells: TDictionary<Int64, IAccessibilityProviderNode>;
    fGrid: TAdvStringGrid;
    fRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    function CellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function CellText(aCol: Integer; aRow: Integer): string;
    function CreateSelectionArray(const aProvider: IRawElementProviderSimple): PSafeArray;
    function EnsureCellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function GridOwnsFocus: Boolean;
    function IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
    function NormalizedCell(aCol: Integer; aRow: Integer): TPoint;
    function RealCell(aCol: Integer; aRow: Integer): TPoint;
    function VisibleCellRect(aCol: Integer; aRow: Integer; out aRect: TRect): Boolean;
    procedure RefreshVisibleCells;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create(aGrid: TAdvStringGrid; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    destructor Destroy; override;
    function ElementProviderFromPoint(aX: Double; aY: Double; out aRetVal: IRawElementProviderFragment):
      HResult; stdcall;
    function GetFocus(out aRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetItem(aRow: Integer; aColumn: Integer; out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_ColumnCount(out aRetVal: Integer): HResult; stdcall;
    function Get_CanSelectMultiple(out aRetVal: BOOL): HResult; stdcall;
    function Get_IsSelectionRequired(out aRetVal: BOOL): HResult; stdcall;
    function Get_RowCount(out aRetVal: Integer): HResult; stdcall;
    function GetSelection(out aRetVal: PSafeArray): HResult; stdcall;
  end;

function CellKey(aCol: Integer; aRow: Integer): Int64;
begin
  Result := (Int64(aRow) shl 32) or Cardinal(aCol);
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
  Result := TAccessibilityAdvStringGridProvider.Create(TAdvStringGrid(aControl), aRuntimeId, aName, aHelpText,
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
begin
  Result := True;
  case aPropertyId of
    UIA_NamePropertyId:
      aValue := CellText;
    UIA_IsOffscreenPropertyId:
      aValue := not IsVisibleCell;
    UIA_HasKeyboardFocusPropertyId:
      aValue := (fGridProvider <> nil) and fGridProvider.GridOwnsFocus and
        (fGrid.Col = fCol) and (fGrid.Row = fRow);
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
var
  lCell: TPoint;
  lSpan: TPoint;
begin
  aRetVal := 1;
  if IsDisconnected or (fGrid = nil) or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lCell := fGridProvider.RealCell(fCol, fRow);
  lSpan := fGrid.CellSpan(lCell.X, lCell.Y);
  if lSpan.X > 0 then
  begin
    aRetVal := lSpan.X + 1;
  end;

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
begin
  aRetVal := False;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if (fGrid.Col = fCol) and (fGrid.Row = fRow) then
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
var
  lCell: TPoint;
  lSpan: TPoint;
begin
  aRetVal := 1;
  if IsDisconnected or (fGrid = nil) or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lCell := fGridProvider.RealCell(fCol, fRow);
  lSpan := fGrid.CellSpan(lCell.X, lCell.Y);
  if lSpan.Y > 0 then
  begin
    aRetVal := lSpan.Y + 1;
  end;

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

function TAccessibilityAdvStringGridProvider.CellText(aCol: Integer; aRow: Integer): string;
var
  lCell: TPoint;
begin
  Result := '';
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lCell := RealCell(aCol, aRow);
  Result := Trim(string(fGrid.StrippedCells[lCell.X, lCell.Y]));
  if Result = '' then
  begin
    Result := Trim(string(fGrid.WideCells[lCell.X, lCell.Y]));
  end;
end;

constructor TAccessibilityAdvStringGridProvider.Create(aGrid: TAdvStringGrid; aRuntimeId: Integer;
  const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode([aRuntimeId], aGrid.Handle, aApi, aGrid);
  fCells := TDictionary<Int64, IAccessibilityProviderNode>.Create;
  fGrid := aGrid;
  fRuntimeId := aRuntimeId;
  fUiaApi := aApi;
  SetProperty(UIA_NamePropertyId, aName);
  SetProperty(UIA_ControlTypePropertyId, UIA_DataGridControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aGrid.ClassName);
  SetProperty(UIA_HelpTextPropertyId, aHelpText);
  RefreshVisibleCells;
end;

function TAccessibilityAdvStringGridProvider.CreateSelectionArray(
  const aProvider: IRawElementProviderSimple): PSafeArray;
var
  lIndex: Integer;
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

  lIndex := 0;
  lUnknown := aProvider as IUnknown;
  if SafeArrayPutElement(Result, lIndex, lUnknown) <> S_OK then
  begin
    SafeArrayDestroy(Result);
    Result := nil;
  end;
end;

destructor TAccessibilityAdvStringGridProvider.Destroy;
begin
  fCells.Free;
  inherited Destroy;
end;

function TAccessibilityAdvStringGridProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lTopLeft: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fGrid = nil) or IsDisconnected then
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
    UIA_HasKeyboardFocusPropertyId:
      aValue := GridOwnsFocus;
    UIA_IsEnabledPropertyId:
      aValue := fGrid.Enabled;
    UIA_IsKeyboardFocusablePropertyId:
      aValue := fGrid.TabStop;
    UIA_IsOffscreenPropertyId:
      aValue := not fGrid.Visible;
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TAccessibilityAdvStringGridProvider.ElementProviderFromPoint(aX: Double; aY: Double;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lCell: IAccessibilityProviderNode;
  lCol: Integer;
  lPoint: TPoint;
  lRow: Integer;
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lPoint := Point(Integer(Round(aX)), Integer(Round(aY)));
  fGrid.ScreenToCell(lPoint, lCol, lRow);
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
  RefreshVisibleCells;
  lCell := NormalizedCell(aCol, aRow);
  Result := CellProvider(lCell.X, lCell.Y);
end;

function TAccessibilityAdvStringGridProvider.GetFocus(out aRetVal: IRawElementProviderFragment): HResult;
var
  lCell: IAccessibilityProviderNode;
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if not GridOwnsFocus then
  begin
    Exit(S_OK);
  end;

  lCell := EnsureCellProvider(fGrid.Col, fGrid.Row);
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
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lCell := EnsureCellProvider(fGrid.Col, fGrid.Row);
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

function TAccessibilityAdvStringGridProvider.IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
var
  lCellRect: TRect;
begin
  Result := VisibleCellRect(aCol, aRow, lCellRect);
end;

function TAccessibilityAdvStringGridProvider.NormalizedCell(aCol: Integer; aRow: Integer): TPoint;
var
  lBaseCell: TPoint;
  lRealCell: TPoint;
begin
  Result := Point(aCol, aRow);
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  if fGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
  begin
    lBaseCell := fGrid.BaseCell(lRealCell.X, lRealCell.Y);
    Result := Point(fGrid.DisplColIndex(lBaseCell.X), lBaseCell.Y);
  end;
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
  lHitCell: TPoint;
  lHitCol: Integer;
  lHitPoint: TPoint;
  lHitRow: Integer;
  lExpectedCell: TPoint;
  lRealCell: TPoint;
  lVisibleRect: TRect;
begin
  aRect := TRect.Empty;
  Result := False;
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lRealCell := RealCell(aCol, aRow);
  if fGrid.IsHiddenColumn(lRealCell.X) or fGrid.IsHiddenRow(fGrid.RealRowIndex(aRow)) or
    fGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
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
  lHitPoint := fGrid.ClientToScreen(lHitPoint);
  fGrid.ScreenToCell(lHitPoint, lHitCol, lHitRow);
  lHitCell := NormalizedCell(lHitCol, lHitRow);
  lExpectedCell := NormalizedCell(aCol, aRow);
  if (lHitCell.X <> lExpectedCell.X) or (lHitCell.Y <> lExpectedCell.Y) then
  begin
    Exit;
  end;

  aRect := lVisibleRect;
  Result := True;
end;

procedure TAccessibilityAdvStringGridProvider.PrepareChildrenForNavigation;
begin
  inherited PrepareChildrenForNavigation;
  RefreshVisibleCells;
end;

procedure TAccessibilityAdvStringGridProvider.RefreshVisibleCells;
var
  lCell: IAccessibilityProviderNode;
  lCol: Integer;
  lKey: Int64;
  lKeysToRemove: TList<Int64>;
  lPair: TPair<Int64, IAccessibilityProviderNode>;
  lRow: Integer;
begin
  if (fGrid = nil) or IsDisconnected then
  begin
    Exit;
  end;

  lKeysToRemove := TList<Int64>.Create;
  try
    for lPair in fCells do
    begin
      if lPair.Value.IsDisconnected or not IsVisibleCell(CellKeyCol(lPair.Key), CellKeyRow(lPair.Key)) then
      begin
        lKeysToRemove.Add(lPair.Key);
      end;
    end;

    for lKey in lKeysToRemove do
    begin
      if fCells.TryGetValue(lKey, lCell) then
      begin
        RemoveChildNode(lCell, True);
        fCells.Remove(lKey);
      end;
    end;
  finally
    lKeysToRemove.Free;
  end;

  for lRow := 0 to Pred(fGrid.RowCount) do
  begin
    for lCol := 0 to Pred(fGrid.ColCount) do
    begin
      if IsVisibleCell(lCol, lRow) and (CellProvider(lCol, lRow) = nil) then
      begin
        lCell := TAccessibilityAdvStringGridCellProvider.Create(Self, fGrid, lCol, lRow,
          [fRuntimeId, lRow, lCol], fUiaApi) as IAccessibilityProviderNode;
        AddChild(lCell);
        fCells.Add(CellKey(lCol, lRow), lCell);
      end;
    end;
  end;
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
