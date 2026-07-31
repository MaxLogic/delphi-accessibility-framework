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

  IAccessibilityScanNodeLabelRelationship = interface
    ['{58CE40D0-810D-462B-A75F-F6820F735B43}']
    function AssociatedLabelControl: TControl;
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
  System.Actions, System.Classes, System.Generics.Defaults, System.SysUtils, System.Types, System.TypInfo,
  Winapi.Messages, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, MaxLogic.Accessibility.Diagnostics,
  MaxLogic.Accessibility.Text;

type
  TSortedChildEntry = record
    Control: TControl;
    OriginalIndex: Integer;
    SortKey: Integer;
  end;

  TScannerLabelCandidate = record
    Control: TControl;
    FocusControl: TControl;
    Text: string;
  end;

  TScannerLabelRelationshipState = record
    ActiveVisible: Boolean;
    Bounds: TRect;
    Control: TControl;
    FocusControl: TControl;
    Hint: string;
    IsLabel: Boolean;
    Parent: TWinControl;
    Text: string;
  end;

  TScannerControlAccess = class(TControl);
  TScannerLabelAccess = class(TCustomLabel);

  TRttiPropertyCache = class
  private
    fPropsByClass: TObjectDictionary<NativeUInt, TDictionary<string, PPropInfo>>;
  public
    constructor Create;
    destructor Destroy; override;
    function Find(aObject: TObject; const aPropertyName: string): PPropInfo;
  end;

  TAccessibilityScanNode = class(TInterfacedObject, IAccessibilityScanNode,
    IAccessibilityScanNodeLabelRelationship)
  private
    fAssociatedLabelControl: TControl;
    fChildren: TList<IAccessibilityScanNode>;
    fControl: TControl;
    fHelpText: string;
    fName: string;
  public
    constructor Create(aControl: TControl; const aName: string; const aHelpText: string;
      aAssociatedLabelControl: TControl);
    function AssociatedLabelControl: TControl;
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
    fFlattenedNodes: TArray<IAccessibilityScanNode>;
    fNodeCount: Integer;
    fNodesByControl: TDictionary<TControl, IAccessibilityScanNode>;
    fRevision: Integer;
    fRoot: IAccessibilityScanNode;
    procedure AddFlattenedChildren(const aNode: IAccessibilityScanNode; var aNodes:
      TArray<IAccessibilityScanNode>; var aIndex: Integer);
    procedure BuildFlattenedNodes;
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
    fRetained: Boolean;
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
    fLabelRelationshipState: TArray<TScannerLabelRelationshipState>;
    fRegistry: IAccessibilityAdapterRegistry;
    fRefreshPending: Boolean;
    fRevision: Integer;
    fTree: IAccessibilityScanTree;
    procedure EnsureFresh;
    procedure HookWinControls(aControl: TWinControl);
    procedure Rebuild;
    procedure RefreshLabelRelationshipState;
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

constructor TRttiPropertyCache.Create;
begin
  inherited Create;
  fPropsByClass := TObjectDictionary<NativeUInt, TDictionary<string, PPropInfo>>.Create([doOwnsValues]);
end;

destructor TRttiPropertyCache.Destroy;
begin
  fPropsByClass.Free;
  inherited Destroy;
end;

function TRttiPropertyCache.Find(aObject: TObject; const aPropertyName: string): PPropInfo;
var
  lClassInfo: PTypeInfo;
  lClassKey: NativeUInt;
  lProperties: TDictionary<string, PPropInfo>;
begin
  Result := nil;
  if aObject = nil then
  begin
    Exit;
  end;

  lClassInfo := aObject.ClassInfo;
  if lClassInfo = nil then
  begin
    Exit;
  end;

  lClassKey := NativeUInt(lClassInfo);
  if not fPropsByClass.TryGetValue(lClassKey, lProperties) then
  begin
    lProperties := TDictionary<string, PPropInfo>.Create;
    fPropsByClass.Add(lClassKey, lProperties);
  end;

  if not lProperties.TryGetValue(aPropertyName, Result) then
  begin
    TAccessibilityDiagnostics.RecordScannerRttiPropertyLookup;
    Result := GetPropInfo(lClassInfo, aPropertyName);
    lProperties.Add(aPropertyName, Result);
  end;
