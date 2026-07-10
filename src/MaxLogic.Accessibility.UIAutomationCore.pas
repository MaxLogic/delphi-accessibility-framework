unit MaxLogic.Accessibility.UIAutomationCore;

interface

uses
  System.Variants, Winapi.ActiveX, Winapi.Windows;

const
  UIAutomationCoreDll = 'UIAutomationCore.dll';
  UiaRootObjectId = -25;

type
  PROPERTYID = Integer;
  PATTERNID = Integer;
  EVENTID = Integer;
  CONTROLTYPEID = Integer;
  TEXTATTRIBUTEID = Integer;

  ProviderOptions = TOleEnum;

const
  UiaAppendRuntimeId = 3;

  ProviderOptions_ClientSideProvider = $00000001;
  ProviderOptions_ServerSideProvider = $00000002;
  ProviderOptions_NonClientAreaProvider = $00000004;
  ProviderOptions_OverrideProvider = $00000008;
  ProviderOptions_ProviderOwnsSetFocus = $00000010;
  ProviderOptions_UseComThreading = $00000020;
  ProviderOptions_RefuseNonClientSupport = $00000040;
  ProviderOptions_HasNativeIAccessible = $00000080;
  ProviderOptions_UseClientCoordinates = $00000100;

type
  NavigateDirection = TOleEnum;

const
  NavigateDirection_Parent = 0;
  NavigateDirection_NextSibling = 1;
  NavigateDirection_PreviousSibling = 2;
  NavigateDirection_FirstChild = 3;
  NavigateDirection_LastChild = 4;

type
  TreeScope = TOleEnum;

const
  TreeScope_None = $00000000;
  TreeScope_Element = $00000001;
  TreeScope_Children = $00000002;
  TreeScope_Descendants = $00000004;
  TreeScope_Parent = $00000008;
  TreeScope_Ancestors = $00000010;
  TreeScope_Subtree = TreeScope_Element or TreeScope_Children or TreeScope_Descendants;

type
  RowOrColumnMajor = TOleEnum;

const
  RowOrColumnMajor_RowMajor = 0;
  RowOrColumnMajor_ColumnMajor = 1;
  RowOrColumnMajor_Indeterminate = 2;

type
  ToggleState = TOleEnum;

const
  ToggleState_Off = 0;
  ToggleState_On = 1;
  ToggleState_Indeterminate = 2;

type
  StructureChangeType = TOleEnum;

const
  StructureChangeType_ChildAdded = 0;
  StructureChangeType_ChildRemoved = 1;
  StructureChangeType_ChildrenInvalidated = 2;
  StructureChangeType_ChildrenBulkAdded = 3;
  StructureChangeType_ChildrenBulkRemoved = 4;
  StructureChangeType_ChildrenReordered = 5;

type
  ScrollAmount = TOleEnum;

const
  ScrollAmount_LargeDecrement = 0;
  ScrollAmount_SmallDecrement = 1;
  ScrollAmount_NoAmount = 2;
  ScrollAmount_LargeIncrement = 3;
  ScrollAmount_SmallIncrement = 4;

type
  TextPatternRangeEndpoint = TOleEnum;

const
  TextPatternRangeEndpoint_Start = 0;
  TextPatternRangeEndpoint_End = 1;

type
  TextUnit = TOleEnum;

const
  TextUnit_Character = 0;
  TextUnit_Format = 1;
  TextUnit_Word = 2;
  TextUnit_Line = 3;
  TextUnit_Paragraph = 4;
  TextUnit_Page = 5;
  TextUnit_Document = 6;

type
  SupportedTextSelection = TOleEnum;

const
  SupportedTextSelection_None = 0;
  SupportedTextSelection_Single = 1;
  SupportedTextSelection_Multiple = 2;

type
  NotificationProcessing = TOleEnum;

const
  NotificationProcessing_ImportantAll = 0;
  NotificationProcessing_ImportantMostRecent = 1;
  NotificationProcessing_All = 2;
  NotificationProcessing_MostRecent = 3;
  NotificationProcessing_CurrentThenMostRecent = 4;
  NotificationProcessing_ImportantCurrentThenMostRecent = 5;

