unit MaxLogic.Accessibility.Scanner;

interface

uses
  System.Generics.Collections, Vcl.Controls, Vcl.Forms;

type
  TAccessibilityTextInfo = record
    Name: string;
    HelpText: string;
    function IsEmpty: Boolean;
  end;

  TAccessibilityControlInfo = record
    Control: TControl;
    Name: string;
    HelpText: string;
    IncludeInTree: Boolean;
    class function Include(aControl: TControl; const aName: string; const aHelpText: string):
      TAccessibilityControlInfo; static;
    class function Omit: TAccessibilityControlInfo; static;
  end;

  IAccessibilityControlAdapter = interface
    ['{E88A19B1-623E-4F1F-8908-F18ACAF50B0E}']
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
  end;

  IAccessibilityAdapterRegistry = interface
    ['{C4B7B873-E5AF-467C-89D8-9049B64C682E}']
    procedure RegisterAdapter(aControlClass: TControlClass; const aAdapter: IAccessibilityControlAdapter);
    function ResolveAdapter(aControl: TControl): IAccessibilityControlAdapter;
  end;

  IAccessibilityScanNode = interface
    ['{23EEB75F-8D0F-4EF0-BBFE-F172BBA2D1BF}']
    function Child(aIndex: Integer): IAccessibilityScanNode;
    function ChildCount: Integer;
    function Control: TControl;
    function HelpText: string;
    function Name: string;
  end;

  IAccessibilityScanTree = interface
    ['{CC3744F4-72A1-4E26-A20F-21CED9C5CC03}']
    function FindNode(aControl: TControl): IAccessibilityScanNode;
    function FlattenedNodes: TArray<IAccessibilityScanNode>;
    function Revision: Integer;
    function Root: IAccessibilityScanNode;
  end;

  IAccessibilityObservedFormScan = interface
    ['{2753C9B1-3587-4C4D-AB63-C4D8B79E1F3A}']
    procedure Refresh;
    function Revision: Integer;
    function Tree: IAccessibilityScanTree;
  end;

  TAccessibilityAdapterRegistry = class(TInterfacedObject, IAccessibilityAdapterRegistry)
  private
    fAdapters: TDictionary<TControlClass, IAccessibilityControlAdapter>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterAdapter(aControlClass: TControlClass; const aAdapter: IAccessibilityControlAdapter);
    function ResolveAdapter(aControl: TControl): IAccessibilityControlAdapter;
  end;

  TAccessibilityTextExtractor = record
  public
    class function Extract(aControl: TControl): TAccessibilityTextInfo; static;
  end;

  TAccessibilityScanner = record
  public
    class function ObserveForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry = nil):
      IAccessibilityObservedFormScan; static;
    class function ScanForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry = nil):
      IAccessibilityScanTree; static;
  end;

implementation

uses
  System.Actions, System.Classes, System.SysUtils, System.Types, System.TypInfo, Winapi.Messages, Vcl.StdCtrls,
  MaxLogic.Accessibility.Text;

type
  TAccessibilityScanNode = class(TInterfacedObject, IAccessibilityScanNode)
  private
    fChildren: TList<IAccessibilityScanNode>;
    fControl: TControl;
    fHelpText: string;
    fName: string;
  public
    constructor Create(aControl: TControl; const aName: string; const aHelpText: string);
    destructor Destroy; override;
    procedure AddChild(const aChild: IAccessibilityScanNode);
    function Child(aIndex: Integer): IAccessibilityScanNode;
    function ChildCount: Integer;
    function Control: TControl;
    function HelpText: string;
    function Name: string;
  end;

  TAccessibilityScanTree = class(TInterfacedObject, IAccessibilityScanTree)
  private
    fNodesByControl: TDictionary<TControl, IAccessibilityScanNode>;
    fRevision: Integer;
    fRoot: IAccessibilityScanNode;
    procedure AddFlattenedChildren(const aNode: IAccessibilityScanNode; var aNodes: TArray<IAccessibilityScanNode>);
    procedure IndexNode(const aNode: IAccessibilityScanNode);
  public
    constructor Create(const aRoot: IAccessibilityScanNode; aRevision: Integer);
    destructor Destroy; override;
    function FindNode(aControl: TControl): IAccessibilityScanNode;
    function FlattenedNodes: TArray<IAccessibilityScanNode>;
    function Revision: Integer;
    function Root: IAccessibilityScanNode;
  end;

  TAccessibilityObservedFormScan = class;

  TAccessibilityControlHook = class(TComponent)
  private
    fControl: TWinControl;
    fObservedScan: TAccessibilityObservedFormScan;
    fOriginalWindowProc: TWndMethod;
    fPassive: Boolean;
    procedure Detach;
    function Passivate: Boolean;
  protected
    procedure Notification(aComponent: TComponent; aOperation: TOperation); override;
  public
    class procedure ReleaseRetainedHooks; static;
    constructor Create(aObservedScan: TAccessibilityObservedFormScan; aControl: TWinControl); reintroduce;
    destructor Destroy; override;
    function IsDetached: Boolean;
    procedure WindowProc(var aMessage: TMessage);
  end;

  TAccessibilityObservedFormScan = class(TInterfacedObject, IAccessibilityObservedFormScan)
  private
    fForm: TCustomForm;
    fHooks: TObjectDictionary<TWinControl, TAccessibilityControlHook>;
    fRegistry: IAccessibilityAdapterRegistry;
    fRevision: Integer;
    fTree: IAccessibilityScanTree;
    procedure HookWinControls(aControl: TWinControl);
    procedure Rebuild;
  public
    constructor Create(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry);
    destructor Destroy; override;
    procedure ControlChanged;
    procedure Refresh;
    function Revision: Integer;
    function Tree: IAccessibilityScanTree;
  end;

