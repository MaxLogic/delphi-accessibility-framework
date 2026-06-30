unit MaxLogic.Accessibility.Manager.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('AccessibilityManager')]
  TAccessibilityManagerTests = class
  public
    [Test]
    procedure ApplicationInstallDiscoversFutureFormsAndChainsActiveFormChange;
    [Test]
    procedure ApplicationInstallWithCustomRegistryDiscoversFutureTmsForms;
    [Test]
    procedure ApplicationInstallWithCustomRegistryScansCurrentTmsForms;
    [Test]
    procedure DemoEnableToggleInstallsUninstallsAndSyncsCurrentAndFutureForms;
    [Test]
    procedure ApplicationCustomRegistryRejectsDefaultFormInstall;
    [Test]
    procedure ApplicationRegistrySwitchRequiresUninstall;
    [Test]
    procedure ApplicationCustomRegistryRejectsInstalledDefaultFormWithoutPartialHook;
    [Test]
    procedure DefaultFormInstallLeavesTmsGridOnDefaultRegistry;
    [Test]
    procedure ApplicationInstallScansCurrentFormsAndIsIdempotent;
    [Test]
    procedure RunInstallsCurrentFormsAndUninstallsAfterApplicationRun;
    [Test]
    procedure RunUninstallsPartialApplicationInstallWhenInstallFails;
    [Test]
    procedure UninstallIsIdempotent;
    [Test]
    procedure ApplicationInstallSkipsInternalNoActiveForm;
    [Test]
    procedure FormInstallIsScopedAndIdempotent;
    [Test]
    procedure FormInstallWithCustomRegistryUsesTmsProviderThroughWmGetObject;
    [Test]
    procedure FormRegistrySwitchRequiresUninstall;
    [Test]
    procedure FormCustomRegistryRejectsActiveDefaultApplicationInstall;
    [Test]
    procedure FormInstallHandlesUiaGetObjectThroughDefaultProvider;
    [Test]
    procedure FormInstallHandlesChildUiaGetObjectThroughFrameworkProvider;
    [Test]
    procedure FormInstallHandlesChildContainerHitTestingForNonWindowedLabel;
    [Test]
    procedure FormInstallLeavesCheckBoxAndRadioButtonNativeGetObject;
    [Test]
    procedure FormInstallLeavesUnsupportedFocusableControlNativeGetObject;
    [Test]
    procedure FormInstallHandlesPageControlUiaGetObjectForTabHeaders;
    [Test]
    procedure FormInstallHandlesPageControlMsaaGetObjectForTabHeaders;
    [Test]
    procedure FormInstallObjectFromPointReturnsPageControlTabHeader;
    [Test]
    procedure FormInstallObjectFromPointReturnsActiveTabSheetNestedLabel;
    [Test]
    procedure FormInstallHandlesInputMsaaGetObjectWithLabelAndTextHint;
    [Test]
    procedure FormInstallHandlesStringGridMsaaGetObjectForFocusedCell;
    [Test]
    procedure FormInstallRaisesFocusedControlHintNotificationOnFocus;
    [Test]
    procedure FormInstallRaisesInputFocusEventOnFocus;
    [Test]
    procedure FormInstallRaisesComboBoxFocusEventOnFocus;
    [Test]
    procedure FormInstallRaisesLabeledEditFocusEventOnFocus;
    [Test]
    procedure FormInstallRaisesFocusedEditTextHintNotificationOnFocus;
    [Test]
    procedure FormInstallRaisesInputFocusAnnouncementMatchingMouseOverSurface;
    [Test]
    procedure FormInstallRaisesInputMsaaFocusWinEventWithDefaultApi;
    [Test]
    procedure FormInstallRaisesPageControlTabHoverNotification;
    [Test]
    procedure FormInstallRaisesPageControlTabHoverNotificationFromFormMouseMove;
    [Test]
    procedure FormInstallRaisesActiveTabSheetLabelHoverNotification;
    [Test]
    procedure FormInstallRaisesActiveTabSheetPanelLabelHoverNotification;
    [Test]
    procedure FormInstallRaisesMemoListBoxAndStatusBarHoverNotifications;
    [Test]
    procedure FormInstallRaisesWindowedButtonHoverNotificationAndKeepsCheckBoxNative;
    [Test]
    procedure FormInstallRaisesGroupBoxHoverAndRadioGroupItemHoverProviders;
    [Test]
    procedure FormInstallRaisesGroupBoxHoverFromNonClientMouseMove;
    [Test]
    procedure FormInstallIgnoresFormNonClientHoverWithoutRangeCheck;
    [Test]
    procedure FormInstallRaisesRadioGroupItemHoverFromButtonWindow;
    [Test]
    procedure DemoFormInstallRaisesRadioGroupItemHoverFromButtonWindow;
    [Test]
    procedure FormInstallRaisesLazyRadioGroupItemHoverFromButtonWindow;
    [Test]
    procedure FormInstallRaisesCheckBoxHoverNativeWinEventsWithoutProviderReplacement;
    [Test]
    procedure FormInstallRaisesCheckBoxFocusNativeWinEventsWithoutProviderReplacement;
    [Test]
    procedure FormInstallRaisesRadioButtonHoverAndFocusNativeWinEventsWithoutProviderReplacement;
    [Test]
    procedure FormInstallLeavesCheckBoxToggleToNativeWindow;
    [Test]
    procedure FormInstallLeavesRadioButtonSelectionToNativeWindow;
    [Test]
    procedure FormInstallRaisesToggleSpeedButtonHoverWithoutCheckBoxStateText;
    [Test]
    procedure FormInstallRaisesGridCellFocusEventAfterStringGridCellChangeMessage;
    [Test]
    procedure FormInstallRaisesGridCellFocusEventAfterStringGridArrowKey;
    [Test]
    procedure FormInstallRaisesStringGridRowFocusNotificationForRowSelect;
    [Test]
    procedure FormInstallRaisesListBoxItemFocusEventAfterArrowKey;
    [Test]
    procedure FormInstallDoesNotRaiseGridMsaaFocusWinEventAfterCellNotification;
    [Test]
    procedure FormInstallRaisesGridCellFocusEventAfterAdvStringGridCellChangeMessage;
    [Test]
    procedure FormInstallRaisesGridCellFocusEventAfterAdvStringGridArrowKey;
    [Test]
    procedure LaterWindowProcHookCanCallManagerAfterUninstallWithoutUiaReturn;
    [Test]
    procedure DestroyedFormIsRemovedFromInstallState;
    [Test]
    procedure InstallerFailureDoesNotMarkFormInstalled;
    [Test]
    procedure LaterHookStillCallsOriginalAfterManagerUninstallWithoutScanning;
    [Test]
    procedure UninstallRestoresOriginalActiveFormChangeHandler;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.SysUtils, System.Types, System.Variants, Winapi.ActiveX,
  Winapi.Messages, Winapi.oleacc, Winapi.Windows, Vcl.Buttons, Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  Vcl.Grids, Vcl.StdCtrls, AdvGrid, MaxLogic.Accessibility.Manager, MaxLogic.Accessibility.ProviderCore,
  MaxLogic.Accessibility.Scanner, MaxLogic.Accessibility.TmsAdvStringGridAdapters, MaxLogic.Accessibility.UIAutomationCore,
  AccessibilityDemoMainForm;

type
  IFormInstallRecorder = interface(IAccessibilityFormInstaller)
    ['{89B798B7-0880-4AE5-B799-58E4EB14DF22}']
    function CountFor(aForm: TCustomForm): Integer;
    procedure FailNextInstall;
  end;

  IManagerTestUiaApi = interface(IAccessibilityUiaApi)
    ['{40F38FD9-3290-4894-A855-082E2884C0C1}']
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function LastHwnd: HWND;
    function LastEventId: EVENTID;
    function LastEventProvider: IRawElementProviderSimple;
    function LastLParam: LPARAM;
    function LastNotificationProvider: IRawElementProviderSimple;
    function LastNotificationText: string;
    function LastPropertyChangedNewValue: OleVariant;
    function LastPropertyChangedOldValue: OleVariant;
    function LastPropertyChangedPropertyId: PROPERTYID;
    function LastPropertyChangedProvider: IRawElementProviderSimple;
    function ReturnedProvider: IRawElementProviderSimple;
    function NotificationCalls: Integer;
    function PropertyChangedCalls: Integer;
    function ReturnCalls: Integer;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  TManagerTestUiaApi = class(TInterfacedObject, IManagerTestUiaApi)
  private
    fClientsAreListening: Boolean;
    fDisconnectCalls: Integer;
    fEventCalls: Integer;
    fLastEventId: EVENTID;
    fLastEventProvider: IRawElementProviderSimple;
    fLastHwnd: HWND;
    fLastLParam: LPARAM;
    fLastNotificationProvider: IRawElementProviderSimple;
    fLastNotificationText: string;
    fLastPropertyChangedNewValue: OleVariant;
    fLastPropertyChangedOldValue: OleVariant;
    fLastPropertyChangedPropertyId: PROPERTYID;
    fLastPropertyChangedProvider: IRawElementProviderSimple;
    fNotificationCalls: Integer;
    fPropertyChangedCalls: Integer;
    fReturnedProvider: IRawElementProviderSimple;
    fReturnCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastEventId: EVENTID;
    function LastEventProvider: IRawElementProviderSimple;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
    function LastNotificationProvider: IRawElementProviderSimple;
    function LastNotificationText: string;
    function LastPropertyChangedNewValue: OleVariant;
    function LastPropertyChangedOldValue: OleVariant;
    function LastPropertyChangedPropertyId: PROPERTYID;
    function LastPropertyChangedProvider: IRawElementProviderSimple;
    function NotificationCalls: Integer;
    function PropertyChangedCalls: Integer;
    function ReturnedProvider: IRawElementProviderSimple;
    function RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
    function RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID;
      const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
    function RaiseNotification(const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
      aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
      const aActivityId: WideString): HRESULT;
    function RaiseStructureChanged(const aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
      const aRuntimeId: TArray<Integer>): HRESULT;
    function ReturnCalls: Integer;
    function ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple): LRESULT;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  TFormInstallRecorder = class(TInterfacedObject, IFormInstallRecorder)
  private
    fForms: TList<TCustomForm>;
    fFailNextInstall: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function CountFor(aForm: TCustomForm): Integer;
    procedure FailNextInstall;
    procedure InstallForm(aForm: TCustomForm);
  end;

  TWinEventRecorder = class(TInterfacedObject, IAccessibilityWinEventSink)
  private
    fCalls: Integer;
    fLastChildId: Cardinal;
    fLastEvent: DWORD;
    fLastHwnd: HWND;
    fLastObjectId: Cardinal;
  public
    procedure NotifyEvent(aEvent: DWORD; aHwnd: HWND; aObjectId: Cardinal; aChildId: Cardinal);
    property Calls: Integer read fCalls;
    property LastChildId: Cardinal read fLastChildId;
    property LastEvent: DWORD read fLastEvent;
    property LastHwnd: HWND read fLastHwnd;
    property LastObjectId: Cardinal read fLastObjectId;
  end;

  TActiveFormChangeProbe = class
  private
    fCalls: Integer;
  public
    procedure HandleActiveFormChange(aSender: TObject);
    property Calls: Integer read fCalls;
  end;

  TChainedActiveFormChangeProbe = class
  private
    fCalls: Integer;
    fPrior: TNotifyEvent;
  public
    procedure HandleActiveFormChange(aSender: TObject);
    property Calls: Integer read fCalls;
    property Prior: TNotifyEvent read fPrior write fPrior;
  end;

  TWindowProcProbe = class
  private
    fCalls: Integer;
    fPrior: TWndMethod;
  public
    procedure WindowProc(var aMessage: TMessage);
    property Calls: Integer read fCalls;
    property Prior: TWndMethod read fPrior write fPrior;
  end;

  TNativeAccessibleProbeControl = class(TCustomControl)
  private
    fGetObjectCalls: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    property GetObjectCalls: Integer read fGetObjectCalls;
  end;

  TNativeAccessibleProbeCheckBox = class(TCheckBox)
  private
    fGetObjectCalls: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    property GetObjectCalls: Integer read fGetObjectCalls;
  end;

  TNativeAccessibleProbeRadioButton = class(TRadioButton)
  private
    fGetObjectCalls: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    property GetObjectCalls: Integer read fGetObjectCalls;
  end;

  TNoActiveForm = class(TForm);

