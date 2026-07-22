unit MaxLogic.Accessibility.Manager;

interface

uses
  Winapi.Windows,
  Vcl.Forms,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner, MaxLogic.Accessibility.UIAutomationCore;

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
    class function TryGetInstalledFormProvider(aForm: TCustomForm; out aProvider: IRawElementProviderSimple):
      Boolean; static;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.Generics.Collections, System.SysUtils, System.Types, System.Variants,
  Winapi.Messages, Winapi.oleacc, Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls,
  MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.Hints, MaxLogic.Accessibility.Msaa,
  MaxLogic.Accessibility.Text, MaxLogic.Accessibility.VclAdapters;

const
  cMaxHoverMissChildCount = 128;
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

  TRuntimeProviderSnapshot = record
    Bounds: UiaRect;
    Enabled: Boolean;
    HasBounds: Boolean;
    HasEnabled: Boolean;
    HasHelpText: Boolean;
    HasName: Boolean;
    HasOffscreen: Boolean;
    HasValue: Boolean;
    HelpText: string;
    Name: string;
    Offscreen: Boolean;
    Provider: IRawElementProviderSimple;
    Value: string;
  end;

  THoverChildGeometry = record
    Bounds: TRect;
    Control: TControl;
    Visible: Boolean;
  end;

  THoverPoints = record
    Client: TPoint;
    Screen: TPoint;
  end;

  THoverResolution = record
    Announcement: string;
    HasLeafBounds: Boolean;
    HasMissBounds: Boolean;
    HitProvider: IRawElementProviderSimple;
    LeafBounds: UiaRect;
    MissBounds: TRect;
    MissChildren: TArray<THoverChildGeometry>;
  end;

  THoverCache = record
    Announcement: string;
    HasLeafBounds: Boolean;
    HasMissBounds: Boolean;
    LeafBounds: UiaRect;
    MissBounds: TRect;
    MissChildren: TArray<THoverChildGeometry>;
    procedure Clear;
    procedure ClearMiss;
    function Matches(aControl: TWinControl; const aPoints: THoverPoints): Boolean;
    procedure RememberHitBounds(const aResolution: THoverResolution);
    procedure RememberMiss(const aResolution: THoverResolution);
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
    fChildHooksByControl: TDictionary<TWinControl, TAccessibilityControlWindowHook>;
    fForm: TCustomForm;
    fHoverCache: THoverCache;
    fMsaaAccessible: IAccessible;
    fObservedRevision: Integer;
    fObservedScan: IAccessibilityObservedFormScan;
    fOriginalWindowProc: TWndMethod;
    fPassive: Boolean;
    fProvider: IAccessibilityProviderNode;
    fRetained: Boolean;
    fRuntimeProperties: TDictionary<TObject, TRuntimeProviderSnapshot>;
    function ControlIsHooked(aControl: TWinControl): Boolean;
    procedure Detach;
    procedure DisconnectProvider;
    procedure HookChildProviderWindows;
    procedure HookControlWindow(aControl: TWinControl; const aProvider: IRawElementProviderSimple;
      aPreserveNativeWindowAccessibility: Boolean);
    procedure HookMissingWindowControls(aParent: TWinControl);
    procedure HookProviderWindow(const aProvider: IRawElementProviderSimple);
    procedure HookRadioGroupButtonWindows(aRadioGroup: TRadioGroup; const aProvider: IRawElementProviderSimple);
    procedure MaybeRaiseProviderHover(aLParam: LPARAM; aClientsKnown: Boolean; aClientsListening: Boolean);
    procedure NotifyProviderWinEvent(const aProvider: IRawElementProviderSimple; aEvent: DWORD);
    procedure PruneRuntimePropertySnapshots(const aTree: IAccessibilityScanTree);
    procedure ReconcileRuntimeHierarchy;
    function Passivate: Boolean;
    procedure ReleaseChildHooks;
    procedure ReleaseObsoleteChildHooks;
    procedure RefreshRuntimeProperties(aPublishChanges: Boolean);
    procedure SynchronizeProviderProperties(const aProvider: IRawElementProviderSimple; aIsRoot: Boolean;
      aPublishChanges: Boolean);
    procedure SynchronizeFormName;
    procedure SynchronizeRuntimeProperties;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    class procedure ReleaseRetainedHooks; static;
    constructor Create(aForm: TCustomForm; const aProvider: IAccessibilityProviderNode;
      const aRegistry: IAccessibilityAdapterRegistry; const aApi: IAccessibilityUiaApi); reintroduce;
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
    fHoverCache: THoverCache;
    fLastFocusAnnouncement: string;
    fLastGridCol: Integer;
    fLastGridRow: Integer;
    fLastListBoxIndex: Integer;
    fLastRaisedProviderState: TProviderStateSnapshot;
    fListBoxSelectionTracker: IAccessibilityListBoxSelectionTracker;
    fMsaaAccessible: IAccessible;
    fOriginalWindowProc: TWndMethod;
    fPassive: Boolean;
    fPreserveNativeWindowAccessibility: Boolean;
    fProvider: IRawElementProviderSimple;
    fProviderIsGrid: Boolean;
    fProviderNativeWindowHandleCheckHwnd: HWND;
    fProviderNativeWindowHandleCheckValid: Boolean;
    fProviderPublishesNativeWindowHandle: Boolean;
    fProviderStateMessageDepth: Integer;
    fRetained: Boolean;
    fRootProvider: IRawElementProviderSimple;
    procedure Detach;
    function GridCellChanged: Boolean;
    procedure InitializeGridCellTracking;
    procedure InitializeListBoxItemTracking;
    function ListBoxItemChanged: Boolean;
    function NativeListBoxShouldHandleGetObject(const aMessage: TMessage): Boolean;
    function NativeListBoxShouldHandleNavigationMessage(const aMessage: TMessage): Boolean;
    function NativeFocusUsesOnlyNativeStateEvents: Boolean;
    procedure NotifyListBoxSelectionMayHaveChanged;
    procedure MaybeRaiseGridFocusChanged;
    procedure MaybeRaiseListBoxFocusChanged;
    procedure MaybeRaiseProviderHover(aLParam: LPARAM; aClientsKnown: Boolean; aClientsListening: Boolean);
    procedure MaybeRaiseRadioNavigationChanged(aPreviousRadio: TRadioButton);
    function Passivate: Boolean;
    procedure RaiseResolvedProviderHover(const aResolution: THoverResolution; aClientsKnown: Boolean;
      aClientsListening: Boolean);
    function ProviderPublishesControlNativeWindowHandle: Boolean;
    procedure RaiseFocusChanged;
    procedure NotifyFocusHint;
    procedure RaiseGridFocusChanged;
    procedure RaiseListBoxFocusChanged;
    procedure RaiseRadioNavigationChanged(aSelectedRadio: TRadioButton);
    function TryCurrentSelectedGroupedRadio(out aRadio: TRadioButton): Boolean;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    class procedure ReleaseRetainedHooks; static;
    constructor Create(aControl: TWinControl; const aProvider: IRawElementProviderSimple;
      const aApi: IAccessibilityUiaApi; const aRootProvider: IRawElementProviderSimple;
      aPreserveNativeWindowAccessibility: Boolean); reintroduce;
    destructor Destroy; override;
    procedure WindowProc(var aMessage: TMessage);
  end;

  TAccessibilityManagerState = class
  private
    fAppInstalled: Boolean;
    fApplicationRegistry: IAccessibilityAdapterRegistry;
    fHintController: TAccessibilityHintController;
    fHintControllerAppWide: Boolean;
    fIdleDispatching: Boolean;
    fIdleHookInstalled: Boolean;
    fFormInstaller: IAccessibilityFormInstaller;
    fPreviousIdle: TIdleEvent;
    fPreviousActiveFormChange: TNotifyEvent;
    fScreenHookInstalled: Boolean;
    fUiaApi: IAccessibilityUiaApi;
    procedure ActiveFormChanged(aSender: TObject);
    procedure ApplicationIdle(aSender: TObject; var aDone: Boolean);
    procedure EnsureApplicationRegistry(const aRegistry: IAccessibilityAdapterRegistry);
    procedure EnsureFormRegistryAllowed(const aRegistry: IAccessibilityAdapterRegistry);
    procedure EnsureInstalledFormsRegistry(const aRegistry: IAccessibilityAdapterRegistry);
    procedure HookScreen;
    procedure HookApplicationIdle;
    procedure InstallHintController(aApplication: TApplication; aAppWide: Boolean);
    procedure InstallFormWithRegistry(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry);
    procedure RemoveInstalledMarkers;
    procedure ReleaseHintController;
    procedure RestoreScreenHook;
    procedure RestoreApplicationIdleHook;
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
  TAccessibilityDiagnostics.RecordSupplementalMsaaEvent(aEvent);
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

function SameIdleEvent(const aLeft: TIdleEvent; const aRight: TIdleEvent): Boolean;
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

function TryProviderDirectChildAt(const aProvider: IRawElementProviderSimple; aIndex: Integer;
  out aChild: IRawElementProviderSimple): Boolean;
var
  lChildAccess: IAccessibilityProviderChildAccess;
begin
  aChild := nil;
  Result := Supports(aProvider, IAccessibilityProviderChildAccess, lChildAccess) and
    (lChildAccess.DirectChildAt(aIndex, aChild) = S_OK) and (aChild <> nil); //PALOFF WARN61 out value is written by DirectChildAt
end;

function TryProviderDirectChildCount(const aProvider: IRawElementProviderSimple; out aCount: Integer): Boolean;
var
  lChildAccess: IAccessibilityProviderChildAccess;
begin
  aCount := 0;
  Result := Supports(aProvider, IAccessibilityProviderChildAccess, lChildAccess) and
    (lChildAccess.DirectChildCount(aCount) = S_OK);
end;

function ProviderHasChildren(const aProvider: IRawElementProviderSimple): Boolean;
var
  lChild: IRawElementProviderFragment;
  lCount: Integer;
  lFragment: IRawElementProviderFragment;
begin
  Result := False;
  if TryProviderDirectChildCount(aProvider, lCount) then
  begin
    Exit(lCount > 0);
  end;

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
  Result := (aControl is TCustomCheckBox) or ((aControl is TRadioButton) and
    not ((aControl.Parent is TRadioGroup) or (aControl.Parent is TCustomGroupBox)));
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

  lRadioGroup := TRadioGroup(aControl); //PALOFF STWA6 guarded by is TRadioGroup
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
var
  lRawValue: Int64;
begin
  lRawValue := Int64(aValue) and $00000000FFFFFFFF; //PALOFF WARN63 explicit unsigned normalization
  Result := Word(lRawValue and $FFFF); //PALOFF WARN52 explicit low-word extraction
end;

function MouseLParamHighWord(aValue: LPARAM): Word;
var
  lRawValue: Int64;
begin
  lRawValue := Int64(aValue) and $00000000FFFFFFFF; //PALOFF WARN63 explicit unsigned normalization
  Result := Word((lRawValue shr 16) and $FFFF); //PALOFF WARN52 explicit high-word extraction
end;

function PointToMouseLParam(const aPoint: TPoint): LPARAM;
var
  lValue: Int64;
begin
  lValue := Int64(MouseCoordinateWord(aPoint.X)) or (Int64(MouseCoordinateWord(aPoint.Y)) shl 16); //PALOFF WARN63 Win32 LPARAM packing
  if (lValue and $80000000) <> 0 then
  begin
    Dec(lValue, $100000000);
  end;

  Result := LPARAM(lValue); //PALOFF STWA6 explicit LPARAM conversion
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

