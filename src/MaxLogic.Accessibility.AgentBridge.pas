unit MaxLogic.Accessibility.AgentBridge;

interface

type
  TAccessibilityAgentBridge = record
  public
    class function Execute(const aRequestJson: string): string; static;
    class function MutationEnabled: Boolean; static;
    class procedure SetMutationEnabled(aValue: Boolean); static;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.JSON, System.SysUtils, System.Types, System.TypInfo,
  Winapi.Messages, Winapi.Windows, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  MaxLogic.Accessibility.Framework, MaxLogic.Accessibility.Scanner, MaxLogic.Accessibility.Text;

type
  TAccessibilityAgentBridgeState = class(TComponent)
  private
    fControlsByRef: TDictionary<string, TControl>;
    fForm: TCustomForm;
    fNextRefIndex: Integer;
    fObservedControls: TList<TComponent>;
    fRefsByControl: TDictionary<TControl, string>;
    fSnapshotId: Integer;
    function BuildFormMap(aForm: TCustomForm): string;
    function ControlCanUseTab(aControl: TWinControl): Boolean;
    function ControlAtScreenPoint(aParent: TWinControl; const aPoint: TPoint): TControl;
    function ControlJson(aControl: TControl; const aParentRef: string; aDepth: Integer;
      const aTree: IAccessibilityScanTree; out aRef: string): TJSONObject;
    function ControlScreenRect(aControl: TControl): TRect;
    function ExecuteClick(aRequest: TJSONObject): string;
    function ExecuteFocus(aRequest: TJSONObject): string;
    function ExecuteFormMap(aRequest: TJSONObject): string;
    function ExecuteFormsList: string;
    function ExecuteHello: string;
    function ExecuteHitTest(aRequest: TJSONObject): string;
    function ExecuteKeyboardTab(aRequest: TJSONObject): string;
    function ExecuteSetText(aRequest: TJSONObject; aAppend: Boolean): string;
    function Failure(const aErrorCode: string; const aMessage: string): string;
    function FormSummaryJson(aForm: TCustomForm): TJSONObject;
    function HitControlAt(const aPoint: TPoint): TControl;
    procedure AddChildControls(aParent: TWinControl; const aParentRef: string; aDepth: Integer;
      aControls: TJSONArray; const aTree: IAccessibilityScanTree);
    procedure AddControlState(aJson: TJSONObject; aControl: TControl; const aTree: IAccessibilityScanTree);
    procedure ClearSnapshot;
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
    function RefForControl(aControl: TControl; out aRef: string): Boolean;
    function RegisterControl(aControl: TControl): string;
    function ResolveControl(aRequest: TJSONObject; out aControl: TControl): Boolean;
    function ResolveForm(aRequest: TJSONObject): TCustomForm;
    function SuccessMutation: string;
    procedure CollectTabControls(aParent: TWinControl; aControls: TList<TWinControl>);
    procedure FocusWinControl(aControl: TWinControl);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    function Execute(aRequest: TJSONObject): string;
  end;

var
  gBridgeState: TAccessibilityAgentBridgeState;
  gMutationEnabled: Boolean;

function AddBool(aObject: TJSONObject; const aName: string; aValue: Boolean): TJSONObject;
begin
  Result := aObject.AddPair(aName, TJSONBool.Create(aValue));
end;

function AddInt(aObject: TJSONObject; const aName: string; aValue: Int64): TJSONObject;
begin
  Result := aObject.AddPair(aName, TJSONNumber.Create(aValue));
end;

function AddUInt(aObject: TJSONObject; const aName: string; aValue: UInt64): TJSONObject;
begin
  Result := aObject.AddPair(aName, TJSONNumber.Create(aValue));
end;

function JsonObjectToString(aObject: TJSONObject): string;
begin
  try
    Result := aObject.ToJSON;
  finally
    aObject.Free;
  end;
end;

function FailureResponse(const aErrorCode: string; const aMessage: string): string;
var
  lResponse: TJSONObject;
begin
  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', False);
  lResponse.AddPair('errorCode', aErrorCode);
  lResponse.AddPair('message', aMessage);
  Result := JsonObjectToString(lResponse);
end;

