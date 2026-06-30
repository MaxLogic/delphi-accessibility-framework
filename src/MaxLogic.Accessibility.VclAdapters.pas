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

  IAccessibilityVclControlProviderInfo = interface
    ['{2A10CDB2-64DC-4553-A53C-A9F6345E6F74}']
    function Control: TControl;
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
  System.Actions, System.Classes, System.Diagnostics, System.Generics.Collections, System.Math, System.SysUtils,
  System.Types, System.TypInfo, Winapi.ActiveX, Winapi.Messages, Winapi.Windows, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.Text,
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

  TNamedContainerAdapter = class(TInterfacedObject, IAccessibilityControlAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
  end;

  TStringGridAdapter = class(TInterfacedObject, IAccessibilityControlAdapter, IAccessibilityVclProviderAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TMemoAdapter = class(TInterfacedObject, IAccessibilityControlAdapter, IAccessibilityVclProviderAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TListBoxAdapter = class(TInterfacedObject, IAccessibilityControlAdapter, IAccessibilityVclProviderAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TStatusBarAdapter = class(TInterfacedObject, IAccessibilityControlAdapter, IAccessibilityVclProviderAdapter)
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

  TAccessibilityVclControlProvider = class(TAccessibilityProviderNode, IAccessibilityVclControlProviderInfo,
    IInvokeProvider, IToggleProvider, IValueProvider, ISelectionItemProvider)
  private
    fControl: TControl;
    class function CheckBoxToggleState(aControl: TControl): ToggleState; static;
    class function ControlSupportsToggle(aControl: TControl): Boolean; static;
    class function SpeedButtonSupportsToggle(aButton: TSpeedButton): Boolean; static;
    class function SupportsValue(aControl: TControl): Boolean; static;
    class function ToggleCheckBox(aControl: TControl): Boolean; static;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aControl: TControl; const aRuntimeId: array of Integer; aControlTypeId: Integer;
      const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
    function AddToSelection: HResult; stdcall;
    function Control: TControl;
    function Get_IsReadOnly(out aRetVal: BOOL): HResult; stdcall;
    function Get_IsSelected(out aRetVal: BOOL): HResult; stdcall;
    function Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_ToggleState(out aRetVal: ToggleState): HResult; stdcall;
    function Get_Value(out aRetVal: WideString): HResult; stdcall;
    function Invoke: HResult; stdcall;
    function RemoveFromSelection: HResult; stdcall;
    function Select: HResult; stdcall;
    function SetValue(aValue: PWideChar): HResult; stdcall;
    function Toggle: HResult; stdcall;
  end;

  TAccessibilityMemoProvider = class;
  TAccessibilityListBoxProvider = class;

  TAccessibilityMemoLineProvider = class(TAccessibilityProviderNode)
  private
    fLine: Integer;
    fMemo: TCustomMemo;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aMemo: TCustomMemo; aLine: Integer; const aRuntimeId: array of Integer;
      const aApi: IAccessibilityUiaApi);
  end;

  TAccessibilityMemoProvider = class(TAccessibilityVclControlProvider, IRawElementProviderFragmentRoot)
  private
    fLines: TDictionary<Integer, IAccessibilityProviderNode>;
    fMemo: TCustomMemo;
    fRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    function EnsureLineProvider(aLine: Integer): IAccessibilityProviderNode;
    function LineProvider(aLine: Integer): IAccessibilityProviderNode;
  protected
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create(aMemo: TCustomMemo; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    destructor Destroy; override;
    function ElementProviderFromPoint(aX: Double; aY: Double; out aRetVal: IRawElementProviderFragment):
      HResult; stdcall;
    function GetFocus(out aRetVal: IRawElementProviderFragment): HResult; stdcall;
  end;

  TAccessibilityListBoxItemProvider = class(TAccessibilityProviderNode, ISelectionItemProvider)
  private
    fIndex: Integer;
    fListBox: TCustomListBox;
    function IsVisibleItem: Boolean;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aListBox: TCustomListBox; aIndex: Integer; const aRuntimeId: array of Integer;
      const aApi: IAccessibilityUiaApi);
    function AddToSelection: HResult; stdcall;
    function Get_IsSelected(out aRetVal: BOOL): HResult; stdcall;
    function Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function RemoveFromSelection: HResult; stdcall;
    function Select: HResult; stdcall;
  end;

  TAccessibilityListBoxProvider = class(TAccessibilityVclControlProvider, IRawElementProviderFragmentRoot,
    ISelectionProvider)
  private
    fItems: TDictionary<Integer, IAccessibilityProviderNode>;
    fItemRawTexts: TDictionary<Integer, string>;
    fListBox: TCustomListBox;
    fPreparedClientHeight: Integer;
    fPreparedClientWidth: Integer;
    fPreparedFocusedIndex: Integer;
    fPreparedHandle: HWND;
    fPreparedItemCount: Integer;
    fPreparedItemHeight: Integer;
    fPreparedTopIndex: Integer;
    fPreparedValid: Boolean;
    fRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    function ChildrenPreparationIsCurrent: Boolean;
    function CreateSelectionArray(const aProviders: TArray<IRawElementProviderSimple>): PSafeArray;
    function EnsureItemProvider(aIndex: Integer): IAccessibilityProviderNode;
    function ItemProvider(aIndex: Integer): IAccessibilityProviderNode;
    function ListBoxOwnsFocus: Boolean;
    procedure RememberChildrenPreparation;
  protected
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create(aListBox: TCustomListBox; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    destructor Destroy; override;
    function ElementProviderFromPoint(aX: Double; aY: Double; out aRetVal: IRawElementProviderFragment):
      HResult; stdcall;
    function GetFocus(out aRetVal: IRawElementProviderFragment): HResult; stdcall;
    function Get_CanSelectMultiple(out aRetVal: BOOL): HResult; stdcall;
    function Get_IsSelectionRequired(out aRetVal: BOOL): HResult; stdcall;
    function GetSelection(out aRetVal: PSafeArray): HResult; stdcall;
  end;

  TAccessibilityStatusBarProvider = class(TAccessibilityProviderNode, IAccessibilityVclControlProviderInfo)
  private
    fHelpText: string;
    fStatusBar: TCustomStatusBar;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aStatusBar: TCustomStatusBar; const aRuntimeId: array of Integer; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    function Control: TControl;
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

  TAccessibilityStringGridRowProvider = class(TAccessibilityProviderNode, IGridItemProvider, ISelectionItemProvider)
  private
    fGrid: TStringGrid;
    fGridProvider: TAccessibilityStringGridProvider;
    fRow: Integer;
    function IsVisibleRow: Boolean;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aGridProvider: TAccessibilityStringGridProvider; aGrid: TStringGrid; aRow: Integer;
      const aRuntimeId: array of Integer; const aApi: IAccessibilityUiaApi);
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

  TAccessibilityStringGridProvider = class(TAccessibilityProviderNode, IAccessibilityVclControlProviderInfo,
    IRawElementProviderFragmentRoot, IGridProvider, ISelectionProvider)
  private
    fCells: TDictionary<Int64, IAccessibilityProviderNode>;
    fGrid: TStringGrid;
    fRows: TDictionary<Integer, IAccessibilityProviderNode>;
    fRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    procedure BuildVisibleCells;
    function CellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    procedure ClearRowProviders;
    function CreateSelectionArray(const aProvider: IRawElementProviderSimple): PSafeArray;
    function EnsureCellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function EnsureRowProvider(aRow: Integer): IAccessibilityProviderNode;
    function GridOwnsFocus: Boolean;
    function IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
    procedure RefreshVisibleCells;
    procedure RefreshVisibleRows;
    function RowProvider(aRow: Integer): IAccessibilityProviderNode;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create(aGrid: TStringGrid; aRuntimeId: Integer; const aName: string; const aHelpText: string;
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
  end;

function NativeWindowHandleForControl(aControl: TControl): HWND;
begin
  Result := 0;
  if aControl is TWinControl then
  begin
    Result := TWinControl(aControl).Handle;
  end;
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

function ControlIsInActiveVisibleTree(aControl: TControl): Boolean; forward;

function PointFromMessageResult(aValue: LRESULT): TPoint;
var
  lRawValue: Int64;
  lSignedValue: Int64;
  lX: Integer;
  lY: Integer;
begin
  lSignedValue := Int64(aValue);
  lRawValue := lSignedValue and $00000000FFFFFFFF;
  lX := Integer(lRawValue and $FFFF);
  if lX > High(Smallint) then
  begin
    Dec(lX, $10000);
  end;

  lY := Integer((lRawValue shr 16) and $FFFF);
  if lY > High(Smallint) then
  begin
    Dec(lY, $10000);
  end;

  Result := Point(lX, lY);
end;

function TextLineHeight(aControl: TCustomMemo): Integer;
var
  lDc: HDC;
  lFont: HFONT;
  lMetrics: TTextMetric;
  lOldFont: HGDIOBJ;
begin
  Result := 16;
  if aControl = nil then
  begin
    Exit;
  end;

  lDc := GetDC(aControl.Handle);
  lOldFont := 0;
  try
    lFont := SendMessage(aControl.Handle, WM_GETFONT, 0, 0);
    if lFont <> 0 then
    begin
      lOldFont := SelectObject(lDc, lFont);
    end;
    if GetTextMetrics(lDc, lMetrics) then
    begin
      Result := Max(1, lMetrics.tmHeight + lMetrics.tmExternalLeading);
    end;
  finally
    if lOldFont <> 0 then
    begin
      SelectObject(lDc, lOldFont);
    end;
    ReleaseDC(aControl.Handle, lDc);
  end;
end;

function MemoLineText(aMemo: TCustomMemo; aLine: Integer): string;
var
  lCharIndex: LRESULT;
  lLineCount: LRESULT;
  lLineLength: LRESULT;
begin
  Result := '';
  if (aMemo = nil) or (aLine < 0) then
  begin
    Exit;
  end;

  lLineCount := aMemo.Perform(EM_GETLINECOUNT, 0, 0);
  if aLine >= lLineCount then
  begin
    Exit;
  end;

  lCharIndex := aMemo.Perform(EM_LINEINDEX, aLine, 0);
  if lCharIndex < 0 then
  begin
    Exit;
  end;

  lLineLength := aMemo.Perform(EM_LINELENGTH, lCharIndex, 0);
  Result := TAccessibilityText.Clean(Copy(aMemo.Text, Integer(lCharIndex) + 1, Integer(lLineLength)));
end;

function MemoLineIndexAtPoint(aMemo: TCustomMemo; const aClientPoint: TPoint): Integer;
var
  lCharIndex: LRESULT;
  lCharIndexParam: WPARAM;
  lRawCharIndex: Int64;
  lSignedCharIndex: Int64;
  lLineCount: LRESULT;
begin
  Result := -1;
  if (aMemo = nil) or not PtInRect(Rect(0, 0, aMemo.ClientWidth, aMemo.ClientHeight), aClientPoint) then
  begin
    Exit;
  end;

  lCharIndex := aMemo.Perform(EM_CHARFROMPOS, 0, MakeLong(aClientPoint.X, aClientPoint.Y));
  if lCharIndex < 0 then
  begin
    Exit;
  end;

  lSignedCharIndex := Int64(lCharIndex);
  lRawCharIndex := lSignedCharIndex and $00000000FFFFFFFF;
  lCharIndexParam := WPARAM(lRawCharIndex and $FFFF);
  Result := aMemo.Perform(EM_LINEFROMCHAR, lCharIndexParam, 0);
  lLineCount := aMemo.Perform(EM_GETLINECOUNT, 0, 0);
  if (Result < 0) or (Result >= lLineCount) then
  begin
    Result := -1;
  end;
end;

function MemoLineBounds(aMemo: TCustomMemo; aLine: Integer; out aRect: TRect): Boolean;
var
  lCharIndex: LRESULT;
  lLineCount: LRESULT;
  lLinePoint: TPoint;
begin
  aRect := TRect.Empty;
  Result := False;
  if (aMemo = nil) or (aLine < 0) or not ControlIsInActiveVisibleTree(aMemo) then
  begin
    Exit;
  end;

  lLineCount := aMemo.Perform(EM_GETLINECOUNT, 0, 0);
  if aLine >= lLineCount then
  begin
    Exit;
  end;

  lCharIndex := aMemo.Perform(EM_LINEINDEX, aLine, 0);
  if lCharIndex < 0 then
  begin
    Exit;
  end;

  lLinePoint := PointFromMessageResult(aMemo.Perform(EM_POSFROMCHAR, lCharIndex, 0));
  aRect := Rect(0, lLinePoint.Y, aMemo.ClientWidth, lLinePoint.Y + TextLineHeight(aMemo));
  Result := (aRect.Width > 0) and (aRect.Height > 0);
end;

function ListBoxItemText(aListBox: TCustomListBox; aIndex: Integer): string;
begin
  Result := '';
  if (aListBox <> nil) and (aIndex >= 0) and (aIndex < aListBox.Items.Count) then
  begin
    TAccessibilityDiagnostics.RecordListBoxItemTextProbe;
    Result := TAccessibilityText.Clean(aListBox.Items[aIndex]);
  end;
end;

function ListBoxRawItemText(aListBox: TCustomListBox; aIndex: Integer): string;
begin
  Result := '';
  if (aListBox <> nil) and (aIndex >= 0) and (aIndex < aListBox.Items.Count) then
  begin
    Result := aListBox.Items[aIndex];
  end;
end;

function ListBoxItemRectIsVisible(aListBox: TCustomListBox; const aItemRect: TRect): Boolean;
begin
  Result := (aListBox <> nil) and (aItemRect.Width > 0) and (aItemRect.Height > 0) and
    aItemRect.IntersectsWith(Rect(0, 0, aListBox.ClientWidth, aListBox.ClientHeight));
end;

function ListBoxItemIsVisible(aListBox: TCustomListBox; aIndex: Integer): Boolean;
var
  lItemRect: TRect;
begin
  Result := False;
  if (aListBox = nil) or (aIndex < 0) or (aIndex >= aListBox.Items.Count) or
    not ControlIsInActiveVisibleTree(aListBox) then
  begin
    Exit;
  end;

  lItemRect := aListBox.ItemRect(aIndex);
  Result := ListBoxItemRectIsVisible(aListBox, lItemRect);
end;

function ListBoxItemIndexExists(aListBox: TCustomListBox; aIndex: Integer): Boolean;
begin
  Result := (aListBox <> nil) and (aIndex >= 0) and (aIndex < aListBox.Items.Count);
end;

function ListBoxWindowItemHeight(aListBox: TCustomListBox): Integer;
var
  lIndex: Integer;
begin
  Result := 0;
  if (aListBox = nil) or not aListBox.HandleAllocated or (aListBox.Items.Count = 0) then
  begin
    Exit;
  end;

  lIndex := EnsureRange(aListBox.TopIndex, 0, Pred(aListBox.Items.Count));
  Result := Integer(aListBox.Perform(LB_GETITEMHEIGHT, lIndex, 0));
  if Result < 0 then
  begin
    Result := 0;
  end;
end;

function ListBoxOwnsKeyboardFocus(aListBox: TCustomListBox): Boolean;
var
  lActiveControl: TWinControl;
  lForm: TCustomForm;
begin
  Result := False;
  if aListBox = nil then
  begin
    Exit;
  end;

  if aListBox.Focused then
  begin
    Exit(True);
  end;

  lForm := GetParentForm(aListBox);
  if lForm = nil then
  begin
    Exit;
  end;

  lActiveControl := lForm.ActiveControl;
  Result := (lActiveControl = aListBox) or ((lActiveControl <> nil) and aListBox.ContainsControl(lActiveControl));
end;

function GridUsesRowSelection(aGrid: TStringGrid): Boolean;
begin
  Result := (aGrid <> nil) and (goRowSelect in aGrid.Options);
end;

function IsVisibleCellRect(const aCellRect: TRect): Boolean;
begin
  Result := (aCellRect.Width > 0) and (aCellRect.Height > 0);
end;

function GridCellIsVisible(aGrid: TStringGrid; aCol: Integer; aRow: Integer): Boolean;
var
  lCellRect: TRect;
begin
  Result := False;
  if (aGrid = nil) or (aCol < 0) or (aCol >= aGrid.ColCount) or (aRow < 0) or (aRow >= aGrid.RowCount) then
  begin
    Exit;
  end;

  lCellRect := aGrid.CellRect(aCol, aRow);
  Result := IsVisibleCellRect(lCellRect);
end;

function GridRowHasVisibleHeader(aGrid: TStringGrid; aRow: Integer): Boolean;
var
  lCol: Integer;
  lHeaderRow: Integer;
begin
  Result := False;
  if (aGrid = nil) or (aGrid.FixedRows <= 0) or (aRow < aGrid.FixedRows) then
  begin
    Exit;
  end;

  lHeaderRow := Pred(aGrid.FixedRows);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    if GridCellIsVisible(aGrid, lCol, aRow) and
      (TAccessibilityText.Clean(aGrid.Cells[lCol, lHeaderRow]) <> '') then
    begin
      Exit(True);
    end;
  end;
end;

function GridRowAccessibleText(aGrid: TStringGrid; aRow: Integer): string;
var
  lCellText: string;
  lCol: Integer;
  lHeaderRow: Integer;
  lHeaderText: string;
  lUseHeaderFormat: Boolean;
begin
  Result := '';
  if (aGrid = nil) or (aRow < 0) or (aRow >= aGrid.RowCount) then
  begin
    Exit;
  end;

  lUseHeaderFormat := GridRowHasVisibleHeader(aGrid, aRow);
  lHeaderRow := Pred(aGrid.FixedRows);
  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    if GridCellIsVisible(aGrid, lCol, aRow) then
    begin
      lCellText := TAccessibilityText.Clean(aGrid.Cells[lCol, aRow]);
      if lCellText <> '' then
      begin
        if Result <> '' then
        begin
          if lUseHeaderFormat then
          begin
            Result := Result + sLineBreak + sLineBreak;
          end else begin
            Result := Result + ', ';
          end;
        end;
        if lUseHeaderFormat then
        begin
          lHeaderText := TAccessibilityText.Clean(aGrid.Cells[lCol, lHeaderRow]);
          if lHeaderText <> '' then
          begin
            lCellText := lHeaderText + ': ' + lCellText;
          end;
        end;
        Result := Result + lCellText;
      end;
    end;
  end;
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

function StatusBarAccessibleText(aStatusBar: TCustomStatusBar): string;
var
  i: Integer;
  lPanelText: string;
begin
  Result := '';
  if aStatusBar = nil then
  begin
    Exit;
  end;

  if aStatusBar.SimplePanel or (aStatusBar.Panels.Count = 0) then
  begin
    Exit(TAccessibilityText.Clean(aStatusBar.SimpleText));
  end;

  for i := 0 to Pred(aStatusBar.Panels.Count) do
  begin
    lPanelText := TAccessibilityText.Clean(aStatusBar.Panels[i].Text);
    if lPanelText <> '' then
    begin
      if Result <> '' then
      begin
        Result := Result + ' ';
      end;
      Result := Result + lPanelText;
    end;
  end;
end;

function ReadBooleanProperty(aObject: TObject; const aPropertyName: string): Boolean;
var
  lPropInfo: PPropInfo;
begin
  Result := False;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then
  begin
    Result := GetOrdProp(aObject, lPropInfo) <> 0;
  end;
end;

function WriteBooleanProperty(aObject: TObject; const aPropertyName: string; aValue: Boolean): Boolean;
var
  lPropInfo: PPropInfo;
begin
  Result := False;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then
  begin
    SetOrdProp(aObject, lPropInfo, Ord(aValue));
    Result := True;
  end;
end;

function ReadOrdinalProperty(aObject: TObject; const aPropertyName: string; out aValue: Integer): Boolean;
var
  lPropInfo: PPropInfo;
begin
  aValue := 0;
  Result := False;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then
  begin
    aValue := GetOrdProp(aObject, lPropInfo);
    Result := True;
  end;
end;

function WriteStringProperty(aObject: TObject; const aPropertyName: string; const aValue: string): Boolean;
var
  lPropInfo: PPropInfo;
begin
  Result := False;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    SetStrProp(aObject, lPropInfo, aValue);
    Result := True;
  end;
end;

function WriteOrdinalProperty(aObject: TObject; const aPropertyName: string; aValue: Integer): Boolean;
var
  lPropInfo: PPropInfo;
begin
  Result := False;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then
  begin
    SetOrdProp(aObject, lPropInfo, aValue);
    Result := True;
  end;
end;

function ControlIsInActiveVisibleTree(aControl: TControl): Boolean;
var
  lControl: TControl;
  lTabSheet: TTabSheet;
begin
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

function GridRowIsVisible(aGrid: TStringGrid; aRow: Integer): Boolean;
var
  lCol: Integer;
begin
  Result := False;
  if (aGrid = nil) or not ControlIsInActiveVisibleTree(aGrid) or (aRow < 0) or (aRow >= aGrid.RowCount) then
  begin
    Exit;
  end;

  for lCol := 0 to Pred(aGrid.ColCount) do
  begin
    if GridCellIsVisible(aGrid, lCol, aRow) then
    begin
      Exit(True);
    end;
  end;
end;

function TabSheetHeaderIsVisible(aTabSheet: TTabSheet): Boolean;
var
  lTabRect: TRect;
begin
  Result := False;
  if (aTabSheet = nil) or (aTabSheet.PageControl = nil) or (aTabSheet.TabIndex < 0) or
    not ControlIsInActiveVisibleTree(aTabSheet.PageControl) then
  begin
    Exit;
  end;

  lTabRect := aTabSheet.PageControl.TabRect(aTabSheet.TabIndex);
  Result := IsVisibleCellRect(lTabRect);
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

  lControl := TWinControl(aControl);
  if not lControl.HandleAllocated or not IsWindowVisible(lControl.Handle) then
  begin
    Exit;
  end;

  lWindow := FindVCLWindow(aPoint);
  Result := (lWindow = lControl) or ((lWindow <> nil) and lControl.ContainsControl(lWindow));
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
  if aControl is TRadioButton then
  begin
    Exit(UIA_RadioButtonControlTypeId);
  end;

  if aControl is TCustomCheckBox then
  begin
    Exit(UIA_CheckBoxControlTypeId);
  end;

  if aControl is TCustomComboBox then
  begin
    Exit(UIA_ComboBoxControlTypeId);
  end;

  if aControl is TCustomListBox then
  begin
    Exit(UIA_ListControlTypeId);
  end;

  if aControl is TCustomStatusBar then
  begin
    Exit(UIA_StatusBarControlTypeId);
  end;

  if aControl is TCustomEdit then
  begin
    Exit(UIA_EditControlTypeId);
  end;

  if (aControl is TSpeedButton) or (aControl is TCustomButton) or (aControl is TToolButton) then
  begin
    Exit(UIA_ButtonControlTypeId);
  end;

  if aControl is TToolBar then
  begin
    Exit(UIA_ToolBarControlTypeId);
  end;

  if aControl is TPageControl then
  begin
    Exit(UIA_TabControlTypeId);
  end;

  if aControl is TCustomGroupBox then
  begin
    Exit(UIA_GroupControlTypeId);
  end;

  if aControl is TCustomPanel then
  begin
    Exit(UIA_PaneControlTypeId);
  end;

  if aControl is TTabSheet then
  begin
    Exit(UIA_TabItemControlTypeId);
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

function TNamedContainerAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if HasUsefulExplicitText(aControl) then
  begin
    Exit(TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText));
  end;

  if (aControl is TWinControl) and HasAccessibleDescendant(TWinControl(aControl)) then
  begin
    Exit(TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText));
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

function TMemoAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if (aControl is TCustomMemo) and ((aFallback.Name <> '') or (aFallback.HelpText <> '') or
    (TCustomMemo(aControl).Lines.Count > 0)) then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TMemoAdapter.CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Result := TAccessibilityMemoProvider.Create(TCustomMemo(aControl), aRuntimeId, aName, aHelpText, aApi) as
    IAccessibilityProviderNode;
end;

function TListBoxAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if (aControl is TCustomListBox) and ((aFallback.Name <> '') or (aFallback.HelpText <> '') or
    (TCustomListBox(aControl).Items.Count > 0)) then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TListBoxAdapter.CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Result := TAccessibilityListBoxProvider.Create(TCustomListBox(aControl), aRuntimeId, aName, aHelpText, aApi) as
    IAccessibilityProviderNode;
end;

function TStatusBarAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
var
  lStatusText: string;
begin
  if aControl is TCustomStatusBar then
  begin
    lStatusText := StatusBarAccessibleText(TCustomStatusBar(aControl));
    if lStatusText <> '' then
    begin
      Exit(TAccessibilityControlInfo.Include(aControl, lStatusText, aFallback.HelpText));
    end;

    if (aFallback.Name <> '') or (aFallback.HelpText <> '') then
    begin
      Exit(TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText));
    end;
  end;

  Result := TAccessibilityControlInfo.Omit;
end;

function TStatusBarAdapter.CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Result := TAccessibilityStatusBarProvider.Create(TCustomStatusBar(aControl), [aRuntimeId], aHelpText, aApi) as
    IAccessibilityProviderNode;
end;

function TryFindTabHeaderProviderFromPoint(const aFragment: IRawElementProviderFragment; aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): Boolean;
var
  lChild: IRawElementProviderFragment;
  lControl: TControl;
  lInfo: IAccessibilityVclControlProviderInfo;
  lNextChild: IRawElementProviderFragment;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lScreenRect: TRect;
  lTabRect: TRect;
  lTabSheet: TTabSheet;
begin
  aProvider := nil;
  Result := False;
  if aFragment = nil then
  begin
    Exit;
  end;

  if Supports(aFragment, IAccessibilityVclControlProviderInfo, lInfo) then
  begin
    lControl := lInfo.Control;
    if lControl is TTabSheet then
    begin
      lTabSheet := TTabSheet(lControl);
      lPageControl := lTabSheet.PageControl;
      if TabSheetHeaderIsVisible(lTabSheet) then
      begin
        lTabRect := lPageControl.TabRect(lTabSheet.TabIndex);
        lPoint := lPageControl.ClientToScreen(lTabRect.TopLeft);
        lScreenRect := Rect(lPoint.X, lPoint.Y, lPoint.X + lTabRect.Width, lPoint.Y + lTabRect.Height);
        if PtInRect(lScreenRect, Point(Integer(Round(aX)), Integer(Round(aY)))) then
        begin
          aProvider := aFragment;
          Exit(True);
        end;
      end;
    end;
  end;

  if aFragment.Navigate(NavigateDirection_FirstChild, lChild) <> S_OK then
  begin
    Exit;
  end;

  while lChild <> nil do
  begin
    if TryFindTabHeaderProviderFromPoint(lChild, aX, aY, aProvider) then
    begin
      Exit(True);
    end;

    lNextChild := nil;
    if lChild.Navigate(NavigateDirection_NextSibling, lNextChild) <> S_OK then
    begin
      Exit;
    end;
    lChild := lNextChild;
  end;
end;

function UiaRectContainsPoint(const aRect: UiaRect; aX: Double; aY: Double): Boolean;
begin
  Result := (aX >= aRect.Left) and (aY >= aRect.Top) and (aX < aRect.Left + aRect.Width) and
    (aY < aRect.Top + aRect.Height);
end;

function TryFindVisibleControlProviderFromPoint(const aFragment: IRawElementProviderFragment; aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): Boolean;
var
  lBounds: UiaRect;
  lChild: IRawElementProviderFragment;
  lControl: TControl;
  lInfo: IAccessibilityVclControlProviderInfo;
  lNextChild: IRawElementProviderFragment;
begin
  aProvider := nil;
  Result := False;
  if aFragment = nil then
  begin
    Exit;
  end;

  if aFragment.Navigate(NavigateDirection_FirstChild, lChild) = S_OK then
  begin
    while lChild <> nil do
    begin
      if TryFindVisibleControlProviderFromPoint(lChild, aX, aY, aProvider) then
      begin
        Exit(True);
      end;

      lNextChild := nil;
      if lChild.Navigate(NavigateDirection_NextSibling, lNextChild) <> S_OK then
      begin
        Break;
      end;
      lChild := lNextChild;
    end;
  end;

  if Supports(aFragment, IAccessibilityVclControlProviderInfo, lInfo) then
  begin
    lControl := lInfo.Control;
    if ControlIsInActiveVisibleTree(lControl) and (aFragment.Get_BoundingRectangle(lBounds) = S_OK) and
      UiaRectContainsPoint(lBounds, aX, aY) then
    begin
      aProvider := aFragment;
      Exit(True);
    end;
  end;
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
  if TryFindTabHeaderProviderFromPoint(FragmentProvider, aX, aY, aProvider) then
  begin
    Exit(S_OK);
  end;

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

  if TryFindVisibleControlProviderFromPoint(FragmentProvider, aX, aY, aProvider) then
  begin
    Exit(S_OK);
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
  inherited CreateNode(aRuntimeId, NativeWindowHandleForControl(aControl), aApi, aControl);
  fControl := aControl;
  SetProperty(UIA_NamePropertyId, aName);
  SetProperty(UIA_ControlTypePropertyId, aControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aControl.ClassName);
  SetProperty(UIA_HelpTextPropertyId, aHelpText);
end;

function TAccessibilityVclControlProvider.Control: TControl;
begin
  Result := fControl;
end;

function TAccessibilityVclControlProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lBottom: Integer;
  lLeft: Integer;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lRight: Integer;
  lTabPoint: TPoint;
  lTabRect: TRect;
  lTabSheet: TTabSheet;
  lTop: Integer;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fControl = nil) or IsDisconnected then
  begin
    Exit;
  end;

  if fControl is TTabSheet then
  begin
    lTabSheet := TTabSheet(fControl);
    lPageControl := lTabSheet.PageControl;
    if not TabSheetHeaderIsVisible(lTabSheet) then
    begin
      Exit;
    end;

    lTabRect := lPageControl.TabRect(lTabSheet.TabIndex);
    if not IsVisibleCellRect(lTabRect) then
    begin
      Exit;
    end;

    lTabPoint := lPageControl.ClientToScreen(lTabRect.TopLeft);
    lLeft := lTabPoint.X;
    lTop := lTabPoint.Y;
    lRight := lTabPoint.X + lTabRect.Width;
    lBottom := lTabPoint.Y + lTabRect.Height;

    aValue.Left := lLeft;
    aValue.Top := lTop;
    aValue.Width := lRight - lLeft;
    aValue.Height := lBottom - lTop;
    Exit(True);
  end;

  if not ControlIsInActiveVisibleTree(fControl) then
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
  if IsDisconnected then
  begin
    Exit;
  end;

  if (aPatternId = UIA_ValuePatternId) and SupportsValue(fControl) then
  begin
    Exit(Self as IValueProvider);
  end;

  if (aPatternId = UIA_SelectionItemPatternId) and ((fControl is TTabSheet) or (fControl is TRadioButton)) then
  begin
    Exit(Self as ISelectionItemProvider);
  end;

  if (aPatternId = UIA_InvokePatternId) and
    ((fControl is TSpeedButton) or (fControl is TCustomButton) or (fControl is TToolButton)) then
  begin
    Exit(Self as IInvokeProvider);
  end;

  if (aPatternId = UIA_TogglePatternId) and ControlSupportsToggle(fControl) then
  begin
    Exit(Self as IToggleProvider);
  end;