function MouseClientPoint(aLParam: LPARAM): TPoint;
begin
  Result := Point(SignedMouseCoordinate(MouseLParamLowWord(aLParam)),
    SignedMouseCoordinate(MouseLParamHighWord(aLParam)));
end;

function MouseHoverPoints(aControl: TWinControl; aLParam: LPARAM): THoverPoints;
begin
  Result.Client := MouseClientPoint(aLParam);
  Result.Screen := Result.Client;
  if aControl <> nil then
  begin
    Result.Screen := aControl.ClientToScreen(Result.Screen);
  end;
end;

function UiaRectContainsScreenPoint(const aRect: UiaRect; const aPoint: TPoint): Boolean;
begin
  Result := (aPoint.X >= aRect.Left) and (aPoint.Y >= aRect.Top) and (aPoint.X < aRect.Left + aRect.Width) and
    (aPoint.Y < aRect.Top + aRect.Height);
end;

function TryGetVclControlBounds(aControl: TControl; out aBounds: UiaRect): Boolean;
var
  lPoint: TPoint;
begin
  aBounds := Default(UiaRect);
  Result := False;
  if (aControl = nil) or (aControl.Width <= 0) or (aControl.Height <= 0) then
  begin
    Exit;
  end;

  lPoint := aControl.ClientToScreen(Point(0, 0));
  aBounds.Left := lPoint.X;
  aBounds.Top := lPoint.Y;
  aBounds.Width := aControl.Width;
  aBounds.Height := aControl.Height;
  Result := True;
end;

function TryGetVclLeafControlBounds(aControl: TControl; out aBounds: UiaRect): Boolean;
begin
  aBounds := Default(UiaRect);
  Result := False;
  if (aControl is TWinControl) and (TWinControl(aControl).ControlCount > 0) then
  begin
    Exit;
  end;

  Result := TryGetVclControlBounds(aControl, aBounds);
end;

function TryGetVclLeafProviderBounds(const aProvider: IRawElementProviderSimple; out aBounds: UiaRect): Boolean;
var
  lControl: TControl;
  lInfo: IAccessibilityVclControlProviderInfo;
begin
  aBounds := Default(UiaRect);
  Result := False;
  if not Supports(aProvider, IAccessibilityVclControlProviderInfo, lInfo) then
  begin
    Exit;
  end;

  lControl := lInfo.Control;
  Result := TryGetVclLeafControlBounds(lControl, aBounds);
end;

procedure THoverCache.Clear;
begin
  Announcement := '';
  HasLeafBounds := False;
  ClearMiss;
end;

procedure THoverCache.ClearMiss;
begin
  HasMissBounds := False;
  MissChildren := nil;
end;

function HoverChildGeometryMatches(aControl: TWinControl;
  const aChildren: TArray<THoverChildGeometry>): Boolean;
var
  i: Integer;
  lBounds: TRect;
  lChild: TControl;
begin
  Result := False;
  if (aControl = nil) or (aControl.ControlCount <> Length(aChildren)) then
  begin
    Exit;
  end;

  for i := 0 to Pred(aControl.ControlCount) do
  begin
    lChild := aControl.Controls[i];
    lBounds := lChild.BoundsRect;
    if (lChild <> aChildren[i].Control) or (lChild.Visible <> aChildren[i].Visible) or
      not EqualRect(lBounds, aChildren[i].Bounds) then
    begin
      Exit;
    end;
  end;

  Result := True;
end;

function THoverCache.Matches(aControl: TWinControl; const aPoints: THoverPoints): Boolean;
begin
  Result := (Announcement <> '') and HasLeafBounds and UiaRectContainsScreenPoint(LeafBounds, aPoints.Screen);
  if Result or not HasMissBounds or not PtInRect(MissBounds, aPoints.Client) then
  begin
    Exit;
  end;

  Result := HoverChildGeometryMatches(aControl, MissChildren);
end;

procedure THoverCache.RememberMiss(const aResolution: THoverResolution);
begin
  Clear;
  if not aResolution.HasMissBounds then
  begin
    Exit;
  end;

  HasMissBounds := True;
  MissBounds := aResolution.MissBounds;
  MissChildren := aResolution.MissChildren;
end;

function HoverMissCacheInvalidatingMessage(aMessageId: Cardinal): Boolean;
begin
  case aMessageId of
    CM_CHANGED, CM_CONTROLCHANGE, CM_CONTROLLISTCHANGE, CM_ENABLEDCHANGED, CM_ENTER, CM_EXIT, CM_FOCUSCHANGED,
    CM_SHOWINGCHANGED, CM_TEXTCHANGED, CM_VISIBLECHANGED, WM_ENABLE, WM_KILLFOCUS, WM_MOVE, WM_SETFOCUS,
    WM_SETTEXT, WM_SHOWWINDOW, WM_SIZE, WM_WINDOWPOSCHANGED:
      Result := True;
  else
    Result := False;
  end;
end;

function ShouldInstallForm(aForm: TCustomForm): Boolean;
begin
  // VCL keeps this sentinel in Screen.Forms when no real form is active.
  Result := (aForm <> nil) and not SameText(aForm.ClassName, 'TNoActiveForm');
end;

function ProviderSupportsPattern(const aProvider: IRawElementProviderSimple; aPatternId: PATTERNID): Boolean;
var
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lPattern: IUnknown;
begin
  Result := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) then
  begin
    Exit(lDirectAccess.SupportsPatternDirect(aPatternId));
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

function TryGetProviderBounds(const aProvider: IRawElementProviderSimple; out aBounds: UiaRect): Boolean;
var
  lFragment: IRawElementProviderFragment;
  lGeometryAccess: IAccessibilityProviderGeometryAccess;
begin
  aBounds := Default(UiaRect);
  if Supports(aProvider, IAccessibilityProviderGeometryAccess, lGeometryAccess) and
    lGeometryAccess.TryGetBoundingRectangle(aBounds) then
  begin
    Exit((aBounds.Width > 0) and (aBounds.Height > 0));
  end;

  Result := Supports(aProvider, IRawElementProviderFragment, lFragment) and
    (lFragment.Get_BoundingRectangle(aBounds) = S_OK) and (aBounds.Width > 0) and (aBounds.Height > 0);
end;

procedure UpdateHoverLeafCache(const aProvider: IRawElementProviderSimple; var aHasLeafBounds: Boolean;
  var aLeafBounds: UiaRect);
var
  lBounds: UiaRect;
begin
  aHasLeafBounds := False;
  if aProvider = nil then
  begin
    Exit;
  end;

  if not TryGetVclLeafProviderBounds(aProvider, lBounds) then
  begin
    if ProviderHasChildren(aProvider) or not TryGetProviderBounds(aProvider, lBounds) then
    begin
      Exit;
    end;
  end;

  aLeafBounds := lBounds;
  aHasLeafBounds := True;
end;

procedure THoverCache.RememberHitBounds(const aResolution: THoverResolution);
begin
  ClearMiss;
  if aResolution.HasLeafBounds then
  begin
    LeafBounds := aResolution.LeafBounds;
    HasLeafBounds := True;
  end else begin
    UpdateHoverLeafCache(aResolution.HitProvider, HasLeafBounds, LeafBounds);
  end;
end;

function ProviderHelpText(const aProvider: IRawElementProviderSimple): string;
var
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lValue: OleVariant;
begin
  Result := '';
  if aProvider = nil then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) and
    lDirectAccess.TryGetStringProperty(UIA_HelpTextPropertyId, Result) then
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
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lValue: OleVariant;
begin
  Result := '';
  if aProvider = nil then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) and
    lDirectAccess.TryGetStringProperty(UIA_NamePropertyId, Result) then
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
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lValue: OleVariant;
begin
  Result := UIA_CustomControlTypeId;
  if aProvider = nil then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) and
    lDirectAccess.TryGetIntegerProperty(UIA_ControlTypePropertyId, Result) then
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
  lNativeWindow: IAccessibilityProviderNativeWindow;
  lValue: OleVariant;
begin
  Result := 0;
  if aProvider = nil then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityProviderNativeWindow, lNativeWindow) then
  begin
    Exit(lNativeWindow.NativeWindowHandle);
  end;

  if (aProvider.GetPropertyValue(UIA_NativeWindowHandlePropertyId, lValue) = S_OK) and not VarIsEmpty(lValue) and
    not VarIsNull(lValue) then
  begin
    Result := HWND(NativeInt(lValue));
  end;
end;

function ProviderPublishesNativeWindowHandleForHwnd(const aProvider: IRawElementProviderSimple; aHwnd: HWND): Boolean;
var
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lNativeWindowHandle: Integer;
  lValue: OleVariant;
begin
  Result := False;
  if (aProvider = nil) or (aHwnd = 0) then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) then
  begin
    if not lDirectAccess.TryGetIntegerProperty(UIA_NativeWindowHandlePropertyId, lNativeWindowHandle) then
    begin
      Exit(False);
    end;

    Exit(HWND(lNativeWindowHandle) = aHwnd);
  end;

  if aProvider.GetPropertyValue(UIA_NativeWindowHandlePropertyId, lValue) <> S_OK then
  begin
    Exit;
  end;

  if VarIsEmpty(lValue) or VarIsNull(lValue) then
  begin
    Exit;
  end;

  Result := HWND(NativeInt(lValue)) = aHwnd;
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
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lPattern: IUnknown;
  lValue: WideString;
  lValueProvider: IValueProvider;
begin
  Result := '';
  if aProvider = nil then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) then
  begin
    if lDirectAccess.TryGetValueText(Result) then
    begin
      Exit;
    end;

    if not lDirectAccess.SupportsPatternDirect(UIA_ValuePatternId) then
    begin
      Exit;
    end;
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

function ProviderFocusAnnouncementText(const aProvider: IRawElementProviderSimple): string;
var
  lDetailProbeCount: Integer;
  lHelpText: string;
  lMetricsEnabled: Boolean;
  lName: string;
  lSpeechAccess: IAccessibilityProviderSpeechAccess;
  lStopwatch: TStopwatch;
  lValueText: string;
begin
  lDetailProbeCount := 0;
  lMetricsEnabled := TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;
  try
    lName := '';
    lValueText := '';
    lHelpText := '';
    if Supports(aProvider, IAccessibilityProviderSpeechAccess, lSpeechAccess) and
      lSpeechAccess.TryGetSpeechProperties(lName, lValueText, lHelpText) then
    begin
      Inc(lDetailProbeCount);
    end else begin
      lName := ProviderName(aProvider);
      Inc(lDetailProbeCount);
      lValueText := ProviderValueText(aProvider);
      Inc(lDetailProbeCount);
      lHelpText := ProviderHelpText(aProvider);
      Inc(lDetailProbeCount);
    end;
    lHelpText := TAccessibilityText.RemoveLeadingDuplicate(lHelpText, lValueText);

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
  finally
    if lMetricsEnabled then
    begin
      TAccessibilityDiagnostics.RecordProviderFocusAnnouncementText(lDetailProbeCount, lStopwatch.ElapsedTicks);
    end;
  end;
end;

function ProviderHoverAnnouncementText(const aProvider: IRawElementProviderSimple): string;
begin
  Result := ProviderFocusAnnouncementText(aProvider);
end;

function ProviderUsesPlatformStateEvents(const aProvider: IRawElementProviderSimple): Boolean; forward;
function ProviderNeedsSupplementalRadioAnnouncements(const aProvider: IRawElementProviderSimple): Boolean; forward;