var
  gRetainedHooks: TList<TAccessibilityControlHook>;

function SameWndMethod(const aLeft: TWndMethod; const aRight: TWndMethod): Boolean;
begin
  Result := (TMethod(aLeft).Code = TMethod(aRight).Code) and (TMethod(aLeft).Data = TMethod(aRight).Data);
end;

function ReadObjectProperty(aObject: TObject; const aPropertyName: string): TObject;
var
  lPropInfo: PPropInfo;
begin
  Result := nil;
  lPropInfo := GetPropInfo(aObject.ClassInfo, aPropertyName);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkClass) then
  begin
    Result := GetObjectProp(aObject, lPropInfo);
  end;
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

function ReadNestedStringProperty(aObject: TObject; const aObjectPropertyName: string;
  const aStringPropertyName: string): string;
var
  lObject: TObject;
begin
  Result := '';
  lObject := ReadObjectProperty(aObject, aObjectPropertyName);
  if lObject <> nil then
  begin
    Result := ReadStringProperty(lObject, aStringPropertyName);
  end;
end;

function IsTextInputControl(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomEdit) or (aControl is TCustomComboBox);
end;

function IsLabelControl(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomLabel) or (aControl is TStaticText);
end;

function LabelTargetsControl(aLabel: TControl; aControl: TControl): Boolean;
begin
  Result := ReadObjectProperty(aLabel, 'FocusControl') = aControl;
end;

function ControlIsInActiveVisibleTree(aControl: TControl): Boolean;
var
  lControl: TControl;
begin
  Result := False;
  lControl := aControl;
  while lControl <> nil do
  begin
    if not (lControl is TCustomForm) and not lControl.Visible then
    begin
      Exit;
    end;

    lControl := lControl.Parent;
  end;

  Result := True;
end;

function LabelScore(aLabel: TControl; aControl: TControl): Integer;
var
  lControlCenterX: Integer;
  lControlCenterY: Integer;
  lControlRect: TRect;
  lLabelCenterX: Integer;
  lLabelCenterY: Integer;
  lLabelRect: TRect;
  lVerticalOverlap: Boolean;
begin
  if LabelTargetsControl(aLabel, aControl) then
  begin
    Exit(0);
  end;

  lControlRect := aControl.BoundsRect;
  lLabelRect := aLabel.BoundsRect;
  lControlCenterX := (lControlRect.Left + lControlRect.Right) div 2;
  lControlCenterY := (lControlRect.Top + lControlRect.Bottom) div 2;
  lLabelCenterX := (lLabelRect.Left + lLabelRect.Right) div 2;
  lLabelCenterY := (lLabelRect.Top + lLabelRect.Bottom) div 2;
  lVerticalOverlap := (lLabelRect.Top <= lControlCenterY) and (lLabelRect.Bottom >= lControlCenterY);

  if lVerticalOverlap and (lLabelRect.Right <= lControlRect.Left + 8) then
  begin
    Exit(1000 + Abs(lControlRect.Left - lLabelRect.Right) + Abs(lControlCenterY - lLabelCenterY));
  end;

  if (lLabelRect.Bottom <= lControlRect.Top + 8) and (lLabelRect.Right >= lControlRect.Left) and
    (lLabelRect.Left <= lControlRect.Right) then
  begin
    Exit(2000 + Abs(lControlRect.Top - lLabelRect.Bottom) + Abs(lControlCenterX - lLabelCenterX));
  end;

  Result := MaxInt;