function PointJson(const aPoint: TPoint): TJSONObject;
begin
  Result := TJSONObject.Create;
  AddInt(Result, 'x', aPoint.X);
  AddInt(Result, 'y', aPoint.Y);
end;

function RectJson(const aRect: TRect): TJSONObject;
begin
  Result := TJSONObject.Create;
  AddInt(Result, 'left', aRect.Left);
  AddInt(Result, 'top', aRect.Top);
  AddInt(Result, 'right', aRect.Right);
  AddInt(Result, 'bottom', aRect.Bottom);
  AddInt(Result, 'width', aRect.Width);
  AddInt(Result, 'height', aRect.Height);
end;

function RequestString(aRequest: TJSONObject; const aName: string): string;
var
  lValue: TJSONValue;
begin
  Result := '';
  lValue := aRequest.GetValue(aName);
  if lValue <> nil then
  begin
    Result := lValue.Value;
  end;
end;

function RequestInt(aRequest: TJSONObject; const aName: string; out aValue: Integer): Boolean;
var
  lValue: TJSONValue;
begin
  aValue := 0;
  lValue := aRequest.GetValue(aName);
  Result := (lValue <> nil) and TryStrToInt(lValue.Value, aValue);
end;

function RequestUInt64(aRequest: TJSONObject; const aName: string; out aValue: UInt64): Boolean;
var
  lValue: TJSONValue;
begin
  aValue := 0;
  lValue := aRequest.GetValue(aName);
  Result := (lValue <> nil) and TryStrToUInt64(lValue.Value, aValue);
end;

function ReadStringProperty(aObject: TObject; const aPropertyName: string): string;
var
  lPropInfo: PPropInfo;
begin
  Result := '';
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    Result := TAccessibilityText.Clean(GetStrProp(aObject, lPropInfo));
  end;
end;

function WriteStringProperty(aObject: TObject; const aPropertyName: string; const aValue: string): Boolean;
var
  lPropInfo: PPropInfo;
begin
  Result := False;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    SetStrProp(aObject, lPropInfo, aValue);
    Result := True;
  end;
end;

function BridgeState: TAccessibilityAgentBridgeState;
begin
  if gBridgeState = nil then
  begin
    gBridgeState := TAccessibilityAgentBridgeState.Create;
  end;
  Result := gBridgeState;
end;

constructor TAccessibilityAgentBridgeState.Create;
begin
  inherited Create(nil);
  fControlsByRef := TDictionary<string, TControl>.Create;
  fObservedControls := TList<TComponent>.Create;
  fRefsByControl := TDictionary<TControl, string>.Create;
end;

destructor TAccessibilityAgentBridgeState.Destroy;
begin
  ClearSnapshot;
  fRefsByControl.Free;
  fObservedControls.Free;
  fControlsByRef.Free;
  inherited Destroy;
end;

procedure TAccessibilityAgentBridgeState.AddChildControls(aParent: TWinControl; const aParentRef: string;
  aDepth: Integer; aControls: TJSONArray; const aTree: IAccessibilityScanTree);
var
  i: Integer;
  lChild: TControl;
  lChildRef: string;
begin
  for i := 0 to Pred(aParent.ControlCount) do
  begin
    lChild := aParent.Controls[i];
    aControls.AddElement(ControlJson(lChild, aParentRef, aDepth, aTree, lChildRef));
    if lChild is TWinControl then
    begin
      AddChildControls(TWinControl(lChild), lChildRef, Succ(aDepth), aControls, aTree);
    end;
  end;
end;

procedure TAccessibilityAgentBridgeState.AddControlState(aJson: TJSONObject; aControl: TControl;
  const aTree: IAccessibilityScanTree);
var
  lNode: IAccessibilityScanNode;
  lRect: TRect;
  lTargetPoints: TJSONObject;
