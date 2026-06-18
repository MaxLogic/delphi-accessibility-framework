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
    procedure ApplicationInstallScansCurrentFormsAndIsIdempotent;
    [Test]
    procedure FormInstallIsScopedAndIdempotent;
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
  System.Classes, System.Generics.Collections, System.SysUtils, Vcl.Forms,
  MaxLogic.Accessibility.Manager;

type
  IFormInstallRecorder = interface(IAccessibilityFormInstaller)
    ['{89B798B7-0880-4AE5-B799-58E4EB14DF22}']
    function CountFor(aForm: TCustomForm): Integer;
    procedure FailNextInstall;
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

procedure ResetManager;
begin
  TAccessibilityManager.Uninstall;
  TAccessibilityManagerInternals.SetFormInstaller(nil);
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
