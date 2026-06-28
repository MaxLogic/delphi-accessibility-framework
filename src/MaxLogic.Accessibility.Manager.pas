unit MaxLogic.Accessibility.Manager;

interface

uses
  Winapi.Windows,
  Vcl.Forms,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner;

type
  IAccessibilityFormInstaller = interface
    ['{F0C5F5C3-2916-4C87-8709-54148F1C31D6}']
    procedure InstallForm(aForm: TCustomForm);
  end;

  IAccessibilityWinEventSink = interface
    ['{2D8FF811-0624-4FD3-8E2A-5CB8D3829C41}']
    procedure NotifyEvent(aEvent: DWORD; aHwnd: HWND; aObjectId: Cardinal; aChildId: Cardinal);
  end;

  TAccessibilityManager = record
  public
    class procedure Install(aApplication: TApplication); overload; static;
    class procedure Install(aApplication: TApplication; const aRegistry: IAccessibilityAdapterRegistry); overload; static;
    class procedure Install(aForm: TCustomForm); overload; static;
    class procedure Install(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry); overload; static;
    class procedure Run(aApplication: TApplication); static;
    class procedure Uninstall; static;
  end;

  TAccessibilityManagerInternals = record
  public
    class function InstalledFormCount: Integer; static;
    class procedure SetFormInstaller(const aInstaller: IAccessibilityFormInstaller); static;
    class procedure SetUiaApi(const aApi: IAccessibilityUiaApi); static;
    class procedure SetWinEventSink(const aSink: IAccessibilityWinEventSink); static;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.SysUtils, System.Types, Winapi.Messages, Vcl.ComCtrls,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.Hints,
  MaxLogic.Accessibility.Msaa, MaxLogic.Accessibility.UIAutomationCore,
  MaxLogic.Accessibility.VclAdapters;

const
  cMsaaObjIdClient = Cardinal($FFFFFFFC);

type
  TAccessibilityControlWindowHook = class;
  TAccessibilityFormWindowHook = class;

  TProviderStateKind = (pskNone, pskToggle, pskSelectionItem);

  TProviderStateSnapshot = record
    Kind: TProviderStateKind;
    IsSelected: Boolean;
    ToggleState: ToggleState;
  end;

  TAccessibilityInstalledFormMarker = class(TComponent)
  private
    fHook: TAccessibilityFormWindowHook;
    fRegistry: IAccessibilityAdapterRegistry;
  public
    destructor Destroy; override;
    class function FindOn(aForm: TCustomForm): TAccessibilityInstalledFormMarker; static;
    procedure InstallProvider(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry;
      const aApi: IAccessibilityUiaApi);
    procedure RememberRegistry(const aRegistry: IAccessibilityAdapterRegistry);
    function RegistryMatches(const aRegistry: IAccessibilityAdapterRegistry): Boolean;
  end;

  TAccessibilityFormWindowHook = class(TComponent)
  private
    fApi: IAccessibilityUiaApi;
    fChildHooks: TList<TAccessibilityControlWindowHook>;
    fForm: TCustomForm;
    fLastHoverAnnouncement: string;
    fOriginalWindowProc: TWndMethod;
    fPassive: Boolean;
    fProvider: IAccessibilityProviderNode;
    function ControlIsHooked(aControl: TWinControl): Boolean;
    procedure Detach;
    procedure DisconnectProvider;
    procedure HookChildProviderWindows;
    procedure HookControlWindow(aControl: TWinControl; const aProvider: IRawElementProviderSimple;
      aPreserveNativeWindowAccessibility: Boolean);
    procedure HookMissingWindowControls(aParent: TWinControl);
    procedure HookProviderWindow(const aProvider: IRawElementProviderSimple);
    procedure HookRadioGroupButtonWindows(aRadioGroup: TRadioGroup; const aProvider: IRawElementProviderSimple);
    procedure MaybeRaiseProviderHover(aLParam: LPARAM);
    function Passivate: Boolean;
    procedure ReleaseChildHooks;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    class procedure ReleaseRetainedHooks; static;
    constructor Create(aForm: TCustomForm; const aProvider: IAccessibilityProviderNode;
      const aApi: IAccessibilityUiaApi); reintroduce;
    destructor Destroy; override;
    procedure WindowProc(var aMessage: TMessage);
  end;

  TAccessibilityControlWindowHook = class(TComponent)
  private
    fApi: IAccessibilityUiaApi;
    fControl: TWinControl;
    fHasLastGridCell: Boolean;
    fHasLastListBoxIndex: Boolean;
    fHasLastRaisedProviderState: Boolean;
    fLastGridCol: Integer;
    fLastGridRow: Integer;
    fLastHoverAnnouncement: string;
    fLastListBoxIndex: Integer;
    fLastRaisedProviderState: TProviderStateSnapshot;
    fOriginalWindowProc: TWndMethod;
    fPassive: Boolean;
    fPreserveNativeWindowAccessibility: Boolean;
    fProvider: IRawElementProviderSimple;
    fProviderStateMessageDepth: Integer;
    procedure Detach;
    function GridCellChanged: Boolean;
    procedure InitializeGridCellTracking;
    procedure InitializeListBoxItemTracking;
    function ListBoxItemChanged: Boolean;
    procedure MaybeRaiseGridFocusChanged;
    procedure MaybeRaiseListBoxFocusChanged;
    procedure MaybeRaiseProviderHover(aLParam: LPARAM);
    function Passivate: Boolean;
    procedure RaiseFocusChanged;
    procedure NotifyFocusHint;
    procedure RaiseGridFocusChanged;
    procedure RaiseListBoxFocusChanged;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    class procedure ReleaseRetainedHooks; static;
    constructor Create(aControl: TWinControl; const aProvider: IRawElementProviderSimple;
      const aApi: IAccessibilityUiaApi; aPreserveNativeWindowAccessibility: Boolean); reintroduce;
    destructor Destroy; override;
    procedure WindowProc(var aMessage: TMessage);
  end;

  TAccessibilityManagerState = class
  private
    fAppInstalled: Boolean;
    fApplicationRegistry: IAccessibilityAdapterRegistry;
    fHintController: TAccessibilityHintController;
    fHintControllerAppWide: Boolean;
    fFormInstaller: IAccessibilityFormInstaller;
    fPreviousActiveFormChange: TNotifyEvent;
    fScreenHookInstalled: Boolean;
    fUiaApi: IAccessibilityUiaApi;
    procedure ActiveFormChanged(aSender: TObject);
    procedure EnsureApplicationRegistry(const aRegistry: IAccessibilityAdapterRegistry);
    procedure EnsureFormRegistryAllowed(const aRegistry: IAccessibilityAdapterRegistry);
    procedure EnsureInstalledFormsRegistry(const aRegistry: IAccessibilityAdapterRegistry);
    procedure HookScreen;
    procedure InstallHintController(aApplication: TApplication; aAppWide: Boolean);
    procedure InstallFormWithRegistry(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry);
    procedure RemoveInstalledMarkers;
    procedure ReleaseHintController;
    procedure RestoreScreenHook;
    procedure ScanCurrentForms;
  public
    constructor Create;
    destructor Destroy; override;
    function InstalledFormCount: Integer;
    procedure InstallApplication(aApplication: TApplication); overload;
    procedure InstallApplication(aApplication: TApplication; const aRegistry: IAccessibilityAdapterRegistry); overload;
    procedure InstallForm(aForm: TCustomForm); overload;
    procedure InstallForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry); overload;
    procedure SetFormInstaller(const aInstaller: IAccessibilityFormInstaller);
    procedure SetUiaApi(const aApi: IAccessibilityUiaApi);
    procedure Uninstall;
  end;

var
  gManagerState: TAccessibilityManagerState;
  gRetainedControlHooks: TList<TAccessibilityControlWindowHook>;
  gRetainedFormHooks: TList<TAccessibilityFormWindowHook>;
  gWinEventSink: IAccessibilityWinEventSink;

procedure NotifyAccessibilityWinEvent(aEvent: DWORD; aHwnd: HWND; aObjectId: Cardinal; aChildId: Cardinal);
begin
  if gWinEventSink <> nil then
  begin
    gWinEventSink.NotifyEvent(aEvent, aHwnd, aObjectId, aChildId);
  end else begin
    NotifyWinEvent(aEvent, aHwnd, aObjectId, aChildId);
  end;