constructor TFormInstallRecorder.Create;
begin
  inherited Create;
  fForms := TList<TCustomForm>.Create;
end;

destructor TFormInstallRecorder.Destroy;
begin
  fForms.Free;
  inherited Destroy;
end;

function TFormInstallRecorder.CountFor(aForm: TCustomForm): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Pred(fForms.Count) do
  begin
    if fForms[i] = aForm then
    begin
      Inc(Result);
    end;
  end;
end;

procedure TFormInstallRecorder.FailNextInstall;
begin
  fFailNextInstall := True;
end;

procedure TFormInstallRecorder.InstallForm(aForm: TCustomForm);
begin
  if fFailNextInstall then
  begin
    fFailNextInstall := False;
    raise EInvalidOperation.Create('Synthetic install failure.');
  end;

  fForms.Add(aForm);
end;

procedure TWinEventRecorder.NotifyEvent(aEvent: DWORD; aHwnd: HWND; aObjectId: Cardinal; aChildId: Cardinal);
begin
  Inc(fCalls);
  fLastEvent := aEvent;
  fLastHwnd := aHwnd;
  fLastObjectId := aObjectId;
  fLastChildId := aChildId;
end;

procedure TActiveFormChangeProbe.HandleActiveFormChange(aSender: TObject);
begin
  Inc(fCalls);
end;

procedure TChainedActiveFormChangeProbe.HandleActiveFormChange(aSender: TObject);
begin
  Inc(fCalls);
  if Assigned(fPrior) then
  begin
    fPrior(aSender);
  end;
end;

procedure TWindowProcProbe.WindowProc(var aMessage: TMessage);
begin
  Inc(fCalls);
  if Assigned(fPrior) then
  begin
    fPrior(aMessage);
  end;
end;

procedure TNativeAccessibleProbeControl.WndProc(var aMessage: TMessage);
begin
  if aMessage.Msg = WM_GETOBJECT then
  begin
    Inc(fGetObjectCalls);
    aMessage.Result := 13579;
    Exit;
  end;

  inherited WndProc(aMessage);
end;

procedure TNativeAccessibleProbeCheckBox.WndProc(var aMessage: TMessage);
begin
  if aMessage.Msg = WM_GETOBJECT then
  begin
    Inc(fGetObjectCalls);
    aMessage.Result := 24680;
    Exit;
  end;

  inherited WndProc(aMessage);
end;

procedure TNativeAccessibleProbeRadioButton.WndProc(var aMessage: TMessage);
begin
  if aMessage.Msg = WM_GETOBJECT then
  begin
    Inc(fGetObjectCalls);
    aMessage.Result := 97531;
    Exit;
  end;

  inherited WndProc(aMessage);
end;

procedure ResetManager;
begin
  TAccessibilityManager.Uninstall;
  TAccessibilityManagerInternals.SetFormInstaller(nil);
  TAccessibilityManagerInternals.SetUiaApi(nil);
  TAccessibilityManagerInternals.SetWinEventSink(nil);
end;

function TManagerTestUiaApi.ClientsAreListening: Boolean;
begin
  Result := fClientsAreListening;
end;

function TManagerTestUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Inc(fDisconnectCalls);
  Result := S_OK;
end;

function TManagerTestUiaApi.DisconnectCalls: Integer;
begin
  Result := fDisconnectCalls;
end;

function TManagerTestUiaApi.EventCalls: Integer;
begin
  Result := fEventCalls;
end;

function TManagerTestUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function TManagerTestUiaApi.LastEventId: EVENTID;
begin
  Result := fLastEventId;
end;

function TManagerTestUiaApi.LastEventProvider: IRawElementProviderSimple;
begin
  Result := fLastEventProvider;
end;

function TManagerTestUiaApi.LastHwnd: HWND;
begin
  Result := fLastHwnd;
end;

function TManagerTestUiaApi.LastLParam: LPARAM;
begin
  Result := fLastLParam;
end;

function TManagerTestUiaApi.LastNotificationProvider: IRawElementProviderSimple;
begin
  Result := fLastNotificationProvider;
end;

function TManagerTestUiaApi.LastNotificationText: string;
begin
  Result := fLastNotificationText;
end;

function TManagerTestUiaApi.LastPropertyChangedNewValue: OleVariant;
begin
  Result := fLastPropertyChangedNewValue;
end;

function TManagerTestUiaApi.LastPropertyChangedOldValue: OleVariant;
begin
  Result := fLastPropertyChangedOldValue;
end;

function TManagerTestUiaApi.LastPropertyChangedPropertyId: PROPERTYID;
begin
  Result := fLastPropertyChangedPropertyId;
end;

function TManagerTestUiaApi.LastPropertyChangedProvider: IRawElementProviderSimple;
begin
  Result := fLastPropertyChangedProvider;
end;

function TManagerTestUiaApi.NotificationCalls: Integer;
begin
  Result := fNotificationCalls;
end;

function TManagerTestUiaApi.PropertyChangedCalls: Integer;
begin
  Result := fPropertyChangedCalls;
end;

function TManagerTestUiaApi.ReturnedProvider: IRawElementProviderSimple;
begin
  Result := fReturnedProvider;
end;

function TManagerTestUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID): HRESULT;
begin
  Inc(fEventCalls);
  fLastEventProvider := aProvider;
  fLastEventId := aEventId;
  Result := S_OK;
end;

function TManagerTestUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Inc(fPropertyChangedCalls);
  fLastPropertyChangedProvider := aProvider;
  fLastPropertyChangedPropertyId := aPropertyId;
  fLastPropertyChangedOldValue := aOldValue;
  fLastPropertyChangedNewValue := aNewValue;
  Result := S_OK;
end;

function TManagerTestUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Inc(fNotificationCalls);
  fLastNotificationProvider := aProvider;
  fLastNotificationText := aDisplayString;
  Result := S_OK;
end;

function TManagerTestUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Result := S_OK;
end;

function TManagerTestUiaApi.ReturnCalls: Integer;
begin
  Result := fReturnCalls;
end;

function TManagerTestUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Inc(fReturnCalls);
  fLastHwnd := aHwnd;
  fLastLParam := aLParam;
  fReturnedProvider := aProvider;
  Result := 2468;
end;

procedure TManagerTestUiaApi.SetClientsAreListening(aValue: Boolean);
begin
  fClientsAreListening := aValue;
end;

function ScaleValue(aValue: Integer): Integer;
begin
  Result := MulDiv(aValue, Screen.PixelsPerInch, 96);
end;

procedure CreateManagerTmsGridFixture(out aForm: TForm; out aGrid: TAdvStringGrid);
begin
  aForm := TForm.Create(nil);
  aForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(360), ScaleValue(220));

  aGrid := TAdvStringGrid.Create(aForm);
  aGrid.Name := 'ManagerAdvGrid';
  aGrid.Parent := aForm;
  aGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(220), ScaleValue(90));
  aGrid.ColCount := 3;
  aGrid.RowCount := 3;
  aGrid.FixedCols := 1;
  aGrid.FixedRows := 1;
  aGrid.DefaultColWidth := ScaleValue(55);
  aGrid.DefaultRowHeight := ScaleValue(22);
  aGrid.Cells[1, 0] := 'Name';
  aGrid.Cells[1, 1] := '<b>Alice</b>';
  aForm.HandleNeeded;
  aGrid.HandleNeeded;
end;

function SimpleProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Assert.IsTrue(Supports(aFragment, IRawElementProviderSimple, Result));
end;

function FragmentFromSimple(const aProvider: IRawElementProviderSimple): IRawElementProviderFragment;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider, IRawElementProviderFragment, Result));
end;

function NavigateFragment(const aFragment: IRawElementProviderFragment; aDirection: NavigateDirection):
  IRawElementProviderFragment;
begin
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

function ProviderStringProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := string(lValue);
end;

function ProviderPattern(const aFragment: IRawElementProviderFragment; aPatternId: PATTERNID): IUnknown;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPatternProvider(aPatternId, Result));
end;