function ProviderHoverResolutionText(const aProvider: IRawElementProviderSimple): string;
begin
  if ProviderUsesPlatformStateEvents(aProvider) and not ProviderNeedsSupplementalRadioAnnouncements(aProvider) then
  begin
    Exit(ProviderName(aProvider));
  end;

  Result := ProviderHoverAnnouncementText(aProvider);
end;

function HoverTargetControlFromClientPoint(aControl: TWinControl; const aClientPoint: TPoint): TControl;
begin
  Result := nil;
  if aControl = nil then
  begin
    Exit;
  end;

  if not PtInRect(aControl.ClientRect, aClientPoint) then
  begin
    Exit;
  end;

  Result := aControl.ControlAtPos(aClientPoint, True, True, True);
  if Result = nil then
  begin
    Result := aControl;
  end;
end;

function ExcludeHoverChildBounds(const aChildBounds: TRect; const aClientPoint: TPoint;
  var aRegion: TRect): Boolean;
begin
  if PtInRect(aChildBounds, aClientPoint) then
  begin
    Exit(False);
  end;

  if aClientPoint.X < aChildBounds.Left then
  begin
    if aChildBounds.Left < aRegion.Right then
    begin
      aRegion.Right := aChildBounds.Left;
    end;
  end else if aClientPoint.X >= aChildBounds.Right then
  begin
    if aChildBounds.Right > aRegion.Left then
    begin
      aRegion.Left := aChildBounds.Right;
    end;
  end else if aClientPoint.Y < aChildBounds.Top then
  begin
    if aChildBounds.Top < aRegion.Bottom then
    begin
      aRegion.Bottom := aChildBounds.Top;
    end;
  end else if aClientPoint.Y >= aChildBounds.Bottom then
  begin
    if aChildBounds.Bottom > aRegion.Top then
    begin
      aRegion.Top := aChildBounds.Bottom;
    end;
  end else begin
    Exit(False);
  end;

  Result := True;
end;

function TryGetVclHoverMissBounds(aTargetControl: TControl; const aProvider: IRawElementProviderSimple;
  const aClientPoint: TPoint; out aBounds: TRect; out aChildren: TArray<THoverChildGeometry>): Boolean;
var
  i: Integer;
  lChild: TControl;
  lPartition: IAccessibilityVclHoverGeometryPartition;
  lWinControl: TWinControl;
begin
  aBounds := TRect.Empty;
  aChildren := nil;
  Result := False;
  if (aTargetControl = nil) or
    not ((aTargetControl is TCustomForm) or (aTargetControl is TCustomPanel) or
    (aTargetControl is TCustomGroupBox)) or
    not Supports(aProvider, IAccessibilityVclHoverGeometryPartition, lPartition) or
    not lPartition.VclGeometryPartitionsHoverTargets then
  begin
    Exit;
  end;

  lWinControl := aTargetControl as TWinControl;
  aBounds := lWinControl.ClientRect;
  if not PtInRect(aBounds, aClientPoint) then
  begin
    Exit;
  end;

  if lWinControl.ControlCount > cMaxHoverMissChildCount then
  begin
    Exit;
  end;

  SetLength(aChildren, lWinControl.ControlCount);
  for i := 0 to Pred(lWinControl.ControlCount) do
  begin
    lChild := lWinControl.Controls[i];
    aChildren[i].Bounds := lChild.BoundsRect;
    aChildren[i].Control := lChild;
    aChildren[i].Visible := lChild.Visible;
    if not lChild.Visible then
    begin
      Continue;
    end;

    if not ExcludeHoverChildBounds(lChild.BoundsRect, aClientPoint, aBounds) then
    begin
      aChildren := nil;
      Exit;
    end;
  end;

  Result := not aBounds.IsEmpty and PtInRect(aBounds, aClientPoint);
  if not Result then
  begin
    aChildren := nil;
  end;
end;

function ProviderIsFragmentRoot(const aProvider: IRawElementProviderSimple): Boolean;
var
  lRoot: IRawElementProviderFragmentRoot;
begin
  Result := Supports(aProvider, IRawElementProviderFragmentRoot, lRoot);
end;

function TryResolveHoverProviderFromVclLookup(aTargetControl: TControl;
  const aProvider: IRawElementProviderSimple; out aHitProvider: IRawElementProviderSimple; out aAnnouncementText: string;
  out aHasLeafBounds: Boolean; out aLeafBounds: UiaRect): Boolean;
var
  lHitProvider: IRawElementProviderSimple;
  lInfo: IAccessibilityVclControlProviderInfo;
  lLeafControl: TControl;
  lLookup: IAccessibilityVclProviderLookup;
begin
  aHitProvider := nil;
  aAnnouncementText := '';
  aHasLeafBounds := False;
  aLeafBounds := Default(UiaRect);
  Result := False;
  if not Supports(aProvider, IAccessibilityVclProviderLookup, lLookup) then
  begin
    Exit;
  end;

  if (aTargetControl = nil) or (aTargetControl is TPageControl) or (aTargetControl is TTabSheet) then
  begin
    Exit;
  end;

  lHitProvider := nil;
  if not lLookup.TryFindProviderForControl(aTargetControl, lHitProvider) or (lHitProvider = nil) or
    ProvidersAreSame(aProvider, lHitProvider) or ProviderIsGrid(lHitProvider) or
    ProviderIsFragmentRoot(lHitProvider) or ProviderSupportsPattern(lHitProvider, UIA_GridItemPatternId) then
  begin
    Exit;
  end;

  aAnnouncementText := ProviderHoverResolutionText(lHitProvider);
  if aAnnouncementText = '' then
  begin
    Exit;
  end;

  aHitProvider := lHitProvider;
  lLeafControl := aTargetControl;
  if Supports(lHitProvider, IAccessibilityVclControlProviderInfo, lInfo) and (lInfo.Control <> nil) then
  begin
    lLeafControl := lInfo.Control;
  end;

  aHasLeafBounds := TryGetVclLeafControlBounds(lLeafControl, aLeafBounds);
  Result := True;
end;

procedure RaiseProviderAnnouncement(const aProvider: IRawElementProviderSimple; const aActivityId: string;
  const aApi: IAccessibilityUiaApi);
var
  lAnnouncementText: string;
begin
  if not TAccessibilityProviderEvents.ClientsAreListening(aApi) then
  begin
    Exit;
  end;

  lAnnouncementText := ProviderFocusAnnouncementText(aProvider);
  if lAnnouncementText = '' then
  begin
    Exit;
  end;

  TAccessibilityProviderEvents.RaiseNotification(aProvider, NotificationKind_Other,
    NotificationProcessing_MostRecent, lAnnouncementText, aActivityId, aApi);
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

function ProviderWrapsGroupBoxRadioButton(const aProvider: IRawElementProviderSimple): Boolean;
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
  Result := (lControl is TRadioButton) and (lControl.Parent is TCustomGroupBox);
end;

function ProviderNeedsSupplementalRadioAnnouncements(const aProvider: IRawElementProviderSimple): Boolean;
begin
  Result := ProviderWrapsRadioGroupButton(aProvider) or ProviderWrapsGroupBoxRadioButton(aProvider);
end;

function TryFindProviderForControl(const aProvider: IRawElementProviderSimple; aControl: TControl;
  out aControlProvider: IRawElementProviderSimple): Boolean;
var
  lChild: IRawElementProviderFragment;
  lDirectChildCount: Integer;
  lChildProvider: IRawElementProviderSimple;
  lFragment: IRawElementProviderFragment;
  lInfo: IAccessibilityVclControlProviderInfo;
  lLookup: IAccessibilityVclProviderLookup;
  lNextChild: IRawElementProviderFragment;
  i: Integer;
begin
  aControlProvider := nil;
  Result := False;
  if (aProvider = nil) or (aControl = nil) then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityVclProviderLookup, lLookup) and
    lLookup.TryFindProviderForControl(aControl, aControlProvider) then
  begin
    Exit(True);
  end;

  if ProviderIsGrid(aProvider) then
  begin
    Exit;
  end;

  if Supports(aProvider, IAccessibilityVclControlProviderInfo, lInfo) and (lInfo.Control = aControl) then
  begin
    aControlProvider := aProvider;
    Exit(True);
  end;

  if TryProviderDirectChildCount(aProvider, lDirectChildCount) then
  begin
    for i := 0 to Pred(lDirectChildCount) do
    begin
      if TryProviderDirectChildAt(aProvider, i, lChildProvider) and
        TryFindProviderForControl(lChildProvider, aControl, aControlProvider) then
      begin
        Exit(True);
      end;
    end;
    Exit;
  end;

  if not Supports(aProvider, IRawElementProviderFragment, lFragment) then
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
    if Supports(lChild, IRawElementProviderSimple, lChildProvider) and
      TryFindProviderForControl(lChildProvider, aControl, aControlProvider) then
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

function TryCaptureProviderState(const aProvider: IRawElementProviderSimple; out aState: TProviderStateSnapshot):
  Boolean;
var
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lCanProbeSelectionItem: Boolean;
  lCanProbeToggle: Boolean;
  lIsSelected: BOOL;
  lPattern: IUnknown;
  lPropertyValue: Integer;
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

  lCanProbeSelectionItem := True;
  lCanProbeToggle := True;
  if Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) then
  begin
    if lDirectAccess.TryGetIntegerProperty(UIA_ToggleToggleStatePropertyId, lPropertyValue) then
    begin
      aState.Kind := pskToggle;
      aState.ToggleState := lPropertyValue; //PALOFF WARN52 Variant-to-enum UIA value
      Exit(True);
    end;

    if lDirectAccess.TryGetIntegerProperty(UIA_SelectionItemIsSelectedPropertyId, lPropertyValue) then
    begin
      aState.Kind := pskSelectionItem;
      aState.IsSelected := lPropertyValue <> 0;
      Exit(True);
    end;

    lCanProbeToggle := lDirectAccess.SupportsPatternDirect(UIA_TogglePatternId);
    lCanProbeSelectionItem := lDirectAccess.SupportsPatternDirect(UIA_SelectionItemPatternId);
    if not lCanProbeToggle and not lCanProbeSelectionItem then
    begin
      Exit(False);
    end;
  end;

  lPattern := nil;
  if lCanProbeToggle and (aProvider.GetPatternProvider(UIA_TogglePatternId, lPattern) = S_OK) and
    Supports(lPattern, IToggleProvider, lToggle) and (lToggle.Get_ToggleState(lToggleState) = S_OK) then
  begin
    aState.Kind := pskToggle;
    aState.ToggleState := lToggleState;
    Exit(True);
  end;

  lPattern := nil;
  if lCanProbeSelectionItem and (aProvider.GetPatternProvider(UIA_SelectionItemPatternId, lPattern) = S_OK) and
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