end;

function TryFindAssociatedLabelText(aControl: TControl; out aText: string): Boolean;
var
  i: Integer;
  lBestScore: Integer;
  lCandidate: TControl;
  lCandidateScore: Integer;
  lText: string;
begin
  Result := False;
  aText := '';
  if (aControl = nil) or (aControl.Parent = nil) then
  begin
    Exit;
  end;

  lBestScore := MaxInt;
  for i := 0 to Pred(aControl.Parent.ControlCount) do
  begin
    lCandidate := aControl.Parent.Controls[i];
    if (lCandidate = aControl) or not IsLabelControl(lCandidate) or not ControlIsInActiveVisibleTree(lCandidate) then
    begin
      Continue;
    end;

    lText := ReadStringProperty(lCandidate, 'Caption');
    if lText = '' then
    begin
      Continue;
    end;

    lCandidateScore := LabelScore(lCandidate, aControl);
    if lCandidateScore < lBestScore then
    begin
      lBestScore := lCandidateScore;
      aText := lText;
      Result := True;
    end;
  end;
end;

function ControlSortKey(aControl: TControl; aFallbackIndex: Integer): Integer;
begin
  if aControl.Owner <> nil then
  begin
    Result := aControl.ComponentIndex;
  end else begin
    Result := MaxInt div 2 + aFallbackIndex;
  end;
end;

function SortedChildren(aParent: TWinControl): TArray<TControl>;
var
  i: Integer;
  j: Integer;
  lTemp: TControl;
begin
  SetLength(Result, aParent.ControlCount);
  for i := 0 to Pred(aParent.ControlCount) do
  begin
    Result[i] := aParent.Controls[i];
  end;

  for i := 1 to High(Result) do
  begin
    j := i;
    while (j > 0) and
      (ControlSortKey(Result[j - 1], j - 1) > ControlSortKey(Result[j], j)) do
    begin
      lTemp := Result[j - 1];
      Result[j - 1] := Result[j];
      Result[j] := lTemp;
      Dec(j);
    end;
  end;
end;

function TAccessibilityTextInfo.IsEmpty: Boolean;
begin
  Result := (Name = '') and (HelpText = '');
end;

class function TAccessibilityControlInfo.Include(aControl: TControl; const aName: string; const aHelpText: string):
  TAccessibilityControlInfo;
begin
  Result := Default(TAccessibilityControlInfo);
  Result.Control := aControl;
  Result.Name := aName;
  Result.HelpText := aHelpText;
  Result.IncludeInTree := True;
end;

class function TAccessibilityControlInfo.Omit: TAccessibilityControlInfo;
begin
  Result := Default(TAccessibilityControlInfo);
end;

constructor TAccessibilityAdapterRegistry.Create;
begin
  inherited Create;
  fAdapters := TDictionary<TControlClass, IAccessibilityControlAdapter>.Create;
end;

destructor TAccessibilityAdapterRegistry.Destroy;
begin
  fAdapters.Free;
  inherited Destroy;
end;

procedure TAccessibilityAdapterRegistry.RegisterAdapter(aControlClass: TControlClass;
  const aAdapter: IAccessibilityControlAdapter);
begin
  if aControlClass = nil then
  begin
    raise EArgumentException.Create('Control class must not be nil.');
  end;

  if aAdapter = nil then
  begin
    fAdapters.Remove(aControlClass);
  end else begin
    fAdapters.AddOrSetValue(aControlClass, aAdapter);
  end;
end;

function TAccessibilityAdapterRegistry.ResolveAdapter(aControl: TControl): IAccessibilityControlAdapter;
var
  lClass: TClass;
begin
  Result := nil;
  if aControl = nil then
  begin
    Exit;
  end;

  lClass := aControl.ClassType;
  while (lClass <> nil) and lClass.InheritsFrom(TControl) do
  begin
    if fAdapters.TryGetValue(TControlClass(lClass), Result) then
    begin
      Exit;
    end;

    lClass := lClass.ClassParent;
  end;
end;

