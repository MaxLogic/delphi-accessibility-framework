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
    [Category('T112Performance')]
    procedure ApplicationActiveFormChangeTouchesOnlyActiveFutureFormAtScale;
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
    procedure FormInstallWalksFrameworkProviderChildrenWithoutProviderNavigation;
    [Test]
    procedure FormInstallChildHookLookupScalesWithHookCount;
    [Test]
    procedure UninstallRetainsLaterHookedControlsWithoutLinearRetainedListScans;
    [Test]
    procedure FormInstallSkipsChildUiaGetObjectForUnpublishedLayoutProvider;
    [Test]
    procedure FormInstallHandlesChildContainerHitTestingForNonWindowedLabel;
    [Test]
    procedure FormInstallLeavesCheckBoxAndRadioButtonNativeGetObject;
    [Test]
    procedure FormInstallLeavesListBoxNativeGetObjectForNativeHwndSpeech;
    [Test]
    procedure FormInstallLeavesUnsupportedFocusableControlNativeGetObject;
    [Test]
    procedure FormInstallHandlesPageControlUiaGetObjectForTabHeaders;
    [Test]
    procedure FormInstallHandlesPageControlMsaaGetObjectForTabHeaders;
    [Test]
    [Category('Msaa')]
    procedure FormInstallReusesPageControlMsaaWrapperAndDisconnectsItOnUninstall;
    [Test]
    [Category('Msaa')]
    procedure FormInstallRoutesMsaaGetObjectWithoutEnteringUiaHandler;
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
    procedure FormInstallSkipsDuplicateFocusAnnouncementBuildForPairedFocusMessages;
    [Test]
    procedure FormInstallFocusAnnouncementUsesInProcessProviderProperties;
    [Test]
    procedure FormInstallRaisesInputMsaaFocusWinEventWithDefaultApi;
    [Test]
    procedure FormInstallRaisesPageControlTabHoverNotification;
    [Test]
    procedure FormInstallRaisesPageControlTabHoverNotificationFromFormMouseMove;
    [Test]
    procedure FormInstallSkipsPageControlHoverHitTestingWhenNoUiaClients;
    [Test]
    procedure FormInstallRaisesActiveTabSheetLabelHoverNotification;
    [Test]
    procedure FormInstallRaisesActiveTabSheetPanelLabelHoverNotification;
    [Test]
    procedure FormInstallRaisesMemoListBoxAndStatusBarHoverNotifications;
    [Test]
    procedure FormInstallCachesRepeatedLeafHoverHitTesting;
    [Test]
    procedure FormInstallCachesRepeatedBlankPanelHoverResolution;
    [Test]
    procedure FormInstallCachesRepeatedBlankFormHoverResolution;
    [Test]
    procedure FormInstallCachesRepeatedBlankGroupBoxHoverResolution;
    [Test]
    procedure FormInstallDoesNotCacheBlankHoverAcrossUnprovenVirtualChildren;
    [Test]
    procedure FormInstallKeepsBlankHoverCachedAcrossRepaint;
    [Test]
    procedure FormInstallKeepsSuccessfulHoverCachedAcrossRepaint;
    [Test]
    procedure FormInstallInvalidatesBlankPanelHoverCacheAfterChildGeometryChange;
    [Test]
    procedure FormInstallInvalidatesBlankPanelHoverCacheAfterAncestorMove;
    [Test]
    procedure FormInstallInvalidatesBlankPanelHoverCacheAfterSiblingFocusChange;
    [Test]
    procedure FormInstallInvalidatesBlankPanelHoverCacheAfterSemanticChanges;
    [Test]
    procedure UninstallPassivatesPopulatedBlankPanelHoverSnapshot;
    [Test]
    [Category('T114Performance')]
    procedure FormInstallHoverMissCacheLatencyDistribution;
    [Test]
    procedure FormInstallHoverUsesVclLookupForSimpleLeafProviders;
    [Test]
    procedure FormInstallRaisesWindowedButtonHoverNotificationAndKeepsCheckBoxNative;
    [Test]
    procedure FormInstallRaisesGroupBoxHoverAndRadioGroupItemHoverProviders;
    [Test]
    procedure DemoFormInstallRaisesViewModeGroupHoverFromGroupWindow;
    [Test]
    procedure DemoFormInstallRaisesDensityGroupHoverFromGroupWindow;
    [Test]
    procedure DemoFormInstallReturnsGroupProvidersFromGroupWindows;
    [Test]
    procedure FormInstallRaisesGroupBoxHoverFromNonClientMouseMove;
    [Test]
    procedure FormInstallIgnoresFormNonClientHoverWithoutRangeCheck;
    [Test]
    procedure FormInstallRaisesRadioGroupItemHoverFromButtonWindow;
    [Test]
    procedure FormInstallRaisesRadioGroupItemFocusNotificationFromButtonWindow;
    [Test]
    procedure FormInstallRaisesGroupedRadioButtonFocusNotificationWithFrameworkProvider;
    [Test]
    procedure FormInstallRaisesGroupedRadioButtonSelectionNotificationWithFrameworkProvider;
    [Test]
    procedure FormInstallRaisesGroupedRadioButtonArrowNavigationNotificationWithFrameworkProvider;
    [Test]
    procedure FormInstallSkipsGroupedRadioSelectionScanWhenNoUiaClients;
    [Test]
    procedure FormInstallRaisesRadioGroupItemArrowNavigationNotificationFromButtonWindow;
    [Test]
    procedure FormInstallReturnsGroupedRadioButtonProviderFromGroupBoxRadioWindow;
    [Test]
    procedure FormInstallBindsRadioGroupButtonWindowByControlIdentity;
    [Test]
    procedure FormInstallReturnsRadioGroupItemProviderFromButtonWindow;
    [Test]
    procedure DemoFormInstallRaisesRadioGroupItemHoverFromButtonWindow;
    [Test]
    procedure DemoFormInstallReturnsRadioGroupItemProviderFromButtonWindow;
    [Test]
    procedure FormInstallRaisesLazyRadioGroupItemHoverFromButtonWindow;
    [Test]
    procedure FormInstallCheckBoxHoverWithoutUiaClientsSkipsProviderBatch;
    [Test]
    procedure FormInstallCheckBoxHoverSkipsUnusedAnnouncementTextBuild;
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
    procedure FormInstallSkipsStringGridFocusTextWhenNoUiaClients;
    [Test]
    procedure FormInstallLeavesListBoxArrowKeySpeechToNativeWindow;
    [Test]
    procedure FormInstallTracksListBoxSelectionOncePerMutation;
    [Test]
    [Category('T113SelectionPerformance')]
    procedure FormInstallListBoxSelectionTrackingLatencyDistribution;
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
  System.Classes, System.Diagnostics, System.Generics.Collections, System.IOUtils, System.SysUtils, System.Types,
  System.Variants, Winapi.ActiveX, Winapi.Messages, Winapi.oleacc, Winapi.Windows, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, AdvGrid, AccessibilityDemoMainForm,
  MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner,
  MaxLogic.Accessibility.TmsAdvStringGridAdapters, MaxLogic.Accessibility.UIAutomationCore,
  MaxLogic.Accessibility.VclAdapters;

const
{$IFDEF RELEASE}
  cT114BuildConfiguration = 'Release';
{$ELSE}
  cT114BuildConfiguration = 'Debug';
{$ENDIF}
  cT114CaseCount = 4;
  cT114ChildCounts: array[0..Pred(cT114CaseCount)] of Integer = (0, 1, 32, 128);
  cT114SampleCount = 200;
  cT114WarmupCount = 20;