end;

function SameNotifyEvent(const aLeft: TNotifyEvent; const aRight: TNotifyEvent): Boolean;
begin
  Result := (TMethod(aLeft).Code = TMethod(aRight).Code) and (TMethod(aLeft).Data = TMethod(aRight).Data);
end;

function SameWndMethod(const aLeft: TWndMethod; const aRight: TWndMethod): Boolean;
begin
  Result := (TMethod(aLeft).Code = TMethod(aRight).Code) and (TMethod(aLeft).Data = TMethod(aRight).Data);
end;

function SameRegistry(const aLeft: IAccessibilityAdapterRegistry;
  const aRight: IAccessibilityAdapterRegistry): Boolean;
begin
  Result := aLeft = aRight;
end;

function ProviderHasChildren(const aProvider: IRawElementProviderSimple): Boolean;
var
  lChild: IRawElementProviderFragment;
  lFragment: IRawElementProviderFragment;
begin
  Result := False;
  if Supports(aProvider, IRawElementProviderFragment, lFragment) then
  begin
    Result := (lFragment.Navigate(NavigateDirection_FirstChild, lChild) = S_OK) and (lChild <> nil);
  end;
end;

function ProviderIsGrid(const aProvider: IRawElementProviderSimple): Boolean;
var
  lGrid: IGridProvider;
begin
  Result := Supports(aProvider, IGridProvider, lGrid);
end;

function ShouldHookMissingWindowControl(aControl: TWinControl): Boolean;
begin
  Result := (aControl is TPageControl) or ((not aControl.TabStop) and (aControl.ControlCount > 0));
end;

function ShouldPreserveNativeWindowAccessibility(aControl: TWinControl): Boolean;
begin
  Result := (aControl is TCustomCheckBox) or ((aControl is TRadioButton) and not (aControl.Parent is TRadioGroup));
end;

procedure EnsureRadioGroupButtonHandles(aControl: TControl);
var
  i: Integer;
  lRadioGroup: TRadioGroup;
begin
  if not (aControl is TRadioGroup) then
  begin
    Exit;
  end;

  lRadioGroup := TRadioGroup(aControl);
  for i := 0 to Pred(lRadioGroup.Items.Count) do
  begin
    lRadioGroup.Buttons[i].HandleNeeded;
  end;
end;

function MouseCoordinateWord(aValue: Integer): Word;
begin
  Result := Word(aValue and $FFFF);
end;

function SignedMouseCoordinate(aValue: Word): Integer;
begin
  Result := aValue;
  if (aValue and $8000) <> 0 then
  begin
    Dec(Result, $10000);
  end;
end;

function MouseLParamLowWord(aValue: LPARAM): Word;
begin
  Result := Word(NativeUInt(aValue) and $FFFF);
end;

function MouseLParamHighWord(aValue: LPARAM): Word;
begin
  Result := Word((NativeUInt(aValue) shr 16) and $FFFF);
end;

function PointToMouseLParam(const aPoint: TPoint): LPARAM;
var
  lValue: Int64;
begin
  lValue := Int64(MouseCoordinateWord(aPoint.X)) or (Int64(MouseCoordinateWord(aPoint.Y)) shl 16);
  if (lValue and $80000000) <> 0 then
  begin
    Dec(lValue, $100000000);
  end;

  Result := LPARAM(lValue);
end;

function MouseMoveClientLParam(aControl: TWinControl; const aMessage: TMessage): LPARAM;
var
  lPoint: TPoint;
begin
  Result := aMessage.LParam;
  if (aControl = nil) or (aMessage.Msg <> WM_NCMOUSEMOVE) then
  begin
    Exit;
  end;

  lPoint := Point(SignedMouseCoordinate(MouseLParamLowWord(aMessage.LParam)),
    SignedMouseCoordinate(MouseLParamHighWord(aMessage.LParam)));
  lPoint := aControl.ScreenToClient(lPoint);
  Result := PointToMouseLParam(lPoint);
end;

function ShouldInstallForm(aForm: TCustomForm): Boolean;
begin
  // VCL keeps this sentinel in Screen.Forms when no real form is active.
  Result := (aForm <> nil) and not SameText(aForm.ClassName, 'TNoActiveForm');
end;

function ProviderSupportsPattern(const aProvider: IRawElementProviderSimple; aPatternId: PATTERNID): Boolean;
var
  lPattern: IUnknown;
begin
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  lPattern := nil;
  Result := (aProvider.GetPatternProvider(aPatternId, lPattern) = S_OK) and (lPattern <> nil);
end;

function ProvidersAreSame(const aLeft: IRawElementProviderSimple;
  const aRight: IRawElementProviderSimple): Boolean;
var
  lLeft: IUnknown;
  lRight: IUnknown;
begin
  if (aLeft = nil) or (aRight = nil) then
  begin
    Exit(aLeft = aRight);
  end;

  lLeft := aLeft as IUnknown;
  lRight := aRight as IUnknown;
  Result := lLeft = lRight;
end;

function ProviderHelpText(const aProvider: IRawElementProviderSimple): string;
var
  lValue: OleVariant;
begin
  Result := '';
  if aProvider = nil then
  begin
    Exit;
  end;

  if aProvider.GetPropertyValue(UIA_HelpTextPropertyId, lValue) = S_OK then
  begin
    Result := string(lValue);
  end;
end;

function ProviderName(const aProvider: IRawElementProviderSimple): string;
var
  lValue: OleVariant;
begin
  Result := '';
  if aProvider = nil then
  begin
    Exit;
  end;

  if aProvider.GetPropertyValue(UIA_NamePropertyId, lValue) = S_OK then
  begin
    Result := string(lValue);
  end;
end;

function ProviderControlType(const aProvider: IRawElementProviderSimple): Integer;
var
  lValue: OleVariant;
begin
  Result := UIA_CustomControlTypeId;
  if aProvider = nil then
  begin
    Exit;
  end;

  if aProvider.GetPropertyValue(UIA_ControlTypePropertyId, lValue) = S_OK then
  begin
    Result := Integer(lValue);
  end;
end;

function ProviderNativeWindowHandle(const aProvider: IRawElementProviderSimple): HWND;
var
  lValue: OleVariant;
begin
  Result := 0;
  if aProvider = nil then
  begin
    Exit;
  end;

  if aProvider.GetPropertyValue(UIA_NativeWindowHandlePropertyId, lValue) = S_OK then
  begin
    Result := HWND(NativeInt(lValue));
  end;
end;

procedure NotifyProviderNativeFocusAndState(const aProvider: IRawElementProviderSimple; aFallbackHwnd: HWND);
var
  lHwnd: HWND;
