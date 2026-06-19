unit MaxLogic.Accessibility.Manager;

interface

uses
  Vcl.Forms,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner;

type
  IAccessibilityFormInstaller = interface
    ['{F0C5F5C3-2916-4C87-8709-54148F1C31D6}']
    procedure InstallForm(aForm: TCustomForm);
  end;

  TAccessibilityManager = record
  public
    class procedure Install(aApplication: TApplication); overload; static;
    class procedure Install(aApplication: TApplication; const aRegistry: IAccessibilityAdapterRegistry); overload; static;
    class procedure Install(aForm: TCustomForm); overload; static;
    class procedure Install(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry); overload; static;
    class procedure Uninstall; static;
  end;

  TAccessibilityManagerInternals = record
  public
    class function InstalledFormCount: Integer; static;
    class procedure SetFormInstaller(const aInstaller: IAccessibilityFormInstaller); static;
    class procedure SetUiaApi(const aApi: IAccessibilityUiaApi); static;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.SysUtils, Winapi.Messages, Winapi.Windows, Vcl.Controls,
  MaxLogic.Accessibility.Hints, MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

type
  TAccessibilityFormWindowHook = class;

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
    fForm: TCustomForm;
    fOriginalWindowProc: TWndMethod;
    fPassive: Boolean;
    fProvider: IAccessibilityProviderNode;
    procedure Detach;
    procedure DisconnectProvider;
    function Passivate: Boolean;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    class procedure ReleaseRetainedHooks; static;
    constructor Create(aForm: TCustomForm; const aProvider: IAccessibilityProviderNode;
      const aApi: IAccessibilityUiaApi); reintroduce;
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
  gRetainedFormHooks: TList<TAccessibilityFormWindowHook>;

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
begin
  if fHook <> nil then
  begin
    Exit;
  end;

  fRegistry := aRegistry;
  fHook := TAccessibilityFormWindowHook.Create(aForm,
    TAccessibilityVclProviderBuilder.BuildForm(aForm, aRegistry, aApi), aApi);
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
  fForm := aForm;
  fProvider := aProvider;
  fOriginalWindowProc := aForm.WindowProc;
  fForm.FreeNotification(Self);
  fForm.WindowProc := WindowProc;
end;

destructor TAccessibilityFormWindowHook.Destroy;
begin
  if not fPassive then
  begin
    Detach;
  end;

  DisconnectProvider;
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
  lResult: Winapi.Windows.LRESULT;
begin
  if (not fPassive) and (fForm <> nil) and (fProvider <> nil) and (aMessage.Msg = WM_GETOBJECT) and
    TAccessibilityProviderWindowMessages.TryHandleGetObject(fForm.Handle, aMessage.WParam, aMessage.LParam,
    fProvider.RawElementProvider, fApi, lResult) then
  begin
    aMessage.Result := lResult;
    Exit;
  end;

  fOriginalWindowProc(aMessage);
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
    InstallFormWithRegistry(Screen.Forms[i], fApplicationRegistry);
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

initialization
  gManagerState := TAccessibilityManagerState.Create;

finalization
  gManagerState.Free;
  TAccessibilityFormWindowHook.ReleaseRetainedHooks;
  gRetainedFormHooks.Free;

end.
