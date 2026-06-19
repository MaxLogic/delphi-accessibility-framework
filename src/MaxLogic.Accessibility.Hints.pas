unit MaxLogic.Accessibility.Hints;

interface

uses
  System.Classes, System.Generics.Collections, Vcl.Controls, Vcl.Forms,
  MaxLogic.Accessibility.ProviderCore;

type
  TAccessibilityHintController = class(TComponent)
  private
    fApi: IAccessibilityUiaApi;
    fApplication: TApplication;
    fDispatchDepth: Integer;
    fHookInstalled: Boolean;
    fLastNotificationText: string;
    fObservers: TList<TComponent>;
    fPassive: Boolean;
    fPendingBalloonFollowUpText: string;
    fPreviousHint: TNotifyEvent;
    fPreviousShowHint: TShowHintEvent;
    fProvider: IAccessibilityProviderNode;
    fPendingBalloonFollowUpHint: string;
    fReleaseAfterDispatch: Boolean;
    procedure ApplicationHint(aSender: TObject);
    procedure ApplicationShowHint(var aHintStr: string; var aCanShow: Boolean;
      var aHintInfo: Vcl.Controls.THintInfo);
    procedure BeginDispatch;
    procedure Detach;
    procedure DisconnectProvider;
    procedure EndDispatch;
    procedure FireDefaultHintAction;
    function NotifyBalloonHintCore(const aTitle: string; const aDescription: string;
      const aFollowUpHint: string): Boolean;
    procedure NotifyControlCustomHint(aControl: TControl);
    function NotifyText(const aText: string; const aActivityId: WideString): Boolean;
    procedure ReleaseObservers;
    function ShouldSuppressVisibleHint(const aHint: string; const aHintInfo: Vcl.Controls.THintInfo): Boolean;
  public
    constructor Create(aApplication: TApplication; const aProvider: IAccessibilityProviderNode;
      const aApi: IAccessibilityUiaApi); reintroduce;
    destructor Destroy; override;
    function Passivate: Boolean;
    procedure NotifyBalloonHint(const aTitle: string; const aDescription: string); overload;
    procedure NotifyBalloonHint(aHint: TCustomHint); overload;
    procedure NotifyVisibleHint(const aHint: string);
    procedure ObserveForm(aForm: TCustomForm);
  end;

implementation

uses
  System.SysUtils, Winapi.Messages, Vcl.StdActns,
  MaxLogic.Accessibility.Text, MaxLogic.Accessibility.UIAutomationCore;

type
  TAccessibilityHintFormObserver = class;

  TAccessibilityHintControlHook = class(TComponent)
  private
    fControl: TWinControl;
    fDispatchDepth: Integer;
    fObserver: TAccessibilityHintFormObserver;
    fOriginalWindowProc: TWndMethod;
    fPassive: Boolean;
    fReleaseAfterDispatch: Boolean;
    procedure BeginDispatch;
    procedure Detach;
    procedure EndDispatch;
    function Passivate: Boolean;
    procedure RetainPassively;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    constructor Create(aObserver: TAccessibilityHintFormObserver; aControl: TWinControl); reintroduce;
    destructor Destroy; override;
    function IsDetached: Boolean;
    procedure WindowProc(var aMessage: TMessage);
  end;

  TAccessibilityHintFormObserver = class(TComponent)
  private
    fController: TAccessibilityHintController;
    fForm: TCustomForm;
    fHooks: TObjectDictionary<TWinControl, TAccessibilityHintControlHook>;
    procedure HookWinControls(aControl: TWinControl);
  public
    constructor Create(aController: TAccessibilityHintController; aForm: TCustomForm); reintroduce;
    destructor Destroy; override;
    procedure ControlChanged;
    procedure ControlMouseEnter(aHookControl: TWinControl; const aMessage: TMessage);
    function Observes(aForm: TCustomForm): Boolean;
    procedure Refresh;
  end;

var
  gRetainedHintControllers: TList<TAccessibilityHintController>;
  gRetainedHintControlHooks: TList<TAccessibilityHintControlHook>;