class function TAccessibilityTextExtractor.Extract(aControl: TControl): TAccessibilityTextInfo;
var
  lAction: TObject;
  lActionHintName: string;
  lCaption: string;
  lHelpText: string;
  lHint: string;
  lIconOnly: Boolean;
  lLabelText: string;
  lText: string;
  lTextHint: string;
begin
  Result := Default(TAccessibilityTextInfo);
  if aControl = nil then
  begin
    Exit;
  end;

  Result.Name := ReadStringProperty(aControl, 'AccessibleName');
  lHint := ReadStringProperty(aControl, 'Hint');
  TAccessibilityText.SplitHint(lHint, lActionHintName, Result.HelpText);
  lTextHint := ReadStringProperty(aControl, 'TextHint');
  if lTextHint <> '' then
  begin
    if Result.HelpText = '' then
    begin
      Result.HelpText := lTextHint;
    end else if not SameText(Result.HelpText, lTextHint) then
    begin
      Result.HelpText := lTextHint + '. ' + Result.HelpText;
    end;
  end;

  if Result.Name <> '' then
  begin
    Exit;
  end;

  lAction := ReadObjectProperty(aControl, 'Action');
  if lAction is TContainedAction then
  begin
    Result.Name := TAccessibilityText.Clean(TContainedAction(lAction).Caption);
    TAccessibilityText.SplitHint(TContainedAction(lAction).Hint, lActionHintName, lHelpText);
    if lHelpText <> '' then
    begin
      Result.HelpText := lHelpText;
    end;

    if Result.Name = '' then
    begin
      Result.Name := lActionHintName;
    end;

    if Result.Name <> '' then
    begin
      Exit;
    end;
  end;

  lIconOnly := False;
  lCaption := ReadStringProperty(aControl, 'Caption');
  if lCaption <> '' then
  begin
    lIconOnly := TAccessibilityText.IsIconFontOnly(lCaption);
    if not lIconOnly then
    begin
      Result.Name := lCaption;
      Exit;
    end;
  end;

  lLabelText := ReadNestedStringProperty(aControl, 'EditLabel', 'Caption');
  if lLabelText <> '' then
  begin
    lIconOnly := lIconOnly or TAccessibilityText.IsIconFontOnly(lLabelText);
    if not TAccessibilityText.IsIconFontOnly(lLabelText) then
    begin
      Result.Name := lLabelText;
      Exit;
    end;
  end;

  lText := ReadStringProperty(aControl, 'Text');
  if lText <> '' then
  begin
    lIconOnly := lIconOnly or TAccessibilityText.IsIconFontOnly(lText);
    if not TAccessibilityText.IsIconFontOnly(lText) then
    begin
      Result.Name := lText;
      Exit;
    end;
  end;

  if lActionHintName <> '' then
  begin
    Result.Name := lActionHintName;
    Exit;
  end;

  if lIconOnly then
  begin
    Result.HelpText := '';
    Exit;
  end;

  Result.Name := TAccessibilityText.Clean(aControl.Name);
end;

constructor TAccessibilityScanNode.Create(aControl: TControl; const aName: string; const aHelpText: string);
begin
  inherited Create;
  fControl := aControl;
  fName := aName;
  fHelpText := aHelpText;
  fChildren := TList<IAccessibilityScanNode>.Create;
end;

destructor TAccessibilityScanNode.Destroy;
begin
  fChildren.Free;
  inherited Destroy;
end;

procedure TAccessibilityScanNode.AddChild(const aChild: IAccessibilityScanNode);
begin
  fChildren.Add(aChild);
end;

function TAccessibilityScanNode.Child(aIndex: Integer): IAccessibilityScanNode;
begin
  Result := fChildren[aIndex];
end;

function TAccessibilityScanNode.ChildCount: Integer;
begin
  Result := fChildren.Count;
end;

function TAccessibilityScanNode.Control: TControl;
begin
  Result := fControl;
end;

function TAccessibilityScanNode.HelpText: string;
begin
  Result := fHelpText;
end;

function TAccessibilityScanNode.Name: string;
begin
  Result := fName;
end;

constructor TAccessibilityScanTree.Create(const aRoot: IAccessibilityScanNode; aRevision: Integer);
begin
  inherited Create;
  fNodesByControl := TDictionary<TControl, IAccessibilityScanNode>.Create;
  fRoot := aRoot;
  fRevision := aRevision;
  IndexNode(fRoot);
end;

destructor TAccessibilityScanTree.Destroy;
begin
  fNodesByControl.Free;
  inherited Destroy;
end;

