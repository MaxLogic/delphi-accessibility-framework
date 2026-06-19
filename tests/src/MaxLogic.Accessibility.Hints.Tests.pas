unit MaxLogic.Accessibility.Hints.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('HintAccessibility')]
  TAccessibilityHintTests = class
  public
    [Test]
    procedure ControlHintIsExposedAsHelpText;
    [Test]
    procedure ApplicationHintNotificationsAreChainedGatedAndDeduplicated;
    [Test]
    procedure BalloonHintTitleAndDescriptionAreRaisedTogether;
    [Test]
    procedure BalloonHintObjectTitleAndDescriptionAreRaisedTogether;
    [Test]
    procedure ManagerApplicationInstallInstallsHintNotifications;
    [Test]
    procedure ManagerApplicationInstallObservesControlBalloonHintsOnMouseEnter;
    [Test]
    procedure ManagerApplicationInstallUsesFinalControlHintAfterMouseEnterMutation;
    [Test]
    procedure BalloonDescriptionSuppressionIsOneShot;
    [Test]
    procedure FormInstallObservesControlBalloonHintsOnMouseEnter;
    [Test]
    procedure FormInstallUsesFinalControlHintAfterMouseEnterMutation;
    [Test]
    procedure FormInstallDoesNotHookApplicationHintEvents;
    [Test]
    procedure ManagerBalloonHintMouseEnterMatchesVclTitleOnlyParsing;
    [Test]
    procedure ManagerBalloonHintMouseEnterIgnoresEmptyControlHint;
    [Test]
    procedure ManagerBalloonHintTitleOnlyFollowUpIsSuppressed;
    [Test]
    procedure ManagerBalloonHintImageIndexFollowUpIsSuppressed;
    [Test]
    procedure ManagerBalloonHintImageIndexOnlyFollowUpIsSuppressed;
    [Test]
    procedure PreviousApplicationHintHandlerCanUninstallManager;
    [Test]
    procedure PreviousApplicationShowHintHandlerCanUninstallManager;
    [Test]
    procedure UninstallDuringObservedMouseEnterDoesNotReadFreedHook;
    [Test]
    procedure VisibleHintShortPartAfterLongPartIsSuppressed;
  end;

implementation

uses
  System.Classes, System.SysUtils, System.Variants, Winapi.Windows, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ExtCtrls, DUnitX.Assert, MaxLogic.Accessibility.Hints, MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

type
  // Real UIA notification delivery needs an external UIA client, so this fake preserves the event boundary deterministically.
  IHintTestUiaApi = interface(IAccessibilityUiaApi)
    ['{1F838FC9-92DE-42A2-8929-CFE9F4F3EBDA}']
    function LastDisplayString: string;
    function LastNotificationProcessing: NotificationProcessing;
    function NotificationCalls: Integer;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  THintTestUiaApi = class(TInterfacedObject, IHintTestUiaApi)
  private
    fClientsAreListening: Boolean;
    fLastDisplayString: string;
    fLastNotificationProcessing: NotificationProcessing;
    fNotificationCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastDisplayString: string;
    function LastNotificationProcessing: NotificationProcessing;
    function NotificationCalls: Integer;
    function RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
    function RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID;
      const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
    function RaiseNotification(const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
      aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
      const aActivityId: WideString): HRESULT;
    function RaiseStructureChanged(const aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
      const aRuntimeId: TArray<Integer>): HRESULT;
    function ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple): LRESULT;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  THintChainProbe = class
  private
    fCalls: Integer;
  public
    procedure HandleHint(aSender: TObject);
    property Calls: Integer read fCalls;
  end;

  THintMutationProbe = class
  private
    fNewHint: string;
  public
    constructor Create(const aNewHint: string);
    procedure HandleMouseEnter(aSender: TObject);
  end;

  THintUninstallProbe = class
  public
    procedure HandleHint(aSender: TObject);
    procedure HandleShowHint(var aHintStr: string; var aCanShow: Boolean;
      var aHintInfo: Vcl.Controls.THintInfo);
    procedure HandleMouseEnter(aSender: TObject);
  end;