begin
  aJson.AddPair('name', aControl.Name);
  aJson.AddPair('className', aControl.ClassName);
  aJson.AddPair('caption', ReadStringProperty(aControl, 'Caption'));
  aJson.AddPair('value', ReadStringProperty(aControl, 'Text'));
  aJson.AddPair('hint', TAccessibilityText.Clean(aControl.Hint));
  AddBool(aJson, 'visible', aControl.Visible);
  AddBool(aJson, 'enabled', aControl.Enabled);
  AddBool(aJson, 'focused', (aControl is TWinControl) and TWinControl(aControl).Focused);

  if aControl is TWinControl then
  begin
    AddBool(aJson, 'tabStop', TWinControl(aControl).TabStop);
    AddInt(aJson, 'tabOrder', TWinControl(aControl).TabOrder);
    AddUInt(aJson, 'handle', UInt64(NativeUInt(TWinControl(aControl).Handle)));
  end else begin
    AddBool(aJson, 'tabStop', False);
    AddInt(aJson, 'tabOrder', -1);
    AddUInt(aJson, 'handle', 0);
  end;

  lNode := nil;
  if aTree <> nil then
  begin
    lNode := aTree.FindNode(aControl);
  end;
  if lNode <> nil then
  begin
    aJson.AddPair('accessibleName', lNode.Name);
    aJson.AddPair('helpText', lNode.HelpText);
  end else begin
    aJson.AddPair('accessibleName', '');
    aJson.AddPair('helpText', '');
  end;

  lRect := ControlScreenRect(aControl);
  aJson.AddPair('screenRect', RectJson(lRect));

  lTargetPoints := TJSONObject.Create;
  lTargetPoints.AddPair('center', PointJson(Point(lRect.Left + (lRect.Width div 2), lRect.Top + (lRect.Height div 2))));
  aJson.AddPair('targetPoints', lTargetPoints);
end;

function TAccessibilityAgentBridgeState.BuildFormMap(aForm: TCustomForm): string;
var
  lControls: TJSONArray;
  lFormRef: string;
  lResponse: TJSONObject;
  lRoot: TJSONObject;
  lTree: IAccessibilityScanTree;
begin
  ClearSnapshot;
  Inc(fSnapshotId);
  fForm := aForm;
  fNextRefIndex := 0;
  lTree := TAccessibilityScanner.ScanForm(aForm);

  lRoot := ControlJson(aForm, '', 0, lTree, lFormRef);
  lControls := TJSONArray.Create;
  AddChildControls(aForm, lFormRef, 1, lControls, lTree);

  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'form.map');
  AddInt(lResponse, 'protocolVersion', 1);
  AddInt(lResponse, 'snapshotId', fSnapshotId);
  lResponse.AddPair('refModel', 'snapshot');
  lResponse.AddPair('form', lRoot);
  lResponse.AddPair('controls', lControls);
  Result := JsonObjectToString(lResponse);
end;

procedure TAccessibilityAgentBridgeState.ClearSnapshot;
var
  i: Integer;
begin
  for i := 0 to Pred(fObservedControls.Count) do
  begin
    fObservedControls[i].RemoveFreeNotification(Self);
  end;

  fObservedControls.Clear;
  fControlsByRef.Clear;
  fRefsByControl.Clear;
  fForm := nil;
  fNextRefIndex := 0;
end;

procedure TAccessibilityAgentBridgeState.CollectTabControls(aParent: TWinControl; aControls: TList<TWinControl>);
var
  i: Integer;
  lBestIndex: Integer;
  lBestTabOrder: Integer;
  lChild: TControl;
  lUsed: TArray<Boolean>;
  lWinControl: TWinControl;
begin
  SetLength(lUsed, aParent.ControlCount);
  while True do
  begin
    lBestIndex := -1;
    lBestTabOrder := MaxInt;
    for i := 0 to Pred(aParent.ControlCount) do
    begin
      if lUsed[i] or not (aParent.Controls[i] is TWinControl) then
      begin
        Continue;
      end;

      lWinControl := TWinControl(aParent.Controls[i]);
      if lWinControl.TabOrder < lBestTabOrder then
      begin
        lBestTabOrder := lWinControl.TabOrder;
        lBestIndex := i;
      end;
    end;

    if lBestIndex < 0 then
    begin
      Break;
    end;

    lUsed[lBestIndex] := True;
    lChild := aParent.Controls[lBestIndex];
    lWinControl := TWinControl(lChild);
    if ControlCanUseTab(lWinControl) then
    begin
      aControls.Add(lWinControl);
    end;
    CollectTabControls(lWinControl, aControls);
  end;
end;