function SameNotifyEvent(const aLeft: TNotifyEvent; const aRight: TNotifyEvent): Boolean;
begin
  Result := (TMethod(aLeft).Code = TMethod(aRight).Code) and (TMethod(aLeft).Data = TMethod(aRight).Data);
end;

function SameShowHintEvent(const aLeft: TShowHintEvent; const aRight: TShowHintEvent): Boolean;
begin
  Result := (TMethod(aLeft).Code = TMethod(aRight).Code) and (TMethod(aLeft).Data = TMethod(aRight).Data);
end;

function SameWndMethod(const aLeft: TWndMethod; const aRight: TWndMethod): Boolean;
begin
  Result := (TMethod(aLeft).Code = TMethod(aRight).Code) and (TMethod(aLeft).Data = TMethod(aRight).Data);
end;

procedure SplitVisibleHintParts(const aHint: string; out aShortHint: string; out aLongHint: string);
begin
  aShortHint := TAccessibilityText.Clean(GetShortHint(aHint));
  aLongHint := TAccessibilityText.Clean(GetLongHint(aHint));
end;

function HintDisplayText(const aHint: string): string;
begin
  Result := TAccessibilityText.Clean(GetLongHint(aHint));
  if Result = '' then
  begin
    Result := TAccessibilityText.Clean(GetShortHint(aHint));
  end;
end;

function BalloonDisplayText(const aTitle: string; const aDescription: string): string;
var
  lDescription: string;
  lTitle: string;
begin
  lTitle := TAccessibilityText.Clean(aTitle);
  lDescription := TAccessibilityText.Clean(aDescription);
  if (lTitle <> '') and (lDescription <> '') then
  begin
    Result := lTitle + ': ' + lDescription;
  end else if lTitle <> '' then
  begin
    Result := lTitle;
  end else begin
    Result := lDescription;
  end;
end;

function CustomHintFor(aControl: TControl): TCustomHint;
begin
  Result := nil;
  if aControl <> nil then
  begin
    Result := aControl.CustomHint;
  end;
end;

function StripBalloonImageIndex(const aDescription: string): string;
var
  lDelimiter: Integer;
begin
  Result := TAccessibilityText.Clean(aDescription);
  lDelimiter := Pos('|', Result);
  if lDelimiter > 0 then
  begin
    Result := TAccessibilityText.Clean(Copy(Result, 1, Pred(lDelimiter)));
  end;
end;

procedure ReleaseRetainedHintControlHooks;
var
  lHook: TAccessibilityHintControlHook;
begin
  if gRetainedHintControlHooks = nil then
  begin
    Exit;
  end;

  while gRetainedHintControlHooks.Count > 0 do
  begin
    lHook := gRetainedHintControlHooks[Pred(gRetainedHintControlHooks.Count)];
    gRetainedHintControlHooks.Delete(Pred(gRetainedHintControlHooks.Count));
    lHook.fPassive := False;
    lHook.Detach;
    lHook.Free;
  end;
end;

procedure ReleaseRetainedHintControllers;
var
  lController: TAccessibilityHintController;
begin
  if gRetainedHintControllers = nil then
  begin
    Exit;
  end;

  while gRetainedHintControllers.Count > 0 do
  begin
    lController := gRetainedHintControllers[Pred(gRetainedHintControllers.Count)];
    gRetainedHintControllers.Delete(Pred(gRetainedHintControllers.Count));
    lController.fPassive := False;
    lController.Detach;
    lController.Free;
  end;
end;

constructor TAccessibilityHintControlHook.Create(aObserver: TAccessibilityHintFormObserver; aControl: TWinControl);
begin
  inherited Create(nil);
  fObserver := aObserver;
  fControl := aControl;
  fOriginalWindowProc := aControl.WindowProc;
  fControl.FreeNotification(Self);
  fControl.WindowProc := WindowProc;
end;

destructor TAccessibilityHintControlHook.Destroy;
begin
  if not fPassive then
  begin
    Detach;
  end;

  inherited Destroy;
end;

procedure TAccessibilityHintControlHook.BeginDispatch;
begin
  Inc(fDispatchDepth);
end;

procedure TAccessibilityHintControlHook.Detach;
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