type
  TT114SampleCases = array[0..Pred(cT114CaseCount)] of TArray<Int64>;

  IFormInstallRecorder = interface(IAccessibilityFormInstaller)
    ['{89B798B7-0880-4AE5-B799-58E4EB14DF22}']
    function CountFor(aForm: TCustomForm): Integer;
    procedure FailNextInstall;
  end;

  IManagerTestUiaApi = interface(IAccessibilityUiaApi)
    ['{40F38FD9-3290-4894-A855-082E2884C0C1}']
    function ClientsAreListeningCalls: Integer;
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function LastHwnd: HWND;
    function LastEventId: EVENTID;
    function LastEventProvider: IRawElementProviderSimple;
    function LastLParam: LPARAM;
    function LastNotificationProcessing: NotificationProcessing;
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
    procedure ResetClientsAreListeningCalls;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  TManagerTestUiaApi = class(TInterfacedObject, IManagerTestUiaApi)
  private
    fClientsAreListening: Boolean;
    fClientsAreListeningCalls: Integer;
    fDisconnectCalls: Integer;
    fEventCalls: Integer;
    fLastEventId: EVENTID;
    fLastEventProvider: IRawElementProviderSimple;
    fLastHwnd: HWND;
    fLastLParam: LPARAM;
    fLastNotificationProcessing: NotificationProcessing;
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
    function ClientsAreListeningCalls: Integer;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function DisconnectCalls: Integer;
    function EventCalls: Integer;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastEventId: EVENTID;
    function LastEventProvider: IRawElementProviderSimple;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
    function LastNotificationProcessing: NotificationProcessing;
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
    procedure ResetClientsAreListeningCalls;
    function ReturnCalls: Integer;
    function ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple): LRESULT;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  TRadioNavigationTestHandler = class
  public
    TargetItemIndex: Integer;
    TargetRadio: TRadioButton;
    TargetRadioGroup: TRadioGroup;
    procedure SelectTargetRadio(aSender: TObject; var aKey: Word; aShift: TShiftState);
    procedure SelectTargetRadioGroupItem(aSender: TObject; var aKey: Word; aShift: TShiftState);
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

  TCheckedReadProbeRadioButton = class(TRadioButton)
  private
    class var fCheckedReadCount: Integer;
  protected
    function GetChecked: Boolean; override;
    procedure WndProc(var aMessage: TMessage); override;
  public
    class function CheckedReadCount: Integer; static;
    class procedure ResetCheckedReadCount; static;
  end;

  TNativeAccessibleProbeListBox = class(TListBox)
  private
    fGetObjectCalls: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    property GetObjectCalls: Integer read fGetObjectCalls;
  end;

  TSelectionReadProbeListBox = class(TListBox)
  private
    fBulkSelectionMessageCount: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    procedure ResetBulkSelectionMessageCount;
    property BulkSelectionMessageCount: Integer read fBulkSelectionMessageCount;
  end;

  TManagerListBoxFixture = record
    fApi: IManagerTestUiaApi;
    fCurrent: IRawElementProviderFragment;
    fForm: TForm;
    fListBox: TSelectionReadProbeListBox;
    fListBoxFragment: IRawElementProviderFragment;
  end;

  TManagerListBoxMeasurement = record
    fBulkSelectionMessageCount: Integer;
    fSamples: TArray<Int64>;
    fSelectedCount: Integer;
  end;

  TLyingRadioGroupAdapter = class(TInterfacedObject, IAccessibilityControlAdapter, IAccessibilityVclProviderAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TLyingRadioGroupProvider = class(TAccessibilityProviderRoot, IAccessibilityVclControlProviderInfo)
  private
    fControl: TRadioGroup;
  protected
    function DoElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment):
      HResult; override;
  public
    constructor Create(aRadioGroup: TRadioGroup; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    function Control: TControl;
  end;

  TTestVclControlProvider = class(TAccessibilityProviderNode, IAccessibilityVclControlProviderInfo)
  private
    fControl: TControl;
  public
    constructor Create(aControl: TControl; aRuntimeId: Integer; aControlTypeId: Integer; const aName: string;
      const aHelpText: string; const aApi: IAccessibilityUiaApi);
    function Control: TControl;
  end;

  TVirtualHoverPanelAdapter = class(TInterfacedObject, IAccessibilityControlAdapter,
    IAccessibilityVclProviderAdapter)
  public
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
    function CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
  end;

  TVirtualHoverChildProvider = class(TAccessibilityProviderNode)
  private
    fPanel: TCustomPanel;
  protected
    function DoGetBoundingRectangle(out aValue: UiaRect): Boolean; override;
  public
    constructor Create(aPanel: TCustomPanel; aRuntimeId: Integer; const aApi: IAccessibilityUiaApi);
  end;

  TVirtualHoverPanelProvider = class(TAccessibilityProviderRoot, IAccessibilityVclControlProviderInfo)
  private
    fPanel: TCustomPanel;
    fVirtualProvider: IAccessibilityProviderNode;
  protected
    function DoElementProviderFromPoint(aX: Double; aY: Double; out aProvider: IRawElementProviderFragment):
      HResult; override;
  public
    constructor Create(aPanel: TCustomPanel; aRuntimeId: Integer; const aName: string; const aHelpText: string;
      const aApi: IAccessibilityUiaApi);
    function Control: TControl;
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

class function TCheckedReadProbeRadioButton.CheckedReadCount: Integer;
begin
  Result := fCheckedReadCount;
end;

function TCheckedReadProbeRadioButton.GetChecked: Boolean;
begin
  Inc(fCheckedReadCount);
  Result := inherited GetChecked;
end;

procedure TCheckedReadProbeRadioButton.WndProc(var aMessage: TMessage);
begin
  if aMessage.Msg = WM_KEYDOWN then
  begin
    aMessage.Result := 0;
    Exit;
  end;

  inherited WndProc(aMessage);
end;

class procedure TCheckedReadProbeRadioButton.ResetCheckedReadCount;
begin
  fCheckedReadCount := 0;
end;

procedure TNativeAccessibleProbeListBox.WndProc(var aMessage: TMessage);
begin
  if aMessage.Msg = WM_GETOBJECT then
  begin
    Inc(fGetObjectCalls);
    aMessage.Result := 86420;
    Exit;
  end;

  inherited WndProc(aMessage);
end;

procedure TSelectionReadProbeListBox.ResetBulkSelectionMessageCount;
begin
  fBulkSelectionMessageCount := 0;
end;

procedure TSelectionReadProbeListBox.WndProc(var aMessage: TMessage);
begin
  if (aMessage.Msg = LB_GETSELCOUNT) or (aMessage.Msg = LB_GETSELITEMS) then
  begin
    Inc(fBulkSelectionMessageCount);
  end;
  inherited WndProc(aMessage);
end;

function TestProviderWindowHandle(aControl: TControl): HWND;
begin
  Result := 0;
  if aControl is TWinControl then
  begin
    Result := TWinControl(aControl).Handle;
  end;
end;

function TLyingRadioGroupAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  if aControl is TRadioGroup then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TLyingRadioGroupAdapter.CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Result := TLyingRadioGroupProvider.Create(TRadioGroup(aControl), aRuntimeId, aName, aHelpText, aApi) as
    IAccessibilityProviderNode;
end;

function TLyingRadioGroupProvider.Control: TControl;
begin
  Result := fControl;
end;

constructor TLyingRadioGroupProvider.Create(aRadioGroup: TRadioGroup; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi);
var
  i: Integer;
  lButton: TRadioButton;
  lProvider: IAccessibilityProviderNode;
begin
  aRadioGroup.HandleNeeded;
  inherited CreateNode([aRuntimeId], aRadioGroup.Handle, aApi, aRadioGroup);
  fControl := aRadioGroup;
  SetProperty(UIA_NamePropertyId, aName);
  SetProperty(UIA_ControlTypePropertyId, UIA_GroupControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aRadioGroup.ClassName);
  SetProperty(UIA_HelpTextPropertyId, aHelpText);
  SetProperty(UIA_NativeWindowHandlePropertyId, Integer(aRadioGroup.Handle));

  for i := 0 to Pred(aRadioGroup.Items.Count) do
  begin
    lButton := aRadioGroup.Buttons[i];
    lButton.HandleNeeded;
    lProvider := TTestVclControlProvider.Create(lButton, (aRuntimeId * 100) + i + 1,
      UIA_RadioButtonControlTypeId, aRadioGroup.Items[i], '', aApi) as IAccessibilityProviderNode;
    AddChild(lProvider);
  end;
end;

function TLyingRadioGroupProvider.DoElementProviderFromPoint(aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): HResult;
begin
  aProvider := Self as IRawElementProviderFragment;
  Result := S_OK;
end;

function TTestVclControlProvider.Control: TControl;
begin
  Result := fControl;
end;

constructor TTestVclControlProvider.Create(aControl: TControl; aRuntimeId: Integer; aControlTypeId: Integer;
  const aName: string; const aHelpText: string; const aApi: IAccessibilityUiaApi);
var
  lHwnd: HWND;
begin
  lHwnd := TestProviderWindowHandle(aControl);
  inherited CreateNode([aRuntimeId], lHwnd, aApi, aControl);
  fControl := aControl;
  SetProperty(UIA_NamePropertyId, aName);
  SetProperty(UIA_ControlTypePropertyId, aControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aControl.ClassName);
  SetProperty(UIA_HelpTextPropertyId, aHelpText);
  if lHwnd <> 0 then
  begin
    SetProperty(UIA_NativeWindowHandlePropertyId, Integer(lHwnd));
  end;
end;

function TVirtualHoverPanelAdapter.CreateInfo(aControl: TControl;
  const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
begin
  if aControl is TCustomPanel then
  begin
    Result := TAccessibilityControlInfo.Include(aControl, aFallback.Name, aFallback.HelpText);
  end else begin
    Result := TAccessibilityControlInfo.Omit;
  end;
end;

function TVirtualHoverPanelAdapter.CreateProvider(aControl: TControl; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi): IAccessibilityProviderNode;
begin
  Result := TVirtualHoverPanelProvider.Create(aControl as TCustomPanel, aRuntimeId, aName, aHelpText, aApi) as
    IAccessibilityProviderNode;
end;

constructor TVirtualHoverChildProvider.Create(aPanel: TCustomPanel; aRuntimeId: Integer;
  const aApi: IAccessibilityUiaApi);
begin
  inherited CreateNode([aRuntimeId], 0, aApi, aPanel);
  fPanel := aPanel;
  SetProperty(UIA_NamePropertyId, 'Virtual action');
  SetProperty(UIA_ControlTypePropertyId, UIA_TextControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, 'VirtualHoverChild');
end;

function TVirtualHoverChildProvider.DoGetBoundingRectangle(out aValue: UiaRect): Boolean;
var
  lPoint: TPoint;
begin
  Result := fPanel <> nil;
  if not Result then
  begin
    aValue := Default(UiaRect);
    Exit;
  end;

  lPoint := fPanel.ClientToScreen(Point(8, 8));
  aValue.Left := lPoint.X;
  aValue.Top := lPoint.Y;
  aValue.Width := 120;
  aValue.Height := 24;
end;

constructor TVirtualHoverPanelProvider.Create(aPanel: TCustomPanel; aRuntimeId: Integer; const aName: string;
  const aHelpText: string; const aApi: IAccessibilityUiaApi);
begin
  aPanel.HandleNeeded;
  inherited CreateNode([aRuntimeId], aPanel.Handle, aApi, aPanel);
  fPanel := aPanel;
  SetProperty(UIA_NamePropertyId, aName);
  SetProperty(UIA_ControlTypePropertyId, UIA_PaneControlTypeId);
  SetProperty(UIA_ClassNamePropertyId, aPanel.ClassName);
  SetProperty(UIA_HelpTextPropertyId, aHelpText);
  SetProperty(UIA_NativeWindowHandlePropertyId, Integer(aPanel.Handle));
  fVirtualProvider := TVirtualHoverChildProvider.Create(aPanel, (aRuntimeId * 100) + 1, aApi) as
    IAccessibilityProviderNode;
  AddChild(fVirtualProvider);
end;

function TVirtualHoverPanelProvider.Control: TControl;
begin
  Result := fPanel;
end;

function TVirtualHoverPanelProvider.DoElementProviderFromPoint(aX: Double; aY: Double;
  out aProvider: IRawElementProviderFragment): HResult;
var
  lPoint: TPoint;
begin
  lPoint := fPanel.ScreenToClient(Point(Round(aX), Round(aY)));
  if PtInRect(Rect(8, 8, 128, 32), lPoint) then
  begin
    aProvider := fVirtualProvider.FragmentProvider;
  end else begin
    aProvider := Self as IRawElementProviderFragment;
  end;
  Result := S_OK;
end;

procedure ResetManager;
begin
  TAccessibilityManager.Uninstall;
  TAccessibilityManagerInternals.SetFormInstaller(nil);
  TAccessibilityManagerInternals.SetUiaApi(nil);
  TAccessibilityManagerInternals.SetWinEventSink(nil);
end;

procedure AssertBlankHoverReResolved(aPanel: TCustomPanel; const aApi: IManagerTestUiaApi;
  const aPoint: TPoint; const aReason: string);
begin
  aApi.ResetClientsAreListeningCalls;
  aPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(aPoint));
  Assert.AreEqual(1, aApi.ClientsAreListeningCalls, aReason);
end;

procedure HideTestForm(aForm: TCustomForm);
begin
  if (aForm <> nil) and aForm.Visible then
  begin
    aForm.Hide;
    Application.ProcessMessages;
  end;
end;

function T112ArtifactFileName: string;
var
  lAgentsDir: string;
  lRunsDir: string;
begin
  lAgentsDir := TPath.Combine(GetCurrentDir, '.agents');
  lRunsDir := TPath.Combine(lAgentsDir, 'runs');
  ForceDirectories(lRunsDir);
  Result := TPath.Combine(lRunsDir, 't112-active-form-current.json');
end;

function T112MillisecondsFromTicks(aTicks: Int64): Double;
begin
  Result := (aTicks * 1000.0) / TStopwatch.Frequency;
end;

function T112NearestRankIndex(aSampleCount: Integer; aPercentile: Integer): Integer;
begin
  Result := (((aSampleCount * aPercentile) + 99) div 100) - 1;
end;

procedure WriteT112Artifact(const aSamples: TArray<Int64>; aInactiveFormCount: Integer;
  aFirstActivationTicks: Int64);
const
{$IFDEF RELEASE}
  cBuildConfiguration = 'Release';
{$ELSE}
  cBuildConfiguration = 'Debug';
{$ENDIF}
var
  lDiagnosticsState: string;
  lJson: string;
  lSampleCount: Integer;
begin
  lSampleCount := Length(aSamples);
  if TAccessibilityDiagnostics.Enabled then
  begin
    lDiagnosticsState := 'enabled';
  end else begin
    lDiagnosticsState := 'disabled';
  end;
  lJson := Format('{"scenario":"t112-active-form-change","phase":"warm-installed-active-form-callback",' +
    '"buildConfiguration":"%s","diagnosticsState":"%s","sampleCount":%d,"inactiveFormCount":%d,' +
    '"stopwatchFrequency":%d,"firstActivationTicks":%d,"firstActivationMs":%.6f,' +
    '"medianTicks":%d,"p95Ticks":%d,"p99Ticks":%d,"maximumTicks":%d,' +
    '"medianMs":%.6f,"p95Ms":%.6f,"p99Ms":%.6f,"maximumMs":%.6f}',
    [cBuildConfiguration, lDiagnosticsState, lSampleCount, aInactiveFormCount, TStopwatch.Frequency,
    aFirstActivationTicks, T112MillisecondsFromTicks(aFirstActivationTicks),
    aSamples[T112NearestRankIndex(lSampleCount, 50)], aSamples[T112NearestRankIndex(lSampleCount, 95)],
    aSamples[T112NearestRankIndex(lSampleCount, 99)], aSamples[Pred(lSampleCount)],
    T112MillisecondsFromTicks(aSamples[T112NearestRankIndex(lSampleCount, 50)]),
    T112MillisecondsFromTicks(aSamples[T112NearestRankIndex(lSampleCount, 95)]),
    T112MillisecondsFromTicks(aSamples[T112NearestRankIndex(lSampleCount, 99)]),
    T112MillisecondsFromTicks(aSamples[Pred(lSampleCount)])], TFormatSettings.Invariant);
  TFile.WriteAllText(T112ArtifactFileName, lJson, TEncoding.UTF8);
end;

function ActivateT112Form(aForm: TCustomForm): Int64;
var
  lStopwatch: TStopwatch;
begin
  lStopwatch := TStopwatch.StartNew;
  aForm.Show;
  Application.ProcessMessages;
  Result := lStopwatch.ElapsedTicks;
end;

function CountT112InstalledForms(const aRecorder: IFormInstallRecorder; const aForms: TArray<TForm>): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Pred(Length(aForms)) do
  begin
    if aRecorder.CountFor(aForms[i]) > 0 then
    begin
      Inc(Result);
    end;
  end;
end;

procedure CreateT112FutureForms(aOwner: TObjectList<TForm>; aInactiveFormCount: Integer;
  out aInactiveForms: TArray<TForm>; var aActiveForm: TForm);
var
  i: Integer;
begin
  SetLength(aInactiveForms, aInactiveFormCount);
  for i := 0 to Pred(aInactiveFormCount) do
  begin
    aInactiveForms[i] := TForm.Create(nil);
    aOwner.Add(aInactiveForms[i]);
  end;
  aActiveForm := TForm.Create(nil);
  aOwner.Add(aActiveForm);
end;

procedure MeasureT112ActiveFormChanges(aInactiveFormCount: Integer; aFirstActivationTicks: Int64);
const
  cSampleCount = 200;
var
  i: Integer;
  lSamples: TArray<Int64>;
  lStopwatch: TStopwatch;
begin
  SetLength(lSamples, cSampleCount);
  for i := 0 to Pred(cSampleCount) do
  begin
    lStopwatch := TStopwatch.StartNew;
    Screen.OnActiveFormChange(Screen);
    lSamples[i] := lStopwatch.ElapsedTicks;
  end;
  TArray.Sort<Int64>(lSamples);
  WriteT112Artifact(lSamples, aInactiveFormCount, aFirstActivationTicks);
end;

function TManagerTestUiaApi.ClientsAreListening: Boolean;
begin
  Inc(fClientsAreListeningCalls);
  Result := fClientsAreListening;
end;

function TManagerTestUiaApi.ClientsAreListeningCalls: Integer;
begin
  Result := fClientsAreListeningCalls;
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

function TManagerTestUiaApi.LastNotificationProcessing: NotificationProcessing;
begin
  Result := fLastNotificationProcessing;
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
  fLastNotificationProcessing := aNotificationProcessing;
  fLastNotificationProvider := aProvider;
  fLastNotificationText := aDisplayString;
  Result := S_OK;
end;

function TManagerTestUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Result := S_OK;
end;

procedure TManagerTestUiaApi.ResetClientsAreListeningCalls;
begin
  fClientsAreListeningCalls := 0;
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

procedure TRadioNavigationTestHandler.SelectTargetRadio(aSender: TObject; var aKey: Word; aShift: TShiftState);
begin
  if (aKey = VK_DOWN) and (TargetRadio <> nil) then
  begin
    TargetRadio.Checked := True;
  end;
end;

procedure TRadioNavigationTestHandler.SelectTargetRadioGroupItem(aSender: TObject; var aKey: Word;
  aShift: TShiftState);
begin
  if (aKey = VK_DOWN) and (TargetRadioGroup <> nil) then
  begin
    TargetRadioGroup.ItemIndex := TargetItemIndex;
  end;
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
var
  lResult: HResult;
begin
  lResult := aFragment.Navigate(aDirection, Result);
  Assert.IsTrue(lResult = S_OK, 'Fragment navigation failed.');
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

function ProviderNativeWindowHandle(const aFragment: IRawElementProviderFragment): HWND;
var
  lNativeWindow: IAccessibilityProviderNativeWindow;
begin
  Assert.IsTrue(Supports(aFragment, IAccessibilityProviderNativeWindow, lNativeWindow));
  Result := lNativeWindow.NativeWindowHandle;
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

function SameAccessibleIdentity(const aFirst: IAccessible; const aSecond: IAccessible): Boolean;
var
  lFirstIdentity: IUnknown;
  lSecondIdentity: IUnknown;
begin
  lFirstIdentity := aFirst as IUnknown;
  lSecondIdentity := aSecond as IUnknown;
  Result := Pointer(lFirstIdentity) = Pointer(lSecondIdentity);
end;

function RepeatedMsaaAccessibleFromControl(aControl: TWinControl): IAccessible;
const
  cObjIdClient = LPARAM(OBJID_CLIENT);
var
  lFirst: IAccessible;
  lResult: Winapi.Windows.LRESULT;
begin
  lResult := SendMessage(aControl.Handle, WM_GETOBJECT, 0, cObjIdClient);
  lFirst := AccessibleFromLResult(lResult, 0);
  lResult := SendMessage(aControl.Handle, WM_GETOBJECT, 0, cObjIdClient);
  Result := AccessibleFromLResult(lResult, 0);
  Assert.IsTrue(SameAccessibleIdentity(lFirst, Result),
    'Repeated OBJID_CLIENT requests should reuse one MSAA wrapper per provider hook.');
end;

procedure CreateManagerMsaaPageControlFixture(out aForm: TForm; out aPageControl: TPageControl;
  out aTab: TTabSheet);
begin
  aForm := TForm.Create(nil);
  try
    aForm.SetBounds(100, 100, 420, 260);
    aPageControl := TPageControl.Create(aForm);
    aPageControl.Parent := aForm;
    aPageControl.SetBounds(12, 12, 360, 200);
    aTab := TTabSheet.Create(aForm);
    aTab.Caption := 'Orders';
    aTab.PageControl := aPageControl;
    aPageControl.HandleNeeded;
  except
    aForm.Free;
    raise;
  end;
end;

procedure AssertMsaaAccessibleDisconnected(const aAccessible: IAccessible);
var
  lName: WideString;
begin
  Assert.AreEqual(S_FALSE, aAccessible.Get_accName(CHILDID_SELF, lName));
  Assert.AreEqual('', string(lName));
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

procedure AssertManagerMsaaPageControlTab(const aAccessible: IAccessible; aPageControl: TPageControl;
  aTab: TTabSheet);
var
  lPoint: TPoint;
  lState: Integer;
  lTabAccessible: IAccessible;
  lTabRect: TRect;
begin
  lTabRect := aPageControl.TabRect(aTab.TabIndex);
  lPoint := aPageControl.ClientToScreen(lTabRect.CenterPoint);
  lTabAccessible := AccessibleHitTestAt(aAccessible, lPoint);
  Assert.AreEqual('Orders', AccessibleName(lTabAccessible));
  Assert.AreEqual(ROLE_SYSTEM_PAGETAB, AccessibleRole(lTabAccessible));
  lState := AccessibleState(lTabAccessible);
  Assert.IsTrue((lState and STATE_SYSTEM_SELECTABLE) <> 0);
  Assert.IsTrue((lState and STATE_SYSTEM_SELECTED) <> 0);
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

procedure PopulateManagerListBox(aListBox: TSelectionReadProbeListBox; aSelectedCount: Integer);
const
  cItemCount = 600;
var
  i: Integer;
begin
  for i := 0 to Pred(cItemCount) do
  begin
    aListBox.Items.Add(Format('Client %.4d', [i]));
  end;
  for i := 0 to Pred(aSelectedCount) do
  begin
    aListBox.Selected[i] := True;
  end;
end;

procedure PrimeManagerListBoxSelection(const aListBoxFragment: IRawElementProviderFragment);
var
  lPattern: IUnknown;
  lSafeArray: PSafeArray;
  lSelection: ISelectionProvider;
begin
  lPattern := ProviderPattern(aListBoxFragment, UIA_SelectionPatternId);
  Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelection));
  lSafeArray := nil;
  Assert.AreEqual(S_OK, lSelection.GetSelection(lSafeArray));
  Assert.IsNotNull(lSafeArray);
  SafeArrayDestroy(lSafeArray);