function TAccessibilityAgentBridgeState.ControlAtScreenPoint(aParent: TWinControl; const aPoint: TPoint): TControl;
var
  i: Integer;
  lChild: TControl;
  lNested: TControl;
begin
  Result := nil;
  if (aParent = nil) or (not aParent.Visible and not (aParent is TCustomForm)) then
  begin
    Exit;
  end;

  for i := Pred(aParent.ControlCount) downto 0 do
  begin
    lChild := aParent.Controls[i];
    if not lChild.Visible then
    begin
      Continue;
    end;

    if lChild is TWinControl then
    begin
      lNested := ControlAtScreenPoint(TWinControl(lChild), aPoint);
      if lNested <> nil then
      begin
        Exit(lNested);
      end;
    end;

    if ControlScreenRect(lChild).Contains(aPoint) then
    begin
      Exit(lChild);
    end;
  end;

  if ControlScreenRect(aParent).Contains(aPoint) then
  begin
    Result := aParent;
  end;
end;

function TAccessibilityAgentBridgeState.ControlCanUseTab(aControl: TWinControl): Boolean;
var
  lControl: TControl;
begin
  Result := False;
  if (aControl = nil) or (not aControl.TabStop) or (not aControl.Enabled) or (not aControl.Visible) then
  begin
    Exit;
  end;

  lControl := aControl.Parent;
  while lControl <> nil do
  begin
    if not (lControl is TCustomForm) and ((not lControl.Visible) or (not lControl.Enabled)) then
    begin
      Exit;
    end;
    lControl := lControl.Parent;
  end;

  Result := True;
end;

function TAccessibilityAgentBridgeState.ControlJson(aControl: TControl; const aParentRef: string; aDepth: Integer;
  const aTree: IAccessibilityScanTree; out aRef: string): TJSONObject;
begin
  aRef := RegisterControl(aControl);
  Result := TJSONObject.Create;
  Result.AddPair('ref', aRef);
  if aParentRef <> '' then
  begin
    Result.AddPair('parentRef', aParentRef);
  end;
  AddInt(Result, 'depth', aDepth);
  AddControlState(Result, aControl, aTree);
end;

function TAccessibilityAgentBridgeState.ControlScreenRect(aControl: TControl): TRect;
begin
  Result := aControl.ClientToScreen(Rect(0, 0, aControl.Width, aControl.Height));
end;

function TAccessibilityAgentBridgeState.Execute(aRequest: TJSONObject): string;
var
  lCommand: string;
begin
  lCommand := RequestString(aRequest, 'cmd');
  if lCommand = 'hello' then
  begin
    Result := ExecuteHello;
  end else if lCommand = 'forms.list' then
  begin
    Result := ExecuteFormsList;
  end else if lCommand = 'form.map' then
  begin
    Result := ExecuteFormMap(aRequest);
  end else if lCommand = 'hitTest' then
  begin
    Result := ExecuteHitTest(aRequest);
  end else if lCommand = 'control.focus' then
  begin
    Result := ExecuteFocus(aRequest);
  end else if lCommand = 'control.click' then
  begin
    Result := ExecuteClick(aRequest);
  end else if lCommand = 'control.setText' then
  begin
    Result := ExecuteSetText(aRequest, False);
  end else if lCommand = 'control.typeText' then
  begin
    Result := ExecuteSetText(aRequest, True);
  end else if lCommand = 'keyboard.tab' then
  begin
    Result := ExecuteKeyboardTab(aRequest);
  end else begin
    Result := Failure('unknown_command', 'Unknown agent bridge command: ' + lCommand);
  end;
end;

function TAccessibilityAgentBridgeState.ExecuteClick(aRequest: TJSONObject): string;
var
  lControl: TControl;
  lMouseParam: LPARAM;
  lPoint: TPoint;
  lWinControl: TWinControl;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  if not ResolveControl(aRequest, lControl) then
  begin
    Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive.'));
  end;

  if lControl is TButton then
  begin
    TButton(lControl).Click;
    Exit(SuccessMutation);
  end;

  if not (lControl is TWinControl) then
  begin
    Exit(Failure('unsupported_control', 'Control does not support diagnostic click.'));
  end;

  lWinControl := TWinControl(lControl);
  lWinControl.HandleNeeded;
  lPoint := Point(lWinControl.Width div 2, lWinControl.Height div 2);
  lMouseParam := MakeLParam(Word(lPoint.X), Word(lPoint.Y));
  lWinControl.Perform(WM_LBUTTONDOWN, MK_LBUTTON, lMouseParam);
  lWinControl.Perform(WM_LBUTTONUP, 0, lMouseParam);
  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.ExecuteFocus(aRequest: TJSONObject): string;