function RadioNavigationMessageMayChangeSelection(aControl: TWinControl; const aMessage: TMessage): Boolean;
begin
  Result := False;
  if not ((aControl is TRadioButton) and ((TRadioButton(aControl).Parent is TRadioGroup) or
    (TRadioButton(aControl).Parent is TCustomGroupBox)) and (aMessage.Msg = WM_KEYDOWN)) then
  begin
    Exit;
  end;

  case aMessage.WParam of
    VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN:
      Result := True;
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
  TAccessibilityProviderEvents.BeginEventBatch;
  try
    case aNewState.Kind of //PALOFF WARN57 pskNone has no state-change event
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
          TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider,
            UIA_SelectionItemIsSelectedPropertyId, aOldState.IsSelected, aNewState.IsSelected, aApi);
          if aNewState.IsSelected then
          begin
            TAccessibilityProviderEvents.RaiseAutomationEvent(aProvider, UIA_SelectionItem_ElementSelectedEventId,
              aApi);
          end;
        end;
    end;
  finally
    TAccessibilityProviderEvents.EndEventBatch;
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
  TAccessibilityProviderEvents.BeginEventBatch;
  try
    if ProviderUsesPlatformStateEvents(aProvider) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationEvent(aProvider, UIA_AutomationFocusChangedEventId, aApi);
      lHwnd := ProviderNativeWindowHandle(aProvider);
      if lHwnd <> 0 then
      begin
        NotifyAccessibilityWinEvent(EVENT_OBJECT_FOCUS, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
        NotifyAccessibilityWinEvent(EVENT_OBJECT_STATECHANGE, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
        if not ProviderNeedsSupplementalRadioAnnouncements(aProvider) then
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
  finally
    TAccessibilityProviderEvents.EndEventBatch;
  end;
end;

procedure CaptureHoverMiss(aControl: TWinControl; aTargetControl: TControl;
  const aProvider: IRawElementProviderSimple; const aClientPoint: TPoint; var aResolution: THoverResolution);
begin
  if aTargetControl = aControl then
  begin
    aResolution.HasMissBounds := TryGetVclHoverMissBounds(aTargetControl, aProvider, aClientPoint,
      aResolution.MissBounds, aResolution.MissChildren);
  end;
end;

function TryResolveHoverProvider(aControl: TWinControl; const aProvider: IRawElementProviderSimple;
  const aPoints: THoverPoints; out aResolution: THoverResolution): Boolean;
var
  lHit: IRawElementProviderFragment;
  lRoot: IRawElementProviderFragmentRoot;
  lTargetControl: TControl;
begin
  Result := False;
  if (aControl = nil) or (aProvider = nil) or ProviderIsGrid(aProvider) then
  begin
    Exit;
  end;

  lTargetControl := HoverTargetControlFromClientPoint(aControl, aPoints.Client);
  if TryResolveHoverProviderFromVclLookup(lTargetControl, aProvider, aResolution.HitProvider,
    aResolution.Announcement, aResolution.HasLeafBounds, aResolution.LeafBounds) then
  begin
    Exit(True);
  end;

  if not Supports(aProvider, IRawElementProviderFragmentRoot, lRoot) then
  begin
    aResolution.Announcement := ProviderHoverResolutionText(aProvider);
    if aResolution.Announcement <> '' then
    begin
      aResolution.HitProvider := aProvider;
      aResolution.HasLeafBounds := TryGetVclLeafProviderBounds(aProvider, aResolution.LeafBounds);
      Exit(True);
    end;

    CaptureHoverMiss(aControl, lTargetControl, aProvider, aPoints.Client, aResolution);
    Exit;
  end;

  lHit := nil;
  if (lRoot.ElementProviderFromPoint(aPoints.Screen.X, aPoints.Screen.Y, lHit) <> S_OK) or (lHit = nil) or
    not Supports(lHit, IRawElementProviderSimple, aResolution.HitProvider) then
  begin
    CaptureHoverMiss(aControl, lTargetControl, aProvider, aPoints.Client, aResolution);
    Exit;
  end;

  if ProvidersAreSame(aProvider, aResolution.HitProvider) or ProviderIsGrid(aResolution.HitProvider) or
    ProviderSupportsPattern(aResolution.HitProvider, UIA_GridItemPatternId) then
  begin
    aResolution.HitProvider := nil;
    CaptureHoverMiss(aControl, lTargetControl, aProvider, aPoints.Client, aResolution);
    Exit;
  end;

  aResolution.Announcement := ProviderHoverResolutionText(aResolution.HitProvider);
  Result := aResolution.Announcement <> '';
  if Result then
  begin
    aResolution.HasLeafBounds := TryGetVclLeafProviderBounds(aResolution.HitProvider, aResolution.LeafBounds);
  end else begin
    CaptureHoverMiss(aControl, lTargetControl, aProvider, aPoints.Client, aResolution);
  end;
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

function ListBoxMessageMayChangeSelection(const aMessage: TMessage): Boolean;
begin
  case aMessage.Msg of
    WM_KEYDOWN, WM_CHAR, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK, CM_CHANGED, CN_COMMAND,
    LB_ADDSTRING, LB_INSERTSTRING, LB_DELETESTRING, LB_SELITEMRANGEEX, LB_RESETCONTENT, LB_SETSEL,
    LB_SETCURSEL, LB_SELITEMRANGE, LB_SETCOUNT:
      Result := True;
  else
    Result := False;
  end;
end;

function ListBoxCurrentItemText(aListBox: TCustomListBox): string;
var
  lItemIndex: Integer;
begin
  Result := '';
  if aListBox = nil then
  begin
    Exit;
  end;

  lItemIndex := aListBox.ItemIndex;
  if (lItemIndex < 0) or (lItemIndex >= aListBox.Items.Count) then
  begin
    Exit;
  end;

  Result := TAccessibilityText.Clean(aListBox.Items[lItemIndex]);
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
  lEffectiveRegistry: IAccessibilityAdapterRegistry;
  lProvider: IAccessibilityProviderNode;
begin
  if fHook <> nil then
  begin
    Exit;
  end;

  fRegistry := aRegistry;
  lEffectiveRegistry := aRegistry;
  if lEffectiveRegistry = nil then
  begin
    lEffectiveRegistry := TAccessibilityVclAdapters.CreateDefaultRegistry;
  end;
  lProvider := TAccessibilityVclProviderBuilder.BuildForm(aForm, lEffectiveRegistry, aApi);
  fHook := TAccessibilityFormWindowHook.Create(aForm, lProvider, lEffectiveRegistry, aApi);
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
  const aRegistry: IAccessibilityAdapterRegistry; const aApi: IAccessibilityUiaApi);
begin
  inherited Create(nil);
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  fApi := aApi;
  fChildHooks := TList<TAccessibilityControlWindowHook>.Create;
  fChildHooksByControl := TDictionary<TWinControl, TAccessibilityControlWindowHook>.Create;
  fForm := aForm;
  fProvider := aProvider;
  fRuntimeProperties := TDictionary<TObject, TRuntimeProviderSnapshot>.Create;
  fObservedScan := TAccessibilityScanner.ObserveForm(aForm, aRegistry);
  fObservedRevision := fObservedScan.Revision;
  fOriginalWindowProc := aForm.WindowProc;
  HookChildProviderWindows;
  RefreshRuntimeProperties(False);
  fForm.FreeNotification(Self);
  fForm.WindowProc := WindowProc;
  if TAccessibilityDiagnostics.Enabled then
  begin
    TAccessibilityDiagnostics.Log(Format('Installed form hook form=%s hwnd=%d childHooks=%d',
      [ControlDescription(aForm), aForm.Handle, fChildHooks.Count]));
  end;
end;

destructor TAccessibilityFormWindowHook.Destroy;
begin
  if not fPassive then
  begin
    Detach;
  end;

  fObservedScan := nil;
  DisconnectProvider;
  ReleaseChildHooks;
  fRuntimeProperties.Free;
  fChildHooksByControl.Free;
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

    fObservedScan := nil;
    fForm.RemoveFreeNotification(Self);
    fForm := nil;
  end;
end;

procedure TAccessibilityFormWindowHook.DisconnectProvider;
begin
  fMsaaAccessible := nil;
  fHoverCache.Clear;
  if fProvider <> nil then
  begin
    fProvider.Disconnect;
    fProvider := nil;
  end;
end;

function TAccessibilityFormWindowHook.ControlIsHooked(aControl: TWinControl): Boolean;
var
  lHook: TAccessibilityControlWindowHook;
  lProbeCount: Integer;
begin
  Result := False;
  lProbeCount := 0;
  if aControl = nil then
  begin
    Exit;
  end;

  try
    Inc(lProbeCount);
    lHook := nil;
    Result := fChildHooksByControl.TryGetValue(aControl, lHook) and (lHook <> nil) and (lHook.fControl = aControl);
    if (not Result) and (lHook <> nil) then
    begin
      fChildHooksByControl.Remove(aControl);
    end;
  finally
    TAccessibilityDiagnostics.RecordManagerHookLookup(lProbeCount);
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
var
  lHook: TAccessibilityControlWindowHook;
begin
  if (aControl = nil) or (aControl = fForm) or (fProvider = nil) or ControlIsHooked(aControl) then
  begin
    Exit;
  end;

  lHook := TAccessibilityControlWindowHook.Create(aControl, aProvider, fApi, fProvider.RawElementProvider,
    aPreserveNativeWindowAccessibility);
  fChildHooks.Add(lHook);
  fChildHooksByControl.AddOrSetValue(aControl, lHook);
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
  i: Integer;
  lChild: IRawElementProviderFragment;
  lChildProvider: IRawElementProviderSimple;
  lControl: TControl;
  lDirectChildCount: Integer;
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
        not (lControl is TCustomGroupBox) and (fProvider <> nil) and
        ((lControl is TPageControl) or not TWinControl(lControl).TabStop) then
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

  if TryProviderDirectChildCount(aProvider, lDirectChildCount) then
  begin
    for i := 0 to Pred(lDirectChildCount) do
    begin
      if TryProviderDirectChildAt(aProvider, i, lChildProvider) then
      begin
        HookProviderWindow(lChildProvider);
      end;
    end;
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
  lButtonProvider: IRawElementProviderSimple;
begin
  if (aRadioGroup = nil) or (aProvider = nil) then
  begin
    Exit;
  end;

  for i := 0 to Pred(aRadioGroup.Items.Count) do
  begin
    lButton := aRadioGroup.Buttons[i];
    lButton.HandleNeeded;
    if TryFindProviderForControl(aProvider, lButton, lButtonProvider) then
    begin
      HookControlWindow(lButton, lButtonProvider, False);
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.MaybeRaiseProviderHover(aLParam: LPARAM; aClientsKnown: Boolean;
  aClientsListening: Boolean);
var
  lClientsListening: Boolean;
  lPoints: THoverPoints;
  lResolution: THoverResolution;
begin
  lPoints := MouseHoverPoints(fForm, aLParam);
  if fHoverCache.Matches(fForm, lPoints) then
  begin
    Exit;
  end;

  lClientsListening := aClientsListening;
  if not aClientsKnown then
  begin
    lClientsListening := TAccessibilityProviderEvents.ClientsAreListening(fApi);
  end;
  if not lClientsListening then
  begin
    fHoverCache.Clear;
    Exit;
  end;

  if fProvider = nil then
  begin
    fHoverCache.Clear;
    Exit;
  end;

  if not TryResolveHoverProvider(fForm, fProvider.RawElementProvider, lPoints, lResolution) then
  begin
    fHoverCache.RememberMiss(lResolution);
    Exit;
  end;

  fHoverCache.RememberHitBounds(lResolution);
  if SameText(fHoverCache.Announcement, lResolution.Announcement) then
  begin
    Exit;
  end;

  fHoverCache.Announcement := lResolution.Announcement;
  RaiseProviderHover(lResolution.HitProvider, lResolution.Announcement, fApi);
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
    fObservedScan := nil;
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
    fObservedScan := nil;
    fPassive := True;
    Result := True;
    if gRetainedFormHooks = nil then
    begin
      gRetainedFormHooks := TList<TAccessibilityFormWindowHook>.Create;
    end;

    TAccessibilityDiagnostics.RecordManagerRetainedHookPassivation(0);
    if not fRetained then
    begin
      gRetainedFormHooks.Add(Self);
      fRetained := True;
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
    if lHook.fControl <> nil then
    begin
      fChildHooksByControl.Remove(lHook.fControl);
    end;
    if not lHook.Passivate then
    begin
      lHook.Free;
    end;
  end;
  fChildHooksByControl.Clear;
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
    lHook.fRetained := False;
    lHook.fPassive := False;
    lHook.Detach;
    lHook.Free;
  end;
end;

procedure TAccessibilityFormWindowHook.SynchronizeFormName;
var
  lHwnd: HWND;
  lNewName: string;
  lOldName: string;
  lRawProvider: IRawElementProviderSimple;
begin
  if fPassive or (fForm = nil) or (fProvider = nil) or fProvider.IsDisconnected then
  begin
    Exit;
  end;

  lRawProvider := fProvider.RawElementProvider;
  lOldName := ProviderName(lRawProvider);
  lNewName := TAccessibilityText.Clean(fForm.Caption);
  if lOldName = lNewName then
  begin
    Exit;
  end;

  lHwnd := 0;
  if fForm.HandleAllocated then
  begin
    lHwnd := fForm.Handle;
  end;
  fProvider.SetProperty(UIA_NamePropertyId, lNewName);
  TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(
    lRawProvider, UIA_NamePropertyId,
    lOldName, lNewName, fApi); //PALOFF event delivery is best effort
  if lHwnd <> 0 then
  begin
    NotifyAccessibilityWinEvent(EVENT_OBJECT_NAMECHANGE, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
  end;
end;

function SameUiaRect(const aLeft: UiaRect; const aRight: UiaRect): Boolean;
begin
  Result := (aLeft.Left = aRight.Left) and (aLeft.Top = aRight.Top) and
    (aLeft.Width = aRight.Width) and (aLeft.Height = aRight.Height);
end;

function UiaRectVariant(const aBounds: UiaRect): OleVariant;
begin
  Result := VarArrayCreate([0, 3], varDouble);
  Result[0] := aBounds.Left;
  Result[1] := aBounds.Top;
  Result[2] := aBounds.Width;
  Result[3] := aBounds.Height;
end;

procedure TAccessibilityFormWindowHook.NotifyProviderWinEvent(
  const aProvider: IRawElementProviderSimple; aEvent: DWORD);
var
  lHwnd: HWND;
begin
  lHwnd := ProviderNativeWindowHandle(aProvider);
  if (lHwnd = 0) and (fForm <> nil) and fForm.HandleAllocated then
  begin
    lHwnd := fForm.Handle;
  end;
  if lHwnd <> 0 then
  begin
    NotifyAccessibilityWinEvent(aEvent, lHwnd, cMsaaObjIdClient, CHILDID_SELF);
  end;
end;

procedure TAccessibilityFormWindowHook.ReleaseObsoleteChildHooks;
var
  i: Integer;
  lControl: TWinControl;
  lHook: TAccessibilityControlWindowHook;
  lNode: IAccessibilityProviderNode;
  lParent: TWinControl;
begin
  for i := Pred(fChildHooks.Count) downto 0 do
  begin
    lHook := fChildHooks[i];
    lControl := lHook.fControl;
    lParent := lControl;
    while (lParent <> nil) and (lParent <> fForm) do
    begin
      lParent := lParent.Parent;
    end;
    if (lControl <> nil) and (lParent = fForm) and
      (not Supports(lHook.fProvider, IAccessibilityProviderNode, lNode) or not lNode.IsDisconnected) then
    begin
      Continue;
    end;

    fChildHooks.Delete(i);
    if lControl <> nil then
    begin
      fChildHooksByControl.Remove(lControl);
    end;
    if not lHook.Passivate then
    begin
      lHook.Free;
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.PruneRuntimePropertySnapshots(
  const aTree: IAccessibilityScanTree);
var
  i: Integer;
  lControl: TControl;
  lObject: TObject;
  lStaleObjects: TList<TObject>;
begin
  if aTree = nil then
  begin
    Exit;
  end;

  lStaleObjects := TList<TObject>.Create;
  try
    for lObject in fRuntimeProperties.Keys do
    begin
      if lObject = fForm then
      begin
        Continue;
      end;
      lControl := nil;
      if lObject is TControl then
      begin
        lControl := lObject as TControl;
      end;
      if (lControl = nil) or (aTree.FindNode(lControl) = nil) then
      begin
        lStaleObjects.Add(lObject);
      end;
    end;
    for i := 0 to Pred(lStaleObjects.Count) do
    begin
      fRuntimeProperties.Remove(lStaleObjects[i]);
    end;
  finally
    lStaleObjects.Free;
  end;
end;

procedure TAccessibilityFormWindowHook.ReconcileRuntimeHierarchy;
var
  lRevision: Integer;
  lRuntime: IAccessibilityVclProviderRuntimeInternal;
  lTree: IAccessibilityScanTree;
begin
  if (fObservedScan = nil) or (fProvider = nil) or fProvider.IsDisconnected or
    not Supports(fProvider, IAccessibilityVclProviderRuntimeInternal, lRuntime) then
  begin
    Exit;
  end;

  lRevision := fObservedScan.Revision;
  if lRevision = fObservedRevision then
  begin
    Exit;
  end;

  lTree := fObservedScan.Tree;
  if lRuntime.ReconcileProviderHierarchy(lTree) then
  begin
    PruneRuntimePropertySnapshots(lTree);
    ReleaseObsoleteChildHooks;
    HookChildProviderWindows;
    fHoverCache.Clear;
    TAccessibilityProviderEvents.RaiseStructureChanged(fProvider.RawElementProvider,
      StructureChangeType_ChildrenInvalidated, [], fApi);
    if (fForm <> nil) and fForm.HandleAllocated then
    begin
      NotifyAccessibilityWinEvent(EVENT_OBJECT_REORDER, fForm.Handle, cMsaaObjIdClient, CHILDID_SELF);
    end;
  end;
  fObservedRevision := lRevision;
end;

procedure TAccessibilityFormWindowHook.RefreshRuntimeProperties(aPublishChanges: Boolean);
begin
  if fPassive or (fForm = nil) or (fProvider = nil) or fProvider.IsDisconnected then
  begin
    Exit;
  end;

  ReconcileRuntimeHierarchy;
  if aPublishChanges then
  begin
    TAccessibilityProviderEvents.BeginEventBatch;
  end;
  try
    SynchronizeProviderProperties(fProvider.RawElementProvider, True, aPublishChanges);
  finally
    if aPublishChanges then
    begin
      TAccessibilityProviderEvents.EndEventBatch;
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.SynchronizeProviderProperties(
  const aProvider: IRawElementProviderSimple; aIsRoot: Boolean; aPublishChanges: Boolean);
var
  i: Integer;
  lChild: IRawElementProviderSimple;
  lChildAccess: IAccessibilityProviderChildAccess;
  lChildCount: Integer;
  lControlInfo: IAccessibilityVclControlProviderInfo;
  lDirectAccess: IAccessibilityProviderDirectAccess;
  lGeometryAccess: IAccessibilityProviderGeometryAccess;
  lIntegerValue: Integer;
  lNewSnapshot: TRuntimeProviderSnapshot;
  lNode: IAccessibilityProviderNode;
  lObject: TObject;
  lOldHelpText: string;
  lOldName: string;
  lOldSnapshot: TRuntimeProviderSnapshot;
  lOldValue: string;
begin
  if (aProvider = nil) or not Supports(aProvider, IAccessibilityProviderDirectAccess, lDirectAccess) then
  begin
    Exit;
  end;

  if aIsRoot then
  begin
    lObject := fForm;
  end else if Supports(aProvider, IAccessibilityVclControlProviderInfo, lControlInfo) then
  begin
    lObject := lControlInfo.Control;
  end else begin
    Exit;
  end;
  if lObject = nil then
  begin
    Exit;
  end;
  if Supports(aProvider, IAccessibilityProviderNode, lNode) and lNode.IsDisconnected then
  begin
    fRuntimeProperties.Remove(lObject);
    Exit;
  end;
  lNewSnapshot := Default(TRuntimeProviderSnapshot);
  lNewSnapshot.Provider := aProvider;
  lNewSnapshot.HasBounds := Supports(aProvider, IAccessibilityProviderGeometryAccess, lGeometryAccess) and
    lGeometryAccess.TryGetBoundingRectangle(lNewSnapshot.Bounds);
  lNewSnapshot.HasEnabled := lDirectAccess.TryGetIntegerProperty(UIA_IsEnabledPropertyId,
    lIntegerValue);
  if lNewSnapshot.HasEnabled then
  begin
    lNewSnapshot.Enabled := lIntegerValue <> 0;
  end;
  lNewSnapshot.HasOffscreen := lDirectAccess.TryGetIntegerProperty(UIA_IsOffscreenPropertyId,
    lIntegerValue);
  if lNewSnapshot.HasOffscreen then
  begin
    lNewSnapshot.Offscreen := lIntegerValue <> 0;
  end;
  lNewSnapshot.HasHelpText := lDirectAccess.TryGetStringProperty(UIA_HelpTextPropertyId,
    lNewSnapshot.HelpText);
  lNewSnapshot.HasName := lDirectAccess.TryGetStringProperty(UIA_NamePropertyId, lNewSnapshot.Name);
  lNewSnapshot.HasValue := lDirectAccess.TryGetValueText(lNewSnapshot.Value);
  if fRuntimeProperties.TryGetValue(lObject, lOldSnapshot) and aPublishChanges and
    ProvidersAreSame(lOldSnapshot.Provider, aProvider) then
  begin
    if (lOldSnapshot.HasBounds <> lNewSnapshot.HasBounds) or
      (lNewSnapshot.HasBounds and not SameUiaRect(lOldSnapshot.Bounds, lNewSnapshot.Bounds)) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider,
        UIA_BoundingRectanglePropertyId, UiaRectVariant(lOldSnapshot.Bounds),
        UiaRectVariant(lNewSnapshot.Bounds), fApi);
      NotifyProviderWinEvent(aProvider, EVENT_OBJECT_LOCATIONCHANGE);
    end;

    if (lOldSnapshot.HasEnabled <> lNewSnapshot.HasEnabled) or
      (lNewSnapshot.HasEnabled and (lOldSnapshot.Enabled <> lNewSnapshot.Enabled)) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider, UIA_IsEnabledPropertyId,
        lOldSnapshot.Enabled, lNewSnapshot.Enabled, fApi);
      NotifyProviderWinEvent(aProvider, EVENT_OBJECT_STATECHANGE);
    end;

    if (lOldSnapshot.HasOffscreen <> lNewSnapshot.HasOffscreen) or
      (lNewSnapshot.HasOffscreen and (lOldSnapshot.Offscreen <> lNewSnapshot.Offscreen)) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider, UIA_IsOffscreenPropertyId,
        lOldSnapshot.Offscreen, lNewSnapshot.Offscreen, fApi);
      NotifyProviderWinEvent(aProvider, EVENT_OBJECT_STATECHANGE);
    end;

    if not aIsRoot and ((lOldSnapshot.HasName <> lNewSnapshot.HasName) or
      (lNewSnapshot.HasName and (lOldSnapshot.Name <> lNewSnapshot.Name))) then
    begin
      lOldName := '';
      if lOldSnapshot.HasName then
      begin
        lOldName := lOldSnapshot.Name;
      end;
      TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider, UIA_NamePropertyId,
        lOldName, lNewSnapshot.Name, fApi);
      NotifyProviderWinEvent(aProvider, EVENT_OBJECT_NAMECHANGE);
    end;

    if (lOldSnapshot.HasHelpText <> lNewSnapshot.HasHelpText) or
      (lNewSnapshot.HasHelpText and (lOldSnapshot.HelpText <> lNewSnapshot.HelpText)) then
    begin
      lOldHelpText := '';
      if lOldSnapshot.HasHelpText then
      begin
        lOldHelpText := lOldSnapshot.HelpText;
      end;
      TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider, UIA_HelpTextPropertyId,
        lOldHelpText, lNewSnapshot.HelpText, fApi);
      NotifyProviderWinEvent(aProvider, EVENT_OBJECT_DESCRIPTIONCHANGE);
    end;

    if (lOldSnapshot.HasValue <> lNewSnapshot.HasValue) or
      (lNewSnapshot.HasValue and (lOldSnapshot.Value <> lNewSnapshot.Value)) then
    begin
      lOldValue := '';
      if lOldSnapshot.HasValue then
      begin
        lOldValue := lOldSnapshot.Value;
      end;
      TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(aProvider, UIA_ValueValuePropertyId,
        lOldValue, lNewSnapshot.Value, fApi);
      NotifyProviderWinEvent(aProvider, EVENT_OBJECT_VALUECHANGE);
    end;
  end;
  fRuntimeProperties.AddOrSetValue(lObject, lNewSnapshot);

  if not Supports(aProvider, IAccessibilityProviderChildAccess, lChildAccess) or
    (lChildAccess.DirectChildCount(lChildCount) <> S_OK) then
  begin
    Exit;
  end;

  for i := 0 to Pred(lChildCount) do
  begin
    lChild := nil;
    if lChildAccess.DirectChildAt(i, lChild) = S_OK then
    begin
      SynchronizeProviderProperties(lChild, False, aPublishChanges);
    end;
  end;