end;

function CreateManagerListBoxFixture(aSelectedCount: Integer): TManagerListBoxFixture;
var
  lMessage: TMessage;
  lRoot: IRawElementProviderFragment;
begin
  Result := Default(TManagerListBoxFixture);
  ResetManager;
  Result.fApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(Result.fApi);
  Result.fForm := TForm.Create(nil);
  try
    Result.fListBox := TSelectionReadProbeListBox.Create(Result.fForm);
    Result.fListBox.Parent := Result.fForm;
    Result.fListBox.MultiSelect := True;
    Result.fListBox.SetBounds(16, 16, 280, 140);
    Result.fForm.HandleNeeded;
    Result.fListBox.HandleNeeded;
    PopulateManagerListBox(Result.fListBox, aSelectedCount);
    Result.fListBox.ItemIndex := 0;

    TAccessibilityManager.Install(Result.fForm);
    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 7;
    lMessage.LParam := UiaRootObjectId;
    Result.fForm.WindowProc(lMessage);
    Assert.IsNotNull(Result.fApi.ReturnedProvider);
    lRoot := FragmentFromSimple(Result.fApi.ReturnedProvider);
    Result.fListBoxFragment := FirstChildFragment(lRoot);
    PrimeManagerListBoxSelection(Result.fListBoxFragment);
    Result.fCurrent := FirstChildFragment(Result.fListBoxFragment);
  except
    Result.fForm.Free;
    Result.fForm := nil;
    ResetManager;
    raise;
  end;
end;

function MeasureManagerListBoxSiblingNavigation(aSelectedCount: Integer;
  aSampleCount: Integer): TManagerListBoxMeasurement;
var
  i: Integer;
  lElapsedTicks: Int64;
  lFixture: TManagerListBoxFixture;
  lNext: IRawElementProviderFragment;
  lStopwatch: TStopwatch;
begin
  Result := Default(TManagerListBoxMeasurement);
  Result.fSelectedCount := aSelectedCount;
  lFixture := CreateManagerListBoxFixture(aSelectedCount);
  try
    SetLength(Result.fSamples, aSampleCount);
    lFixture.fListBox.ResetBulkSelectionMessageCount;
    for i := 0 to Pred(aSampleCount) do
    begin
      lStopwatch := TStopwatch.StartNew;
      if Odd(i) then
      begin
        lNext := NavigateFragment(lFixture.fCurrent, NavigateDirection_PreviousSibling);
      end else begin
        lNext := NavigateFragment(lFixture.fCurrent, NavigateDirection_NextSibling);
      end;
      lElapsedTicks := lStopwatch.ElapsedTicks;
      if lElapsedTicks < 1 then
      begin
        lElapsedTicks := 1;
      end;
      Result.fSamples[i] := lElapsedTicks;
      Assert.IsNotNull(lNext);
      lFixture.fCurrent := lNext;
    end;
    Result.fBulkSelectionMessageCount := lFixture.fListBox.BulkSelectionMessageCount;
  finally
    lFixture.fForm.Free;
    ResetManager;
  end;
end;

procedure NavigateManagerListBox(var aFixture: TManagerListBoxFixture; aCount: Integer;
  const aContext: string);
var
  i: Integer;
  lNext: IRawElementProviderFragment;
begin
  for i := 1 to aCount do
  begin
    lNext := NavigateFragment(aFixture.fCurrent, NavigateDirection_NextSibling);
    Assert.IsNotNull(lNext, Format('%s traversal failed at step %d.', [aContext, i]));
    aFixture.fCurrent := lNext;
  end;
end;

procedure AssertManagerListBoxReconcilesOnce(var aFixture: TManagerListBoxFixture;
  const aContext: string);
begin
  aFixture.fListBox.ResetBulkSelectionMessageCount;
  NavigateManagerListBox(aFixture, 1, aContext + ' reconciliation');
  Assert.IsTrue((aFixture.fListBox.BulkSelectionMessageCount > 0) and
    (aFixture.fListBox.BulkSelectionMessageCount <= 2),
    Format('%s must trigger exactly one bulk refresh.', [aContext]));

  aFixture.fListBox.ResetBulkSelectionMessageCount;
  NavigateManagerListBox(aFixture, 10, aContext + ' stable follow-up');
  Assert.AreEqual(0, aFixture.fListBox.BulkSelectionMessageCount,
    Format('%s must leave stable traversal clean.', [aContext]));
end;

function TickCsvLine(const aSamples: TArray<Int64>): string;
var
  i: Integer;
  lBuilder: TStringBuilder;
begin
  lBuilder := TStringBuilder.Create;
  try
    for i := 0 to High(aSamples) do
    begin
      if i > 0 then
      begin
        lBuilder.Append(',');
      end;
      lBuilder.Append(aSamples[i]);
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

function CreateT114BenchmarkForm(aChildCount: Integer): TForm;
var
  i: Integer;
  lLabel: TLabel;