end;

function ControlHasDirectCaption(aControl: TControl): Boolean;
begin
  Result := (aControl is TCustomForm) or (aControl is TCustomLabel) or (aControl is TStaticText) or
    (aControl is TCustomButton) or (aControl is TCustomCheckBox) or (aControl is TRadioButton) or
    (aControl is TCustomGroupBox) or (aControl is TCustomPanel) or (aControl is TTabSheet) or
    (aControl is TToolButton);
end;

function TryReadDirectObjectProperty(aObject: TObject; const aPropertyName: string; out aValue: TObject): Boolean;
begin
  Result := False;
  aValue := nil;
  if (aPropertyName = 'Action') and (aObject is TControl) then
  begin
    aValue := TScannerControlAccess(aObject).Action;
    Exit(True);
  end;

  if (aPropertyName = 'FocusControl') and (aObject is TCustomLabel) then
  begin
    aValue := TScannerLabelAccess(aObject).FocusControl;
    Exit(True);
  end;

  if (aPropertyName = 'EditLabel') and (aObject is TCustomLabeledEdit) then
  begin
    aValue := TCustomLabeledEdit(aObject).EditLabel;
    Exit(True);
  end;
end;

function TryReadDirectStringProperty(aObject: TObject; const aPropertyName: string; out aValue: string): Boolean;
var
  lControl: TControl;
begin
  Result := False;
  aValue := '';
  if not (aObject is TControl) then
  begin
    Exit;
  end;

  lControl := TControl(aObject); //PALOFF STWA6 guarded by is TControl
  if (aPropertyName = 'Caption') and ControlHasDirectCaption(lControl) then
  begin
    aValue := TAccessibilityText.Clean(TScannerControlAccess(lControl).Caption);
    Exit(True);
  end;

  if (aPropertyName = 'Text') and
    ((lControl is TCustomEdit) or (lControl is TCustomMemo) or (lControl is TCustomComboBox)) then
  begin
    aValue := TAccessibilityText.Clean(TScannerControlAccess(lControl).Text);
    Exit(True);
  end;

  if aPropertyName = 'Hint' then
  begin
    aValue := TAccessibilityText.Clean(lControl.Hint);
    Exit(True);
  end;

  if aPropertyName = 'TextHint' then
  begin
    if lControl is TCustomEdit then
    begin
      aValue := TAccessibilityText.Clean(TCustomEdit(lControl).TextHint);
      Exit(True);
    end;

    if lControl is TCustomComboBox then
    begin
      aValue := TAccessibilityText.Clean(TCustomComboBox(lControl).TextHint);
      Exit(True);
    end;
  end;
end;

function LookupPropInfo(aObject: TObject; const aPropertyName: string; aCache: TRttiPropertyCache): PPropInfo;
begin
  if aCache <> nil then
  begin
    Exit(aCache.Find(aObject, aPropertyName));
  end;

  TAccessibilityDiagnostics.RecordScannerRttiPropertyLookup;
  Result := GetPropInfo(aObject.ClassInfo, aPropertyName);
end;

function ReadObjectProperty(aObject: TObject; const aPropertyName: string; aCache: TRttiPropertyCache = nil):
  TObject;
var
  lPropInfo: PPropInfo;
begin
  Result := nil;
  if TryReadDirectObjectProperty(aObject, aPropertyName, Result) then
  begin
    Exit;
  end;

  lPropInfo := LookupPropInfo(aObject, aPropertyName, aCache);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind = tkClass) then
  begin
    Result := GetObjectProp(aObject, lPropInfo);
  end;
end;

function ReadStringProperty(aObject: TObject; const aPropertyName: string; aCache: TRttiPropertyCache = nil): string;
var
  lPropInfo: PPropInfo;
begin
  Result := '';
  if TryReadDirectStringProperty(aObject, aPropertyName, Result) then
  begin
    Exit;
  end;

  lPropInfo := LookupPropInfo(aObject, aPropertyName, aCache);
  if (lPropInfo <> nil) and (lPropInfo.PropType^.Kind in [tkString, tkLString, tkWString, tkUString]) then
  begin
    Result := TAccessibilityText.Clean(GetStrProp(aObject, lPropInfo));
  end;
