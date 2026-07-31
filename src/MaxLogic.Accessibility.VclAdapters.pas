unit MaxLogic.Accessibility.VclAdapters;

interface

uses
  Vcl.Controls, Vcl.Forms,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner, MaxLogic.Accessibility.UIAutomationCore;

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

  IAccessibilityVclProviderLookup = interface
    ['{BE71B85E-441E-45EE-96F6-504148877F0A}']
    function TryFindProviderForControl(aControl: TControl; out aProvider: IRawElementProviderSimple): Boolean;
  end;

  IAccessibilityVclProviderRuntimeInternal = interface
    ['{3318F903-76F0-48B2-90CC-203037295357}']
    function ReconcileProviderHierarchy(const aTree: IAccessibilityScanTree): Boolean;
  end;

  IAccessibilityVclHoverGeometryPartition = interface
    ['{463E21F1-28E8-40F2-8686-3A098DFFC492}']
    function VclGeometryPartitionsHoverTargets: Boolean;
  end;

  IAccessibilityListBoxSelectionTracker = interface
    ['{2CDB3FE4-6203-47BC-ADDD-0E99641AC47D}']
    procedure SelectionMayHaveChanged;
    procedure StartSelectionTracking;
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
  System.Types, System.TypInfo, System.Variants, Winapi.ActiveX, Winapi.Messages, Winapi.Windows, Vcl.Buttons,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.Diagnostics,
  MaxLogic.Accessibility.Text;