type
  NotificationKind = TOleEnum;

const
  NotificationKind_ItemAdded = 0;
  NotificationKind_ItemRemoved = 1;
  NotificationKind_ActionCompleted = 2;
  NotificationKind_ActionAborted = 3;
  NotificationKind_Other = 4;

const
  UIA_InvokePatternId = 10000;
  UIA_SelectionPatternId = 10001;
  UIA_ValuePatternId = 10002;
  UIA_ScrollPatternId = 10004;
  UIA_GridPatternId = 10006;
  UIA_GridItemPatternId = 10007;
  UIA_SelectionItemPatternId = 10010;
  UIA_TablePatternId = 10012;
  UIA_TableItemPatternId = 10013;
  UIA_TextPatternId = 10014;
  UIA_TogglePatternId = 10015;

  UIA_ToolTipOpenedEventId = 20000;
  UIA_ToolTipClosedEventId = 20001;
  UIA_StructureChangedEventId = 20002;
  UIA_AutomationPropertyChangedEventId = 20004;
  UIA_AutomationFocusChangedEventId = 20005;
  UIA_Invoke_InvokedEventId = 20009;
  UIA_SelectionItem_ElementSelectedEventId = 20012;
  UIA_Text_TextSelectionChangedEventId = 20014;
  UIA_Text_TextChangedEventId = 20015;
  UIA_NotificationEventId = 20035;

  UIA_RuntimeIdPropertyId = 30000;
  UIA_BoundingRectanglePropertyId = 30001;
  UIA_ControlTypePropertyId = 30003;
  UIA_LocalizedControlTypePropertyId = 30004;
  UIA_NamePropertyId = 30005;
  UIA_HasKeyboardFocusPropertyId = 30008;
  UIA_IsKeyboardFocusablePropertyId = 30009;
  UIA_IsEnabledPropertyId = 30010;
  UIA_AutomationIdPropertyId = 30011;
  UIA_ClassNamePropertyId = 30012;
  UIA_HelpTextPropertyId = 30013;
  UIA_ClickablePointPropertyId = 30014;
  UIA_IsControlElementPropertyId = 30016;
  UIA_IsContentElementPropertyId = 30017;
  UIA_LabeledByPropertyId = 30018;
  UIA_NativeWindowHandlePropertyId = 30020;
  UIA_ItemTypePropertyId = 30021;
  UIA_IsOffscreenPropertyId = 30022;
  UIA_FrameworkIdPropertyId = 30024;
  UIA_ItemStatusPropertyId = 30026;
  UIA_SelectionItemIsSelectedPropertyId = 30079;
  UIA_SelectionItemSelectionContainerPropertyId = 30080;
  UIA_ToggleToggleStatePropertyId = 30086;
  UIA_ProviderDescriptionPropertyId = 30107;

  UIA_ButtonControlTypeId = 50000;
  UIA_CheckBoxControlTypeId = 50002;
  UIA_ComboBoxControlTypeId = 50003;
  UIA_EditControlTypeId = 50004;
  UIA_ListItemControlTypeId = 50007;
  UIA_ListControlTypeId = 50008;
  UIA_RadioButtonControlTypeId = 50013;
  UIA_StatusBarControlTypeId = 50017;
  UIA_TabControlTypeId = 50018;
  UIA_TabItemControlTypeId = 50019;
  UIA_TextControlTypeId = 50020;
  UIA_ToolBarControlTypeId = 50021;
  UIA_ToolTipControlTypeId = 50022;
  UIA_CustomControlTypeId = 50025;
  UIA_GroupControlTypeId = 50026;
  UIA_DataGridControlTypeId = 50028;
  UIA_DataItemControlTypeId = 50029;
  UIA_DocumentControlTypeId = 50030;
  UIA_WindowControlTypeId = 50032;
  UIA_PaneControlTypeId = 50033;
  UIA_HeaderControlTypeId = 50034;
  UIA_HeaderItemControlTypeId = 50035;
  UIA_TableControlTypeId = 50036;