function AccessibleFromLResult(aResult: LRESULT; aWParam: WPARAM): IAccessible;
begin
  Result := nil;
  Assert.IsTrue(aResult <> 0, 'MSAA WM_GETOBJECT did not return an object result.');
  Assert.AreEqual(S_OK, ObjectFromLresult(aResult, IID_IAccessible, aWParam, Result));
  Assert.IsNotNull(Result);
end;

function AccessibleObjectFromPointAt(const aPoint: TPoint; out aChild: VARIANT): IAccessible;
begin
  Result := nil;
  aChild := Unassigned;
  Assert.AreEqual(S_OK, AccessibleObjectFromPoint(aPoint, Result, aChild));
  Assert.IsNotNull(Result);
end;

function AccessibleHitTestAt(const aAccessible: IAccessible; const aPoint: TPoint): IAccessible;
var
  lHit: OleVariant;
  lHitDispatch: IDispatch;
begin
  lHit := Unassigned;
  Assert.AreEqual(S_OK, aAccessible.accHitTest(aPoint.X, aPoint.Y, lHit));
  Assert.AreEqual(varDispatch, VarType(lHit));

  lHitDispatch := IDispatch(TVarData(lHit).VDispatch);
  Result := nil;
  Assert.IsTrue(Supports(lHitDispatch, IAccessible, Result));
end;

function AccessibleName(const aAccessible: IAccessible): string;
var
  lName: WideString;
begin
  lName := '';
  Assert.AreEqual(S_OK, aAccessible.Get_accName(CHILDID_SELF, lName));
  Result := string(lName);
end;

function AccessibleRole(const aAccessible: IAccessible): Integer;
var
  lRole: OleVariant;
begin
  lRole := Unassigned;
  Assert.AreEqual(S_OK, aAccessible.Get_accRole(CHILDID_SELF, lRole));
  Result := Integer(lRole);
end;

function AccessibleState(const aAccessible: IAccessible): Integer;
var
  lState: OleVariant;
begin
  lState := Unassigned;
  Assert.AreEqual(S_OK, aAccessible.Get_accState(CHILDID_SELF, lState));
  Result := Integer(lState);
end;

function ControlScreenCenter(aControl: TControl): TPoint;
begin
  Result := aControl.ClientToScreen(Point(aControl.Width div 2, aControl.Height div 2));
end;

function MouseCoordinateWord(aValue: Integer): Word;
begin
  Result := Word(aValue and $FFFF);
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

function PointFromMessageResult(aValue: LRESULT): TPoint;
var
  lRawValue: Cardinal;
  lX: Integer;
  lY: Integer;
begin
  lRawValue := Cardinal(aValue);
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

procedure AssertManagerGridCellName(const aApi: IManagerTestUiaApi; aForm: TCustomForm;
  const aExpectedName: string);
var
  lCellProvider: IRawElementProviderSimple;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lMessage: TMessage;
  lPattern: IUnknown;
  lRootFragment: IRawElementProviderFragment;
begin
  aForm.HandleNeeded;

  lMessage := Default(TMessage);
  lMessage.Msg := WM_GETOBJECT;
  lMessage.LParam := UiaRootObjectId;
  aForm.WindowProc(lMessage);

  Assert.AreEqual(2468, lMessage.Result);
  Assert.IsNotNull(aApi.ReturnedProvider);

  lRootFragment := FragmentFromSimple(aApi.ReturnedProvider);
  lGridFragment := FirstChildFragment(lRootFragment);
  Assert.AreEqual(UIA_DataGridControlTypeId, ProviderIntProperty(lGridFragment, UIA_ControlTypePropertyId));
  lPattern := ProviderPattern(lGridFragment, UIA_GridPatternId);
  Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));
  Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lCellProvider));
  Assert.AreEqual(aExpectedName, ProviderStringProperty(FragmentFromSimple(lCellProvider), UIA_NamePropertyId));
end;

procedure TAccessibilityManagerTests.ApplicationInstallDiscoversFutureFormsAndChainsActiveFormChange;
var
  lForm: TForm;
  lOriginalActiveFormChange: TNotifyEvent;
  lProbe: TActiveFormChangeProbe;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lProbe := TActiveFormChangeProbe.Create;
  try
    lRecorder := TFormInstallRecorder.Create;
    TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
    Screen.OnActiveFormChange := lProbe.HandleActiveFormChange;

    TAccessibilityManager.Install(Application);
    lForm := TForm.Create(nil);
    try
      Assert.AreEqual(0, lRecorder.CountFor(lForm));

      Screen.OnActiveFormChange(Screen);

      Assert.AreEqual(1, lProbe.Calls);
      Assert.AreEqual(1, lRecorder.CountFor(lForm));
    finally
      lForm.Free;
    end;
  finally
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
    lProbe.Free;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationInstallWithCustomRegistryDiscoversFutureTmsForms;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lOriginalActiveFormChange: TNotifyEvent;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  try
    TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
    CreateManagerTmsGridFixture(lForm, lGrid);
    try
      Assert.IsNotNull(lGrid);
      Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);

      Screen.OnActiveFormChange(Screen);

      Assert.IsTrue(TAccessibilityManagerInternals.InstalledFormCount >= 1);
      AssertManagerGridCellName(lApi, lForm, 'Alice');
    finally
      lForm.Free;
    end;
  finally
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationInstallWithCustomRegistryScansCurrentTmsForms;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lOriginalActiveFormChange: TNotifyEvent;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  CreateManagerTmsGridFixture(lForm, lGrid);
  try
    Assert.IsNotNull(lGrid);

    TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);

    Assert.IsTrue(TAccessibilityManagerInternals.InstalledFormCount >= 1);
    AssertManagerGridCellName(lApi, lForm, 'Alice');
  finally
    lForm.Free;
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
  end;
end;

procedure TAccessibilityManagerTests.DemoEnableToggleInstallsUninstallsAndSyncsCurrentAndFutureForms;
var
  lFirstForm: TAccessibilityDemoMainForm;
  lFutureForm: TAccessibilityDemoMainForm;
  lOriginalActiveFormChange: TNotifyEvent;
  lRaised: Boolean;
  lSecondForm: TAccessibilityDemoMainForm;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lFirstForm := nil;
  lFutureForm := nil;
  lSecondForm := nil;
  try
    if DemoAccessibilityFrameworkEnabled then
    begin
      SetDemoAccessibilityFrameworkEnabled(False);
    end;

    lFirstForm := TAccessibilityDemoMainForm.Create(Application);
    lSecondForm := TAccessibilityDemoMainForm.Create(Application);

    Assert.IsFalse(DemoAccessibilityFrameworkEnabled);
    Assert.IsFalse(lFirstForm.chkAccessibilityEnabled.Checked);
    Assert.IsFalse(lSecondForm.chkAccessibilityEnabled.Checked);

    SetDemoAccessibilityFrameworkEnabled(True);

    Assert.IsTrue(DemoAccessibilityFrameworkEnabled);
    Assert.IsTrue(lFirstForm.chkAccessibilityEnabled.Checked);
    Assert.IsTrue(lSecondForm.chkAccessibilityEnabled.Checked);
    Assert.IsTrue(TAccessibilityManagerInternals.InstalledFormCount >= 2,
      'App-wide demo enable must install current demo forms.');

    lRaised := False;
    try
      TAccessibilityManager.Install(Application);
    except
      on EInvalidOperation do
      begin
        lRaised := True;
      end;
    end;
    Assert.IsTrue(lRaised, 'Demo enable must install the TMS app-wide registry, not the default registry.');

    lFirstForm.chkAccessibilityEnabled.Checked := False;
    lFirstForm.chkAccessibilityEnabledClick(lFirstForm.chkAccessibilityEnabled);

    Assert.IsFalse(DemoAccessibilityFrameworkEnabled);
    Assert.IsFalse(lFirstForm.chkAccessibilityEnabled.Checked);
    Assert.IsFalse(lSecondForm.chkAccessibilityEnabled.Checked);
    Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);

    lSecondForm.chkAccessibilityEnabled.Checked := True;
    lSecondForm.chkAccessibilityEnabledClick(lSecondForm.chkAccessibilityEnabled);

    Assert.IsTrue(DemoAccessibilityFrameworkEnabled);
    Assert.IsTrue(lFirstForm.chkAccessibilityEnabled.Checked);
    Assert.IsTrue(lSecondForm.chkAccessibilityEnabled.Checked);

    lFutureForm := TAccessibilityDemoMainForm.Create(Application);
    Assert.IsTrue(lFutureForm.chkAccessibilityEnabled.Checked);

    Screen.OnActiveFormChange(Screen);

    Assert.IsTrue(TAccessibilityManagerInternals.InstalledFormCount >= 3,
      'App-wide demo enable must discover future demo forms.');
  finally
    if DemoAccessibilityFrameworkEnabled then
    begin
      SetDemoAccessibilityFrameworkEnabled(False);
    end;
    lFutureForm.Free;
    lSecondForm.Free;
    lFirstForm.Free;
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationCustomRegistryRejectsDefaultFormInstall;
var
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lOriginalActiveFormChange: TNotifyEvent;
  lRaised: Boolean;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  try
    TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
    CreateManagerTmsGridFixture(lForm, lGrid);
    try
      Assert.IsNotNull(lGrid);

      lRaised := False;
      try
        TAccessibilityManager.Install(lForm);
      except
        on EInvalidOperation do
        begin
          lRaised := True;
        end;
      end;

      Assert.IsTrue(lRaised, 'One-arg form install must not mix with active app-wide custom registry.');
      Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);
    finally
      lForm.Free;
    end;
  finally
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationRegistrySwitchRequiresUninstall;
var
  lFirstRegistry: IAccessibilityAdapterRegistry;
  lOriginalActiveFormChange: TNotifyEvent;
  lRaised: Boolean;
  lSecondRegistry: IAccessibilityAdapterRegistry;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lFirstRegistry := TAccessibilityTmsAdvStringGridAdapters.CreateRegistry;
  lSecondRegistry := TAccessibilityTmsAdvStringGridAdapters.CreateRegistry;
  try
    TAccessibilityManager.Install(Application, lFirstRegistry);
    TAccessibilityManager.Install(Application, lFirstRegistry);

    lRaised := False;
    try
      TAccessibilityManager.Install(Application, lSecondRegistry);
    except
      on EInvalidOperation do
      begin
        lRaised := True;
      end;
    end;

    Assert.IsTrue(lRaised, 'Changing the app-wide registry while installed must require Uninstall first.');

    TAccessibilityManager.Uninstall;
    TAccessibilityManager.Install(Application, lSecondRegistry);
  finally
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationCustomRegistryRejectsInstalledDefaultFormWithoutPartialHook;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lOriginalActiveFormChange: TNotifyEvent;
  lProbe: TActiveFormChangeProbe;
  lRaised: Boolean;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lProbe := TActiveFormChangeProbe.Create;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  CreateManagerTmsGridFixture(lForm, lGrid);
  try
    Assert.IsNotNull(lGrid);
    Screen.OnActiveFormChange := lProbe.HandleActiveFormChange;
    TAccessibilityManager.Install(lForm);

    lRaised := False;
    try
      TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
    except
      on EInvalidOperation do
      begin
        lRaised := True;
      end;
    end;

    Assert.IsTrue(lRaised, 'Changing registry for an already installed form must fail.');

    Screen.OnActiveFormChange(Screen);
    Assert.AreEqual(1, lProbe.Calls);
    AssertManagerGridCellName(lApi, lForm, '<b>Alice</b>');
  finally
    lForm.Free;
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
    lProbe.Free;
  end;