end;

function ReadNestedStringProperty(aObject: TObject; const aObjectPropertyName: string; const aStringPropertyName:
  string; aCache: TRttiPropertyCache = nil): string;
var
  lObject: TObject;
begin
  Result := '';
  lObject := ReadObjectProperty(aObject, aObjectPropertyName, aCache);
  if lObject <> nil then
  begin
    Result := ReadStringProperty(lObject, aStringPropertyName, aCache);
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

function SortedChildren(aParent: TWinControl): TArray<TControl>; forward;

procedure CollectLabelRelationshipState(aParent: TWinControl; //PALOFF WARN19 bounded VCL parent/child tree walk
  aState: TList<TScannerLabelRelationshipState>);
var
  i: Integer;
  lChild: TControl;
  lChildren: TArray<TControl>;
  lFocusControl: TObject;
  lState: TScannerLabelRelationshipState;
begin
  lChildren := SortedChildren(aParent);
  for i := 0 to High(lChildren) do
  begin
    lChild := lChildren[i];
    lState := Default(TScannerLabelRelationshipState);
    lState.ActiveVisible := ControlIsInActiveVisibleTree(lChild);
    lState.Bounds := lChild.BoundsRect;
    lState.Control := lChild;
    lState.IsLabel := IsLabelControl(lChild);
    lState.Hint := lChild.Hint;
    lState.Parent := lChild.Parent;
    if lState.IsLabel then
    begin
      lState.Text := TAccessibilityTextExtractor.Extract(lChild).Name;
      lFocusControl := ReadObjectProperty(lChild, 'FocusControl');
      if lFocusControl is TControl then
      begin
        lState.FocusControl := TControl(lFocusControl); //PALOFF STWA6 guarded by is TControl
      end;
    end;
    aState.Add(lState);

    if lChild is TWinControl then
    begin
      CollectLabelRelationshipState(TWinControl(lChild), aState); //PALOFF STWA6 guarded by is TWinControl
    end;
  end;
end;

function CaptureLabelRelationshipState(aForm: TCustomForm): TArray<TScannerLabelRelationshipState>;
var
  lFormState: TScannerLabelRelationshipState;
  lState: TList<TScannerLabelRelationshipState>;
begin
  lState := TList<TScannerLabelRelationshipState>.Create;
  try
    lFormState := Default(TScannerLabelRelationshipState);
    lFormState.ActiveVisible := True;
    lFormState.Bounds := aForm.BoundsRect;
    lFormState.Control := aForm;
    lFormState.Hint := aForm.Hint;
    lState.Add(lFormState);
    CollectLabelRelationshipState(aForm, lState);
    Result := lState.ToArray;
  finally
    lState.Free;
  end;
end;

function CurrentLabelRelationshipStateMatches(
  const aState: TArray<TScannerLabelRelationshipState>): Boolean;
var
  i: Integer;
  lControl: TControl;
  lFocusControl: TControl;
  lFocusObject: TObject;
  lIsLabel: Boolean;
  lRelationshipControl: Boolean;
  lText: string;
begin
  for i := 0 to High(aState) do
  begin
    lControl := aState[i].Control;
    if (lControl = nil) or (csDestroying in lControl.ComponentState) then
    begin
      Exit(False);
    end;
    lIsLabel := IsLabelControl(lControl);
    lRelationshipControl := lIsLabel or IsTextInputControl(lControl);
    lFocusControl := nil;
    lText := '';
    if lIsLabel then
    begin
      lText := TAccessibilityTextExtractor.Extract(lControl).Name;
      lFocusObject := ReadObjectProperty(lControl, 'FocusControl');
      if lFocusObject is TControl then
      begin
        lFocusControl := TControl(lFocusObject); //PALOFF STWA6 guarded by is TControl
      end;
    end;
    if (aState[i].Hint <> lControl.Hint) or (aState[i].IsLabel <> lIsLabel) or
      (lRelationshipControl and
      ((aState[i].ActiveVisible <> ControlIsInActiveVisibleTree(lControl)) or
      not EqualRect(aState[i].Bounds, lControl.BoundsRect) or
      (aState[i].FocusControl <> lFocusControl) or (aState[i].Parent <> lControl.Parent) or
      (aState[i].Text <> lText))) then
    begin
      Exit(False);
    end;
  end;
  Result := True;