procedure TAccessibilityHintControlHook.EndDispatch;
var
  lReleaseAfterDispatch: Boolean;
begin
  Dec(fDispatchDepth);
  lReleaseAfterDispatch := (fDispatchDepth = 0) and fReleaseAfterDispatch;
  if lReleaseAfterDispatch then
  begin
    Free;
  end;
end;

function TAccessibilityHintControlHook.IsDetached: Boolean;
begin
  Result := fControl = nil;
end;

procedure TAccessibilityHintControlHook.Notification(aComponent: TComponent; aOperation: TOperation);
begin
  inherited Notification(aComponent, aOperation);
  if (aOperation = opRemove) and (aComponent = fControl) then
  begin
    if SameWndMethod(fControl.WindowProc, WindowProc) then
    begin
      fControl.WindowProc := fOriginalWindowProc;
    end;

    fControl := nil;
  end;
end;

function TAccessibilityHintControlHook.Passivate: Boolean;
begin
  Result := False;
  fObserver := nil;
  if fDispatchDepth > 0 then
  begin
    if (fControl <> nil) and (not SameWndMethod(fControl.WindowProc, WindowProc)) then
    begin
      RetainPassively;
    end else begin
      if fControl <> nil then
      begin
        Detach;
      end;

      fPassive := True;
      fReleaseAfterDispatch := True;
    end;

    Result := True;
    Exit;
  end;

  if fControl = nil then
  begin
    Exit;
  end;

  if SameWndMethod(fControl.WindowProc, WindowProc) then
  begin
    Detach;
  end else begin
    RetainPassively;
    Result := True;
  end;
end;

procedure TAccessibilityHintControlHook.RetainPassively;
begin
  fPassive := True;
  if gRetainedHintControlHooks = nil then
  begin
    gRetainedHintControlHooks := TList<TAccessibilityHintControlHook>.Create;
  end;

  if not gRetainedHintControlHooks.Contains(Self) then
  begin
    gRetainedHintControlHooks.Add(Self);
  end;
end;

procedure TAccessibilityHintControlHook.WindowProc(var aMessage: TMessage);
var
  lOriginalWindowProc: TWndMethod;
begin
  BeginDispatch;
  try
    lOriginalWindowProc := fOriginalWindowProc;

    if (not fPassive) and (fObserver <> nil) and (aMessage.Msg = CM_MOUSEENTER) then
    begin
      lOriginalWindowProc(aMessage);
      if (not fPassive) and (fObserver <> nil) and (fControl <> nil) then
      begin
        fObserver.ControlMouseEnter(fControl, aMessage);
      end;
      Exit;
    end;

    if (not fPassive) and (fObserver <> nil) and
      (((aMessage.Msg = CM_CONTROLCHANGE) and (aMessage.LParam <> 0)) or
      ((aMessage.Msg = CM_CONTROLLISTCHANGE) and (aMessage.LParam = 0))) then
    begin
      fObserver.ControlChanged;
    end;

    lOriginalWindowProc(aMessage);
  finally
    EndDispatch;
  end;
end;

constructor TAccessibilityHintFormObserver.Create(aController: TAccessibilityHintController; aForm: TCustomForm);
begin
  inherited Create(nil);
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  fController := aController;
  fForm := aForm;
  fHooks := TObjectDictionary<TWinControl, TAccessibilityHintControlHook>.Create([]);
  Refresh;
end;

destructor TAccessibilityHintFormObserver.Destroy;
var
  lHook: TAccessibilityHintControlHook;
begin
  for lHook in fHooks.Values do
  begin
    if not lHook.Passivate then
    begin
      lHook.Free;
    end;
  end;

  fHooks.Free;
  inherited Destroy;
end;

procedure TAccessibilityHintFormObserver.ControlChanged;
begin
  Refresh;
end;

procedure TAccessibilityHintFormObserver.ControlMouseEnter(aHookControl: TWinControl; const aMessage: TMessage);
var
  lControl: TControl;
begin
  if (fController = nil) or (aHookControl = nil) then
  begin
    Exit;
  end;

  if aMessage.LParam = 0 then
  begin
    lControl := aHookControl;
  end else begin
    lControl := TControl(aMessage.LParam);
    if (lControl = nil) or (lControl is TWinControl) or (lControl.Parent <> aHookControl) then
    begin
      Exit;
    end;
  end;

  fController.NotifyControlCustomHint(lControl);