procedure TAccessibilityScanTree.AddFlattenedChildren(const aNode: IAccessibilityScanNode;
  var aNodes: TArray<IAccessibilityScanNode>);
var
  i: Integer;
  lIndex: Integer;
begin
  for i := 0 to Pred(aNode.ChildCount) do
  begin
    lIndex := Length(aNodes);
    SetLength(aNodes, lIndex + 1);
    aNodes[lIndex] := aNode.Child(i);
    AddFlattenedChildren(aNode.Child(i), aNodes);
  end;
end;

function TAccessibilityScanTree.FindNode(aControl: TControl): IAccessibilityScanNode;
begin
  if aControl = nil then
  begin
    Exit(nil);
  end;

  if not fNodesByControl.TryGetValue(aControl, Result) then
  begin
    Result := nil;
  end;
end;

procedure TAccessibilityScanTree.IndexNode(const aNode: IAccessibilityScanNode);
var
  i: Integer;
begin
  if aNode = nil then
  begin
    Exit;
  end;

  if (aNode.Control <> nil) and not fNodesByControl.ContainsKey(aNode.Control) then
  begin
    fNodesByControl.Add(aNode.Control, aNode);
  end;

  for i := 0 to Pred(aNode.ChildCount) do
  begin
    IndexNode(aNode.Child(i));
  end;
end;

function TAccessibilityScanTree.FlattenedNodes: TArray<IAccessibilityScanNode>;
begin
  Result := [];
  AddFlattenedChildren(fRoot, Result);
end;

function TAccessibilityScanTree.Revision: Integer;
begin
  Result := fRevision;
end;

function TAccessibilityScanTree.Root: IAccessibilityScanNode;
begin
  Result := fRoot;
end;

constructor TAccessibilityControlHook.Create(aObservedScan: TAccessibilityObservedFormScan; aControl: TWinControl);
begin
  inherited Create(nil);
  fObservedScan := aObservedScan;
  fControl := aControl;
  fOriginalWindowProc := aControl.WindowProc;
  fControl.FreeNotification(Self);
  aControl.WindowProc := WindowProc;
end;

destructor TAccessibilityControlHook.Destroy;
begin
  if not fPassive then
  begin
    Detach;
  end;

  inherited Destroy;
end;

procedure TAccessibilityControlHook.Detach;
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

function TAccessibilityControlHook.IsDetached: Boolean;
begin
  Result := fControl = nil;
end;

procedure TAccessibilityControlHook.Notification(aComponent: TComponent; aOperation: TOperation);
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

function TAccessibilityControlHook.Passivate: Boolean;
begin
  Result := False;
  fObservedScan := nil;
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
    if gRetainedHooks = nil then
    begin
      gRetainedHooks := TList<TAccessibilityControlHook>.Create;
    end;

    if not gRetainedHooks.Contains(Self) then
    begin
      gRetainedHooks.Add(Self);
    end;
  end;
end;

class procedure TAccessibilityControlHook.ReleaseRetainedHooks;
var
  lHook: TAccessibilityControlHook;
begin
  if gRetainedHooks = nil then
  begin
    Exit;
  end;

  while gRetainedHooks.Count > 0 do
  begin
    lHook := gRetainedHooks[Pred(gRetainedHooks.Count)];
    gRetainedHooks.Delete(Pred(gRetainedHooks.Count));
    lHook.fPassive := False;
    lHook.Detach;
    lHook.Free;
  end;
end;

procedure TAccessibilityControlHook.WindowProc(var aMessage: TMessage);
begin
  fOriginalWindowProc(aMessage);
  if (not fPassive) and (fObservedScan <> nil) and
    (((aMessage.Msg = CM_CONTROLCHANGE) and (aMessage.LParam <> 0)) or
    ((aMessage.Msg = CM_CONTROLLISTCHANGE) and (aMessage.LParam = 0))) then
  begin
    fObservedScan.ControlChanged;
  end;
end;

constructor TAccessibilityObservedFormScan.Create(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry);
begin
  inherited Create;
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  fForm := aForm;
  fRegistry := aRegistry;
  fHooks := TObjectDictionary<TWinControl, TAccessibilityControlHook>.Create;
  Refresh;
end;

destructor TAccessibilityObservedFormScan.Destroy;
var
  lHook: TAccessibilityControlHook;
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

procedure TAccessibilityObservedFormScan.ControlChanged;
begin
  Refresh;
end;