end;

procedure TAccessibilityManagerTests.DefaultFormInstallLeavesTmsGridOnDefaultRegistry;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  CreateManagerTmsGridFixture(lForm, lGrid);
  try
    Assert.IsNotNull(lGrid);

    TAccessibilityManager.Install(lForm);

    AssertManagerGridCellName(lApi, lForm, '<b>Alice</b>');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationInstallScansCurrentFormsAndIsIdempotent;
var
  lFirst: TForm;
  lRecorder: IFormInstallRecorder;
  lSecond: TForm;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
  lFirst := TForm.Create(nil);
  try
    lSecond := TForm.Create(nil);
    try
      TAccessibilityManager.Install(Application);
      TAccessibilityManager.Install(Application);

      Assert.AreEqual(1, lRecorder.CountFor(lFirst));
      Assert.AreEqual(1, lRecorder.CountFor(lSecond));
    finally
      lSecond.Free;
    end;
  finally
    lFirst.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.RunInstallsCurrentFormsAndUninstallsAfterApplicationRun;
var
  lForm: TForm;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
  lForm := TForm.Create(nil);
  try
    TAccessibilityManager.Run(Application);

    Assert.AreEqual(1, lRecorder.CountFor(lForm));
    Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.RunUninstallsPartialApplicationInstallWhenInstallFails;
var
  lFirst: TForm;
  lRaised: Boolean;
  lRecorder: IFormInstallRecorder;
  lSecond: TForm;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
  lFirst := TForm.Create(nil);
  try
    lSecond := TForm.Create(nil);
    try
      TAccessibilityManager.Install(lFirst);
      lRecorder.FailNextInstall;
      lRaised := False;

      try
        TAccessibilityManager.Run(Application);
      except
        on EInvalidOperation do
        begin
          lRaised := True;
        end;
      end;

      Assert.IsTrue(lRaised, 'Run must preserve the install failure.');
      Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);
    finally
      lSecond.Free;
    end;
  finally
    lFirst.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.UninstallIsIdempotent;
var
  lForm: TForm;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
  lForm := TForm.Create(nil);
  try
    TAccessibilityManager.Install(Application);
    TAccessibilityManager.Uninstall;
    TAccessibilityManager.Uninstall;

    Assert.AreEqual(1, lRecorder.CountFor(lForm));
    Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationInstallSkipsInternalNoActiveForm;
var
  lInternalForm: TForm;
  lRealForm: TForm;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
  lInternalForm := TNoActiveForm.CreateNew(nil);
  try
    lRealForm := TForm.Create(nil);
    try
      TAccessibilityManager.Install(Application);

      Assert.AreEqual(0, lRecorder.CountFor(lInternalForm));
      Assert.AreEqual(1, lRecorder.CountFor(lRealForm));
    finally
      lRealForm.Free;
    end;
  finally
    lInternalForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallIsScopedAndIdempotent;
var
  lFirst: TForm;
  lRecorder: IFormInstallRecorder;
  lSecond: TForm;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
  lFirst := TForm.Create(nil);
  try
    lSecond := TForm.Create(nil);
    try
      TAccessibilityManager.Install(lFirst);
      TAccessibilityManager.Install(lFirst);

      Assert.AreEqual(1, lRecorder.CountFor(lFirst));
      Assert.AreEqual(0, lRecorder.CountFor(lSecond));
    finally
      lSecond.Free;
    end;
  finally
    lFirst.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallWithCustomRegistryUsesTmsProviderThroughWmGetObject;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  CreateManagerTmsGridFixture(lForm, lGrid);
  try
    Assert.IsNotNull(lGrid);

    TAccessibilityManager.Install(lForm, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);

    AssertManagerGridCellName(lApi, lForm, 'Alice');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormRegistrySwitchRequiresUninstall;
var
  lFirstRegistry: IAccessibilityAdapterRegistry;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lRaised: Boolean;
  lSecondRegistry: IAccessibilityAdapterRegistry;