type
  TAccessibilityVclCheckBoxAccess = class(TCustomCheckBox);
  TAccessibilityVclControlAccess = class(TControl);
  TAccessibilityListBoxAccess = class(TCustomListBox);

  TVclAdapterRttiPropertyCache = class
  private
    fPropsByClass: TObjectDictionary<NativeUInt, TDictionary<string, PPropInfo>>;
  public
    constructor Create;
    destructor Destroy; override;
    function Lookup(aObject: TObject; const aPropertyName: string): PPropInfo;
  end;

  IAccessibilityVclRootProvider = interface
    ['{28654175-22FB-4F34-BDE7-8D82E7087897}']
    procedure AddHitTestRoot(const aRoot: IRawElementProviderFragmentRoot);
    procedure RegisterControlProvider(aControl: TControl; const aProvider: IRawElementProviderFragment);
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

  TAccessibilityVclFormProviderRoot = class(TAccessibilityProviderRoot, IAccessibilityVclRootProvider,
    IAccessibilityVclProviderLookup, IAccessibilityVclProviderRuntimeInternal,
    IAccessibilityVclHoverGeometryPartition)
  private
    fForm: TCustomForm;
    fHitTestRoots: TList<IRawElementProviderFragmentRoot>;
    fNextRuntimeId: Integer;
    fProviderNodesByControl: TDictionary<Pointer, IAccessibilityProviderNode>;
    fProvidersByControl: TDictionary<Pointer, IRawElementProviderFragment>;
    fRegistry: IAccessibilityAdapterRegistry;
    fRuntimeApi: IAccessibilityUiaApi;
    function AddMissingProviderChildren(const aParentProvider: IAccessibilityProviderNode;
      const aScanNode: IAccessibilityScanNode): Boolean;
    procedure CollectScanControls(const aScanNode: IAccessibilityScanNode;
      aControls: THashSet<Pointer>);
    procedure ReconcileLabeledByRelationships(const aTree: IAccessibilityScanTree);
    function CanUseDirectHitTarget(aControl: TControl): Boolean;
    function ControlFromPoint(const aScreenPoint: TPoint): TControl;
    function TryFindControlProvider(aControl: TControl; out aProvider: IRawElementProviderFragment): Boolean;
    function TryFindTabHeaderProviderFromPoint(const aScreenPoint: TPoint;
      out aProvider: IRawElementProviderFragment): Boolean;
  protected
    function DoElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment):
      HResult; override;
    function DoGetFocus(out aProvider: IRawElementProviderFragment): HResult; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry;
      const aApi: IAccessibilityUiaApi);
    destructor Destroy; override;
    procedure AddHitTestRoot(const aRoot: IRawElementProviderFragmentRoot);
    procedure RegisterControlProvider(aControl: TControl; const aProvider: IRawElementProviderFragment);
    function ReconcileProviderHierarchy(const aTree: IAccessibilityScanTree): Boolean;
    function TryFindProviderForControl(aControl: TControl; out aProvider: IRawElementProviderSimple): Boolean;
    function VclGeometryPartitionsHoverTargets: Boolean;
  end;

  TAccessibilityStringGridProvider = class;

  TAccessibilityVclOwnedProvider = class(TAccessibilityProviderNode)
  protected
    procedure DetachReparentedChildren(aOwner: TControl);
  end;

  TAccessibilityVclControlProvider = class(TAccessibilityVclOwnedProvider, IAccessibilityVclControlProviderInfo,
    IAccessibilityVclHoverGeometryPartition, IInvokeProvider, IToggleProvider, IValueProvider,
    ISelectionItemProvider)
  private
    fControl: TControl;
    fHelpText: string;
    fLabeledByDirectAccess: IAccessibilityProviderDirectAccess;
    fLabeledByProvider: IRawElementProviderSimple;
    fLiveHelpText: Boolean;
    fLiveName: Boolean;
    fName: string;
    class function CheckBoxToggleState(aControl: TControl): ToggleState; static;
    class function ControlSupportsToggle(aControl: TControl): Boolean; static;
    function CurrentHelpText: string;
    function CurrentName: string;
    procedure SetLabeledByProvider(const aProvider: IRawElementProviderSimple);
    function TryGetLabeledByProperty(out aValue: OleVariant): Boolean;
    function UpdateLabeledByProvider(const aProvider: IRawElementProviderSimple;
      out aOldProvider: IRawElementProviderSimple): Boolean;
    procedure UpdateScannerName(const aName: string);
    class function SpeedButtonSupportsToggle(aButton: TSpeedButton): Boolean; static;
    class function SupportsValue(aControl: TControl): Boolean; static;
    class function ToggleCheckBox(aControl: TControl): Boolean; static;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
    procedure PrepareForOwnerDisconnect; override;
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
    function TryGetValueText(out aValue: string): Boolean; override;
    function VclGeometryPartitionsHoverTargets: Boolean;
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

  IAccessibilityListBoxItemTextCache = interface
    ['{7B41092B-4819-4556-B41E-E5E6C40B6E4E}']
    procedure RefreshTextCache(const aRawText: string; const aCleanText: string);
  end;

  TAccessibilityMemoProvider = class(TAccessibilityVclControlProvider, IRawElementProviderFragmentRoot)
  private
    fLineIndexes: TList<Integer>;
    fLines: TDictionary<Integer, IAccessibilityProviderNode>;
    fLinesToRemove: TList<Integer>;
    fMemo: TCustomMemo;
    fPreparedClientHeight: Integer;
    fPreparedClientWidth: Integer;
    fPreparedFirstVisibleLine: Integer;
    fPreparedHandle: HWND;
    fPreparedLineCount: Integer;
    fPreparedValid: Boolean;
    fProviderRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    function ChildrenPreparationIsCurrent: Boolean;
    procedure AddLineProvider(aLine: Integer; const aProvider: IAccessibilityProviderNode);
    function EnsureLineProvider(aLine: Integer): IAccessibilityProviderNode;
    function EnsurePreparedLineProvider(aLine: Integer): IAccessibilityProviderNode;
    function LineProvider(aLine: Integer): IAccessibilityProviderNode;
    procedure MaterializeVisibleLines(aFirstVisibleLine: Integer; aLastVisibleLine: Integer; aMetricsEnabled: Boolean;
      out aLineProbeCount: Integer; out aCreatedCount: Integer);
    procedure PruneLineProviders(aFirstVisibleLine: Integer; aLastVisibleLine: Integer);
    procedure RemoveLineProvider(aLine: Integer; const aProvider: IAccessibilityProviderNode; aDisconnect: Boolean);
    procedure RememberChildrenPreparation(aLineCount: Integer; aFirstVisibleLine: Integer);
    function TryGetVisibleLineRange(aLineCount: Integer; out aFirstVisibleLine: Integer;
      out aLastVisibleLine: Integer): Boolean;
  protected
    function CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean; override;
    procedure PrepareChildrenForNavigation; override;
  public
    constructor Create(aMemo: TCustomMemo; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    destructor Destroy; override;
    function ElementProviderFromPoint(aX: Double; aY: Double; out aRetVal: IRawElementProviderFragment):
      HResult; stdcall;
    function GetFocus(out aRetVal: IRawElementProviderFragment): HResult; stdcall;
  end;

  TAccessibilityListBoxItemProvider = class(TAccessibilityProviderNode, IAccessibilityListBoxItemTextCache,
    ISelectionItemProvider)
  private
    fCachedCleanText: string;
    fCachedRawText: string;
    fIndex: Integer;
    fListBox: TCustomListBox;
    fOwner: TAccessibilityListBoxProvider;
    fTextCacheValid: Boolean;
    function CurrentText: string;
    function IsVisibleItem: Boolean;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPatternProvider(aPatternId: PATTERNID): IUnknown; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
  public
    constructor Create(aOwner: TAccessibilityListBoxProvider; aListBox: TCustomListBox; aIndex: Integer;
      const aRuntimeId: array of Integer; const aApi: IAccessibilityUiaApi; const aRawText: string;
      const aCleanText: string);
    function AddToSelection: HResult; stdcall;
    function Get_IsSelected(out aRetVal: BOOL): HResult; stdcall;
    function Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    procedure RefreshTextCache(const aRawText: string; const aCleanText: string);
    function RemoveFromSelection: HResult; stdcall;
    function Select: HResult; stdcall;
  end;

  TAccessibilityListBoxProvider = class(TAccessibilityVclControlProvider, IRawElementProviderFragmentRoot,
    ISelectionProvider, IAccessibilityListBoxSelectionTracker)
  private
    fItemIndexes: TList<Integer>;
    fItems: TDictionary<Integer, IAccessibilityProviderNode>;
    fItemRawTexts: TDictionary<Integer, string>;
    fListBox: TCustomListBox;
    fPreparedClientHeight: Integer;
    fPreparedClientWidth: Integer;
    fPreparedFirstVisibleIndex: Integer;
    fPreparedFocusedIndex: Integer;
    fPreparedHandle: HWND;
    fPreparedItemCount: Integer;
    fPreparedItemHeight: Integer;
    fPreparedLastVisibleIndex: Integer;
    fPreparedTopIndex: Integer;
    fPreparedValid: Boolean;
    fProviderRuntimeId: Integer;
    fSelectionDirty: Boolean;
    fSelectionTracking: Boolean;
    fSelectedIndexes: THashSet<Integer>;
    fSelectedIndexesValid: Boolean;
    fUiaApi: IAccessibilityUiaApi;
    procedure AddItemProvider(aIndex: Integer; const aRawText: string;
      const aProvider: IAccessibilityProviderNode);
    function ChildrenPreparationIsCurrent: Boolean;
    function CreateMultiSelection(out aItemProbeCount: Integer; out aProviderCount: Integer): PSafeArray;
    function CreateSelectionArray(const aProvider: IRawElementProviderSimple): PSafeArray; overload;
    function CreateSelectionArrayForSelectedIndexes(const aSelectedIndexes: TArray<Integer>;
      out aProviderCount: Integer): PSafeArray;
    function CreateSingleSelection(out aItemProbeCount: Integer; out aProviderCount: Integer): PSafeArray;
    function EnsureItemProvider(aIndex: Integer): IAccessibilityProviderNode;
    procedure ItemSelectionChanged(aIndex: Integer; aSelected: Boolean);
    function ItemProvider(aIndex: Integer): IAccessibilityProviderNode;
    function ListBoxOwnsFocus: Boolean;
    procedure PruneItemProviders(aFirstVisibleIndex: Integer; aLastVisibleIndex: Integer; aFocusedIndex: Integer);
    procedure ReconcilePreparedRetention(aFocusedIndex: Integer);
    function RefreshSelectedIndexes: Boolean;
    procedure RememberChildrenPreparation(aFirstVisibleIndex: Integer; aLastVisibleIndex: Integer);
    procedure RememberSelectedIndexes(const aSelectedIndexes: TArray<Integer>);
    procedure RemoveItemProvider(aIndex: Integer; const aProvider: IAccessibilityProviderNode; aDisconnect: Boolean);
    procedure RemoveItemProviderChildren(const aRemovalFlags: TArray<Boolean>; aRemovedCount: Integer);
    procedure RemoveItemProviderAt(aItemPosition: Integer; aIndex: Integer;
      const aProvider: IAccessibilityProviderNode; aDisconnect: Boolean);
    function ShouldRetainItemProvider(aIndex: Integer; const aProvider: IAccessibilityProviderNode;
      aItemCount: Integer; aFirstVisibleIndex: Integer; aLastVisibleIndex: Integer;
      aFocusedIndex: Integer): Boolean;
    function TryGetVisibleItemRange(out aFirstVisibleIndex: Integer; out aLastVisibleIndex: Integer): Boolean;
    function TryGetPreparedItemRect(aIndex: Integer; out aItemRect: TRect): Boolean;
  protected
    function CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean; override;
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
    procedure SelectionMayHaveChanged;
    procedure StartSelectionTracking;
  end;

  TAccessibilityStatusBarProvider = class(TAccessibilityVclOwnedProvider, IAccessibilityVclControlProviderInfo)
  private
    fHelpText: string;
    fLiveHelpText: Boolean;
    fStatusBar: TCustomStatusBar;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
    function DoGetPropertyValue(aPropertyId: PROPERTYID; out aValue: OleVariant): Boolean; override;
    procedure PrepareForOwnerDisconnect; override;
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
    IAccessibilityFocusedItemProvider, IRawElementProviderFragmentRoot, IGridProvider, ISelectionProvider)
  private
    fCells: TDictionary<Int64, IAccessibilityProviderNode>;
    fGrid: TStringGrid;
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
    fPreparedOptions: TGridOptions;
    fPreparedRowCount: Integer;
    fPreparedTopRow: Integer;
    fPreparedValid: Boolean;
    fPreparedVisibleColCount: Integer;
    fPreparedVisibleRowCount: Integer;
    fRows: TDictionary<Integer, IAccessibilityProviderNode>;
    fProviderRuntimeId: Integer;
    fUiaApi: IAccessibilityUiaApi;
    procedure BuildVisibleCells;
    function CellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function ChildrenPreparationIsCurrent: Boolean;
    procedure ClearRowProviders;
    function CreateSelectionArray(const aProvider: IRawElementProviderSimple): PSafeArray;
    function EnsureCellProvider(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function EnsureCellProviderDirect(aCol: Integer; aRow: Integer): IAccessibilityProviderNode;
    function EnsureRowProvider(aRow: Integer): IAccessibilityProviderNode;
    function EnsureRowProviderDirect(aRow: Integer): IAccessibilityProviderNode;
    procedure EnsureVisibleCellProvider(aCol: Integer; aRow: Integer; aMetricsEnabled: Boolean;
      var aCellProbeCount: Integer; var aCreatedCount: Integer);
    procedure EnsureVisibleRowProvider(aRow: Integer; aMetricsEnabled: Boolean; var aRowProbeCount: Integer;
      var aCreatedCount: Integer);
    function GridOwnsFocus: Boolean;
    function IsVisibleCell(aCol: Integer; aRow: Integer): Boolean;
    procedure RefreshVisibleCells;
    procedure RefreshVisibleRows;
    procedure RememberChildrenPreparation;
    function RowProvider(aRow: Integer): IAccessibilityProviderNode;
  protected
    function CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean; override;
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
    function TryGetFocusedItem(out aProvider: IRawElementProviderSimple; out aName: string): Boolean;
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

function ControlIsInActiveVisibleTree(aControl: TControl): Boolean; forward;

function PointFromMessageResult(aValue: LRESULT): TPoint;
var
  lRawValue: Int64;
  lSignedValue: Int64;
  lX: Integer;
  lY: Integer;
begin
  lSignedValue := Int64(aValue); //PALOFF WARN63 explicit LPARAM sign normalization
  lRawValue := lSignedValue and $00000000FFFFFFFF;
  lX := Integer(lRawValue and $FFFF); //PALOFF explicit reviewed low-word extraction
  if lX > High(Smallint) then
  begin
    Dec(lX, $10000);
  end;

  lY := Integer((lRawValue shr 16) and $FFFF); //PALOFF explicit reviewed high-word extraction
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
  lFontResult: LRESULT;
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
    lFontResult := SendMessage(aControl.Handle, WM_GETFONT, 0, 0);
    lFont := HFONT(lFontResult);
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

function MemoLineExists(aMemo: TCustomMemo; aLine: Integer): Boolean;
begin
  Result := False;
  if (aMemo = nil) or (aLine < 0) then
  begin
    Exit;
  end;

  Result := aMemo.Perform(EM_LINEINDEX, aLine, 0) >= 0;
end;

function MemoLineCount(aMemo: TCustomMemo): Integer;
var
  lLineCountResult: LRESULT;
begin
  Result := 0;
  if aMemo = nil then
  begin
    Exit;
  end;

  lLineCountResult := aMemo.Perform(EM_GETLINECOUNT, 0, 0);
  if lLineCountResult > 0 then
  begin
    Result := Integer(lLineCountResult);
  end;
end;

function MemoLineText(aMemo: TCustomMemo; aLine: Integer): string;
const
  cMaxMemoGetLineLength = High(Word);
var
  lCharIndex: LRESULT;
  lCopiedLength: LRESULT;
  lLineBuffer: string;
  lLineLength: LRESULT;
begin
  Result := '';
  if (aMemo = nil) or (aLine < 0) then
  begin
    Exit;
  end;

  lCharIndex := aMemo.Perform(EM_LINEINDEX, aLine, 0);
  if lCharIndex < 0 then
  begin
    Exit;
  end;

  lLineLength := aMemo.Perform(EM_LINELENGTH, lCharIndex, 0);
  if lLineLength <= 0 then
  begin
    Exit;
  end;

  if lLineLength > cMaxMemoGetLineLength then
  begin
    Result := TAccessibilityText.Clean(Copy(aMemo.Text, Integer(lCharIndex) + 1, Integer(lLineLength)));
    Exit;
  end;

  SetLength(lLineBuffer, Integer(lLineLength));
  PWord(PChar(lLineBuffer))^ := Word(lLineLength); //PALOFF WARN52 Win32 edit-buffer contract
  lCopiedLength := aMemo.Perform(EM_GETLINE, aLine, LPARAM(PChar(lLineBuffer)));
  if lCopiedLength <= 0 then
  begin
    Exit;
  end;

  if lCopiedLength > lLineLength then
  begin
    lCopiedLength := lLineLength;
  end;
  if lCopiedLength < lLineLength then
  begin
    SetLength(lLineBuffer, Integer(lCopiedLength));
  end;
  Result := TAccessibilityText.Clean(lLineBuffer);
end;

function MemoLineIndexAtPoint(aMemo: TCustomMemo; const aClientPoint: TPoint): Integer;
var
  lCharIndex: LRESULT;
  lCharIndexParam: WPARAM;
  lRawCharIndex: Int64;
  lSignedCharIndex: Int64;
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

  lSignedCharIndex := Int64(lCharIndex); //PALOFF WARN63 explicit WPARAM sign normalization
  lRawCharIndex := lSignedCharIndex and $00000000FFFFFFFF;
  lCharIndexParam := WPARAM(lRawCharIndex and $FFFF); //PALOFF explicit reviewed Win32 word packing
  Result := aMemo.Perform(EM_LINEFROMCHAR, lCharIndexParam, 0);
  if Result < 0 then
  begin
    Result := -1;
  end;
end;

function MemoLineBounds(aMemo: TCustomMemo; aLine: Integer; out aRect: TRect): Boolean;
var
  lCharIndex: LRESULT;
  lLinePoint: TPoint;
begin
  aRect := TRect.Empty;
  Result := False;
  if (aMemo = nil) or (aLine < 0) or not ControlIsInActiveVisibleTree(aMemo) then
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

function CleanListBoxItemText(const aRawText: string): string;
begin
  TAccessibilityDiagnostics.RecordListBoxItemTextProbe;
  Result := TAccessibilityText.Clean(aRawText);
end;

function ListBoxItemText(aListBox: TCustomListBox; aIndex: Integer): string;
begin
  Result := '';
  if (aListBox <> nil) and (aIndex >= 0) and (aIndex < aListBox.Items.Count) then
  begin
    Result := CleanListBoxItemText(aListBox.Items[aIndex]);
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

function ListBoxItemIndexExists(aListBox: TCustomListBox; aIndex: Integer): Boolean;
begin
  Result := (aListBox <> nil) and (aIndex >= 0) and (aIndex < aListBox.Items.Count);
end;

function ListBoxWindowItemHeight(aListBox: TCustomListBox): Integer;
var
  lIndex: Integer;
  lListBox: TAccessibilityListBoxAccess;
begin
  Result := 0;
  if aListBox = nil then
  begin
    Exit;
  end;

  lListBox := TAccessibilityListBoxAccess(aListBox); //PALOFF STWA6 access class preserves runtime type
  if aListBox.HandleAllocated then
  begin
    lIndex := 0;
    if (lListBox.Style = lbOwnerDrawVariable) and (aListBox.Items.Count > 0) then
    begin
      lIndex := EnsureRange(aListBox.TopIndex, 0, Pred(aListBox.Items.Count));
    end;

    Result := Integer(aListBox.Perform(LB_GETITEMHEIGHT, lIndex, 0));
    if Result > 0 then
    begin
      Exit;
    end;

    if aListBox.Items.Count = 0 then
    begin
      Exit(0);
    end;
  end;

  Result := lListBox.ItemHeight;
end;

function ListBoxUsesUniformItemHeight(aListBox: TCustomListBox): Boolean;
begin
  Result := (aListBox <> nil) and (TAccessibilityListBoxAccess(aListBox).Style <> lbOwnerDrawVariable);
end;

function ListBoxVisibleItemRect(aListBox: TCustomListBox; aIndex: Integer; out aItemRect: TRect): Boolean;
var
  lItemHeight: Integer;
  lTop: Integer;
  lTopIndex: Integer;
begin
  aItemRect := TRect.Empty;
  Result := False;
  if not ListBoxItemIndexExists(aListBox, aIndex) then
  begin
    Exit;
  end;

  if not ControlIsInActiveVisibleTree(aListBox) then
  begin
    Exit;
  end;

  if ListBoxUsesUniformItemHeight(aListBox) then
  begin
    lItemHeight := ListBoxWindowItemHeight(aListBox);
    if (lItemHeight <= 0) or (aListBox.ClientWidth <= 0) then
    begin
      Exit;
    end;

    lTopIndex := EnsureRange(aListBox.TopIndex, 0, Pred(aListBox.Items.Count));
    lTop := (aIndex - lTopIndex) * lItemHeight;
    aItemRect := Rect(0, lTop, aListBox.ClientWidth, lTop + lItemHeight);
  end else begin
    aItemRect := aListBox.ItemRect(aIndex);
  end;

  Result := ListBoxItemRectIsVisible(aListBox, aItemRect);
end;

function ListBoxItemIsVisible(aListBox: TCustomListBox; aIndex: Integer): Boolean;
var
  lItemRect: TRect;
begin
  Result := ListBoxVisibleItemRect(aListBox, aIndex, lItemRect);
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

function ListBoxSelectedIndexes(aListBox: TCustomListBox): TArray<Integer>;
var
  lCount: Integer;
  lReturnedCount: LRESULT;
begin
  Result := nil;
  if (aListBox = nil) or not aListBox.HandleAllocated then
  begin
    Exit;
  end;

  lCount := aListBox.SelCount;
  if lCount <= 0 then
  begin
    Exit;
  end;

  SetLength(Result, lCount);
  lReturnedCount := SendMessage(aListBox.Handle, LB_GETSELITEMS, WPARAM(lCount), LPARAM(@Result[0]));
  if lReturnedCount <= 0 then
  begin
    Result := nil;
    Exit;
  end;

  if lReturnedCount < lCount then
  begin
    SetLength(Result, Integer(lReturnedCount));
  end;
end;

function GridUsesRowSelection(aGrid: TStringGrid): Boolean;
begin
  Result := (aGrid <> nil) and (goRowSelect in aGrid.Options);
end;

function IsVisibleCellRect(const aCellRect: TRect): Boolean;
begin
  Result := (aCellRect.Width > 0) and (aCellRect.Height > 0);
end;

function TryGetVisibleGridCellRect(aGrid: TStringGrid; aCol: Integer; aRow: Integer;
  out aCellRect: TRect): Boolean;
begin
  aCellRect := TRect.Empty;
  Result := False;
  if (aGrid = nil) or (aCol < 0) or (aCol >= aGrid.ColCount) or (aRow < 0) or (aRow >= aGrid.RowCount) then
  begin
    Exit;
  end;

  aCellRect := aGrid.CellRect(aCol, aRow);
  Result := IsVisibleCellRect(aCellRect);
end;

function GridCellIsVisible(aGrid: TStringGrid; aCol: Integer; aRow: Integer): Boolean;
var
  lCellRect: TRect;
begin
  Result := TryGetVisibleGridCellRect(aGrid, aCol, aRow, lCellRect);
end;

function GridRowHasVisibleHeader(aGrid: TStringGrid; aRow: Integer): Boolean;
var
  lCol: Integer;
  lFirstScrollableCol: Integer;
  lFixedColCount: Integer;
  lHeaderRow: Integer;
  lLastScrollableCol: Integer;
begin
  Result := False;
  if (aGrid = nil) or (aGrid.FixedRows <= 0) or (aRow < aGrid.FixedRows) then
  begin
    Exit;
  end;

  lHeaderRow := Pred(aGrid.FixedRows);
  lFixedColCount := Min(aGrid.FixedCols, aGrid.ColCount); //PALOFF WARN52 same-width bounded count
  for lCol := 0 to Pred(lFixedColCount) do
  begin
    if GridCellIsVisible(aGrid, lCol, aRow) and
      (TAccessibilityText.Clean(aGrid.Cells[lCol, lHeaderRow]) <> '') then
    begin
      Exit(True);
    end;
  end;

  if aGrid.ColCount <= 0 then
  begin
    Exit;
  end;

  lFirstScrollableCol := EnsureRange(aGrid.LeftCol, 0, Pred(aGrid.ColCount));
  lLastScrollableCol := Min(Pred(aGrid.ColCount), lFirstScrollableCol + Max(0, aGrid.VisibleColCount) + 1);
  for lCol := lFirstScrollableCol to lLastScrollableCol do
  begin
    if (lCol >= lFixedColCount) and GridCellIsVisible(aGrid, lCol, aRow) and
      (TAccessibilityText.Clean(aGrid.Cells[lCol, lHeaderRow]) <> '') then
    begin
      Exit(True);
    end;
  end;
end;

procedure AppendGridRowAccessibleCell(aGrid: TStringGrid; aRow: Integer; aCol: Integer; aHeaderRow: Integer;
  aUseHeaderFormat: Boolean; var aText: string; aMetricsEnabled: Boolean; var aHeaderProbeCount: Integer);
var
  lCellText: string;
  lHeaderText: string;
begin
  if not GridCellIsVisible(aGrid, aCol, aRow) then
  begin
    Exit;
  end;

  lCellText := TAccessibilityText.Clean(aGrid.Cells[aCol, aRow]);
  if lCellText = '' then
  begin
    Exit;
  end;

  if aText <> '' then
  begin
    if aUseHeaderFormat then
    begin
      aText := aText + sLineBreak + sLineBreak;
    end else begin
      aText := aText + ', ';
    end;
  end;

  if aUseHeaderFormat then
  begin
    if aMetricsEnabled then
    begin
      Inc(aHeaderProbeCount);
    end;
    lHeaderText := TAccessibilityText.Clean(aGrid.Cells[aCol, aHeaderRow]);
    if lHeaderText <> '' then
    begin
      lCellText := lHeaderText + ': ' + lCellText;
    end;
  end;

  aText := aText + lCellText;
end;

function GridRowAccessibleText(aGrid: TStringGrid; aRow: Integer): string;
var
  lCellProbeCount: Integer;
  lCol: Integer;
  lFirstScrollableCol: Integer;
  lFixedColCount: Integer;
  lHeaderProbeCount: Integer;
  lHeaderRow: Integer;
  lLastScrollableCol: Integer;
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
  lUseHeaderFormat: Boolean;
begin
  Result := '';
  if (aGrid = nil) or (aRow < 0) or (aRow >= aGrid.RowCount) then
  begin
    Exit;
  end;

  lCellProbeCount := 0;
  lHeaderProbeCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  lUseHeaderFormat := GridRowHasVisibleHeader(aGrid, aRow);
  lHeaderRow := Pred(aGrid.FixedRows);
  try
    lFixedColCount := Min(aGrid.FixedCols, aGrid.ColCount); //PALOFF WARN52 same-width bounded count
    for lCol := 0 to Pred(lFixedColCount) do
    begin
      if lMetricsEnabled then
      begin
        Inc(lCellProbeCount);
      end;

      AppendGridRowAccessibleCell(aGrid, aRow, lCol, lHeaderRow, lUseHeaderFormat, Result, lMetricsEnabled,
        lHeaderProbeCount);
    end;

    if aGrid.ColCount > 0 then
    begin
      lFirstScrollableCol := EnsureRange(aGrid.LeftCol, 0, Pred(aGrid.ColCount));
      lLastScrollableCol := Min(Pred(aGrid.ColCount), lFirstScrollableCol + Max(0, aGrid.VisibleColCount) + 1);
      for lCol := lFirstScrollableCol to lLastScrollableCol do
      begin
        if lCol >= lFixedColCount then
        begin
          if lMetricsEnabled then
          begin
            Inc(lCellProbeCount);
          end;
          AppendGridRowAccessibleCell(aGrid, aRow, lCol, lHeaderRow, lUseHeaderFormat, Result, lMetricsEnabled,
            lHeaderProbeCount);
        end;
      end;
    end;
  finally
    if lMetricsEnabled then
    begin
      TAccessibilityDiagnostics.RecordStringGridRowText(lCellProbeCount, lHeaderProbeCount, lStopwatch.ElapsedTicks);
    end;
  end;
end;

procedure IncludeGridRowBoundsCell(aGrid: TStringGrid; aRow: Integer; aCol: Integer; var aLeft: Integer;
  var aRight: Integer; var aTop: Integer; var aHeight: Integer; var aVisibleCellFound: Boolean;
  aMetricsEnabled: Boolean; var aCellProbeCount: Integer);
var
  lCellRect: TRect;
begin
  if aMetricsEnabled then
  begin
    Inc(aCellProbeCount);
  end;

  if TryGetVisibleGridCellRect(aGrid, aCol, aRow, lCellRect) then
  begin
    aLeft := Min(aLeft, lCellRect.Left);
    aRight := Max(aRight, lCellRect.Right);
    if not aVisibleCellFound then
    begin
      aTop := lCellRect.Top;
      aHeight := lCellRect.Height;
    end;
    aVisibleCellFound := True;
  end;
end;

function ControlHasDirectCaption(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomForm) or (aControl is TCustomLabel) or (aControl is TStaticText) or
    (aControl is TCustomButton) or (aControl is TCustomCheckBox) or (aControl is TRadioButton) or
    (aControl is TCustomGroupBox) or (aControl is TCustomPanel) or (aControl is TTabSheet) or
    (aControl is TSpeedButton) or (aControl is TToolButton);
end;

function ControlHasDirectText(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomEdit) or (aControl is TCustomMemo) or (aControl is TCustomComboBox);
end;

function TryReadDirectObjectProperty(aObject: TObject; const aPropertyName: string; out aValue: TObject): Boolean;
begin
  Result := False;
  aValue := nil;
  if (aPropertyName = 'Action') and (aObject is TControl) then
  begin
    aValue := TAccessibilityVclControlAccess(aObject).Action;
    Exit(True);
  end;
end;

function TryReadDirectStringProperty(aObject: TObject; const aPropertyName: string; out aValue: string): Boolean;
var
  lControl: TControl;
begin
  Result := False;
  aValue := '';
  if not (aObject is TControl) then
  begin
    Exit;
  end;

  lControl := TControl(aObject); //PALOFF STWA6 guarded by is TControl
  if (aPropertyName = 'Caption') and ControlHasDirectCaption(lControl) then
  begin
    aValue := TAccessibilityText.Clean(TAccessibilityVclControlAccess(lControl).Caption);
    Exit(True);
  end;

  if (aPropertyName = 'Text') and
    ((lControl is TCustomEdit) or (lControl is TCustomMemo) or (lControl is TCustomComboBox)) then
  begin
    aValue := TAccessibilityText.Clean(TAccessibilityVclControlAccess(lControl).Text);
    Exit(True);
  end;

  if aPropertyName = 'Hint' then
  begin
    aValue := TAccessibilityText.Clean(lControl.Hint);
    Exit(True);
  end;

  if aPropertyName = 'TextHint' then
  begin
    if lControl is TCustomEdit then
    begin
      aValue := TAccessibilityText.Clean(TCustomEdit(lControl).TextHint);
      Exit(True);
    end;

    if lControl is TCustomComboBox then
    begin
      aValue := TAccessibilityText.Clean(TCustomComboBox(lControl).TextHint);
      Exit(True);
    end;
  end;
end;

function LookupRttiProperty(aObject: TObject; const aPropertyName: string): PPropInfo; forward;

function ReadObjectProperty(aObject: TObject; const aPropertyName: string): TObject;
var
  lPropInfo: PPropInfo;
begin
  Result := nil;
  if TryReadDirectObjectProperty(aObject, aPropertyName, Result) then
  begin
    Exit;
  end;

  lPropInfo := LookupRttiProperty(aObject, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkClass) then //PALOFF STWA5 nil guard precedes dereference
  begin
    Result := GetObjectProp(aObject, lPropInfo);
  end;
end;

function ReadStringProperty(aObject: TObject; const aPropertyName: string): string;
var
  lPropInfo: PPropInfo;
begin
  Result := '';
  if TryReadDirectStringProperty(aObject, aPropertyName, Result) then
  begin
    Exit;
  end;

  lPropInfo := LookupRttiProperty(aObject, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then //PALOFF STWA5 nil guard precedes dereference
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
  if aPropertyName = 'Checked' then
  begin
    if aObject is TCustomCheckBox then
    begin
      Exit(TAccessibilityVclCheckBoxAccess(aObject).Checked);
    end;

    if aObject is TRadioButton then
    begin
      Exit(TRadioButton(aObject).Checked);
    end;
  end;

  if aPropertyName = 'ReadOnly' then
  begin
    if aObject is TCustomEdit then
    begin
      Exit(TCustomEdit(aObject).ReadOnly);
    end;

    if aObject is TCustomMemo then
    begin
      Exit(TCustomMemo(aObject).ReadOnly);
    end;
  end;

  if (aPropertyName = 'AllowGrayed') and (aObject is TCustomCheckBox) then
  begin
    Exit(TAccessibilityVclCheckBoxAccess(aObject).AllowGrayed);
  end;

  lPropInfo := LookupRttiProperty(aObject, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then //PALOFF STWA5 nil guard precedes dereference
  begin
    Result := GetOrdProp(aObject, lPropInfo) <> 0;
  end;
end;

function WriteBooleanProperty(aObject: TObject; const aPropertyName: string; aValue: Boolean): Boolean;
var
  lPropInfo: PPropInfo;
begin
  Result := False;
  if aPropertyName = 'Checked' then
  begin
    if aObject is TCustomCheckBox then
    begin
      TAccessibilityVclCheckBoxAccess(aObject).Checked := aValue;
      Exit(True);
    end;

    if aObject is TRadioButton then
    begin
      TRadioButton(aObject).Checked := aValue;
      Exit(True);
    end;
  end;

  lPropInfo := LookupRttiProperty(aObject, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then //PALOFF STWA5 nil guard precedes dereference
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
  if (aPropertyName = 'State') and (aObject is TCustomCheckBox) then
  begin
    aValue := Ord(TAccessibilityVclCheckBoxAccess(aObject).State);
    Exit(True);
  end;

  lPropInfo := LookupRttiProperty(aObject, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then //PALOFF STWA5 nil guard precedes dereference
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
  if (aPropertyName = 'Text') and (aObject is TControl) and
    ((aObject is TCustomEdit) or (aObject is TCustomMemo) or (aObject is TCustomComboBox)) then
  begin
    TAccessibilityVclControlAccess(aObject).Text := aValue;
    Exit(True);
  end;

  lPropInfo := LookupRttiProperty(aObject, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then //PALOFF STWA5 nil guard precedes dereference
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
  if (aPropertyName = 'State') and (aObject is TCustomCheckBox) then
  begin
    TAccessibilityVclCheckBoxAccess(aObject).State := TCheckBoxState(aValue); //PALOFF STWA6 validated enum conversion
    Exit(True);
  end;

  lPropInfo := LookupRttiProperty(aObject, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkEnumeration) then //PALOFF STWA5 nil guard precedes dereference
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

function GridRowIsVisible(aGrid: TStringGrid; aRow: Integer): Boolean;
var
  lCol: Integer;
  lFirstScrollableCol: Integer;
  lFixedColCount: Integer;
  lLastScrollableCol: Integer;
begin
  Result := False;
  if (aGrid = nil) or not ControlIsInActiveVisibleTree(aGrid) or (aRow < 0) or (aRow >= aGrid.RowCount) then
  begin
    Exit;
  end;

  lFixedColCount := Min(aGrid.FixedCols, aGrid.ColCount); //PALOFF WARN52 same-width bounded count
  for lCol := 0 to Pred(lFixedColCount) do
  begin
    if GridCellIsVisible(aGrid, lCol, aRow) then
    begin
      Exit(True);
    end;
  end;

  if aGrid.ColCount <= 0 then
  begin
    Exit;
  end;

  lFirstScrollableCol := EnsureRange(aGrid.LeftCol, 0, Pred(aGrid.ColCount));
  lLastScrollableCol := Min(Pred(aGrid.ColCount), lFirstScrollableCol + Max(0, aGrid.VisibleColCount) + 1);
  for lCol := lFirstScrollableCol to lLastScrollableCol do
  begin
    if (lCol >= lFixedColCount) and GridCellIsVisible(aGrid, lCol, aRow) then
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

  lControl := TWinControl(aControl); //PALOFF STWA6 guarded by is TWinControl
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
    if (TAccessibilityText.Clean(TContainedAction(lAction).Caption) <> '') or //PALOFF STWA5 guarded by is TContainedAction
      (TAccessibilityText.Clean(TContainedAction(lAction).Hint) <> '') then
    begin
      Exit(True);
    end;
  end;
end;

function FallbackHasUsefulExplicitText(aControl: TControl; const aFallback: TAccessibilityTextInfo): Boolean;
var
  lControlName: string;
begin
  Result := False;
  if aControl = nil then
  begin
    Exit;
  end;

  if aFallback.HelpText <> '' then
  begin
    Exit(True);
  end;

  if (aFallback.Name = '') or TAccessibilityText.IsIconFontOnly(aFallback.Name) then
  begin
    Exit;
  end;

  lControlName := TAccessibilityText.Clean(aControl.Name);
  Result := not SameText(aFallback.Name, lControlName);
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

procedure EnsureRadioGroupButtonControls(aControl: TControl);
var
  i: Integer;
  lParent: TWinControl;
  lRadioGroup: TRadioGroup;
begin
  if aControl is TRadioGroup then
  begin
    lRadioGroup := TRadioGroup(aControl);
    lRadioGroup.HandleNeeded;
    for i := 0 to Pred(lRadioGroup.Items.Count) do
    begin
      lRadioGroup.Buttons[i].HandleNeeded;
    end;
  end;

  if aControl is TWinControl then
  begin
    lParent := TWinControl(aControl);
    for i := 0 to Pred(lParent.ControlCount) do
    begin
      EnsureRadioGroupButtonControls(lParent.Controls[i]);
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

function ShouldPublishNativeWindowHandle(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomGroupBox) or (aControl is TPageControl) or ((aControl is TRadioButton) and
    ((aControl.Parent is TRadioGroup) or (aControl.Parent is TCustomGroupBox)));
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
    if aRootProvider <> nil then
    begin
      aRootProvider.RegisterControlProvider(aScanNode.Child(i).Control, lChildProvider.FragmentProvider);
    end;

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

procedure AddLabeledByRelationship(const aScanNode: IAccessibilityScanNode;
  const aLookup: IAccessibilityVclProviderLookup);
var
  lInputNode: IAccessibilityProviderNode;
  lInputNodeInternal: IAccessibilityProviderNodeInternal;
  lInputProvider: IRawElementProviderSimple;
  lLabelControl: TControl;
  lLabelProvider: IRawElementProviderSimple;
  lRelationship: IAccessibilityScanNodeLabelRelationship;
  lValue: OleVariant;
begin
  if not Supports(aScanNode, IAccessibilityScanNodeLabelRelationship, lRelationship) then
  begin
    Exit;
  end;

  lLabelControl := lRelationship.AssociatedLabelControl;
  if (lLabelControl = nil) or (lLabelControl = aScanNode.Control) or
    not aLookup.TryFindProviderForControl(aScanNode.Control, lInputProvider) or
    not Supports(lInputProvider, IAccessibilityProviderNode, lInputNode) or
    not aLookup.TryFindProviderForControl(lLabelControl, lLabelProvider) then
  begin
    Exit;
  end;

  if Supports(lInputNode, IAccessibilityProviderNodeInternal, lInputNodeInternal) and
    (lInputNodeInternal.ProviderObject is TAccessibilityVclControlProvider) then
  begin
    TAccessibilityVclControlProvider(lInputNodeInternal.ProviderObject).SetLabeledByProvider(lLabelProvider);
  end else begin
    lValue := lLabelProvider as IUnknown;
    lInputNode.SetProperty(UIA_LabeledByPropertyId, lValue);
  end;
end;

procedure AddLabeledByRelationships(const aTree: IAccessibilityScanTree;
  const aLookup: IAccessibilityVclProviderLookup);
var
  i: Integer;
  lNodes: TArray<IAccessibilityScanNode>;
begin
  if (aTree = nil) or (aLookup = nil) then
  begin
    Exit;
  end;

  lNodes := aTree.FlattenedNodes;
  for i := 0 to High(lNodes) do
  begin
    AddLabeledByRelationship(lNodes[i], aLookup);
  end;
end;

function TExplicitTextAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if FallbackHasUsefulExplicitText(aControl, aFallback) or HasUsefulExplicitText(aControl) then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TPanelAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if FallbackHasUsefulExplicitText(aControl, aFallback) or HasUsefulExplicitText(aControl) then
  begin
    Exit(TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText));
  end;

  Result := TAccessibilityControlInfo.Omit;
end;

function TNamedContainerAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if FallbackHasUsefulExplicitText(aControl, aFallback) or HasUsefulExplicitText(aControl) then
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
  Result := TAccessibilityStringGridProvider.Create(TStringGrid(aControl), aRuntimeId, aName, aHelpText, aApi) as //PALOFF STWA6 guarded by Supports
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
  Result := TAccessibilityMemoProvider.Create(TCustomMemo(aControl), aRuntimeId, aName, aHelpText, aApi) as //PALOFF STWA6 guarded by Supports
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
  Result := TAccessibilityListBoxProvider.Create(TCustomListBox(aControl), aRuntimeId, aName, aHelpText, aApi) as //PALOFF STWA6 guarded by Supports
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
  Result := TAccessibilityStatusBarProvider.Create(TCustomStatusBar(aControl), [aRuntimeId], aHelpText, aApi) as //PALOFF STWA6 guarded by Supports
    IAccessibilityProviderNode;
end;

type
  THitTestCandidates = record
    TabHeader: IRawElementProviderFragment;
    VisibleControl: IRawElementProviderFragment;
  end;

var
  gVclAdapterRttiPropertyCache: TVclAdapterRttiPropertyCache;

constructor TVclAdapterRttiPropertyCache.Create;
begin
  inherited Create;
  fPropsByClass := TObjectDictionary<NativeUInt, TDictionary<string, PPropInfo>>.Create([doOwnsValues]);
end;

destructor TVclAdapterRttiPropertyCache.Destroy;
begin
  fPropsByClass.Free;
  inherited Destroy;
end;

function TVclAdapterRttiPropertyCache.Lookup(aObject: TObject; const aPropertyName: string): PPropInfo;
var
  lClassInfo: PTypeInfo;
  lClassKey: NativeUInt;
  lProperties: TDictionary<string, PPropInfo>;
begin
  Result := nil;
  if aObject = nil then
  begin
    Exit;
  end;

  lClassInfo := aObject.ClassInfo;
  if lClassInfo = nil then
  begin
    Exit;
  end;

  System.TMonitor.Enter(Self);
  try
    lClassKey := NativeUInt(lClassInfo);
    if not fPropsByClass.TryGetValue(lClassKey, lProperties) then
    begin
      lProperties := TDictionary<string, PPropInfo>.Create;
      fPropsByClass.Add(lClassKey, lProperties);
    end;

    if not lProperties.TryGetValue(aPropertyName, Result) then
    begin
      TAccessibilityDiagnostics.RecordVclAdapterRttiPropertyLookup;
      Result := GetPropInfo(lClassInfo, aPropertyName);
      lProperties.Add(aPropertyName, Result);
    end;
  finally
    System.TMonitor.Exit(Self);
  end;
end;

function LookupRttiProperty(aObject: TObject; const aPropertyName: string): PPropInfo;
begin
  Result := nil;
  if aObject = nil then
  begin
    Exit;
  end;

  if gVclAdapterRttiPropertyCache <> nil then
  begin
    Exit(gVclAdapterRttiPropertyCache.Lookup(aObject, aPropertyName));
  end;

  TAccessibilityDiagnostics.RecordVclAdapterRttiPropertyLookup;
  Result := GetPropInfo(aObject.ClassInfo, aPropertyName);
end;

function UiaRectContainsPoint(const aRect: UiaRect; aX: Double; aY: Double): Boolean;
begin
  Result := (aX >= aRect.Left) and (aY >= aRect.Top) and (aX < aRect.Left + aRect.Width) and
    (aY < aRect.Top + aRect.Height);
end;

function TryGetControlBoundingRectangle(aControl: TControl; out aValue: UiaRect): Boolean;
var
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabRect: TRect;
  lTabSheet: TTabSheet;
begin
  aValue := Default(UiaRect);
  Result := False;
  if aControl = nil then
  begin
    Exit;
  end;

  if aControl is TTabSheet then
  begin
    lTabSheet := TTabSheet(aControl);
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

    lPoint := lPageControl.ClientToScreen(lTabRect.TopLeft);
    aValue.Left := lPoint.X;
    aValue.Top := lPoint.Y;
    aValue.Width := lTabRect.Width;
    aValue.Height := lTabRect.Height;
    Exit(True);
  end;

  if not ControlIsInActiveVisibleTree(aControl) then
  begin
    Exit;
  end;

  lPoint := aControl.ClientToScreen(Point(0, 0));
  aValue.Left := lPoint.X;
  aValue.Top := lPoint.Y;
  aValue.Width := aControl.Width;
  aValue.Height := aControl.Height;
  Result := True;
end;

function TryProviderDirectChildAt(const aFragment: IRawElementProviderFragment; aIndex: Integer;
  out aChild: IRawElementProviderFragment): Boolean;
var
  lChildAccess: IAccessibilityProviderChildAccess;
  lSimple: IRawElementProviderSimple;
begin
  aChild := nil;
  lSimple := nil;
  Result := Supports(aFragment, IAccessibilityProviderChildAccess, lChildAccess) and
    (lChildAccess.DirectChildAt(aIndex, lSimple) = S_OK) and
    Supports(lSimple, IRawElementProviderFragment, aChild);
end;

function TryProviderDirectChildCount(const aFragment: IRawElementProviderFragment; out aCount: Integer): Boolean;
var
  lChildAccess: IAccessibilityProviderChildAccess;
begin
  aCount := 0;
  Result := Supports(aFragment, IAccessibilityProviderChildAccess, lChildAccess) and
    (lChildAccess.DirectChildCount(aCount) = S_OK);
end;

procedure FindHitTestCandidatesFromPoint(const aFragment: IRawElementProviderFragment; aX: Double; aY: Double;
  const aScreenPoint: TPoint; var aCandidates: THitTestCandidates);
var
  i: Integer;
  lBounds: UiaRect;
  lChild: IRawElementProviderFragment;
  lChildCount: Integer;
  lControl: TControl;
  lInfo: IAccessibilityVclControlProviderInfo;
  lNextChild: IRawElementProviderFragment;
  lNode: IAccessibilityProviderNode;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lScreenRect: TRect;
  lTabRect: TRect;
  lTabSheet: TTabSheet;
begin
  if aFragment = nil then
  begin
    Exit;
  end;

  lControl := nil;
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
        if PtInRect(lScreenRect, aScreenPoint) then
        begin
          aCandidates.TabHeader := aFragment;
          Exit;
        end;
      end;
    end;
  end;

  if TryProviderDirectChildCount(aFragment, lChildCount) then
  begin
    for i := 0 to Pred(lChildCount) do
    begin
      lChild := nil;
      if not TryProviderDirectChildAt(aFragment, i, lChild) then
      begin
        Continue;
      end;

      FindHitTestCandidatesFromPoint(lChild, aX, aY, aScreenPoint, aCandidates);
      if aCandidates.TabHeader <> nil then
      begin
        Exit;
      end;
    end;
  end else if aFragment.Navigate(NavigateDirection_FirstChild, lChild) = S_OK then
  begin
    while lChild <> nil do
    begin
      FindHitTestCandidatesFromPoint(lChild, aX, aY, aScreenPoint, aCandidates);
      if aCandidates.TabHeader <> nil then
      begin
        Exit;
      end;

      lNextChild := nil;
      if lChild.Navigate(NavigateDirection_NextSibling, lNextChild) <> S_OK then
      begin
        Break;
      end;
      lChild := lNextChild;
    end;
  end;

  if (aCandidates.VisibleControl = nil) and (lControl <> nil) then
  begin
    if Supports(aFragment, IAccessibilityProviderNode, lNode) and lNode.IsDisconnected then
    begin
      Exit;
    end;

    if TryGetControlBoundingRectangle(lControl, lBounds) and
      UiaRectContainsPoint(lBounds, aX, aY) then
    begin
      aCandidates.VisibleControl := aFragment;
    end;
  end;
end;

function TAccessibilityVclFormProviderRoot.AddMissingProviderChildren(
  const aParentProvider: IAccessibilityProviderNode; const aScanNode: IAccessibilityScanNode): Boolean;
var
  i: Integer;
  lCurrentParent: IRawElementProviderFragment;
  lChildHitTestRoot: IRawElementProviderFragmentRoot;
  lChildManagesOwnTree: Boolean;
  lChildProvider: IAccessibilityProviderNode;
  lCurrentIndex: Integer;
  lHierarchy: IAccessibilityProviderHierarchyInternal;
  lParentHierarchy: IAccessibilityProviderHierarchyInternal;
  lParentMatches: Boolean;
  lParentSimple: IRawElementProviderSimple;
begin
  Result := False;
  if not Supports(aParentProvider, IAccessibilityProviderHierarchyInternal, lParentHierarchy) then
  begin
    raise EInvalidOperation.Create('Provider parent does not support hierarchy reconciliation.');
  end;
  for i := 0 to Pred(aScanNode.ChildCount) do
  begin
    if not fProviderNodesByControl.TryGetValue(Pointer(aScanNode.Child(i).Control), lChildProvider) or
      (lChildProvider = nil) or lChildProvider.IsDisconnected then
    begin
      if lChildProvider <> nil then
      begin
        if Supports(lChildProvider.RawElementProvider, IRawElementProviderFragmentRoot, lChildHitTestRoot) then
        begin
          fHitTestRoots.Remove(lChildHitTestRoot);
        end;
        if Supports(lChildProvider, IAccessibilityProviderHierarchyInternal, lHierarchy) then
        begin
          lHierarchy.DetachFromParent(True);
        end;
      end;
      lChildProvider := CreateProviderForNode(aScanNode.Child(i), fRegistry, fNextRuntimeId, fRuntimeApi);
      lParentHierarchy.InsertChildAt(i, lChildProvider);
      RegisterControlProvider(aScanNode.Child(i).Control, lChildProvider.FragmentProvider);
      lChildManagesOwnTree := Supports(lChildProvider.RawElementProvider,
        IRawElementProviderFragmentRoot, lChildHitTestRoot);
      if lChildManagesOwnTree then
      begin
        AddHitTestRoot(lChildHitTestRoot);
      end;
      Result := True;
    end else begin
      lChildManagesOwnTree := Supports(lChildProvider.RawElementProvider,
        IRawElementProviderFragmentRoot, lChildHitTestRoot);
      lCurrentParent := nil;
      lParentSimple := nil;
      lParentMatches := (lChildProvider.FragmentProvider.Navigate(NavigateDirection_Parent, lCurrentParent) = S_OK) and
        Supports(lCurrentParent, IRawElementProviderSimple, lParentSimple) and
        ((lParentSimple as IUnknown) = (aParentProvider.RawElementProvider as IUnknown));
      lCurrentIndex := -1;
      if lParentMatches then
      begin
        lCurrentIndex := lParentHierarchy.ChildIndexOf(lChildProvider);
      end;
      if not lParentMatches or (lCurrentIndex <> i) then
      begin
        if not Supports(lChildProvider, IAccessibilityProviderHierarchyInternal, lHierarchy) then
        begin
          raise EInvalidOperation.Create('Provider node does not support hierarchy reconciliation.');
        end;
        lHierarchy.DetachFromParent(False);
        lParentHierarchy.InsertChildAt(i, lChildProvider);
        Result := True;
      end;
    end;

    if not lChildManagesOwnTree then
    begin
      Result := AddMissingProviderChildren(lChildProvider, aScanNode.Child(i)) or Result;
    end;
  end;
end;

procedure TAccessibilityVclFormProviderRoot.CollectScanControls(const aScanNode: IAccessibilityScanNode;
  aControls: THashSet<Pointer>);
var
  i: Integer;
begin
  for i := 0 to Pred(aScanNode.ChildCount) do
  begin
    aControls.Add(Pointer(aScanNode.Child(i).Control));
    CollectScanControls(aScanNode.Child(i), aControls);
  end;
end;

procedure TAccessibilityVclFormProviderRoot.AddHitTestRoot(const aRoot: IRawElementProviderFragmentRoot);
begin
  if aRoot <> nil then
  begin
    fHitTestRoots.Add(aRoot);
  end;
end;

constructor TAccessibilityVclFormProviderRoot.Create(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode([1], aForm.Handle, aApi, aForm);
  fForm := aForm;
  fRegistry := aRegistry;
  fRuntimeApi := aApi;
  fHitTestRoots := TList<IRawElementProviderFragmentRoot>.Create;
  fNextRuntimeId := 1;
  fProviderNodesByControl := TDictionary<Pointer, IAccessibilityProviderNode>.Create;
  fProvidersByControl := TDictionary<Pointer, IRawElementProviderFragment>.Create;
end;

destructor TAccessibilityVclFormProviderRoot.Destroy;
begin
  fProvidersByControl.Free;
  fProviderNodesByControl.Free;
  fHitTestRoots.Free;
  inherited Destroy;
end;

function TAccessibilityVclFormProviderRoot.DoGetPropertyValue(aPropertyId: PROPERTYID;
  out aValue: OleVariant): Boolean;
begin
  if aPropertyId = UIA_NamePropertyId then
  begin
    aValue := TAccessibilityText.Clean(fForm.Caption);
    Exit(True);
  end;
  if aPropertyId = UIA_HelpTextPropertyId then
  begin
    aValue := TAccessibilityTextExtractor.Extract(fForm).HelpText;
    Exit(True);
  end;

  Result := inherited DoGetPropertyValue(aPropertyId, aValue);
end;

procedure TAccessibilityVclFormProviderRoot.RegisterControlProvider(aControl: TControl;
  const aProvider: IRawElementProviderFragment);
var
  lNode: IAccessibilityProviderNode;
begin
  if (aControl <> nil) and (aProvider <> nil) then
  begin
    fProvidersByControl.AddOrSetValue(Pointer(aControl), aProvider);
    if Supports(aProvider, IAccessibilityProviderNode, lNode) then
    begin
      fProviderNodesByControl.AddOrSetValue(Pointer(aControl), lNode);
    end;
  end;
end;

procedure TAccessibilityVclFormProviderRoot.ReconcileLabeledByRelationships(
  const aTree: IAccessibilityScanTree);
var
  lControl: TControl;
  lControlKey: Pointer;
  lControlProvider: TAccessibilityVclControlProvider;
  lLabelControl: TControl;
  lLabelNode: IAccessibilityProviderNode;
  lLabelProvider: IRawElementProviderSimple;
  lNewValue: OleVariant;
  lNode: IAccessibilityProviderNode;
  lNodeInternal: IAccessibilityProviderNodeInternal;
  lOldProvider: IRawElementProviderSimple;
  lOldValue: OleVariant;
  lRelationship: IAccessibilityScanNodeLabelRelationship;
  lScanNode: IAccessibilityScanNode;
begin
  if (aTree = nil) or IsDisconnected then
  begin
    Exit;
  end;

  for lControlKey in fProviderNodesByControl.Keys do
  begin
    lControl := TControl(lControlKey);
    if not fProviderNodesByControl.TryGetValue(lControlKey, lNode) or
      not Supports(lNode, IAccessibilityProviderNodeInternal, lNodeInternal) or
      not (lNodeInternal.ProviderObject is TAccessibilityVclControlProvider) then
    begin
      Continue;
    end;

    lControlProvider := TAccessibilityVclControlProvider(lNodeInternal.ProviderObject);
    lScanNode := aTree.FindNode(lControl);
    if lScanNode = nil then
    begin
      Continue;
    end;
    lControlProvider.UpdateScannerName(lScanNode.Name);
    lLabelProvider := nil;
    if Supports(lScanNode, IAccessibilityScanNodeLabelRelationship, lRelationship) then
    begin
      lLabelControl := lRelationship.AssociatedLabelControl;
      if (lLabelControl <> nil) and
        fProviderNodesByControl.TryGetValue(Pointer(lLabelControl), lLabelNode) and
        not lLabelNode.IsDisconnected then
      begin
        lLabelProvider := lLabelNode.RawElementProvider;
      end;
    end;

    if lControlProvider.UpdateLabeledByProvider(lLabelProvider, lOldProvider) then
    begin
      lOldValue := Unassigned;
      lNewValue := Unassigned;
      if lOldProvider <> nil then
      begin
        lOldValue := lOldProvider as IUnknown;
      end;
      if lLabelProvider <> nil then
      begin
        lNewValue := lLabelProvider as IUnknown;
      end;
      TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(lNode.RawElementProvider,
        UIA_LabeledByPropertyId, lOldValue, lNewValue, fRuntimeApi); //PALOFF WARN44 event result is non-actionable
    end;
  end;
end;

function TAccessibilityVclFormProviderRoot.ReconcileProviderHierarchy(
  const aTree: IAccessibilityScanTree): Boolean;
var
  i: Integer;
  lControlKey: Pointer;
  lControlsToRemove: TList<Pointer>;
  lDesiredControls: THashSet<Pointer>;
  lHierarchy: IAccessibilityProviderHierarchyInternal;
  lHitTestRoot: IRawElementProviderFragmentRoot;
  lNode: IAccessibilityProviderNode;
begin
  Result := False;
  if (aTree = nil) or IsDisconnected then
  begin
    Exit;
  end;

  lDesiredControls := THashSet<Pointer>.Create;
  lControlsToRemove := TList<Pointer>.Create;
  try
    CollectScanControls(aTree.Root, lDesiredControls);
    for lControlKey in fProviderNodesByControl.Keys do
    begin
      if not lDesiredControls.Contains(lControlKey) then
      begin
        lControlsToRemove.Add(lControlKey);
      end;
    end;

    Result := AddMissingProviderChildren(Self as IAccessibilityProviderNode, aTree.Root);
    for i := 0 to Pred(lControlsToRemove.Count) do
    begin
      lControlKey := lControlsToRemove[i];
      if fProviderNodesByControl.TryGetValue(lControlKey, lNode) then
      begin
        if Supports(lNode, IRawElementProviderFragmentRoot, lHitTestRoot) then
        begin
          fHitTestRoots.Remove(lHitTestRoot);
        end;
        if Supports(lNode, IAccessibilityProviderHierarchyInternal, lHierarchy) then
        begin
          lHierarchy.DetachFromParent(True);
        end else begin
          lNode.Disconnect;
        end;
      end;
      fProviderNodesByControl.Remove(lControlKey);
      fProvidersByControl.Remove(lControlKey);
      Result := True;
    end;
  finally
    lControlsToRemove.Free;
    lDesiredControls.Free;
  end;
  ReconcileLabeledByRelationships(aTree);
end;

function TAccessibilityVclFormProviderRoot.TryFindProviderForControl(aControl: TControl;
  out aProvider: IRawElementProviderSimple): Boolean;
var
  lFragment: IRawElementProviderFragment;
begin
  aProvider := nil;
  lFragment := nil;
  Result := TryFindControlProvider(aControl, lFragment) and Supports(lFragment, IRawElementProviderSimple,
    aProvider);
end;

function TAccessibilityVclFormProviderRoot.VclGeometryPartitionsHoverTargets: Boolean;
begin
  Result := fHitTestRoots.Count = 0;
end;

function TAccessibilityVclFormProviderRoot.CanUseDirectHitTarget(aControl: TControl): Boolean;
begin
  Result := (aControl <> nil) and not (aControl is TPageControl) and not (aControl is TTabSheet);
end;

function TAccessibilityVclFormProviderRoot.ControlFromPoint(const aScreenPoint: TPoint): TControl;
var
  lClientPoint: TPoint;
begin
  Result := nil;
  if fForm <> nil then
  begin
    lClientPoint := fForm.ScreenToClient(aScreenPoint);
    if PtInRect(fForm.ClientRect, lClientPoint) then
    begin
      Result := fForm.ControlAtPos(lClientPoint, True, True, True);
    end;

    if Result <> nil then
    begin
      Exit;
    end;
  end;

  Result := FindDragTarget(aScreenPoint, True);
end;

function TAccessibilityVclFormProviderRoot.TryFindControlProvider(aControl: TControl;
  out aProvider: IRawElementProviderFragment): Boolean;
var
  lControl: TControl;
begin
  aProvider := nil;
  Result := False;
  if not ControlIsInActiveVisibleTree(aControl) then
  begin
    Exit;
  end;

  lControl := aControl;
  while lControl <> nil do
  begin
    if fProvidersByControl.TryGetValue(Pointer(lControl), aProvider) and (aProvider <> nil) then
    begin
      Exit(True);
    end;

    lControl := lControl.Parent;
  end;

  aProvider := nil;
end;

function TAccessibilityVclFormProviderRoot.TryFindTabHeaderProviderFromPoint(const aScreenPoint: TPoint;
  out aProvider: IRawElementProviderFragment): Boolean;
var
  lClientPoint: TPoint;
  lPageControl: TPageControl;
  lTabIndex: Integer;
  lTabSheet: TTabSheet;
  lWindow: TWinControl;
begin
  aProvider := nil;
  Result := False;
  lPageControl := nil;
  lWindow := FindVCLWindow(aScreenPoint);
  while lWindow <> nil do
  begin
    if lWindow is TPageControl then
    begin
      lPageControl := TPageControl(lWindow);
      Break;
    end;

    lWindow := lWindow.Parent;
  end;

  if lPageControl = nil then
  begin
    Exit;
  end;

  if (lPageControl = nil) or ((fForm <> nil) and not fForm.ContainsControl(lPageControl)) then
  begin
    Exit;
  end;

  lClientPoint := lPageControl.ScreenToClient(aScreenPoint);
  lTabIndex := lPageControl.IndexOfTabAt(lClientPoint.X, lClientPoint.Y);
  if (lTabIndex < 0) or (lTabIndex >= lPageControl.PageCount) then
  begin
    Exit;
  end;

  lTabSheet := lPageControl.Pages[lTabIndex];
  Result := TabSheetHeaderIsVisible(lTabSheet) and TryFindControlProvider(lTabSheet, aProvider);
end;

function TAccessibilityVclFormProviderRoot.DoElementProviderFromPoint(aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): HResult;
var
  i: Integer;
  lCandidates: THitTestCandidates;
  lProvider: IRawElementProviderFragment;
  lResult: HResult;
  lScreenPoint: TPoint;
  lTarget: TControl;
begin
  aProvider := nil;
  lScreenPoint := Point(Integer(Round(aX)), Integer(Round(aY)));
  if TryFindTabHeaderProviderFromPoint(lScreenPoint, aProvider) then
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

  lTarget := ControlFromPoint(lScreenPoint);
  if CanUseDirectHitTarget(lTarget) and ((fForm = nil) or fForm.ContainsControl(lTarget)) and
    TryFindControlProvider(lTarget, aProvider) then
  begin
    Exit(S_OK);
  end;

  lCandidates := Default(THitTestCandidates);
  FindHitTestCandidatesFromPoint(FragmentProvider, aX, aY, lScreenPoint, lCandidates);
  if lCandidates.TabHeader <> nil then
  begin
    aProvider := lCandidates.TabHeader;
    Exit(S_OK);
  end;

  if lCandidates.VisibleControl <> nil then
  begin
    aProvider := lCandidates.VisibleControl;
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
var
  lPublishNativeWindowHandle: Boolean;
  lTextInfo: TAccessibilityTextInfo;
begin
  inherited CreateNode(aRuntimeId, NativeWindowHandleForControl(aControl), aApi, aControl);
  fControl := aControl;
  fName := aName;
  fHelpText := aHelpText;
  lTextInfo := TAccessibilityTextExtractor.Extract(aControl);
  fLiveName := (ControlHasDirectCaption(aControl) or ControlHasDirectText(aControl)) and
    SameText(fName, lTextInfo.Name);
  fLiveHelpText := SameText(fHelpText, lTextInfo.HelpText);
  SetProperty(UIA_ControlTypePropertyId, aControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aControl.ClassName);
  lPublishNativeWindowHandle := ShouldPublishNativeWindowHandle(aControl);
  SetOverrideNativeProvider(lPublishNativeWindowHandle);
  if lPublishNativeWindowHandle then
  begin
    SetPublishNativeWindowHandle(True);
  end;
end;

function TAccessibilityVclControlProvider.Control: TControl;
begin
  Result := fControl;
end;

function TAccessibilityVclControlProvider.CurrentHelpText: string;
begin
  if fLiveHelpText then
  begin
    Exit(TAccessibilityTextExtractor.Extract(fControl).HelpText);
  end;
  Result := fHelpText;
end;

function TAccessibilityVclControlProvider.CurrentName: string;
var
  lValue: OleVariant;
begin
  if fLabeledByProvider <> nil then
  begin
    if (fLabeledByDirectAccess <> nil) and
      fLabeledByDirectAccess.TryGetStringProperty(UIA_NamePropertyId, Result) then
    begin
      Exit;
    end;

    if (fLabeledByProvider.GetPropertyValue(UIA_NamePropertyId, lValue) = S_OK) and
      not VarIsEmpty(lValue) and not VarIsNull(lValue) then
    begin
      Exit(VarToStr(lValue));
    end;
  end;

  if fLiveName then
  begin
    Exit(TAccessibilityTextExtractor.Extract(fControl).Name);
  end;
  Result := fName;
end;

procedure TAccessibilityVclControlProvider.SetLabeledByProvider(const aProvider: IRawElementProviderSimple);
begin
  fLabeledByProvider := aProvider;
  fLabeledByDirectAccess := nil;
  Supports(aProvider, IAccessibilityProviderDirectAccess, fLabeledByDirectAccess);
end;

function TAccessibilityVclControlProvider.UpdateLabeledByProvider(
  const aProvider: IRawElementProviderSimple; out aOldProvider: IRawElementProviderSimple): Boolean;
var
  lCurrentIdentity: IUnknown;
  lNewIdentity: IUnknown;
begin
  aOldProvider := fLabeledByProvider;
  lCurrentIdentity := nil;
  lNewIdentity := nil;
  if fLabeledByProvider <> nil then
  begin
    lCurrentIdentity := fLabeledByProvider as IUnknown;
  end;
  if aProvider <> nil then
  begin
    lNewIdentity := aProvider as IUnknown;
  end;
  Result := lCurrentIdentity <> lNewIdentity;
  if Result then
  begin
    SetLabeledByProvider(aProvider);
  end;
end;

procedure TAccessibilityVclControlProvider.UpdateScannerName(const aName: string);
var
  lTextInfo: TAccessibilityTextInfo;
begin
  fName := aName;
  lTextInfo := TAccessibilityTextExtractor.Extract(fControl);
  fLiveName := (ControlHasDirectCaption(fControl) or ControlHasDirectText(fControl)) and
    SameText(fName, lTextInfo.Name);
end;

function TAccessibilityVclControlProvider.TryGetLabeledByProperty(out aValue: OleVariant): Boolean;
begin
  Result := fLabeledByProvider <> nil;
  if Result then
  begin
    aValue := fLabeledByProvider as IUnknown;
  end else begin
    Result := inherited DoGetPropertyValue(UIA_LabeledByPropertyId, aValue);
  end;
end;

function TAccessibilityVclControlProvider.VclGeometryPartitionsHoverTargets: Boolean;
var
  lRoot: IRawElementProviderFragmentRoot;
begin
  Result := not Supports(Self, IRawElementProviderFragmentRoot, lRoot);
end;

function TAccessibilityVclControlProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fControl = nil) or IsDisconnected then
  begin
    Exit;
  end;

  Result := TryGetControlBoundingRectangle(fControl, aValue);
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
var
  lTabSheet: TTabSheet;
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
    UIA_LabeledByPropertyId: Result := TryGetLabeledByProperty(aValue);
    UIA_HelpTextPropertyId: aValue := CurrentHelpText;
    UIA_NamePropertyId: aValue := CurrentName;
    UIA_SelectionItemIsSelectedPropertyId:
      if fControl is TRadioButton then
      begin
        aValue := ReadBooleanProperty(fControl, 'Checked');
      end else if fControl is TTabSheet then
      begin
        lTabSheet := TTabSheet(fControl);
        aValue := (lTabSheet.PageControl <> nil) and (lTabSheet.PageControl.ActivePage = lTabSheet);
      end else begin
        Result := inherited DoGetPropertyValue(aPropertyId, aValue);
      end;
    UIA_ToggleToggleStatePropertyId:
      if ControlSupportsToggle(fControl) then
      begin
        if fControl is TCustomCheckBox then
        begin
          aValue := Integer(CheckBoxToggleState(fControl));
        end else if TSpeedButton(fControl).Down then
        begin
          aValue := Integer(ToggleState_On);
        end else begin
          aValue := Integer(ToggleState_Off);
        end;
      end else begin
        Result := inherited DoGetPropertyValue(aPropertyId, aValue);
      end;
  else
    Result := inherited DoGetPropertyValue(aPropertyId, aValue);
  end;
end;

procedure TAccessibilityVclOwnedProvider.DetachReparentedChildren(aOwner: TControl);
var
  i: Integer;
  lChild: IAccessibilityProviderNode;
  lChildControl: TControl;
  lChildInfo: IAccessibilityVclControlProviderInfo;
  lHierarchy: IAccessibilityProviderHierarchyInternal;
  lParent: TWinControl;
begin
  for i := Pred(ExistingChildCount) downto 0 do
  begin
    lChild := ExistingChildProviderAt(i);
    if (lChild = nil) or lChild.IsDisconnected or
      not Supports(lChild, IAccessibilityVclControlProviderInfo, lChildInfo) then
    begin
      Continue;
    end;

    lChildControl := lChildInfo.Control;
    if (lChildControl <> nil) and (csDestroying in lChildControl.ComponentState) then
    begin
      Continue;
    end;
    lParent := nil;
    if lChildControl <> nil then
    begin
      lParent := lChildControl.Parent;
    end;
    while (lParent <> nil) and (lParent <> aOwner) do
    begin
      lParent := lParent.Parent;
    end;
    if (lParent = nil) and Supports(lChild, IAccessibilityProviderHierarchyInternal, lHierarchy) then
    begin
      lHierarchy.DetachFromParent(False);
    end;
  end;
end;

procedure TAccessibilityVclControlProvider.PrepareForOwnerDisconnect;
begin
  DetachReparentedChildren(fControl);
  inherited PrepareForOwnerDisconnect;
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

  lTabSheet := TTabSheet(fControl); //PALOFF STWA6 provider contract fixes control type
  if (lTabSheet.PageControl <> nil) and (lTabSheet.PageControl.ActivePage = lTabSheet) then
  begin
    aRetVal := True;
  end;

  Result := S_OK;
end;

function TAccessibilityVclControlProvider.Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult;
begin
  aRetVal := nil;
  if IsDisconnected or not ((fControl is TTabSheet) or (fControl is TRadioButton)) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := ParentRawElementProvider;
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
var
  lValue: string;
begin
  aRetVal := '';
  if not TryGetValueText(lValue) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := lValue;
  Result := S_OK;
end;

function TAccessibilityVclControlProvider.TryGetValueText(out aValue: string): Boolean;
begin
  aValue := '';
  Result := (not IsDisconnected) and SupportsValue(fControl);
  if not Result then
  begin
    Exit;
  end;

  aValue := ReadStringProperty(fControl, 'Text');
  if (aValue = '') and (fControl is TCustomEdit) then
  begin
    aValue := ReadStringProperty(fControl, 'TextHint');
  end;
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
    lButton := TCustomButton(fControl); //PALOFF STWA6 provider contract fixes control type
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
    case TCheckBoxState(lState) of //PALOFF STWA6 validated UIA enum conversion
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
    SpeedButtonSupportsToggle(TSpeedButton(aControl))); //PALOFF STWA6 guarded by is TSpeedButton
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

  lTabSheet := TTabSheet(fControl); //PALOFF STWA6 provider contract fixes control type
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
  case TCheckBoxState(lState) of //PALOFF STWA6 validated UIA enum conversion
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

  lButton := TSpeedButton(fControl); //PALOFF STWA6 provider contract fixes control type
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
  SetPublishNativeWindowHandle(True);
  fMemo := aMemo;
  fProviderRuntimeId := aRuntimeId;
  fUiaApi := aApi;
  fLineIndexes := TList<Integer>.Create;
  fLines := TDictionary<Integer, IAccessibilityProviderNode>.Create;
  fLinesToRemove := TList<Integer>.Create;
end;

destructor TAccessibilityMemoProvider.Destroy;
begin
  fLinesToRemove.Free;
  fLineIndexes.Free;
  fLines.Free;
  inherited Destroy;
end;

function TAccessibilityMemoProvider.CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean;
begin
  Result := ChildrenPreparationIsCurrent and HasCurrentChildIndex(aChild);
end;

function TAccessibilityMemoProvider.ChildrenPreparationIsCurrent: Boolean;
var
  lFirstVisibleLineResult: LRESULT;
begin
  Result := False;
  if (fMemo = nil) or (not fPreparedValid) or IsDisconnected or not ControlIsInActiveVisibleTree(fMemo) then
  begin
    Exit;
  end;

  lFirstVisibleLineResult := SendMessage(fMemo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
  Result := (fPreparedHandle = fMemo.Handle) and (fPreparedClientWidth = fMemo.ClientWidth) and
    (fPreparedClientHeight = fMemo.ClientHeight) and
    (fPreparedLineCount = MemoLineCount(fMemo)) and
    (fPreparedFirstVisibleLine = Integer(lFirstVisibleLineResult));
end;

procedure TAccessibilityMemoProvider.AddLineProvider(aLine: Integer;
  const aProvider: IAccessibilityProviderNode);
var
  lInsertIndex: Integer;
begin
  if fLineIndexes.BinarySearch(aLine, lInsertIndex) then
  begin
    raise EInvalidOperation.CreateFmt('Memo line provider %d already exists.', [aLine]);
  end;

  fLines.Add(aLine, aProvider);
  try
    fLineIndexes.Insert(lInsertIndex, aLine);
    try
      InsertChildNode(lInsertIndex, aProvider);
    except
      fLineIndexes.Delete(lInsertIndex);
      raise;
    end;
  except
    fLines.Remove(aLine);
    raise;
  end;
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

  PrepareChildrenForNavigation;
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
  if (fMemo = nil) or (aLine < 0) or not MemoLineExists(fMemo, aLine) then
  begin
    Exit;
  end;

  Result := LineProvider(aLine);
  if Result = nil then
  begin
    Result := TAccessibilityMemoLineProvider.Create(fMemo, aLine, [fProviderRuntimeId, aLine], fUiaApi) as
      IAccessibilityProviderNode;
    AddLineProvider(aLine, Result);
  end;
end;

function TAccessibilityMemoProvider.EnsurePreparedLineProvider(aLine: Integer): IAccessibilityProviderNode;
begin
  Result := nil;
  if (fMemo = nil) or (aLine < 0) then
  begin
    Exit;
  end;

  Result := LineProvider(aLine);
  if Result = nil then
  begin
    Result := TAccessibilityMemoLineProvider.Create(fMemo, aLine, [fProviderRuntimeId, aLine], fUiaApi) as
      IAccessibilityProviderNode;
    AddLineProvider(aLine, Result);
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
    RemoveLineProvider(aLine, Result, False);
    Result := nil;
  end;
end;

procedure TAccessibilityMemoProvider.MaterializeVisibleLines(aFirstVisibleLine: Integer; aLastVisibleLine: Integer;
  aMetricsEnabled: Boolean; out aLineProbeCount: Integer; out aCreatedCount: Integer);
var
  lExistingProvider: IAccessibilityProviderNode;
  lLine: Integer;
begin
  aCreatedCount := 0;
  aLineProbeCount := 0;
  for lLine := aFirstVisibleLine to aLastVisibleLine do
  begin
    if aMetricsEnabled then
    begin
      Inc(aLineProbeCount);
      lExistingProvider := LineProvider(lLine);
      EnsurePreparedLineProvider(lLine);
      if (lExistingProvider = nil) and (LineProvider(lLine) <> nil) then
      begin
        Inc(aCreatedCount);
      end;
    end else begin
      EnsurePreparedLineProvider(lLine);
    end;
  end;
end;

procedure TAccessibilityMemoProvider.PruneLineProviders(aFirstVisibleLine: Integer; aLastVisibleLine: Integer);
var
  lLine: Integer;
  lLineProvider: IAccessibilityProviderNode;
  lPair: TPair<Integer, IAccessibilityProviderNode>;
begin
  fLinesToRemove.Clear;
  for lPair in fLines do
  begin
    if lPair.Value.IsDisconnected or (lPair.Key < aFirstVisibleLine) or (lPair.Key > aLastVisibleLine) then
    begin
      fLinesToRemove.Add(lPair.Key);
    end;
  end;

  for lLine in fLinesToRemove do
  begin
    if fLines.TryGetValue(lLine, lLineProvider) then
    begin
      RemoveLineProvider(lLine, lLineProvider, False);
    end;
  end;
end;

procedure TAccessibilityMemoProvider.RemoveLineProvider(aLine: Integer;
  const aProvider: IAccessibilityProviderNode; aDisconnect: Boolean);
var
  lIndex: Integer;
begin
  if aProvider <> nil then
  begin
    RemoveChildNode(aProvider, aDisconnect);
  end;
  fLines.Remove(aLine);
  if fLineIndexes.BinarySearch(aLine, lIndex) then
  begin
    fLineIndexes.Delete(lIndex);
  end;
end;

procedure TAccessibilityMemoProvider.RememberChildrenPreparation(aLineCount: Integer; aFirstVisibleLine: Integer);
begin
  fPreparedValid := False;
  if (fMemo = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fMemo) then
  begin
    Exit;
  end;

  fPreparedHandle := fMemo.Handle;
  fPreparedClientWidth := fMemo.ClientWidth;
  fPreparedClientHeight := fMemo.ClientHeight;
  fPreparedFirstVisibleLine := aFirstVisibleLine;
  fPreparedLineCount := aLineCount;
  fPreparedValid := True;
end;

function TAccessibilityMemoProvider.TryGetVisibleLineRange(aLineCount: Integer; out aFirstVisibleLine: Integer;
  out aLastVisibleLine: Integer): Boolean;
var
  lFirstVisibleLineResult: LRESULT;
  lLastLine: Integer;
  lLineHeight: Integer;
begin
  aFirstVisibleLine := 0;
  aLastVisibleLine := -1;
  Result := aLineCount > 0;
  if not Result then
  begin
    Exit;
  end;

  lLastLine := Pred(aLineCount);
  lLineHeight := TextLineHeight(fMemo);
  lFirstVisibleLineResult := SendMessage(fMemo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
  if lFirstVisibleLineResult > 0 then
  begin
    aFirstVisibleLine := Integer(lFirstVisibleLineResult);
  end;
  if aFirstVisibleLine > lLastLine then
  begin
    aFirstVisibleLine := lLastLine;
  end;
  aLastVisibleLine := Min(lLastLine, aFirstVisibleLine + Max(1, fMemo.ClientHeight div lLineHeight) + 1);
end;

procedure TAccessibilityMemoProvider.PrepareChildrenForNavigation;
var
  lCreatedCount: Integer;
  lFirstVisibleLine: Integer;
  lLineCount: Integer;
  lLineProbeCount: Integer;
  lLastVisibleLine: Integer;
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
begin
  inherited PrepareChildrenForNavigation;
  if (fMemo = nil) or not ControlIsInActiveVisibleTree(fMemo) then
  begin
    Exit;
  end;

  if ChildrenPreparationIsCurrent then
  begin
    Exit;
  end;

  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  lLineCount := MemoLineCount(fMemo);
  if not TryGetVisibleLineRange(lLineCount, lFirstVisibleLine, lLastVisibleLine) then
  begin
    PruneLineProviders(0, -1);
    if lMetricsEnabled then
    begin
      TAccessibilityDiagnostics.RecordMemoPrepareChildren(0, 0, lStopwatch.ElapsedTicks);
    end;
    RememberChildrenPreparation(lLineCount, 0);
    Exit;
  end;

  PruneLineProviders(lFirstVisibleLine, lLastVisibleLine);
  MaterializeVisibleLines(lFirstVisibleLine, lLastVisibleLine, lMetricsEnabled, lLineProbeCount, lCreatedCount);

  if lMetricsEnabled then
  begin
    TAccessibilityDiagnostics.RecordMemoPrepareChildren(lLineProbeCount, lCreatedCount, lStopwatch.ElapsedTicks);
  end;
  RememberChildrenPreparation(lLineCount, lFirstVisibleLine);
end;

constructor TAccessibilityListBoxItemProvider.Create(aOwner: TAccessibilityListBoxProvider; aListBox: TCustomListBox;
  aIndex: Integer; const aRuntimeId: array of Integer; const aApi: IAccessibilityUiaApi; const aRawText: string;
  const aCleanText: string);
begin
  inherited CreateNode(aRuntimeId, 0, aApi, nil);
  fOwner := aOwner;
  fListBox := aListBox;
  fIndex := aIndex;
  SetProperty(UIA_ControlTypePropertyId, UIA_ListItemControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, 'TListBoxItem');
  RefreshTextCache(aRawText, aCleanText);
end;

function TAccessibilityListBoxItemProvider.AddToSelection: HResult;
begin
  Result := Select;
end;

function TAccessibilityListBoxItemProvider.CurrentText: string;
var
  lRawText: string;
begin
  Result := '';
  if not ListBoxItemIndexExists(fListBox, fIndex) then
  begin
    Exit;
  end;

  lRawText := ListBoxRawItemText(fListBox, fIndex);
  if fTextCacheValid and (fCachedRawText = lRawText) then
  begin
    Exit(fCachedCleanText);
  end;

  Result := CleanListBoxItemText(lRawText);
  RefreshTextCache(lRawText, Result);
end;

function TAccessibilityListBoxItemProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lItemRect: TRect;
  lPoint: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if IsDisconnected then
  begin
    Exit;
  end;

  if ((fOwner = nil) or not fOwner.TryGetPreparedItemRect(fIndex, lItemRect)) and
    not ListBoxVisibleItemRect(fListBox, fIndex, lItemRect) then
  begin
    Exit;
  end;

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
      aValue := CurrentText;
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
  if fOwner <> nil then
  begin
    fOwner.ItemSelectionChanged(fIndex, aRetVal);
  end;
  Result := S_OK;
end;

function TAccessibilityListBoxItemProvider.Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult;
begin
  aRetVal := nil;
  if IsDisconnected or (fOwner = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  aRetVal := fOwner.RawElementProvider;
  Result := S_OK;
end;

function TAccessibilityListBoxItemProvider.IsVisibleItem: Boolean;
begin
  Result := ListBoxItemIsVisible(fListBox, fIndex);
end;

procedure TAccessibilityListBoxItemProvider.RefreshTextCache(const aRawText: string; const aCleanText: string);
begin
  fCachedRawText := aRawText;
  fCachedCleanText := aCleanText;
  fTextCacheValid := True;
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
    if fOwner <> nil then
    begin
      fOwner.ItemSelectionChanged(fIndex, False);
    end;
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
    if fOwner <> nil then
    begin
      fOwner.ItemSelectionChanged(fIndex, True);
    end;
  end;
  Result := S_OK;
end;

constructor TAccessibilityListBoxProvider.Create(aListBox: TCustomListBox; aRuntimeId: Integer;
  const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited Create(aListBox, [aRuntimeId], UIA_ListControlTypeId, aName, aHelpText, aApi);
  SetUseHostRawElementProvider(False);
  fItemIndexes := TList<Integer>.Create;
  fItems := TDictionary<Integer, IAccessibilityProviderNode>.Create;
  fItemRawTexts := TDictionary<Integer, string>.Create;
  fSelectedIndexes := THashSet<Integer>.Create;
  fListBox := aListBox;
  fProviderRuntimeId := aRuntimeId;
  fUiaApi := aApi;
end;

procedure TAccessibilityListBoxProvider.AddItemProvider(aIndex: Integer; const aRawText: string;
  const aProvider: IAccessibilityProviderNode);
var
  lInsertIndex: Integer;
begin
  if fItemIndexes.BinarySearch(aIndex, lInsertIndex) then
  begin
    raise EInvalidOperation.CreateFmt('Listbox item provider %d already exists.', [aIndex]);
  end;

  fItems.Add(aIndex, aProvider);
  try
    fItemRawTexts.Add(aIndex, aRawText);
    try
      fItemIndexes.Insert(lInsertIndex, aIndex);
      try
        InsertChildNode(lInsertIndex, aProvider);
      except
        fItemIndexes.Delete(lInsertIndex);
        raise;
      end;
    except
      fItemRawTexts.Remove(aIndex);
      raise;
    end;
  except
    fItems.Remove(aIndex);
    raise;
  end;
end;

function TAccessibilityListBoxProvider.CanUsePreparedSiblingNavigation(
  aChild: TAccessibilityProviderNode): Boolean;
begin
  Result := ChildrenPreparationIsCurrent;
  if not Result then
  begin
    Exit;
  end;

  if RefreshSelectedIndexes or (fPreparedFocusedIndex <> fListBox.ItemIndex) then
  begin
    ReconcilePreparedRetention(fListBox.ItemIndex);
  end;
  Result := HasCurrentChildIndex(aChild);
end;

function TAccessibilityListBoxProvider.ChildrenPreparationIsCurrent: Boolean;
begin
  Result := fPreparedValid and (fListBox <> nil) and (fPreparedHandle = fListBox.Handle) and
    (fPreparedItemCount = fListBox.Items.Count) and (fPreparedTopIndex = fListBox.TopIndex) and
    (fPreparedClientWidth = fListBox.ClientWidth) and (fPreparedClientHeight = fListBox.ClientHeight);
  if Result and not ListBoxUsesUniformItemHeight(fListBox) then
  begin
    Result := fPreparedItemHeight = ListBoxWindowItemHeight(fListBox);
  end;
end;

function TAccessibilityListBoxProvider.CreateMultiSelection(out aItemProbeCount: Integer;
  out aProviderCount: Integer): PSafeArray;
var
  lFirstVisibleIndex: Integer;
  lLastVisibleIndex: Integer;
  lSelectedIndexes: TArray<Integer>;
begin
  lSelectedIndexes := ListBoxSelectedIndexes(fListBox);
  RememberSelectedIndexes(lSelectedIndexes);
  if TryGetVisibleItemRange(lFirstVisibleIndex, lLastVisibleIndex) then
  begin
    PruneItemProviders(lFirstVisibleIndex, lLastVisibleIndex, fListBox.ItemIndex);
  end else begin
    PruneItemProviders(0, -1, fListBox.ItemIndex);
  end;
  aItemProbeCount := Length(lSelectedIndexes);
  Result := CreateSelectionArrayForSelectedIndexes(lSelectedIndexes, aProviderCount);
end;

function TAccessibilityListBoxProvider.CreateSelectionArrayForSelectedIndexes(const aSelectedIndexes: TArray<Integer>;
  out aProviderCount: Integer): PSafeArray;
var
  i: Integer;
  lData: Pointer;
  lItem: IAccessibilityProviderNode;
  lNewBounds: TSafeArrayBound;
  lUnknown: IUnknown;
begin
  aProviderCount := 0;
  Result := SafeArrayCreateVector(VT_UNKNOWN, 0, Length(aSelectedIndexes));
  if Result = nil then
  begin
    Exit;
  end;

  if Length(aSelectedIndexes) = 0 then
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
    for i := 0 to High(aSelectedIndexes) do
    begin
      lItem := EnsureItemProvider(aSelectedIndexes[i]);
      if lItem <> nil then
      begin
        lUnknown := lItem.RawElementProvider as IUnknown;
        PPointer(NativeUInt(lData) + NativeUInt(aProviderCount) * SizeOf(Pointer))^ := Pointer(lUnknown);
        lUnknown._AddRef;
        Inc(aProviderCount);
      end;
    end;
  finally
    SafeArrayUnaccessData(Result);
  end;

  if aProviderCount = 0 then
  begin
    SafeArrayDestroy(Result);
    Exit(SafeArrayCreateVector(VT_UNKNOWN, 0, 0));
  end;

  if aProviderCount < Length(aSelectedIndexes) then
  begin
    lNewBounds.lLbound := 0;
    lNewBounds.cElements := aProviderCount;
    if SafeArrayRedim(Result, @lNewBounds) <> S_OK then
    begin
      SafeArrayDestroy(Result);
      Result := nil;
    end;
  end;
end;

function TAccessibilityListBoxProvider.CreateSelectionArray(
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
  if (SafeArrayAccessData(Result, lData) <> S_OK) or (lData = nil) then
  begin
    SafeArrayDestroy(Result);
    Result := nil;
    Exit;
  end;

  try
    lUnknown := aProvider as IUnknown;
    PPointer(lData)^ := Pointer(lUnknown);
    lUnknown._AddRef;
  finally
    SafeArrayUnaccessData(Result);
  end;
end;

function TAccessibilityListBoxProvider.CreateSingleSelection(out aItemProbeCount: Integer;
  out aProviderCount: Integer): PSafeArray;
var
  lFirstVisibleIndex: Integer;
  lItem: IAccessibilityProviderNode;
  lLastVisibleIndex: Integer;
  lProvider: IRawElementProviderSimple;
begin
  aItemProbeCount := 1;
  aProviderCount := 0;
  lProvider := nil;
  if TryGetVisibleItemRange(lFirstVisibleIndex, lLastVisibleIndex) then
  begin
    PruneItemProviders(lFirstVisibleIndex, lLastVisibleIndex, fListBox.ItemIndex);
  end else begin
    PruneItemProviders(0, -1, fListBox.ItemIndex);
  end;
  lItem := EnsureItemProvider(fListBox.ItemIndex);
  if lItem <> nil then
  begin
    lProvider := lItem.RawElementProvider;
    aProviderCount := 1;
  end;
  Result := CreateSelectionArray(lProvider);
end;

destructor TAccessibilityListBoxProvider.Destroy;
begin
  fSelectedIndexes.Free;
  fItemIndexes.Free;
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

  PrepareChildrenForNavigation;
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
  lCache: IAccessibilityListBoxItemTextCache;
  lCleanText: string;
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

    lCleanText := CleanListBoxItemText(lRawText);
    if lCleanText = '' then
    begin
      RemoveItemProvider(aIndex, Result, True);
      Result := nil;
      Exit;
    end;

    if Supports(Result.RawElementProvider, IAccessibilityListBoxItemTextCache, lCache) then
    begin
      lCache.RefreshTextCache(lRawText, lCleanText);
    end;
    fItemRawTexts.AddOrSetValue(aIndex, lRawText);
    TAccessibilityDiagnostics.RecordListBoxEnsureItemProvider(False);
    Exit;
  end;

  lCleanText := CleanListBoxItemText(lRawText);
  if lCleanText = '' then
  begin
    Exit;
  end;

  if Result = nil then
  begin
    lCreated := True;
    Result := TAccessibilityListBoxItemProvider.Create(Self, fListBox, aIndex, [fProviderRuntimeId, aIndex], fUiaApi,
      lRawText, lCleanText) as IAccessibilityProviderNode;
    AddItemProvider(aIndex, lRawText, Result);
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
    if not ChildrenPreparationIsCurrent then
    begin
      PrepareChildrenForNavigation;
    end else if RefreshSelectedIndexes or (fPreparedFocusedIndex <> fListBox.ItemIndex) then
    begin
      ReconcilePreparedRetention(fListBox.ItemIndex);
    end;
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
  lItemProbeCount: Integer;
  lMetricsEnabled: Boolean;
  lProviderCount: Integer;
  lStopwatch: TStopwatch;
begin
  aRetVal := nil;
  if IsDisconnected or (fListBox = nil) then
  begin
    Exit(UIA_E_ELEMENTNOTAVAILABLE);
  end;

  TAccessibilityDiagnostics.RecordListBoxGetSelection;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  if fListBox.MultiSelect then
  begin
    aRetVal := CreateMultiSelection(lItemProbeCount, lProviderCount);
  end else begin
    aRetVal := CreateSingleSelection(lItemProbeCount, lProviderCount);
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
    RemoveItemProvider(aIndex, Result, False);
    Result := nil;
  end;
end;

procedure TAccessibilityListBoxProvider.ItemSelectionChanged(aIndex: Integer; aSelected: Boolean);
var
  lWasSelected: Boolean;
begin
  if not fSelectedIndexesValid then
  begin
    Exit;
  end;

  lWasSelected := fSelectedIndexes.Contains(aIndex);
  if lWasSelected = aSelected then
  begin
    Exit;
  end;

  if aSelected then
  begin
    fSelectedIndexes.Add(aIndex);
  end else begin
    fSelectedIndexes.Remove(aIndex);
  end;
  fPreparedValid := False;
end;

function TAccessibilityListBoxProvider.ListBoxOwnsFocus: Boolean;
begin
  Result := ListBoxOwnsKeyboardFocus(fListBox);
end;

procedure TAccessibilityListBoxProvider.PruneItemProviders(aFirstVisibleIndex: Integer; aLastVisibleIndex: Integer;
  aFocusedIndex: Integer);
var
  lIndex: Integer;
  lItemCount: Integer;
  lItemProvider: IAccessibilityProviderNode;
  lPosition: Integer;
  lRemovedIndexes: TList<Integer>;
  lRemovalFlags: TArray<Boolean>;
  lRetainedIndexes: TList<Integer>;
begin
  lRemovedIndexes := nil;
  lRetainedIndexes := nil;
  try
    lRemovedIndexes := TList<Integer>.Create;
    lRetainedIndexes := TList<Integer>.Create;
    lItemCount := fListBox.Items.Count;
    lRemovedIndexes.Capacity := fItemIndexes.Count;
    lRetainedIndexes.Capacity := fItemIndexes.Count;
    SetLength(lRemovalFlags, fItemIndexes.Count);
    for lPosition := 0 to Pred(fItemIndexes.Count) do
    begin
      lIndex := fItemIndexes[lPosition];
      lItemProvider := nil;
      if fItems.TryGetValue(lIndex, lItemProvider) and ShouldRetainItemProvider(lIndex, lItemProvider,
        lItemCount, aFirstVisibleIndex, aLastVisibleIndex, aFocusedIndex) then
      begin
        lRetainedIndexes.Add(lIndex);
      end else begin
        lRemovedIndexes.Add(lIndex);
        lRemovalFlags[lPosition] := True;
      end;
    end;

    if lRemovedIndexes.Count = 0 then
    begin
      Exit;
    end;
    RemoveItemProviderChildren(lRemovalFlags, lRemovedIndexes.Count);
    for lIndex in lRemovedIndexes do
    begin
      fItems.Remove(lIndex);
      fItemRawTexts.Remove(lIndex);
    end;
    fItemIndexes.Free;
    fItemIndexes := lRetainedIndexes;
    lRetainedIndexes := nil;
  finally
    lRetainedIndexes.Free;
    lRemovedIndexes.Free;
  end;
end;

procedure TAccessibilityListBoxProvider.RemoveItemProviderChildren(
  const aRemovalFlags: TArray<Boolean>; aRemovedCount: Integer);
var
  lItemProvider: IAccessibilityProviderNode;
  lPosition: Integer;
  lRemovedProviders: TList<IAccessibilityProviderNode>;
begin
  if RemoveChildNodesByIndexFlags(aRemovalFlags, aRemovedCount, False) then
  begin
    Exit;
  end;

  lRemovedProviders := TList<IAccessibilityProviderNode>.Create;
  try
    lRemovedProviders.Capacity := aRemovedCount;
    for lPosition := 0 to High(aRemovalFlags) do
    begin
      if aRemovalFlags[lPosition] and
        fItems.TryGetValue(fItemIndexes[lPosition], lItemProvider) then
      begin
        lRemovedProviders.Add(lItemProvider);
      end;
    end;
    if lRemovedProviders.Count > 0 then
    begin
      RemoveChildNodes(lRemovedProviders.ToArray, False);
    end;
  finally
    lRemovedProviders.Free;
  end;
end;

procedure TAccessibilityListBoxProvider.RemoveItemProvider(aIndex: Integer;
  const aProvider: IAccessibilityProviderNode; aDisconnect: Boolean);
var
  lItemIndex: Integer;
begin
  lItemIndex := -1;
  fItemIndexes.BinarySearch(aIndex, lItemIndex);
  RemoveItemProviderAt(lItemIndex, aIndex, aProvider, aDisconnect);
end;

procedure TAccessibilityListBoxProvider.RemoveItemProviderAt(aItemPosition: Integer; aIndex: Integer;
  const aProvider: IAccessibilityProviderNode; aDisconnect: Boolean);
begin
  if aProvider <> nil then
  begin
    RemoveChildNode(aProvider, aDisconnect);
  end;
  fItems.Remove(aIndex);
  fItemRawTexts.Remove(aIndex);
  if (aItemPosition >= 0) and (aItemPosition < fItemIndexes.Count) and
    (fItemIndexes[aItemPosition] = aIndex) then
  begin
    fItemIndexes.Delete(aItemPosition);
  end;
end;

procedure TAccessibilityListBoxProvider.ReconcilePreparedRetention(aFocusedIndex: Integer);
begin
  if (fListBox = nil) or not fPreparedValid then
  begin
    Exit;
  end;

  PruneItemProviders(fPreparedFirstVisibleIndex, fPreparedLastVisibleIndex, aFocusedIndex);
  if ListBoxItemIndexExists(fListBox, aFocusedIndex) and (ItemProvider(aFocusedIndex) = nil) then
  begin
    EnsureItemProvider(aFocusedIndex);
  end;
  fPreparedFocusedIndex := aFocusedIndex;
end;

function TAccessibilityListBoxProvider.RefreshSelectedIndexes: Boolean;
var
  lIndex: Integer;
  lSelectedIndexes: TArray<Integer>;
begin
  if (fListBox = nil) or not fListBox.MultiSelect then
  begin
    Result := fSelectedIndexesValid or (fSelectedIndexes.Count > 0);
    fSelectedIndexes.Clear;
    fSelectedIndexesValid := False;
    fSelectionDirty := False;
    Exit;
  end;

  if fSelectionTracking and fSelectedIndexesValid and not fSelectionDirty then
  begin
    Exit(False);
  end;

  lSelectedIndexes := ListBoxSelectedIndexes(fListBox);
  Result := not fSelectedIndexesValid or (fSelectedIndexes.Count <> Length(lSelectedIndexes));
  if not Result then
  begin
    for lIndex in lSelectedIndexes do
    begin
      if not fSelectedIndexes.Contains(lIndex) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  if Result then
  begin
    RememberSelectedIndexes(lSelectedIndexes);
  end else begin
    fSelectionDirty := False;
  end;
end;

function TAccessibilityListBoxProvider.ShouldRetainItemProvider(aIndex: Integer;
  const aProvider: IAccessibilityProviderNode; aItemCount: Integer; aFirstVisibleIndex: Integer;
  aLastVisibleIndex: Integer; aFocusedIndex: Integer): Boolean;
begin
  Result := not aProvider.IsDisconnected and (aIndex >= 0) and (aIndex < aItemCount);
  if not Result then
  begin
    Exit;
  end;

  Result := ((aIndex >= aFirstVisibleIndex) and (aIndex <= aLastVisibleIndex)) or
    (aIndex = aFocusedIndex);
  if not Result and fListBox.MultiSelect then
  begin
    Result := fSelectedIndexes.Contains(aIndex);
  end;
end;

procedure TAccessibilityListBoxProvider.RememberChildrenPreparation(aFirstVisibleIndex: Integer;
  aLastVisibleIndex: Integer);
begin
  if fListBox = nil then
  begin
    fPreparedValid := False;
    Exit;
  end;

  fPreparedHandle := fListBox.Handle;
  fPreparedFirstVisibleIndex := aFirstVisibleIndex;
  fPreparedFocusedIndex := fListBox.ItemIndex;
  fPreparedItemCount := fListBox.Items.Count;
  fPreparedTopIndex := fListBox.TopIndex;
  fPreparedClientWidth := fListBox.ClientWidth;
  fPreparedClientHeight := fListBox.ClientHeight;
  fPreparedItemHeight := ListBoxWindowItemHeight(fListBox);
  fPreparedLastVisibleIndex := aLastVisibleIndex;
  fPreparedValid := True;
end;

procedure TAccessibilityListBoxProvider.RememberSelectedIndexes(const aSelectedIndexes: TArray<Integer>);
var
  lIndex: Integer;
begin
  fSelectedIndexes.Clear;
  for lIndex in aSelectedIndexes do
  begin
    fSelectedIndexes.Add(lIndex);
  end;
  fSelectedIndexesValid := True;
  fSelectionDirty := False;
end;

procedure TAccessibilityListBoxProvider.SelectionMayHaveChanged;
begin
  if fSelectionTracking then
  begin
    fSelectionDirty := True;
  end;
end;

procedure TAccessibilityListBoxProvider.StartSelectionTracking;
begin
  fSelectionTracking := True;
  fSelectionDirty := True;
end;

function TAccessibilityListBoxProvider.TryGetVisibleItemRange(out aFirstVisibleIndex: Integer;
  out aLastVisibleIndex: Integer): Boolean;
var
  i: Integer;
  lItemHeight: Integer;
  lItemRect: TRect;
  lLastIndex: Integer;
  lVisibleCount: Integer;
begin
  aFirstVisibleIndex := 0;
  aLastVisibleIndex := -1;
  Result := False;
  if (fListBox = nil) or (fListBox.Items.Count = 0) then
  begin
    Exit;
  end;

  lLastIndex := Pred(fListBox.Items.Count);
  aFirstVisibleIndex := EnsureRange(fListBox.TopIndex, 0, lLastIndex);
  if ListBoxUsesUniformItemHeight(fListBox) then
  begin
    lItemHeight := ListBoxWindowItemHeight(fListBox);
    if lItemHeight <= 0 then
    begin
      Exit;
    end;

    lVisibleCount := (Max(0, fListBox.ClientHeight) + lItemHeight - 1) div lItemHeight;
    if lVisibleCount <= 0 then
    begin
      Exit;
    end;

    aLastVisibleIndex := Min(lLastIndex, aFirstVisibleIndex + lVisibleCount - 1);
    Exit(True);
  end;

  for i := aFirstVisibleIndex to lLastIndex do
  begin
    TAccessibilityDiagnostics.RecordListBoxVisibleItemProbe;
    lItemRect := fListBox.ItemRect(i);
    if (i > aFirstVisibleIndex) and (lItemRect.Top >= fListBox.ClientHeight) then
    begin
      Break;
    end;

    if ListBoxItemRectIsVisible(fListBox, lItemRect) then
    begin
      aLastVisibleIndex := i;
      Result := True;
    end;
  end;
end;

function TAccessibilityListBoxProvider.TryGetPreparedItemRect(aIndex: Integer; out aItemRect: TRect): Boolean;
var
  lTop: Integer;
begin
  aItemRect := TRect.Empty;
  Result := False;
  if (fListBox = nil) or not fPreparedValid or not ListBoxUsesUniformItemHeight(fListBox) or
    not ChildrenPreparationIsCurrent or not ControlIsInActiveVisibleTree(fListBox) then
  begin
    Exit;
  end;

  if (aIndex < fPreparedTopIndex) or (aIndex >= fPreparedItemCount) or (fPreparedItemHeight <= 0) or
    (fPreparedClientWidth <= 0) then
  begin
    Exit;
  end;

  lTop := (aIndex - fPreparedTopIndex) * fPreparedItemHeight;
  aItemRect := Rect(0, lTop, fPreparedClientWidth, lTop + fPreparedItemHeight);
  Result := ListBoxItemRectIsVisible(fListBox, aItemRect);
end;

procedure TAccessibilityListBoxProvider.PrepareChildrenForNavigation;
var
  i: Integer;
  lFirstVisibleIndex: Integer;
  lFocusedIndex: Integer;
  lHasVisibleItems: Boolean;
  lSelectionChanged: Boolean;
  lVisibleLastIndex: Integer;
begin
  inherited PrepareChildrenForNavigation;
  if (fListBox = nil) or not ControlIsInActiveVisibleTree(fListBox) then
  begin
    Exit;
  end;

  lSelectionChanged := RefreshSelectedIndexes;
  if ChildrenPreparationIsCurrent then
  begin
    if lSelectionChanged or (fPreparedFocusedIndex <> fListBox.ItemIndex) then
    begin
      ReconcilePreparedRetention(fListBox.ItemIndex);
    end;
    Exit;
  end;

  TAccessibilityDiagnostics.RecordListBoxPrepareChildren;
  lFocusedIndex := fListBox.ItemIndex;
  if fListBox.Items.Count = 0 then
  begin
    PruneItemProviders(0, -1, -1);
    RememberChildrenPreparation(0, -1);
    Exit;
  end;

  lHasVisibleItems := TryGetVisibleItemRange(lFirstVisibleIndex, lVisibleLastIndex);
  PruneItemProviders(lFirstVisibleIndex, lVisibleLastIndex, lFocusedIndex);
  if lHasVisibleItems then
  begin
    for i := lFirstVisibleIndex to lVisibleLastIndex do
    begin
      EnsureItemProvider(i);
    end;
  end;

  if ((lFocusedIndex < lFirstVisibleIndex) or (lFocusedIndex > lVisibleLastIndex)) and
    ListBoxItemIndexExists(fListBox, lFocusedIndex) then
  begin
    EnsureItemProvider(lFocusedIndex);
  end;
  RememberChildrenPreparation(lFirstVisibleIndex, lVisibleLastIndex);
end;

constructor TAccessibilityStatusBarProvider.Create(aStatusBar: TCustomStatusBar; const aRuntimeId: array of Integer;
  const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode(aRuntimeId, NativeWindowHandleForControl(aStatusBar), aApi, aStatusBar);
  SetPublishNativeWindowHandle(True);
  fStatusBar := aStatusBar;
  fHelpText := aHelpText;
  fLiveHelpText := SameText(fHelpText, TAccessibilityTextExtractor.Extract(aStatusBar).HelpText);
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
      if fLiveHelpText then
      begin
        aValue := TAccessibilityTextExtractor.Extract(fStatusBar).HelpText;
      end else begin
        aValue := fHelpText;
      end;
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

procedure TAccessibilityStatusBarProvider.PrepareForOwnerDisconnect;
begin
  DetachReparentedChildren(fStatusBar);
  inherited PrepareForOwnerDisconnect;
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
  lCellProbeCount: Integer;
  lCellRect: TRect;
  lMetricsEnabled: Boolean;
  lStopwatch: TStopwatch;
  lTopLeft: TPoint;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fGrid = nil) or IsDisconnected then
  begin
    Exit;
  end;

  lCellProbeCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  try
    if lMetricsEnabled then
    begin
      Inc(lCellProbeCount);
    end;

    if not TryGetVisibleGridCellRect(fGrid, fCol, fRow, lCellRect) then
    begin
      Exit;
    end;

    lTopLeft := fGrid.ClientToScreen(lCellRect.TopLeft);
    aValue.Left := lTopLeft.X;
    aValue.Top := lTopLeft.Y;
    aValue.Width := lCellRect.Width;
    aValue.Height := lCellRect.Height;
    Result := True;
  finally
    if lMetricsEnabled then
    begin
      TAccessibilityDiagnostics.RecordStringGridCellBounds(lCellProbeCount, lStopwatch.ElapsedTicks);
    end;
  end;
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
  lCellProbeCount: Integer;
  lCol: Integer;
  lFirstScrollableCol: Integer;
  lFixedColCount: Integer;
  lHeight: Integer;
  lLastScrollableCol: Integer;
  lLeft: Integer;
  lMetricsEnabled: Boolean;
  lRight: Integer;
  lStopwatch: TStopwatch;
  lTop: Integer;
  lTopLeft: TPoint;
  lVisibleCellFound: Boolean;
begin
  aValue := Default(UiaRect);
  Result := False;
  if (fGrid = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) or
    (fRow < 0) or (fRow >= fGrid.RowCount) then
  begin
    Exit;
  end;

  lLeft := MaxInt;
  lRight := 0;
  lTop := 0;
  lHeight := 0;
  lVisibleCellFound := False;
  lCellProbeCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  try
    lFixedColCount := Min(fGrid.FixedCols, fGrid.ColCount); //PALOFF WARN52 same-width bounded count
    for lCol := 0 to Pred(lFixedColCount) do
    begin
      IncludeGridRowBoundsCell(fGrid, fRow, lCol, lLeft, lRight, lTop, lHeight, lVisibleCellFound,
        lMetricsEnabled, lCellProbeCount);
    end;

    if fGrid.ColCount > 0 then
    begin
      lFirstScrollableCol := EnsureRange(fGrid.LeftCol, 0, Pred(fGrid.ColCount));
      lLastScrollableCol := Min(Pred(fGrid.ColCount), lFirstScrollableCol + Max(0, fGrid.VisibleColCount) + 1);
      for lCol := lFirstScrollableCol to lLastScrollableCol do
      begin
        if lCol >= lFixedColCount then
        begin
          IncludeGridRowBoundsCell(fGrid, fRow, lCol, lLeft, lRight, lTop, lHeight, lVisibleCellFound,
            lMetricsEnabled, lCellProbeCount);
        end;
      end;
    end;
  finally
    if lMetricsEnabled then
    begin
      TAccessibilityDiagnostics.RecordStringGridRowBounds(lCellProbeCount, lStopwatch.ElapsedTicks);
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
  RememberChildrenPreparation;
end;

function TAccessibilityStringGridProvider.CanUsePreparedSiblingNavigation(aChild: TAccessibilityProviderNode): Boolean;
begin
  Result := ChildrenPreparationIsCurrent and HasCurrentChildIndex(aChild);
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

function TAccessibilityStringGridProvider.ChildrenPreparationIsCurrent: Boolean;
begin
  Result := False;
  if (fGrid = nil) or (not fPreparedValid) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) then
  begin
    Exit;
  end;

  if GridUsesRowSelection(fGrid) and (fRows.Count = 0) then
  begin
    Exit;
  end;

  Result := (fPreparedHandle = fGrid.Handle) and (fPreparedClientWidth = fGrid.ClientWidth) and
    (fPreparedClientHeight = fGrid.ClientHeight) and (fPreparedColCount = fGrid.ColCount) and
    (fPreparedRowCount = fGrid.RowCount) and (fPreparedFixedCols = fGrid.FixedCols) and
    (fPreparedFixedRows = fGrid.FixedRows) and (fPreparedLeftCol = fGrid.LeftCol) and
    (fPreparedTopRow = fGrid.TopRow) and (fPreparedVisibleColCount = fGrid.VisibleColCount) and
    (fPreparedVisibleRowCount = fGrid.VisibleRowCount) and (fPreparedOptions = fGrid.Options);
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
  Result := CellProvider(aCol, aRow);
  if (Result <> nil) and ChildrenPreparationIsCurrent then
  begin
    Exit;
  end;

  RefreshVisibleCells;
  fPreparedValid := False;
  Result := EnsureCellProviderDirect(aCol, aRow);
end;

function TAccessibilityStringGridProvider.EnsureCellProviderDirect(aCol: Integer; aRow: Integer):
  IAccessibilityProviderNode;
var
  lKey: Int64;
begin
  lKey := CellKey(aCol, aRow);
  Result := CellProvider(aCol, aRow);
  if Result = nil then
  begin
    fCells.Remove(lKey);
  end;

  if (Result = nil) and (fGrid <> nil) and (aCol >= 0) and (aCol < fGrid.ColCount) and
    (aRow >= 0) and (aRow < fGrid.RowCount) then
  begin
    Result := TAccessibilityStringGridCellProvider.Create(Self, fGrid, aCol, aRow,
      [fProviderRuntimeId, aRow, aCol], fUiaApi) as
      IAccessibilityProviderNode;
    AddChild(Result);
    fCells.Add(lKey, Result);
  end;
end;

function TAccessibilityStringGridProvider.EnsureRowProvider(aRow: Integer): IAccessibilityProviderNode;
begin
  RefreshVisibleRows;
  fPreparedValid := False;
  Result := EnsureRowProviderDirect(aRow);
end;

function TAccessibilityStringGridProvider.EnsureRowProviderDirect(aRow: Integer): IAccessibilityProviderNode;
begin
  Result := RowProvider(aRow);
  if Result = nil then
  begin
    fRows.Remove(aRow);
  end;

  if (Result = nil) and (fGrid <> nil) and GridUsesRowSelection(fGrid) and GridRowIsVisible(fGrid, aRow) then
  begin
    Result := TAccessibilityStringGridRowProvider.Create(Self, fGrid, aRow,
      [fProviderRuntimeId, aRow, fGrid.ColCount],
      fUiaApi) as IAccessibilityProviderNode;
    AddChild(Result);
    fRows.Add(aRow, Result);
  end;
end;

procedure TAccessibilityStringGridProvider.EnsureVisibleCellProvider(aCol: Integer; aRow: Integer;
  aMetricsEnabled: Boolean; var aCellProbeCount: Integer; var aCreatedCount: Integer);
var
  lCell: IAccessibilityProviderNode;
begin
  if aMetricsEnabled then
  begin
    Inc(aCellProbeCount);
  end;

  if IsVisibleCell(aCol, aRow) and (CellProvider(aCol, aRow) = nil) then
  begin
    lCell := TAccessibilityStringGridCellProvider.Create(Self, fGrid, aCol, aRow,
      [fProviderRuntimeId, aRow, aCol], fUiaApi) as IAccessibilityProviderNode;
    AddChild(lCell);
    fCells.Add(CellKey(aCol, aRow), lCell);
    if aMetricsEnabled then
    begin
      Inc(aCreatedCount);
    end;
  end;
end;

procedure TAccessibilityStringGridProvider.EnsureVisibleRowProvider(aRow: Integer; aMetricsEnabled: Boolean;
  var aRowProbeCount: Integer; var aCreatedCount: Integer);
var
  lRowProvider: IAccessibilityProviderNode;
begin
  if aMetricsEnabled then
  begin
    Inc(aRowProbeCount);
  end;

  if GridRowIsVisible(fGrid, aRow) and (RowProvider(aRow) = nil) then
  begin
    lRowProvider := TAccessibilityStringGridRowProvider.Create(Self, fGrid, aRow,
      [fProviderRuntimeId, aRow, fGrid.ColCount], fUiaApi) as IAccessibilityProviderNode;
    AddChild(lRowProvider);
    fRows.Add(aRow, lRowProvider);
    if aMetricsEnabled then
    begin
      Inc(aCreatedCount);
    end;
  end;
end;

procedure TAccessibilityStringGridProvider.RefreshVisibleCells;
var
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
  lGridIsVisible: Boolean;
  lMetricsEnabled: Boolean;
  lPair: TPair<Int64, IAccessibilityProviderNode>;
  lRow: Integer;
  lCell: IAccessibilityProviderNode;
  lStopwatch: TStopwatch;
begin
  if (fGrid = nil) or IsDisconnected then
  begin
    Exit;
  end;

  lGridIsVisible := ControlIsInActiveVisibleTree(fGrid);
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
      if lPair.Value.IsDisconnected or (CellKeyCol(lPair.Key) < 0) or
        (CellKeyCol(lPair.Key) >= fGrid.ColCount) or (CellKeyRow(lPair.Key) < 0) or
        (CellKeyRow(lPair.Key) >= fGrid.RowCount) or
        (lGridIsVisible and not IsVisibleCell(CellKeyCol(lPair.Key), CellKeyRow(lPair.Key))) then
      begin
        if lKeysToRemove = nil then
        begin
          lKeysToRemove := TList<Int64>.Create;
          if lMetricsEnabled then
          begin
            TAccessibilityDiagnostics.RecordStringGridRefreshScratchListAllocation(1);
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

  if not lGridIsVisible or (fGrid.ColCount <= 0) or (fGrid.RowCount <= 0) then
  begin
    Exit;
  end;

  lFixedColCount := Min(fGrid.FixedCols, fGrid.ColCount); //PALOFF WARN52 same-width bounded count
  lFixedRowCount := Min(fGrid.FixedRows, fGrid.RowCount); //PALOFF WARN52 same-width bounded count
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
    TAccessibilityDiagnostics.RecordStringGridRefresh(lCellProbeCount, lCreatedCount, lStopwatch.ElapsedTicks);
  end;
end;

procedure TAccessibilityStringGridProvider.RefreshVisibleRows;
var
  lCreatedCount: Integer;
  lFixedRowCount: Integer;
  lFirstScrollableRow: Integer;
  lLastScrollableRow: Integer;
  lMetricsEnabled: Boolean;
  lKeysToRemove: TList<Integer>;
  lPair: TPair<Integer, IAccessibilityProviderNode>;
  lRow: Integer;
  lRowProbeCount: Integer;
  lRowProvider: IAccessibilityProviderNode;
  lStopwatch: TStopwatch;
begin
  if (fGrid = nil) or IsDisconnected or not ControlIsInActiveVisibleTree(fGrid) or not GridUsesRowSelection(fGrid) then
  begin
    ClearRowProviders;
    Exit;
  end;

  lCreatedCount := 0;
  lRowProbeCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;

  lKeysToRemove := nil;
  try
    for lPair in fRows do
    begin
      if lPair.Value.IsDisconnected or not GridRowIsVisible(fGrid, lPair.Key) then
      begin
        if lKeysToRemove = nil then
        begin
          lKeysToRemove := TList<Integer>.Create;
          if lMetricsEnabled then
          begin
            TAccessibilityDiagnostics.RecordStringGridRowRefreshScratchListAllocation(1);
          end;
        end;
        lKeysToRemove.Add(lPair.Key);
      end;
    end;

    if lKeysToRemove <> nil then
    begin
      for lRow in lKeysToRemove do
      begin
        if fRows.TryGetValue(lRow, lRowProvider) then
        begin
          RemoveChildNode(lRowProvider, False);
          fRows.Remove(lRow);
        end;
      end;
    end;
  finally
    lKeysToRemove.Free;
  end;

  if fGrid.RowCount <= 0 then
  begin
    Exit;
  end;

  lFixedRowCount := Min(fGrid.FixedRows, fGrid.RowCount); //PALOFF WARN52 same-width bounded count
  lFirstScrollableRow := EnsureRange(fGrid.TopRow, 0, Pred(fGrid.RowCount));
  lLastScrollableRow := Min(Pred(fGrid.RowCount), lFirstScrollableRow + Max(0, fGrid.VisibleRowCount) + 1);

  for lRow := 0 to Pred(lFixedRowCount) do
  begin
    EnsureVisibleRowProvider(lRow, lMetricsEnabled, lRowProbeCount, lCreatedCount);
  end;

  for lRow := lFirstScrollableRow to lLastScrollableRow do
  begin
    if lRow >= lFixedRowCount then
    begin
      EnsureVisibleRowProvider(lRow, lMetricsEnabled, lRowProbeCount, lCreatedCount);
    end;
  end;

  if lMetricsEnabled then
  begin
    TAccessibilityDiagnostics.RecordStringGridRowRefresh(lRowProbeCount, lCreatedCount, lStopwatch.ElapsedTicks);
  end;
end;

procedure TAccessibilityStringGridProvider.RememberChildrenPreparation;
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
  fPreparedOptions := fGrid.Options;
  fPreparedValid := True;
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
var
  lTextInfo: TAccessibilityTextInfo;
begin
  inherited CreateNode([aRuntimeId], aGrid.Handle, aApi, aGrid);
  SetPublishNativeWindowHandle(True);
  fCells := TDictionary<Int64, IAccessibilityProviderNode>.Create;
  fRows := TDictionary<Integer, IAccessibilityProviderNode>.Create;
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

function TAccessibilityStringGridProvider.TryGetFocusedItem(out aProvider: IRawElementProviderSimple;
  out aName: string): Boolean;
var
  lItem: IAccessibilityProviderNode;
begin
  aProvider := nil;
  aName := '';
  Result := False;
  if IsDisconnected or (fGrid = nil) or not ControlIsInActiveVisibleTree(fGrid) or not GridOwnsFocus then
  begin
    Exit;
  end;

  if GridUsesRowSelection(fGrid) then
  begin
    lItem := EnsureRowProviderDirect(fGrid.Row);
    aName := GridRowAccessibleText(fGrid, fGrid.Row);
  end else begin
    lItem := EnsureCellProviderDirect(fGrid.Col, fGrid.Row);
    if (fGrid.Col >= 0) and (fGrid.Col < fGrid.ColCount) and (fGrid.Row >= 0) and
      (fGrid.Row < fGrid.RowCount) then
    begin
      aName := fGrid.Cells[fGrid.Col, fGrid.Row];
    end;
  end;

  if lItem = nil then
  begin
    aName := '';
    Exit;
  end;

  aProvider := lItem.RawElementProvider;
  Result := aProvider <> nil;
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
  if ChildrenPreparationIsCurrent then
  begin
    Exit;
  end;

  RefreshVisibleCells;
  RefreshVisibleRows;
  RememberChildrenPreparation;
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
  lFormRoot: TAccessibilityVclFormProviderRoot;
  lNextRuntimeId: Integer;
  lRegistry: IAccessibilityAdapterRegistry;
  lRootProvider: IAccessibilityVclRootProvider;
  lProviderLookup: IAccessibilityVclProviderLookup;
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

  EnsureRadioGroupButtonControls(aForm);
  lTree := TAccessibilityScanner.ScanForm(aForm, lRegistry);
  lFormRoot := TAccessibilityVclFormProviderRoot.Create(aForm, lRegistry, aApi);
  Result := lFormRoot as IAccessibilityProviderNode;
  Result.SetProperty(UIA_ControlTypePropertyId, UIA_WindowControlTypeId);
  Result.SetProperty(UIA_ClassNamePropertyId, aForm.ClassName);

  lNextRuntimeId := 1;
  Supports(Result, IAccessibilityVclRootProvider, lRootProvider);
  AddProviderChildren(Result, lTree.Root, lRegistry, lNextRuntimeId, aApi, lRootProvider);
  lFormRoot.fNextRuntimeId := lNextRuntimeId;
  if Supports(Result, IAccessibilityVclProviderLookup, lProviderLookup) then
  begin
    AddLabeledByRelationships(lTree, lProviderLookup);
  end;
end;

initialization

gVclAdapterRttiPropertyCache := TVclAdapterRttiPropertyCache.Create;

finalization

FreeAndNil(gVclAdapterRttiPropertyCache);

end.