procedure TAccessibilityObservedFormScan.HookWinControls(aControl: TWinControl);
var
  i: Integer;
  lChildren: TArray<TControl>;
  lHook: TAccessibilityControlHook;
begin
  if fHooks.TryGetValue(aControl, lHook) and lHook.IsDetached then
  begin
    fHooks.Remove(aControl);
  end;

  if not fHooks.ContainsKey(aControl) then
  begin
    fHooks.Add(aControl, TAccessibilityControlHook.Create(Self, aControl));
  end;

  lChildren := SortedChildren(aControl);
  for i := 0 to High(lChildren) do
  begin
    if lChildren[i] is TWinControl then
    begin
      HookWinControls(TWinControl(lChildren[i]));
    end;
  end;
end;

procedure TAccessibilityObservedFormScan.Rebuild;
begin
  Inc(fRevision);
  fTree := TAccessibilityScanner.ScanForm(fForm, fRegistry);
  fTree := TAccessibilityScanTree.Create(fTree.Root, fRevision);
end;

procedure TAccessibilityObservedFormScan.Refresh;
begin
  HookWinControls(fForm);
  Rebuild;
end;

function TAccessibilityObservedFormScan.Revision: Integer;
begin
  Result := fRevision;
end;

function TAccessibilityObservedFormScan.Tree: IAccessibilityScanTree;
begin
  Result := fTree;
end;

function CreateControlInfo(aControl: TControl; const aRegistry: IAccessibilityAdapterRegistry):
  TAccessibilityControlInfo;
var
  lAdapter: IAccessibilityControlAdapter;
  lAssociatedLabelText: string;
  lText: TAccessibilityTextInfo;
begin
  lText := TAccessibilityTextExtractor.Extract(aControl);
  if IsTextInputControl(aControl) and TryFindAssociatedLabelText(aControl, lAssociatedLabelText) then
  begin
    lText.Name := lAssociatedLabelText;
  end;

  lAdapter := nil;
  if aRegistry <> nil then
  begin
    lAdapter := aRegistry.ResolveAdapter(aControl);
  end;

  if lAdapter <> nil then
  begin
    Exit(lAdapter.CreateInfo(aControl, lText));
  end;

  if (aControl is TWinControl) and TWinControl(aControl).TabStop and not IsTextInputControl(aControl) then
  begin
    Exit(TAccessibilityControlInfo.Omit);
  end;

  if lText.IsEmpty then
  begin
    Result := TAccessibilityControlInfo.Omit;
  end else begin
    Result := TAccessibilityControlInfo.Include(aControl, lText.Name, lText.HelpText);
  end;
end;

procedure ScanControlChildren(aParent: TWinControl; const aParentNode: TAccessibilityScanNode;
  const aRegistry: IAccessibilityAdapterRegistry);
var
  i: Integer;
  lChildren: TArray<TControl>;
  lChildNode: TAccessibilityScanNode;
  lInfo: TAccessibilityControlInfo;
  lNextParent: TAccessibilityScanNode;
begin
  lChildren := SortedChildren(aParent);
  for i := 0 to High(lChildren) do
  begin
    lInfo := CreateControlInfo(lChildren[i], aRegistry);
    lNextParent := aParentNode;
    if lInfo.IncludeInTree then
    begin
      lChildNode := TAccessibilityScanNode.Create(lInfo.Control, lInfo.Name, lInfo.HelpText);
      aParentNode.AddChild(lChildNode);
      lNextParent := lChildNode;
    end;

    if lChildren[i] is TWinControl then
    begin
      ScanControlChildren(TWinControl(lChildren[i]), lNextParent, aRegistry);
    end;
  end;
end;

class function TAccessibilityScanner.ObserveForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry):
  IAccessibilityObservedFormScan;
begin
  Result := TAccessibilityObservedFormScan.Create(aForm, aRegistry);
end;

class function TAccessibilityScanner.ScanForm(aForm: TCustomForm; const aRegistry: IAccessibilityAdapterRegistry):
  IAccessibilityScanTree;
var
  lRoot: TAccessibilityScanNode;
begin
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  lRoot := TAccessibilityScanNode.Create(aForm, TAccessibilityText.Clean(aForm.Caption),
    TAccessibilityText.Clean(aForm.Hint));
  ScanControlChildren(aForm, lRoot, aRegistry);
  Result := TAccessibilityScanTree.Create(lRoot, 1);
end;

initialization

finalization
  TAccessibilityControlHook.ReleaseRetainedHooks;
  gRetainedHooks.Free;

end.