begin
  lHwnd := ProviderNativeWindowHandle(aProvider);
  if lHwnd = 0 then
  begin
    lHwnd := aFallbackHwnd;
  end;

  if lHwnd <> 0 then
  begin
    NotifyAccessibilityWinEvent(EVENT_OBJECT_FOCUS, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
    NotifyAccessibilityWinEvent(EVENT_OBJECT_STATECHANGE, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
  end;
end;

function ProviderValueText(const aProvider: IRawElementProviderSimple): string;
var
  lPattern: IUnknown;
  lValue: WideString;
  lValueProvider: IValueProvider;
begin
  Result := '';
  if aProvider = nil then
  begin
    Exit;
  end;

  lPattern := nil;
  if (aProvider.GetPatternProvider(UIA_ValuePatternId, lPattern) <> S_OK) or
    not Supports(lPattern, IValueProvider, lValueProvider) then
  begin
    Exit;
  end;

  lValue := '';
  if lValueProvider.Get_Value(lValue) = S_OK then
  begin
    Result := string(lValue);
  end;
end;

function RemoveLeadingSpeechDuplicate(const aText: string; const aDuplicate: string): string;
begin
  Result := Trim(aText);
  if (Result = '') or (aDuplicate = '') or (CompareText(Copy(Result, 1, Length(aDuplicate)), aDuplicate) <> 0) then
  begin
    Exit;
  end;

  Delete(Result, 1, Length(aDuplicate));
  Result := Trim(Result);
  while (Result <> '') and CharInSet(Result[1], ['.', ',', ';', ':', '|', '-']) do
  begin
    Delete(Result, 1, 1);
    Result := Trim(Result);
  end;
end;

function ProviderFocusAnnouncementText(const aProvider: IRawElementProviderSimple): string;
var
  lHelpText: string;
  lName: string;
  lValueText: string;
begin
  lName := ProviderName(aProvider);
  lValueText := ProviderValueText(aProvider);
  lHelpText := RemoveLeadingSpeechDuplicate(ProviderHelpText(aProvider), lValueText);

  Result := '';
  if lName <> '' then
  begin
    Result := lName;
  end;

  if (lValueText <> '') and (CompareText(Result, lValueText) <> 0) then
  begin
    if Result <> '' then
    begin
      Result := Result + ' ';
    end;
    Result := Result + lValueText;
  end;

  if (lHelpText <> '') and (CompareText(Result, lHelpText) <> 0) then
  begin
    if Result <> '' then
    begin
      Result := Result + '. ';
    end;
    Result := Result + lHelpText;
  end;
end;

function ProviderHoverAnnouncementText(const aProvider: IRawElementProviderSimple): string;
begin
  Result := ProviderFocusAnnouncementText(aProvider);
end;

function ProviderUsesPlatformStateEvents(const aProvider: IRawElementProviderSimple): Boolean;
var
  lControlType: Integer;
begin
  lControlType := ProviderControlType(aProvider);
  Result := (lControlType = UIA_CheckBoxControlTypeId) or (lControlType = UIA_RadioButtonControlTypeId);
end;

function ProviderUsesHoverFocusEvent(const aProvider: IRawElementProviderSimple): Boolean;
begin
  Result := ProviderControlType(aProvider) = UIA_GroupControlTypeId;
end;

function ProviderWrapsRadioGroupButton(const aProvider: IRawElementProviderSimple): Boolean;
var
  lControl: TControl;
  lInfo: IAccessibilityVclControlProviderInfo;
begin
  Result := False;
  if not Supports(aProvider, IAccessibilityVclControlProviderInfo, lInfo) then
  begin
    Exit;
  end;

  lControl := lInfo.Control;
  Result := (lControl is TRadioButton) and (lControl.Parent is TRadioGroup);
end;

function TryCaptureProviderState(const aProvider: IRawElementProviderSimple; out aState: TProviderStateSnapshot):
  Boolean;
var
  lIsSelected: BOOL;
  lPattern: IUnknown;
  lSelectionItem: ISelectionItemProvider;
  lToggle: IToggleProvider;
  lToggleState: ToggleState;
begin
  aState := Default(TProviderStateSnapshot);
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  lPattern := nil;
  if (aProvider.GetPatternProvider(UIA_TogglePatternId, lPattern) = S_OK) and
    Supports(lPattern, IToggleProvider, lToggle) and (lToggle.Get_ToggleState(lToggleState) = S_OK) then
  begin
    aState.Kind := pskToggle;
    aState.ToggleState := lToggleState;
    Exit(True);
  end;

  lPattern := nil;
  if (aProvider.GetPatternProvider(UIA_SelectionItemPatternId, lPattern) = S_OK) and
    Supports(lPattern, ISelectionItemProvider, lSelectionItem) and (lSelectionItem.Get_IsSelected(lIsSelected) = S_OK)
  then
  begin
    aState.Kind := pskSelectionItem;
    aState.IsSelected := lIsSelected;
    Exit(True);
  end;
end;

function ProviderStateMessageMayChangeState(const aMessage: TMessage): Boolean;
begin
  case aMessage.Msg of
    BM_CLICK, WM_LBUTTONUP:
      Result := True;
    WM_KEYDOWN:
      case aMessage.WParam of
        VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN:
          Result := True;
      else
        Result := False;
      end;
    WM_KEYUP:
      case aMessage.WParam of
        VK_SPACE:
          Result := True;
      else
        Result := False;
      end;
  else
    Result := False;
  end;
end;

function ProviderStatesEqual(const aLeft: TProviderStateSnapshot; const aRight: TProviderStateSnapshot): Boolean;
begin
  Result := False;
  if aLeft.Kind <> aRight.Kind then
  begin
    Exit;
  end;

  case aLeft.Kind of
    pskToggle:
      Result := aLeft.ToggleState = aRight.ToggleState;
    pskSelectionItem:
      Result := aLeft.IsSelected = aRight.IsSelected;
  else
    Result := True;
  end;
end;

procedure RaiseProviderStateChanged(const aProvider: IRawElementProviderSimple;
  const aOldState: TProviderStateSnapshot; const aNewState: TProviderStateSnapshot; const aApi: IAccessibilityUiaApi);
var
  lChanged: Boolean;
  lHwnd: HWND;
begin
  if (aProvider = nil) or (aOldState.Kind <> aNewState.Kind) then
  begin
    Exit;
  end;

  lChanged := False;
  case aNewState.Kind of
    pskToggle:
      if aOldState.ToggleState <> aNewState.ToggleState then
      begin
        lChanged := True;
        TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider, UIA_ToggleToggleStatePropertyId,
          Integer(aOldState.ToggleState), Integer(aNewState.ToggleState), aApi);
      end;
    pskSelectionItem:
      if aOldState.IsSelected <> aNewState.IsSelected then
      begin
        lChanged := True;
        TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider, UIA_SelectionItemIsSelectedPropertyId,
          aOldState.IsSelected, aNewState.IsSelected, aApi);
        if aNewState.IsSelected then
        begin
          TAccessibilityProviderEvents.RaiseAutomationEvent(aProvider, UIA_SelectionItem_ElementSelectedEventId, aApi);
        end;
      end;
  end;

  if lChanged then
  begin
    lHwnd := ProviderNativeWindowHandle(aProvider);
    if lHwnd <> 0 then
    begin
      NotifyAccessibilityWinEvent(EVENT_OBJECT_STATECHANGE, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
    end;
  end;
end;

procedure RaiseProviderHover(const aProvider: IRawElementProviderSimple; const aAnnouncementText: string;
  const aApi: IAccessibilityUiaApi);
var
  lHwnd: HWND;
begin
  if ProviderUsesPlatformStateEvents(aProvider) then
  begin
    TAccessibilityProviderEvents.RaiseAutomationEvent(aProvider, UIA_AutomationFocusChangedEventId, aApi);
    lHwnd := ProviderNativeWindowHandle(aProvider);
    if lHwnd <> 0 then
    begin
      NotifyAccessibilityWinEvent(EVENT_OBJECT_FOCUS, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
      NotifyAccessibilityWinEvent(EVENT_OBJECT_STATECHANGE, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
      if not ProviderWrapsRadioGroupButton(aProvider) then
      begin
        Exit;
      end;
    end;
  end;

  if ProviderUsesHoverFocusEvent(aProvider) then
  begin
    TAccessibilityProviderEvents.RaiseAutomationEvent(aProvider, UIA_AutomationFocusChangedEventId, aApi);
  end;

  TAccessibilityProviderEvents.RaiseNotification(aProvider, NotificationKind_Other,
    NotificationProcessing_MostRecent, aAnnouncementText, 'vcl-hover', aApi);
end;

function TryResolveHoverProvider(aControl: TWinControl; const aProvider: IRawElementProviderSimple;
  aLParam: LPARAM; out aHitProvider: IRawElementProviderSimple; out aAnnouncementText: string): Boolean;
var
  lClientPoint: TPoint;
  lHit: IRawElementProviderFragment;
  lRoot: IRawElementProviderFragmentRoot;
  lScreenPoint: TPoint;
begin
  aHitProvider := nil;
  aAnnouncementText := '';
  Result := False;
  if (aControl = nil) or (aProvider = nil) or ProviderIsGrid(aProvider) then
  begin
    Exit;
  end;

  if not Supports(aProvider, IRawElementProviderFragmentRoot, lRoot) then
  begin
    aAnnouncementText := ProviderHoverAnnouncementText(aProvider);
    if aAnnouncementText <> '' then
    begin
      aHitProvider := aProvider;
      Exit(True);
    end;

    Exit;
  end;

  lClientPoint := Point(SignedMouseCoordinate(MouseLParamLowWord(aLParam)), SignedMouseCoordinate(MouseLParamHighWord(aLParam)));
  lScreenPoint := aControl.ClientToScreen(lClientPoint);
  lHit := nil;
  if (lRoot.ElementProviderFromPoint(lScreenPoint.X, lScreenPoint.Y, lHit) <> S_OK) or (lHit = nil) or
    not Supports(lHit, IRawElementProviderSimple, aHitProvider) then
  begin
    Exit;
  end;

  if ProvidersAreSame(aProvider, aHitProvider) or ProviderIsGrid(aHitProvider) or
    ProviderSupportsPattern(aHitProvider, UIA_GridItemPatternId) then
  begin
    aHitProvider := nil;
    Exit;
  end;

  aAnnouncementText := ProviderHoverAnnouncementText(aHitProvider);
  Result := aAnnouncementText <> '';
end;

function TryGetFocusedGridCell(const aProvider: IRawElementProviderSimple; out aCol: Integer;
  out aRow: Integer): Boolean;
var
  lCell: IGridItemProvider;
  lFocus: IRawElementProviderFragment;
  lRoot: IRawElementProviderFragmentRoot;
begin
  aCol := 0;
  aRow := 0;
  Result := False;
  if not ProviderIsGrid(aProvider) or not Supports(aProvider, IRawElementProviderFragmentRoot, lRoot) then
  begin
    Exit;
  end;

  if (lRoot.GetFocus(lFocus) <> S_OK) or (lFocus = nil) or not Supports(lFocus, IGridItemProvider, lCell) then
  begin
    Exit;
  end;

  if (lCell.Get_Column(aCol) <> S_OK) or (lCell.Get_Row(aRow) <> S_OK) then
  begin
    Exit;
  end;

  Result := True;
end;

function TryGetGridCell(aControl: TControl; const aProvider: IRawElementProviderSimple; out aCol: Integer;
  out aRow: Integer): Boolean;
begin
  aCol := 0;
  aRow := 0;
  if aControl is TStringGrid then
  begin
    aCol := TStringGrid(aControl).Col;
    aRow := TStringGrid(aControl).Row;
    Exit(True);
  end;

  Result := TryGetFocusedGridCell(aProvider, aCol, aRow);
end;

function IsGridNavigationKey(aKey: WPARAM): Boolean;
begin
  case Integer(aKey) of
    VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT:
      Result := True;
  else
    Result := False;
  end;
end;

function IsListBoxNavigationKey(aKey: WPARAM): Boolean;
begin
  case Integer(aKey) of
    VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT:
      Result := True;
  else
    Result := False;
  end;
end;

function ControlDescription(aControl: TControl): string;
begin
  if aControl = nil then
  begin
    Exit('nil');
  end;

  Result := Format('%s(%s)', [aControl.Name, aControl.ClassName]);
end;

function ManagerState: TAccessibilityManagerState;
begin
  if gManagerState = nil then
  begin
    gManagerState := TAccessibilityManagerState.Create;
  end;

  Result := gManagerState;
end;

destructor TAccessibilityInstalledFormMarker.Destroy;
begin
  if fHook <> nil then
  begin
    if not fHook.Passivate then
    begin
      fHook.Free;
    end;
    fHook := nil;
  end;

  inherited Destroy;
end;

class function TAccessibilityInstalledFormMarker.FindOn(aForm: TCustomForm): TAccessibilityInstalledFormMarker;
var
  i: Integer;
begin
  Result := nil;
  if aForm = nil then
  begin
    Exit;
  end;

  for i := 0 to Pred(aForm.ComponentCount) do
  begin
    if aForm.Components[i] is TAccessibilityInstalledFormMarker then
    begin
      Exit(TAccessibilityInstalledFormMarker(aForm.Components[i]));
    end;
  end;
end;

procedure TAccessibilityInstalledFormMarker.InstallProvider(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry; const aApi: IAccessibilityUiaApi);
var
  lProvider: IAccessibilityProviderNode;
begin
  if fHook <> nil then
  begin
    Exit;
  end;

  fRegistry := aRegistry;
  lProvider := TAccessibilityVclProviderBuilder.BuildForm(aForm, aRegistry, aApi);
  fHook := TAccessibilityFormWindowHook.Create(aForm, lProvider, aApi);
end;

procedure TAccessibilityInstalledFormMarker.RememberRegistry(const aRegistry: IAccessibilityAdapterRegistry);
begin
  fRegistry := aRegistry;
end;

function TAccessibilityInstalledFormMarker.RegistryMatches(
  const aRegistry: IAccessibilityAdapterRegistry): Boolean;
begin
  Result := SameRegistry(fRegistry, aRegistry);
end;

constructor TAccessibilityFormWindowHook.Create(aForm: TCustomForm; const aProvider: IAccessibilityProviderNode;
  const aApi: IAccessibilityUiaApi);
begin
  inherited Create(nil);
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  fApi := aApi;
  fChildHooks := TList<TAccessibilityControlWindowHook>.Create;
  fForm := aForm;
  fProvider := aProvider;
  fOriginalWindowProc := aForm.WindowProc;
  HookChildProviderWindows;
  fForm.FreeNotification(Self);
  fForm.WindowProc := WindowProc;
  TAccessibilityDiagnostics.Log(Format('Installed form hook form=%s hwnd=%d childHooks=%d',
    [ControlDescription(aForm), aForm.Handle, fChildHooks.Count]));
end;

destructor TAccessibilityFormWindowHook.Destroy;
begin
  if not fPassive then
  begin
    Detach;
  end;

  DisconnectProvider;
  ReleaseChildHooks;
  fChildHooks.Free;
  inherited Destroy;
end;

procedure TAccessibilityFormWindowHook.Detach;
begin
  if fForm <> nil then
  begin
    if SameWndMethod(fForm.WindowProc, WindowProc) then
    begin
      fForm.WindowProc := fOriginalWindowProc;
    end;

    fForm.RemoveFreeNotification(Self);
    fForm := nil;
  end;
end;

procedure TAccessibilityFormWindowHook.DisconnectProvider;
begin
  if fProvider <> nil then
  begin
    fProvider.Disconnect;
    fProvider := nil;
  end;
end;

function TAccessibilityFormWindowHook.ControlIsHooked(aControl: TWinControl): Boolean;
var
  lHook: TAccessibilityControlWindowHook;
begin
  Result := False;
  if aControl = nil then
  begin
    Exit;
  end;

  for lHook in fChildHooks do
  begin
    if lHook.fControl = aControl then
    begin
      Exit(True);
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.HookChildProviderWindows;
begin
  if fProvider <> nil then
  begin
    HookProviderWindow(fProvider.RawElementProvider);
    HookMissingWindowControls(fForm);
  end;
end;

procedure TAccessibilityFormWindowHook.HookControlWindow(aControl: TWinControl;
  const aProvider: IRawElementProviderSimple; aPreserveNativeWindowAccessibility: Boolean);
begin
  if (aControl = nil) or (aControl = fForm) or ControlIsHooked(aControl) then
  begin
    Exit;
  end;

  fChildHooks.Add(TAccessibilityControlWindowHook.Create(aControl, aProvider, fApi,
    aPreserveNativeWindowAccessibility));
end;

procedure TAccessibilityFormWindowHook.HookMissingWindowControls(aParent: TWinControl);
var
  i: Integer;
  lChild: TControl;
  lWinControl: TWinControl;
begin
  if (aParent = nil) or (fProvider = nil) then
  begin
    Exit;
  end;

  for i := 0 to Pred(aParent.ControlCount) do
  begin
    lChild := aParent.Controls[i];
    if lChild is TWinControl then
    begin
      lWinControl := TWinControl(lChild);
      if lWinControl is TRadioGroup then
      begin
        HookRadioGroupButtonWindows(TRadioGroup(lWinControl), fProvider.RawElementProvider);
      end;
      if ShouldHookMissingWindowControl(lWinControl) then
      begin
        HookControlWindow(lWinControl, fProvider.RawElementProvider, False);
      end;
      HookMissingWindowControls(lWinControl);
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.HookProviderWindow(const aProvider: IRawElementProviderSimple);
var
  lChild: IRawElementProviderFragment;
  lChildProvider: IRawElementProviderSimple;
  lControl: TControl;
  lFragment: IRawElementProviderFragment;
  lInfo: IAccessibilityVclControlProviderInfo;
  lNextChild: IRawElementProviderFragment;
  lPreserveNativeAccessibility: Boolean;
  lWindowProvider: IRawElementProviderSimple;
begin
  if not Supports(aProvider, IRawElementProviderFragment, lFragment) then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityVclControlProviderInfo, lInfo) then
  begin
    lControl := lInfo.Control;
    EnsureRadioGroupButtonHandles(lControl);
    if lControl is TRadioGroup then
    begin
      HookRadioGroupButtonWindows(TRadioGroup(lControl), aProvider);
    end;
    if (lControl is TWinControl) and (lControl <> fForm) then
    begin
      lPreserveNativeAccessibility := ShouldPreserveNativeWindowAccessibility(TWinControl(lControl));
      lWindowProvider := aProvider;
      if (not lPreserveNativeAccessibility) and not ProviderIsGrid(aProvider) and ProviderHasChildren(aProvider) and
        (fProvider <> nil) and ((lControl is TPageControl) or not TWinControl(lControl).TabStop) then
      begin
        lWindowProvider := fProvider.RawElementProvider;
      end;

      HookControlWindow(TWinControl(lControl), lWindowProvider, lPreserveNativeAccessibility);
    end;
  end;

  if ProviderIsGrid(aProvider) then
  begin
    Exit;
  end;

  if lFragment.Navigate(NavigateDirection_FirstChild, lChild) <> S_OK then
  begin
    Exit;
  end;

  while lChild <> nil do
  begin
    lChildProvider := nil;
    if Supports(lChild, IRawElementProviderSimple, lChildProvider) then
    begin
      HookProviderWindow(lChildProvider);
    end;

    lNextChild := nil;
    if lChild.Navigate(NavigateDirection_NextSibling, lNextChild) <> S_OK then
    begin
      Exit;
    end;
    lChild := lNextChild;
  end;
end;

procedure TAccessibilityFormWindowHook.HookRadioGroupButtonWindows(aRadioGroup: TRadioGroup;
  const aProvider: IRawElementProviderSimple);
var
  i: Integer;
  lButton: TRadioButton;
  lButtonCenter: TPoint;
  lHit: IRawElementProviderFragment;
  lHitProvider: IRawElementProviderSimple;
  lRoot: IRawElementProviderFragmentRoot;
begin
  if (aRadioGroup = nil) or not Supports(aProvider, IRawElementProviderFragmentRoot, lRoot) then
  begin
    Exit;
  end;

  for i := 0 to Pred(aRadioGroup.Items.Count) do
  begin
    lButton := aRadioGroup.Buttons[i];
    lButton.HandleNeeded;
    lButtonCenter := lButton.ClientToScreen(Point(lButton.Width div 2, lButton.Height div 2));
    lHit := nil;
    if (lRoot.ElementProviderFromPoint(lButtonCenter.X, lButtonCenter.Y, lHit) = S_OK) and
      Supports(lHit, IRawElementProviderSimple, lHitProvider) then
    begin
      HookControlWindow(lButton, lHitProvider, False);
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.MaybeRaiseProviderHover(aLParam: LPARAM);
var
  lHitProvider: IRawElementProviderSimple;
  lName: string;
begin
  if (fProvider = nil) or not TryResolveHoverProvider(fForm, fProvider.RawElementProvider, aLParam, lHitProvider,
    lName) then
  begin
    fLastHoverAnnouncement := '';
    Exit;
  end;

  if SameText(fLastHoverAnnouncement, lName) then
  begin
    Exit;
  end;

  fLastHoverAnnouncement := lName;
  RaiseProviderHover(lHitProvider, lName, fApi);
end;

procedure TAccessibilityFormWindowHook.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent, aOperation);
  if (aOperation = opRemove) and (aComponent = fForm) then
  begin
    if SameWndMethod(fForm.WindowProc, WindowProc) then
    begin
      fForm.WindowProc := fOriginalWindowProc;
    end;

    fForm := nil;
    DisconnectProvider;
  end;
end;

function TAccessibilityFormWindowHook.Passivate: Boolean;
begin
  Result := False;
  DisconnectProvider;
  ReleaseChildHooks;
  fApi := nil;
  if fForm = nil then
  begin
    Exit;
  end;

  if SameWndMethod(fForm.WindowProc, WindowProc) then
  begin
    Detach;
  end else begin
    fPassive := True;
    Result := True;
    if gRetainedFormHooks = nil then
    begin
      gRetainedFormHooks := TList<TAccessibilityFormWindowHook>.Create;
    end;

    if not gRetainedFormHooks.Contains(Self) then
    begin
      gRetainedFormHooks.Add(Self);
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.ReleaseChildHooks;
var
  lHook: TAccessibilityControlWindowHook;
begin
  if fChildHooks = nil then
  begin
    Exit;
  end;

  while fChildHooks.Count > 0 do
  begin
    lHook := fChildHooks[Pred(fChildHooks.Count)];
    fChildHooks.Delete(Pred(fChildHooks.Count));
    if not lHook.Passivate then
    begin
      lHook.Free;
    end;
  end;
end;

class procedure TAccessibilityFormWindowHook.ReleaseRetainedHooks;
var
  lHook: TAccessibilityFormWindowHook;
begin
  if gRetainedFormHooks = nil then
  begin
    Exit;
  end;

  while gRetainedFormHooks.Count > 0 do
  begin
    lHook := gRetainedFormHooks[Pred(gRetainedFormHooks.Count)];
    gRetainedFormHooks.Delete(Pred(gRetainedFormHooks.Count));
    lHook.fPassive := False;
    lHook.Detach;
    lHook.Free;
  end;
end;

procedure TAccessibilityFormWindowHook.WindowProc(var aMessage: TMessage);
var
  lIsMouseMoveMessage: Boolean;
  lResult: Winapi.Windows.LRESULT;
begin
  lIsMouseMoveMessage := (aMessage.Msg = WM_MOUSEMOVE) or (aMessage.Msg = WM_NCMOUSEMOVE);
  if (not fPassive) and (fForm <> nil) and (fProvider <> nil) and (aMessage.Msg = WM_GETOBJECT) and
    TAccessibilityProviderWindowMessages.TryHandleGetObject(fForm.Handle, aMessage.WParam, aMessage.LParam,
    fProvider.RawElementProvider, fApi, lResult) then
  begin
    TAccessibilityDiagnostics.Log(Format('Form WM_GETOBJECT handled form=%s hwnd=%d lParam=%d',
      [ControlDescription(fForm), fForm.Handle, aMessage.LParam]));
    aMessage.Result := lResult;
    Exit;
  end;

  if (not fPassive) and (fForm <> nil) and (fProvider <> nil) and (aMessage.Msg = WM_GETOBJECT) and
    TAccessibilityMsaaBridge.TryHandleGetObject(aMessage.WParam, aMessage.LParam, fProvider.RawElementProvider,
    lResult) then
  begin
    TAccessibilityDiagnostics.Log(Format('Form MSAA WM_GETOBJECT handled form=%s hwnd=%d lParam=%d',
      [ControlDescription(fForm), fForm.Handle, aMessage.LParam]));
    aMessage.Result := lResult;
    Exit;
  end;

  fOriginalWindowProc(aMessage);
  if (not fPassive) and (fForm <> nil) and (fProvider <> nil) and lIsMouseMoveMessage then
  begin
    MaybeRaiseProviderHover(MouseMoveClientLParam(fForm, aMessage));
  end;
end;

constructor TAccessibilityControlWindowHook.Create(aControl: TWinControl;
  const aProvider: IRawElementProviderSimple; const aApi: IAccessibilityUiaApi;
  aPreserveNativeWindowAccessibility: Boolean);
begin
  inherited Create(nil);
  if aControl = nil then
  begin
    raise EArgumentException.Create('Control must not be nil.');
  end;

  fApi := aApi;
  fControl := aControl;
  fProvider := aProvider;
  fPreserveNativeWindowAccessibility := aPreserveNativeWindowAccessibility;
  fOriginalWindowProc := aControl.WindowProc;
  InitializeGridCellTracking;
  InitializeListBoxItemTracking;
  fControl.FreeNotification(Self);
  fControl.WindowProc := WindowProc;
  TAccessibilityDiagnostics.Log(Format('Installed child hook control=%s hwnd=%d',
    [ControlDescription(aControl), aControl.Handle]));
end;

destructor TAccessibilityControlWindowHook.Destroy;
begin
  if not fPassive then
  begin
    Detach;
  end;

  inherited Destroy;
end;

procedure TAccessibilityControlWindowHook.Detach;
begin
  if fControl <> nil then
  begin
    if SameWndMethod(fControl.WindowProc, WindowProc) then
    begin
      fControl.WindowProc := fOriginalWindowProc;
    end;

    fControl.RemoveFreeNotification(Self);
    fControl := nil;
  end;
end;

function TAccessibilityControlWindowHook.GridCellChanged: Boolean;
var
  lCol: Integer;
  lRow: Integer;
begin
  Result := False;
  if (fProvider = nil) or not TryGetGridCell(fControl, fProvider, lCol, lRow) then
  begin
    Exit;
  end;

  if fHasLastGridCell and (fLastGridCol = lCol) and (fLastGridRow = lRow) then
  begin
    Exit;
  end;

  fLastGridCol := lCol;
  fLastGridRow := lRow;
  fHasLastGridCell := True;
  Result := True;
end;

procedure TAccessibilityControlWindowHook.InitializeGridCellTracking;
begin
  fHasLastGridCell := (fProvider <> nil) and TryGetGridCell(fControl, fProvider, fLastGridCol, fLastGridRow);
end;

procedure TAccessibilityControlWindowHook.InitializeListBoxItemTracking;
begin
  if fControl is TCustomListBox then
  begin
    fLastListBoxIndex := TCustomListBox(fControl).ItemIndex;
    fHasLastListBoxIndex := True;
  end else begin
    fHasLastListBoxIndex := False;
    fLastListBoxIndex := -1;
  end;
end;

function TAccessibilityControlWindowHook.ListBoxItemChanged: Boolean;
var
  lItemIndex: Integer;
begin
  Result := False;
  if not (fControl is TCustomListBox) then
  begin
    Exit;
  end;

  lItemIndex := TCustomListBox(fControl).ItemIndex;
  if fHasLastListBoxIndex and (fLastListBoxIndex = lItemIndex) then
  begin
    Exit;
  end;

  fLastListBoxIndex := lItemIndex;
  fHasLastListBoxIndex := True;
  Result := lItemIndex >= 0;
end;

procedure TAccessibilityControlWindowHook.MaybeRaiseGridFocusChanged;
begin
  if GridCellChanged then
  begin
    RaiseGridFocusChanged;
  end;
end;

procedure TAccessibilityControlWindowHook.MaybeRaiseListBoxFocusChanged;
begin
  if ListBoxItemChanged then
  begin
    RaiseListBoxFocusChanged;
  end;
end;

procedure TAccessibilityControlWindowHook.MaybeRaiseProviderHover(aLParam: LPARAM);
var
  lHitProvider: IRawElementProviderSimple;
  lName: string;
begin
  if not TryResolveHoverProvider(fControl, fProvider, aLParam, lHitProvider, lName) then
  begin
    fLastHoverAnnouncement := '';
    Exit;
  end;

  if SameText(fLastHoverAnnouncement, lName) then
  begin
    Exit;
  end;

  fLastHoverAnnouncement := lName;
  if fPreserveNativeWindowAccessibility then
  begin
    if ProviderUsesPlatformStateEvents(lHitProvider) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationEvent(lHitProvider, UIA_AutomationFocusChangedEventId, fApi);
    end;
    NotifyProviderNativeFocusAndState(lHitProvider, fControl.Handle);
  end else begin
    RaiseProviderHover(lHitProvider, lName, fApi);
  end;
end;

procedure TAccessibilityControlWindowHook.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent, aOperation);
  if (aOperation = opRemove) and (aComponent = fControl) then
  begin
    if SameWndMethod(fControl.WindowProc, WindowProc) then
    begin
      fControl.WindowProc := fOriginalWindowProc;
    end;

    fControl := nil;
    fProvider := nil;
  end;