begin
  Result := TForm.Create(nil);
  try
    Result.SetBounds(100, 100, 460, 260);
    for i := 0 to Pred(aChildCount) do
    begin
      lLabel := TLabel.Create(Result);
      lLabel.Parent := Result;
      lLabel.Caption := 'Measured child ' + IntToStr(i);
      lLabel.SetBounds(250 + (i mod 4), 120 + (i mod 8), 150, 20);
    end;
    Result.Show;
  except
    Result.Free;
    raise;
  end;
end;

procedure WarmT114HoverMissCache(aForm: TCustomForm);
var
  i: Integer;
  lPoint: TPoint;
begin
  for i := 0 to Pred(cT114WarmupCount) do
  begin
    lPoint := Point(8 + (i mod 20), 8 + ((i div 20) mod 4));
    aForm.Perform(CM_CHANGED, 0, 0);
    aForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    aForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
  end;
end;

procedure MeasureT114HoverMissSamples(aForm: TCustomForm; const aApi: IManagerTestUiaApi;
  out aResolvedSamples: TArray<Int64>; out aCachedSamples: TArray<Int64>);
var
  i: Integer;
  lPoint: TPoint;
  lStopwatch: TStopwatch;
begin
  SetLength(aResolvedSamples, cT114SampleCount);
  SetLength(aCachedSamples, cT114SampleCount);
  aApi.ResetClientsAreListeningCalls;
  for i := 0 to Pred(cT114SampleCount) do
  begin
    lPoint := Point(8 + (i mod 20), 8 + ((i div 20) mod 4));
    if Odd(i) then
    begin
      aForm.Perform(CM_CHANGED, 0, 0);
      aForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
      lStopwatch := TStopwatch.StartNew;
      aForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
      aCachedSamples[i] := lStopwatch.ElapsedTicks;
      aForm.Perform(CM_CHANGED, 0, 0);
      lStopwatch := TStopwatch.StartNew;
      aForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
      aResolvedSamples[i] := lStopwatch.ElapsedTicks;
    end else begin
      aForm.Perform(CM_CHANGED, 0, 0);
      lStopwatch := TStopwatch.StartNew;
      aForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
      aResolvedSamples[i] := lStopwatch.ElapsedTicks;
      lStopwatch := TStopwatch.StartNew;
      aForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
      aCachedSamples[i] := lStopwatch.ElapsedTicks;
    end;
  end;
end;

procedure MeasureT114HoverMissCase(const aApi: IManagerTestUiaApi; aChildCount: Integer;
  out aResolvedSamples: TArray<Int64>; out aCachedSamples: TArray<Int64>);
var
  lExpectedResolutionCalls: Integer;
  lForm: TForm;
begin
  ResetManager;
  TAccessibilityManagerInternals.SetUiaApi(aApi);
  lForm := CreateT114BenchmarkForm(aChildCount);
  try
    TAccessibilityManager.Install(lForm);
    lForm.Update;
    WarmT114HoverMissCache(lForm);
    MeasureT114HoverMissSamples(lForm, aApi, aResolvedSamples, aCachedSamples);
    lExpectedResolutionCalls := cT114SampleCount + (cT114SampleCount div 2);
    Assert.AreEqual(lExpectedResolutionCalls, aApi.ClientsAreListeningCalls,
      Format('Child count %d must resolve once per measured pair plus cached-first preparation.', [aChildCount]));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

function T114DiagnosticsState: string;
begin
  if TAccessibilityDiagnostics.Enabled then
  begin
    Result := 'enabled';
  end else begin
    Result := 'disabled';
  end;
end;

function BuildT114HoverMissCsv(const aResolvedSamples: TT114SampleCases;
  const aCachedSamples: TT114SampleCases): string;
var
  i: Integer;
  lBuilder: TStringBuilder;
begin
  lBuilder := TStringBuilder.Create;
  try
    lBuilder.Append(Format('sampleCountPerMode=%d,warmupCount=%d,frequency=%d,build=%s,diagnostics=%s%s',
      [cT114SampleCount, cT114WarmupCount, TStopwatch.Frequency, cT114BuildConfiguration,
      T114DiagnosticsState, sLineBreak]));
    for i := 0 to Pred(cT114CaseCount) do
    begin
      lBuilder.Append(Format('childCount=%d,mode=resolved,', [cT114ChildCounts[i]]));
      lBuilder.Append(TickCsvLine(aResolvedSamples[i]));
      lBuilder.Append(sLineBreak);
      lBuilder.Append(Format('childCount=%d,mode=cached,', [cT114ChildCounts[i]]));
      lBuilder.Append(TickCsvLine(aCachedSamples[i]));
      lBuilder.Append(sLineBreak);
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
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
  lCallsBefore: Integer;
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

      lForm.Show;
      Application.ProcessMessages;
      lCallsBefore := lProbe.Calls;
      Screen.OnActiveFormChange(Screen);

      Assert.AreEqual(Succ(lCallsBefore), lProbe.Calls);
      Assert.AreEqual(1, lRecorder.CountFor(lForm));
    finally
      HideTestForm(lForm);
      lForm.Free;
    end;
  finally
    ResetManager;
    Screen.OnActiveFormChange := lOriginalActiveFormChange;
    lProbe.Free;
  end;
end;

procedure TAccessibilityManagerTests.ApplicationActiveFormChangeTouchesOnlyActiveFutureFormAtScale;
const
  cInactiveFormCount = 100;
var
  lActiveForm: TForm;
  lFirstActivationTicks: Int64;
  lForms: TObjectList<TForm>;
  lInactiveForms: TArray<TForm>;
  lOriginalActiveFormChange: TNotifyEvent;
  lProbe: TActiveFormChangeProbe;
  lRecorder: IFormInstallRecorder;
begin
  ResetManager;
  lActiveForm := nil;
  lOriginalActiveFormChange := Screen.OnActiveFormChange;
  lProbe := TActiveFormChangeProbe.Create;
  lForms := TObjectList<TForm>.Create(True);
  try
    lRecorder := TFormInstallRecorder.Create;
    TAccessibilityManagerInternals.SetFormInstaller(lRecorder);
    Screen.OnActiveFormChange := lProbe.HandleActiveFormChange;
    TAccessibilityManager.Install(Application);

    CreateT112FutureForms(lForms, cInactiveFormCount, lInactiveForms, lActiveForm);
    lFirstActivationTicks := ActivateT112Form(lActiveForm);
    Assert.AreSame(lActiveForm, Screen.ActiveCustomForm, 'The scaling fixture did not activate its target form.');

    MeasureT112ActiveFormChanges(cInactiveFormCount, lFirstActivationTicks);

    Assert.AreEqual(0, CountT112InstalledForms(lRecorder, lInactiveForms),
      'An active-form event installed inactive future forms.');
    Assert.AreEqual(1, lRecorder.CountFor(lActiveForm), 'The active future form was not installed exactly once.');
  finally
    ResetManager;
    HideTestForm(lActiveForm);
    lForms.Free;
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

      lForm.Show;
      Application.ProcessMessages;
      Screen.OnActiveFormChange(Screen);

      Assert.IsTrue(TAccessibilityManagerInternals.InstalledFormCount >= 1);
      AssertManagerGridCellName(lApi, lForm, 'Alice');
    finally
      HideTestForm(lForm);
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

    lFutureForm.Show;
    Application.ProcessMessages;
    Screen.OnActiveFormChange(Screen);

    Assert.IsTrue(TAccessibilityManagerInternals.InstalledFormCount >= 3,
      'App-wide demo enable must discover future demo forms.');
  finally
    if DemoAccessibilityFrameworkEnabled then
    begin
      SetDemoAccessibilityFrameworkEnabled(False);
    end;
    HideTestForm(lFutureForm);
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
      HideTestForm(lForm);
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

      lForm.Show;
      Application.ProcessMessages;
      Screen.OnActiveFormChange(Screen);
      AssertManagerGridCellName(lApi, lForm, '<b>Alice</b>');
    finally
      HideTestForm(lForm);
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
  lForm: TForm;
  lMessage: TMessage;
  lStatusBar: TStatusBar;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lStatusBar := TStatusBar.Create(lForm);
    lStatusBar.Parent := lForm;
    lStatusBar.SimplePanel := True;
    lStatusBar.SimpleText := 'Ready';
    lStatusBar.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 11;
    lMessage.LParam := UiaRootObjectId;
    lStatusBar.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(lStatusBar.Handle, lApi.LastHwnd);
    Assert.IsNotNull(lApi.ReturnedProvider);
    Assert.AreEqual(UIA_StatusBarControlTypeId, ProviderIntProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_ControlTypePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallWalksFrameworkProviderChildrenWithoutProviderNavigation;
var
  i: Integer;
  lApi: IManagerTestUiaApi;
  lEdit: TEdit;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPanel: TPanel;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 360);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := 'Settings';
    lPanel.SetBounds(16, 16, 260, 300);
    lPanel.HandleNeeded;

    for i := 0 to 11 do
    begin
      lEdit := TEdit.Create(lForm);
      lEdit.Parent := lPanel;
      lEdit.Text := 'Value';
      lEdit.SetBounds(12, 16 + i * 23, 180, 21);
      lEdit.HandleNeeded;
    end;

    TAccessibilityManager.Install(lForm);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
      'Form install should walk framework-owned provider children through direct in-process child access.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallChildHookLookupScalesWithHookCount;
const
  cControlCount = 120;
var
  i: Integer;
  lButton: TButton;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  ResetManager;
  lForm := TForm.Create(nil);
  try
    for i := 0 to Pred(cControlCount) do
    begin
      lButton := TButton.Create(lForm);
      lButton.Parent := lForm;
      lButton.Name := 'Button' + IntToStr(i);
      lButton.Caption := 'Button ' + IntToStr(i);
    end;

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    TAccessibilityManager.Install(lForm);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.IsTrue(lMetrics.ManagerHookLookupCount >= cControlCount,
      'The fixture must exercise child hook lookup during install.');
    Assert.IsTrue(lMetrics.ManagerHookLookupProbeCount <= lMetrics.ManagerHookLookupCount + cControlCount,
      Format('Child hook lookup should stay linear on large forms; %d lookups used %d probes.',
      [lMetrics.ManagerHookLookupCount, lMetrics.ManagerHookLookupProbeCount]));
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.UninstallRetainsLaterHookedControlsWithoutLinearRetainedListScans;
const
  cControlCount = 80;
var
  i: Integer;
  lButton: TButton;
  lControl: TWinControl;
  lControls: TList<TWinControl>;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lOriginalControlWindowProcs: TArray<TWndMethod>;
  lOriginalFormWindowProc: TWndMethod;
  lProbe: TWindowProcProbe;
  lWindowProcsReplaced: Boolean;
begin
  ResetManager;
  lControls := TList<TWinControl>.Create;
  lForm := TForm.Create(nil);
  lProbe := TWindowProcProbe.Create;
  lOriginalControlWindowProcs := nil;
  lOriginalFormWindowProc := nil;
  lWindowProcsReplaced := False;
  try
    for i := 0 to Pred(cControlCount) do
    begin
      lButton := TButton.Create(lForm);
      lButton.Parent := lForm;
      lButton.Name := 'Button' + IntToStr(i);
      lButton.Caption := 'Button ' + IntToStr(i);
      lButton.HandleNeeded;
      lControls.Add(lButton);
    end;

    lOriginalFormWindowProc := lForm.WindowProc;
    SetLength(lOriginalControlWindowProcs, lControls.Count);
    for i := 0 to Pred(lControls.Count) do
    begin
      lOriginalControlWindowProcs[i] := lControls[i].WindowProc;
    end;

    TAccessibilityManager.Install(lForm);
    lForm.WindowProc := lProbe.WindowProc;
    for lControl in lControls do
    begin
      lControl.WindowProc := lProbe.WindowProc;
    end;
    lWindowProcsReplaced := True;

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    TAccessibilityManager.Uninstall;
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    lForm.WindowProc := lOriginalFormWindowProc;
    for i := 0 to Pred(lControls.Count) do
    begin
      lControls[i].WindowProc := lOriginalControlWindowProcs[i];
    end;
    lWindowProcsReplaced := False;

    Assert.IsTrue(lMetrics.ManagerRetainedHookPassivateCount >= cControlCount,
      'The fixture must passivate later-hooked child controls.');
    Assert.AreEqual(0, lMetrics.ManagerRetainedHookLinearScanCount,
      'Retaining passivated hooks should be idempotent without scanning the retained hook list per control.');
  finally
    if lWindowProcsReplaced then
    begin
      lForm.WindowProc := lOriginalFormWindowProc;
      for i := 0 to Pred(lControls.Count) do
      begin
        lControls[i].WindowProc := lOriginalControlWindowProcs[i];
      end;
    end;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lProbe.Free;
    lForm.Free;
    lControls.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallSkipsChildUiaGetObjectForUnpublishedLayoutProvider;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lMessage: TMessage;
  lPanel: TPanel;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := 'Layout panel';
    lPanel.HandleNeeded;

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lPanel;
    lLabel.Caption := 'Nested label';

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 13;
    lMessage.LParam := UiaRootObjectId;
    lPanel.WindowProc(lMessage);

    Assert.AreEqual(0, Integer(lMessage.Result));
    Assert.AreEqual(0, lApi.ReturnCalls);
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
    lForm.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(lForm.Handle, lApi.LastHwnd);
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