end;

procedure TAccessibilityFormWindowHook.SynchronizeRuntimeProperties;
begin
  RefreshRuntimeProperties(True);
end;

procedure TAccessibilityFormWindowHook.WindowProc(var aMessage: TMessage);
var
  lClientsAreListening: Boolean;
  lIsMouseMoveMessage: Boolean;
  lMouseParam: LPARAM;
  lResult: Winapi.Windows.LRESULT;
  lSynchronizeName: Boolean;
begin
  lIsMouseMoveMessage := (aMessage.Msg = WM_MOUSEMOVE) or (aMessage.Msg = WM_NCMOUSEMOVE);
  lSynchronizeName := (aMessage.Msg = WM_SETTEXT) or (aMessage.Msg = CM_TEXTCHANGED);
  if HoverMissCacheInvalidatingMessage(aMessage.Msg) then
  begin
    fHoverCache.ClearMiss;
  end;

  if (not fPassive) and (fForm <> nil) and (fProvider <> nil) and (aMessage.Msg = WM_GETOBJECT) then
  begin
    if (aMessage.LParam = LPARAM(UiaRootObjectId)) and
      TAccessibilityProviderWindowMessages.TryHandleGetObject(fForm.Handle, aMessage.WParam, aMessage.LParam,
      fProvider.RawElementProvider, fApi, lResult) then
    begin
      if TAccessibilityDiagnostics.Enabled then
      begin
        TAccessibilityDiagnostics.Log(Format('Form WM_GETOBJECT handled form=%s hwnd=%d lParam=%d',
          [ControlDescription(fForm), fForm.Handle, aMessage.LParam]));
      end;
      aMessage.Result := lResult;
      Exit;
    end;

    if (aMessage.LParam = LPARAM(OBJID_CLIENT)) and
      TAccessibilityMsaaBridge.TryHandleGetObject(aMessage.WParam, aMessage.LParam, fProvider.RawElementProvider,
      fMsaaAccessible, lResult) then
    begin
      if TAccessibilityDiagnostics.Enabled then
      begin
        TAccessibilityDiagnostics.Log(Format('Form MSAA WM_GETOBJECT handled form=%s hwnd=%d lParam=%d',
          [ControlDescription(fForm), fForm.Handle, aMessage.LParam]));
      end;
      aMessage.Result := lResult;
      Exit;
    end;
  end;

  fOriginalWindowProc(aMessage);
  if lSynchronizeName then
  begin
    SynchronizeFormName;
  end;
  if (not fPassive) and (fForm <> nil) and (fProvider <> nil) and lIsMouseMoveMessage then
  begin
    lMouseParam := MouseMoveClientLParam(fForm, aMessage);
    if fHoverCache.Matches(fForm, MouseHoverPoints(fForm, lMouseParam)) then
    begin
      Exit;
    end;

    lClientsAreListening := TAccessibilityProviderEvents.ClientsAreListening(fApi);
    if not lClientsAreListening then
    begin
      fHoverCache.Clear;
      Exit;
    end;

    TAccessibilityProviderEvents.BeginEventBatchWithKnownClientState(lClientsAreListening);
    try
      MaybeRaiseProviderHover(lMouseParam, True, lClientsAreListening);
    finally
      TAccessibilityProviderEvents.EndEventBatch;
    end;
  end;