var
  lControl: TControl;
  lWinControl: TWinControl;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  if not ResolveControl(aRequest, lControl) then
  begin
    Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive.'));
  end;

  if not (lControl is TWinControl) then
  begin
    Exit(Failure('unsupported_control', 'Control does not support focus.'));
  end;

  lWinControl := TWinControl(lControl);
  FocusWinControl(lWinControl);

  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.ExecuteFormMap(aRequest: TJSONObject): string;
var
  lForm: TCustomForm;
begin
  lForm := ResolveForm(aRequest);
  if lForm = nil then
  begin
    Exit(Failure('form_not_found', 'Requested form was not found.'));
  end;

  Result := BuildFormMap(lForm);
end;

function TAccessibilityAgentBridgeState.ExecuteFormsList: string;
var
  i: Integer;
  lForms: TJSONArray;
  lResponse: TJSONObject;
begin
  lForms := TJSONArray.Create;
  for i := 0 to Pred(Screen.CustomFormCount) do
  begin
    if Screen.CustomForms[i].Visible then
    begin
      lForms.AddElement(FormSummaryJson(Screen.CustomForms[i]));
    end;
  end;

  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'forms.list');
  AddInt(lResponse, 'protocolVersion', 1);
  lResponse.AddPair('forms', lForms);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.ExecuteHello: string;
var
  lResponse: TJSONObject;
begin
  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'hello');
  AddInt(lResponse, 'protocolVersion', 1);
  lResponse.AddPair('frameworkName', cAccessibilityFrameworkName);
  AddUInt(lResponse, 'processId', GetCurrentProcessId);
  AddBool(lResponse, 'mutationEnabled', gMutationEnabled);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.ExecuteHitTest(aRequest: TJSONObject): string;
var
  lControl: TControl;
  lPoint: TPoint;
  lRef: string;
  x: Integer;
  y: Integer;
  lResponse: TJSONObject;
begin
  if (not RequestInt(aRequest, 'x', x)) or (not RequestInt(aRequest, 'y', y)) then
  begin
    Exit(Failure('invalid_request', 'hitTest requires integer x and y.'));
  end;

  lPoint := Point(x, y);
  lControl := HitControlAt(lPoint);
  if lControl = nil then
  begin
    Exit(Failure('no_hit', 'No VCL control was found at the requested point.'));
  end;

  if not RefForControl(lControl, lRef) then
  begin
    Exit(Failure('no_snapshot_ref', 'Hit control is not part of the current snapshot.'));
  end;

  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  lResponse.AddPair('cmd', 'hitTest');
  AddInt(lResponse, 'snapshotId', fSnapshotId);
  lResponse.AddPair('ref', lRef);
  lResponse.AddPair('name', lControl.Name);
  lResponse.AddPair('className', lControl.ClassName);
  Result := JsonObjectToString(lResponse);
end;