procedure TAccessibilityManagerTests.FormInstallLeavesListBoxNativeGetObjectForNativeHwndSpeech;
const
  cObjIdClient = LPARAM(OBJID_CLIENT);
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lListBox: TNativeAccessibleProbeListBox;
  lMessage: TMessage;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 320, 200);

    lListBox := TNativeAccessibleProbeListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.Name := 'Events';
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Completed action');
    lListBox.SetBounds(24, 24, 220, 80);
    lListBox.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 19;
    lMessage.LParam := UiaRootObjectId;
    lListBox.WindowProc(lMessage);

    Assert.AreEqual(86420, Integer(lMessage.Result));
    Assert.AreEqual(1, lListBox.GetObjectCalls);
    Assert.AreEqual(0, lApi.ReturnCalls);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 19;
    lMessage.LParam := cObjIdClient;
    lListBox.WindowProc(lMessage);

    Assert.AreEqual(86420, Integer(lMessage.Result));
    Assert.AreEqual(2, lListBox.GetObjectCalls);
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

procedure TAccessibilityManagerTests.FormInstallReusesPageControlMsaaWrapperAndDisconnectsItOnUninstall;
var
  lAccessible: IAccessible;
  lCoInit: HRESULT;
  lPageControl: TPageControl;
  lTab: TTabSheet;
  lForm: TForm;
begin
  ResetManager;
  lCoInit := CoInitialize(nil);
  CreateManagerMsaaPageControlFixture(lForm, lPageControl, lTab);
  try
    Assert.IsTrue((lCoInit = S_OK) or (lCoInit = S_FALSE) or (lCoInit = RPC_E_CHANGED_MODE));
    TAccessibilityManager.Install(lForm);
    lAccessible := RepeatedMsaaAccessibleFromControl(lPageControl);
    AssertManagerMsaaPageControlTab(lAccessible, lPageControl, lTab);
    TAccessibilityManager.Uninstall;
    AssertMsaaAccessibleDisconnected(lAccessible);
  finally
    lAccessible := nil;
    lForm.Free;
    if (lCoInit = S_OK) or (lCoInit = S_FALSE) then
    begin
      CoUninitialize;
    end;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRoutesMsaaGetObjectWithoutEnteringUiaHandler;
var
  lAccessible: IAccessible;
  lCoInit: HRESULT;
  lForm: TForm;
  lLogFile: string;
  lLogText: string;
begin
  ResetManager;
  TAccessibilityDiagnostics.Disable;
  lCoInit := CoInitialize(nil);
  lLogFile := TPath.GetTempFileName;
  lForm := TForm.Create(nil);
  try
    Assert.IsTrue((lCoInit = S_OK) or (lCoInit = S_FALSE) or (lCoInit = RPC_E_CHANGED_MODE));
    TAccessibilityDiagnostics.Configure(lLogFile);
    TAccessibilityManager.Install(lForm);
    lAccessible := RepeatedMsaaAccessibleFromControl(lForm);
    Assert.IsNotNull(lAccessible);
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.FlushLog(5000), 'Diagnostics did not become idle.');
    TAccessibilityDiagnostics.Disable;
    lLogText := TFile.ReadAllText(lLogFile, TEncoding.UTF8);
    Assert.DoesNotContain(lLogText, 'WM_GETOBJECT ignored',
      'OBJID_CLIENT must route directly to MSAA without entering the UIA handler.');
  finally
    TAccessibilityDiagnostics.Disable;
    lForm.Free;
    ResetManager;
    TFile.Delete(lLogFile);
    lAccessible := nil;
    if (lCoInit = S_OK) or (lCoInit = S_FALSE) then
    begin
      CoUninitialize;
    end;
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
    Assert.AreEqual(Integer(lEdit.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.LastNotificationProvider))));
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
    Assert.AreEqual(Integer(lEdit.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.LastEventProvider))));
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
    Assert.AreEqual(Integer(lCombo.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.LastEventProvider))));
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
    Assert.AreEqual(Integer(lLabeledEdit.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.LastEventProvider))));
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
    Assert.AreEqual(Integer(lEdit.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.LastNotificationProvider))));
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

procedure TAccessibilityManagerTests.FormInstallSkipsDuplicateFocusAnnouncementBuildForPairedFocusMessages;
var
  lApi: IManagerTestUiaApi;
  lEdit: TEdit;
  lEditLabel: TLabel;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 140);

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

    TAccessibilityManager.Install(lForm);
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lEdit.Perform(CM_ENTER, 0, 0);
    lEdit.Perform(WM_SETFOCUS, 0, 0);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Customer Alice. Search demo orders and audit findings', lApi.LastNotificationText);
    Assert.AreEqual(1, lMetrics.ProviderFocusAnnouncementTextCount,
      'Paired focus messages should not rebuild the same speech text after the first notification was cached.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallFocusAnnouncementUsesInProcessProviderProperties;
var
  lApi: IManagerTestUiaApi;
  lEdit: TEdit;
  lEditLabel: TLabel;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 140);

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

    TAccessibilityManager.Install(lForm);
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lEdit.Perform(CM_ENTER, 0, 0);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Customer Alice. Search demo orders and audit findings', lApi.LastNotificationText);
    Assert.AreEqual(1, lMetrics.ProviderFocusAnnouncementTextCount);
    Assert.AreEqual(1, lMetrics.ProviderFocusAnnouncementDetailProbeCount,
      'Focus speech should read provider speech properties through one in-process batch.');
    Assert.AreEqual(0, lMetrics.ProviderGetPropertyValueCount,
      'Focus speech should read our in-process provider properties directly.');
    Assert.AreEqual(0, lMetrics.ProviderGetPatternProviderCount,
      'Focus speech should read our in-process provider patterns directly.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
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

procedure TAccessibilityManagerTests.FormInstallSkipsPageControlHoverHitTestingWhenNoUiaClients;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lTabOrders: TTabSheet;
  lTabRect: TRect;
  lTabTms: TTabSheet;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(False);
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lPoint := lTabRect.CenterPoint;
    lPageControl.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.AreEqual(0, lApi.EventCalls);
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(0, lMetrics.ProviderRootElementProviderFromPointCount,
      'Hover should skip provider hit-testing when no UIA clients are listening.');
    Assert.AreEqual(0, lMetrics.ProviderEventBatchCount,
      'Silent hover should not open provider event batches when no UIA clients are listening.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
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
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lMouseParam: LPARAM;
  lPoint: TPoint;
  lProviderName: string;
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lCharIndex := lMemo.Perform(EM_LINEINDEX, 1, 0);
    lLinePoint := PointFromMessageResult(lMemo.Perform(EM_POSFROMCHAR, lCharIndex, 0));
    lMouseParam := PointToMouseLParam(Point(lLinePoint.X + 4, lLinePoint.Y + 2));
    lMemo.Perform(WM_MOUSEMOVE, 0, lMouseParam);
    Assert.IsTrue(lApi.NotificationCalls = 1, 'Memo hover notification count mismatch.');
    Assert.AreEqual('Second memo line', lApi.LastNotificationText);
    lProviderName := ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider), UIA_NamePropertyId);
    Assert.AreEqual('Second memo line', lProviderName);

    lItemRect := lListBox.ItemRect(2);
    lPoint := lItemRect.CenterPoint;
    lMouseParam := PointToLParam(lPoint);
    lListBox.Perform(WM_MOUSEMOVE, 0, lMouseParam);
    Assert.IsTrue(lApi.NotificationCalls = 2, 'Listbox hover notification count mismatch.');
    Assert.AreEqual('Completed action', lApi.LastNotificationText);
    lProviderName := ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider), UIA_NamePropertyId);
    Assert.AreEqual('Completed action', lProviderName);

    lMouseParam := PointToLParam(Point(8, 8));
    lStatusBar.Perform(WM_MOUSEMOVE, 0, lMouseParam);
    Assert.IsTrue(lApi.NotificationCalls = 3, 'Statusbar hover notification count mismatch.');
    Assert.AreEqual('Ready. High severity checks: 4', lApi.LastNotificationText);
    lProviderName := ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider), UIA_NamePropertyId);
    Assert.AreEqual('Ready. High severity checks: 4', lProviderName);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lMetrics.ProviderGetBoundingRectangleCount,
      'Virtual hover cache bounds should use direct provider geometry, not UIA bounding rectangle callbacks.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallCachesRepeatedLeafHoverHitTesting;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lMouseParam: LPARAM;
  lNextLabel: TLabel;
  lNextMouseParam: LPARAM;
  lPoint: TPoint;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lForm;
    lLabel.Caption := 'Audit warning';
    lLabel.SetBounds(20, 20, 180, 24);

    lNextLabel := TLabel.Create(lForm);
    lNextLabel.Parent := lForm;
    lNextLabel.Caption := 'Completed action';
    lNextLabel.SetBounds(20, 60, 180, 24);

    TAccessibilityManager.Install(lForm);
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lApi.ResetClientsAreListeningCalls;

    lPoint := lForm.ScreenToClient(ControlScreenCenter(lLabel));
    lMouseParam := PointToLParam(lPoint);
    lForm.Perform(WM_MOUSEMOVE, 0, lMouseParam);
    lForm.Perform(WM_MOUSEMOVE, 0, lMouseParam);
    lForm.Perform(WM_MOUSEMOVE, 0, lMouseParam);
    lForm.Perform(WM_MOUSEMOVE, 0, lMouseParam);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Audit warning', lApi.LastNotificationText);

    lPoint := lForm.ScreenToClient(ControlScreenCenter(lNextLabel));
    lNextMouseParam := PointToLParam(lPoint);
    lForm.Perform(WM_MOUSEMOVE, 0, lNextMouseParam);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.AreEqual(2, lApi.NotificationCalls);
    Assert.AreEqual('Completed action', lApi.LastNotificationText);
    Assert.AreEqual(2, lApi.ClientsAreListeningCalls,
      'Repeated form-level hover should probe UIA client-listening state only for actual hover announcements.');
    Assert.IsTrue(lMetrics.ProviderRootElementProviderFromPointCount <= 2,
      Format('Repeated hover should not re-hit-test the same leaf provider; root hit tests=%d.',
      [lMetrics.ProviderRootElementProviderFromPointCount]));
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallCachesRepeatedBlankPanelHoverResolution;
const
  cMoveCount = 100;
var
  i: Integer;
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lPanel: TPanel;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lPanel;
    lLabel.Caption := 'Completed action';
    lLabel.SetBounds(170, 46, 110, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;
    lApi.ResetClientsAreListeningCalls;

    for i := 0 to Pred(cMoveCount) do
    begin
      lPoint := Point(8 + (i mod 20), 8 + ((i div 20) mod 4));
      lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    end;

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      Format('%d moves in one blank panel region must perform one hover resolution.', [cMoveCount]));

    lPoint := Point(lLabel.Left + (lLabel.Width div 2), lLabel.Top + (lLabel.Height div 2));
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Completed action', lApi.LastNotificationText);
    Assert.AreEqual(2, lApi.ClientsAreListeningCalls,
      'Crossing into a named control must resolve and raise hover semantics immediately.');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallCachesRepeatedBlankFormHoverResolution;
const
  cMoveCount = 100;