begin
  ResetManager;
  lFirstRegistry := TAccessibilityTmsAdvStringGridAdapters.CreateRegistry;
  lSecondRegistry := TAccessibilityTmsAdvStringGridAdapters.CreateRegistry;
  CreateManagerTmsGridFixture(lForm, lGrid);
  try
    Assert.IsNotNull(lGrid);
    TAccessibilityManager.Install(lForm, lFirstRegistry);
    TAccessibilityManager.Install(lForm, lFirstRegistry);

    lRaised := False;
    try
      TAccessibilityManager.Install(lForm, lSecondRegistry);
    except
      on EInvalidOperation do
      begin
        lRaised := True;
      end;
    end;

    Assert.IsTrue(lRaised, 'Changing a form registry while installed must require Uninstall first.');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormCustomRegistryRejectsActiveDefaultApplicationInstall;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lOriginalActiveFormChange: TNotifyEvent;
  lRaised: Boolean;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  try
    TAccessibilityManager.Install(Application);
    CreateManagerTmsGridFixture(lForm, lGrid);
    try
      Assert.IsNotNull(lGrid);

      lRaised := False;
      try
        TAccessibilityManager.Install(lForm, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
      except
        on EInvalidOperation do
        begin
          lRaised := True;
        end;
      end;

      Assert.IsTrue(lRaised, 'Scoped custom registry must not mix with active app-wide default registry.');

      Screen.OnActiveFormChange(Screen);
      AssertManagerGridCellName(lApi, lForm, '<b>Alice</b>');
    finally
      lForm.Free;
    end;
  finally
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHandlesUiaGetObjectThroughDefaultProvider;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lMessage: TMessage;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := '&Customer';
    lLabel.Parent := lForm;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 7;
    lMessage.LParam := UiaRootObjectId;
    lForm.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(1, lApi.ReturnCalls);
    Assert.AreEqual(lForm.Handle, lApi.LastHwnd);
    Assert.AreEqual(LPARAM(UiaRootObjectId), lApi.LastLParam);

    TAccessibilityManager.Uninstall;

    Assert.IsTrue(lApi.DisconnectCalls > 0);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHandlesChildUiaGetObjectThroughFrameworkProvider;
var
  lApi: IManagerTestUiaApi;
  lEdit: TLabeledEdit;
  lForm: TForm;
  lMessage: TMessage;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lEdit := TLabeledEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.EditLabel.Caption := 'Reference number';
    lEdit.Text := 'REF-1042';
    lEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 11;
    lMessage.LParam := UiaRootObjectId;
    lEdit.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(lEdit.Handle, lApi.LastHwnd);
    Assert.IsNotNull(lApi.ReturnedProvider);
    Assert.AreEqual('Reference number',
      ProviderStringProperty(FragmentFromSimple(lApi.ReturnedProvider), UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHandlesChildContainerHitTestingForNonWindowedLabel;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lLabel: TLabel;
  lMessage: TMessage;
  lPanel: TPanel;
  lPoint: TPoint;
  lRoot: IRawElementProviderFragmentRoot;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 320, 200);

    lPanel := TPanel.Create(lForm);
    lPanel.Caption := '';
    lPanel.Parent := lForm;
    lPanel.SetBounds(16, 16, 220, 80);

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Command title';
    lLabel.Parent := lPanel;
    lLabel.SetBounds(12, 12, 120, 24);

    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 13;
    lMessage.LParam := UiaRootObjectId;
    lPanel.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(lPanel.Handle, lApi.LastHwnd);
    Assert.IsTrue(Supports(lApi.ReturnedProvider, IRawElementProviderFragmentRoot, lRoot));
    lPoint := ControlScreenCenter(lLabel);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Command title', ProviderStringProperty(lHit, UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallLeavesCheckBoxAndRadioButtonNativeGetObject;
var
  lApi: IManagerTestUiaApi;
  lCheckBox: TNativeAccessibleProbeCheckBox;
  lForm: TForm;
  lMessage: TMessage;
  lRadioButton: TNativeAccessibleProbeRadioButton;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 160);

    lCheckBox := TNativeAccessibleProbeCheckBox.Create(lForm);
    lCheckBox.Parent := lForm;
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Checked := True;
    lCheckBox.SetBounds(24, 24, 220, 24);
    lCheckBox.HandleNeeded;

    lRadioButton := TNativeAccessibleProbeRadioButton.Create(lForm);
    lRadioButton.Parent := lForm;
    lRadioButton.Caption := 'Compact';
    lRadioButton.Checked := True;
    lRadioButton.SetBounds(24, 64, 140, 24);
    lRadioButton.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 17;
    lMessage.LParam := UiaRootObjectId;
    lCheckBox.WindowProc(lMessage);

    Assert.AreEqual(24680, lMessage.Result);
    Assert.AreEqual(1, lCheckBox.GetObjectCalls);
    Assert.AreEqual(0, lApi.ReturnCalls);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 17;
    lMessage.LParam := UiaRootObjectId;
    lRadioButton.WindowProc(lMessage);

    Assert.AreEqual(97531, lMessage.Result);
    Assert.AreEqual(1, lRadioButton.GetObjectCalls);
    Assert.AreEqual(0, lApi.ReturnCalls);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallLeavesUnsupportedFocusableControlNativeGetObject;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lMessage: TMessage;
  lNativeControl: TNativeAccessibleProbeControl;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 320, 200);

    lNativeControl := TNativeAccessibleProbeControl.Create(lForm);
    lNativeControl.Name := 'NativeTree';
    lNativeControl.Parent := lForm;
    lNativeControl.TabStop := True;
    lNativeControl.SetBounds(16, 16, 220, 80);
    lNativeControl.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 19;
    lMessage.LParam := UiaRootObjectId;
    lNativeControl.WindowProc(lMessage);

    Assert.AreEqual(13579, lMessage.Result);
    Assert.AreEqual(1, lNativeControl.GetObjectCalls);
    Assert.AreEqual(0, lApi.ReturnCalls);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHandlesPageControlUiaGetObjectForTabHeaders;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lMessage: TMessage;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lRoot: IRawElementProviderFragmentRoot;
  lTabOrders: TTabSheet;
  lTabTms: TTabSheet;
  lTabRect: TRect;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Name := 'PageControl';
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lPageControl.HandleNeeded;
    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 17;
    lMessage.LParam := UiaRootObjectId;
    lPageControl.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(lPageControl.Handle, lApi.LastHwnd);
    Assert.IsTrue(Supports(lApi.ReturnedProvider, IRawElementProviderFragmentRoot, lRoot));

    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lPoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('TMS grid', ProviderStringProperty(lHit, UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHandlesPageControlMsaaGetObjectForTabHeaders;
const
  cObjIdClient = LPARAM(OBJID_CLIENT);
var
  lAccessible: IAccessible;
  lCoInit: HRESULT;
  lDefaultAction: WideString;
  lForm: TForm;
  lObjectResult: LRESULT;
  lObjectWParam: WPARAM;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lState: Integer;
  lTabOrders: TTabSheet;
  lTabRect: TRect;
  lTabTms: TTabSheet;
  lTmsAccessible: IAccessible;
begin
  ResetManager;
  lCoInit := CoInitialize(nil);
  lForm := TForm.Create(nil);
  try
    Assert.IsTrue((lCoInit = S_OK) or (lCoInit = S_FALSE) or (lCoInit = RPC_E_CHANGED_MODE));
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lPageControl.HandleNeeded;
    TAccessibilityManager.Install(lForm);

    lObjectWParam := 0;
    lObjectResult := SendMessage(lPageControl.Handle, WM_GETOBJECT, lObjectWParam, cObjIdClient);

    lAccessible := AccessibleFromLResult(lObjectResult, lObjectWParam);
    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lPoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);
    lTmsAccessible := AccessibleHitTestAt(lAccessible, lPoint);

    Assert.AreEqual('TMS grid', AccessibleName(lTmsAccessible));
    Assert.AreEqual(ROLE_SYSTEM_PAGETAB, AccessibleRole(lTmsAccessible));
    lState := AccessibleState(lTmsAccessible);
    Assert.IsTrue((lState and STATE_SYSTEM_SELECTABLE) <> 0);
    Assert.IsTrue((lState and STATE_SYSTEM_SELECTED) = 0);

    lDefaultAction := '';
    Assert.AreEqual(S_OK, lTmsAccessible.Get_accDefaultAction(CHILDID_SELF, lDefaultAction));
    Assert.AreEqual('Switch', string(lDefaultAction));
    Assert.AreEqual(S_OK, lTmsAccessible.accDoDefaultAction(CHILDID_SELF));
    Assert.AreSame(lTabTms, lPageControl.ActivePage);
    Assert.IsTrue((AccessibleState(lTmsAccessible) and STATE_SYSTEM_SELECTED) <> 0);
  finally
    lForm.Free;
    if (lCoInit = S_OK) or (lCoInit = S_FALSE) then
    begin
      CoUninitialize;
    end;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallObjectFromPointReturnsPageControlTabHeader;
var
  lAccessible: IAccessible;
  lChild: VARIANT;
  lCoInit: HRESULT;
  lForm: TForm;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabOrders: TTabSheet;
  lTabRect: TRect;
  lTabTms: TTabSheet;
begin
  ResetManager;
  lCoInit := CoInitialize(nil);
  lForm := TForm.Create(nil);
  try
    Assert.IsTrue((lCoInit = S_OK) or (lCoInit = S_FALSE) or (lCoInit = RPC_E_CHANGED_MODE));
    lForm.FormStyle := fsStayOnTop;
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lPageControl.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    SetWindowPos(lForm.Handle, HWND_TOPMOST, 100, 100, 420, 260, SWP_SHOWWINDOW);
    lForm.Show;
    lForm.Update;
    Application.ProcessMessages;

    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lPoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);
    lAccessible := AccessibleObjectFromPointAt(lPoint, lChild);

    Assert.AreEqual(CHILDID_SELF, Integer(lChild));
    Assert.AreEqual('TMS grid', AccessibleName(lAccessible));
    Assert.AreEqual(ROLE_SYSTEM_PAGETAB, AccessibleRole(lAccessible));
  finally
    lForm.Free;
    if (lCoInit = S_OK) or (lCoInit = S_FALSE) then
    begin
      CoUninitialize;
    end;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallObjectFromPointReturnsActiveTabSheetNestedLabel;
var
  lAccessible: IAccessible;
  lChild: VARIANT;
  lCoInit: HRESULT;
  lForm: TForm;
  lGrid: TStringGrid;
  lHeaderPanel: TPanel;
  lLabel: TLabel;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabOrders: TTabSheet;
  lTabTms: TTabSheet;
begin
  ResetManager;
  lCoInit := CoInitialize(nil);
  lForm := TForm.Create(nil);
  try
    Assert.IsTrue((lCoInit = S_OK) or (lCoInit = S_FALSE) or (lCoInit = RPC_E_CHANGED_MODE));
    lForm.FormStyle := fsStayOnTop;
    lForm.SetBounds(100, 100, 460, 320);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Name := 'PageControl';
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 400, 250);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'TStringGrid rows';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lHeaderPanel := TPanel.Create(lForm);
    lHeaderPanel.Parent := lTabOrders;
    lHeaderPanel.SetBounds(16, 16, 340, 42);
    lHeaderPanel.Caption := '';
    lHeaderPanel.BevelOuter := bvNone;

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'TStringGrid row-select keyboard demo';
    lLabel.Parent := lHeaderPanel;
    lLabel.SetBounds(8, 8, 260, 24);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lTabOrders;
    lGrid.SetBounds(24, 70, 300, 130);
    lGrid.ColCount := 2;
    lGrid.RowCount := 2;
    lGrid.Cells[1, 1] := 'Contoso';
    lGrid.HandleNeeded;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lPageControl.HandleNeeded;
    lHeaderPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    SetWindowPos(lForm.Handle, HWND_TOPMOST, 100, 100, 460, 320, SWP_SHOWWINDOW);
    lForm.Show;
    lForm.Update;
    Application.ProcessMessages;

    lPoint := ControlScreenCenter(lLabel);
    lAccessible := AccessibleObjectFromPointAt(lPoint, lChild);

    Assert.AreEqual(CHILDID_SELF, Integer(lChild));
    Assert.AreEqual('TStringGrid row-select keyboard demo', AccessibleName(lAccessible));
    Assert.AreEqual(ROLE_SYSTEM_STATICTEXT, AccessibleRole(lAccessible));
  finally
    lForm.Free;
    if (lCoInit = S_OK) or (lCoInit = S_FALSE) then
    begin
      CoUninitialize;
    end;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHandlesInputMsaaGetObjectWithLabelAndTextHint;
const
  cObjIdClient = LPARAM(OBJID_CLIENT);
var
  lEdit: TEdit;
  lForm: TForm;
  lLabel: TLabel;
  lMessage: TMessage;
begin
  ResetManager;
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 320, 180);

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Search text';
    lLabel.Parent := lForm;
    lLabel.SetBounds(12, 12, 120, 24);

    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.TextHint := 'customer, order, or finding';
    lEdit.SetBounds(12, 40, 180, 24);
    lEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 23;
    lMessage.LParam := cObjIdClient;
    lEdit.WindowProc(lMessage);

    Assert.AreNotEqual(0, Integer(lMessage.Result), 'Input hook did not return an MSAA result.');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHandlesStringGridMsaaGetObjectForFocusedCell;
const
  cObjIdClient = LPARAM(OBJID_CLIENT);
var
  lForm: TForm;
  lGrid: TStringGrid;
  lMessage: TMessage;
begin
  ResetManager;
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 220);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.SetBounds(12, 12, 240, 110);
    lGrid.ColCount := 2;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Cells[1, 1] := 'Alice';
    lGrid.Cells[1, 2] := 'Contoso';
    lGrid.Col := 1;
    lGrid.Row := 2;
    lForm.ActiveControl := lGrid;
    lGrid.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 29;
    lMessage.LParam := cObjIdClient;
    lGrid.WindowProc(lMessage);

    Assert.AreNotEqual(0, Integer(lMessage.Result), 'StringGrid hook did not return an MSAA result.');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesFocusedControlHintNotificationOnFocus;
