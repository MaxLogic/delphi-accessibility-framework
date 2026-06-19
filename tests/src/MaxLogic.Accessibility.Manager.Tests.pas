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
  System.Classes, System.Generics.Collections, System.SysUtils, System.Types, System.Variants, Winapi.Messages,
  Winapi.Windows, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, AdvGrid, MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner,
  MaxLogic.Accessibility.TmsAdvStringGridAdapters, MaxLogic.Accessibility.UIAutomationCore;

type
  IFormInstallRecorder = interface(IAccessibilityFormInstaller)
    ['{89B798B7-0880-4AE5-B799-58E4EB14DF22}']
    function CountFor(aForm: TCustomForm): Integer;
    procedure FailNextInstall;
  end;

  IManagerTestUiaApi = interface(IAccessibilityUiaApi)
    ['{40F38FD9-3290-4894-A855-082E2884C0C1}']
    function DisconnectCalls: Integer;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
    function ReturnedProvider: IRawElementProviderSimple;
    function ReturnCalls: Integer;
  end;

  TManagerTestUiaApi = class(TInterfacedObject, IManagerTestUiaApi)
  private
    fDisconnectCalls: Integer;
    fLastHwnd: HWND;
    fLastLParam: LPARAM;
    fReturnedProvider: IRawElementProviderSimple;
    fReturnCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function DisconnectCalls: Integer;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastHwnd: HWND;
    function LastLParam: LPARAM;
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

procedure ResetManager;
begin
  TAccessibilityManager.Uninstall;
  TAccessibilityManagerInternals.SetFormInstaller(nil);
  TAccessibilityManagerInternals.SetUiaApi(nil);
end;

function TManagerTestUiaApi.ClientsAreListening: Boolean;
begin
  Result := False;
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

function TManagerTestUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function TManagerTestUiaApi.LastHwnd: HWND;
begin
  Result := fLastHwnd;
end;

function TManagerTestUiaApi.LastLParam: LPARAM;
begin
  Result := fLastLParam;
end;

function TManagerTestUiaApi.ReturnedProvider: IRawElementProviderSimple;
begin
  Result := fReturnedProvider;
end;

function TManagerTestUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID): HRESULT;
begin
  Result := S_OK;
end;

function TManagerTestUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := S_OK;
end;

function TManagerTestUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
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