var
  i: Integer;
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lForm;
    lLabel.Caption := 'Form action';
    lLabel.SetBounds(220, 80, 100, 24);

    lForm.Show;
    TAccessibilityManager.Install(lForm);
    lForm.Update;
    lApi.ResetClientsAreListeningCalls;

    for i := 0 to Pred(cMoveCount) do
    begin
      lPoint := Point(8 + (i mod 20), 8 + ((i div 20) mod 4));
      lForm.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    end;

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      Format('%d moves in one blank form region must perform one hover resolution.', [cMoveCount]));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallCachesRepeatedBlankGroupBoxHoverResolution;
const
  cMoveCount = 100;
var
  i: Integer;
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lLabel: TLabel;
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
    lGroupBox.Caption := '';
    lGroupBox.SetBounds(20, 20, 300, 120);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lGroupBox;
    lLabel.Caption := 'Group action';
    lLabel.SetBounds(170, 46, 110, 24);

    lForm.Show;
    lGroupBox.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lGroupBox.Update;
    lApi.ResetClientsAreListeningCalls;

    for i := 0 to Pred(cMoveCount) do
    begin
      lPoint := Point(8 + (i mod 20), 8 + ((i div 20) mod 4));
      lGroupBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    end;

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      Format('%d moves in one blank group-box region must perform one hover resolution.', [cMoveCount]));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallDoesNotCacheBlankHoverAcrossUnprovenVirtualChildren;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lPanel: TPanel;
  lRegistry: IAccessibilityAdapterRegistry;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lRegistry := TAccessibilityVclAdapters.CreateDefaultRegistry;
  lRegistry.RegisterAdapter(TPanel, TVirtualHoverPanelAdapter.Create);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lForm.Show;
    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm, lRegistry);
    lPanel.Update;
    lApi.ResetClientsAreListeningCalls;

    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(200, 80)));
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls);

    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(20, 20)));

    Assert.AreEqual(2, lApi.ClientsAreListeningCalls,
      'A provider without a VCL-complete hover capability must resolve each point.');
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Virtual action', lApi.LastNotificationText);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallKeepsBlankHoverCachedAcrossRepaint;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lPanel: TPanel;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lPanel;
    lLabel.Caption := 'Stable action';
    lLabel.SetBounds(170, 46, 110, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;
    lApi.ResetClientsAreListeningCalls;

    lPoint := Point(12, 12);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls);

    lPanel.Perform(WM_PAINT, 0, 0);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    lPanel.Perform(CM_INVALIDATE, 0, 0);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      'Pure paint and invalidate messages must preserve a stable blank-region hover miss.');
    Assert.AreEqual(0, lApi.NotificationCalls);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallKeepsSuccessfulHoverCachedAcrossRepaint;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lPanel: TPanel;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lPanel;
    lLabel.Caption := 'Stable action';
    lLabel.SetBounds(20, 20, 110, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;

    lPoint := Point(lLabel.Left + (lLabel.Width div 2), lLabel.Top + (lLabel.Height div 2));
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    Assert.AreEqual(1, lApi.NotificationCalls);

    lPanel.Perform(WM_PAINT, 0, 0);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.NotificationCalls,
      'A purely visual repaint must not duplicate the successful hover announcement.');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallInvalidatesBlankPanelHoverCacheAfterChildGeometryChange;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lPanel: TPanel;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lPanel;
    lLabel.Caption := 'Moved action';
    lLabel.SetBounds(170, 46, 110, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;
    lApi.ResetClientsAreListeningCalls;

    lPoint := Point(12, 12);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls);
    Assert.AreEqual(0, lApi.NotificationCalls);

    lLabel.SetBounds(4, 4, 110, 24);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(2, lApi.ClientsAreListeningCalls,
      'Moving a child into a cached blank region must invalidate the hover miss.');
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Moved action', lApi.LastNotificationText);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallInvalidatesBlankPanelHoverCacheAfterAncestorMove;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lPanel: TPanel;
  lPoint: TPoint;
  lScreenPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(300, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lPanel;
    lLabel.Caption := 'Moved ancestor action';
    lLabel.SetBounds(170, 46, 110, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;
    lApi.ResetClientsAreListeningCalls;

    lPoint := Point(12, 12);
    lScreenPoint := lPanel.ClientToScreen(lPoint);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls);
    Assert.AreEqual(0, lApi.NotificationCalls);

    Assert.IsTrue(SetWindowPos(lForm.Handle, 0,
      lForm.Left - (lLabel.Left + (lLabel.Width div 2) - lPoint.X),
      lForm.Top - (lLabel.Top + (lLabel.Height div 2) - lPoint.Y), 0, 0,
      SWP_NOACTIVATE or SWP_NOREDRAW or SWP_NOSIZE or SWP_NOZORDER));
    lPoint := lPanel.ScreenToClient(lScreenPoint);
    Assert.IsTrue(PtInRect(lLabel.BoundsRect, lPoint),
      'The ancestor move must place the label beneath the stationary screen point.');

    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(2, lApi.ClientsAreListeningCalls,
      'An ancestor move must invalidate a cached blank region expressed in screen coordinates.');
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Moved ancestor action', lApi.LastNotificationText);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallInvalidatesBlankPanelHoverCacheAfterSiblingFocusChange;
var
  lApi: IManagerTestUiaApi;
  lFirstEdit: TEdit;
  lForm: TForm;
  lPanel: TPanel;
  lPoint: TPoint;
  lSecondEdit: TEdit;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lFirstEdit := TEdit.Create(lForm);
    lFirstEdit.Parent := lPanel;
    lFirstEdit.SetBounds(150, 12, 120, 24);

    lSecondEdit := TEdit.Create(lForm);
    lSecondEdit.Parent := lPanel;
    lSecondEdit.SetBounds(150, 54, 120, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    lFirstEdit.HandleNeeded;
    lSecondEdit.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;
    lFirstEdit.SetFocus;
    Assert.IsTrue(lFirstEdit.Focused);
    lApi.ResetClientsAreListeningCalls;

    lPoint := Point(12, 12);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls);

    lSecondEdit.SetFocus;
    Assert.IsTrue(lSecondEdit.Focused);
    lApi.ResetClientsAreListeningCalls;
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      'A real sibling focus transition must invalidate the parent panel hover miss.');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallInvalidatesBlankPanelHoverCacheAfterSemanticChanges;
var
  lAnchorLabel: TLabel;
  lApi: IManagerTestUiaApi;
  lExtraLabel: TLabel;
  lForm: TForm;
  lPanel: TPanel;
  lPoint: TPoint;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lAnchorLabel := TLabel.Create(lForm);
    lAnchorLabel.Parent := lPanel;
    lAnchorLabel.Caption := 'Anchor action';
    lAnchorLabel.SetBounds(170, 46, 110, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;
    lApi.ResetClientsAreListeningCalls;

    lPoint := Point(12, 12);
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls);

    lExtraLabel := TLabel.Create(lForm);
    lExtraLabel.Visible := False;
    lExtraLabel.Parent := lPanel;
    AssertBlankHoverReResolved(lPanel, lApi, lPoint,
      'A control-tree change must invalidate the cached hover miss.');

    lPanel.SetBounds(lPanel.Left, lPanel.Top, lPanel.Width + 1, lPanel.Height);
    AssertBlankHoverReResolved(lPanel, lApi, lPoint,
      'A direct geometry change must invalidate the cached hover miss.');

    lPanel.Perform(CM_ENTER, 0, 0);
    AssertBlankHoverReResolved(lPanel, lApi, lPoint,
      'A focus change must invalidate the cached hover miss.');

    lPanel.Perform(CM_CHANGED, 0, 0);
    AssertBlankHoverReResolved(lPanel, lApi, lPoint,
      'A state change must invalidate the cached hover miss.');
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.UninstallPassivatesPopulatedBlankPanelHoverSnapshot;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalWindowProc: TWndMethod;
  lPanel: TPanel;
  lProbe: TWindowProcProbe;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  lOriginalWindowProc := nil;
  lPanel := nil;
  lProbe := TWindowProcProbe.Create;
  try
    lForm.SetBounds(100, 100, 360, 180);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := '';
    lPanel.SetBounds(20, 20, 300, 120);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lPanel;
    lLabel.Caption := 'Retained action';
    lLabel.SetBounds(170, 46, 110, 24);

    lForm.Show;
    lPanel.HandleNeeded;
    lOriginalWindowProc := lPanel.WindowProc;
    TAccessibilityManager.Install(lForm);
    lPanel.Update;
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(12, 12)));
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls);

    lProbe.Prior := lPanel.WindowProc;
    lPanel.WindowProc := lProbe.WindowProc;
    TAccessibilityManager.Uninstall;
    lPanel.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(12, 12)));

    Assert.IsTrue(lProbe.Calls > 0);
    Assert.AreEqual(0, lApi.NotificationCalls,
      'A passivated hook with a populated miss snapshot must not call UIA after uninstall.');
  finally
    if Assigned(lOriginalWindowProc) then
    begin
      lPanel.WindowProc := lOriginalWindowProc;
    end;
    lForm.Free;
    ResetManager;
    lProbe.Free;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHoverMissCacheLatencyDistribution;
var
  i: Integer;
  lApi: IManagerTestUiaApi;
  lCachedSamples: TT114SampleCases;
  lDirectory: string;
  lResolvedSamples: TT114SampleCases;
begin
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  for i := 0 to Pred(cT114CaseCount) do
  begin
    MeasureT114HoverMissCase(lApi, cT114ChildCounts[i], lResolvedSamples[i], lCachedSamples[i]);
  end;

  lDirectory := GetEnvironmentVariable('MAXLOGIC_T114_MEASURE_DIR');
  if lDirectory <> '' then
  begin
    ForceDirectories(lDirectory);
    TFile.WriteAllText(TPath.Combine(lDirectory, 'hover-miss.csv'),
      BuildT114HoverMissCsv(lResolvedSamples, lCachedSamples), TEncoding.UTF8);
  end;
end;

procedure TAccessibilityManagerTests.FormInstallHoverUsesVclLookupForSimpleLeafProviders;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lLabel: TLabel;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lMouseParam: LPARAM;
  lNextLabel: TLabel;
  lPoint: TPoint;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lLabel := TLabel.Create(lForm);
    lLabel.Parent := lForm;
    lLabel.Caption := 'Audit warning';
    lLabel.SetBounds(20, 20, 180, 24);

    lNextLabel := TLabel.Create(lForm);
    lNextLabel.Parent := lForm;
    lNextLabel.Caption := 'Completed action';
    lNextLabel.SetBounds(20, 60, 180, 24);

    TAccessibilityManager.Install(lForm);
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lPoint := lForm.ScreenToClient(ControlScreenCenter(lLabel));
    lMouseParam := PointToLParam(lPoint);
    lForm.Perform(WM_MOUSEMOVE, 0, lMouseParam);

    lPoint := lForm.ScreenToClient(ControlScreenCenter(lNextLabel));
    lMouseParam := PointToLParam(lPoint);
    lForm.Perform(WM_MOUSEMOVE, 0, lMouseParam);

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(2, lApi.NotificationCalls);
    Assert.AreEqual('Completed action', lApi.LastNotificationText);
    Assert.AreEqual(0, lMetrics.ProviderRootElementProviderFromPointCount,
      'Simple leaf hover should use the VCL control-provider lookup instead of root provider hit testing.');
    Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
      'Simple leaf hover should use VCL geometry for cache bounds, not provider child navigation.');
    Assert.AreEqual(0, lMetrics.ProviderGetBoundingRectangleCount,
      'Simple leaf hover should use VCL geometry for cache bounds, not provider bounding-rectangle callbacks.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
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

    lPoint := Point(8, 8);
    lRadioGroup.Perform(WM_MOUSEMOVE, 0, PointToLParam(lPoint));

    Assert.AreEqual(2, lApi.NotificationCalls);
    Assert.AreEqual('Density. TRadioGroup sample for role comparison', lApi.LastNotificationText);
    Assert.AreEqual('Density', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Density', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.DemoFormInstallRaisesViewModeGroupHoverFromGroupWindow;
var
  lApi: IManagerTestUiaApi;
  lForm: TAccessibilityDemoMainForm;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    lForm.HandleNeeded;
    lForm.grpViewMode.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lForm.grpViewMode.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(8, 8)));

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