end;

function LabelScore(const aLabel: TScannerLabelCandidate; aControl: TControl): Integer;
const
  cMaximumLabelGap = 32;
  cOverlapTolerance = 8;
var
  lControlCenter: TPoint;
  lControlRect: TRect;
  lGap: Integer;
  lLabelCenter: TPoint;
  lLabelRect: TRect;
  lMaximumLabelGap: Integer;
  lOverlapTolerance: Integer;
begin
  if aLabel.FocusControl = aControl then
  begin
    Exit(0);
  end;

  lControlRect := aControl.BoundsRect;
  lLabelRect := aLabel.Control.BoundsRect;
  lControlCenter := Point((lControlRect.Left + lControlRect.Right) div 2,
    (lControlRect.Top + lControlRect.Bottom) div 2);
  lLabelCenter := Point((lLabelRect.Left + lLabelRect.Right) div 2,
    (lLabelRect.Top + lLabelRect.Bottom) div 2);
  lMaximumLabelGap := aControl.ScaleValue(cMaximumLabelGap);
  lOverlapTolerance := aControl.ScaleValue(cOverlapTolerance);
  lGap := lControlRect.Left - lLabelRect.Right;
  if (lLabelRect.Top <= lControlCenter.Y) and (lLabelRect.Bottom >= lControlCenter.Y) and
    (lGap >= -lOverlapTolerance) and (lGap <= lMaximumLabelGap) then
  begin
    Exit(1000 + Abs(lGap) + Abs(lControlCenter.Y - lLabelCenter.Y));
  end;

  lGap := lControlRect.Top - lLabelRect.Bottom;
  if (lGap >= -lOverlapTolerance) and (lGap <= lMaximumLabelGap) and
    (lLabelRect.Right >= lControlRect.Left) and (lLabelRect.Left <= lControlRect.Right) then
  begin
    Exit(2000 + Abs(lGap) + Abs(lControlCenter.X - lLabelCenter.X));
  end;

  Result := MaxInt;
end;

function TryFindAssociatedLabel(aControl: TControl; const aLabels: TArray<TScannerLabelCandidate>;
  aFocusLabels: TDictionary<TControl, TScannerLabelCandidate>; out aLabel: TScannerLabelCandidate): Boolean;
var
  i: Integer;
  lAmbiguous: Boolean;
  lBestScore: Integer;
  lCandidate: TScannerLabelCandidate;
  lCandidateScore: Integer;
begin
  Result := False;
  aLabel := Default(TScannerLabelCandidate);
  if (aControl = nil) or (aControl.Parent = nil) then
  begin
    Exit;
  end;

  if (aFocusLabels <> nil) and aFocusLabels.TryGetValue(aControl, aLabel) then
  begin
    Exit(True);
  end;

  lAmbiguous := False;
  lBestScore := MaxInt;
  for i := 0 to High(aLabels) do
  begin
    lCandidate := aLabels[i];
    if lCandidate.Control = aControl then
    begin
      Continue;
    end;

    lCandidateScore := LabelScore(lCandidate, aControl);
    if lCandidateScore < lBestScore then
    begin
      lBestScore := lCandidateScore;
      aLabel := lCandidate;
      lAmbiguous := False;
    end else if lCandidateScore = lBestScore then
    begin
      lAmbiguous := True;
    end;
  end;
  Result := (lBestScore < MaxInt) and not lAmbiguous;
end;

function BuildLabelCandidates(const aChildren: TArray<TControl>;
  out aFocusLabels: TDictionary<TControl, TScannerLabelCandidate>;
  aCache: TRttiPropertyCache): TArray<TScannerLabelCandidate>;
var
  i: Integer;
  lCount: Integer;
  lFocusControl: TObject;
  lText: string;