function THintTestUiaApi.ClientsAreListening: Boolean;
begin
  Result := fClientsAreListening;
end;

function THintTestUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Result := S_OK;
end;

function THintTestUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function THintTestUiaApi.LastDisplayString: string;
begin
  Result := fLastDisplayString;
end;

function THintTestUiaApi.LastNotificationProcessing: NotificationProcessing;
begin
  Result := fLastNotificationProcessing;
end;

function THintTestUiaApi.NotificationCalls: Integer;
begin
  Result := fNotificationCalls;
end;

function THintTestUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID): HRESULT;
begin
  Result := S_OK;
end;

function THintTestUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := S_OK;
end;

function THintTestUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Inc(fNotificationCalls);
  fLastDisplayString := aDisplayString;
  fLastNotificationProcessing := aNotificationProcessing;
  Result := S_OK;
end;

function THintTestUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Result := S_OK;
end;

function THintTestUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Result := 0;
end;

procedure THintTestUiaApi.SetClientsAreListening(aValue: Boolean);
begin
  fClientsAreListening := aValue;
end;

procedure THintChainProbe.HandleHint(aSender: TObject);
begin
  Inc(fCalls);
end;

constructor THintMutationProbe.Create(const aNewHint: string);
begin
  inherited Create;
  fNewHint := aNewHint;
end;

procedure THintMutationProbe.HandleMouseEnter(aSender: TObject);
begin
  if aSender is TControl then
  begin
    TControl(aSender).Hint := fNewHint;
  end;
end;

procedure THintUninstallProbe.HandleMouseEnter(aSender: TObject);
begin
  TAccessibilityManager.Uninstall;
end;

procedure THintUninstallProbe.HandleHint(aSender: TObject);
begin
  TAccessibilityManager.Uninstall;
end;

procedure THintUninstallProbe.HandleShowHint(var aHintStr: string; var aCanShow: Boolean;
  var aHintInfo: Vcl.Controls.THintInfo);
begin
  TAccessibilityManager.Uninstall;
end;

function FirstChildProvider(const aProvider: IAccessibilityProviderNode): IRawElementProviderSimple;
var
  lFragment: IRawElementProviderFragment;
begin
  lFragment := nil;
  Result := nil;
  Assert.AreEqual(S_OK, aProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lFragment));
  Assert.IsNotNull(lFragment);
  Assert.IsTrue(Supports(lFragment, IRawElementProviderSimple, Result));
end;

procedure TAccessibilityHintTests.ControlHintIsExposedAsHelpText;
var
  lChildProvider: IRawElementProviderSimple;
  lForm: TForm;
  lLabel: TLabel;
  lProvider: IAccessibilityProviderNode;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := '&Name';
    lLabel.Hint := 'Short hint|Long help text';
    lLabel.Parent := lForm;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lChildProvider := FirstChildProvider(lProvider);

    Assert.AreEqual(S_OK, lChildProvider.GetPropertyValue(UIA_HelpTextPropertyId, lValue));
    Assert.AreEqual('Long help text', string(lValue));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.ApplicationHintNotificationsAreChainedGatedAndDeduplicated;
var
  lApi: IHintTestUiaApi;
  lController: TAccessibilityHintController;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lProbe: THintChainProbe;
  lProvider: IAccessibilityProviderNode;
begin
  lOriginalHint := Application.OnHint;
  lOriginalHintText := Application.Hint;
  lProbe := THintChainProbe.Create;
  lApi := THintTestUiaApi.Create;
  lProvider := TAccessibilityProviderFactory.CreateRoot([700], 0, lApi);
  try
    Application.OnHint := lProbe.HandleHint;
    lController := TAccessibilityHintController.Create(Application, lProvider, lApi);
    try
      Application.Hint := 'Muted short|Muted long';
      Assert.AreEqual(1, lProbe.Calls);
      Assert.AreEqual(0, lApi.NotificationCalls);

      lApi.SetClientsAreListening(True);
      Application.Hint := 'Short hint|Long help text';
      lController.NotifyVisibleHint('Short hint|Long help text');

      Assert.AreEqual(2, lProbe.Calls);
      Assert.AreEqual(1, lApi.NotificationCalls);
      Assert.AreEqual('Long help text', lApi.LastDisplayString);
      Assert.AreEqual(NotificationProcessing_MostRecent, lApi.LastNotificationProcessing);
    finally
      lController.Free;
    end;
  finally
    Application.OnHint := lOriginalHint;
    Application.Hint := lOriginalHintText;
    lProbe.Free;
  end;