var
  lApi: IManagerTestUiaApi;
  lEdit: TEdit;
  lForm: TForm;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.Hint := 'Search demo orders and audit findings';
    lEdit.ShowHint := True;
    lEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lEdit.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Search demo orders and audit findings', lApi.LastNotificationText);
    Assert.AreEqual(Integer(lEdit.Handle), ProviderIntProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NativeWindowHandlePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesInputFocusEventOnFocus;
var
  lApi: IManagerTestUiaApi;
  lEdit: TEdit;
  lForm: TForm;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.Text := 'Alice';
    lEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lEdit.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual(Integer(lEdit.Handle), ProviderIntProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NativeWindowHandlePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesComboBoxFocusEventOnFocus;
var
  lApi: IManagerTestUiaApi;
  lCombo: TComboBox;
  lForm: TForm;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lCombo := TComboBox.Create(lForm);
    lCombo.Parent := lForm;
    lCombo.Items.Add('Urgent');
    lCombo.ItemIndex := 0;
    lCombo.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lCombo.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual(Integer(lCombo.Handle), ProviderIntProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NativeWindowHandlePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesLabeledEditFocusEventOnFocus;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabeledEdit: TLabeledEdit;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lLabeledEdit := TLabeledEdit.Create(lForm);
    lLabeledEdit.Parent := lForm;
    lLabeledEdit.EditLabel.Caption := 'Reference number';
    lLabeledEdit.Text := 'REF-1042';
    lLabeledEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lLabeledEdit.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual(Integer(lLabeledEdit.Handle), ProviderIntProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NativeWindowHandlePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesFocusedEditTextHintNotificationOnFocus;
var
  lApi: IManagerTestUiaApi;
  lEdit: TEdit;
  lForm: TForm;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.TextHint := 'customer, order, or finding';
    lEdit.ShowHint := True;
    lEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lEdit.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('customer, order, or finding', lApi.LastNotificationText);
    Assert.AreEqual(Integer(lEdit.Handle), ProviderIntProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NativeWindowHandlePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesInputFocusAnnouncementMatchingMouseOverSurface;
var
  lApi: IManagerTestUiaApi;
  lCombo: TComboBox;
  lComboLabel: TLabel;
  lEdit: TEdit;
  lEditLabel: TLabel;
  lForm: TForm;
  lLabeledEdit: TLabeledEdit;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 240);

    lEditLabel := TLabel.Create(lForm);
    lEditLabel.Caption := 'Customer';
    lEditLabel.Parent := lForm;
    lEditLabel.SetBounds(12, 18, 90, 20);

    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.Text := 'Alice';
    lEdit.Hint := 'Search demo orders and audit findings';
    lEdit.SetBounds(112, 14, 160, 23);
    lEdit.HandleNeeded;

    lComboLabel := TLabel.Create(lForm);
    lComboLabel.Caption := 'Queue';
    lComboLabel.Parent := lForm;
    lComboLabel.SetBounds(12, 58, 90, 20);

    lCombo := TComboBox.Create(lForm);
    lCombo.Parent := lForm;
    lCombo.SetBounds(112, 54, 160, 23);
    lCombo.Items.Add('Urgent');
    lCombo.ItemIndex := 0;
    lCombo.HandleNeeded;

    lLabeledEdit := TLabeledEdit.Create(lForm);
    lLabeledEdit.Parent := lForm;
    lLabeledEdit.EditLabel.Caption := 'Reference number';
    lLabeledEdit.Text := 'REF-1042';
    lLabeledEdit.SetBounds(112, 98, 160, 23);
    lLabeledEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lEdit.Perform(CM_ENTER, 0, 0);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Customer Alice. Search demo orders and audit findings', lApi.LastNotificationText);

    lCombo.Perform(CM_ENTER, 0, 0);
    Assert.AreEqual(2, lApi.NotificationCalls);
    Assert.AreEqual('Queue Urgent', lApi.LastNotificationText);

    lLabeledEdit.Perform(CM_ENTER, 0, 0);
    Assert.AreEqual(3, lApi.NotificationCalls);
    Assert.AreEqual('Reference number REF-1042', lApi.LastNotificationText);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesInputMsaaFocusWinEventWithDefaultApi;
var
  lEdit: TEdit;
  lForm: TForm;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lWinEvents := TWinEventRecorder.Create;
  TAccessibilityManagerInternals.SetWinEventSink(lWinEvents);
  lForm := TForm.Create(nil);
  try
    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.Text := 'Alice';
    lEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lEdit.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(1, lWinEvents.Calls);
    Assert.AreEqual(EVENT_OBJECT_FOCUS, lWinEvents.LastEvent);
    Assert.AreEqual(lEdit.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesPageControlTabHoverNotification;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabOrders: TTabSheet;
  lTabRect: TRect;
  lTabTms: TTabSheet;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lPageControl.HandleNeeded;
    TAccessibilityManager.Install(lForm);

    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lPoint := lTabRect.CenterPoint;
    lPageControl.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('TMS grid', lApi.LastNotificationText);
    Assert.AreEqual('TMS grid', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesPageControlTabHoverNotificationFromFormMouseMove;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lFormPoint: TPoint;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabOrders: TTabSheet;
  lTabRect: TRect;
  lTabTms: TTabSheet;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    TAccessibilityManager.Install(lForm);

    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lPoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);
    lFormPoint := lForm.ScreenToClient(lPoint);
    lForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lFormPoint));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('TMS grid', lApi.LastNotificationText);
    Assert.AreEqual('TMS grid', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesActiveTabSheetLabelHoverNotification;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TStringGrid;
  lLabel: TLabel;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabOrders: TTabSheet;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 460, 320);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 400, 250);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'TStringGrid rows';
    lTabOrders.PageControl := lPageControl;

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'TStringGrid row-select keyboard demo';
    lLabel.Parent := lTabOrders;
    lLabel.SetBounds(24, 24, 260, 24);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lTabOrders;
    lGrid.SetBounds(24, 58, 300, 130);
    lGrid.ColCount := 2;
    lGrid.RowCount := 2;
    lGrid.Cells[1, 1] := 'Contoso';
    lGrid.HandleNeeded;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lTabOrders.HandleNeeded;
    TAccessibilityManager.Install(lForm);

    lPoint := lTabOrders.ScreenToClient(ControlScreenCenter(lLabel));
    lTabOrders.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('TStringGrid row-select keyboard demo', lApi.LastNotificationText);
    Assert.AreEqual('TStringGrid row-select keyboard demo',
      ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider), UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesActiveTabSheetPanelLabelHoverNotification;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TStringGrid;
  lHeaderPanel: TPanel;
  lLabel: TLabel;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabOrders: TTabSheet;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 460, 320);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 400, 250);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'TStringGrid rows';
    lTabOrders.PageControl := lPageControl;

    lHeaderPanel := TPanel.Create(lForm);
    lHeaderPanel.Parent := lTabOrders;
    lHeaderPanel.SetBounds(16, 16, 340, 42);
    lHeaderPanel.Caption := '';
    lHeaderPanel.BevelOuter := bvNone;

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'TStringGrid row-select keyboard demo';
    lLabel.Parent := lHeaderPanel;
    lLabel.SetBounds(8, 8, 260, 24);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lTabOrders;
    lGrid.SetBounds(24, 70, 300, 130);
    lGrid.ColCount := 2;
    lGrid.RowCount := 2;
    lGrid.Cells[1, 1] := 'Contoso';
    lGrid.HandleNeeded;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lHeaderPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);

    lPoint := lHeaderPanel.ScreenToClient(ControlScreenCenter(lLabel));
    lHeaderPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('TStringGrid row-select keyboard demo', lApi.LastNotificationText);
    Assert.AreEqual('TStringGrid row-select keyboard demo',
      ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider), UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesMemoListBoxAndStatusBarHoverNotifications;
var
  lApi: IManagerTestUiaApi;
  lCharIndex: LRESULT;
  lForm: TForm;
  lItemRect: TRect;
  lLinePoint: TPoint;
  lListBox: TListBox;
  lMemo: TMemo;
  lPoint: TPoint;
  lStatusBar: TStatusBar;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 460, 260);

    lMemo := TMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.ScrollBars := ssNone;
    lMemo.WordWrap := False;
    lMemo.SetBounds(12, 12, 220, 80);
    lMemo.Lines.Text := 'First memo line' + sLineBreak + 'Second memo line';
    lMemo.HandleNeeded;

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(250, 12, 160, 80);
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.Items.Add('Completed action');
    lListBox.HandleNeeded;

    lStatusBar := TStatusBar.Create(lForm);
    lStatusBar.Parent := lForm;
    lStatusBar.SimplePanel := True;
    lStatusBar.SimpleText := 'Ready. High severity checks: 4';
    lStatusBar.SetBounds(0, 210, 460, 24);
    lStatusBar.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lCharIndex := lMemo.Perform(EM_LINEINDEX, 1, 0);
    lLinePoint := PointFromMessageResult(lMemo.Perform(EM_POSFROMCHAR, lCharIndex, 0));
    lMemo.Perform(WM_MOUSEMOVE, 0, PointToMouseLParam(Point(lLinePoint.X + 4, lLinePoint.Y + 2)));
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Second memo line', lApi.LastNotificationText);
    Assert.AreEqual('Second memo line', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));

    lItemRect := lListBox.ItemRect(2);
    lPoint := lItemRect.CenterPoint;
    lListBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    Assert.AreEqual(2, lApi.NotificationCalls);
    Assert.AreEqual('Completed action', lApi.LastNotificationText);
    Assert.AreEqual('Completed action', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));

    lStatusBar.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(8, 8)));
    Assert.AreEqual(3, lApi.NotificationCalls);
    Assert.AreEqual('Ready. High severity checks: 4', lApi.LastNotificationText);
    Assert.AreEqual('Ready. High severity checks: 4',
      ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider), UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesWindowedButtonHoverNotificationAndKeepsCheckBoxNative;