end;

function TAccessibilityControlWindowHook.Passivate: Boolean;
begin
  Result := False;
  fApi := nil;
  fProvider := nil;
  if fControl = nil then
  begin
    Exit;
  end;

  if SameWndMethod(fControl.WindowProc, WindowProc) then
  begin
    Detach;
  end else begin
    fPassive := True;
    Result := True;
    if gRetainedControlHooks = nil then
    begin
      gRetainedControlHooks := TList<TAccessibilityControlWindowHook>.Create;
    end;

    if not gRetainedControlHooks.Contains(Self) then
    begin
      gRetainedControlHooks.Add(Self);
    end;
  end;
end;

procedure TAccessibilityControlWindowHook.NotifyFocusHint;
var
  lAnnouncementText: string;
begin
  if fProvider = nil then
  begin
    Exit;
  end;

  if ProviderUsesPlatformStateEvents(fProvider) then
  begin
    Exit;
  end;

  lAnnouncementText := ProviderFocusAnnouncementText(fProvider);
  if lAnnouncementText = '' then
  begin
    Exit;
  end;

  TAccessibilityProviderEvents.RaiseNotification(fProvider, NotificationKind_Other,
    NotificationProcessing_MostRecent, lAnnouncementText, 'vcl-focus-hint', fApi);