begin
  aFocusLabels := nil;
  SetLength(Result, Length(aChildren));
  lCount := 0;
  for i := 0 to High(aChildren) do
  begin
    if not IsLabelControl(aChildren[i]) or not ControlIsInActiveVisibleTree(aChildren[i]) then
    begin
      Continue;
    end;

    lText := TAccessibilityText.Clean(ReadStringProperty(aChildren[i], 'Caption', aCache));
    if lText = '' then
    begin
      Continue;
    end;

    Result[lCount].Control := aChildren[i];
    Result[lCount].Text := lText;
    lFocusControl := ReadObjectProperty(aChildren[i], 'FocusControl', aCache);
    if lFocusControl is TControl then
    begin
      Result[lCount].FocusControl := TControl(lFocusControl);
      if aFocusLabels = nil then
      begin
        aFocusLabels := TDictionary<TControl, TScannerLabelCandidate>.Create;
      end;

      if not aFocusLabels.ContainsKey(TControl(lFocusControl)) then //PALOFF STWA6 guarded by is TControl
      begin
        aFocusLabels.Add(TControl(lFocusControl), Result[lCount]); //PALOFF STWA6 guarded by is TControl
      end;
    end;

    Inc(lCount);
  end;

  SetLength(Result, lCount);
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

function CompareSortedChildEntry(const aLeft: TSortedChildEntry; const aRight: TSortedChildEntry): Integer;
begin
  if aLeft.SortKey < aRight.SortKey then
  begin
    Exit(-1);
  end;

  if aLeft.SortKey > aRight.SortKey then
  begin
    Exit(1);
  end;

  if aLeft.OriginalIndex < aRight.OriginalIndex then
  begin
    Exit(-1);
  end;

  if aLeft.OriginalIndex > aRight.OriginalIndex then
  begin
    Exit(1);
  end;

  Result := 0;
end;

function SortedChildren(aParent: TWinControl): TArray<TControl>;
var
  i: Integer;
  lEntries: TArray<TSortedChildEntry>;
  lIsSorted: Boolean;
  lPreviousSortKey: Integer;
  lSortKey: Integer;
begin
  SetLength(Result, aParent.ControlCount);
  lIsSorted := True;
  lPreviousSortKey := Low(Integer);
  for i := 0 to Pred(aParent.ControlCount) do
  begin
    Result[i] := aParent.Controls[i];
    lSortKey := ControlSortKey(Result[i], i);
    if (i > 0) and (lSortKey < lPreviousSortKey) then
    begin
      lIsSorted := False;
    end;

    lPreviousSortKey := lSortKey;
  end;

  if lIsSorted then
  begin
    TAccessibilityDiagnostics.RecordScannerSortedChildren(Length(Result), False);
    Exit;
  end;

  TAccessibilityDiagnostics.RecordScannerSortedChildren(Length(Result), True);
  SetLength(lEntries, Length(Result));
  for i := 0 to High(Result) do
  begin
    lEntries[i].Control := Result[i];
    lEntries[i].OriginalIndex := i;
    lEntries[i].SortKey := ControlSortKey(lEntries[i].Control, i);
  end;

  TArray.Sort<TSortedChildEntry>(lEntries, TComparer<TSortedChildEntry>.Construct(CompareSortedChildEntry));

  for i := 0 to High(lEntries) do
  begin
    Result[i] := lEntries[i].Control;
  end;
end;

function ContainsTextInputControl(const aChildren: TArray<TControl>): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(aChildren) do
  begin
    if IsTextInputControl(aChildren[i]) then
    begin
      Exit(True);
    end;
  end;

  Result := False;
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