procedure TAccessibilityManagerTests.DemoFormInstallRaisesDensityGroupHoverFromGroupWindow;
var
  lApi: IManagerTestUiaApi;
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

    TAccessibilityManager.Install(lForm);

    lForm.radioGroupDensity.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(8, 8)));

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Density. TRadioGroup sample for role comparison', lApi.LastNotificationText);
    Assert.AreEqual('Density', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Density', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.DemoFormInstallReturnsGroupProvidersFromGroupWindows;
var
  lApi: IManagerTestUiaApi;
  lForm: TAccessibilityDemoMainForm;
  lMessage: TMessage;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    lForm.HandleNeeded;
    lForm.grpViewMode.HandleNeeded;
    lForm.radioGroupDensity.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 7;
    lMessage.LParam := UiaRootObjectId;
    lForm.grpViewMode.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(1, lApi.ReturnCalls);
    Assert.AreEqual(lForm.grpViewMode.Handle, lApi.LastHwnd);
    Assert.AreEqual('View mode', ProviderStringProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(UIA_GroupControlTypeId, ProviderIntProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_ControlTypePropertyId));

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 8;
    lMessage.LParam := UiaRootObjectId;
    lForm.radioGroupDensity.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(2, lApi.ReturnCalls);
    Assert.AreEqual(lForm.radioGroupDensity.Handle, lApi.LastHwnd);
    Assert.AreEqual('Density', ProviderStringProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(UIA_GroupControlTypeId, ProviderIntProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_ControlTypePropertyId));
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

procedure TAccessibilityManagerTests.FormInstallRaisesRadioGroupItemFocusNotificationFromButtonWindow;
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

    lButton.Perform(CM_ENTER, 0, 0);

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

procedure TAccessibilityManagerTests.FormInstallRaisesGroupedRadioButtonFocusNotificationWithFrameworkProvider;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lRadioButton: TRadioButton;
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
    lForm.SetBounds(100, 100, 360, 180);

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Parent := lForm;
    lGroupBox.Caption := 'View mode';
    lGroupBox.SetBounds(24, 24, 220, 86);
    lGroupBox.HandleNeeded;

    lRadioButton := TRadioButton.Create(lForm);
    lRadioButton.Parent := lGroupBox;
    lRadioButton.Caption := 'Compact';
    lRadioButton.Hint := 'Use the compact view mode';
    lRadioButton.Checked := True;
    lRadioButton.SetBounds(12, 28, 120, 22);
    lRadioButton.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lRadioButton.Perform(CM_ENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Compact. Use the compact view mode', lApi.LastNotificationText);
    Assert.AreEqual('Compact', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Compact', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(2, lWinEvents.Calls);
    Assert.AreEqual(EVENT_OBJECT_STATECHANGE, lWinEvents.LastEvent);
    Assert.AreEqual(lRadioButton.Handle, lWinEvents.LastHwnd);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGroupedRadioButtonSelectionNotificationWithFrameworkProvider;
var
  lApi: IManagerTestUiaApi;
  lFirstRadio: TRadioButton;
  lForm: TForm;
  lGroupBox: TGroupBox;
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
    lForm.SetBounds(100, 100, 360, 180);

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Parent := lForm;
    lGroupBox.Caption := 'View mode';
    lGroupBox.SetBounds(24, 24, 220, 86);
    lGroupBox.HandleNeeded;

    lFirstRadio := TRadioButton.Create(lForm);
    lFirstRadio.Parent := lGroupBox;
    lFirstRadio.Caption := 'Compact';
    lFirstRadio.Checked := True;
    lFirstRadio.SetBounds(12, 28, 120, 22);
    lFirstRadio.HandleNeeded;

    lSecondRadio := TRadioButton.Create(lForm);
    lSecondRadio.Parent := lGroupBox;
    lSecondRadio.Caption := 'Detailed';
    lSecondRadio.Hint := 'Use the detailed view mode';
    lSecondRadio.SetBounds(12, 54, 120, 22);
    lSecondRadio.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lFirstRadio.Perform(CM_ENTER, 0, 0);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Compact', lApi.LastNotificationText);

    lSecondRadio.Checked := True;
    lSecondRadio.Perform(CM_ENTER, 0, 0);

    Assert.IsTrue(lSecondRadio.Checked);
    Assert.AreEqual(2, lApi.NotificationCalls);
    Assert.AreEqual('Detailed. Use the detailed view mode', lApi.LastNotificationText);
    Assert.AreEqual('Detailed', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.IsTrue(lApi.EventCalls >= 2);
    Assert.AreEqual(UIA_AutomationFocusChangedEventId, lApi.LastEventId);
    Assert.AreEqual('Detailed', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    Assert.IsTrue(lWinEvents.Calls > 0);
    Assert.AreEqual(lSecondRadio.Handle, lWinEvents.LastHwnd);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesGroupedRadioButtonArrowNavigationNotificationWithFrameworkProvider;
var
  lApi: IManagerTestUiaApi;
  lFirstRadio: TRadioButton;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lHandler: TRadioNavigationTestHandler;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lSecondRadio: TRadioButton;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lHandler := nil;
  lForm := TForm.Create(nil);
  try
    lHandler := TRadioNavigationTestHandler.Create;

    lForm.SetBounds(100, 100, 360, 180);

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Parent := lForm;
    lGroupBox.Caption := 'View mode';
    lGroupBox.SetBounds(24, 24, 220, 86);

    lFirstRadio := TRadioButton.Create(lForm);
    lFirstRadio.Parent := lGroupBox;
    lFirstRadio.Caption := 'Compact';
    lFirstRadio.Checked := True;
    lFirstRadio.SetBounds(12, 28, 120, 22);

    lSecondRadio := TRadioButton.Create(lForm);
    lSecondRadio.Parent := lGroupBox;
    lSecondRadio.Caption := 'Detailed';
    lSecondRadio.Hint := 'Use the detailed view mode';
    lSecondRadio.SetBounds(12, 54, 120, 22);

    lHandler.TargetRadio := lSecondRadio;
    lFirstRadio.OnKeyDown := lHandler.SelectTargetRadio;

    lForm.Show;
    lFirstRadio.HandleNeeded;
    lSecondRadio.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lFirstRadio.SetFocus;
    Application.ProcessMessages;
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lApi.ResetClientsAreListeningCalls;

    lFirstRadio.Perform(WM_KEYDOWN, VK_DOWN, 0);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Application.ProcessMessages;

    Assert.IsTrue(lSecondRadio.Checked);
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      'Grouped radio arrow speech should probe UIA client-listening state once for the event burst.');
    Assert.AreEqual(0, lMetrics.ProviderGetPatternProviderCount,
      'Grouped radio state capture should read in-process provider state directly, not call GetPatternProvider.');
    Assert.AreEqual('Detailed. Use the detailed view mode', lApi.LastNotificationText);
    Assert.AreEqual('Detailed', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lForm.Free;
    lHandler.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallSkipsGroupedRadioSelectionScanWhenNoUiaClients;
var
  lApi: IManagerTestUiaApi;
  lFirstRadio: TCheckedReadProbeRadioButton;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lSecondRadio: TCheckedReadProbeRadioButton;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(False);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Parent := lForm;
    lGroupBox.Caption := 'View mode';
    lGroupBox.SetBounds(24, 24, 220, 86);

    lFirstRadio := TCheckedReadProbeRadioButton.Create(lForm);
    lFirstRadio.Parent := lGroupBox;
    lFirstRadio.Caption := 'Compact';
    lFirstRadio.Checked := True;
    lFirstRadio.SetBounds(12, 28, 120, 22);

    lSecondRadio := TCheckedReadProbeRadioButton.Create(lForm);
    lSecondRadio.Parent := lGroupBox;
    lSecondRadio.Caption := 'Detailed';
    lSecondRadio.SetBounds(12, 54, 120, 22);

    lForm.Show;
    lFirstRadio.HandleNeeded;
    lSecondRadio.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    lFirstRadio.SetFocus;
    Application.ProcessMessages;
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    TCheckedReadProbeRadioButton.ResetCheckedReadCount;
    lApi.ResetClientsAreListeningCalls;

    lFirstRadio.Perform(WM_KEYDOWN, VK_DOWN, 0);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Application.ProcessMessages;

    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      'Silent grouped radio arrow handling should ask UIA listener state once.');
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(0, lMetrics.ProviderEventBatchCount,
      'Silent grouped radio arrow handling should not open provider event batches.');
    Assert.AreEqual(0, TCheckedReadProbeRadioButton.CheckedReadCount,
      'Silent grouped radio arrow handling should not scan checked radio state for skipped announcements.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesRadioGroupItemArrowNavigationNotificationFromButtonWindow;
var
  lApi: IManagerTestUiaApi;
  lButton: TRadioButton;
  lForm: TForm;
  lHandler: TRadioNavigationTestHandler;
  lRadioGroup: TRadioGroup;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lHandler := nil;
  lForm := TForm.Create(nil);
  try
    lHandler := TRadioNavigationTestHandler.Create;

    lForm.SetBounds(100, 100, 360, 180);

    lRadioGroup := TRadioGroup.Create(lForm);
    lRadioGroup.Parent := lForm;
    lRadioGroup.Caption := 'Density';
    lRadioGroup.Items.Add('Comfortable');
    lRadioGroup.Items.Add('Compact density');
    lRadioGroup.ItemIndex := 0;
    lRadioGroup.SetBounds(24, 24, 220, 82);

    lForm.Show;
    lRadioGroup.HandleNeeded;
    lRadioGroup.Buttons[0].HandleNeeded;
    lRadioGroup.Buttons[1].HandleNeeded;
    lButton := lRadioGroup.Buttons[0];
    lHandler.TargetRadioGroup := lRadioGroup;
    lHandler.TargetItemIndex := 1;
    lButton.OnKeyDown := lHandler.SelectTargetRadioGroupItem;
    TAccessibilityManager.Install(lForm);
    lButton.SetFocus;
    Application.ProcessMessages;

    lButton.Perform(WM_KEYDOWN, VK_DOWN, 0);
    Application.ProcessMessages;

    Assert.AreEqual(1, lRadioGroup.ItemIndex);
    Assert.AreEqual('Compact density', lApi.LastNotificationText);
    Assert.AreEqual('Compact density', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
  finally
    lForm.Free;
    lHandler.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallReturnsGroupedRadioButtonProviderFromGroupBoxRadioWindow;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lMessage: TMessage;
  lRadioButton: TRadioButton;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Parent := lForm;
    lGroupBox.Caption := 'View mode';
    lGroupBox.SetBounds(24, 24, 220, 86);
    lGroupBox.HandleNeeded;

    lRadioButton := TRadioButton.Create(lForm);
    lRadioButton.Parent := lGroupBox;
    lRadioButton.Caption := 'Compact';
    lRadioButton.Checked := True;
    lRadioButton.SetBounds(12, 28, 120, 22);
    lRadioButton.HandleNeeded;

    TAccessibilityManager.Install(lForm);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 7;
    lMessage.LParam := UiaRootObjectId;
    lRadioButton.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(1, lApi.ReturnCalls);
    Assert.AreEqual(lRadioButton.Handle, lApi.LastHwnd);
    Assert.AreEqual('Compact', ProviderStringProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(UIA_RadioButtonControlTypeId, ProviderIntProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_ControlTypePropertyId));
    Assert.IsTrue(ProviderPattern(FragmentFromSimple(lApi.ReturnedProvider), UIA_SelectionItemPatternId) <> nil);
  finally
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallBindsRadioGroupButtonWindowByControlIdentity;
var
  lApi: IManagerTestUiaApi;
  lButton: TRadioButton;
  lForm: TForm;
  lMessage: TMessage;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lRadioGroup: TRadioGroup;
  lRegistry: IAccessibilityAdapterRegistry;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lRegistry := TAccessibilityVclAdapters.CreateDefaultRegistry;
  lRegistry.RegisterAdapter(TRadioGroup, TLyingRadioGroupAdapter.Create);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 180);

    lRadioGroup := TRadioGroup.Create(lForm);
    lRadioGroup.Parent := lForm;
    lRadioGroup.Caption := 'Density';
    lRadioGroup.Items.Add('Comfortable');
    lRadioGroup.Items.Add('Compact density');
    lRadioGroup.ItemIndex := 0;
    lRadioGroup.SetBounds(24, 24, 220, 82);
    lRadioGroup.HandleNeeded;
    lRadioGroup.Buttons[0].HandleNeeded;
    lButton := lRadioGroup.Buttons[0];

    TAccessibilityManager.Install(lForm, lRegistry);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 7;
    lMessage.LParam := UiaRootObjectId;
    lButton.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(1, lApi.ReturnCalls);
    Assert.AreEqual(lButton.Handle, lApi.LastHwnd);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(Integer(lButton.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.ReturnedProvider))));
    Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
      'RadioGroup child-window binding should use direct in-process child access, not UIA Navigate.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallReturnsRadioGroupItemProviderFromButtonWindow;
var
  lApi: IManagerTestUiaApi;
  lButton: TRadioButton;
  lForm: TForm;
  lMessage: TMessage;
  lRadioGroup: TRadioGroup;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
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

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 7;
    lMessage.LParam := UiaRootObjectId;
    lButton.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(1, lApi.ReturnCalls);
    Assert.AreEqual(lButton.Handle, lApi.LastHwnd);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(Integer(lButton.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.ReturnedProvider))));
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

procedure TAccessibilityManagerTests.DemoFormInstallReturnsRadioGroupItemProviderFromButtonWindow;
var
  lApi: IManagerTestUiaApi;
  lButton: TRadioButton;
  lForm: TAccessibilityDemoMainForm;
  lMessage: TMessage;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    lForm.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lButton := lForm.radioGroupDensity.Buttons[0];

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.WParam := 7;
    lMessage.LParam := UiaRootObjectId;
    lButton.WindowProc(lMessage);

    Assert.AreEqual(2468, lMessage.Result);
    Assert.AreEqual(1, lApi.ReturnCalls);
    Assert.AreEqual(lButton.Handle, lApi.LastHwnd);
    Assert.AreEqual('Comfortable', ProviderStringProperty(FragmentFromSimple(lApi.ReturnedProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(Integer(lButton.Handle), Integer(ProviderNativeWindowHandle(FragmentFromSimple(
      lApi.ReturnedProvider))));
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

procedure TAccessibilityManagerTests.FormInstallCheckBoxHoverSkipsUnusedAnnouncementTextBuild;
var
  lApi: IManagerTestUiaApi;
  lCheckBox: TCheckBox;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lCheckBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lCheckBox.Width div 2, lCheckBox.Height div 2)));

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(1, lApi.EventCalls);
    Assert.AreEqual(2, lWinEvents.Calls);
    Assert.AreEqual(0, lMetrics.ProviderFocusAnnouncementTextCount);
    Assert.AreEqual(0, lMetrics.ProviderFocusAnnouncementDetailProbeCount);
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallCheckBoxHoverWithoutUiaClientsSkipsProviderBatch;
var
  lApi: IManagerTestUiaApi;
  lCheckBox: TCheckBox;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lWinEvents: TWinEventRecorder;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(False);
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lCheckBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lCheckBox.Width div 2, lCheckBox.Height div 2)));

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.AreEqual(2, lWinEvents.Calls);
    Assert.AreEqual(0, lMetrics.ProviderEventBatchCount,
      'Native checkbox hover should not open a provider UIA event batch when no UIA clients are listening.');
    Assert.AreEqual(EVENT_OBJECT_STATECHANGE, lWinEvents.LastEvent);
    Assert.AreEqual(lCheckBox.Handle, lWinEvents.LastHwnd);
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallRaisesCheckBoxFocusNativeWinEventsWithoutProviderReplacement;
var
  lApi: IManagerTestUiaApi;
  lCheckBox: TCheckBox;
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;

    lCheckBox.Perform(CM_ENTER, 0, 0);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.AreEqual(0, lMetrics.ProviderEventBatchCount,
      'Native checkbox focus should not open a provider UIA event batch when native WinEvents own speech.');
    Assert.AreEqual(2, lWinEvents.Calls);
    Assert.AreEqual(EVENT_OBJECT_STATECHANGE, lWinEvents.LastEvent);
    Assert.AreEqual(lCheckBox.Handle, lWinEvents.LastHwnd);
    Assert.AreEqual(Cardinal($FFFFFFFC), lWinEvents.LastObjectId);
    Assert.AreEqual(Cardinal(CHILDID_SELF), lWinEvents.LastChildId);
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
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
  lMetrics: TAccessibilityProviderHotspotMetrics;
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Contoso', lApi.LastNotificationText);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lMetrics.StringGridRefreshCount,
      'Grid keyboard speech should use the provider native focused-item path, not refresh visible cells.');
    Assert.AreEqual('Contoso', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider), UIA_NamePropertyId));
    Assert.AreEqual('Contoso', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(0, lMetrics.ProviderRootGetFocusCount,
      'Grid keyboard speech should use the provider native focused-item path, not root GetFocus traversal.');
    Assert.AreEqual(0, lMetrics.ProviderGetPatternProviderCount,
      'Grid keyboard speech should not probe generic toggle/selection patterns on the grid provider.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
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
    lApi.ResetClientsAreListeningCalls;
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(1, lApi.ClientsAreListeningCalls,
      'Grid keyboard speech should probe UIA client-listening state once for the event burst.');
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

procedure TAccessibilityManagerTests.FormInstallSkipsStringGridFocusTextWhenNoUiaClients;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lGrid: TStringGrid;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  ResetManager;
  lApi := TManagerTestUiaApi.Create;
  lApi.SetClientsAreListening(False);
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

    TAccessibilityManager.Install(lForm);
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual(0, lMetrics.StringGridRowTextBuildCount,
      'Grid keyboard path should not build row speech text when no UIA clients are listening.');
    Assert.AreEqual(0, lMetrics.ProviderEventBatchCount,
      'Grid keyboard path should not open a provider event batch when no UIA clients are listening.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallLeavesListBoxArrowKeySpeechToNativeWindow;
var
  lApi: IManagerTestUiaApi;
  lForm: TForm;
  lListBox: TListBox;
  lMetrics: TAccessibilityListBoxFocusMetrics;
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
    TAccessibilityDiagnostics.EnableListBoxFocusMetrics;
    TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
    lApi.ResetClientsAreListeningCalls;
    lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);
    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;

    Assert.AreEqual(2, lListBox.ItemIndex);
    Assert.AreEqual(0, lApi.EventCalls);
    Assert.AreEqual(0, lApi.NotificationCalls);
    Assert.AreEqual('', lApi.LastNotificationText);
    Assert.AreEqual(0, lApi.ClientsAreListeningCalls,
      'Native-listbox arrow-key handling should not ask UIA listener state when native HWND speech owns it.');
    Assert.AreEqual(0, lMetrics.NativeHandlePublicationCheckCount,
      'Native-listbox arrow-key handling should not re-check framework HWND publication on the key path.');
    Assert.AreEqual(0, lMetrics.ItemIndexProbeCount,
      'Native-listbox arrow-key handling should not probe framework item state on the key path.');
  finally
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
    lForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallTracksListBoxSelectionOncePerMutation;
const
  cNavigationCount = 100;
  cSelectedCount = 300;
var
  lFixture: TManagerListBoxFixture;
  lPattern: IUnknown;
  lSelectionItem: ISelectionItemProvider;
begin
  lFixture := CreateManagerListBoxFixture(cSelectedCount);
  try
    lFixture.fListBox.ResetBulkSelectionMessageCount;
    NavigateManagerListBox(lFixture, cNavigationCount, 'Initial stable');
    Assert.IsTrue(lFixture.fListBox.BulkSelectionMessageCount <= 2,
      Format('Stable traversal used %d bulk selection messages.',
      [lFixture.fListBox.BulkSelectionMessageCount]));

    lFixture.fListBox.Perform(WM_KEYDOWN, VK_SHIFT, 0);
    AssertManagerListBoxReconcilesOnce(lFixture, 'A no-op native key message');

    lFixture.fListBox.Selected[Pred(cSelectedCount)] := False;
    lFixture.fListBox.Selected[599] := True;
    AssertManagerListBoxReconcilesOnce(lFixture, 'A same-count native selection mutation');

    lFixture.fCurrent := FirstChildFragment(lFixture.fListBoxFragment);
    lPattern := ProviderPattern(lFixture.fCurrent, UIA_SelectionItemPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
    Assert.AreEqual(S_OK, lSelectionItem.RemoveFromSelection);
    lFixture.fListBox.ItemIndex := 0;
    AssertManagerListBoxReconcilesOnce(lFixture, 'A framework selection-item mutation');
  finally
    lFixture.fForm.Free;
    ResetManager;
  end;
end;

procedure TAccessibilityManagerTests.FormInstallListBoxSelectionTrackingLatencyDistribution;
const
  cManySelectedCount = 300;
  cSampleCount = 200;
var
  lDirectory: string;
  lDiagnosticsState: string;
  lMany: TManagerListBoxMeasurement;
  lOne: TManagerListBoxMeasurement;
  lText: string;
  lZero: TManagerListBoxMeasurement;
begin
  lZero := MeasureManagerListBoxSiblingNavigation(0, cSampleCount);
  lOne := MeasureManagerListBoxSiblingNavigation(1, cSampleCount);
  lMany := MeasureManagerListBoxSiblingNavigation(cManySelectedCount, cSampleCount);

  Assert.IsTrue(lZero.fBulkSelectionMessageCount <= 2,
    Format('Zero-selection traversal used %d bulk selection messages.', [lZero.fBulkSelectionMessageCount]));
  Assert.IsTrue(lOne.fBulkSelectionMessageCount <= 2,
    Format('One-selection traversal used %d bulk selection messages.', [lOne.fBulkSelectionMessageCount]));
  Assert.IsTrue(lMany.fBulkSelectionMessageCount <= 2,
    Format('Many-selection traversal used %d bulk selection messages.', [lMany.fBulkSelectionMessageCount]));

  lDirectory := GetEnvironmentVariable('MAXLOGIC_T113_MEASURE_DIR');
  if lDirectory = '' then
  begin
    Exit;
  end;

  ForceDirectories(lDirectory);
  if TAccessibilityDiagnostics.Enabled then
  begin
    lDiagnosticsState := 'enabled';
  end else begin
    lDiagnosticsState := 'disabled';
  end;
  lText := Format('sampleCount=%d,frequency=%d,diagnostics=%s,zeroSelected=0,zeroBulk=%d,' +
    'oneSelected=1,oneBulk=%d,manySelected=%d,manyBulk=%d%s',
    [cSampleCount, TStopwatch.Frequency, lDiagnosticsState, lZero.fBulkSelectionMessageCount,
    lOne.fBulkSelectionMessageCount, lMany.fSelectedCount, lMany.fBulkSelectionMessageCount, sLineBreak]) +
    TickCsvLine(lZero.fSamples) + sLineBreak + TickCsvLine(lOne.fSamples) + sLineBreak +
    TickCsvLine(lMany.fSamples) + sLineBreak;
  TFile.WriteAllText(TPath.Combine(lDirectory, 'listbox-selection.csv'), lText, TEncoding.UTF8);
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
  lMetrics: TAccessibilityProviderHotspotMetrics;
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lGrid.Perform(WM_KEYDOWN, VK_DOWN, 0);

    Assert.AreEqual(2, lGrid.Row);
    Assert.AreEqual(2, lApi.EventCalls);
    Assert.AreEqual(UIA_SelectionItem_ElementSelectedEventId, lApi.LastEventId);
    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Contoso TMS', lApi.LastNotificationText);
    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lMetrics.TmsAdvStringGridRefreshCount,
      'TMS grid keyboard speech should use the provider native focused-item path, not refresh visible cells.');
    Assert.AreEqual('Contoso TMS', ProviderStringProperty(FragmentFromSimple(lApi.LastEventProvider),
      UIA_NamePropertyId));
    Assert.AreEqual('Contoso TMS', ProviderStringProperty(FragmentFromSimple(lApi.LastNotificationProvider),
      UIA_NamePropertyId));
    Assert.AreEqual(0, lMetrics.ProviderGetPatternProviderCount,
      'TMS grid keyboard speech should not probe generic toggle/selection patterns on the grid provider.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
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