end;

procedure TAccessibilityHintFormObserver.HookWinControls(aControl: TWinControl);
var
  i: Integer;
  lHook: TAccessibilityHintControlHook;
begin
  if fHooks.TryGetValue(aControl, lHook) and lHook.IsDetached then
  begin
    fHooks.Remove(aControl);
    lHook.Free;
  end;

  if not fHooks.ContainsKey(aControl) then
  begin
    fHooks.Add(aControl, TAccessibilityHintControlHook.Create(Self, aControl));
  end;

  for i := 0 to Pred(aControl.ControlCount) do
  begin
    if aControl.Controls[i] is TWinControl then
    begin
      HookWinControls(TWinControl(aControl.Controls[i]));
    end;
  end;
end;

function TAccessibilityHintFormObserver.Observes(aForm: TCustomForm): Boolean;
begin
  Result := fForm = aForm;
end;

procedure TAccessibilityHintFormObserver.Refresh;
begin
  HookWinControls(fForm);
end;

constructor TAccessibilityHintController.Create(aApplication: TApplication;
  const aProvider: IAccessibilityProviderNode; const aApi: IAccessibilityUiaApi);
begin
  inherited Create(nil);
  fApi := aApi;
  fApplication := aApplication;
  fObservers := TList<TComponent>.Create;
  fProvider := aProvider;
  if fApplication <> nil then
  begin
    fPreviousHint := fApplication.OnHint;
    fPreviousShowHint := fApplication.OnShowHint;
    fApplication.OnHint := ApplicationHint;
    fApplication.OnShowHint := ApplicationShowHint;
    fHookInstalled := True;
  end;
end;

destructor TAccessibilityHintController.Destroy;
begin
  if not fPassive then
  begin
    Detach;
  end;

  ReleaseObservers;
  fObservers.Free;
  DisconnectProvider;
  inherited Destroy;
end;

procedure TAccessibilityHintController.ApplicationHint(aSender: TObject);
begin
  BeginDispatch;
  try
    if Assigned(fPreviousHint) then
    begin
      fPreviousHint(aSender);
    end else begin
      FireDefaultHintAction;
    end;

    if (not fPassive) and (fApplication <> nil) then
    begin
      NotifyVisibleHint(fApplication.Hint);
    end;
  finally
    EndDispatch;
  end;
end;

procedure TAccessibilityHintController.ApplicationShowHint(var aHintStr: string; var aCanShow: Boolean;
  var aHintInfo: Vcl.Controls.THintInfo);
var
  lCustomHint: TCustomHint;
begin
  BeginDispatch;
  try
    if Assigned(fPreviousShowHint) then
    begin
      fPreviousShowHint(aHintStr, aCanShow, aHintInfo);
    end;

    if fPassive or not aCanShow then
    begin
      Exit;
    end;

    lCustomHint := CustomHintFor(aHintInfo.HintControl);
    if lCustomHint <> nil then
    begin
      NotifyBalloonHint(lCustomHint);
    end else if ShouldSuppressVisibleHint(aHintStr, aHintInfo) then
    begin
      Exit;
    end else begin
      NotifyVisibleHint(aHintStr);
    end;
  finally
    EndDispatch;
  end;
end;

procedure TAccessibilityHintController.BeginDispatch;
begin
  Inc(fDispatchDepth);
end;

procedure TAccessibilityHintController.Detach;
begin
  if (fApplication <> nil) and fHookInstalled then
  begin
    if SameNotifyEvent(fApplication.OnHint, ApplicationHint) then
    begin
      fApplication.OnHint := fPreviousHint;
    end;

    if SameShowHintEvent(fApplication.OnShowHint, ApplicationShowHint) then
    begin
      fApplication.OnShowHint := fPreviousShowHint;
    end;
  end;

  fApplication := nil;
  fPreviousHint := nil;
  fPreviousShowHint := nil;
  fHookInstalled := False;
end;