end;

procedure TAccessibilityHintTests.BalloonHintTitleAndDescriptionAreRaisedTogether;
var
  lApi: IHintTestUiaApi;
  lController: TAccessibilityHintController;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := THintTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lProvider := TAccessibilityProviderFactory.CreateRoot([701], 0, lApi);
  lController := TAccessibilityHintController.Create(nil, lProvider, lApi);
  try
    lController.NotifyBalloonHint('Upload complete', '5 files were processed');

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Upload complete: 5 files were processed', lApi.LastDisplayString);
  finally
    lController.Free;
  end;
end;

procedure TAccessibilityHintTests.BalloonHintObjectTitleAndDescriptionAreRaisedTogether;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lController: TAccessibilityHintController;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := THintTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lBalloonHint := TBalloonHint.Create(nil);
  lProvider := TAccessibilityProviderFactory.CreateRoot([702], 0, lApi);
  lController := TAccessibilityHintController.Create(nil, lProvider, lApi);
  try
    lBalloonHint.Title := 'Upload complete';
    lBalloonHint.Description := '5 files were processed';

    lController.NotifyBalloonHint(lBalloonHint);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Upload complete: 5 files were processed', lApi.LastDisplayString);
  finally
    lController.Free;
    lBalloonHint.Free;
  end;
end;

procedure TAccessibilityHintTests.ManagerApplicationInstallInstallsHintNotifications;
var
  lApi: IHintTestUiaApi;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  try
    Application.OnHint := nil;
    Application.Hint := '';
    Application.OnHint := lOriginalHint;
    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);

    TAccessibilityManager.Install(Application);
    Application.Hint := 'Manager short|Manager long';

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Manager long', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
  end;
end;