end;

constructor TAccessibilityControlWindowHook.Create(aControl: TWinControl;
  const aProvider: IRawElementProviderSimple; const aApi: IAccessibilityUiaApi;
  const aRootProvider: IRawElementProviderSimple;
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
  fProviderIsGrid := ProviderIsGrid(fProvider);
  fRootProvider := aRootProvider;
  fPreserveNativeWindowAccessibility := aPreserveNativeWindowAccessibility;
  fOriginalWindowProc := aControl.WindowProc;
  InitializeGridCellTracking;
  InitializeListBoxItemTracking;
  if (fControl is TCustomListBox) and fControl.HandleAllocated then
  begin
    ProviderPublishesControlNativeWindowHandle;
  end;
  fControl.FreeNotification(Self);
  fControl.WindowProc := WindowProc;
  if Supports(fProvider, IAccessibilityListBoxSelectionTracker, fListBoxSelectionTracker) then
  begin
    fListBoxSelectionTracker.StartSelectionTracking;
  end;
  if TAccessibilityDiagnostics.Enabled then
  begin
    TAccessibilityDiagnostics.Log(Format('Installed child hook control=%s hwnd=%d',
      [ControlDescription(aControl), aControl.Handle]));
  end;
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
  fMsaaAccessible := nil;
  fHoverCache.Clear;
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
  if fControl is TCustomListBox then
  begin
    TAccessibilityDiagnostics.RecordListBoxGridFocusProbe;
  end;

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
  fHasLastGridCell := fProviderIsGrid and TryGetGridCell(fControl, fProvider, fLastGridCol, fLastGridRow);
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

  TAccessibilityDiagnostics.RecordListBoxItemIndexProbe;
  lItemIndex := TCustomListBox(fControl).ItemIndex;
  if fHasLastListBoxIndex and (fLastListBoxIndex = lItemIndex) then
  begin
    Exit;
  end;

  fLastListBoxIndex := lItemIndex;
  fHasLastListBoxIndex := True;
  Result := lItemIndex >= 0;
end;

function TAccessibilityControlWindowHook.NativeListBoxShouldHandleGetObject(const aMessage: TMessage): Boolean;
begin
  Result := (not fPassive) and (fControl is TCustomListBox) and (fProvider <> nil) and
    (aMessage.Msg = WM_GETOBJECT) and not ProviderPublishesControlNativeWindowHandle;
end;

function TAccessibilityControlWindowHook.NativeListBoxShouldHandleNavigationMessage(
  const aMessage: TMessage): Boolean;
begin
  Result := (not fPassive) and (fControl is TCustomListBox) and (fProvider <> nil) and
    (aMessage.Msg = WM_KEYDOWN) and IsListBoxNavigationKey(aMessage.WParam) and
    not ProviderPublishesControlNativeWindowHandle;
end;

function TAccessibilityControlWindowHook.NativeFocusUsesOnlyNativeStateEvents: Boolean;
begin
  Result := fPreserveNativeWindowAccessibility and (fProvider <> nil) and ProviderUsesPlatformStateEvents(fProvider) and
    not ProviderNeedsSupplementalRadioAnnouncements(fProvider);
end;

procedure TAccessibilityControlWindowHook.NotifyListBoxSelectionMayHaveChanged;
begin
  if fListBoxSelectionTracker <> nil then
  begin
    fListBoxSelectionTracker.SelectionMayHaveChanged;
  end;
end;

function TAccessibilityControlWindowHook.ProviderPublishesControlNativeWindowHandle: Boolean;
var
  lHwnd: HWND;
begin
  Result := False;
  if (fControl = nil) or (fProvider = nil) then
  begin
    Exit;
  end;

  lHwnd := fControl.Handle;
  if fProviderNativeWindowHandleCheckValid and (fProviderNativeWindowHandleCheckHwnd = lHwnd) then
  begin
    Exit(fProviderPublishesNativeWindowHandle);
  end;

  if fControl is TCustomListBox then
  begin
    TAccessibilityDiagnostics.RecordListBoxNativeHandlePublicationCheck;
  end;
  fProviderPublishesNativeWindowHandle := ProviderPublishesNativeWindowHandleForHwnd(fProvider, lHwnd);
  fProviderNativeWindowHandleCheckHwnd := lHwnd;
  fProviderNativeWindowHandleCheckValid := True;
  Result := fProviderPublishesNativeWindowHandle;
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

procedure TAccessibilityControlWindowHook.MaybeRaiseProviderHover(aLParam: LPARAM; aClientsKnown: Boolean;
  aClientsListening: Boolean);
var
  lClientsKnown: Boolean;
  lClientsListening: Boolean;
  lPoints: THoverPoints;
  lResolution: THoverResolution;
begin
  lPoints := MouseHoverPoints(fControl, aLParam);
  if fHoverCache.Matches(fControl, lPoints) then
  begin
    Exit;
  end;

  lClientsKnown := aClientsKnown;
  lClientsListening := aClientsListening;
  if not lClientsKnown and not fPreserveNativeWindowAccessibility then
  begin
    lClientsKnown := True;
    lClientsListening := TAccessibilityProviderEvents.ClientsAreListening(fApi);
  end;
  if (not fPreserveNativeWindowAccessibility) and not lClientsListening then
  begin
    fHoverCache.Clear;
    Exit;
  end;

  if not TryResolveHoverProvider(fControl, fProvider, lPoints, lResolution) then
  begin
    fHoverCache.RememberMiss(lResolution);
    Exit;
  end;

  fHoverCache.RememberHitBounds(lResolution);
  if SameText(fHoverCache.Announcement, lResolution.Announcement) then
  begin
    Exit;
  end;

  fHoverCache.Announcement := lResolution.Announcement;
  RaiseResolvedProviderHover(lResolution, lClientsKnown, lClientsListening);
end;

procedure TAccessibilityControlWindowHook.RaiseResolvedProviderHover(const aResolution: THoverResolution;
  aClientsKnown: Boolean; aClientsListening: Boolean);
var
  lClientsListening: Boolean;
begin
  lClientsListening := aClientsListening;
  if fPreserveNativeWindowAccessibility then
  begin
    if not aClientsKnown then
    begin
      lClientsListening := TAccessibilityProviderEvents.ClientsAreListening(fApi);
    end;

    if lClientsListening and ProviderUsesPlatformStateEvents(aResolution.HitProvider) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationEvent(aResolution.HitProvider, UIA_AutomationFocusChangedEventId,
        fApi);
    end;
    NotifyProviderNativeFocusAndState(aResolution.HitProvider, fControl.Handle);
    if lClientsListening and ProviderNeedsSupplementalRadioAnnouncements(aResolution.HitProvider) then
    begin
      RaiseProviderAnnouncement(aResolution.HitProvider, 'vcl-hover', fApi);
    end;
  end else begin
    RaiseProviderHover(aResolution.HitProvider, aResolution.Announcement, fApi);
  end;
end;

procedure TAccessibilityControlWindowHook.MaybeRaiseRadioNavigationChanged(aPreviousRadio: TRadioButton);
var
  lSelectedRadio: TRadioButton;
begin
  if not TryCurrentSelectedGroupedRadio(lSelectedRadio) or (lSelectedRadio = aPreviousRadio) then
  begin
    Exit;
  end;

  RaiseRadioNavigationChanged(lSelectedRadio);
end;

procedure TAccessibilityControlWindowHook.RaiseRadioNavigationChanged(aSelectedRadio: TRadioButton);
var
  lProvider: IRawElementProviderSimple;
begin
  if (aSelectedRadio = nil) or (fRootProvider = nil) or
    not TryFindProviderForControl(fRootProvider, aSelectedRadio, lProvider) or
    not ProviderNeedsSupplementalRadioAnnouncements(lProvider) then
  begin
    Exit;
  end;

  TAccessibilityProviderEvents.BeginEventBatch;
  try
    TAccessibilityProviderEvents.RaiseAutomationPropertyChanged(lProvider, UIA_SelectionItemIsSelectedPropertyId,
      False, True, fApi);
    TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider, UIA_SelectionItem_ElementSelectedEventId, fApi);
    TAccessibilityProviderEvents.RaiseAutomationEvent(lProvider, UIA_AutomationFocusChangedEventId, fApi);
    NotifyAccessibilityWinEvent(EVENT_OBJECT_FOCUS, aSelectedRadio.Handle, cMsaaObjIdClient, CHILDID_SELF);
    NotifyAccessibilityWinEvent(EVENT_OBJECT_STATECHANGE, aSelectedRadio.Handle, cMsaaObjIdClient, CHILDID_SELF);
    RaiseProviderAnnouncement(lProvider, 'vcl-radio-navigation', fApi);
  finally
    TAccessibilityProviderEvents.EndEventBatch;
  end;