function ExtractText(aControl: TControl; aCache: TRttiPropertyCache): TAccessibilityTextInfo;
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

  Result.Name := ReadStringProperty(aControl, 'AccessibleName', aCache);
  lHint := ReadStringProperty(aControl, 'Hint', aCache);
  TAccessibilityText.SplitHint(lHint, lActionHintName, Result.HelpText);
  lTextHint := ReadStringProperty(aControl, 'TextHint', aCache);
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

  lAction := ReadObjectProperty(aControl, 'Action', aCache);
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
  lCaption := ReadStringProperty(aControl, 'Caption', aCache);
  if lCaption <> '' then
  begin
    lIconOnly := TAccessibilityText.IsIconFontOnly(lCaption);
    if not lIconOnly then
    begin
      Result.Name := lCaption;
      Exit;
    end;
  end;

  lLabelText := ReadNestedStringProperty(aControl, 'EditLabel', 'Caption', aCache);
  if lLabelText <> '' then
  begin
    lIconOnly := lIconOnly or TAccessibilityText.IsIconFontOnly(lLabelText);
    if not TAccessibilityText.IsIconFontOnly(lLabelText) then
    begin
      Result.Name := lLabelText;
      Exit;
    end;
  end;

  lText := ReadStringProperty(aControl, 'Text', aCache);
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

class function TAccessibilityTextExtractor.Extract(aControl: TControl): TAccessibilityTextInfo;
begin
  Result := ExtractText(aControl, nil);
end;

constructor TAccessibilityScanNode.Create(aControl: TControl; const aName: string; const aHelpText: string;
  aAssociatedLabelControl: TControl);
begin
  inherited Create;
  fAssociatedLabelControl := aAssociatedLabelControl;
  fControl := aControl;
  fName := aName;
  fHelpText := aHelpText;
  fChildren := TList<IAccessibilityScanNode>.Create;
end;

function TAccessibilityScanNode.AssociatedLabelControl: TControl;
begin
  Result := fAssociatedLabelControl;
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
  BuildFlattenedNodes;
end;

destructor TAccessibilityScanTree.Destroy;
begin
  fNodesByControl.Free;
  inherited Destroy;
end;

procedure TAccessibilityScanTree.AddFlattenedChildren(const aNode: IAccessibilityScanNode;
  var aNodes: TArray<IAccessibilityScanNode>; var aIndex: Integer);
var
  i: Integer;
  lChild: IAccessibilityScanNode;
begin
  for i := 0 to Pred(aNode.ChildCount) do
  begin
    lChild := aNode.Child(i);
    aNodes[aIndex] := lChild;
    Inc(aIndex);
    AddFlattenedChildren(lChild, aNodes, aIndex);
  end;
end;

procedure TAccessibilityScanTree.BuildFlattenedNodes;
var
  lIndex: Integer;
begin
  fFlattenedNodes := nil;
  if fNodeCount <= 1 then
  begin
    TAccessibilityDiagnostics.RecordScannerFlattenedNodesBuild(0);
    Exit;
  end;

  SetLength(fFlattenedNodes, fNodeCount - 1);
  TAccessibilityDiagnostics.RecordScannerFlattenedNodesBuild(Length(fFlattenedNodes));
  lIndex := 0;
  AddFlattenedChildren(fRoot, fFlattenedNodes, lIndex);
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

  Inc(fNodeCount);
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
  TAccessibilityDiagnostics.RecordScannerFlattenedNodesSnapshot(Length(fFlattenedNodes));
  Result := Copy(fFlattenedNodes);
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

    if not fRetained then
    begin
      gRetainedHooks.Add(Self);
      fRetained := True;
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
    lHook.fRetained := False;
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
  fRefreshPending := True;
end;

procedure TAccessibilityObservedFormScan.EnsureFresh;
begin
  if not fRefreshPending then
  begin
    fRefreshPending := not CurrentLabelRelationshipStateMatches(fLabelRelationshipState);
  end;
  if fRefreshPending then
  begin
    Refresh;
  end;
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
  RefreshLabelRelationshipState;
end;

procedure TAccessibilityObservedFormScan.RefreshLabelRelationshipState;
begin
  fLabelRelationshipState := CaptureLabelRelationshipState(fForm);
end;

procedure TAccessibilityObservedFormScan.Refresh;
begin
  fRefreshPending := False;
  HookWinControls(fForm);
  Rebuild;
end;

function TAccessibilityObservedFormScan.Revision: Integer;
begin
  EnsureFresh;
  Result := fRevision;
end;

function TAccessibilityObservedFormScan.Tree: IAccessibilityScanTree;
begin
  EnsureFresh;
  Result := fTree;
end;