var
  lApi: IManagerTestUiaApi;
  lButton: TButton;
  lCheckBox: TCheckBox;
  lForm: TForm;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lButton := TButton.Create(lForm);
    lButton.Parent := lForm;
    lButton.Caption := '&Apply Filters';
    lButton.Hint := 'Apply the selected filters';
    lButton.SetBounds(24, 24, 140, 34);
    lButton.HandleNeeded;

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Parent := lForm;
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Hint := 'Includes archived rows in the demo grids';
    lCheckBox.Checked := True;
    lCheckBox.SetBounds(24, 76, 220, 24);
    lCheckBox.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lButton.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lButton.Width div 2, lButton.Height div 2)));
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Apply Filters. Apply the selected filters', lApi.LastNotificationText);
    Assert.AreEqual('Apply Filters', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));

    lCheckBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lCheckBox.Width div 2, lCheckBox.Height div 2)));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGroupBoxHoverAndRadioGroupItemHoverProviders;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lPoint: TPoint;
  lRadioGroup: TRadioGroup;
  lRadioOne: TRadioButton;
  lRadioTwo: TRadioButton;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Parent := lForm;
    lGroupBox.Caption := 'View mode';
    lGroupBox.Hint := 'Choose how the demo presents detail density';
    lGroupBox.SetBounds(24, 24, 220, 86);
    lGroupBox.HandleNeeded;

    lRadioOne := TRadioButton.Create(lForm);
    lRadioOne.Parent := lGroupBox;
    lRadioOne.Caption := 'Compact';
    lRadioOne.Checked := True;
    lRadioOne.SetBounds(12, 28, 120, 22);
    lRadioOne.HandleNeeded;

    lRadioTwo := TRadioButton.Create(lForm);
    lRadioTwo.Parent := lGroupBox;
    lRadioTwo.Caption := 'Detailed';
    lRadioTwo.SetBounds(12, 54, 120, 22);
    lRadioTwo.HandleNeeded;

    lRadioGroup := TRadioGroup.Create(lForm);
    lRadioGroup.Parent := lForm;
    lRadioGroup.Caption := 'Density';
    lRadioGroup.Hint := 'TRadioGroup sample for role comparison';
    lRadioGroup.Items.Add('Comfortable');
    lRadioGroup.Items.Add('Compact density');
    lRadioGroup.ItemIndex := 0;
    lRadioGroup.SetBounds(24, 128, 220, 82);
    lRadioGroup.HandleNeeded;
    lRadioGroup.Buttons[0].HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lGroupBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(8, 8)));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('View mode. Choose how the demo presents detail density', lApi.LastNotificationText);
    Assert.AreEqual('View mode', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('View mode', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));

    lPoint := lRadioGroup.Buttons[0].BoundsRect.CenterPoint;
    lRadioGroup.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(2, lApi.NotificationCalls);
    Assert.AreEqual('Comfortable', lApi.LastNotificationText);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGroupBoxHoverFromNonClientMouseMove;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Parent := lForm;
    lGroupBox.Caption := 'View mode';
    lGroupBox.Hint := 'Choose how the demo presents detail density';
    lGroupBox.SetBounds(24, 24, 220, 86);
    lGroupBox.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lPoint := lGroupBox.ClientToScreen(Point(8, 8));
    lGroupBox.Perform(WM_NCMOUSEMOVE, HTCAPTION, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('View mode. Choose how the demo presents detail density', lApi.LastNotificationText);
    Assert.AreEqual('View mode', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('View mode', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallIgnoresFormNonClientHoverWithoutRangeCheck;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);
    lForm.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lPoint := lForm.ClientToScreen(Point(lForm.ClientWidth - 8, -8));
    lForm.Perform(WM_NCMOUSEMOVE, HTCLOSE, PointToMouseLParam(lPoint));

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(0, lApi.EventCalls);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesRadioGroupItemHoverFromButtonWindow;
var
  lApi: IManagerTestUiaApi;
  lButton: TRadioButton;
  lForm: TForm;
  lRadioGroup: TRadioGroup;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lRadioGroup := TRadioGroup.Create(lForm);
    lRadioGroup.Parent := lForm;
    lRadioGroup.Caption := 'Density';
    lRadioGroup.Hint := 'TRadioGroup sample for role comparison';
    lRadioGroup.Items.Add('Comfortable');
    lRadioGroup.Items.Add('Compact density');
    lRadioGroup.ItemIndex := 0;
    lRadioGroup.SetBounds(24, 24, 220, 82);
    lRadioGroup.HandleNeeded;
    lRadioGroup.Buttons[0].HandleNeeded;
    lButton := lRadioGroup.Buttons[0];

    TAccessibilityManager.Install(lForm);

    lButton.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lButton.Width div 2, lButton.Height div 2)));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Comfortable', lApi.LastNotificationText);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.DemoFormInstallRaisesRadioGroupItemHoverFromButtonWindow;
var
  lApi: IManagerTestUiaApi;
  lButton: TRadioButton;
  lForm: TAccessibilityDemoMainForm;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    lForm.HandleNeeded;
    lForm.radioGroupDensity.HandleNeeded;
    lForm.radioGroupDensity.Buttons[0].HandleNeeded;
    lButton := lForm.radioGroupDensity.Buttons[0];

    TAccessibilityManager.Install(lForm);

    lButton.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lButton.Width div 2, lButton.Height div 2)));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Comfortable', lApi.LastNotificationText);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesLazyRadioGroupItemHoverFromButtonWindow;
var
  lApi: IManagerTestUiaApi;
  lButton: TRadioButton;
  lForm: TForm;
  lRadioGroup: TRadioGroup;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lRadioGroup := TRadioGroup.Create(lForm);
    lRadioGroup.Parent := lForm;
    lRadioGroup.Caption := 'Density';
    lRadioGroup.Hint := 'TRadioGroup sample for role comparison';
    lRadioGroup.Items.Add('Comfortable');
    lRadioGroup.Items.Add('Compact density');
    lRadioGroup.ItemIndex := 0;
    lRadioGroup.SetBounds(24, 24, 220, 82);
    lRadioGroup.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lButton := lRadioGroup.Buttons[0];
    lButton.HandleNeeded;
    lButton.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lButton.Width div 2, lButton.Height div 2)));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Comfortable', lApi.LastNotificationText);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesCheckBoxHoverNativeWinEventsWithoutProviderReplacement;