end;

function TAccessibilityVclControlProvider.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant):
  Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_HasKeyboardFocusPropertyId:
      aValue := (fControl is TWinControl) and TWinControl(fControl).Focused;
    UIA_IsEnabledPropertyId:
      aValue := (fControl <> nil) and fControl.Enabled;
    UIA_IsKeyboardFocusablePropertyId:
      aValue := (fControl is TWinControl) and TWinControl(fControl).TabStop;
    UIA_IsOffscreenPropertyId:
      if fControl is TTabSheet then
      begin
        aValue := not TabSheetHeaderIsVisible(TTabSheet(fControl));
      end else begin
        aValue := not ControlIsInActiveVisibleTree(fControl);
      end;
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TAccessibilityVclControlProvider.AddToSelection: HResult;
begin
  Result := Select;
end;

function TAccessibilityVclControlProvider.Get_IsReadOnly(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected or not SupportsValue(fControl) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := ReadBooleanProperty(fControl, 'ReadOnly');
  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Get_IsSelected(out aRetVal: BOOL): HResult;
var
  lTabSheet: TTabSheet;
begin
  aRetVal := False;
  if IsDisconnected or not ((fControl is TTabSheet) or (fControl is TRadioButton)) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if fControl is TRadioButton then
  begin
    aRetVal := ReadBooleanProperty(fControl, 'Checked');
    Exit(S_OK);
  end;

  lTabSheet := TTabSheet(fControl);
  if (lTabSheet.PageControl <> nil) and (lTabSheet.PageControl.ActivePage = lTabSheet) then
  begin
    aRetVal := True;
  end;

  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult;
var
  lParent: IRawElementProviderFragment;
begin
  aRetVal := nil;
  if IsDisconnected or not ((fControl is TTabSheet) or (fControl is TRadioButton)) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if (Navigate(NavigateDirection_Parent, lParent) = S_OK) and (lParent <> nil) then
  begin
    aRetVal := lParent as IRawElementProviderSimple;
  end;

  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Get_ToggleState(out aRetVal: ToggleState): HResult;
begin
  aRetVal := ToggleState_Off;
  if IsDisconnected or not ControlSupportsToggle(fControl) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if fControl is TCustomCheckBox then
  begin
    aRetVal := CheckBoxToggleState(fControl);
  end else if TSpeedButton(fControl).Down then
  begin
    aRetVal := ToggleState_On;
  end;

  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Get_Value(out aRetVal: WideString): HResult;
begin
  aRetVal := '';
  if IsDisconnected or not SupportsValue(fControl) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := ReadStringProperty(fControl, 'Text');
  if (aRetVal = '') and (fControl is TCustomEdit) then
  begin
    aRetVal := ReadStringProperty(fControl, 'TextHint');
  end;
  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Invoke: HResult;
var
  lButton: TCustomButton;
  lSpeedButton: TSpeedButton;
  lToolButton: TToolButton;
begin
  if IsDisconnected or not ((fControl is TSpeedButton) or (fControl is TCustomButton) or
    (fControl is TToolButton)) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if not fControl.Enabled then
  begin
    Exit(S_OK);
  end;

  if fControl is TSpeedButton then
  begin
    lSpeedButton := TSpeedButton(fControl);
    lSpeedButton.Click;
  end else if fControl is TToolButton then
  begin
    lToolButton := TToolButton(fControl);
    lToolButton.Click;
  end else begin
    lButton := TCustomButton(fControl);
    lButton.Click;
  end;
  Result := S_OK;
end;

class function TAccessibilityVclControlProvider.CheckBoxToggleState(aControl: TControl): ToggleState;
var
  lState: Integer;
begin
  Result := ToggleState_Off;
  if not (aControl is TCustomCheckBox) then
  begin
    Exit;
  end;

  if ReadOrdinalProperty(aControl, 'State', lState) then
  begin
    case TCheckBoxState(lState) of
      cbChecked:
        Result := ToggleState_On;
      cbGrayed:
        Result := ToggleState_Indeterminate;
    else
      Result := ToggleState_Off;
    end;
    Exit;
  end;

  if ReadBooleanProperty(aControl, 'Checked') then
  begin
    Result := ToggleState_On;
  end;
end;

class function TAccessibilityVclControlProvider.ControlSupportsToggle(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomCheckBox) or ((aControl is TSpeedButton) and
    SpeedButtonSupportsToggle(TSpeedButton(aControl)));
end;

class function TAccessibilityVclControlProvider.SpeedButtonSupportsToggle(aButton: TSpeedButton): Boolean;
begin
  Result := (aButton <> nil) and ((aButton.GroupIndex <> 0) or aButton.AllowAllUp or aButton.Down);
end;

function TAccessibilityVclControlProvider.RemoveFromSelection: HResult;
begin
  if IsDisconnected or not ((fControl is TTabSheet) or (fControl is TRadioButton)) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := E_NOTIMPL;
end;

function TAccessibilityVclControlProvider.Select: HResult;
var
  lTabSheet: TTabSheet;
begin
  if IsDisconnected or not ((fControl is TTabSheet) or (fControl is TRadioButton)) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if fControl is TRadioButton then
  begin
    if not fControl.Enabled then
    begin
      Exit(S_OK);
    end;

    if WriteBooleanProperty(fControl, 'Checked', True) then
    begin
      Exit(S_OK);
    end;

    Exit(E_NOTIMPL);
  end;

  lTabSheet := TTabSheet(fControl);
  if (lTabSheet.PageControl = nil) or not TabSheetHeaderIsVisible(lTabSheet) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  lTabSheet.PageControl.ActivePage := lTabSheet;
  Result := S_OK;
end;

function TAccessibilityVclControlProvider.SetValue(aValue: PWideChar): HResult;
begin
  if IsDisconnected or not SupportsValue(fControl) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if ReadBooleanProperty(fControl, 'ReadOnly') then
  begin
    Exit(S_OK);
  end;

  if not WriteStringProperty(fControl, 'Text', string(aValue)) then
  begin
    Exit(E_NOTIMPL);
  end;

  Result := S_OK;
end;

class function TAccessibilityVclControlProvider.SupportsValue(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomEdit) or (aControl is TCustomComboBox);
end;

class function TAccessibilityVclControlProvider.ToggleCheckBox(aControl: TControl): Boolean;
var
  lAllowGrayed: Boolean;
  lNewState: TCheckBoxState;
  lState: Integer;
begin
  Result := False;
  if not (aControl is TCustomCheckBox) then
  begin
    Exit;
  end;

  if not ReadOrdinalProperty(aControl, 'State', lState) then
  begin
    Exit;
  end;

  lAllowGrayed := ReadBooleanProperty(aControl, 'AllowGrayed');
  case TCheckBoxState(lState) of
    cbUnchecked:
      if lAllowGrayed then
      begin
        lNewState := cbGrayed;
      end else begin
        lNewState := cbChecked;
      end;
    cbChecked:
      lNewState := cbUnchecked;
  else
    lNewState := cbChecked;
  end;

  Result := WriteOrdinalProperty(aControl, 'State', Ord(lNewState));
end;

function TAccessibilityVclControlProvider.Toggle: HResult;
var
  lButton: TSpeedButton;
begin
  if IsDisconnected or not ControlSupportsToggle(fControl) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if not fControl.Enabled then
  begin
    Exit(S_OK);
  end;

  if fControl is TCustomCheckBox then
  begin
    if ToggleCheckBox(fControl) then
    begin
      Exit(S_OK);
    end;

    Exit(E_NOTIMPL);
  end;

  lButton := TSpeedButton(fControl);
  if lButton.Down and not lButton.AllowAllUp then
  begin
    lButton.Down := True;
  end else begin
    lButton.Down := not lButton.Down;
  end;

  lButton.Click;
  Result := S_OK;
end;

constructor TAccessibilityMemoLineProvider.Create(aMemo: TCustomMemo; aLine: Integer; const aRuntimeId: array of Integer;
  const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, aMemo);
  fMemo := aMemo;
  fLine := aLine;
  SetProperty(UIA_ControlTypePropertyId, UIA_TextControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, 'TMemoLine');
end;

function TAccessibilityMemoLineProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lLineRect: TRect;
  lPoint: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if IsDisconnected or not MemoLineBounds(fMemo, fLine, lLineRect) then
  begin
    Exit;
  end;

  lPoint := fMemo.ClientToScreen(lLineRect.TopLeft);
  aValue.Left := lPoint.X;
  aValue.Top := lPoint.Y;
  aValue.Width := lLineRect.Width;
  aValue.Height := lLineRect.Height;
  Result := True;
end;

function TAccessibilityMemoLineProvider.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant):
  Boolean;