function CreateControlInfo(aControl: TControl; const aRegistry: IAccessibilityAdapterRegistry;
  const aLabels: TArray<TScannerLabelCandidate>;
  aFocusLabels: TDictionary<TControl, TScannerLabelCandidate>; aCache: TRttiPropertyCache;
  out aAssociatedLabelControl: TControl):
  TAccessibilityControlInfo;
var
  lAdapter: IAccessibilityControlAdapter;
  lAssociatedLabel: TScannerLabelCandidate;
  lText: TAccessibilityTextInfo;
begin
  aAssociatedLabelControl := nil;
  lText := ExtractText(aControl, aCache);
  if IsTextInputControl(aControl) and TryFindAssociatedLabel(aControl, aLabels, aFocusLabels,
    lAssociatedLabel) then
  begin
    lText.Name := lAssociatedLabel.Text;
    aAssociatedLabelControl := lAssociatedLabel.Control;
  end;

  lAdapter := nil;
  if aRegistry <> nil then
  begin
    lAdapter := aRegistry.ResolveAdapter(aControl);
  end;

  if lAdapter <> nil then
  begin
    Result := lAdapter.CreateInfo(aControl, lText);
    if not Result.IncludeInTree then
    begin
      aAssociatedLabelControl := nil;
    end;
    Exit;
  end;

  if (aControl is TWinControl) and TWinControl(aControl).TabStop and not IsTextInputControl(aControl) then
  begin
    Exit(TAccessibilityControlInfo.Omit);
  end;

  if lText.IsEmpty then
  begin
    Result := TAccessibilityControlInfo.Omit;
    aAssociatedLabelControl := nil;
  end else begin
    Result := TAccessibilityControlInfo.Include(aControl, lText.Name, lText.HelpText);
  end;
end;

procedure ScanControlChildren(aParent: TWinControl; const aParentNode: TAccessibilityScanNode;
  const aRegistry: IAccessibilityAdapterRegistry; aCache: TRttiPropertyCache);
var
  i: Integer;
  lAssociatedLabelControl: TControl;
  lChildren: TArray<TControl>;
  lFocusLabels: TDictionary<TControl, TScannerLabelCandidate>;
  lInfo: TAccessibilityControlInfo;
  lLabels: TArray<TScannerLabelCandidate>;
  lNextParent: TAccessibilityScanNode;
begin
  lChildren := SortedChildren(aParent);
  lFocusLabels := nil;
  if ContainsTextInputControl(lChildren) then
  begin
    lLabels := BuildLabelCandidates(lChildren, lFocusLabels, aCache);
  end else begin
    lLabels := [];
  end;
  try
    for i := 0 to High(lChildren) do
    begin
      lInfo := CreateControlInfo(lChildren[i], aRegistry, lLabels, lFocusLabels, aCache,
        lAssociatedLabelControl);
      lNextParent := aParentNode;
      if lInfo.IncludeInTree then
      begin
        lNextParent := TAccessibilityScanNode.Create(lInfo.Control, lInfo.Name, lInfo.HelpText,
          lAssociatedLabelControl);
        aParentNode.AddChild(lNextParent); //PALOFF WARN53 graph owns concrete nodes behind interfaces
      end;

      if lChildren[i] is TWinControl then
      begin
        ScanControlChildren(TWinControl(lChildren[i]), lNextParent, aRegistry, aCache);
      end;
    end;
  finally
    lFocusLabels.Free;
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
  lCache: TRttiPropertyCache;
  lRoot: TAccessibilityScanNode;
begin
  if aForm = nil then
  begin
    raise EArgumentException.Create('Form must not be nil.');
  end;

  lRoot := TAccessibilityScanNode.Create(aForm, TAccessibilityText.Clean(aForm.Caption),
    TAccessibilityText.Clean(aForm.Hint), nil);
  lCache := TRttiPropertyCache.Create;
  try
    ScanControlChildren(aForm, lRoot, aRegistry, lCache);
    Result := TAccessibilityScanTree.Create(lRoot, 1); //PALOFF WARN53 scan tree owns the concrete root
  finally
    lCache.Free;
  end;
end;

initialization

finalization
  TAccessibilityControlHook.ReleaseRetainedHooks;
  gRetainedHooks.Free;

end.
