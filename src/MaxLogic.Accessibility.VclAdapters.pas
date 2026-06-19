unit MaxLogic.Accessibility.VclAdapters;

interface

uses
  Vcl.Controls, Vcl.Forms,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner;

type
  IAccessibilityVclProviderAdapter = interface
    ['{D5B0E9EE-408D-426B-9FF8-7E3A2BB90057}']
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TAccessibilityVclAdapters = record
  public
    class function CreateDefaultRegistry: IAccessibilityAdapterRegistry; static;
    class procedure RegisterDefaultAdapters(const aRegistry: IAccessibilityAdapterRegistry); static;
  end;

  TAccessibilityVclProviderBuilder = record
  public
    class function BuildForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry = nil):
      IAccessibilityProviderNode; overload; static;
    class function BuildForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry;
      const aApi: IAccessibilityUiaApi):
      IAccessibilityProviderNode; overload; static;
  end;

implementation

uses
  System.Actions, System.Generics.Collections, System.SysUtils, System.Types, System.TypInfo, Winapi.ActiveX,
  Winapi.Windows, Vcl.Buttons, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.Text,
  MaxLogic.Accessibility.UIAutomationCore;

type
  IAccessibilityVclRootProvider = interface
    ['{28654175-22FB-4F34-BDE7-8D82E7087897}']
    procedure AddHitTestRoot(const aRoot: IRawElementProviderFragmentRoot);
  end;

  TExplicitTextAdapter = class(TInterfacedObject, IAccessibilityControlAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
  end;

  TPanelAdapter = class(TInterfacedObject, IAccessibilityControlAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
  end;

  TStringGridAdapter = class(TInterfacedObject, IAccessibilityControlAdapter, IAccessibilityVclProviderAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TAccessibilityVclFormProviderRoot = class(TAccessibilityProviderRoot, IAccessibilityVclRootProvider)
  private
    fHitTestRoots: TList<IRawElementProviderFragmentRoot>;
  protected
    function DoElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment):
      HResult; override;
    function DoGetFocus(out aProvider: IRawElementProviderFragment): HResult; override;
  public
    constructor Create(aForm: TCustomForm; const aApi: IAccessibilityUiaApi);
    destructor Destroy; override;
    procedure AddHitTestRoot(const aRoot: IRawElementProviderFragmentRoot);
  end;

  TAccessibilityStringGridProvider = class;

  TAccessibilityVclControlProvider = class(TAccessibilityProviderNode, IInvokeProvider, IToggleProvider)
  private
    fControl: TControl;
    class function SpeedButtonSupportsToggle(aButton: TSpeedButton): Boolean; static;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
  public
    constructor Create(aControl: TControl; const aRuntimeId: array of Integer; aControlTypeId: Integer;
      const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
    function Get_ToggleState(out aRetVal: ToggleState): HResult; stdcall;
    function Invoke: HResult; stdcall;
    function Toggle: HResult; stdcall;
  end;

  TAccessibilityStringGridCellProvider = class(TAccessibilityProviderNode, IGridItemProvider, ISelectionItemProvider)
  private
    fCol: Integer;
    fGrid: TStringGrid;
    fGridProvider: TAccessibilityStringGridProvider;
    fRow: Integer;
    function IsVisibleCell: Boolean;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aGridProvider: TAccessibilityStringGridProvider; aGrid: TStringGrid; aCol: Integer;
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

  TAccessibilityStringGridProvider = class(TAccessibilityProviderNode, IRawElementProviderFragmentRoot, IGridProvider,
    ISelectionProvider)
  private
    fCells: TDictionary<Int64, IAccessibilityProviderNode>;
    fGrid: TStringGrid;
    fRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    procedure BuildVisibleCells;
    function CellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function CreateSelectionArray(const aProvider: IRawElementProviderSimple): PSafeArray;
    function EnsureCellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function GridOwnsFocus: Boolean;
    function IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
    procedure RefreshVisibleCells;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create(aGrid: TStringGrid; aRuntimeId: Integer; const aName: string; const aHelpText: string;
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

function IsVisibleCellRect(const aCellRect: TRect): Boolean;
begin
  Result := (aCellRect.Width > 0) and (aCellRect.Height > 0);
end;

function ReadObjectProperty(aObject: TObject; const aPropertyName: string): TObject;
var
  lPropInfo: PPropInfo;
begin
  Result := nil;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkClass) then
  begin
    Result := GetObjectProp(aObject, lPropInfo);
  end;
end;

function ReadStringProperty(aObject: TObject; const aPropertyName: string): string;
var
  lPropInfo: PPropInfo;
begin
  Result := '';
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    Result := TAccessibilityText.Clean(GetStrProp(aObject, lPropInfo));
  end;
end;

function HasUsefulTextProperty(aControl: TControl; const aPropertyName: string): Boolean;
var
  lText: string;
begin
  lText := ReadStringProperty(aControl, aPropertyName);
  Result := (lText <> '') and not TAccessibilityText.IsIconFontOnly(lText);
end;

function HasUsefulExplicitText(aControl: TControl): Boolean;
var
  lAction: TObject;
  lHelpText: string;
  lHintName: string;
begin
  Result := False;
  if aControl = nil then
  begin
    Exit;
  end;

  if HasUsefulTextProperty(aControl, 'AccessibleName') or HasUsefulTextProperty(aControl, 'Caption') or
    HasUsefulTextProperty(aControl, 'Text') then
  begin
    Exit(True);
  end;

  TAccessibilityText.SplitHint(ReadStringProperty(aControl, 'Hint'), lHintName, lHelpText);
  if (lHintName <> '') or (lHelpText <> '') then
  begin
    Exit(True);
  end;

  lAction := ReadObjectProperty(aControl, 'Action');
  if lAction is TContainedAction then
  begin
    if (TAccessibilityText.Clean(TContainedAction(lAction).Caption) <> '') or
      (TAccessibilityText.Clean(TContainedAction(lAction).Hint) <> '') then
    begin
      Exit(True);
    end;
  end;
end;

function HasAccessibleDescendant(aControl: TWinControl): Boolean;
var
  i: Integer;
  lChild: TControl;
begin
  Result := False;
  for i := 0 to Pred(aControl.ControlCount) do
  begin
    lChild := aControl.Controls[i];
    if HasUsefulExplicitText(lChild) then
    begin
      Exit(True);
    end;

    if (lChild is TWinControl) and HasAccessibleDescendant(TWinControl(lChild)) then
    begin
      Exit(True);
    end;
  end;
end;

function ControlTypeFor(aControl: TControl): Integer;
begin
  if aControl is TSpeedButton then
  begin
    Exit(UIA_ButtonControlTypeId);
  end;

  if aControl is TCustomPanel then
  begin
    Exit(UIA_PaneControlTypeId);
  end;

  Result := UIA_TextControlTypeId;
end;

function CreateProviderForNode(const aNode: IAccessibilityScanNode; const aRegistry: IAccessibilityAdapterRegistry;
  var aNextRuntimeId: Integer; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
var
  lAdapter: IAccessibilityControlAdapter;
  lProviderAdapter: IAccessibilityVclProviderAdapter;
begin
  Inc(aNextRuntimeId);
  if aRegistry <> nil then
  begin
    lAdapter := aRegistry.ResolveAdapter(aNode.Control);
    if Supports(lAdapter, IAccessibilityVclProviderAdapter, lProviderAdapter) then
    begin
      Exit(lProviderAdapter.CreateProvider(aNode.Control, aNextRuntimeId, aNode.Name, aNode.HelpText, aApi));
    end;
  end;

  Result := TAccessibilityVclControlProvider.Create(aNode.Control, [aNextRuntimeId], ControlTypeFor(aNode.Control),
    aNode.Name, aNode.HelpText, aApi) as IAccessibilityProviderNode;
end;

procedure AddProviderChildren(const aProvider: IAccessibilityProviderNode; const aScanNode: IAccessibilityScanNode;
  const aRegistry: IAccessibilityAdapterRegistry; var aNextRuntimeId: Integer; const aApi: IAccessibilityUiaApi;
  const aRootProvider: IAccessibilityVclRootProvider);
var
  i: Integer;
  lChildHitTestRoot: IRawElementProviderFragmentRoot;
  lChildManagesOwnTree: Boolean;
  lChildProvider: IAccessibilityProviderNode;
begin
  for i := 0 to Pred(aScanNode.ChildCount) do
  begin
    lChildProvider := CreateProviderForNode(aScanNode.Child(i), aRegistry, aNextRuntimeId, aApi);
    aProvider.AddChild(lChildProvider);
    lChildManagesOwnTree := Supports(lChildProvider.RawElementProvider, IRawElementProviderFragmentRoot,
      lChildHitTestRoot);
    if (aRootProvider <> nil) and lChildManagesOwnTree then
    begin
      aRootProvider.AddHitTestRoot(lChildHitTestRoot);
    end;

    if not lChildManagesOwnTree then
    begin
      AddProviderChildren(lChildProvider, aScanNode.Child(i), aRegistry, aNextRuntimeId, aApi, aRootProvider);
    end;
  end;
end;

function TExplicitTextAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if HasUsefulExplicitText(aControl) then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TPanelAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if HasUsefulExplicitText(aControl) then
  begin
    Exit(TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText));
  end;

  if (aControl is TWinControl) and HasAccessibleDescendant(TWinControl(aControl)) then
  begin
    Exit(TAccessibilityControlInfo.Include(aControl, '', ''));
  end;

  Result := TAccessibilityControlInfo.Omit;
end;

function TStringGridAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if aControl is TStringGrid then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TStringGridAdapter.CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Result := TAccessibilityStringGridProvider.Create(TStringGrid(aControl), aRuntimeId, aName, aHelpText, aApi) as
    IAccessibilityProviderNode;
end;

procedure TAccessibilityVclFormProviderRoot.AddHitTestRoot(const aRoot: IRawElementProviderFragmentRoot);
begin
  if aRoot <> nil then
  begin
    fHitTestRoots.Add(aRoot);
  end;
end;

constructor TAccessibilityVclFormProviderRoot.Create(aForm: TCustomForm; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode([1], aForm.Handle, aApi, aForm);
  fHitTestRoots := TList<IRawElementProviderFragmentRoot>.Create;
end;

destructor TAccessibilityVclFormProviderRoot.Destroy;
begin
  fHitTestRoots.Free;
  inherited Destroy;
end;

function TAccessibilityVclFormProviderRoot.DoElementProviderFromPoint(aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): HResult;
var
  i: Integer;
  lProvider: IRawElementProviderFragment;
  lResult: HResult;
begin
  aProvider := nil;
  for i := Pred(fHitTestRoots.Count) downto 0 do
  begin
    lProvider := nil;
    lResult := fHitTestRoots[i].ElementProviderFromPoint(aX, aY, lProvider);
    if lResult = UIA_E_ELEMENTNOTAVAILABLE then
    begin
      fHitTestRoots.Delete(i);
      Continue;
    end;

    if lResult <> S_OK then
    begin
      Exit(lResult);
    end;

    if lProvider <> nil then
    begin
      aProvider := lProvider;
      Exit(S_OK);
    end;
  end;

  Result := inherited DoElementProviderFromPoint(aX, aY, aProvider);
end;

function TAccessibilityVclFormProviderRoot.DoGetFocus(out aProvider: IRawElementProviderFragment): HResult;
var
  i: Integer;
  lProvider: IRawElementProviderFragment;
  lResult: HResult;
begin
  aProvider := nil;
  i := 0;
  while i < fHitTestRoots.Count do
  begin
    lProvider := nil;
    lResult := fHitTestRoots[i].GetFocus(lProvider);
    if lResult = UIA_E_ELEMENTNOTAVAILABLE then
    begin
      fHitTestRoots.Delete(i);
      Continue;
    end;

    if lResult <> S_OK then
    begin
      Exit(lResult);
    end;

    if lProvider <> nil then
    begin
      aProvider := lProvider;
      Exit(S_OK);
    end;

    Inc(i);
  end;

  Result := inherited DoGetFocus(aProvider);
end;

constructor TAccessibilityVclControlProvider.Create(aControl: TControl; const aRuntimeId: array of Integer;
  aControlTypeId: Integer; const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, aControl);
  fControl := aControl;
  SetProperty(UIA_NamePropertyId, aName);
  SetProperty(UIA_ControlTypePropertyId, aControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aControl.ClassName);
  SetProperty(UIA_HelpTextPropertyId, aHelpText);
end;

function TAccessibilityVclControlProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lPoint: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fControl = nil) or IsDisconnected then
  begin
    Exit;
  end;

  lPoint := fControl.ClientToScreen(Point(0, 0));
  aValue.Left := lPoint.X;
  aValue.Top := lPoint.Y;
  aValue.Width := fControl.Width;
  aValue.Height := fControl.Height;
  Result := True;
end;

function TAccessibilityVclControlProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Result := nil;
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit;
  end;

  if aPatternId = UIA_InvokePatternId then
  begin
    Exit(Self as IInvokeProvider);
  end;

  if (aPatternId = UIA_TogglePatternId) and SpeedButtonSupportsToggle(TSpeedButton(fControl)) then
  begin
    Exit(Self as IToggleProvider);
  end;
end;

function TAccessibilityVclControlProvider.Get_ToggleState(out aRetVal: ToggleState): HResult;
begin
  aRetVal := ToggleState_Off;
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if TSpeedButton(fControl).Down then
  begin
    aRetVal := ToggleState_On;
  end;

  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Invoke: HResult;
var
  lButton: TSpeedButton;
begin
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lButton := TSpeedButton(fControl);
  if not lButton.Enabled then
  begin
    Exit(S_OK);
  end;

  lButton.Click;
  Result := S_OK;
end;

class function TAccessibilityVclControlProvider.SpeedButtonSupportsToggle(aButton: TSpeedButton): Boolean;
begin
  Result := (aButton <> nil) and ((aButton.GroupIndex <> 0) or aButton.AllowAllUp or aButton.Down);
end;

function TAccessibilityVclControlProvider.Toggle: HResult;
var
  lButton: TSpeedButton;
begin
  if IsDisconnected or not (fControl is TSpeedButton) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lButton := TSpeedButton(fControl);
  if not SpeedButtonSupportsToggle(lButton) then
  begin
    Exit(E_NOTIMPL);
  end;

  if not lButton.Enabled then
  begin
    Exit(S_OK);
  end;

  if lButton.Down and not lButton.AllowAllUp then
  begin
    lButton.Down := True;
  end else begin
    lButton.Down := not lButton.Down;
  end;

  lButton.Click;
  Result := S_OK;
end;

function TAccessibilityStringGridCellProvider.AddToSelection: HResult;
begin
  Result := Select;
end;

constructor TAccessibilityStringGridCellProvider.Create(aGridProvider: TAccessibilityStringGridProvider;
  aGrid: TStringGrid; aCol: Integer; aRow: Integer; const aRuntimeId: array of Integer;
  const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, aGrid);
  fGridProvider := aGridProvider;
  fGrid := aGrid;
  fCol := aCol;
  fRow := aRow;
  SetProperty(UIA_ControlTypePropertyId, UIA_DataItemControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, 'TStringGridCell');
  SetProperty(UIA_HelpTextPropertyId, '');
end;

function TAccessibilityStringGridCellProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
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

  lCellRect := fGrid.CellRect(fCol, fRow);
  lTopLeft := fGrid.ClientToScreen(lCellRect.TopLeft);
  aValue.Left := lTopLeft.X;
  aValue.Top := lTopLeft.Y;
  aValue.Width := lCellRect.Width;
  aValue.Height := lCellRect.Height;
  Result := True;
end;

function TAccessibilityStringGridCellProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
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

function TAccessibilityStringGridCellProvider.DoGetPropertyValue(aPropertyId: PROPERTYID;
  out aValue: OleVariant): Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_NamePropertyId:
      aValue := fGrid.Cells[fCol, fRow];
    UIA_IsOffscreenPropertyId:
      aValue := not IsVisibleCell;
    UIA_HasKeyboardFocusPropertyId:
      aValue := (fGridProvider <> nil) and fGridProvider.GridOwnsFocus and
        (fGrid.Col = fCol) and (fGrid.Row = fRow);
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TAccessibilityStringGridCellProvider.Get_Column(out aRetVal: Integer): HResult;
begin
  aRetVal := fCol;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridCellProvider.Get_ColumnSpan(out aRetVal: Integer): HResult;
begin
  aRetVal := 1;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridCellProvider.Get_ContainingGrid(out aRetVal: IRawElementProviderSimple): HResult;
begin
  aRetVal := nil;
  if IsDisconnected or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGridProvider.RawElementProvider;
  Result := S_OK;
end;

function TAccessibilityStringGridCellProvider.Get_IsSelected(out aRetVal: BOOL): HResult;
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

function TAccessibilityStringGridCellProvider.Get_Row(out aRetVal: Integer): HResult;
begin
  aRetVal := fRow;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridCellProvider.Get_RowSpan(out aRetVal: Integer): HResult;
begin
  aRetVal := 1;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridCellProvider.Get_SelectionContainer(out aRetVal: IRawElementProviderSimple):
  HResult;
begin
  Result := Get_ContainingGrid(aRetVal);
end;

function TAccessibilityStringGridCellProvider.IsVisibleCell: Boolean;
var
  lCellRect: TRect;
begin
  Result := False;
  if (fGrid = nil) or (fCol < 0) or (fCol >= fGrid.ColCount) or (fRow < 0) or (fRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lCellRect := fGrid.CellRect(fCol, fRow);
  Result := IsVisibleCellRect(lCellRect);
end;

function TAccessibilityStringGridCellProvider.RemoveFromSelection: HResult;
begin
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := E_NOTIMPL;
end;

function TAccessibilityStringGridCellProvider.Select: HResult;
begin
  if IsDisconnected or (fGrid = nil) or not IsVisibleCell then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  fGrid.Col := fCol;
  fGrid.Row := fRow;
  Result := S_OK;
end;

procedure TAccessibilityStringGridProvider.BuildVisibleCells;
begin
  RefreshVisibleCells;
end;

function TAccessibilityStringGridProvider.CellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
begin
  if not fCells.TryGetValue(CellKey(aCol, aRow), Result) then
  begin
    Result := nil;
  end else if Result.IsDisconnected then
  begin
    Result := nil;
  end;
end;

function TAccessibilityStringGridProvider.EnsureCellProvider(aCol: Integer; aRow: Integer):
  IAccessibilityProviderNode;
begin
  RefreshVisibleCells;
  Result := CellProvider(aCol, aRow);
end;

procedure TAccessibilityStringGridProvider.RefreshVisibleCells;
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
        lCell := TAccessibilityStringGridCellProvider.Create(Self, fGrid, lCol, lRow,
          [fRuntimeId, lRow, lCol], fUiaApi) as IAccessibilityProviderNode;
        AddChild(lCell);
        fCells.Add(CellKey(lCol, lRow), lCell);
      end;
    end;
  end;
end;

constructor TAccessibilityStringGridProvider.Create(aGrid: TStringGrid; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi);
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
  BuildVisibleCells;
end;

function TAccessibilityStringGridProvider.CreateSelectionArray(
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

destructor TAccessibilityStringGridProvider.Destroy;
begin
  fCells.Free;
  inherited Destroy;
end;

function TAccessibilityStringGridProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
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

function TAccessibilityStringGridProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
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

function TAccessibilityStringGridProvider.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant):
  Boolean;
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

function TAccessibilityStringGridProvider.ElementProviderFromPoint(aX: Double; aY: Double;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lCell: IAccessibilityProviderNode;
  lClientPoint: TPoint;
  lCol: Longint;
  lRow: Longint;
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lClientPoint := fGrid.ScreenToClient(Point(Integer(Round(aX)), Integer(Round(aY))));
  fGrid.MouseToCell(lClientPoint.X, lClientPoint.Y, lCol, lRow);
  lCell := EnsureCellProvider(lCol, lRow);
  if lCell <> nil then
  begin
    aRetVal := lCell.FragmentProvider;
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridProvider.GetFocus(out aRetVal: IRawElementProviderFragment): HResult;
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

function TAccessibilityStringGridProvider.GetItem(aRow: Integer; aColumn: Integer;
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

function TAccessibilityStringGridProvider.Get_ColumnCount(out aRetVal: Integer): HResult;
begin
  aRetVal := 0;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGrid.ColCount;
  Result := S_OK;
end;

function TAccessibilityStringGridProvider.Get_CanSelectMultiple(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridProvider.Get_IsSelectionRequired(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridProvider.Get_RowCount(out aRetVal: Integer): HResult;
begin
  aRetVal := 0;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGrid.RowCount;
  Result := S_OK;
end;

function TAccessibilityStringGridProvider.GetSelection(out aRetVal: PSafeArray): HResult;
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

function TAccessibilityStringGridProvider.GridOwnsFocus: Boolean;
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

function TAccessibilityStringGridProvider.IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
var
  lCellRect: TRect;
begin
  Result := False;
  if (fGrid = nil) or (aCol < 0) or (aCol >= fGrid.ColCount) or (aRow < 0) or (aRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lCellRect := fGrid.CellRect(aCol, aRow);
  Result := IsVisibleCellRect(lCellRect);
end;

procedure TAccessibilityStringGridProvider.PrepareChildrenForNavigation;
begin
  inherited PrepareChildrenForNavigation;
  RefreshVisibleCells;
end;

class function TAccessibilityVclAdapters.CreateDefaultRegistry: IAccessibilityAdapterRegistry;
begin
  Result := TAccessibilityAdapterRegistry.Create;
  RegisterDefaultAdapters(Result);
end;

class procedure TAccessibilityVclAdapters.RegisterDefaultAdapters(const aRegistry: IAccessibilityAdapterRegistry);
begin
  if aRegistry = nil then
  begin
    raise EArgumentException.Create('Adapter registry must not be nil.');
  end;

  aRegistry.RegisterAdapter(TCustomLabel, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TSpeedButton, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TCustomPanel, TPanelAdapter.Create);
  aRegistry.RegisterAdapter(TGraphicControl, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TStringGrid, TStringGridAdapter.Create);
end;

class function TAccessibilityVclProviderBuilder.BuildForm(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry): IAccessibilityProviderNode;
begin
  Result := BuildForm(aForm, aRegistry, nil);
end;

class function TAccessibilityVclProviderBuilder.BuildForm(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
var
  lNextRuntimeId: Integer;
  lRegistry: IAccessibilityAdapterRegistry;
  lRootProvider: IAccessibilityVclRootProvider;
  lTree: IAccessibilityScanTree;
begin
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  lRegistry := aRegistry;
  if lRegistry = nil then
  begin
    lRegistry := TAccessibilityVclAdapters.CreateDefaultRegistry;
  end;

  lTree := TAccessibilityScanner.ScanForm(aForm, lRegistry);
  Result := TAccessibilityVclFormProviderRoot.Create(aForm, aApi) as IAccessibilityProviderNode;
  Result.SetProperty(UIA_NamePropertyId, lTree.Root.Name);
  Result.SetProperty(UIA_ControlTypePropertyId, UIA_PaneControlTypeId);
  Result.SetProperty(UIA_ClassNamePropertyId, aForm.ClassName);
  Result.SetProperty(UIA_HelpTextPropertyId, lTree.Root.HelpText);

  lNextRuntimeId := 1;
  Supports(Result, IAccessibilityVclRootProvider, lRootProvider);
  AddProviderChildren(Result, lTree.Root, lRegistry, lNextRuntimeId, aApi, lRootProvider);
end;

end.