var
  lLineRect: TRect;
begin
  Result := True;
  case aPropertyId of
    UIA_NamePropertyId:
      aValue := MemoLineText(fMemo, fLine);
    UIA_IsOffscreenPropertyId:
      aValue := not MemoLineBounds(fMemo, fLine, lLineRect);
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

constructor TAccessibilityMemoProvider.Create(aMemo: TCustomMemo; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited Create(aMemo, [aRuntimeId], UIA_EditControlTypeId, aName, aHelpText, aApi);
  fMemo := aMemo;
  fRuntimeId := aRuntimeId;
  fUiaApi := aApi;
  fLines := TDictionary<Integer, IAccessibilityProviderNode>.Create;
end;

destructor TAccessibilityMemoProvider.Destroy;
begin
  fLines.Free;
  inherited Destroy;
end;

function TAccessibilityMemoProvider.ElementProviderFromPoint(aX: Double; aY: Double;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lClientPoint: TPoint;
  lLine: Integer;
  lLineProvider: IAccessibilityProviderNode;
begin
  aRetVal := nil;
  if IsDisconnected or (fMemo = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if not ControlIsInActiveVisibleTree(fMemo) or
    not WindowUnderPointMatchesControl(fMemo, Point(Integer(Round(aX)), Integer(Round(aY)))) then
  begin
    Exit(S_OK);
  end;

  lClientPoint := fMemo.ScreenToClient(Point(Integer(Round(aX)), Integer(Round(aY))));
  lLine := MemoLineIndexAtPoint(fMemo, lClientPoint);
  lLineProvider := EnsureLineProvider(lLine);
  if lLineProvider <> nil then
  begin
    aRetVal := lLineProvider.FragmentProvider;
  end;

  Result := S_OK;
end;

function TAccessibilityMemoProvider.EnsureLineProvider(aLine: Integer): IAccessibilityProviderNode;
begin
  Result := nil;
  if (fMemo = nil) or (aLine < 0) or (MemoLineText(fMemo, aLine) = '') then
  begin
    Exit;
  end;

  Result := LineProvider(aLine);
  if Result = nil then
  begin
    Result := TAccessibilityMemoLineProvider.Create(fMemo, aLine, [fRuntimeId, aLine], fUiaApi) as
      IAccessibilityProviderNode;
    AddChild(Result);
    fLines.Add(aLine, Result);
  end;
end;

function TAccessibilityMemoProvider.GetFocus(out aRetVal: IRawElementProviderFragment): HResult;
begin
  aRetVal := nil;
  if IsDisconnected or (fMemo = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityMemoProvider.LineProvider(aLine: Integer): IAccessibilityProviderNode;
begin
  if not fLines.TryGetValue(aLine, Result) then
  begin
    Result := nil;
  end else if Result.IsDisconnected then
  begin
    Result := nil;
  end;
end;

procedure TAccessibilityMemoProvider.PrepareChildrenForNavigation;
var
  lCaretLine: Integer;
  lCaretLineResult: LRESULT;
  lCreatedCount: Integer;
  lExistingProvider: IAccessibilityProviderNode;
  lFirstVisibleLine: Integer;
  lFirstVisibleLineResult: LRESULT;
  lLine: Integer;
  lLineCount: LRESULT;
  lLineCountInt: Integer;
  lLineProbeCount: Integer;
  lLastVisibleLine: Integer;
  lLineHeight: Integer;
  lMetricsEnabled: Boolean;
  lSelStart: Integer;
  lStopwatch: TStopwatch;
begin
  inherited PrepareChildrenForNavigation;
  if (fMemo = nil) or not ControlIsInActiveVisibleTree(fMemo) then
  begin
    Exit;
  end;

  lCreatedCount := 0;
  lLineProbeCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  lLineCount := fMemo.Perform(EM_GETLINECOUNT, 0, 0);
  if lLineCount <= 0 then
  begin
    Exit;
  end;
  lLineCountInt := lLineCount;

  lLineHeight := TextLineHeight(fMemo);
  lFirstVisibleLineResult := SendMessage(fMemo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
  if lFirstVisibleLineResult <= 0 then
  begin
    lFirstVisibleLine := 0;
  end else if lFirstVisibleLineResult >= lLineCountInt then
  begin
    lFirstVisibleLine := Pred(lLineCountInt);
  end else begin
    lFirstVisibleLine := Integer(lFirstVisibleLineResult);
  end;
  lLastVisibleLine := Min(Pred(lLineCountInt), lFirstVisibleLine + Max(1, fMemo.ClientHeight div lLineHeight) + 1);

  for lLine := lFirstVisibleLine to lLastVisibleLine do
  begin
    if lMetricsEnabled then
    begin
      Inc(lLineProbeCount);
      lExistingProvider := LineProvider(lLine);
      EnsureLineProvider(lLine);
      if (lExistingProvider = nil) and (LineProvider(lLine) <> nil) then
      begin
        Inc(lCreatedCount);
      end;
    end else begin
      EnsureLineProvider(lLine);
    end;
  end;

  lSelStart := fMemo.SelStart;
  if lSelStart >= 0 then
  begin
    lCaretLineResult := fMemo.Perform(EM_LINEFROMCHAR, WPARAM(lSelStart), 0);
    if (lCaretLineResult >= 0) and (lCaretLineResult < lLineCount) then
    begin
      lCaretLine := Integer(lCaretLineResult);
      if (lCaretLine < lFirstVisibleLine) or (lCaretLine > lLastVisibleLine) then
      begin
        if lMetricsEnabled then
        begin
          Inc(lLineProbeCount);
          lExistingProvider := LineProvider(lCaretLine);
          EnsureLineProvider(lCaretLine);
          if (lExistingProvider = nil) and (LineProvider(lCaretLine) <> nil) then
          begin
            Inc(lCreatedCount);
          end;
        end else begin
          EnsureLineProvider(lCaretLine);
        end;
      end;
    end;
  end;

  if lMetricsEnabled then
  begin
    TAccessibilityDiagnostics.RecordMemoPrepareChildren(lLineProbeCount, lCreatedCount, lStopwatch.ElapsedTicks);
  end;
end;

function TAccessibilityListBoxItemProvider.AddToSelection: HResult;
begin
  Result := Select;
end;

constructor TAccessibilityListBoxItemProvider.Create(aListBox: TCustomListBox; aIndex: Integer;
  const aRuntimeId: array of Integer; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, aListBox);
  fListBox := aListBox;
  fIndex := aIndex;
  SetProperty(UIA_ControlTypePropertyId, UIA_ListItemControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, 'TListBoxItem');
end;

function TAccessibilityListBoxItemProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lItemRect: TRect;
  lPoint: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if IsDisconnected or not IsVisibleItem then
  begin
    Exit;
  end;

  lItemRect := fListBox.ItemRect(fIndex);
  lPoint := fListBox.ClientToScreen(lItemRect.TopLeft);
  aValue.Left := lPoint.X;
  aValue.Top := lPoint.Y;
  aValue.Width := lItemRect.Width;
  aValue.Height := lItemRect.Height;
  Result := True;
end;

function TAccessibilityListBoxItemProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Result := nil;
  if IsDisconnected then
  begin
    Exit;
  end;

  if aPatternId = UIA_SelectionItemPatternId then
  begin
    Exit(Self as ISelectionItemProvider);
  end;
end;

function TAccessibilityListBoxItemProvider.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant):
  Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_NamePropertyId:
      aValue := ListBoxItemText(fListBox, fIndex);
    UIA_HasKeyboardFocusPropertyId:
      aValue := (fListBox <> nil) and (fListBox.ItemIndex = fIndex) and ListBoxOwnsKeyboardFocus(fListBox);
    UIA_IsOffscreenPropertyId:
      aValue := not IsVisibleItem;
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TAccessibilityListBoxItemProvider.Get_IsSelected(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected or not ListBoxItemIndexExists(fListBox, fIndex) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if fListBox.MultiSelect then
  begin
    aRetVal := fListBox.Selected[fIndex];
  end else begin
    aRetVal := fListBox.ItemIndex = fIndex;
  end;
  Result := S_OK;
end;

function TAccessibilityListBoxItemProvider.Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult;
var
  lParent: IRawElementProviderFragment;
begin
  aRetVal := nil;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if (Navigate(NavigateDirection_Parent, lParent) = S_OK) and (lParent <> nil) then
  begin
    aRetVal := lParent as IRawElementProviderSimple;
  end;
  Result := S_OK;
end;

function TAccessibilityListBoxItemProvider.IsVisibleItem: Boolean;
begin
  Result := ListBoxItemIsVisible(fListBox, fIndex);
end;

function TAccessibilityListBoxItemProvider.RemoveFromSelection: HResult;
begin
  if IsDisconnected or not ListBoxItemIndexExists(fListBox, fIndex) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if fListBox.MultiSelect then
  begin
    fListBox.Selected[fIndex] := False;
  end;
  Result := S_OK;
end;

function TAccessibilityListBoxItemProvider.Select: HResult;
begin
  if IsDisconnected or not ListBoxItemIndexExists(fListBox, fIndex) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  fListBox.ItemIndex := fIndex;
  if fListBox.MultiSelect then
  begin
    fListBox.Selected[fIndex] := True;
  end;
  Result := S_OK;
end;

constructor TAccessibilityListBoxProvider.Create(aListBox: TCustomListBox; aRuntimeId: Integer;
  const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited Create(aListBox, [aRuntimeId], UIA_ListControlTypeId, aName, aHelpText, aApi);
  fItems := TDictionary<Integer, IAccessibilityProviderNode>.Create;
  fItemRawTexts := TDictionary<Integer, string>.Create;
  fListBox := aListBox;
  fRuntimeId := aRuntimeId;
  fUiaApi := aApi;
end;

function TAccessibilityListBoxProvider.ChildrenPreparationIsCurrent: Boolean;
begin
  Result := fPreparedValid and (fListBox <> nil) and (fPreparedHandle = fListBox.Handle) and
    (fPreparedItemCount = fListBox.Items.Count) and (fPreparedTopIndex = fListBox.TopIndex) and
    (fPreparedFocusedIndex = fListBox.ItemIndex) and (fPreparedClientWidth = fListBox.ClientWidth) and
    (fPreparedClientHeight = fListBox.ClientHeight) and (fPreparedItemHeight = ListBoxWindowItemHeight(fListBox));
end;

function TAccessibilityListBoxProvider.CreateSelectionArray(
  const aProviders: TArray<IRawElementProviderSimple>): PSafeArray;
var
  i: Integer;
  lData: Pointer;
  lUnknown: IUnknown;
begin
  Result := SafeArrayCreateVector(VT_UNKNOWN, 0, Length(aProviders));
  if Result = nil then
  begin
    Exit;
  end;

  lData := nil;
  if (SafeArrayAccessData(Result, lData) <> S_OK) or (lData = nil) then
  begin
    SafeArrayDestroy(Result);
    Result := nil;
    Exit;
  end;

  try
    for i := 0 to High(aProviders) do
    begin
      lUnknown := aProviders[i] as IUnknown;
      PPointer(NativeUInt(lData) + NativeUInt(i) * SizeOf(Pointer))^ := Pointer(lUnknown);
      lUnknown._AddRef;
    end;
  finally
    SafeArrayUnaccessData(Result);
  end;
end;

destructor TAccessibilityListBoxProvider.Destroy;
begin
  fItems.Free;
  fItemRawTexts.Free;
  inherited Destroy;
end;

function TAccessibilityListBoxProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
begin
  Result := inherited DoGetPatternProvider(aPatternId);
  if Result <> nil then
  begin
    Exit;
  end;

  if (aPatternId = UIA_SelectionPatternId) and not IsDisconnected then
  begin
    Exit(Self as ISelectionProvider);
  end;
end;

function TAccessibilityListBoxProvider.ElementProviderFromPoint(aX: Double; aY: Double;
  out aRetVal: IRawElementProviderFragment): HResult;
var
  lClientPoint: TPoint;
  lIndex: Integer;
  lItem: IAccessibilityProviderNode;
begin
  aRetVal := nil;
  if IsDisconnected or (fListBox = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if not ControlIsInActiveVisibleTree(fListBox) or
    not WindowUnderPointMatchesControl(fListBox, Point(Integer(Round(aX)), Integer(Round(aY)))) then
  begin
    Exit(S_OK);
  end;

  lClientPoint := fListBox.ScreenToClient(Point(Integer(Round(aX)), Integer(Round(aY))));
  lIndex := fListBox.ItemAtPos(lClientPoint, True);
  lItem := EnsureItemProvider(lIndex);
  if lItem <> nil then
  begin
    aRetVal := lItem.FragmentProvider;
  end;

  Result := S_OK;
end;

function TAccessibilityListBoxProvider.EnsureItemProvider(aIndex: Integer): IAccessibilityProviderNode;
var
  lCachedRawText: string;
  lCreated: Boolean;
  lRawText: string;
begin
  Result := nil;
  if (fListBox = nil) or (aIndex < 0) or (aIndex >= fListBox.Items.Count) then
  begin
    Exit;
  end;

  lRawText := ListBoxRawItemText(fListBox, aIndex);
  lCreated := False;
  Result := ItemProvider(aIndex);
  if Result <> nil then
  begin
    if fItemRawTexts.TryGetValue(aIndex, lCachedRawText) and (lCachedRawText = lRawText) then
    begin
      TAccessibilityDiagnostics.RecordListBoxEnsureItemProvider(False);
      Exit;
    end;

    if ListBoxItemText(fListBox, aIndex) = '' then
    begin
      RemoveChildNode(Result, True);
      fItems.Remove(aIndex);
      fItemRawTexts.Remove(aIndex);
      Result := nil;
      Exit;
    end;

    fItemRawTexts.AddOrSetValue(aIndex, lRawText);
    TAccessibilityDiagnostics.RecordListBoxEnsureItemProvider(False);
    Exit;
  end;

  if ListBoxItemText(fListBox, aIndex) = '' then
  begin
    Exit;
  end;

  if Result = nil then
  begin
    lCreated := True;
    Result := TAccessibilityListBoxItemProvider.Create(fListBox, aIndex, [fRuntimeId, aIndex], fUiaApi) as
      IAccessibilityProviderNode;
    AddChild(Result);
    fItems.Add(aIndex, Result);
    fItemRawTexts.AddOrSetValue(aIndex, lRawText);
  end;
  TAccessibilityDiagnostics.RecordListBoxEnsureItemProvider(lCreated);
end;

function TAccessibilityListBoxProvider.GetFocus(out aRetVal: IRawElementProviderFragment): HResult;
var
  lItem: IAccessibilityProviderNode;
begin
  aRetVal := nil;
  if IsDisconnected or (fListBox = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  TAccessibilityDiagnostics.RecordListBoxGetFocus;
  if ListBoxOwnsFocus then
  begin
    lItem := EnsureItemProvider(fListBox.ItemIndex);
    if lItem <> nil then
    begin
      aRetVal := lItem.FragmentProvider;
    end;
  end;
  Result := S_OK;
end;

function TAccessibilityListBoxProvider.Get_CanSelectMultiple(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected or (fListBox = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fListBox.MultiSelect;
  Result := S_OK;
end;

function TAccessibilityListBoxProvider.Get_IsSelectionRequired(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityListBoxProvider.GetSelection(out aRetVal: PSafeArray): HResult;
var
  i: Integer;
  lItemProbeCount: Integer;
  lItem: IAccessibilityProviderNode;
  lMetricsEnabled: Boolean;
  lProviderCount: Integer;
  lSelectedProviders: TList<IRawElementProviderSimple>;
  lStopwatch: TStopwatch;
begin
  aRetVal := nil;
  if IsDisconnected or (fListBox = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  TAccessibilityDiagnostics.RecordListBoxGetSelection;
  lItemProbeCount := 0;
  lProviderCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  lSelectedProviders := TList<IRawElementProviderSimple>.Create;
  try
    if fListBox.MultiSelect then
    begin
      for i := 0 to Pred(fListBox.Items.Count) do
      begin
        if lMetricsEnabled then
        begin
          Inc(lItemProbeCount);
        end;

        if fListBox.Selected[i] then
        begin
          lItem := EnsureItemProvider(i);
          if lItem <> nil then
          begin
            lSelectedProviders.Add(lItem.RawElementProvider);
            if lMetricsEnabled then
            begin
              Inc(lProviderCount);
            end;
          end;
        end;
      end;
    end else begin
      if lMetricsEnabled then
      begin
        Inc(lItemProbeCount);
      end;

      lItem := EnsureItemProvider(fListBox.ItemIndex);
      if lItem <> nil then
      begin
        lSelectedProviders.Add(lItem.RawElementProvider);
        if lMetricsEnabled then
        begin
          Inc(lProviderCount);
        end;
      end;
    end;

    aRetVal := CreateSelectionArray(lSelectedProviders.ToArray);
  finally
    lSelectedProviders.Free;
  end;

  if lMetricsEnabled then
  begin
    TAccessibilityDiagnostics.RecordProviderHotspotListBoxGetSelection(lItemProbeCount, lProviderCount,
      lStopwatch.ElapsedTicks);
  end;

  if aRetVal = nil then
  begin
    Result := E_UNEXPECTED;
  end else begin
    Result := S_OK;
  end;
end;

function TAccessibilityListBoxProvider.ItemProvider(aIndex: Integer): IAccessibilityProviderNode;
begin
  if not fItems.TryGetValue(aIndex, Result) then
  begin
    Result := nil;
  end else if Result.IsDisconnected then
  begin
    fItems.Remove(aIndex);
    fItemRawTexts.Remove(aIndex);
    Result := nil;
  end;
end;

function TAccessibilityListBoxProvider.ListBoxOwnsFocus: Boolean;
begin
  Result := ListBoxOwnsKeyboardFocus(fListBox);
end;

procedure TAccessibilityListBoxProvider.RememberChildrenPreparation;
begin
  if fListBox = nil then
  begin
    fPreparedValid := False;
    Exit;
  end;

  fPreparedHandle := fListBox.Handle;
  fPreparedItemCount := fListBox.Items.Count;
  fPreparedTopIndex := fListBox.TopIndex;
  fPreparedFocusedIndex := fListBox.ItemIndex;
  fPreparedClientWidth := fListBox.ClientWidth;
  fPreparedClientHeight := fListBox.ClientHeight;
  fPreparedItemHeight := ListBoxWindowItemHeight(fListBox);
  fPreparedValid := True;
end;

procedure TAccessibilityListBoxProvider.PrepareChildrenForNavigation;
var
  lFocusedPrepared: Boolean;
  i: Integer;
  lFocusedIndex: Integer;
  lItemRect: TRect;
  lLastIndex: Integer;
  lTopIndex: Integer;
begin
  inherited PrepareChildrenForNavigation;
  if (fListBox = nil) or not ControlIsInActiveVisibleTree(fListBox) then
  begin
    Exit;
  end;

  if ChildrenPreparationIsCurrent then
  begin
    Exit;
  end;

  TAccessibilityDiagnostics.RecordListBoxPrepareChildren;
  lFocusedIndex := fListBox.ItemIndex;
  lFocusedPrepared := False;
  if fListBox.Items.Count = 0 then
  begin
    RememberChildrenPreparation;
    Exit;
  end;

  lLastIndex := Pred(fListBox.Items.Count);
  lTopIndex := EnsureRange(fListBox.TopIndex, 0, lLastIndex);
  for i := lTopIndex to lLastIndex do
  begin
    TAccessibilityDiagnostics.RecordListBoxVisibleItemProbe;
    lItemRect := fListBox.ItemRect(i);
    if (i > lTopIndex) and (lItemRect.Top >= fListBox.ClientHeight) then
    begin
      Break;
    end;

    if ListBoxItemRectIsVisible(fListBox, lItemRect) then
    begin
      EnsureItemProvider(i);
      lFocusedPrepared := lFocusedPrepared or (i = lFocusedIndex);
    end;
  end;

  if (not lFocusedPrepared) and ListBoxItemIndexExists(fListBox, lFocusedIndex) then
  begin
    EnsureItemProvider(lFocusedIndex);
  end;
  RememberChildrenPreparation;
end;

constructor TAccessibilityStatusBarProvider.Create(aStatusBar: TCustomStatusBar; const aRuntimeId: array of Integer;
  const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, NativeWindowHandleForControl(aStatusBar), aApi, aStatusBar);
  fStatusBar := aStatusBar;
  fHelpText := aHelpText;
end;

function TAccessibilityStatusBarProvider.Control: TControl;
begin
  Result := fStatusBar;
end;

function TAccessibilityStatusBarProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lPoint: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if IsDisconnected or (fStatusBar = nil) or not ControlIsInActiveVisibleTree(fStatusBar) then
  begin
    Exit;
  end;

  lPoint := fStatusBar.ClientToScreen(Point(0, 0));
  aValue.Left := lPoint.X;
  aValue.Top := lPoint.Y;
  aValue.Width := fStatusBar.Width;
  aValue.Height := fStatusBar.Height;
  Result := True;
end;

function TAccessibilityStatusBarProvider.DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant):
  Boolean;
const
  cStatusBarControlTypeId = 50017;
begin
  Result := True;
  case aPropertyId of
    UIA_NamePropertyId:
      aValue := StatusBarAccessibleText(fStatusBar);
    UIA_ControlTypePropertyId:
      aValue := cStatusBarControlTypeId;
    UIA_ClassNamePropertyId:
      aValue := fStatusBar.ClassName;
    UIA_HelpTextPropertyId:
      aValue := fHelpText;
    UIA_IsEnabledPropertyId:
      aValue := (fStatusBar <> nil) and fStatusBar.Enabled;
    UIA_IsKeyboardFocusablePropertyId,
    UIA_HasKeyboardFocusPropertyId:
      aValue := False;
    UIA_IsOffscreenPropertyId:
      aValue := (fStatusBar = nil) or not ControlIsInActiveVisibleTree(fStatusBar);
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
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
  if (fGrid = nil) or not ControlIsInActiveVisibleTree(fGrid) or (fCol < 0) or (fCol >= fGrid.ColCount) or
    (fRow < 0) or (fRow >= fGrid.RowCount) then
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

function TAccessibilityStringGridRowProvider.AddToSelection: HResult;
begin
  Result := Select;
end;

constructor TAccessibilityStringGridRowProvider.Create(aGridProvider: TAccessibilityStringGridProvider;
  aGrid: TStringGrid; aRow: Integer; const aRuntimeId: array of Integer; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, aGrid);
  fGridProvider := aGridProvider;
  fGrid := aGrid;
  fRow := aRow;
  SetProperty(UIA_ControlTypePropertyId, UIA_DataItemControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, 'TStringGridRow');
  SetProperty(UIA_HelpTextPropertyId, '');
end;

function TAccessibilityStringGridRowProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lCellRect: TRect;
  lHeight: Integer;
  lLeft: Integer;
  lRight: Integer;
  lTop: Integer;
  lTopLeft: TPoint;
  lVisibleCellFound: Boolean;
  lCol: Integer;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fGrid = nil) or IsDisconnected or not IsVisibleRow then
  begin
    Exit;
  end;

  lLeft := MaxInt;
  lRight := 0;
  lTop := 0;
  lHeight := 0;
  lVisibleCellFound := False;
  for lCol := 0 to Pred(fGrid.ColCount) do
  begin
    if GridCellIsVisible(fGrid, lCol, fRow) then
    begin
      lCellRect := fGrid.CellRect(lCol, fRow);
      lLeft := Min(lLeft, lCellRect.Left);
      lRight := Max(lRight, lCellRect.Right);
      if not lVisibleCellFound then
      begin
        lTop := lCellRect.Top;
        lHeight := lCellRect.Height;
      end;
      lVisibleCellFound := True;
    end;
  end;

  if not lVisibleCellFound then
  begin
    Exit;
  end;

  lTopLeft := fGrid.ClientToScreen(Point(lLeft, lTop));
  aValue.Left := lTopLeft.X;
  aValue.Top := lTopLeft.Y;
  aValue.Width := lRight - lLeft;
  aValue.Height := lHeight;
  Result := True;
end;

function TAccessibilityStringGridRowProvider.DoGetPatternProvider(aPatternId: PATTERNID): IUnknown;
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

function TAccessibilityStringGridRowProvider.DoGetPropertyValue(aPropertyId: PROPERTYID;
  out aValue: OleVariant): Boolean;
begin
  Result := True;
  case aPropertyId of
    UIA_NamePropertyId:
      aValue := GridRowAccessibleText(fGrid, fRow);
    UIA_IsOffscreenPropertyId:
      aValue := not IsVisibleRow;
    UIA_HasKeyboardFocusPropertyId:
      aValue := (fGridProvider <> nil) and fGridProvider.GridOwnsFocus and (fGrid.Row = fRow);
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

function TAccessibilityStringGridRowProvider.Get_Column(out aRetVal: Integer): HResult;
begin
  aRetVal := 0;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridRowProvider.Get_ColumnSpan(out aRetVal: Integer): HResult;
begin
  aRetVal := 0;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGrid.ColCount;
  Result := S_OK;
end;

function TAccessibilityStringGridRowProvider.Get_ContainingGrid(out aRetVal: IRawElementProviderSimple): HResult;
begin
  aRetVal := nil;
  if IsDisconnected or (fGridProvider = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fGridProvider.RawElementProvider;
  Result := S_OK;
end;

function TAccessibilityStringGridRowProvider.Get_IsSelected(out aRetVal: BOOL): HResult;
begin
  aRetVal := False;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := (fGrid <> nil) and (fGrid.Row = fRow);
  Result := S_OK;
end;

function TAccessibilityStringGridRowProvider.Get_Row(out aRetVal: Integer): HResult;
begin
  aRetVal := fRow;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridRowProvider.Get_RowSpan(out aRetVal: Integer): HResult;
begin
  aRetVal := 1;
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := S_OK;
end;

function TAccessibilityStringGridRowProvider.Get_SelectionContainer(out aRetVal: IRawElementProviderSimple):
  HResult;
begin
  Result := Get_ContainingGrid(aRetVal);
end;

function TAccessibilityStringGridRowProvider.IsVisibleRow: Boolean;
begin
  Result := GridRowIsVisible(fGrid, fRow);
end;

function TAccessibilityStringGridRowProvider.RemoveFromSelection: HResult;
begin
  if IsDisconnected then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  Result := E_NOTIMPL;
end;

function TAccessibilityStringGridRowProvider.Select: HResult;
begin
  if IsDisconnected or (fGrid = nil) or not IsVisibleRow then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

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

procedure TAccessibilityStringGridProvider.ClearRowProviders;
var
  lPair: TPair<Integer, IAccessibilityProviderNode>;
  lRowProvider: IAccessibilityProviderNode;
  lRowsToRemove: TList<Integer>;
  lRow: Integer;
begin
  lRowsToRemove := TList<Integer>.Create;
  try
    for lPair in fRows do
    begin
      lRowsToRemove.Add(lPair.Key);
    end;

    for lRow in lRowsToRemove do
    begin
      if fRows.TryGetValue(lRow, lRowProvider) then
      begin
        RemoveChildNode(lRowProvider, False);
        fRows.Remove(lRow);
      end;
    end;
  finally
    lRowsToRemove.Free;
  end;
end;

function TAccessibilityStringGridProvider.EnsureCellProvider(aCol: Integer; aRow: Integer):
  IAccessibilityProviderNode;
begin
  RefreshVisibleCells;
  Result := CellProvider(aCol, aRow);
  if (Result = nil) and (fGrid <> nil) and (aCol >= 0) and (aCol < fGrid.ColCount) and
    (aRow >= 0) and (aRow < fGrid.RowCount) then
  begin
    Result := TAccessibilityStringGridCellProvider.Create(Self, fGrid, aCol, aRow, [fRuntimeId, aRow, aCol], fUiaApi) as
      IAccessibilityProviderNode;
    AddChild(Result);
    fCells.Add(CellKey(aCol, aRow), Result);
  end;
end;

function TAccessibilityStringGridProvider.EnsureRowProvider(aRow: Integer): IAccessibilityProviderNode;
begin
  RefreshVisibleRows;
  Result := RowProvider(aRow);
end;

procedure TAccessibilityStringGridProvider.RefreshVisibleCells;
var
  lCell: IAccessibilityProviderNode;
  lCellProbeCount: Integer;
  lCol: Integer;
  lCols: TList<Integer>;
  lCreatedCount: Integer;
  lFirstScrollableCol: Integer;
  lFirstScrollableRow: Integer;
  lKey: Int64;
  lKeysToRemove: TList<Int64>;
  lLastScrollableCol: Integer;
  lLastScrollableRow: Integer;
  lMetricsEnabled: Boolean;
  lPair: TPair<Int64, IAccessibilityProviderNode>;
  lRow: Integer;
  lRows: TList<Integer>;
  lStopwatch: TStopwatch;
begin
  if (fGrid = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) then
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
        RemoveChildNode(lCell, False);
        fCells.Remove(lKey);
      end;
    end;
  finally
    lKeysToRemove.Free;
  end;

  lCols := TList<Integer>.Create;
  lRows := TList<Integer>.Create;
  try
    for lCol := 0 to Pred(Min(fGrid.FixedCols, fGrid.ColCount)) do
    begin
      lCols.Add(lCol);
    end;

    lFirstScrollableCol := EnsureRange(fGrid.LeftCol, 0, Pred(fGrid.ColCount));
    lLastScrollableCol := Min(Pred(fGrid.ColCount), lFirstScrollableCol + Max(0, fGrid.VisibleColCount) + 1);
    for lCol := lFirstScrollableCol to lLastScrollableCol do
    begin
      if not lCols.Contains(lCol) then
      begin
        lCols.Add(lCol);
      end;
    end;

    for lRow := 0 to Pred(Min(fGrid.FixedRows, fGrid.RowCount)) do
    begin
      lRows.Add(lRow);
    end;

    lFirstScrollableRow := EnsureRange(fGrid.TopRow, 0, Pred(fGrid.RowCount));
    lLastScrollableRow := Min(Pred(fGrid.RowCount), lFirstScrollableRow + Max(0, fGrid.VisibleRowCount) + 1);
    for lRow := lFirstScrollableRow to lLastScrollableRow do
    begin
      if not lRows.Contains(lRow) then
      begin
        lRows.Add(lRow);
      end;
    end;

    for lRow in lRows do
    begin
      for lCol in lCols do
      begin
        if lMetricsEnabled then
        begin
          Inc(lCellProbeCount);
        end;

        if IsVisibleCell(lCol, lRow) and (CellProvider(lCol, lRow) = nil) then
        begin
          lCell := TAccessibilityStringGridCellProvider.Create(Self, fGrid, lCol, lRow,
            [fRuntimeId, lRow, lCol], fUiaApi) as IAccessibilityProviderNode;
          AddChild(lCell);
          fCells.Add(CellKey(lCol, lRow), lCell);
          if lMetricsEnabled then
          begin
            Inc(lCreatedCount);
          end;
        end;
      end;
    end;
  finally
    lRows.Free;
    lCols.Free;
  end;

  if lMetricsEnabled then
  begin
    TAccessibilityDiagnostics.RecordStringGridRefresh(lCellProbeCount, lCreatedCount, lStopwatch.ElapsedTicks);
  end;
end;

procedure TAccessibilityStringGridProvider.RefreshVisibleRows;
var
  lKeysToRemove: TList<Integer>;
  lPair: TPair<Integer, IAccessibilityProviderNode>;
  lRow: Integer;
  lRowProvider: IAccessibilityProviderNode;
begin
  if (fGrid = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) or not GridUsesRowSelection(fGrid) then
  begin
    ClearRowProviders;
    Exit;
  end;

  lKeysToRemove := TList<Integer>.Create;
  try
    for lPair in fRows do
    begin
      if lPair.Value.IsDisconnected or not GridRowIsVisible(fGrid, lPair.Key) then
      begin
        lKeysToRemove.Add(lPair.Key);
      end;
    end;

    for lRow in lKeysToRemove do
    begin
      if fRows.TryGetValue(lRow, lRowProvider) then
      begin
        RemoveChildNode(lRowProvider, False);
        fRows.Remove(lRow);
      end;
    end;
  finally
    lKeysToRemove.Free;
  end;

  for lRow := 0 to Pred(fGrid.RowCount) do
  begin
    if GridRowIsVisible(fGrid, lRow) and (RowProvider(lRow) = nil) then
    begin
      lRowProvider := TAccessibilityStringGridRowProvider.Create(Self, fGrid, lRow,
        [fRuntimeId, lRow, fGrid.ColCount], fUiaApi) as IAccessibilityProviderNode;
      AddChild(lRowProvider);
      fRows.Add(lRow, lRowProvider);
    end;
  end;
end;

function TAccessibilityStringGridProvider.RowProvider(aRow: Integer): IAccessibilityProviderNode;
begin
  if not fRows.TryGetValue(aRow, Result) then
  begin
    Result := nil;
  end else if Result.IsDisconnected then
  begin
    Result := nil;
  end;
end;

constructor TAccessibilityStringGridProvider.Create(aGrid: TStringGrid; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode([aRuntimeId], aGrid.Handle, aApi, aGrid);
  fCells := TDictionary<Int64, IAccessibilityProviderNode>.Create;
  fRows := TDictionary<Integer, IAccessibilityProviderNode>.Create;
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

  lData := nil;
  lUnknown := aProvider as IUnknown;
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

destructor TAccessibilityStringGridProvider.Destroy;
begin
  fRows.Free;
  fCells.Free;
  inherited Destroy;
end;

function TAccessibilityStringGridProvider.Control: TControl;
begin
  Result := fGrid;
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
      aValue := not ControlIsInActiveVisibleTree(fGrid);
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
  if not ControlIsInActiveVisibleTree(fGrid) or
    not WindowUnderPointMatchesControl(fGrid, Point(Integer(Round(aX)), Integer(Round(aY)))) then
  begin
    Exit(S_OK);
  end;

  if not PtInRect(Rect(0, 0, fGrid.ClientWidth, fGrid.ClientHeight), lClientPoint) then
  begin
    Exit(S_OK);
  end;

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
  lRow: IAccessibilityProviderNode;
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

  if GridUsesRowSelection(fGrid) then
  begin
    lRow := EnsureRowProvider(fGrid.Row);
    if lRow <> nil then
    begin
      aRetVal := lRow.FragmentProvider;
    end;
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
  lRow: IAccessibilityProviderNode;
begin
  aRetVal := nil;
  if IsDisconnected or (fGrid = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  if GridUsesRowSelection(fGrid) then
  begin
    lRow := EnsureRowProvider(fGrid.Row);
    if lRow = nil then
    begin
      aRetVal := CreateSelectionArray(nil);
    end else begin
      aRetVal := CreateSelectionArray(lRow.RawElementProvider);
    end;
  end else begin
    lCell := EnsureCellProvider(fGrid.Col, fGrid.Row);
    if lCell = nil then
    begin
      aRetVal := CreateSelectionArray(nil);
    end else begin
      aRetVal := CreateSelectionArray(lCell.RawElementProvider);
    end;
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
  RefreshVisibleRows;
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
  aRegistry.RegisterAdapter(TCustomButton, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TCustomCheckBox, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TCustomComboBox, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TCustomGroupBox, TNamedContainerAdapter.Create);
  aRegistry.RegisterAdapter(TRadioButton, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TSpeedButton, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TToolBar, TNamedContainerAdapter.Create);
  aRegistry.RegisterAdapter(TToolButton, TExplicitTextAdapter.Create);
  aRegistry.RegisterAdapter(TPageControl, TNamedContainerAdapter.Create);
  aRegistry.RegisterAdapter(TCustomPanel, TPanelAdapter.Create);
  aRegistry.RegisterAdapter(TCustomMemo, TMemoAdapter.Create);
  aRegistry.RegisterAdapter(TCustomListBox, TListBoxAdapter.Create);
  aRegistry.RegisterAdapter(TCustomStatusBar, TStatusBarAdapter.Create);
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
