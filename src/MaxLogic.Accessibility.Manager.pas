unit MaxLogic.Accessibility.Manager;

interface

uses
  Vcl.Forms;

type
  IAccessibilityFormInstaller = interface
    ['{F0C5F5C3-2916-4C87-8709-54148F1C31D6}']
    procedure InstallForm(aForm: TCustomForm);
  end;

  TAccessibilityManager = record
  public
    class procedure Install(aApplication: TApplication); overload; static;
    class procedure Install(aForm: TCustomForm); overload; static;
    class procedure Uninstall; static;
  end;

  TAccessibilityManagerInternals = record
  public
    class function InstalledFormCount: Integer; static;
    class procedure SetFormInstaller(const aInstaller: IAccessibilityFormInstaller); static;
  end;

implementation

uses
  System.Classes, System.SysUtils;

type
  TAccessibilityInstalledFormMarker = class(TComponent)
  public
    class function FindOn(aForm: TCustomForm): TAccessibilityInstalledFormMarker; static;
  end;

  TAccessibilityManagerState = class
  private
    fAppInstalled: Boolean;
    fFormInstaller: IAccessibilityFormInstaller;
    fPreviousActiveFormChange: TNotifyEvent;
    fScreenHookInstalled: Boolean;
    procedure ActiveFormChanged(aSender: TObject);
    procedure HookScreen;
    procedure RemoveInstalledMarkers;
    procedure RestoreScreenHook;
    procedure ScanCurrentForms;
  public
    constructor Create;
    destructor Destroy; override;
    function InstalledFormCount: Integer;
    procedure InstallApplication(aApplication: TApplication);
    procedure InstallForm(aForm: TCustomForm);
    procedure SetFormInstaller(const aInstaller: IAccessibilityFormInstaller);
    procedure Uninstall;
  end;

var
  gManagerState: TAccessibilityManagerState;

function SameNotifyEvent(const aLeft: TNotifyEvent; const aRight: TNotifyEvent): Boolean;
begin
  Result := (TMethod(aLeft).Code = TMethod(aRight).Code) and (TMethod(aLeft).Data = TMethod(aRight).Data);
end;

function ManagerState: TAccessibilityManagerState;
begin
  if gManagerState = nil then
  begin
    gManagerState := TAccessibilityManagerState.Create;
  end;

  Result := gManagerState;
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
  if aApplication = nil then
  begin
    raise EArgumentException.Create('Application must not be nil.');
  end;

  if not fAppInstalled then
  begin
    fAppInstalled := True;
    HookScreen;
  end;

  ScanCurrentForms;
end;

procedure TAccessibilityManagerState.InstallForm(aForm: TCustomForm);
begin
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  if TAccessibilityInstalledFormMarker.FindOn(aForm) <> nil then
  begin
    Exit;
  end;

  if fFormInstaller <> nil then
  begin
    fFormInstaller.InstallForm(aForm);
  end;

  TAccessibilityInstalledFormMarker.Create(aForm);
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
    InstallForm(Screen.Forms[i]);
  end;
end;

procedure TAccessibilityManagerState.SetFormInstaller(const aInstaller: IAccessibilityFormInstaller);
begin
  fFormInstaller := aInstaller;
end;

procedure TAccessibilityManagerState.Uninstall;
begin
  fAppInstalled := False;
  RemoveInstalledMarkers;
  RestoreScreenHook;
end;

class procedure TAccessibilityManager.Install(aApplication: TApplication);
begin
  ManagerState.InstallApplication(aApplication);
end;

class procedure TAccessibilityManager.Install(aForm: TCustomForm);
begin
  ManagerState.InstallForm(aForm);
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

initialization
  gManagerState := TAccessibilityManagerState.Create;

finalization
  gManagerState.Free;

end.