end;

function TAccessibilityControlWindowHook.TryCurrentSelectedGroupedRadio(out aRadio: TRadioButton): Boolean;
var
  i: Integer;
  lChild: TControl;
  lParent: TWinControl;
  lRadioGroup: TRadioGroup;
begin
  aRadio := nil;
  Result := False;
  if not (fControl is TRadioButton) then
  begin
    Exit;
  end;

  lParent := TRadioButton(fControl).Parent;
  if lParent is TRadioGroup then
  begin
    lRadioGroup := TRadioGroup(lParent);
    if (lRadioGroup.ItemIndex >= 0) and (lRadioGroup.ItemIndex < lRadioGroup.Items.Count) then
    begin
      aRadio := lRadioGroup.Buttons[lRadioGroup.ItemIndex];
      Result := aRadio <> nil;
    end;
    Exit;
  end;

  if not (lParent is TCustomGroupBox) then
  begin
    Exit;
  end;

  for i := 0 to Pred(lParent.ControlCount) do
  begin
    lChild := lParent.Controls[i];
    if (lChild is TRadioButton) and TRadioButton(lChild).Checked then
    begin
      aRadio := TRadioButton(lChild);
      Exit(True);
    end;
  end;
end;

procedure TAccessibilityControlWindowHook.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent, aOperation);
  if (aOperation = opRemove) and (aComponent = fControl) then
  begin
    fMsaaAccessible := nil;
    fHoverCache.Clear;
    if SameWndMethod(fControl.WindowProc, WindowProc) then
    begin
      fControl.WindowProc := fOriginalWindowProc;
    end;

    fControl := nil;
    fListBoxSelectionTracker := nil;
    fProvider := nil;
    fProviderIsGrid := False;
    fRootProvider := nil;
  end;
end;

function TAccessibilityControlWindowHook.Passivate: Boolean;
begin
  Result := False;
  fMsaaAccessible := nil;
  fHoverCache.Clear;
  fApi := nil;
  fListBoxSelectionTracker := nil;
  fProvider := nil;
  fProviderIsGrid := False;
  fRootProvider := nil;
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

    TAccessibilityDiagnostics.RecordManagerRetainedHookPassivation(0);
    if not fRetained then
    begin
      gRetainedControlHooks.Add(Self);
      fRetained := True;
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

  if ProviderUsesPlatformStateEvents(fProvider) and not ProviderNeedsSupplementalRadioAnnouncements(fProvider) then
  begin
    Exit;
  end;

  if not TAccessibilityProviderEvents.ClientsAreListening(fApi) then
  begin
    Exit;
  end;

  if fLastFocusAnnouncement <> '' then
  begin
    Exit;
  end;

  lAnnouncementText := ProviderFocusAnnouncementText(fProvider);
  if (lAnnouncementText = '') or SameText(fLastFocusAnnouncement, lAnnouncementText) then
  begin
    Exit;
  end;

  fLastFocusAnnouncement := lAnnouncementText;
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
    if ProviderNeedsSupplementalRadioAnnouncements(fProvider) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationEvent(fProvider, UIA_AutomationFocusChangedEventId, fApi);
    end;
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
  lFocusedItems: IAccessibilityFocusedItemProvider;
  lFocus: IRawElementProviderFragment;
  lFocusName: string;
  lFocusProvider: IRawElementProviderSimple;
  lRoot: IRawElementProviderFragmentRoot;
begin
  if (fProvider = nil) or not ProviderIsGrid(fProvider) then
  begin
    Exit;
  end;

  if not TAccessibilityProviderEvents.ClientsAreListening(fApi) then
  begin
    Exit;
  end;

  TAccessibilityProviderEvents.BeginEventBatch;
  try
    if Supports(fProvider, IAccessibilityFocusedItemProvider, lFocusedItems) and
      lFocusedItems.TryGetFocusedItem(lFocusProvider, lFocusName) then
    begin
      TAccessibilityProviderEvents.RaiseAutomationEvent(lFocusProvider, UIA_AutomationFocusChangedEventId, fApi);
      TAccessibilityProviderEvents.RaiseAutomationEvent(lFocusProvider, UIA_SelectionItem_ElementSelectedEventId,
        fApi);
      if lFocusName <> '' then
      begin
        TAccessibilityProviderEvents.RaiseNotification(lFocusProvider, NotificationKind_Other,
          NotificationProcessing_MostRecent, lFocusName, 'vcl-grid-cell-focus', fApi);
      end;
      Exit;
    end;

    if not Supports(fProvider, IRawElementProviderFragmentRoot, lRoot) then
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
  finally
    TAccessibilityProviderEvents.EndEventBatch;
  end;
end;

procedure TAccessibilityControlWindowHook.RaiseListBoxFocusChanged;
var
  lFocusName: string;
  lListBox: TCustomListBox;
  lMetricsEnabled: Boolean;
  lRecordedMovement: Boolean;
  lStopwatch: TStopwatch;
begin
  if (fProvider = nil) or not (fControl is TCustomListBox) then
  begin
    Exit;
  end;

  if not TAccessibilityProviderEvents.ClientsAreListening(fApi) then
  begin
    Exit;
  end;

  lListBox := TCustomListBox(fControl); //PALOFF STWA6 provider contract fixes control type
  if not ProviderPublishesControlNativeWindowHandle then
  begin
    Exit;
  end;

  lMetricsEnabled := TAccessibilityDiagnostics.ListBoxFocusMetricsEnabled;
  lRecordedMovement := False;
  if lMetricsEnabled then
  begin
    lStopwatch := TStopwatch.StartNew;
  end;
  try
    lFocusName := ListBoxCurrentItemText(lListBox);
    if lFocusName = '' then
    begin
      Exit;
    end;

    lRecordedMovement := True;
    if (lFocusName <> '') and TAccessibilityProviderEvents.RaiseNotification(fProvider, NotificationKind_Other,
      NotificationProcessing_ImportantMostRecent, lFocusName, 'vcl-listbox-focus', fApi) then
    begin
      TAccessibilityDiagnostics.RecordListBoxNotification(Length(lFocusName));
    end;
  finally
    if lMetricsEnabled and lRecordedMovement then
    begin
      TAccessibilityDiagnostics.RecordListBoxFocusMovement(lStopwatch.ElapsedTicks);
    end;
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
    lHook.fRetained := False;
    lHook.fPassive := False;
    lHook.Detach;
    lHook.Free;
  end;
end;

procedure TAccessibilityControlWindowHook.WindowProc(var aMessage: TMessage);
var
  lHasOldProviderState: Boolean;
  lHasNonHoverPostMessageWork: Boolean;
  lHasPostMessageWork: Boolean;
  lHoverClientsKnown: Boolean;
  lHoverClientsListening: Boolean;
  lIsBlurMessage: Boolean;
  lIsFocusMessage: Boolean;
  lIsGridNavigationMessage: Boolean;
  lListBoxSelectionMayChange: Boolean;
  lIsListBoxSelectionMessage: Boolean;
  lIsMouseMoveMessage: Boolean;
  lIsOuterProviderStateMessage: Boolean;
  lIsProviderStateMessage: Boolean;
  lIsRadioNavigationMessage: Boolean;
  lIsUiaOnlyPostMessageWork: Boolean;
  lRadioNavigationClientsKnown: Boolean;
  lRadioNavigationClientsListening: Boolean;
  lUiaOnlyClientsKnown: Boolean;
  lUiaOnlyClientsListening: Boolean;
  lMouseParam: LPARAM;
  lNewProviderState: TProviderStateSnapshot;
  lOldProviderState: TProviderStateSnapshot;
  lOldSelectedRadio: TRadioButton;
  lResult: Winapi.Windows.LRESULT;