var
  lApi: IManagerTestUiaApi;
  lCheckBox: TCheckBox;
  lForm: TForm;
  lPattern: IUnknown;
  lToggle: IToggleProvider;
  lToggleState: ToggleState;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lWinEvents := TWinEventRecorder.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  TAccessibilityManagerInternals.SetWinEventSink(lWinEvents);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 140);

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Parent := lForm;
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Hint := 'Includes archived rows in the demo grids';
    lCheckBox.Checked := True;
    lCheckBox.SetBounds(24, 24, 220, 24);
    lCheckBox.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lCheckBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lCheckBox.Width div 2, lCheckBox.Height div 2)));

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Include archived rows', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    lPattern := ProviderPattern(FragmentFromSimple(lApi.LastEventProvider), UIA_TogglePatternId);
    Assert.IsTrue(Supports(lPattern, IToggleProvider, lToggle));
    Assert.AreEqual(S_OK, lToggle.Get_ToggleState(lToggleState));
    Assert.AreEqual(ToggleState_On, lToggleState);
    Assert.AreEqual(2, lWinEvents.Calls);
    Assert.AreEqual(EVENT_OBJECT_STATECHANGE, lWinEvents.LastEvent);
    Assert.AreEqual(lCheckBox.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesCheckBoxFocusNativeWinEventsWithoutProviderReplacement;
var
  lApi: IManagerTestUiaApi;
  lCheckBox: TCheckBox;
  lForm: TForm;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lWinEvents := TWinEventRecorder.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  TAccessibilityManagerInternals.SetWinEventSink(lWinEvents);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 140);

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Parent := lForm;
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Hint := 'Includes archived rows in the demo grids';
    lCheckBox.Checked := True;
    lCheckBox.SetBounds(24, 24, 220, 24);
    lCheckBox.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lCheckBox.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.AreEqual(2, lWinEvents.Calls);
    Assert.AreEqual(EVENT_OBJECT_STATECHANGE, lWinEvents.LastEvent);
    Assert.AreEqual(lCheckBox.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesRadioButtonHoverAndFocusNativeWinEventsWithoutProviderReplacement;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lIsSelected: BOOL;
  lPattern: IUnknown;
  lRadioButton: TRadioButton;
  lSelectionItem: ISelectionItemProvider;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lWinEvents := TWinEventRecorder.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  TAccessibilityManagerInternals.SetWinEventSink(lWinEvents);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 140);

    lRadioButton := TRadioButton.Create(lForm);
    lRadioButton.Parent := lForm;
    lRadioButton.Caption := 'Compact';
    lRadioButton.Checked := True;
    lRadioButton.SetBounds(24, 24, 140, 24);
    lRadioButton.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lRadioButton.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lRadioButton.Width div 2, lRadioButton.Height div 2)));

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Compact', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    lPattern := ProviderPattern(FragmentFromSimple(lApi.LastEventProvider), UIA_SelectionItemPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
    Assert.AreEqual(S_OK, lSelectionItem.Get_IsSelected(lIsSelected));
    Assert.IsTrue(lIsSelected);
    Assert.AreEqual(2, lWinEvents.Calls);
    Assert.AreEqual(EVENT_OBJECT_STATECHANGE, lWinEvents.LastEvent);
    Assert.AreEqual(lRadioButton.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);

    lRadioButton.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(4, lWinEvents.Calls);
    Assert.AreEqual(EVENT_OBJECT_STATECHANGE, lWinEvents.LastEvent);
    Assert.AreEqual(lRadioButton.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallLeavesCheckBoxToggleToNativeWindow;
var
  lApi: IManagerTestUiaApi;
  lCheckBox: TCheckBox;
  lForm: TForm;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lWinEvents := TWinEventRecorder.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  TAccessibilityManagerInternals.SetWinEventSink(lWinEvents);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 140);

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Parent := lForm;
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Checked := False;
    lCheckBox.SetBounds(24, 24, 220, 24);
    lCheckBox.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lCheckBox.Perform(BM_CLICK, 0, 0);

    Assert.IsTrue(lCheckBox.Checked);
    Assert.AreEqual(0, lApi.PropertyChangedCalls);
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.IsTrue(lWinEvents.Calls > 0);
    Assert.AreEqual(lCheckBox.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallLeavesRadioButtonSelectionToNativeWindow;
var
  lApi: IManagerTestUiaApi;
  lFirstRadio: TRadioButton;
  lForm: TForm;
  lSecondRadio: TRadioButton;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lWinEvents := TWinEventRecorder.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  TAccessibilityManagerInternals.SetWinEventSink(lWinEvents);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 160);

    lFirstRadio := TRadioButton.Create(lForm);
    lFirstRadio.Parent := lForm;
    lFirstRadio.Caption := 'Compact';
    lFirstRadio.Checked := True;
    lFirstRadio.SetBounds(24, 24, 120, 22);
    lFirstRadio.HandleNeeded;

    lSecondRadio := TRadioButton.Create(lForm);
    lSecondRadio.Parent := lForm;
    lSecondRadio.Caption := 'Detailed';
    lSecondRadio.SetBounds(24, 54, 120, 22);
    lSecondRadio.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lSecondRadio.Perform(BM_CLICK, 0, 0);

    Assert.IsTrue(lSecondRadio.Checked);
    Assert.AreEqual(0, lApi.PropertyChangedCalls);
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.IsTrue(lWinEvents.Calls > 0);
    Assert.AreEqual(lSecondRadio.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesToggleSpeedButtonHoverWithoutCheckBoxStateText;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lPoint: TPoint;
  lSpeedButton: TSpeedButton;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 320, 160);

    lSpeedButton := TSpeedButton.Create(lForm);
    lSpeedButton.Parent := lForm;
    lSpeedButton.Caption := '&Pinned';
    lSpeedButton.Hint := 'Pinned state';
    lSpeedButton.GroupIndex := 1;
    lSpeedButton.AllowAllUp := True;
    lSpeedButton.Down := False;
    lSpeedButton.SetBounds(24, 24, 96, 34);

    TAccessibilityManager.Install(lForm);

    lPoint := lForm.ScreenToClient(ControlScreenCenter(lSpeedButton));
    lForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Pinned. Pinned state', lApi.LastNotificationText);
    Assert.AreEqual('Pinned', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGridCellFocusEventAfterStringGridCellChangeMessage;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TStringGrid;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.ColCount := 2;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Cells[1, 1] := 'Alice';
    lGrid.Cells[1, 2] := 'Contoso';
    lGrid.Col := 1;
    lGrid.Row := 1;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    TAccessibilityManager.Install(lForm);
    lGrid.Row := 2;
    lGrid.Perform(CM_CHANGED, 0, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Contoso', lApi.LastNotificationText);
    Assert.AreEqual('Contoso', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider), UIA_NamePropertyId));
    Assert.AreEqual('Contoso', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGridCellFocusEventAfterStringGridArrowKey;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TStringGrid;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.ColCount := 2;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Cells[1, 1] := 'Alice';
    lGrid.Cells[1, 2] := 'Contoso';
    lGrid.Col := 1;
    lGrid.Row := 1;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    TAccessibilityManager.Install(lForm);
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Contoso', lApi.LastNotificationText);
    Assert.AreEqual('Contoso', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider), UIA_NamePropertyId));
    Assert.AreEqual('Contoso', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesStringGridRowFocusNotificationForRowSelect;
var
  lApi: IManagerTestUiaApi;
  lExpectedName: string;
  lForm: TForm;
  lGrid: TStringGrid;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.ColCount := 3;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Options := lGrid.Options + [goRowSelect];
    lGrid.Cells[0, 0] := 'Order';
    lGrid.Cells[1, 0] := 'Customer';
    lGrid.Cells[2, 0] := 'Status';
    lGrid.Cells[0, 1] := '#24018';
    lGrid.Cells[1, 1] := 'Northwind';
    lGrid.Cells[2, 1] := 'Packed';
    lGrid.Cells[0, 2] := '#24019';
    lGrid.Cells[1, 2] := 'Contoso';
    lGrid.Cells[2, 2] := 'Waiting';
    lGrid.Col := 0;
    lGrid.Row := 1;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;
    lExpectedName := 'Order: #24019' + sLineBreak + sLineBreak + 'Customer: Contoso' + sLineBreak +
      sLineBreak + 'Status: Waiting';

    TAccessibilityManager.Install(lForm);
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual(lExpectedName, lApi.LastNotificationText);
    Assert.AreEqual(lExpectedName, ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(lExpectedName, ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesListBoxItemFocusEventAfterArrowKey;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lListBox: TListBox;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.Items.Add('Completed action');
    lListBox.ItemIndex := 1;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;

    TAccessibilityManager.Install(lForm);
    lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(2, lListBox.ItemIndex);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual('Completed action', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallDoesNotRaiseGridMsaaFocusWinEventAfterCellNotification;
var
  lForm: TForm;
  lGrid: TStringGrid;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lWinEvents := TWinEventRecorder.Create;
  TAccessibilityManagerInternals.SetWinEventSink(lWinEvents);
  lForm := TForm.Create(nil);
  try
    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.ColCount := 2;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Cells[1, 1] := 'Alice';
    lGrid.Cells[1, 2] := 'Contoso';
    lGrid.Col := 1;
    lGrid.Row := 1;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    TAccessibilityManager.Install(lForm);
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(0, lWinEvents.Calls);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGridCellFocusEventAfterAdvStringGridCellChangeMessage;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lGrid := TAdvStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.ColCount := 2;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Cells[1, 1] := 'Alice TMS';
    lGrid.Cells[1, 2] := 'Contoso TMS';
    lGrid.Col := 1;
    lGrid.Row := 1;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    TAccessibilityManager.Install(lForm, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
    lGrid.Row := 2;
    lGrid.Perform(CM_CHANGED, 0, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Contoso TMS', lApi.LastNotificationText);
    Assert.AreEqual('Contoso TMS', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    Assert.AreEqual('Contoso TMS', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGridCellFocusEventAfterAdvStringGridArrowKey;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TAdvStringGrid;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lGrid := TAdvStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.ColCount := 2;
    lGrid.RowCount := 3;
    lGrid.FixedRows := 1;
    lGrid.Cells[1, 1] := 'Alice TMS';
    lGrid.Cells[1, 2] := 'Contoso TMS';
    lGrid.Col := 1;
    lGrid.Row := 1;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    TAccessibilityManager.Install(lForm, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Contoso TMS', lApi.LastNotificationText);
    Assert.AreEqual('Contoso TMS', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    Assert.AreEqual('Contoso TMS', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.LaterWindowProcHookCanCallManagerAfterUninstallWithoutUiaReturn;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lMessage: TMessage;
  lOriginalWindowProc: TWndMethod;
  lProbe: TWindowProcProbe;
begin
  ResetManager;
  lForm := nil;
  lOriginalWindowProc := nil;
  lProbe := nil;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  try
    lForm := TForm.Create(nil);
    lProbe := TWindowProcProbe.Create;
    lOriginalWindowProc := lForm.WindowProc;
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := '&Customer';
    lLabel.Parent := lForm;

    TAccessibilityManager.Install(lForm);
    lProbe.Prior := lForm.WindowProc;
    lForm.WindowProc := lProbe.WindowProc;

    TAccessibilityManager.Uninstall;
    Assert.IsTrue(lApi.DisconnectCalls > 0);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.LParam := UiaRootObjectId;
    lForm.WindowProc(lMessage);

    Assert.AreEqual(1, lProbe.Calls);
    Assert.AreEqual(0, lApi.ReturnCalls);
    Assert.AreEqual(0, lMessage.Result);
  finally
    if (lForm <> nil) and Assigned(lOriginalWindowProc) then
    begin
      lForm.WindowProc := lOriginalWindowProc;
    end;
    lForm.Free;
    ResetManager;
    lProbe.Free;
  end;
end;

procedure TAccessibilityManagerTests.DestroyedFormIsRemovedFromInstallState;
var
  lForm: TForm;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);

  lForm := TForm.Create(nil);
  TAccessibilityManager.Install(lForm);
  Assert.AreEqual(1, TAccessibilityManagerInternals.InstalledFormCount);
  lForm.Free;

  Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);
  ResetManager;
end;

procedure TAccessibilityManagerTests.InstallerFailureDoesNotMarkFormInstalled;
var
  lForm: TForm;
  lRaised: Boolean;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lRecorder := TFormInstallRecorder.Create;
  TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
  lForm := TForm.Create(nil);
  try
    lRecorder.FailNextInstall;
    lRaised := False;
    try
      TAccessibilityManager.Install(lForm);
    except
      on EInvalidOperation do
      begin
        lRaised := True;
      end;
    end;
    Assert.IsTrue(lRaised);

    Assert.AreEqual(0, lRecorder.CountFor(lForm));
    Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);

    TAccessibilityManager.Install(lForm);

    Assert.AreEqual(1, lRecorder.CountFor(lForm));
    Assert.AreEqual(1, TAccessibilityManagerInternals.InstalledFormCount);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.LaterHookStillCallsOriginalAfterManagerUninstallWithoutScanning;
var
  lExternalProbe: TChainedActiveFormChangeProbe;
  lForm: TForm;
  lOriginalActiveFormChange: TNotifyEvent;
  lOriginalProbe: TActiveFormChangeProbe;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lOriginalProbe := TActiveFormChangeProbe.Create;
  lExternalProbe := TChainedActiveFormChangeProbe.Create;
  lRecorder := TFormInstallRecorder.Create;
  try
    TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
    Screen.OnActiveFormChange := lOriginalProbe.HandleActiveFormChange;
    TAccessibilityManager.Install(Application);
    lExternalProbe.Prior := Screen.OnActiveFormChange;
    Screen.OnActiveFormChange := lExternalProbe.HandleActiveFormChange;

    TAccessibilityManager.Uninstall;
    lForm := TForm.Create(nil);
    try
      Screen.OnActiveFormChange(Screen);

      Assert.AreEqual(1, lExternalProbe.Calls);
      Assert.AreEqual(1, lOriginalProbe.Calls);
      Assert.AreEqual(0, lRecorder.CountFor(lForm));
    finally
      lForm.Free;
    end;
  finally
    Screen.OnActiveFormChange := lOriginalProbe.HandleActiveFormChange;
    TAccessibilityManager.Uninstall;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
    TAccessibilityManagerInternals.SetFormInstaller(nil);
    lExternalProbe.Free;
    lOriginalProbe.Free;
  end;
end;

procedure TAccessibilityManagerTests.UninstallRestoresOriginalActiveFormChangeHandler;
var
  lOriginalActiveFormChange: TNotifyEvent;
  lProbe: TActiveFormChangeProbe;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lProbe := TActiveFormChangeProbe.Create;
  lRecorder := TFormInstallRecorder.Create;
  try
    TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
    Screen.OnActiveFormChange := lProbe.HandleActiveFormChange;

    TAccessibilityManager.Install(Application);
    TAccessibilityManager.Uninstall;

    Assert.IsTrue(Assigned(Screen.OnActiveFormChange));
    Screen.OnActiveFormChange(Screen);
    Assert.AreEqual(1, lProbe.Calls);
  finally
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
    ResetManager;
    lProbe.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityManagerTests);

end.