end;

procedure TAccessibilityControlWindowHook.RaiseFocusChanged;
var
  lHwnd: HWND;
begin
  if fProvider = nil then
  begin
    Exit;
  end;

  if fPreserveNativeWindowAccessibility then
  begin
    NotifyProviderNativeFocusAndState(fProvider, fControl.Handle);
    Exit;
  end;

  TAccessibilityProviderEvents.RaiseAutomationEvent(fProvider, UIA_AutomationFocusChangedEventId, fApi);
  NotifyAccessibilityWinEvent(EVENT_OBJECT_FOCUS, fControl.Handle, cMsaaObjIdClient, CHILDID_SELF);
  if ProviderUsesPlatformStateEvents(fProvider) then
  begin
    lHwnd := ProviderNativeWindowHandle(fProvider);
    if lHwnd <> 0 then
    begin
      NotifyAccessibilityWinEvent(EVENT_OBJECT_STATECHANGE, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
    end;
  end;
end;

procedure TAccessibilityControlWindowHook.RaiseGridFocusChanged;
var
  lFocus: IRawElementProviderFragment;
  lFocusName: string;
  lFocusProvider: IRawElementProviderSimple;
  lRoot: IRawElementProviderFragmentRoot;
begin
  if (fProvider = nil) or not ProviderIsGrid(fProvider) or not Supports(fProvider, IRawElementProviderFragmentRoot,
    lRoot) then
  begin
    Exit;
  end;

  if (lRoot.GetFocus(lFocus) <> S_OK) or (lFocus = nil) then
  begin
    Exit;
  end;

  if not Supports(lFocus, IRawElementProviderSimple, lFocusProvider) then
  begin
    Exit;
  end;

  TAccessibilityProviderEvents.RaiseAutomationEvent(lFocusProvider, UIA_AutomationFocusChangedEventId, fApi);
  TAccessibilityProviderEvents.RaiseAutomationEvent(lFocusProvider, UIA_SelectionItem_ElementSelectedEventId, fApi);
  lFocusName := ProviderName(lFocusProvider);
  if lFocusName <> '' then
  begin
    TAccessibilityProviderEvents.RaiseNotification(lFocusProvider, NotificationKind_Other,
      NotificationProcessing_MostRecent, lFocusName, 'vcl-grid-cell-focus', fApi);
  end;
end;

procedure TAccessibilityControlWindowHook.RaiseListBoxFocusChanged;
var
  lFocus: IRawElementProviderFragment;
  lFocusName: string;
  lFocusProvider: IRawElementProviderSimple;
  lRoot: IRawElementProviderFragmentRoot;
begin
  if (fProvider = nil) or not (fControl is TCustomListBox) or
    not Supports(fProvider, IRawElementProviderFragmentRoot, lRoot) then
  begin
    Exit;
  end;

  if (lRoot.GetFocus(lFocus) <> S_OK) or (lFocus = nil) then
  begin
    Exit;
  end;

  if not Supports(lFocus, IRawElementProviderSimple, lFocusProvider) then
  begin
    Exit;
  end;

  TAccessibilityProviderEvents.RaiseAutomationEvent(lFocusProvider, UIA_AutomationFocusChangedEventId, fApi);
  TAccessibilityProviderEvents.RaiseAutomationEvent(lFocusProvider, UIA_SelectionItem_ElementSelectedEventId, fApi);
  lFocusName := ProviderName(lFocusProvider);
  if lFocusName <> '' then
  begin
    TAccessibilityProviderEvents.RaiseNotification(lFocusProvider, NotificationKind_Other,
      NotificationProcessing_MostRecent, lFocusName, 'vcl-listbox-item-focus', fApi);
  end;
end;

class procedure TAccessibilityControlWindowHook.ReleaseRetainedHooks;
var
  lHook: TAccessibilityControlWindowHook;
begin
  if gRetainedControlHooks = nil then
  begin
    Exit;
  end;

  while gRetainedControlHooks.Count > 0 do
  begin
    lHook := gRetainedControlHooks[Pred(gRetainedControlHooks.Count)];
    gRetainedControlHooks.Delete(Pred(gRetainedControlHooks.Count));
    lHook.fPassive := False;
    lHook.Detach;
    lHook.Free;
  end;
end;

procedure TAccessibilityControlWindowHook.WindowProc(var aMessage: TMessage);
var
  lHasOldProviderState: Boolean;
  lIsFocusMessage: Boolean;
  lIsGridNavigationMessage: Boolean;
  lIsListBoxSelectionMessage: Boolean;
  lIsMouseMoveMessage: Boolean;
  lIsOuterProviderStateMessage: Boolean;
  lIsProviderStateMessage: Boolean;
  lNewProviderState: TProviderStateSnapshot;
  lOldProviderState: TProviderStateSnapshot;
  lResult: Winapi.Windows.LRESULT;
begin
  if (not fPreserveNativeWindowAccessibility) and (not fPassive) and (fControl <> nil) and (fProvider <> nil) and
    (aMessage.Msg = WM_GETOBJECT) and
    TAccessibilityProviderWindowMessages.TryHandleGetObject(fControl.Handle, aMessage.WParam, aMessage.LParam,
    fProvider, fApi, lResult) then
  begin
    TAccessibilityDiagnostics.Log(Format('Child WM_GETOBJECT handled control=%s hwnd=%d lParam=%d',
      [ControlDescription(fControl), fControl.Handle, aMessage.LParam]));
    aMessage.Result := lResult;
    Exit;
  end;

  if (not fPreserveNativeWindowAccessibility) and (not fPassive) and (fControl <> nil) and (fProvider <> nil) and
    (aMessage.Msg = WM_GETOBJECT) and
    TAccessibilityMsaaBridge.TryHandleGetObject(aMessage.WParam, aMessage.LParam, fProvider, lResult) then
  begin
    TAccessibilityDiagnostics.Log(Format('Child MSAA WM_GETOBJECT handled control=%s hwnd=%d lParam=%d',
      [ControlDescription(fControl), fControl.Handle, aMessage.LParam]));
    aMessage.Result := lResult;
    Exit;
  end;

  lIsFocusMessage := (aMessage.Msg = CM_ENTER) or (aMessage.Msg = WM_SETFOCUS);
  lIsGridNavigationMessage := (aMessage.Msg = WM_KEYDOWN) and IsGridNavigationKey(aMessage.WParam);
  lIsListBoxSelectionMessage := (fControl is TCustomListBox) and
    (((aMessage.Msg = WM_KEYDOWN) and IsListBoxNavigationKey(aMessage.WParam)) or
    (aMessage.Msg = WM_LBUTTONUP) or (aMessage.Msg = CM_CHANGED));
  lIsMouseMoveMessage := (aMessage.Msg = WM_MOUSEMOVE) or (aMessage.Msg = WM_NCMOUSEMOVE);
  lIsProviderStateMessage := (not fPreserveNativeWindowAccessibility) and ProviderStateMessageMayChangeState(aMessage);
  lIsOuterProviderStateMessage := lIsProviderStateMessage and (fProviderStateMessageDepth = 0);
  lHasOldProviderState := lIsOuterProviderStateMessage and TryCaptureProviderState(fProvider, lOldProviderState);
  if lIsProviderStateMessage then
  begin
    Inc(fProviderStateMessageDepth);
  end;
  try
    fOriginalWindowProc(aMessage);
  finally
    if lIsProviderStateMessage then
    begin
      Dec(fProviderStateMessageDepth);
    end;
  end;
  if (not fPassive) and (fControl <> nil) and (fProvider <> nil) then
  begin
    if lIsOuterProviderStateMessage and lHasOldProviderState and TryCaptureProviderState(fProvider, lNewProviderState) and
      not ProviderStatesEqual(lOldProviderState, lNewProviderState) and
      (not fHasLastRaisedProviderState or not ProviderStatesEqual(fLastRaisedProviderState, lNewProviderState)) then
    begin
      RaiseProviderStateChanged(fProvider, lOldProviderState, lNewProviderState, fApi);
      fLastRaisedProviderState := lNewProviderState;
      fHasLastRaisedProviderState := True;
    end;

    if lIsMouseMoveMessage then
    begin
      MaybeRaiseProviderHover(MouseMoveClientLParam(fControl, aMessage));
    end;

    if lIsFocusMessage then
    begin
      RaiseFocusChanged;
      NotifyFocusHint;
    end;

    if lIsGridNavigationMessage or (aMessage.Msg = CM_CHANGED) then
    begin
      MaybeRaiseGridFocusChanged;
    end;

    if lIsListBoxSelectionMessage then
    begin
      MaybeRaiseListBoxFocusChanged;
    end;
  end;
end;

constructor TAccessibilityManagerState.Create;
begin
  inherited Create;
end;

destructor TAccessibilityManagerState.Destroy;
begin
  Uninstall;
  inherited Destroy;
end;

procedure TAccessibilityManagerState.ActiveFormChanged(aSender: TObject);
begin
  if Assigned(fPreviousActiveFormChange) then
  begin
    fPreviousActiveFormChange(aSender);
  end;

  if fAppInstalled then
  begin
    ScanCurrentForms;
  end;
end;

procedure TAccessibilityManagerState.EnsureApplicationRegistry(const aRegistry: IAccessibilityAdapterRegistry);
begin
  if fAppInstalled and not SameRegistry(fApplicationRegistry, aRegistry) then
  begin
    raise EInvalidOperation.Create('Call TAccessibilityManager.Uninstall before changing the app-wide adapter registry.');
  end;
end;

procedure TAccessibilityManagerState.EnsureFormRegistryAllowed(const aRegistry: IAccessibilityAdapterRegistry);
begin
  if fAppInstalled and not SameRegistry(fApplicationRegistry, aRegistry) then
  begin
    raise EInvalidOperation.Create('Pass the active app-wide adapter registry or call TAccessibilityManager.Uninstall first.');
  end;
end;

procedure TAccessibilityManagerState.EnsureInstalledFormsRegistry(const aRegistry: IAccessibilityAdapterRegistry);
var
  i: Integer;
  lMarker: TAccessibilityInstalledFormMarker;
begin
  for i := 0 to Pred(Screen.CustomFormCount) do
  begin
    lMarker := TAccessibilityInstalledFormMarker.FindOn(Screen.CustomForms[i]);
    if (lMarker <> nil) and not lMarker.RegistryMatches(aRegistry) then
    begin
      raise EInvalidOperation.Create('Call TAccessibilityManager.Uninstall before changing a form adapter registry.');
    end;
  end;
end;

procedure TAccessibilityManagerState.HookScreen;
begin
  if fScreenHookInstalled then
  begin
    if SameNotifyEvent(Screen.OnActiveFormChange, ActiveFormChanged) then
    begin
      Exit;
    end;

    if SameNotifyEvent(Screen.OnActiveFormChange, fPreviousActiveFormChange) then
    begin
      fPreviousActiveFormChange := nil;
      fScreenHookInstalled := False;
    end else begin
      Exit;
    end;
  end;

  fPreviousActiveFormChange := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := ActiveFormChanged;
  fScreenHookInstalled := True;
end;

procedure TAccessibilityManagerState.InstallHintController(aApplication: TApplication; aAppWide: Boolean);
var
  lProvider: IAccessibilityProviderNode;
begin
  if fHintController <> nil then
  begin
    if (not aAppWide) or fHintControllerAppWide then
    begin
      Exit;
    end;

    ReleaseHintController;
  end;

  lProvider := TAccessibilityProviderFactory.CreateRoot([2], 0, fUiaApi);
  lProvider.SetProperty(UIA_NamePropertyId, 'VCL hints');
  lProvider.SetProperty(UIA_ControlTypePropertyId, UIA_ToolTipControlTypeId);
  lProvider.SetProperty(UIA_ClassNamePropertyId, 'TAccessibilityHintController');
  if aAppWide then
  begin
    fHintController := TAccessibilityHintController.Create(aApplication, lProvider, fUiaApi);
  end else begin
    fHintController := TAccessibilityHintController.Create(nil, lProvider, fUiaApi);
  end;
  fHintControllerAppWide := aAppWide;
end;

function TAccessibilityManagerState.InstalledFormCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Pred(Screen.CustomFormCount) do
  begin
    if TAccessibilityInstalledFormMarker.FindOn(Screen.CustomForms[i]) <> nil then
    begin
      Inc(Result);
    end;
  end;
end;

procedure TAccessibilityManagerState.InstallApplication(aApplication: TApplication);
begin
  InstallApplication(aApplication, nil);
end;

procedure TAccessibilityManagerState.InstallApplication(aApplication: TApplication;
  const aRegistry: IAccessibilityAdapterRegistry);
begin
  if aApplication = nil then
  begin
    raise EArgumentException.Create('Application must not be nil.');
  end;

  EnsureApplicationRegistry(aRegistry);
  EnsureInstalledFormsRegistry(aRegistry);

  if not fAppInstalled then
  begin
    fApplicationRegistry := aRegistry;
    fAppInstalled := True;
    HookScreen;
  end;

  InstallHintController(aApplication, True);
  ScanCurrentForms;
end;

procedure TAccessibilityManagerState.InstallForm(aForm: TCustomForm);
begin
  InstallFormWithRegistry(aForm, nil);
end;

procedure TAccessibilityManagerState.InstallForm(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry);
begin
  InstallFormWithRegistry(aForm, aRegistry);
end;

procedure TAccessibilityManagerState.InstallFormWithRegistry(aForm: TCustomForm;
  const aRegistry: IAccessibilityAdapterRegistry);
var
  lMarker: TAccessibilityInstalledFormMarker;
begin
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  if not ShouldInstallForm(aForm) then
  begin
    Exit;
  end;

  EnsureFormRegistryAllowed(aRegistry);

  if fHintController = nil then
  begin
    InstallHintController(nil, False);
  end;

  lMarker := TAccessibilityInstalledFormMarker.FindOn(aForm);
  if lMarker <> nil then
  begin
    if not lMarker.RegistryMatches(aRegistry) then
    begin
      raise EInvalidOperation.Create('Call TAccessibilityManager.Uninstall before changing a form adapter registry.');
    end;

    if fHintController <> nil then
    begin
      fHintController.ObserveForm(aForm);
    end;
    Exit;
  end;

  lMarker := TAccessibilityInstalledFormMarker.Create(aForm);
  try
    if fFormInstaller <> nil then
    begin
      fFormInstaller.InstallForm(aForm);
      lMarker.RememberRegistry(aRegistry);
    end else begin
      lMarker.InstallProvider(aForm, aRegistry, fUiaApi);
    end;
  except
    lMarker.Free;
    raise;
  end;

  if fHintController <> nil then
  begin
    fHintController.ObserveForm(aForm);
  end;
end;

procedure TAccessibilityManagerState.RemoveInstalledMarkers;
var
  i: Integer;
  lMarker: TAccessibilityInstalledFormMarker;
begin
  for i := Pred(Screen.CustomFormCount) downto 0 do
  begin
    repeat
      lMarker := TAccessibilityInstalledFormMarker.FindOn(Screen.CustomForms[i]);
      if lMarker <> nil then
      begin
        lMarker.Free;
      end;
    until lMarker = nil;
  end;
end;

procedure TAccessibilityManagerState.ReleaseHintController;
begin
  if fHintController = nil then
  begin
    Exit;
  end;

  if not fHintController.Passivate then
  begin
    fHintController.Free;
  end;

  fHintController := nil;
  fHintControllerAppWide := False;
end;

procedure TAccessibilityManagerState.RestoreScreenHook;
begin
  if not fScreenHookInstalled then
  begin
    Exit;
  end;

  if SameNotifyEvent(Screen.OnActiveFormChange, ActiveFormChanged) then
  begin
    Screen.OnActiveFormChange := fPreviousActiveFormChange;
    fPreviousActiveFormChange := nil;
    fScreenHookInstalled := False;
  end else if SameNotifyEvent(Screen.OnActiveFormChange, fPreviousActiveFormChange) then
  begin
    fPreviousActiveFormChange := nil;
    fScreenHookInstalled := False;
  end;
end;

procedure TAccessibilityManagerState.ScanCurrentForms;
var
  i: Integer;
begin
  for i := 0 to Pred(Screen.FormCount) do
  begin
    if ShouldInstallForm(Screen.Forms[i]) then
    begin
      InstallFormWithRegistry(Screen.Forms[i], fApplicationRegistry);
    end;
  end;
end;

procedure TAccessibilityManagerState.SetFormInstaller(const aInstaller: IAccessibilityFormInstaller);
begin
  fFormInstaller := aInstaller;
end;

procedure TAccessibilityManagerState.SetUiaApi(const aApi: IAccessibilityUiaApi);
begin
  fUiaApi := aApi;
end;

procedure TAccessibilityManagerState.Uninstall;
begin
  fAppInstalled := False;
  fApplicationRegistry := nil;
  ReleaseHintController;
  RemoveInstalledMarkers;
  RestoreScreenHook;
end;

class procedure TAccessibilityManager.Install(aApplication: TApplication);
begin
  ManagerState.InstallApplication(aApplication);
end;

class procedure TAccessibilityManager.Install(aApplication: TApplication;
  const aRegistry: IAccessibilityAdapterRegistry);
begin
  ManagerState.InstallApplication(aApplication, aRegistry);
end;

class procedure TAccessibilityManager.Install(aForm: TCustomForm);
begin
  ManagerState.InstallForm(aForm);
end;

class procedure TAccessibilityManager.Install(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry);
begin
  ManagerState.InstallForm(aForm, aRegistry);
end;

class procedure TAccessibilityManager.Run(aApplication: TApplication);
begin
  try
    Install(aApplication);
    aApplication.Run;
  finally
    Uninstall;
  end;
end;

class procedure TAccessibilityManager.Uninstall;
begin
  ManagerState.Uninstall;
end;

class function TAccessibilityManagerInternals.InstalledFormCount: Integer;
begin
  Result := ManagerState.InstalledFormCount;
end;

class procedure TAccessibilityManagerInternals.SetFormInstaller(const aInstaller: IAccessibilityFormInstaller);
begin
  ManagerState.SetFormInstaller(aInstaller);
end;

class procedure TAccessibilityManagerInternals.SetUiaApi(const aApi: IAccessibilityUiaApi);
begin
  ManagerState.SetUiaApi(aApi);
end;

class procedure TAccessibilityManagerInternals.SetWinEventSink(const aSink: IAccessibilityWinEventSink);
begin
  gWinEventSink := aSink;
end;

initialization
  gManagerState := TAccessibilityManagerState.Create;

finalization
  gManagerState.Free;
  TAccessibilityControlWindowHook.ReleaseRetainedHooks;
  TAccessibilityFormWindowHook.ReleaseRetainedHooks;
  gRetainedControlHooks.Free;
  gRetainedFormHooks.Free;

end.