function TAccessibilityAgentBridgeState.ExecuteKeyboardTab(aRequest: TJSONObject): string;
var
  i: Integer;
  lForm: TCustomForm;
  lForward: Boolean;
  lIndex: Integer;
  lShift: string;
  lTabControls: TList<TWinControl>;
  lTarget: TWinControl;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  lForm := fForm;
  if lForm = nil then
  begin
    lForm := Screen.ActiveCustomForm;
  end;
  if lForm = nil then
  begin
    Exit(Failure('form_not_found', 'No form is available for keyboard.tab.'));
  end;

  lShift := LowerCase(RequestString(aRequest, 'shift'));
  lForward := not ((lShift = 'true') or (lShift = '1'));
  lTabControls := TList<TWinControl>.Create;
  try
    CollectTabControls(lForm, lTabControls);
    if lTabControls.Count = 0 then
    begin
      Exit(Failure('no_tab_target', 'No tab-stop controls were found.'));
    end;

    lIndex := -1;
    for i := 0 to Pred(lTabControls.Count) do
    begin
      if lTabControls[i] = lForm.ActiveControl then
      begin
        lIndex := i;
        Break;
      end;
    end;

    if lIndex < 0 then
    begin
      if lForward then
      begin
        lIndex := 0;
      end else begin
        lIndex := Pred(lTabControls.Count);
      end;
    end else begin
      if lForward then
      begin
        lIndex := Succ(lIndex) mod lTabControls.Count;
      end else begin
        lIndex := (lIndex + Pred(lTabControls.Count)) mod lTabControls.Count;
      end;
    end;

    lTarget := lTabControls[lIndex];
    FocusWinControl(lTarget);
  finally
    lTabControls.Free;
  end;

  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.ExecuteSetText(aRequest: TJSONObject; aAppend: Boolean): string;
var
  lControl: TControl;
  lCurrentText: string;
  lText: string;
begin
  if not gMutationEnabled then
  begin
    Exit(Failure('mutation_disabled', 'Mutation commands are disabled.'));
  end;

  if not ResolveControl(aRequest, lControl) then
  begin
    Exit(Failure('stale_ref', 'Control ref is unknown or no longer alive.'));
  end;

  lText := RequestString(aRequest, 'text');
  if aAppend then
  begin
    lCurrentText := ReadStringProperty(lControl, 'Text');
    lText := lCurrentText + lText;
  end;

  if not WriteStringProperty(lControl, 'Text', lText) then
  begin
    Exit(Failure('unsupported_control', 'Control does not expose a writable Text property.'));
  end;

  Result := SuccessMutation;
end;

function TAccessibilityAgentBridgeState.Failure(const aErrorCode: string; const aMessage: string): string;
begin
  Result := FailureResponse(aErrorCode, aMessage);
end;

function TAccessibilityAgentBridgeState.FormSummaryJson(aForm: TCustomForm): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', aForm.Name);
  Result.AddPair('className', aForm.ClassName);
  Result.AddPair('caption', TAccessibilityText.Clean(aForm.Caption));
  AddBool(Result, 'visible', aForm.Visible);
  AddBool(Result, 'enabled', aForm.Enabled);
  AddBool(Result, 'active', Screen.ActiveCustomForm = aForm);
  AddUInt(Result, 'handle', UInt64(NativeUInt(aForm.Handle)));
  Result.AddPair('screenRect', RectJson(ControlScreenRect(aForm)));
end;

procedure TAccessibilityAgentBridgeState.FocusWinControl(aControl: TWinControl);
var
  lForm: TCustomForm;
begin
  lForm := GetParentForm(aControl, False);
  if lForm <> nil then
  begin
    lForm.ActiveControl := aControl;
  end;

  if aControl.CanFocus then
  begin
    aControl.SetFocus;
  end;
end;

function TAccessibilityAgentBridgeState.HitControlAt(const aPoint: TPoint): TControl;
var
  lForm: TCustomForm;
  lWindow: TWinControl;
begin
  Result := nil;
  if fForm <> nil then
  begin
    Result := ControlAtScreenPoint(fForm, aPoint);
    if Result <> nil then
    begin
      Exit;
    end;
  end;

  lWindow := FindVCLWindow(aPoint);
  if lWindow = nil then
  begin
    Exit;
  end;

  lForm := GetParentForm(lWindow, False);
  if lForm <> nil then
  begin
    Result := ControlAtScreenPoint(lForm, aPoint);
  end else begin
    Result := lWindow;
  end;
end;

procedure TAccessibilityAgentBridgeState.Notification(aComponent: TComponent; aOperation: TOperation);
var
  lControl: TControl;
  lRef: string;
begin
  inherited Notification(aComponent, aOperation);
  if (aOperation <> opRemove) or not (aComponent is TControl) then
  begin
    Exit;
  end;

  lControl := TControl(aComponent);
  if fRefsByControl.TryGetValue(lControl, lRef) then
  begin
    fRefsByControl.Remove(lControl);
    fControlsByRef.Remove(lRef);
  end;
  fObservedControls.Remove(aComponent);

  if aComponent = fForm then
  begin
    fForm := nil;
  end;