begin
  if HoverMissCacheInvalidatingMessage(aMessage.Msg) then
  begin
    fHoverCache.ClearMiss;
  end;

  if NativeListBoxShouldHandleGetObject(aMessage) then
  begin
    if TAccessibilityDiagnostics.Enabled then
    begin
      TAccessibilityDiagnostics.Log(Format(
        'Child WM_GETOBJECT passed to native listbox control=%s hwnd=%d; native handle not published',
        [ControlDescription(fControl), fControl.Handle]));
    end;
    fOriginalWindowProc(aMessage);
    Exit;
  end;

  if NativeListBoxShouldHandleNavigationMessage(aMessage) then
  begin
    try
      fOriginalWindowProc(aMessage);
    finally
      NotifyListBoxSelectionMayHaveChanged;
    end;
    Exit;
  end;

  if (not fPreserveNativeWindowAccessibility) and (not fPassive) and (fControl <> nil) and (fProvider <> nil) and
    (aMessage.Msg = WM_GETOBJECT) then
  begin
    if aMessage.LParam = LPARAM(UiaRootObjectId) then
    begin
      if not (fControl is TPageControl) and not ProviderPublishesControlNativeWindowHandle then
      begin
        if TAccessibilityDiagnostics.Enabled then
        begin
          TAccessibilityDiagnostics.Log(Format(
            'Child WM_GETOBJECT skipped framework provider control=%s hwnd=%d; native handle not published',
            [ControlDescription(fControl), fControl.Handle]));
        end;
      end else if TAccessibilityProviderWindowMessages.TryHandleGetObject(fControl.Handle, aMessage.WParam,
        aMessage.LParam, fProvider, fApi, lResult) then
      begin
        if TAccessibilityDiagnostics.Enabled then
        begin
          TAccessibilityDiagnostics.Log(Format('Child WM_GETOBJECT handled control=%s hwnd=%d lParam=%d',
            [ControlDescription(fControl), fControl.Handle, aMessage.LParam]));
        end;
        aMessage.Result := lResult;
        Exit;
      end;
    end;

    if (aMessage.LParam = LPARAM(OBJID_CLIENT)) and
      TAccessibilityMsaaBridge.TryHandleGetObject(aMessage.WParam, aMessage.LParam, fProvider, fMsaaAccessible,
      lResult) then
    begin
      if TAccessibilityDiagnostics.Enabled then
      begin
        TAccessibilityDiagnostics.Log(Format('Child MSAA WM_GETOBJECT handled control=%s hwnd=%d lParam=%d',
          [ControlDescription(fControl), fControl.Handle, aMessage.LParam]));
      end;
      aMessage.Result := lResult;
      Exit;
    end;
  end;

  lIsBlurMessage := aMessage.Msg = CM_EXIT;
  lIsFocusMessage := (aMessage.Msg = CM_ENTER) or (aMessage.Msg = WM_SETFOCUS);
  lIsGridNavigationMessage := fProviderIsGrid and (aMessage.Msg = WM_KEYDOWN) and
    IsGridNavigationKey(aMessage.WParam);
  lListBoxSelectionMayChange := (fControl is TCustomListBox) and
    ListBoxMessageMayChangeSelection(aMessage);
  lIsListBoxSelectionMessage := (fControl is TCustomListBox) and
    (((aMessage.Msg = WM_KEYDOWN) and IsListBoxNavigationKey(aMessage.WParam)) or
    (aMessage.Msg = WM_LBUTTONUP) or (aMessage.Msg = CM_CHANGED));
  if lIsListBoxSelectionMessage then
  begin
    lIsListBoxSelectionMessage := ProviderPublishesControlNativeWindowHandle;
  end;
  lIsRadioNavigationMessage := RadioNavigationMessageMayChangeSelection(fControl, aMessage);
  lRadioNavigationClientsKnown := False;
  lRadioNavigationClientsListening := False;
  lUiaOnlyClientsKnown := False;
  lUiaOnlyClientsListening := False;
  if lIsRadioNavigationMessage and (not fPassive) and (fControl <> nil) and (fProvider <> nil) then
  begin
    lRadioNavigationClientsKnown := True;
    lRadioNavigationClientsListening := TAccessibilityProviderEvents.ClientsAreListening(fApi);
  end;
  lIsMouseMoveMessage := (aMessage.Msg = WM_MOUSEMOVE) or (aMessage.Msg = WM_NCMOUSEMOVE);
  lIsProviderStateMessage := (not fPreserveNativeWindowAccessibility) and (not fProviderIsGrid) and
    ProviderStateMessageMayChangeState(aMessage) and
    ((not (fControl is TCustomListBox)) or ProviderPublishesControlNativeWindowHandle) and
    (not (lIsRadioNavigationMessage and lRadioNavigationClientsKnown and not lRadioNavigationClientsListening));
  lIsOuterProviderStateMessage := lIsProviderStateMessage and (fProviderStateMessageDepth = 0);
  lHasOldProviderState := lIsOuterProviderStateMessage and TryCaptureProviderState(fProvider, lOldProviderState);
  if (not lIsRadioNavigationMessage) or (not lRadioNavigationClientsListening) or
    (not TryCurrentSelectedGroupedRadio(lOldSelectedRadio)) then
  begin
    lOldSelectedRadio := nil;
  end;
  lHasNonHoverPostMessageWork := lIsOuterProviderStateMessage or lIsBlurMessage or lIsFocusMessage or
    lIsGridNavigationMessage or (fProviderIsGrid and (aMessage.Msg = CM_CHANGED)) or lIsListBoxSelectionMessage or
    lIsRadioNavigationMessage;
  lHasPostMessageWork := lHasNonHoverPostMessageWork or lIsMouseMoveMessage;
  lHoverClientsKnown := False;
  lHoverClientsListening := False;
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
    if lListBoxSelectionMayChange then
    begin
      NotifyListBoxSelectionMayHaveChanged;
    end;
  end;
  if lIsBlurMessage or lIsFocusMessage or lIsOuterProviderStateMessage or lIsGridNavigationMessage or
    (fProviderIsGrid and (aMessage.Msg = CM_CHANGED)) or lIsListBoxSelectionMessage or lIsRadioNavigationMessage then
  begin
    fHoverCache.Clear;
  end;
  if (not fPassive) and (fControl <> nil) and (fProvider <> nil) and lHasPostMessageWork then
  begin
    if lIsFocusMessage and NativeFocusUsesOnlyNativeStateEvents then
    begin
      RaiseFocusChanged;
      Exit;
    end;

    if lIsMouseMoveMessage then
    begin
      lMouseParam := MouseMoveClientLParam(fControl, aMessage);
    end else begin
      lMouseParam := 0;
    end;

    if lIsMouseMoveMessage and (not lHasNonHoverPostMessageWork) then
    begin
      if fHoverCache.Matches(fControl, MouseHoverPoints(fControl, lMouseParam)) then
      begin
        Exit;
      end;

      lHoverClientsKnown := True;
      lHoverClientsListening := TAccessibilityProviderEvents.ClientsAreListening(fApi);
      if not lHoverClientsListening then
      begin
        if fPreserveNativeWindowAccessibility then
        begin
          MaybeRaiseProviderHover(lMouseParam, lHoverClientsKnown, lHoverClientsListening);
        end else begin
          fHoverCache.Clear;
        end;
        Exit;
      end;
    end;

    lIsUiaOnlyPostMessageWork := (not lIsOuterProviderStateMessage) and (not lIsBlurMessage) and
      (not lIsFocusMessage) and
      (lIsGridNavigationMessage or (fProviderIsGrid and (aMessage.Msg = CM_CHANGED)) or
      lIsListBoxSelectionMessage or lIsRadioNavigationMessage);
    if lIsUiaOnlyPostMessageWork then
    begin
      if lRadioNavigationClientsKnown then
      begin
        if not lRadioNavigationClientsListening then
        begin
          Exit;
        end;
      end else begin
        lUiaOnlyClientsKnown := True;
        lUiaOnlyClientsListening := TAccessibilityProviderEvents.ClientsAreListening(fApi);
        if not lUiaOnlyClientsListening then
        begin
          Exit;
        end;
      end;
    end;

    if lHoverClientsKnown then
    begin
      TAccessibilityProviderEvents.BeginEventBatchWithKnownClientState(lHoverClientsListening);
    end else if lRadioNavigationClientsKnown then
    begin
      TAccessibilityProviderEvents.BeginEventBatchWithKnownClientState(lRadioNavigationClientsListening);
    end else if lUiaOnlyClientsKnown then
    begin
      TAccessibilityProviderEvents.BeginEventBatchWithKnownClientState(lUiaOnlyClientsListening);
    end else begin
      TAccessibilityProviderEvents.BeginEventBatch;
    end;
    try
      if lIsOuterProviderStateMessage and lHasOldProviderState and
        TryCaptureProviderState(fProvider, lNewProviderState) and
        not ProviderStatesEqual(lOldProviderState, lNewProviderState) and
        (not fHasLastRaisedProviderState or not ProviderStatesEqual(fLastRaisedProviderState, lNewProviderState)) then
      begin
        RaiseProviderStateChanged(fProvider, lOldProviderState, lNewProviderState, fApi);
        fLastRaisedProviderState := lNewProviderState;
        fHasLastRaisedProviderState := True;
      end;

      if lIsMouseMoveMessage then
      begin
        MaybeRaiseProviderHover(lMouseParam, lHoverClientsKnown, lHoverClientsListening);
      end;

      if lIsBlurMessage then
      begin
        fLastFocusAnnouncement := '';
      end;

      if lIsFocusMessage then
      begin
        RaiseFocusChanged;
        NotifyFocusHint;
      end;

      if lIsGridNavigationMessage or (fProviderIsGrid and (aMessage.Msg = CM_CHANGED)) then
      begin
        MaybeRaiseGridFocusChanged;
      end;

      if lIsListBoxSelectionMessage then
      begin
        MaybeRaiseListBoxFocusChanged;
      end;

      if lIsRadioNavigationMessage then
      begin
        MaybeRaiseRadioNavigationChanged(lOldSelectedRadio);
      end;
    finally
      TAccessibilityProviderEvents.EndEventBatch;
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
var
  lActiveForm: TCustomForm;
begin
  if Assigned(fPreviousActiveFormChange) then
  begin
    fPreviousActiveFormChange(aSender);
  end;

  if fAppInstalled then
  begin
    lActiveForm := Screen.ActiveCustomForm;
    if lActiveForm <> nil then
    begin
      InstallFormWithRegistry(lActiveForm, fApplicationRegistry);
    end;
  end;
end;

procedure TAccessibilityManagerState.ApplicationIdle(aSender: TObject; var aDone: Boolean);
var
  i: Integer;
  lMarker: TAccessibilityInstalledFormMarker;
begin
  if fIdleDispatching then
  begin
    Exit;
  end;

  fIdleDispatching := True;
  try
    if Assigned(fPreviousIdle) then
    begin
      fPreviousIdle(aSender, aDone);
    end;

    for i := 0 to Pred(Screen.CustomFormCount) do
    begin
      lMarker := TAccessibilityInstalledFormMarker.FindOn(Screen.CustomForms[i]);
      if (lMarker <> nil) and (lMarker.fHook <> nil) then
      begin
        lMarker.fHook.SynchronizeRuntimeProperties;
      end;
    end;
  finally
    fIdleDispatching := False;
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

procedure TAccessibilityManagerState.HookApplicationIdle;
begin
  if fIdleHookInstalled then
  begin
    if SameIdleEvent(Application.OnIdle, ApplicationIdle) then
    begin
      Exit;
    end;

    fPreviousIdle := nil;
    fIdleHookInstalled := False;
  end;

  fPreviousIdle := Application.OnIdle;
  Application.OnIdle := ApplicationIdle;
  fIdleHookInstalled := True;
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
  HookApplicationIdle;
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

procedure TAccessibilityManagerState.RestoreApplicationIdleHook;
begin
  if not fIdleHookInstalled then
  begin
    Exit;
  end;

  if SameIdleEvent(Application.OnIdle, ApplicationIdle) then
  begin
    Application.OnIdle := fPreviousIdle;
  end;
  fPreviousIdle := nil;
  fIdleHookInstalled := False;
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
  RestoreApplicationIdleHook;
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

class function TAccessibilityManagerInternals.TryGetInstalledFormProvider(aForm: TCustomForm;
  out aProvider: IRawElementProviderSimple): Boolean;
var
  lMarker: TAccessibilityInstalledFormMarker;
begin
  aProvider := nil;
  lMarker := TAccessibilityInstalledFormMarker.FindOn(aForm);
  Result := (lMarker <> nil) and (lMarker.fHook <> nil) and (lMarker.fHook.fProvider <> nil);
  if Result then
  begin
    aProvider := lMarker.fHook.fProvider.RawElementProvider; //PALOFF WARN53 intentional object-to-interface bridge
  end;
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