procedure TAccessibilityHintTests.ManagerApplicationInstallObservesControlBalloonHintsOnMouseEnter;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Upload';
    lLabel.Hint := 'Upload complete|5 files were processed';
    lLabel.CustomHint := lBalloonHint;
    lLabel.ShowHint := True;
    lLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lLabel.Perform(CM_MOUSEENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Upload complete: 5 files were processed', lApi.LastDisplayString);

    Application.Hint := '5 files were processed';

    Assert.AreEqual(1, lApi.NotificationCalls);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.ManagerApplicationInstallUsesFinalControlHintAfterMouseEnterMutation;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
  lPanel: TPanel;
  lProbe: THintMutationProbe;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  lProbe := THintMutationProbe.Create('Final title|Final description');
  try
    lPanel := TPanel.Create(lForm);
    lPanel.Hint := 'Initial title|Initial description';
    lPanel.CustomHint := lBalloonHint;
    lPanel.ShowHint := True;
    lPanel.OnMouseEnter := lProbe.HandleMouseEnter;
    lPanel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lPanel.Perform(CM_MOUSEENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Final title: Final description', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lProbe.Free;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.BalloonDescriptionSuppressionIsOneShot;
var
  lApi: IHintTestUiaApi;
  lController: TAccessibilityHintController;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := THintTestUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lProvider := TAccessibilityProviderFactory.CreateRoot([704], 0, lApi);
  lController := TAccessibilityHintController.Create(nil, lProvider, lApi);
  try
    lController.NotifyBalloonHint('Title', 'Same');
    lController.NotifyVisibleHint('Other');
    lController.NotifyVisibleHint('Same');

    Assert.AreEqual(3, lApi.NotificationCalls);
    Assert.AreEqual('Same', lApi.LastDisplayString);
  finally
    lController.Free;
  end;
end;

procedure TAccessibilityHintTests.FormInstallObservesControlBalloonHintsOnMouseEnter;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Hint := 'Scoped title|Scoped description';
    lLabel.CustomHint := lBalloonHint;
    lLabel.ShowHint := True;
    lLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(lForm);

    lLabel.Perform(CM_MOUSEENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Scoped title: Scoped description', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.FormInstallUsesFinalControlHintAfterMouseEnterMutation;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
  lPanel: TPanel;
  lProbe: THintMutationProbe;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  lProbe := THintMutationProbe.Create('Scoped final title|Scoped final description');
  try
    lPanel := TPanel.Create(lForm);
    lPanel.Hint := 'Scoped initial title|Scoped initial description';
    lPanel.CustomHint := lBalloonHint;
    lPanel.ShowHint := True;
    lPanel.OnMouseEnter := lProbe.HandleMouseEnter;
    lPanel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(lForm);

    lPanel.Perform(CM_MOUSEENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Scoped final title: Scoped final description', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lProbe.Free;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.FormInstallDoesNotHookApplicationHintEvents;
var
  lApi: IHintTestUiaApi;
  lForm: TForm;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  try
    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);

    TAccessibilityManager.Install(lForm);

    Assert.AreEqual(TMethod(lOriginalHint).Code, TMethod(Application.OnHint).Code);
    Assert.AreEqual(TMethod(lOriginalHint).Data, TMethod(Application.OnHint).Data);
    Assert.AreEqual(TMethod(lOriginalShowHint).Code, TMethod(Application.OnShowHint).Code);
    Assert.AreEqual(TMethod(lOriginalShowHint).Data, TMethod(Application.OnShowHint).Data);

    Application.Hint := 'Other form short|Other form long';

    Assert.AreEqual(0, lApi.NotificationCalls);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.ManagerBalloonHintMouseEnterMatchesVclTitleOnlyParsing;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Hint := 'Title only';
    lLabel.CustomHint := lBalloonHint;
    lLabel.ShowHint := True;
    lLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lLabel.Perform(CM_MOUSEENTER, 0, 0);

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Title only', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.ManagerBalloonHintMouseEnterIgnoresEmptyControlHint;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lBalloonHint.Title := 'Stale title';
    lBalloonHint.Description := 'Stale description';
    lLabel := TLabel.Create(lForm);
    lLabel.Hint := '';
    lLabel.CustomHint := lBalloonHint;
    lLabel.ShowHint := True;
    lLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lLabel.Perform(CM_MOUSEENTER, 0, 0);

    Assert.AreEqual(0, lApi.NotificationCalls);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.ManagerBalloonHintTitleOnlyFollowUpIsSuppressed;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Hint := 'Title only';
    lLabel.CustomHint := lBalloonHint;
    lLabel.ShowHint := True;
    lLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lLabel.Perform(CM_MOUSEENTER, 0, 0);
    Application.Hint := 'Title only';

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Title only', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.ManagerBalloonHintImageIndexFollowUpIsSuppressed;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Hint := 'Upload complete|5 files were processed|3';
    lLabel.CustomHint := lBalloonHint;
    lLabel.ShowHint := True;
    lLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lLabel.Perform(CM_MOUSEENTER, 0, 0);
    Application.Hint := '5 files were processed|3';

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Upload complete: 5 files were processed', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.ManagerBalloonHintImageIndexOnlyFollowUpIsSuppressed;
var
  lApi: IHintTestUiaApi;
  lBalloonHint: TBalloonHint;
  lForm: TForm;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Hint := 'Title only||3';
    lLabel.CustomHint := lBalloonHint;
    lLabel.ShowHint := True;
    lLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lLabel.Perform(CM_MOUSEENTER, 0, 0);
    Application.Hint := '|3';

    Assert.AreEqual(1, lApi.NotificationCalls);
    Assert.AreEqual('Title only', lApi.LastDisplayString);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.PreviousApplicationHintHandlerCanUninstallManager;
var
  lApi: IHintTestUiaApi;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
  lProbe: THintUninstallProbe;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lProbe := THintUninstallProbe.Create;
  try
    Application.OnHint := lProbe.HandleHint;
    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);

    TAccessibilityManager.Install(Application);
    Application.Hint := 'Uninstall short|Uninstall long';

    Assert.AreEqual(0, lApi.NotificationCalls);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lProbe.Free;
  end;
end;

procedure TAccessibilityHintTests.PreviousApplicationShowHintHandlerCanUninstallManager;
var
  lApi: IHintTestUiaApi;
  lCanShow: Boolean;
  lHintInfo: Vcl.Controls.THintInfo;
  lHintStr: string;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
  lProbe: THintUninstallProbe;
  lShowHint: TShowHintEvent;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lProbe := THintUninstallProbe.Create;
  try
    Application.OnShowHint := lProbe.HandleShowHint;
    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);

    TAccessibilityManager.Install(Application);
    lShowHint := Application.OnShowHint;
    lHintStr := 'Uninstall hint';
    lCanShow := True;
    lHintInfo := Default(Vcl.Controls.THintInfo);

    lShowHint(lHintStr, lCanShow, lHintInfo);

    Assert.AreEqual(0, lApi.NotificationCalls);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lProbe.Free;
  end;
end;

procedure TAccessibilityHintTests.UninstallDuringObservedMouseEnterDoesNotReadFreedHook;
var
  lApi: IHintTestUiaApi;
  lForm: TForm;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
  lPanel: TPanel;
  lProbe: THintUninstallProbe;
begin
  TAccessibilityManager.Uninstall;
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lForm := TForm.Create(nil);
  lProbe := THintUninstallProbe.Create;
  try
    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.OnMouseEnter := lProbe.HandleMouseEnter;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    lApi.SetClientsAreListening(True);
    TAccessibilityManager.Install(Application);

    lPanel.Perform(CM_MOUSEENTER, 0, 0);

    Assert.AreEqual(0, TAccessibilityManagerInternals.InstalledFormCount);
    Assert.AreEqual(0, lApi.NotificationCalls);
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lProbe.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityHintTests.VisibleHintShortPartAfterLongPartIsSuppressed;
var
  lApi: IHintTestUiaApi;
  lCanShow: Boolean;
  lController: TAccessibilityHintController;
  lForm: TForm;
  lHintInfo: Vcl.Controls.THintInfo;
  lHintStr: string;
  lLabel: TLabel;
  lOriginalHint: TNotifyEvent;
  lOriginalHintText: string;
  lOriginalShowHint: TShowHintEvent;
  lProvider: IAccessibilityProviderNode;
  lShowHint: TShowHintEvent;
begin
  lOriginalHint := Application.OnHint;
  lOriginalShowHint := Application.OnShowHint;
  lOriginalHintText := Application.Hint;
  lApi := THintTestUiaApi.Create;
  lProvider := TAccessibilityProviderFactory.CreateRoot([703], 0, lApi);
  lForm := TForm.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Upload';
    lLabel.Hint := 'Short hint|Long help text';
    lLabel.Parent := lForm;
    lApi.SetClientsAreListening(True);

    lController := TAccessibilityHintController.Create(Application, lProvider, lApi);
    try
      Application.Hint := 'Long help text';
      lShowHint := Application.OnShowHint;
      lHintStr := 'Short hint';
      lCanShow := True;
      lHintInfo := Default(Vcl.Controls.THintInfo);
      lHintInfo.HintControl := lLabel;

      lShowHint(lHintStr, lCanShow, lHintInfo);

      Assert.AreEqual(1, lApi.NotificationCalls);
      Assert.AreEqual('Long help text', lApi.LastDisplayString);
    finally
      lController.Free;
    end;
  finally
    Application.OnHint := nil;
    Application.Hint := lOriginalHintText;
    Application.OnHint := lOriginalHint;
    Application.OnShowHint := lOriginalShowHint;
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityHintTests);

end.