procedure TAccessibilityHintController.DisconnectProvider;
begin
  if fProvider <> nil then
  begin
    fProvider.Disconnect;
    fProvider := nil;
  end;

  fApi := nil;
end;

procedure TAccessibilityHintController.EndDispatch;
var
  lReleaseAfterDispatch: Boolean;
begin
  Dec(fDispatchDepth);
  lReleaseAfterDispatch := (fDispatchDepth = 0) and fReleaseAfterDispatch;
  if lReleaseAfterDispatch then
  begin
    if gRetainedHintControllers <> nil then
    begin
      gRetainedHintControllers.Remove(Self);
    end;

    Free;
  end;
end;

procedure TAccessibilityHintController.FireDefaultHintAction;
begin
  if fApplication = nil then
  begin
    Exit;
  end;

  with THintAction.Create(fApplication) do
  begin
    Hint := fApplication.Hint;
    try
      Execute;
    finally
      Free;
    end;
  end;
end;

function TAccessibilityHintController.NotifyBalloonHintCore(const aTitle: string; const aDescription: string;
  const aFollowUpHint: string): Boolean;
var
  lDescription: string;
  lFollowUpHint: string;
  lTitle: string;
begin
  lTitle := TAccessibilityText.Clean(aTitle);
  lDescription := TAccessibilityText.Clean(aDescription);
  lFollowUpHint := TAccessibilityText.Clean(aFollowUpHint);
  Result := NotifyText(BalloonDisplayText(aTitle, aDescription), 'vcl-balloon-hint');
  if not Result then
  begin
    Exit;
  end;

  if lDescription <> '' then
  begin
    fPendingBalloonFollowUpText := lDescription;
  end else begin
    fPendingBalloonFollowUpText := lTitle;
  end;
  fPendingBalloonFollowUpHint := lFollowUpHint;
end;

procedure TAccessibilityHintController.NotifyControlCustomHint(aControl: TControl);
var
  lDescription: string;
  lFollowUpHint: string;
  lHint: TCustomHint;
  lTitle: string;
begin
  if (aControl = nil) or (not aControl.ShowHint) or (csDesigning in aControl.ComponentState) then
  begin
    Exit;
  end;

  lHint := CustomHintFor(aControl);
  if lHint = nil then
  begin
    Exit;
  end;

  if aControl.Hint = '' then
  begin
    Exit;
  end;

  lTitle := TAccessibilityText.Clean(GetShortHint(aControl.Hint));
  if Pos('|', aControl.Hint) <> 0 then
  begin
    lFollowUpHint := GetLongHint(aControl.Hint);
    lDescription := StripBalloonImageIndex(lFollowUpHint);
  end else begin
    lDescription := '';
    lFollowUpHint := GetShortHint(aControl.Hint);
  end;

  NotifyBalloonHintCore(lTitle, lDescription, lFollowUpHint);
end;

function TAccessibilityHintController.NotifyText(const aText: string; const aActivityId: WideString): Boolean;
var
  lText: string;
begin
  Result := False;
  lText := TAccessibilityText.Clean(aText);
  if (lText = '') or (lText = fLastNotificationText) or (fProvider = nil) then
  begin
    Exit;
  end;

  Result := TAccessibilityProviderEvents.RaiseNotification(fProvider.RawElementProvider, NotificationKind_Other,
    NotificationProcessing_MostRecent, lText, aActivityId, fApi);
  if Result then
  begin
    fLastNotificationText := lText;
  end;
end;

procedure TAccessibilityHintController.ObserveForm(aForm: TCustomForm);
var
  lObserver: TComponent;
begin
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  for lObserver in fObservers do
  begin
    if TAccessibilityHintFormObserver(lObserver).Observes(aForm) then
    begin
      TAccessibilityHintFormObserver(lObserver).Refresh;
      Exit;
    end;
  end;

  fObservers.Add(TAccessibilityHintFormObserver.Create(Self, aForm));
end;