end;

function TAccessibilityAgentBridgeState.RefForControl(aControl: TControl; out aRef: string): Boolean;
begin
  aRef := '';
  Result := (aControl <> nil) and fRefsByControl.TryGetValue(aControl, aRef);
end;

function TAccessibilityAgentBridgeState.RegisterControl(aControl: TControl): string;
begin
  Result := Format('@a%d', [fNextRefIndex]);
  Inc(fNextRefIndex);
  fControlsByRef.Add(Result, aControl);
  fRefsByControl.Add(aControl, Result);
  aControl.FreeNotification(Self);
  fObservedControls.Add(aControl);
end;

function TAccessibilityAgentBridgeState.ResolveControl(aRequest: TJSONObject; out aControl: TControl): Boolean;
var
  lRef: string;
begin
  aControl := nil;
  lRef := RequestString(aRequest, 'ref');
  Result := (lRef <> '') and fControlsByRef.TryGetValue(lRef, aControl) and (aControl <> nil) and
    not (csDestroying in aControl.ComponentState);
end;

function TAccessibilityAgentBridgeState.ResolveForm(aRequest: TJSONObject): TCustomForm;
var
  i: Integer;
  lHandle: UInt64;
  lTarget: string;
  lWinControl: TWinControl;
begin
  Result := nil;
  lTarget := RequestString(aRequest, 'target');

  if lTarget = 'handle' then
  begin
    if not RequestUInt64(aRequest, 'handle', lHandle) then
    begin
      Exit(nil);
    end;
    lWinControl := FindControl(HWND(NativeUInt(lHandle)));
    if lWinControl <> nil then
    begin
      Result := GetParentForm(lWinControl, False);
      if Result = nil then
      begin
        if lWinControl is TCustomForm then
        begin
          Result := TCustomForm(lWinControl);
        end;
      end;
    end;
    Exit;
  end;

  if lTarget = 'name' then
  begin
    lTarget := RequestString(aRequest, 'name');
    for i := 0 to Pred(Screen.CustomFormCount) do
    begin
      if SameText(Screen.CustomForms[i].Name, lTarget) then
      begin
        Exit(Screen.CustomForms[i]);
      end;
    end;
    Exit;
  end;

  Result := Screen.ActiveCustomForm;
  if (Result = nil) and (Application.MainForm <> nil) then
  begin
    Result := Application.MainForm;
  end;
end;

function TAccessibilityAgentBridgeState.SuccessMutation: string;
var
  lResponse: TJSONObject;
begin
  lResponse := TJSONObject.Create;
  AddBool(lResponse, 'ok', True);
  AddBool(lResponse, 'snapshotInvalidated', True);
  Result := JsonObjectToString(lResponse);
end;

class function TAccessibilityAgentBridge.Execute(const aRequestJson: string): string;
var
  lRequest: TJSONObject;
  lValue: TJSONValue;
begin
  if GetCurrentThreadId <> MainThreadID then
  begin
    Exit(FailureResponse('wrong_thread', 'Agent bridge commands must run on the VCL main thread.'));
  end;

  lValue := nil;
  try
    try
      try
        lValue := TJSONObject.ParseJSONValue(aRequestJson, True, True);
      except
        on lException: Exception do
        begin
          Exit(FailureResponse('invalid_json', lException.Message));
        end;
      end;

      if not (lValue is TJSONObject) then
      begin
        Exit(FailureResponse('invalid_request', 'Agent bridge request must be a JSON object.'));
      end;

      lRequest := TJSONObject(lValue);
      Result := BridgeState.Execute(lRequest);
    except
      on lException: Exception do
      begin
        Result := FailureResponse('exception', lException.Message);
      end;
    end;
  finally
    lValue.Free;
  end;
end;

class function TAccessibilityAgentBridge.MutationEnabled: Boolean;
begin
  Result := gMutationEnabled;
end;

class procedure TAccessibilityAgentBridge.SetMutationEnabled(aValue: Boolean);
begin
  gMutationEnabled := aValue;
end;

initialization

finalization
  FreeAndNil(gBridgeState);

end.