type
  UiaRect = record
    Left: Double;
    Top: Double;
    Width: Double;
    Height: Double;
  end;

  UiaPoint = record
    X: Double;
    Y: Double;
  end;

  IRawElementProviderFragmentRoot = interface;
  ITextRangeProvider = interface;

  IRawElementProviderSimple = interface(IUnknown)
    ['{D6DD68D1-86FD-4332-8666-9ABEDEA2D24C}']
    function Get_ProviderOptions(out aRetVal: ProviderOptions): HResult; stdcall;
    function GetPatternProvider(aPatternId: PATTERNID; out aRetVal: IUnknown): HResult; stdcall;
    function GetPropertyValue(aPropertyId: PROPERTYID; out aRetVal: OleVariant): HResult; stdcall;
    function Get_HostRawElementProvider(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
  end;

  IRawElementProviderFragment = interface(IUnknown)
    ['{F7063DA8-8359-439C-9297-BBC5299A7D87}']
    function Navigate(aDirection: NavigateDirection; out aRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetRuntimeId(out aRetVal: PSafeArray): HResult; stdcall;
    function Get_BoundingRectangle(out aRetVal: UiaRect): HResult; stdcall;
    function GetEmbeddedFragmentRoots(out aRetVal: PSafeArray): HResult; stdcall;
    function SetFocus: HResult; stdcall;
    function Get_FragmentRoot(out aRetVal: IRawElementProviderFragmentRoot): HResult; stdcall;
  end;

  IRawElementProviderFragmentRoot = interface(IUnknown)
    ['{620CE2A5-AB8F-40A9-86CB-DE3C75599B58}']
    function ElementProviderFromPoint(aX: Double; aY: Double; out aRetVal: IRawElementProviderFragment): HResult; stdcall;
    function GetFocus(out aRetVal: IRawElementProviderFragment): HResult; stdcall;
  end;

  IRawElementProviderAdviseEvents = interface(IUnknown)
    ['{A407B27B-0F6D-4427-9292-473C7BF93258}']
    function AdviseEventAdded(aEventId: EVENTID; aPropertyIds: PSafeArray): HResult; stdcall;
    function AdviseEventRemoved(aEventId: EVENTID; aPropertyIds: PSafeArray): HResult; stdcall;
  end;

  IInvokeProvider = interface(IUnknown)
    ['{54FCB24B-E18E-47A2-B4D3-ECCBE77599A2}']
    function Invoke: HResult; stdcall;
  end;

  IValueProvider = interface(IUnknown)
    ['{C7935180-6FB3-4201-B174-7DF73ADBF64A}']
    function SetValue(aValue: PWideChar): HResult; stdcall;
    function Get_Value(out aRetVal: WideString): HResult; stdcall;
    function Get_IsReadOnly(out aRetVal: BOOL): HResult; stdcall;
  end;

  IToggleProvider = interface(IUnknown)
    ['{56D00BD0-C4F4-433C-A836-1A52A57E0892}']
    function Toggle: HResult; stdcall;
    function Get_ToggleState(out aRetVal: ToggleState): HResult; stdcall;
  end;

  IGridProvider = interface(IUnknown)
    ['{B17D6187-0907-464B-A168-0EF17A1572B1}']
    function GetItem(aRow: Integer; aColumn: Integer; out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_RowCount(out aRetVal: Integer): HResult; stdcall;
    function Get_ColumnCount(out aRetVal: Integer): HResult; stdcall;
  end;

  IGridItemProvider = interface(IUnknown)
    ['{D02541F1-FB81-4D64-AE32-F520F8A6DBD1}']
    function Get_Row(out aRetVal: Integer): HResult; stdcall;
    function Get_Column(out aRetVal: Integer): HResult; stdcall;
    function Get_RowSpan(out aRetVal: Integer): HResult; stdcall;
    function Get_ColumnSpan(out aRetVal: Integer): HResult; stdcall;
    function Get_ContainingGrid(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
  end;

  ITableProvider = interface(IUnknown)
    ['{9C860395-97B3-490A-B52A-858CC22AF166}']
    function GetRowHeaders(out aRetVal: PSafeArray): HResult; stdcall;
    function GetColumnHeaders(out aRetVal: PSafeArray): HResult; stdcall;
    function Get_RowOrColumnMajor(out aRetVal: RowOrColumnMajor): HResult; stdcall;
  end;

  ITableItemProvider = interface(IUnknown)
    ['{B9734FA6-771F-4D78-9C90-2517999349CD}']
    function GetRowHeaderItems(out aRetVal: PSafeArray): HResult; stdcall;
    function GetColumnHeaderItems(out aRetVal: PSafeArray): HResult; stdcall;
  end;

  ISelectionProvider = interface(IUnknown)
    ['{FB8B03AF-3BDF-48D4-BD36-1A65793BE168}']
    function GetSelection(out aRetVal: PSafeArray): HResult; stdcall;
    function Get_CanSelectMultiple(out aRetVal: BOOL): HResult; stdcall;
    function Get_IsSelectionRequired(out aRetVal: BOOL): HResult; stdcall;
  end;

  ISelectionItemProvider = interface(IUnknown)
    ['{2ACAD808-B2D4-452D-A407-91FF1AD167B2}']
    function Select: HResult; stdcall;
    function AddToSelection: HResult; stdcall;
    function RemoveFromSelection: HResult; stdcall;
    function Get_IsSelected(out aRetVal: BOOL): HResult; stdcall;
    function Get_SelectionContainer(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
  end;

  IScrollProvider = interface(IUnknown)
    ['{B38B8077-1FC3-42A5-8CAE-D40C2215055A}']
    function Scroll(aHorizontalAmount: ScrollAmount; aVerticalAmount: ScrollAmount): HResult; stdcall;
    function SetScrollPercent(aHorizontalPercent: Double; aVerticalPercent: Double): HResult; stdcall;
    function Get_HorizontalScrollPercent(out aRetVal: Double): HResult; stdcall;
    function Get_VerticalScrollPercent(out aRetVal: Double): HResult; stdcall;
    function Get_HorizontalViewSize(out aRetVal: Double): HResult; stdcall;
    function Get_VerticalViewSize(out aRetVal: Double): HResult; stdcall;
    function Get_HorizontallyScrollable(out aRetVal: BOOL): HResult; stdcall;
    function Get_VerticallyScrollable(out aRetVal: BOOL): HResult; stdcall;
  end;

  ITextProvider = interface(IUnknown)
    ['{3589C92C-63F3-4367-99BB-ADA653B77CF2}']
    function GetSelection(out aRetVal: PSafeArray): HResult; stdcall;
    function GetVisibleRanges(out aRetVal: PSafeArray): HResult; stdcall;
    function RangeFromChild(aChildElement: IRawElementProviderSimple; out aRetVal: ITextRangeProvider): HResult; stdcall;
    function RangeFromPoint(aPoint: UiaPoint; out aRetVal: ITextRangeProvider): HResult; stdcall;
    function Get_DocumentRange(out aRetVal: ITextRangeProvider): HResult; stdcall;
    function Get_SupportedTextSelection(out aRetVal: SupportedTextSelection): HResult; stdcall;
  end;

  ITextRangeProvider = interface(IUnknown)
    ['{5347AD7B-C355-46F8-AFF5-909033582F63}']
    function Clone(out aRetVal: ITextRangeProvider): HResult; stdcall;
    function Compare(aRange: ITextRangeProvider; out aRetVal: BOOL): HResult; stdcall;
    function CompareEndpoints(aEndpoint: TextPatternRangeEndpoint; aTargetRange: ITextRangeProvider;
      aTargetEndpoint: TextPatternRangeEndpoint; out aRetVal: Integer): HResult; stdcall;
    function ExpandToEnclosingUnit(aUnit: TextUnit): HResult; stdcall;
    function FindAttribute(aAttributeId: TEXTATTRIBUTEID; aValue: OleVariant; aBackward: BOOL;
      out aRetVal: ITextRangeProvider): HResult; stdcall;
    function FindText(aText: WideString; aBackward: BOOL; aIgnoreCase: BOOL;
      out aRetVal: ITextRangeProvider): HResult; stdcall;
    function GetAttributeValue(aAttributeId: TEXTATTRIBUTEID; out aRetVal: OleVariant): HResult; stdcall;
    function GetBoundingRectangles(out aRetVal: PSafeArray): HResult; stdcall;
    function GetEnclosingElement(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function GetText(aMaxLength: Integer; out aRetVal: WideString): HResult; stdcall;
    function Move(aUnit: TextUnit; aCount: Integer; out aRetVal: Integer): HResult; stdcall;
    function MoveEndpointByUnit(aEndpoint: TextPatternRangeEndpoint; aUnit: TextUnit; aCount: Integer;
      out aRetVal: Integer): HResult; stdcall;
    function MoveEndpointByRange(aEndpoint: TextPatternRangeEndpoint; aTargetRange: ITextRangeProvider;
      aTargetEndpoint: TextPatternRangeEndpoint): HResult; stdcall;
    function Select: HResult; stdcall;
    function AddToSelection: HResult; stdcall;
    function RemoveFromSelection: HResult; stdcall;
    function ScrollIntoView(aAlignToTop: BOOL): HResult; stdcall;
    function GetChildren(out aRetVal: PSafeArray): HResult; stdcall;
  end;

  TUIAutomationCoreExport = (
    uiceClientsAreListening,
    uiceGetReservedNotSupportedValue,
    uiceHostProviderFromHwnd,
    uiceReturnRawElementProvider,
    uiceDisconnectProvider,
    uiceRaiseAutomationEvent,
    uiceRaiseAutomationPropertyChangedEvent,
    uiceRaiseStructureChangedEvent,
    uiceRaiseNotificationEvent
  );

  TUIAutomationCoreImports = record
  public
    class function ExportName(aExport: TUIAutomationCoreExport): string; static;
    class function HasExport(aExport: TUIAutomationCoreExport): Boolean; static;
    class function LibraryLoadFlags: DWORD; static;
    class function LibraryName: string; static;
    class function RequiredExportsAvailable: Boolean; static;
  end;

function UiaClientsAreListening: BOOL; stdcall;
function UiaGetReservedNotSupportedValue(out aNotSupportedValue: IUnknown): HRESULT; stdcall;
function UiaHostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT; stdcall;
function UiaReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  aElement: IRawElementProviderSimple): LRESULT; stdcall;
function UiaDisconnectProvider(aProvider: IRawElementProviderSimple): HRESULT; stdcall;
function UiaRaiseAutomationEvent(aProvider: IRawElementProviderSimple; aId: EVENTID): HRESULT; stdcall;
function UiaRaiseAutomationPropertyChangedEvent(aProvider: IRawElementProviderSimple; aId: PROPERTYID;
  aOldValue: OleVariant; aNewValue: OleVariant): HRESULT; stdcall;
function UiaRaiseStructureChangedEvent(aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
  aRuntimeId: PInteger; aRuntimeIdLength: Integer): HRESULT; stdcall;
function UiaRaiseNotificationEvent(aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
  aNotificationProcessing: NotificationProcessing; aDisplayString: WideString; aActivityId: WideString): HRESULT; stdcall;

implementation

uses
  System.SysUtils;

const
  cLoadLibrarySearchSystem32 = $00000800;

type
  TUiaClientsAreListeningProc = function: BOOL; stdcall;
  TUiaGetReservedNotSupportedValueProc = function(out aNotSupportedValue: IUnknown): HRESULT; stdcall;
  TUiaHostProviderFromHwndProc = function(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT; stdcall;
  TUiaReturnRawElementProviderProc = function(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
    aElement: IRawElementProviderSimple): LRESULT; stdcall;
  TUiaDisconnectProviderProc = function(aProvider: IRawElementProviderSimple): HRESULT; stdcall;
  TUiaRaiseAutomationEventProc = function(aProvider: IRawElementProviderSimple; aId: EVENTID): HRESULT; stdcall;
  TUiaRaiseAutomationPropertyChangedEventProc = function(aProvider: IRawElementProviderSimple; aId: PROPERTYID;
    aOldValue: OleVariant; aNewValue: OleVariant): HRESULT; stdcall;
  TUiaRaiseStructureChangedEventProc = function(aProvider: IRawElementProviderSimple;
    aStructureChangeType: StructureChangeType; aRuntimeId: PInteger; aRuntimeIdLength: Integer): HRESULT; stdcall;
  TUiaRaiseNotificationEventProc = function(aProvider: IRawElementProviderSimple;
    aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; aDisplayString: WideString;
    aActivityId: WideString): HRESULT; stdcall;

var
  gUIAutomationCoreModule: HMODULE;
  gImportLock: TObject;

function LoadUIAutomationCoreLibrary: HMODULE;
begin
  Result := LoadLibraryEx(PChar(UIAutomationCoreDll), 0, TUIAutomationCoreImports.LibraryLoadFlags);
end;

function UIAutomationCoreModule: HMODULE;
var
  lModule: HMODULE;
begin
  Result := gUIAutomationCoreModule;
  if Result <> 0 then
  begin
    Exit;
  end;

  TMonitor.Enter(gImportLock);
  try
    if gUIAutomationCoreModule = 0 then
    begin
      lModule := LoadUIAutomationCoreLibrary;
      if lModule = 0 then
      begin
        RaiseLastOSError;
      end;

      gUIAutomationCoreModule := lModule;
    end;

    Result := gUIAutomationCoreModule;
  finally
    TMonitor.Exit(gImportLock);
  end;
end;

function GetUIAutomationCoreProc(aExport: TUIAutomationCoreExport): Pointer;
var
  lName: AnsiString;
begin
  lName := AnsiString(TUIAutomationCoreImports.ExportName(aExport));
  Result := GetProcAddress(UIAutomationCoreModule, PAnsiChar(lName));
  if Result = nil then
  begin
    raise EExternalException.CreateFmt('UI Automation Core export not found: %s', [string(lName)]);
  end;
end;

class function TUIAutomationCoreImports.ExportName(aExport: TUIAutomationCoreExport): string;
begin
  case aExport of
    uiceClientsAreListening:
      Result := 'UiaClientsAreListening';
    uiceGetReservedNotSupportedValue:
      Result := 'UiaGetReservedNotSupportedValue';
    uiceHostProviderFromHwnd:
      Result := 'UiaHostProviderFromHwnd';
    uiceReturnRawElementProvider:
      Result := 'UiaReturnRawElementProvider';
    uiceDisconnectProvider:
      Result := 'UiaDisconnectProvider';
    uiceRaiseAutomationEvent:
      Result := 'UiaRaiseAutomationEvent';
    uiceRaiseAutomationPropertyChangedEvent:
      Result := 'UiaRaiseAutomationPropertyChangedEvent';
    uiceRaiseStructureChangedEvent:
      Result := 'UiaRaiseStructureChangedEvent';
    uiceRaiseNotificationEvent:
      Result := 'UiaRaiseNotificationEvent';
  else
    raise EArgumentOutOfRangeException.Create('Unknown UI Automation Core export.');
  end;
end;

class function TUIAutomationCoreImports.HasExport(aExport: TUIAutomationCoreExport): Boolean;
var
  lModule: HMODULE;
  lName: AnsiString;
begin
  Result := False;
  lModule := LoadUIAutomationCoreLibrary;
  if lModule = 0 then
  begin
    Exit;
  end;

  try
    lName := AnsiString(ExportName(aExport));
    Result := GetProcAddress(lModule, PAnsiChar(lName)) <> nil;
  finally
    FreeLibrary(lModule);
  end;
end;

class function TUIAutomationCoreImports.LibraryLoadFlags: DWORD;
begin
  Result := cLoadLibrarySearchSystem32;
end;

class function TUIAutomationCoreImports.LibraryName: string;
begin
  Result := UIAutomationCoreDll;
end;

class function TUIAutomationCoreImports.RequiredExportsAvailable: Boolean;
var
  lExport: TUIAutomationCoreExport;
begin
  Result := True;
  for lExport := Low(TUIAutomationCoreExport) to High(TUIAutomationCoreExport) do
  begin
    if not HasExport(lExport) then
    begin
      Exit(False);
    end;
  end;
end;

function UiaClientsAreListening: BOOL;
var
  lProc: TUiaClientsAreListeningProc;
begin
  lProc := TUiaClientsAreListeningProc(GetUIAutomationCoreProc(uiceClientsAreListening));
  Result := lProc();
end;

function UiaGetReservedNotSupportedValue(out aNotSupportedValue: IUnknown): HRESULT;
var
  lProc: TUiaGetReservedNotSupportedValueProc;
begin
  lProc := TUiaGetReservedNotSupportedValueProc(GetUIAutomationCoreProc(uiceGetReservedNotSupportedValue));
  Result := lProc(aNotSupportedValue);
end;

function UiaHostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
var
  lProc: TUiaHostProviderFromHwndProc;
begin
  lProc := TUiaHostProviderFromHwndProc(GetUIAutomationCoreProc(uiceHostProviderFromHwnd));
  Result := lProc(aHwnd, aProvider);
end;

function UiaReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  aElement: IRawElementProviderSimple): LRESULT;
var
  lProc: TUiaReturnRawElementProviderProc;
begin
  lProc := TUiaReturnRawElementProviderProc(GetUIAutomationCoreProc(uiceReturnRawElementProvider));
  Result := lProc(aHwnd, aWParam, aLParam, aElement);
end;

function UiaDisconnectProvider(aProvider: IRawElementProviderSimple): HRESULT;
var
  lProc: TUiaDisconnectProviderProc;
begin
  lProc := TUiaDisconnectProviderProc(GetUIAutomationCoreProc(uiceDisconnectProvider));
  Result := lProc(aProvider);
end;

function UiaRaiseAutomationEvent(aProvider: IRawElementProviderSimple; aId: EVENTID): HRESULT;
var
  lProc: TUiaRaiseAutomationEventProc;
begin
  lProc := TUiaRaiseAutomationEventProc(GetUIAutomationCoreProc(uiceRaiseAutomationEvent));
  Result := lProc(aProvider, aId);
end;

function UiaRaiseAutomationPropertyChangedEvent(aProvider: IRawElementProviderSimple; aId: PROPERTYID;
  aOldValue: OleVariant; aNewValue: OleVariant): HRESULT;
var
  lProc: TUiaRaiseAutomationPropertyChangedEventProc;
begin
  lProc := TUiaRaiseAutomationPropertyChangedEventProc(GetUIAutomationCoreProc(uiceRaiseAutomationPropertyChangedEvent));
  Result := lProc(aProvider, aId, aOldValue, aNewValue);
end;

function UiaRaiseStructureChangedEvent(aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
  aRuntimeId: PInteger; aRuntimeIdLength: Integer): HRESULT;
var
  lProc: TUiaRaiseStructureChangedEventProc;
begin
  lProc := TUiaRaiseStructureChangedEventProc(GetUIAutomationCoreProc(uiceRaiseStructureChangedEvent));
  Result := lProc(aProvider, aStructureChangeType, aRuntimeId, aRuntimeIdLength);
end;

function UiaRaiseNotificationEvent(aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
  aNotificationProcessing: NotificationProcessing; aDisplayString: WideString; aActivityId: WideString): HRESULT;
var
  lProc: TUiaRaiseNotificationEventProc;
begin
  lProc := TUiaRaiseNotificationEventProc(GetUIAutomationCoreProc(uiceRaiseNotificationEvent));
  Result := lProc(aProvider, aNotificationKind, aNotificationProcessing, aDisplayString, aActivityId);
end;

initialization
  gImportLock := TObject.Create;

finalization
  if gUIAutomationCoreModule <> 0 then
  begin
    FreeLibrary(gUIAutomationCoreModule);
  end;

  gImportLock.Free;

end.