function TAccessibilityHintController.Passivate: Boolean;
begin
  Result := False;
  DisconnectProvider;
  ReleaseObservers;
  if fDispatchDepth > 0 then
  begin
    Detach;
    fPassive := True;
    fReleaseAfterDispatch := True;
    Result := True;
    if gRetainedHintControllers = nil then
    begin
      gRetainedHintControllers := TList<TAccessibilityHintController>.Create;
    end;

    if not gRetainedHintControllers.Contains(Self) then
    begin
      gRetainedHintControllers.Add(Self);
    end;
    Exit;
  end;

  if (fApplication = nil) or not fHookInstalled then
  begin
    Exit;
  end;

  if SameNotifyEvent(fApplication.OnHint, ApplicationHint) and
    SameShowHintEvent(fApplication.OnShowHint, ApplicationShowHint) then
  begin
    Detach;
  end else begin
    fPassive := True;
    Result := True;
    if gRetainedHintControllers = nil then
    begin
      gRetainedHintControllers := TList<TAccessibilityHintController>.Create;
    end;

    if not gRetainedHintControllers.Contains(Self) then
    begin
      gRetainedHintControllers.Add(Self);
    end;
  end;
end;

procedure TAccessibilityHintController.ReleaseObservers;
var
  lObserver: TComponent;
begin
  for lObserver in fObservers do
  begin
    lObserver.Free;
  end;

  fObservers.Clear;
end;

function TAccessibilityHintController.ShouldSuppressVisibleHint(const aHint: string;
  const aHintInfo: Vcl.Controls.THintInfo): Boolean;
var
  lLongHint: string;
  lShortHint: string;
begin
  Result := False;
  if aHintInfo.HintControl = nil then
  begin
    Exit;
  end;

  SplitVisibleHintParts(aHintInfo.HintControl.Hint, lShortHint, lLongHint);
  Result := (lShortHint <> '') and (lLongHint <> '') and (TAccessibilityText.Clean(aHint) = lShortHint) and
    (lLongHint = fLastNotificationText);
end;

procedure TAccessibilityHintController.NotifyBalloonHint(const aTitle: string; const aDescription: string);
begin
  if TAccessibilityText.Clean(aDescription) <> '' then
  begin
    NotifyBalloonHintCore(aTitle, aDescription, aDescription);
  end else begin
    NotifyBalloonHintCore(aTitle, aDescription, aTitle);
  end;
end;

procedure TAccessibilityHintController.NotifyBalloonHint(aHint: TCustomHint);
begin
  if aHint = nil then
  begin
    NotifyBalloonHint('', '');
  end else begin
    NotifyBalloonHint(aHint.Title, aHint.Description);
  end;
end;

procedure TAccessibilityHintController.NotifyVisibleHint(const aHint: string);
var
  lCleanHint: string;
  lPendingFollowUpHint: string;
  lPendingFollowUpText: string;
  lStrippedHint: string;
  lSuppressAsBalloonFollowUp: Boolean;
  lText: string;
begin
  lText := HintDisplayText(aHint);
  lCleanHint := TAccessibilityText.Clean(aHint);
  lStrippedHint := StripBalloonImageIndex(aHint);
  lPendingFollowUpHint := fPendingBalloonFollowUpHint;
  lPendingFollowUpText := fPendingBalloonFollowUpText;
  lSuppressAsBalloonFollowUp := (lText <> '') and (lPendingFollowUpText <> '') and
    ((lText = lPendingFollowUpText) or (lCleanHint = lPendingFollowUpText) or
    (lStrippedHint = lPendingFollowUpText));
  if (not lSuppressAsBalloonFollowUp) and (lText <> '') and (lPendingFollowUpHint <> '') then
  begin
    lSuppressAsBalloonFollowUp := (lText = lPendingFollowUpHint) or (lCleanHint = lPendingFollowUpHint) or
      (lStrippedHint = lPendingFollowUpHint);
  end;
  if lText <> '' then
  begin
    fPendingBalloonFollowUpHint := '';
    fPendingBalloonFollowUpText := '';
  end;

  if lSuppressAsBalloonFollowUp then
  begin
    Exit;
  end;

  NotifyText(lText, 'vcl-hint');
end;

initialization

finalization
  ReleaseRetainedHintControlHooks;
  ReleaseRetainedHintControllers;
  gRetainedHintControlHooks.Free;
  gRetainedHintControllers.Free;

end.
