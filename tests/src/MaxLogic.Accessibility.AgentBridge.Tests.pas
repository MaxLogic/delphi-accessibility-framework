unit MaxLogic.Accessibility.AgentBridge.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('AgentBridge')]
  TAccessibilityAgentBridgeTests = class
  public
    [Test]
    procedure HelloReportsFrameworkPresenceAndMutationGate;
    [Test]
    [Category('AgentBridge,AgentBridgeSnapshotRefs')]
    procedure SnapshotRefsAreGenerationQualifiedAndInvalidated;
    [Test]
    [Category('AgentBridge,AgentBridgeSnapshotRefs')]
    procedure MutationRefsAreInvalidatedBeforeAndAfterDispatch;
    [Test]
    [Category('AgentBridge,AgentBridgeNamedTargets')]
    procedure MutationsAcceptAtomicNameAndHandleTargetsWithoutSnapshot;
    [Test]
    [Category('AgentBridge,AgentBridgeNamedTargets')]
    procedure NamedTargetsRejectMalformedAmbiguousAndNonActionableRequests;
    [Test]
    procedure WindowInfoReturnsGeometryAndDpi;
    [Test]
    procedure FormMapReturnsSnapshotRefsAndTargetPoints;
    [Test]
    procedure FormMapAppliesConfiguredDepthAndChildBounds;
    [Test]
    [Category('AgentBridge,AgentBridgeSnapshotRefs')]
    procedure FormMapReferenceGenerationAvoidsFormatParser;
    [Test]
    procedure FormMapReturnsNativeAccessibilityRoleAndState;
    [Test]
    procedure ProviderMapReturnsInProcessProviderTreeWithVirtualChildren;
    [Test]
    procedure ProviderMapReusesInstalledManagerProviderWithoutRescanningForm;
    [Test]
    procedure ProviderMapQueriesDirectAccessOncePerNode;
    [Test]
    procedure ProviderMapWritesChildMetadataOnce;
    [Test]
    procedure FormMapCanSkipAccessibilityScanForFastNativeSnapshot;
    [Test]
    procedure FormMapCanReturnOnlyVisibleActivePageControls;
    [Test]
    procedure FormMapGeometryDetailSkipsTextAccessibilityAndState;
    [Test]
    procedure FormMapGeometryVisibleOnlyScalesOnDeepNestedControls;
    [Test]
    procedure FormMapGeometrySkipsClientOriginForLeafWindowedControls;
    [Test]
    procedure FormMapGeometryReadsFocusedHandleOnceForFlatWindowedControls;
    [Test]
    procedure FormMapFullCachesRepeatedRttiPropertyLookups;
    [Test]
    procedure FormMapFullAvoidsRttiForStandardVclStringProperties;
    [Test]
    procedure FormMapDoesNotAllocateHiddenControlHandles;
    [Test]
    procedure ControlInfoEnrichesOneSnapshotRefWithoutFullMapScan;
    [Test]
    procedure ControlResolveFindsNamedControlWithoutFullFormMap;
    [Test]
    procedure ControlResolveReportsMdiChildHostContext;
    [Test]
    [Category('AgentBridge,AgentBridgeNamedTargets')]
    procedure FocusRejectsDisabledAncestorBeforeMutation;
    [Test]
    [Category('AgentBridge,AgentBridgeNamedTargets')]
    procedure FocusFailureReportsEffectiveVclContext;
    [Test]
    procedure ControlInfoReusesSnapshotRectangleForMappedControl;
    [Test]
    procedure ControlsInfoBatchesSnapshotRefsWithOneFocusProbe;
    [Test]
    procedure HitTestReturnsControlFromLastSnapshot;
    [Test]
    procedure HitTestUsesSnapshotRectanglesForMappedControls;
    [Test]
    procedure HitTestSkipsSubtreesOutsideTheTargetPoint;
    [Test]
    procedure DiagnosticsCommandsExposeProviderHotspotMetrics;
    [Test]
    procedure KeyboardTabScalesWithTabStopCount;
    [Test]
    [Category('AgentBridge,AgentBridgeBackgroundActions')]
    procedure BackgroundInvokeSupportsVclAndActionControls;
    [Test]
    [Category('AgentBridge,AgentBridgeBackgroundActions')]
    procedure SetCheckedUsesDeterministicVclEvents;
    [Test]
    [Category('AgentBridge,AgentBridgeBackgroundActions')]
    procedure SelectUsesStockVclNotificationOncePerChange;
    [Test]
    [Category('AgentBridge,AgentBridgeBackgroundActions')]
    procedure BackgroundActionsRejectInvalidOrUnsupportedRequests;
    [Test]
    [Category('AgentBridge,AgentBridgeQueuedOperations')]
    procedure QueuedInvokeReportsLifecycleFailureAndConsumption;
    [Test]
    [Category('AgentBridge,AgentBridgeQueuedOperations')]
    procedure QueuedInvokeCancelsDestroyedTargetsAndDisabledMutations;
    [Test]
    [Category('AgentBridge,AgentBridgeQueuedOperations')]
    procedure QueuedInvokeBoundsRegistryAndPreservesOtherCallbacks;
    [Test]
    procedure MutationsAreGatedAndReportBackgroundSemantics;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.Generics.Collections, System.IOUtils, System.JSON, System.SyncObjs, System.SysUtils,
  System.Types, System.TypInfo, System.Variants, Winapi.Windows, Vcl.ActnList, Vcl.Buttons, Vcl.ComCtrls, Vcl.Controls,
  Vcl.ExtCtrls, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.AgentBridge, MaxLogic.Accessibility.Diagnostics,
  MaxLogic.Accessibility.Framework, MaxLogic.Accessibility.Manager, MaxLogic.Accessibility.ProviderCore,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

type
  TAgentBridgeClickRecorder = class
  private
    fClicks: Integer;
  public
    procedure Click(aSender: TObject);
    property Clicks: Integer read fClicks;
  end;

  TAgentBridgeRefProbe = class
  private
    fErrorCode: string;
    fProbeRef: string;
  public
    procedure Click(aSender: TObject);
    property ErrorCode: string read fErrorCode;
    property ProbeRef: string read fProbeRef write fProbeRef;
  end;

  TAgentBridgeFallbackTextControl = class(TCustomControl)
  private
    fFallbackText: string;
  published
    property Text: string read fFallbackText write fFallbackText;
  end;

  TAgentBridgeTabOrderProbeEdit = class(TEdit)
  private
    class var fTabOrderListCalls: Integer;
  protected
    procedure GetTabOrderList(aList: System.Classes.TList); override;
  public
    class function TabOrderListCalls: Integer; static;
    class procedure ResetTabOrderListCalls; static;
  end;

  TAgentBridgeFailingFocusEdit = class(TEdit)
  private
    fFailFocus: Boolean;
  public
    procedure SetFocus; override;
    property FailFocus: Boolean read fFailFocus write fFailFocus;
  end;

  TAgentBridgeFailingClickButton = class(TButton)
  public
    procedure Click; override;
  end;

  TAgentBridgeOperationProbe = class
  private
    fClicks: Integer;
    fObservedStatus: string;
    fOperationId: string;
  public
    procedure Click(aSender: TObject);
    property Clicks: Integer read fClicks;
    property ObservedStatus: string read fObservedStatus;
    property OperationId: string read fOperationId write fOperationId;
  end;

  TAgentBridgeQueuedProbe = class
  private
    fCalls: Integer;
  public
    procedure Run;
    property Calls: Integer read fCalls;
  end;

  TAgentBridgeProviderQueryMetrics = record
    ChildAccessQueries: Integer;
    DirectAccessQueries: Integer;
    GeometryAccessQueries: Integer;
    VclInfoQueries: Integer;
  end;

  PAgentBridgeProviderQueryMetrics = ^TAgentBridgeProviderQueryMetrics;

  TAgentBridgeCountingProvider = class(TObject, IInterface, IRawElementProviderSimple,
    IAccessibilityProviderDirectAccess, IAccessibilityProviderGeometryAccess, IAccessibilityProviderChildAccess,
    IAccessibilityVclControlProviderInfo)
  private
    fChild: IRawElementProviderSimple;
    fChildCountResult: HResult;
    fChildCountValue: Integer;
    fMetrics: PAgentBridgeProviderQueryMetrics;
    fRefCount: Integer;
  public
    constructor Create(aMetrics: PAgentBridgeProviderQueryMetrics; aChildCountResult: HResult;
      aChildCountValue: Integer; const aChild: IRawElementProviderSimple);
  protected
    function QueryInterface(const aIID: TGUID; out aObject): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    function Control: TControl;
    function DirectChildAt(aIndex: Integer; out aProvider: IRawElementProviderSimple): HResult;
    function DirectChildCount(out aCount: Integer): HResult;
    function Get_HostRawElementProvider(out aRetVal: IRawElementProviderSimple): HResult; stdcall;
    function Get_ProviderOptions(out aRetVal: ProviderOptions): HResult; stdcall;
    function GetPatternProvider(aPatternId: PATTERNID; out aRetVal: IUnknown): HResult; stdcall;
    function GetPropertyValue(aPropertyId: PROPERTYID; out aRetVal: OleVariant): HResult; stdcall;
    function SupportsPatternDirect(aPatternId: PATTERNID): Boolean;
    function TryGetBoundingRectangle(out aValue: UiaRect): Boolean;
    function TryGetIntegerProperty(aPropertyId: PROPERTYID; out aValue: Integer): Boolean;
    function TryGetNativeWindowHandle(out aValue: HWND): Boolean;
    function TryGetStringProperty(aPropertyId: PROPERTYID; out aValue: string): Boolean;
    function TryGetValueText(out aValue: string): Boolean;
  end;

procedure TAgentBridgeClickRecorder.Click(aSender: TObject);
begin
  Inc(fClicks);
end;

procedure TAgentBridgeTabOrderProbeEdit.GetTabOrderList(aList: System.Classes.TList);
begin
  Inc(fTabOrderListCalls);
  inherited GetTabOrderList(aList);
end;

class procedure TAgentBridgeTabOrderProbeEdit.ResetTabOrderListCalls;
begin
  fTabOrderListCalls := 0;
end;

class function TAgentBridgeTabOrderProbeEdit.TabOrderListCalls: Integer;
begin
  Result := fTabOrderListCalls;
end;

procedure TAgentBridgeFailingFocusEdit.SetFocus;
begin
  if fFailFocus then
  begin
    raise EInvalidOperation.Create('Expected bridge focus failure.');
  end;
  inherited SetFocus;
end;

procedure TAgentBridgeFailingClickButton.Click;
begin
  raise EInvalidOperation.Create('Expected queued invoke failure.');
end;

constructor TAgentBridgeCountingProvider.Create(aMetrics: PAgentBridgeProviderQueryMetrics;
  aChildCountResult: HResult; aChildCountValue: Integer; const aChild: IRawElementProviderSimple);
begin
  inherited Create;
  fChild := aChild;
  fChildCountResult := aChildCountResult;
  fChildCountValue := aChildCountValue;
  fMetrics := aMetrics;
end;

function TAgentBridgeCountingProvider._AddRef: Integer;
begin
  Result := TInterlocked.Increment(fRefCount);
end;

function TAgentBridgeCountingProvider._Release: Integer;
begin
  Result := TInterlocked.Decrement(fRefCount);
  if Result = 0 then
  begin
    Destroy;
  end;
end;

function TAgentBridgeCountingProvider.Control: TControl;
begin
  Result := nil;
end;

function TAgentBridgeCountingProvider.DirectChildAt(aIndex: Integer;
  out aProvider: IRawElementProviderSimple): HResult;
begin
  aProvider := nil;
  if (aIndex = 0) and (fChild <> nil) then
  begin
    aProvider := fChild;
    Exit(S_OK);
  end;

  Result := E_INVALIDARG;
end;

function TAgentBridgeCountingProvider.DirectChildCount(out aCount: Integer): HResult;
begin
  aCount := fChildCountValue;
  Result := fChildCountResult;
end;

function TAgentBridgeCountingProvider.Get_HostRawElementProvider(
  out aRetVal: IRawElementProviderSimple): HResult;
begin
  aRetVal := nil;
  Result := S_FALSE;
end;

function TAgentBridgeCountingProvider.Get_ProviderOptions(out aRetVal: ProviderOptions): HResult;
begin
  aRetVal := ProviderOptions_ServerSideProvider;
  Result := S_OK;
end;

function TAgentBridgeCountingProvider.GetPatternProvider(aPatternId: PATTERNID; out aRetVal: IUnknown): HResult;
begin
  aRetVal := nil;
  Result := S_OK;
end;

function TAgentBridgeCountingProvider.GetPropertyValue(aPropertyId: PROPERTYID;
  out aRetVal: OleVariant): HResult;
begin
  aRetVal := Unassigned;
  Result := S_OK;
end;

function TAgentBridgeCountingProvider.QueryInterface(const aIID: TGUID; out aObject): HResult;
begin
  if not GetInterface(aIID, aObject) then
  begin
    Exit(E_NOINTERFACE);
  end;

  if fMetrics <> nil then
  begin
    if IsEqualGUID(aIID, GetTypeData(TypeInfo(IAccessibilityProviderDirectAccess))^.Guid) then
    begin
      Inc(fMetrics^.DirectAccessQueries);
    end else if IsEqualGUID(aIID, GetTypeData(TypeInfo(IAccessibilityProviderGeometryAccess))^.Guid) then
    begin
      Inc(fMetrics^.GeometryAccessQueries);
    end else if IsEqualGUID(aIID, GetTypeData(TypeInfo(IAccessibilityProviderChildAccess))^.Guid) then
    begin
      Inc(fMetrics^.ChildAccessQueries);
    end else if IsEqualGUID(aIID, GetTypeData(TypeInfo(IAccessibilityVclControlProviderInfo))^.Guid) then
    begin
      Inc(fMetrics^.VclInfoQueries);
    end;
  end;

  Result := S_OK;
end;

function TAgentBridgeCountingProvider.SupportsPatternDirect(aPatternId: PATTERNID): Boolean;
begin
  Result := False;
end;

function TAgentBridgeCountingProvider.TryGetBoundingRectangle(out aValue: UiaRect): Boolean;
begin
  aValue.Left := 10;
  aValue.Top := 20;
  aValue.Width := 100;
  aValue.Height := 30;
  Result := True;
end;

function TAgentBridgeCountingProvider.TryGetIntegerProperty(aPropertyId: PROPERTYID;
  out aValue: Integer): Boolean;
begin
  aValue := 0;
  if aPropertyId = UIA_ControlTypePropertyId then
  begin
    aValue := UIA_ButtonControlTypeId;
    Exit(True);
  end;

  Result := False;
end;

function TAgentBridgeCountingProvider.TryGetNativeWindowHandle(out aValue: HWND): Boolean;
begin
  aValue := 0;
  Result := False;
end;

function TAgentBridgeCountingProvider.TryGetStringProperty(aPropertyId: PROPERTYID; out aValue: string): Boolean;
begin
  aValue := '';
  if aPropertyId = UIA_NamePropertyId then
  begin
    aValue := 'Counting provider';
    Exit(True);
  end;

  Result := False;
end;

function TAgentBridgeCountingProvider.TryGetValueText(out aValue: string): Boolean;
begin
  aValue := '';
  Result := False;
end;

function JsonObjectFrom(const aText: string): TJSONObject;
var
  lValue: TJSONValue;
begin
  lValue := TJSONObject.ParseJSONValue(aText, True, True);
  Assert.IsNotNull(lValue, 'JSON response was empty.');
  Assert.IsTrue(lValue is TJSONObject, 'JSON response is not an object.');
  Result := TJSONObject(lValue); //PALOFF STWA6 guarded by JSON type assertion
end;

function JsonObjectValue(aObject: TJSONObject; const aName: string): TJSONObject;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing object value: ' + aName);
  Assert.IsTrue(lValue is TJSONObject, 'Value is not an object: ' + aName);
  Result := TJSONObject(lValue); //PALOFF STWA6 guarded by JSON type assertion
end;

function JsonArrayValue(aObject: TJSONObject; const aName: string): TJSONArray;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing array value: ' + aName);
  Assert.IsTrue(lValue is TJSONArray, 'Value is not an array: ' + aName);
  Result := TJSONArray(lValue); //PALOFF STWA6 guarded by JSON type assertion
end;

function JsonText(aObject: TJSONObject; const aName: string): string;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing text value: ' + aName);
  Result := lValue.Value;
end;

function JsonInt(aObject: TJSONObject; const aName: string): Integer;
begin
  Result := StrToInt(JsonText(aObject, aName));
end;

function JsonHasValue(aObject: TJSONObject; const aName: string): Boolean;
begin
  Result := aObject.GetValue(aName) <> nil;
end;

procedure TAgentBridgeOperationProbe.Click(aSender: TObject);
var
  lResponse: TJSONObject;
begin
  Inc(fClicks);
  lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
    '{"cmd":"operation.status","operationId":"' + fOperationId + '"}'));
  try
    if SameText(JsonText(lResponse, 'ok'), 'true') then
    begin
      fObservedStatus := JsonText(lResponse, 'status');
    end;
  finally
    lResponse.Free;
  end;
end;

procedure TAgentBridgeQueuedProbe.Run;
begin
  Inc(fCalls);
end;

procedure TAgentBridgeRefProbe.Click(aSender: TObject);
var
  lResponse: TJSONObject;
begin
  lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
    '{"cmd":"control.info","ref":"' + fProbeRef + '"}'));
  try
    fErrorCode := JsonText(lResponse, 'errorCode');
  finally
    lResponse.Free;
  end;
end;

function JsonPairCount(aObject: TJSONObject; const aName: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Pred(aObject.Count) do
  begin
    if SameText(aObject.Pairs[i].JsonString.Value, aName) then
    begin
      Inc(Result);
    end;
  end;
end;

function CreateCountingProvider(var aMetrics: TAgentBridgeProviderQueryMetrics; aChildCountResult: HResult;
  aChildCountValue: Integer; const aChild: IRawElementProviderSimple): IRawElementProviderSimple;
begin
  Result := TAgentBridgeCountingProvider.Create(@aMetrics, aChildCountResult, aChildCountValue, aChild);
end;

function RepoRoot: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\..'));
end;

function ReadRepoText(const aRelativePath: string): string;
var
  lPath: string;
begin
  lPath := TPath.Combine(RepoRoot, aRelativePath);
  Assert.IsTrue(TFile.Exists(lPath), aRelativePath + ' is missing.');
  Result := TFile.ReadAllText(lPath, TEncoding.UTF8);
end;

procedure BuildBridgeTestForm(out aForm: TForm; out aEdit: TEdit; out aButton: TButton);
begin
  aForm := TForm.Create(nil);
  aForm.Name := 'BridgeForm';
  aForm.Caption := 'Bridge Test Window';
  aForm.SetBounds(200, 150, 360, 200);

  aEdit := TEdit.Create(aForm);
  aEdit.Name := 'SearchEdit';
  aEdit.Hint := 'Search text';
  aEdit.TabOrder := 0;
  aEdit.SetBounds(20, 24, 140, 24);
  aEdit.Parent := aForm;

  aButton := TButton.Create(aForm);
  aButton.Name := 'ApplyButton';
  aButton.Caption := 'Apply';
  aButton.TabOrder := 1;
  aButton.SetBounds(20, 64, 90, 28);
  aButton.Parent := aForm;

  aForm.HandleNeeded;
  aEdit.HandleNeeded;
  aButton.HandleNeeded;
end;

function BuildTabOrderStressForm(aControlCount: Integer): TForm;
var
  i: Integer;
  lEdit: TAgentBridgeTabOrderProbeEdit;
begin
  Result := TForm.Create(nil);
  Result.Name := 'BridgeTabStressForm';
  Result.Caption := 'Bridge Tab Stress Window';
  Result.SetBounds(200, 150, 420, 280);

  for i := 0 to Pred(aControlCount) do
  begin
    lEdit := TAgentBridgeTabOrderProbeEdit.Create(Result);
    lEdit.Parent := Result;
    lEdit.TabOrder := Pred(aControlCount) - i;
    lEdit.SetBounds(8, 8, 120, 22);
  end;

  Result.HandleNeeded;
end;

function BuildDeepPanelMapForm(aDepth: Integer): TForm;
var
  i: Integer;
  lLabel: TLabel;
  lPanel: TPanel;
  lParent: TWinControl;
begin
  Result := TForm.Create(nil);
  Result.Name := 'BridgeDeepMapForm';
  Result.Caption := 'Bridge Deep Map Window';
  Result.SetBounds(200, 150, 420, 280);

  lParent := Result;
  for i := 0 to Pred(aDepth) do
  begin
    lPanel := TPanel.Create(Result);
    lPanel.Name := 'NestedPanel' + IntToStr(i);
    lPanel.SetBounds(1, 1, 240, 120);
    lPanel.Parent := lParent;

    lLabel := TLabel.Create(Result);
    lLabel.Name := 'NestedLabel' + IntToStr(i);
    lLabel.Caption := 'Nested label ' + IntToStr(i);
    lLabel.SetBounds(2, 2, 96, 17);
    lLabel.Parent := lPanel;

    lParent := lPanel;
  end;

  Result.HandleNeeded;
end;

function BuildHitTestBranchForm(aDepth: Integer; out aTargetButton: TButton): TForm;
var
  i: Integer;
  lPanel: TPanel;
  lParent: TWinControl;
begin
  Result := TForm.Create(nil);
  Result.Name := 'BridgeHitTestBranchForm';
  Result.Caption := 'Bridge Hit Test Branch Window';
  Result.SetBounds(200, 150, 640, 360);

  aTargetButton := TButton.Create(Result);
  aTargetButton.Name := 'TargetButton';
  aTargetButton.Caption := 'Target';
  aTargetButton.SetBounds(360, 40, 90, 28);
  aTargetButton.Parent := Result;

  lParent := Result;
  for i := 0 to Pred(aDepth) do
  begin
    lPanel := TPanel.Create(Result);
    lPanel.Name := 'IgnoredBranchPanel' + IntToStr(i);
    lPanel.SetBounds(1, 1, 220, 96);
    lPanel.Parent := lParent;
    lParent := lPanel;
  end;

  Result.HandleNeeded;
end;

function BuildFlatGeometryMapForm(aControlCount: Integer; aWindowed: Boolean): TForm;
var
  i: Integer;
  lEdit: TEdit;
  lLabel: TLabel;
begin
  Result := TForm.Create(nil);
  Result.Name := 'BridgeFlatMapForm';
  Result.Caption := 'Bridge Flat Map Window';
  Result.SetBounds(200, 150, 640, 480);

  for i := 0 to Pred(aControlCount) do
  begin
    if aWindowed then
    begin
      lEdit := TEdit.Create(Result);
      lEdit.Name := 'WindowedEdit' + IntToStr(i);
      lEdit.Parent := Result;
      lEdit.TabOrder := i;
      lEdit.SetBounds(8 + (i mod 20) * 28, 8 + (i div 20) * 20, 24, 18);
    end else begin
      lLabel := TLabel.Create(Result);
      lLabel.Name := 'NonWindowedLabel' + IntToStr(i);
      lLabel.Parent := Result;
      lLabel.SetBounds(8 + (i mod 20) * 28, 8 + (i div 20) * 20, 24, 18);
    end;
  end;

  Result.HandleNeeded;
  if aWindowed then
  begin
    for i := 0 to Pred(Result.ControlCount) do
    begin
      if Result.Controls[i] is TWinControl then
      begin
        TWinControl(Result.Controls[i]).HandleNeeded;
      end;
    end;
  end;
end;

function BuildFallbackTextMapForm(aControlCount: Integer): TForm;
var
  i: Integer;
  lControl: TAgentBridgeFallbackTextControl;
begin
  Result := TForm.Create(nil);
  Result.Name := 'BridgeFallbackTextMapForm';
  Result.Caption := 'Bridge Fallback Text Map Window';
  Result.SetBounds(200, 150, 640, 480);

  for i := 0 to Pred(aControlCount) do
  begin
    lControl := TAgentBridgeFallbackTextControl.Create(Result);
    lControl.Name := 'FallbackTextControl' + IntToStr(i);
    lControl.Text := 'Fallback text ' + IntToStr(i);
    lControl.Parent := Result;
    lControl.SetBounds(8 + (i mod 20) * 28, 8 + (i div 20) * 20, 24, 18);
  end;

  Result.HandleNeeded;
end;

function BuildStandardNativeStringMapForm: TForm;
var
  lButton: TButton;
  lCheckBox: TCheckBox;
  lComboBox: TComboBox;
  lEdit: TEdit;
  lGroupBox: TGroupBox;
  lLabel: TLabel;
  lListBox: TListBox;
  lPageControl: TPageControl;
  lSplitter: TSplitter;
  lStatusBar: TStatusBar;
  lStringGrid: TStringGrid;
  lTabSheet: TTabSheet;
  lToolBar: TToolBar;
begin
  Result := TForm.Create(nil);
  Result.Name := 'BridgeNativeStringMapForm';
  Result.Caption := 'Bridge Native String Map Window';
  Result.SetBounds(200, 150, 720, 420);

  lButton := TButton.Create(Result);
  lButton.Name := 'ActionButton';
  lButton.Caption := 'Apply';
  lButton.SetBounds(16, 16, 96, 28);
  lButton.Parent := Result;

  lCheckBox := TCheckBox.Create(Result);
  lCheckBox.Name := 'EnabledCheckBox';
  lCheckBox.Caption := 'Enabled';
  lCheckBox.Checked := True;
  lCheckBox.SetBounds(16, 56, 120, 24);
  lCheckBox.Parent := Result;

  lEdit := TEdit.Create(Result);
  lEdit.Name := 'SearchEdit';
  lEdit.Text := 'Query';
  lEdit.SetBounds(16, 88, 140, 24);
  lEdit.Parent := Result;

  lComboBox := TComboBox.Create(Result);
  lComboBox.Name := 'ModeComboBox';
  lComboBox.SetBounds(16, 120, 140, 24);
  lComboBox.Parent := Result;
  lComboBox.Items.Add('All');
  lComboBox.ItemIndex := 0;

  lListBox := TListBox.Create(Result);
  lListBox.Name := 'EventsListBox';
  lListBox.SetBounds(176, 16, 140, 96);
  lListBox.Parent := Result;
  lListBox.Items.Add('Created');
  lListBox.ItemIndex := 0;

  lLabel := TLabel.Create(Result);
  lLabel.Name := 'HeaderLabel';
  lLabel.Caption := 'Header';
  lLabel.SetBounds(176, 120, 120, 20);
  lLabel.Parent := Result;

  lGroupBox := TGroupBox.Create(Result);
  lGroupBox.Name := 'OptionsGroup';
  lGroupBox.Caption := 'Options';
  lGroupBox.SetBounds(336, 16, 160, 96);
  lGroupBox.Parent := Result;

  lPageControl := TPageControl.Create(Result);
  lPageControl.Name := 'Pages';
  lPageControl.SetBounds(336, 128, 180, 120);
  lPageControl.Parent := Result;

  lTabSheet := TTabSheet.Create(Result);
  lTabSheet.Name := 'SummaryPage';
  lTabSheet.Caption := 'Summary';
  lTabSheet.PageControl := lPageControl;

  lStringGrid := TStringGrid.Create(Result);
  lStringGrid.Name := 'DataGrid';
  lStringGrid.SetBounds(16, 160, 260, 110);
  lStringGrid.Parent := Result;
  lStringGrid.ColCount := 2;
  lStringGrid.RowCount := 2;
  lStringGrid.Cells[0, 0] := 'Name';
  lStringGrid.Cells[1, 1] := 'Value';

  lToolBar := TToolBar.Create(Result);
  lToolBar.Name := 'MainToolBar';
  lToolBar.SetBounds(16, 288, 260, 28);
  lToolBar.Parent := Result;

  lSplitter := TSplitter.Create(Result);
  lSplitter.Name := 'FilterSplitter';
  lSplitter.SetBounds(296, 288, 6, 96);
  lSplitter.Parent := Result;

  lStatusBar := TStatusBar.Create(Result);
  lStatusBar.Name := 'MainStatusBar';
  lStatusBar.SimpleText := 'Ready';
  lStatusBar.Parent := Result;

  Result.HandleNeeded;
end;

function MapForm(aForm: TCustomForm; aIncludeAccessibility: Boolean = True; aVisibleOnly: Boolean = False;
  const aDetail: string = ''): TJSONObject;
var
  lDetail: string;
  lIncludeAccessibility: string;
  lResponse: string;
  lVisibleOnly: string;
begin
  if aIncludeAccessibility then
  begin
    lIncludeAccessibility := 'true';
  end else begin
    lIncludeAccessibility := 'false';
  end;

  if aVisibleOnly then
  begin
    lVisibleOnly := 'true';
  end else begin
    lVisibleOnly := 'false';
  end;

  lDetail := '';
  if aDetail <> '' then
  begin
    lDetail := ',"detail":"' + aDetail + '"';
  end;

  lResponse := TAccessibilityAgentBridge.Execute(
    '{"cmd":"form.map","target":"handle","handle":' + UIntToStr(NativeUInt(aForm.Handle)) +
    ',"includeAccessibility":' + lIncludeAccessibility + ',"visibleOnly":' + lVisibleOnly + lDetail + '}');
  Result := JsonObjectFrom(lResponse);
end;

function ProviderMapForm(aForm: TCustomForm; const aDetail: string = 'full'; aMaxDepth: Integer = 3;
  aMaxChildren: Integer = 200): TJSONObject;
var
  lResponse: string;
begin
  lResponse := TAccessibilityAgentBridge.Execute(
    '{"cmd":"provider.map","target":"handle","handle":' + UIntToStr(NativeUInt(aForm.Handle)) +
    ',"detail":"' + aDetail + '","maxDepth":' + IntToStr(aMaxDepth) + ',"maxChildren":' +
    IntToStr(aMaxChildren) + '}');
  Result := JsonObjectFrom(lResponse);
end;

function ProviderNodeByName(aNode: TJSONObject; const aName: string): TJSONObject;
var
  i: Integer;
  lChild: TJSONObject;
  lChildren: TJSONArray;
begin
  if JsonHasValue(aNode, 'name') and (JsonText(aNode, 'name') = aName) then
  begin
    Exit(aNode);
  end;

  lChildren := JsonArrayValue(aNode, 'children');
  for i := 0 to Pred(lChildren.Count) do
  begin
    if not (lChildren.Items[i] is TJSONObject) then
    begin
      Continue;
    end;

    lChild := ProviderNodeByName(TJSONObject(lChildren.Items[i]), aName);
    if lChild <> nil then
    begin
      Exit(lChild);
    end;
  end;

  Result := nil;
end;

function ProviderNodeByVclName(aNode: TJSONObject; const aName: string): TJSONObject;
var
  i: Integer;
  lChild: TJSONObject;
  lChildren: TJSONArray;
begin
  if JsonHasValue(aNode, 'vclName') and (JsonText(aNode, 'vclName') = aName) then
  begin
    Exit(aNode);
  end;

  lChildren := JsonArrayValue(aNode, 'children');
  for i := 0 to Pred(lChildren.Count) do
  begin
    if not (lChildren.Items[i] is TJSONObject) then
    begin
      Continue;
    end;

    lChild := ProviderNodeByVclName(TJSONObject(lChildren.Items[i]), aName);
    if lChild <> nil then
    begin
      Exit(lChild);
    end;
  end;

  Result := nil;
end;

function RequireProviderNodeByName(aMap: TJSONObject; const aName: string): TJSONObject;
begin
  Result := ProviderNodeByName(JsonObjectValue(aMap, 'root'), aName);
  Assert.IsNotNull(Result, 'Provider node was not found in map: ' + aName);
end;

function RequireProviderNodeByVclName(aMap: TJSONObject; const aName: string): TJSONObject;
begin
  Result := ProviderNodeByVclName(JsonObjectValue(aMap, 'root'), aName);
  Assert.IsNotNull(Result, 'Provider node was not found in map by VCL name: ' + aName);
end;

function ControlByName(aMap: TJSONObject; const aName: string): TJSONObject;
var
  i: Integer;
  lControl: TJSONObject;
  lControls: TJSONArray;
begin
  lControls := JsonArrayValue(aMap, 'controls');
  for i := 0 to Pred(lControls.Count) do
  begin
    Assert.IsTrue(lControls.Items[i] is TJSONObject, 'Control entry is not an object.');
    lControl := TJSONObject(lControls.Items[i]);
    if JsonText(lControl, 'name') = aName then
    begin
      Exit(lControl);
    end;
  end;

  Assert.Fail('Control was not found in map: ' + aName);
  Result := nil;
end;

function ControlRefByName(aMap: TJSONObject; const aName: string): string;
begin
  Result := JsonText(ControlByName(aMap, aName), 'ref');
end;

function ControlExistsByName(aMap: TJSONObject; const aName: string): Boolean;
var
  i: Integer;
  lControl: TJSONObject;
  lControls: TJSONArray;
begin
  lControls := JsonArrayValue(aMap, 'controls');
  for i := 0 to Pred(lControls.Count) do
  begin
    if not (lControls.Items[i] is TJSONObject) then
    begin
      Continue;
    end;

    lControl := TJSONObject(lControls.Items[i]);
    if JsonText(lControl, 'name') = aName then
    begin
      Exit(True);
    end;
  end;

  Result := False;
end;

procedure AssertOk(aResponse: TJSONObject);
begin
  Assert.AreEqual('true', JsonText(aResponse, 'ok'), aResponse.ToJSON);
  Assert.AreEqual(2, JsonInt(aResponse, 'protocolVersion'), aResponse.ToJSON);
end;

procedure AssertFailure(aResponse: TJSONObject; const aErrorCode: string);
begin
  Assert.AreEqual('false', JsonText(aResponse, 'ok'), aResponse.ToJSON);
  Assert.AreEqual(aErrorCode, JsonText(aResponse, 'errorCode'), aResponse.ToJSON);
  Assert.AreEqual(2, JsonInt(aResponse, 'protocolVersion'), aResponse.ToJSON);
end;

function MeasureBestGeometryMapTicks(aDepth: Integer; aSamples: Integer): Int64;
var
  i: Integer;
  lForm: TForm;
  lMap: TJSONObject;
  lStopwatch: TStopwatch;
  lTicks: Int64;
begin
  Result := High(Int64);
  lForm := BuildDeepPanelMapForm(aDepth);
  try
    for i := 1 to aSamples do
    begin
      lStopwatch := TStopwatch.StartNew;
      lMap := MapForm(lForm, False, True, 'geometry');
      lStopwatch.Stop;
      try
        AssertOk(lMap);
      finally
        lMap.Free;
      end;

      lTicks := lStopwatch.ElapsedTicks;
      if lTicks < Result then
      begin
        Result := lTicks;
      end;
    end;

    if Result < 1 then
    begin
      Result := 1;
    end;
  finally
    lForm.Free;
  end;
end;

function MeasureBestHitTestTicks(aDepth: Integer; aSamples: Integer): Int64;
var
  i: Integer;
  lButton: TButton;
  lForm: TForm;
  lMap: TJSONObject;
  lPoint: TPoint;
  lResponse: TJSONObject;
  lStopwatch: TStopwatch;
  lTicks: Int64;
begin
  Result := High(Int64);
  lForm := BuildHitTestBranchForm(aDepth, lButton);
  try
    lMap := MapForm(lForm, False, True, 'geometry');
    try
      AssertOk(lMap);
    finally
      lMap.Free;
    end;

    lPoint := lButton.ClientToScreen(Point(lButton.Width div 2, lButton.Height div 2));
    for i := 1 to aSamples do
    begin
      lStopwatch := TStopwatch.StartNew;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        Format('{"cmd":"hitTest","x":%d,"y":%d}', [lPoint.X, lPoint.Y])));
      lStopwatch.Stop;
      try
        AssertOk(lResponse);
        Assert.AreEqual('TargetButton', JsonText(lResponse, 'name'));
      finally
        lResponse.Free;
      end;

      lTicks := lStopwatch.ElapsedTicks;
      if lTicks < Result then
      begin
        Result := lTicks;
      end;
    end;

    if Result < 1 then
    begin
      Result := 1;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.HelloReportsFrameworkPresenceAndMutationGate;
var
  lResponse: TJSONObject;
begin
  TAccessibilityAgentBridge.SetMutationEnabled(False);
  lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"hello"}'));
  try
    AssertOk(lResponse);
    Assert.AreEqual(cAccessibilityFrameworkName, JsonText(lResponse, 'frameworkName'));
    Assert.AreEqual(2, JsonInt(lResponse, 'protocolVersion'));
    Assert.AreEqual('false', JsonText(lResponse, 'mutationEnabled'));
  finally
    lResponse.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.SnapshotRefsAreGenerationQualifiedAndInvalidated;
var
  lCapabilities: TJSONArray;
  lCurrentRef: string;
  lEdit: TEdit;
  lFirstRef: string;
  lForm: TForm;
  lMap: TJSONObject;
  lResponse: TJSONObject;
  lSnapshotId: Integer;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'GenerationBridgeForm';
    lEdit := TEdit.Create(lForm);
    lEdit.Name := 'GenerationEdit';
    lEdit.Parent := lForm;
    lForm.Show;
    Application.ProcessMessages;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"hello"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual(2, JsonInt(lResponse, 'protocolVersion'));
      lCapabilities := JsonArrayValue(lResponse, 'capabilities');
      Assert.IsTrue(lCapabilities.ToJSON.Contains('"background-command-mode"'));
      Assert.IsTrue(lCapabilities.ToJSON.Contains('"snapshot-refs-v2"'));
      Assert.IsTrue(lCapabilities.ToJSON.Contains('"atomic-control-targets"'));
    finally
      lResponse.Free;
    end;

    lMap := MapForm(lForm);
    try
      lSnapshotId := JsonInt(lMap, 'snapshotId');
      lFirstRef := ControlRefByName(lMap, 'GenerationEdit');
      Assert.IsTrue(lFirstRef.StartsWith(Format('@s%da', [lSnapshotId])));
    finally
      lMap.Free;
    end;

    lMap := MapForm(lForm);
    try
      lSnapshotId := JsonInt(lMap, 'snapshotId');
      lCurrentRef := ControlRefByName(lMap, 'GenerationEdit');
      Assert.IsTrue(lCurrentRef.StartsWith(Format('@s%da', [lSnapshotId])));
      Assert.IsTrue(lFirstRef <> lCurrentRef, 'A remap must not reuse an older snapshot ref.');
    finally
      lMap.Free;
    end;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lFirstRef + '"}'));
    try
      AssertFailure(lResponse, 'stale_ref');
    finally
      lResponse.Free;
    end;

    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","ref":"' + lCurrentRef + '","text":"changed"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(2, JsonInt(lResponse, 'protocolVersion'));
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lCurrentRef + '"}'));
    try
      AssertFailure(lResponse, 'stale_ref');
    finally
      lResponse.Free;
    end;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{'));
    try
      AssertFailure(lResponse, 'invalid_json');
    finally
      lResponse.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.MutationRefsAreInvalidatedBeforeAndAfterDispatch;
var
  lButton: TButton;
  lButtonRef: string;
  lEdit: TEdit;
  lEditRef: string;
  lForm: TForm;
  lMap: TJSONObject;
  lProbe: TAgentBridgeRefProbe;
  lResponse: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  lForm.Show;
  Application.ProcessMessages;
  lProbe := TAgentBridgeRefProbe.Create;
  try
    lMap := MapForm(lForm);
    try
      lButtonRef := ControlRefByName(lMap, 'ApplyButton');
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
    finally
      lMap.Free;
    end;

    lProbe.ProbeRef := lEditRef;
    lButton.OnClick := lProbe.Click;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.click","ref":"' + lButtonRef + '"}'));
      try
        AssertOk(lResponse);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
    Assert.AreEqual('stale_ref', lProbe.ErrorCode,
      'Snapshot refs must be invalid before a reentrant click handler runs.');

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lButtonRef + '"}'));
    try
      AssertFailure(lResponse, 'stale_ref');
    finally
      lResponse.Free;
    end;

    lMap := MapForm(lForm);
    try
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
    finally
      lMap.Free;
    end;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"keyboard.tab"}'));
      try
        AssertOk(lResponse);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lEditRef + '"}'));
    try
      AssertFailure(lResponse, 'stale_ref');
    finally
      lResponse.Free;
    end;

    lMap := MapForm(lForm);
    try
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
    finally
      lMap.Free;
    end;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.focus","ref":"' + lEditRef + '"}'));
      try
        AssertOk(lResponse);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lEditRef + '"}'));
    try
      AssertFailure(lResponse, 'stale_ref');
    finally
      lResponse.Free;
    end;

    lMap := MapForm(lForm);
    try
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
    finally
      lMap.Free;
    end;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.typeText","ref":"' + lEditRef + '","text":"x"}'));
      try
        AssertOk(lResponse);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lEditRef + '"}'));
    try
      AssertFailure(lResponse, 'stale_ref');
    finally
      lResponse.Free;
    end;
  finally
    lProbe.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.MutationsAcceptAtomicNameAndHandleTargetsWithoutSnapshot;
var
  lButton: TButton;
  lClickRecorder: TAgentBridgeClickRecorder;
  lEdit: TEdit;
  lForm: TForm;
  lHandle: string;
  lResponse: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  lForm.Show;
  Application.ProcessMessages;
  lHandle := UIntToStr(NativeUInt(lForm.Handle));
  lClickRecorder := TAgentBridgeClickRecorder.Create;
  try
    lButton.OnClick := lClickRecorder.Click;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.focus","target":{"formName":"BridgeForm","controlName":"SearchEdit"}}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreSame(lEdit, lForm.ActiveControl);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formHandle":' + lHandle +
        ',"controlName":"SearchEdit"},"text":"base"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('base', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.typeText","target":{"formName":"BridgeForm","controlName":"SearchEdit"},' +
        '"text":" plus"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('base plus', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.click","target":{"formHandle":' + lHandle +
        ',"controlName":"ApplyButton"}}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(1, lClickRecorder.Clicks);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lClickRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.NamedTargetsRejectMalformedAmbiguousAndNonActionableRequests;
var
  lButton: TButton;
  lDeadForm: TForm;
  lDeadHandle: string;
  lDuplicateForm: TForm;
  lDuplicateFormEdit: TEdit;
  lDuplicateText: string;
  lDuplicateOwner: TPanel;
  lEdit: TEdit;
  lEditText: string;
  lForeignEdit: TEdit;
  lForeignForm: TForm;
  lForeignText: string;
  lForm: TForm;
  lMap: TJSONObject;
  lRef: string;
  lResponse: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  lEditText := lEdit.Text;
  lForm.Show;
  Application.ProcessMessages;
  lDuplicateForm := nil;
  lForeignForm := nil;
  lDeadForm := TForm.Create(nil);
  try
    lDeadForm.Name := 'DeadBridgeForm';
    lDeadForm.HandleNeeded;
    lDeadHandle := UIntToStr(NativeUInt(lDeadForm.Handle));
  finally
    lDeadForm.Free;
  end;

  try
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm"},"text":"bad"}'));
      try
        AssertFailure(lResponse, 'invalid_request');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm","formHandle":' +
        UIntToStr(NativeUInt(lForm.Handle)) + ',"controlName":"SearchEdit"},"text":"bad"}'));
      try
        AssertFailure(lResponse, 'invalid_request');
      finally
        lResponse.Free;
      end;

      lMap := MapForm(lForm);
      try
        lRef := ControlRefByName(lMap, 'SearchEdit');
      finally
        lMap.Free;
      end;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","ref":"' + lRef +
        '","target":{"formName":"BridgeForm","controlName":"SearchEdit"},"text":"bad"}'));
      try
        AssertFailure(lResponse, 'invalid_request');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","ref":123,"text":"bad"}'));
      try
        AssertFailure(lResponse, 'invalid_request');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":123,"controlName":"SearchEdit"},' +
        '"text":"bad"}'));
      try
        AssertFailure(lResponse, 'invalid_request');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm","controlName":123},' +
        '"text":"bad"}'));
      try
        AssertFailure(lResponse, 'invalid_request');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formHandle":"' +
        UIntToStr(NativeUInt(lForm.Handle)) + '","controlName":"SearchEdit"},"text":"bad"}'));
      try
        AssertFailure(lResponse, 'invalid_request');
        Assert.AreEqual(lEditText, lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formHandle":' + UIntToStr(NativeUInt(lButton.Handle)) +
        ',"controlName":"SearchEdit"},"text":"bad"}'));
      try
        AssertFailure(lResponse, 'form_not_found');
        Assert.AreEqual(lEditText, lEdit.Text);
      finally
        lResponse.Free;
      end;

      lEdit.Visible := False;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm","controlName":"SearchEdit"},' +
        '"text":"hidden"}'));
      try
        AssertFailure(lResponse, 'control_hidden');
        Assert.AreEqual(lEditText, lEdit.Text);
      finally
        lResponse.Free;
      end;
      lEdit.Visible := True;
      lEdit.Enabled := False;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm","controlName":"SearchEdit"},' +
        '"text":"disabled"}'));
      try
        AssertFailure(lResponse, 'control_disabled');
        Assert.AreEqual(lEditText, lEdit.Text);
      finally
        lResponse.Free;
      end;
      lEdit.Enabled := True;

      lForeignForm := TForm.Create(nil);
      lForeignForm.Name := 'ForeignBridgeForm';
      lForeignEdit := TEdit.Create(lForm);
      lForeignEdit.Name := 'CrossFormEdit';
      lForeignEdit.Parent := lForeignForm;
      lForeignText := lForeignEdit.Text;
      lForeignForm.Show;
      Application.ProcessMessages;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm","controlName":"CrossFormEdit"},' +
        '"text":"escaped"}'));
      try
        AssertFailure(lResponse, 'control_not_in_form');
        Assert.AreEqual(lForeignText, lForeignEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formHandle":' + lDeadHandle +
        ',"controlName":"SearchEdit"},"text":"dead"}'));
      try
        AssertFailure(lResponse, 'form_not_found');
      finally
        lResponse.Free;
      end;

      lDuplicateForm := TForm.Create(nil);
      lDuplicateForm.Name := 'BridgeForm';
      lDuplicateFormEdit := TEdit.Create(lDuplicateForm);
      lDuplicateFormEdit.Name := 'SearchEdit';
      lDuplicateFormEdit.Parent := lDuplicateForm;
      lDuplicateText := lDuplicateFormEdit.Text;
      lDuplicateForm.Show;
      Application.ProcessMessages;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm","controlName":"SearchEdit"},' +
        '"text":"ambiguous"}'));
      try
        AssertFailure(lResponse, 'ambiguous_form');
        Assert.AreEqual(lEditText, lEdit.Text);
        Assert.AreEqual(lDuplicateText, lDuplicateFormEdit.Text);
      finally
        lResponse.Free;
      end;
      lDuplicateForm.Free;
      lDuplicateForm := nil;

      lDuplicateOwner := TPanel.Create(lForm);
      lDuplicateOwner.Parent := lForm;
      lDuplicateFormEdit := TEdit.Create(lDuplicateOwner);
      lDuplicateFormEdit.Name := 'SearchEdit';
      lDuplicateFormEdit.Parent := lDuplicateOwner;
      lDuplicateText := lDuplicateFormEdit.Text;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formName":"BridgeForm","controlName":"SearchEdit"},' +
        '"text":"ambiguous"}'));
      try
        AssertFailure(lResponse, 'ambiguous_control');
        Assert.AreEqual(lEditText, lEdit.Text);
        Assert.AreEqual(lDuplicateText, lDuplicateFormEdit.Text);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lDuplicateForm.Free;
    lForm.Free;
    lForeignForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.WindowInfoReturnsGeometryAndDpi;
var
  lButton: TButton;
  lClientRect: TJSONObject;
  lClientScreenRect: TJSONObject;
  lEdit: TEdit;
  lForm: TForm;
  lPoint: TPoint;
  lResponse: TJSONObject;
  lWindow: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"window.info","target":"handle","handle":' + UIntToStr(NativeUInt(lForm.Handle)) + '}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('window.info', JsonText(lResponse, 'cmd'));
      Assert.AreEqual(2, JsonInt(lResponse, 'protocolVersion'));

      lWindow := JsonObjectValue(lResponse, 'window');
      Assert.AreEqual('BridgeForm', JsonText(lWindow, 'name'));
      Assert.AreEqual(UIntToStr(NativeUInt(lForm.Handle)), JsonText(lWindow, 'handle'));
      Assert.AreEqual(lForm.PixelsPerInch, JsonInt(lWindow, 'pixelsPerInch'));

      lClientRect := JsonObjectValue(lWindow, 'clientRect');
      Assert.AreEqual(0, JsonInt(lClientRect, 'left'));
      Assert.AreEqual(0, JsonInt(lClientRect, 'top'));
      Assert.AreEqual(lForm.ClientWidth, JsonInt(lClientRect, 'width'));
      Assert.AreEqual(lForm.ClientHeight, JsonInt(lClientRect, 'height'));

      lClientScreenRect := JsonObjectValue(lWindow, 'clientScreenRect');
      lPoint := lForm.ClientToScreen(Point(0, 0));
      Assert.AreEqual(lPoint.X, JsonInt(lClientScreenRect, 'left'));
      Assert.AreEqual(lPoint.Y, JsonInt(lClientScreenRect, 'top'));
      Assert.AreEqual(lForm.ClientWidth, JsonInt(lClientScreenRect, 'width'));
      Assert.AreEqual(lForm.ClientHeight, JsonInt(lClientScreenRect, 'height'));
    finally
      lResponse.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapReturnsSnapshotRefsAndTargetPoints;
var
  lButton: TButton;
  lCenter: TJSONObject;
  lEdit: TEdit;
  lEditEntry: TJSONObject;
  lForm: TForm;
  lMap: TJSONObject;
  lPoint: TPoint;
  lRoot: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm);
    try
      AssertOk(lMap);
      Assert.AreEqual('snapshot', JsonText(lMap, 'refModel'));
      Assert.IsTrue(JsonInt(lMap, 'snapshotId') > 0, 'Snapshot id should be positive.');
      Assert.IsTrue(JsonHasValue(lMap, 'elapsedMs'), 'form.map should report in-process elapsed milliseconds.');
      Assert.IsTrue(JsonHasValue(lMap, 'elapsedTicks'), 'form.map should report in-process elapsed ticks.');
      Assert.IsTrue(JsonInt(lMap, 'elapsedMs') >= 0, 'form.map elapsed milliseconds should be non-negative.');
      Assert.IsTrue(JsonInt(lMap, 'stopwatchFrequency') > 0, 'form.map should report the stopwatch frequency.');
      Assert.IsTrue(JsonInt(lMap, 'maxDepth') > 0, 'form.map should report a bounded default depth.');
      Assert.IsTrue(JsonInt(lMap, 'maxChildren') > 0, 'form.map should report a bounded default child count.');
      Assert.IsTrue(JsonInt(lMap, 'maxControls') > 0, 'form.map should report a bounded default control count.');

      lRoot := JsonObjectValue(lMap, 'form');
      Assert.AreEqual(Format('@s%da0', [JsonInt(lMap, 'snapshotId')]), JsonText(lRoot, 'ref'));
      Assert.AreEqual('BridgeForm', JsonText(lRoot, 'name'));
      Assert.AreEqual('TForm', JsonText(lRoot, 'className'));
      Assert.AreEqual('Bridge Test Window', JsonText(lRoot, 'caption'));

      lEditEntry := ControlByName(lMap, 'SearchEdit');
      Assert.AreEqual(Format('@s%da1', [JsonInt(lMap, 'snapshotId')]), JsonText(lEditEntry, 'ref'));
      Assert.AreEqual(Format('@s%da0', [JsonInt(lMap, 'snapshotId')]), JsonText(lEditEntry, 'parentRef'));
      Assert.AreEqual('TEdit', JsonText(lEditEntry, 'className'));
      Assert.AreEqual('Search text', JsonText(lEditEntry, 'hint'));
      Assert.AreEqual('true', JsonText(lEditEntry, 'visible'));
      Assert.AreEqual('true', JsonText(lEditEntry, 'enabled'));
      Assert.AreEqual('true', JsonText(lEditEntry, 'tabStop'));
      Assert.AreEqual(0, JsonInt(lEditEntry, 'tabOrder'));

      lCenter := JsonObjectValue(JsonObjectValue(lEditEntry, 'targetPoints'), 'center');
      lPoint := lForm.ClientToScreen(Point(lEdit.Left + (lEdit.Width div 2), lEdit.Top + (lEdit.Height div 2)));
      Assert.AreEqual(lPoint.X, JsonInt(lCenter, 'x'));
      Assert.AreEqual(lPoint.Y, JsonInt(lCenter, 'y'));

      Assert.AreEqual(Format('@s%da2', [JsonInt(lMap, 'snapshotId')]), ControlRefByName(lMap, 'ApplyButton'));
    finally
      lMap.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapAppliesConfiguredDepthAndChildBounds;
var
  lChildEdit: TEdit;
  lControls: TJSONArray;
  lForm: TForm;
  lPanel: TPanel;
  lResponse: TJSONObject;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'BoundedBridgeForm';
    lPanel := TPanel.Create(lForm);
    lPanel.Name := 'FirstPanel';
    lPanel.Parent := lForm;
    lChildEdit := TEdit.Create(lForm);
    lChildEdit.Name := 'NestedEdit';
    lChildEdit.Parent := lPanel;
    lPanel := TPanel.Create(lForm);
    lPanel.Name := 'SecondPanel';
    lPanel.Parent := lForm;
    lForm.HandleNeeded;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"form.map","target":"handle","handle":' + UIntToStr(NativeUInt(lForm.Handle)) +
      ',"includeAccessibility":false,"detail":"geometry","maxDepth":1,"maxChildren":1}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual(1, JsonInt(lResponse, 'maxDepth'));
      Assert.AreEqual(1, JsonInt(lResponse, 'maxChildren'));
      Assert.AreEqual('true', JsonText(lResponse, 'depthTruncated'));
      Assert.AreEqual('true', JsonText(lResponse, 'childrenTruncated'));
      lControls := JsonArrayValue(lResponse, 'controls');
      Assert.AreEqual(1, lControls.Count);
      Assert.AreEqual('FirstPanel', JsonText(TJSONObject(lControls.Items[0]), 'name'));
    finally
      lResponse.Free;
    end;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"form.map","target":"handle","handle":' + UIntToStr(NativeUInt(lForm.Handle)) +
      ',"includeAccessibility":false,"detail":"geometry","maxDepth":2,"maxChildren":2,"maxControls":1}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual(1, JsonInt(lResponse, 'maxControls'));
      Assert.AreEqual('true', JsonText(lResponse, 'controlsTruncated'));
      Assert.AreEqual(1, JsonArrayValue(lResponse, 'controls').Count);
    finally
      lResponse.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapReferenceGenerationAvoidsFormatParser;
var
  lSourceText: string;
begin
  lSourceText := ReadRepoText('src\MaxLogic.Accessibility.AgentBridge.pas');

  Assert.IsFalse(Pos('Format(''@a%d''', lSourceText) > 0,
    'Agent bridge refs are generated for every mapped control; avoid Format parser and variant allocation here.');
  Assert.Contains(lSourceText, 'SnapshotId: UInt64;', 'Snapshot generations must not wrap at signed 32-bit range.');
  Assert.Contains(lSourceText, 'fSnapshotId: UInt64;', 'Bridge generation state must use the same 64-bit type.');
  Assert.Contains(lSourceText, 'UIntToStr(fSnapshotId)', 'Generation-qualified refs must serialize UInt64 safely.');
end;

procedure TAccessibilityAgentBridgeTests.ProviderMapQueriesDirectAccessOncePerNode;
var
  lChild: IRawElementProviderSimple;
  lChildJson: TJSONObject;
  lChildMetrics: TAgentBridgeProviderQueryMetrics;
  lChildren: TJSONArray;
  lGeometryJson: TJSONObject;
  lGeometryMetrics: TAgentBridgeProviderQueryMetrics;
  lGeometryProvider: IRawElementProviderSimple;
  lRoot: IRawElementProviderSimple;
  lRootJson: TJSONObject;
  lRootMetrics: TAgentBridgeProviderQueryMetrics;
begin
  lChildMetrics := Default(TAgentBridgeProviderQueryMetrics);
  lRootMetrics := Default(TAgentBridgeProviderQueryMetrics);
  lChild := CreateCountingProvider(lChildMetrics, E_FAIL, 0, nil);
  lRoot := CreateCountingProvider(lRootMetrics, S_OK, 1, lChild);

  lRootJson := JsonObjectFrom(TAccessibilityAgentBridgeInternals.SerializeProviderNode(lRoot, True, 2, 10));
  try
    Assert.AreEqual(1, lRootMetrics.DirectAccessQueries, 'Root direct access should be queried once.');
    Assert.AreEqual(1, lRootMetrics.GeometryAccessQueries, 'Root geometry access should be queried once.');
    Assert.AreEqual(1, lRootMetrics.VclInfoQueries, 'Root VCL info should be queried once in full detail.');
    Assert.AreEqual(1, lRootMetrics.ChildAccessQueries, 'Root child access should be queried once.');

    lChildren := JsonArrayValue(lRootJson, 'children');
    Assert.AreEqual(1, lChildren.Count);
    Assert.IsTrue(lChildren.Items[0] is TJSONObject);
    lChildJson := TJSONObject(lChildren.Items[0]);
    Assert.AreEqual('Counting provider', JsonText(lChildJson, 'name'));
    Assert.AreEqual(1, lChildMetrics.DirectAccessQueries, 'Child direct access should be queried once.');
    Assert.AreEqual(1, lChildMetrics.GeometryAccessQueries, 'Child geometry access should be queried once.');
    Assert.AreEqual(1, lChildMetrics.VclInfoQueries, 'Child VCL info should be queried once in full detail.');
    Assert.AreEqual(1, lChildMetrics.ChildAccessQueries, 'Child child-access support should be queried once.');
  finally
    lRootJson.Free;
  end;

  lGeometryMetrics := Default(TAgentBridgeProviderQueryMetrics);
  lGeometryProvider := CreateCountingProvider(lGeometryMetrics, S_OK, 0, nil);
  lGeometryJson := JsonObjectFrom(
    TAccessibilityAgentBridgeInternals.SerializeProviderNode(lGeometryProvider, False, 0, 10));
  try
    Assert.AreEqual(1, lGeometryMetrics.DirectAccessQueries,
      'Geometry detail should still query direct control-type access once.');
    Assert.AreEqual(1, lGeometryMetrics.GeometryAccessQueries,
      'Geometry detail should query geometry access once.');
    Assert.AreEqual(0, lGeometryMetrics.VclInfoQueries,
      'Geometry detail should not query VCL text metadata.');
    Assert.AreEqual(0, lGeometryMetrics.ChildAccessQueries,
      'A depth-truncated geometry node should not query child access.');
  finally
    lGeometryJson.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ProviderMapWritesChildMetadataOnce;
var
  lChild: IRawElementProviderSimple;
  lChildMetrics: TAgentBridgeProviderQueryMetrics;
  lChildren: TJSONArray;
  lDepthJson: TJSONObject;
  lDepthMetrics: TAgentBridgeProviderQueryMetrics;
  lDepthProvider: IRawElementProviderSimple;
  lFailureJson: TJSONObject;
  lFailureMetrics: TAgentBridgeProviderQueryMetrics;
  lFailureProvider: IRawElementProviderSimple;
  lTruncatedJson: TJSONObject;
  lTruncatedMetrics: TAgentBridgeProviderQueryMetrics;
  lTruncatedProvider: IRawElementProviderSimple;
begin
  lFailureMetrics := Default(TAgentBridgeProviderQueryMetrics);
  lFailureProvider := CreateCountingProvider(lFailureMetrics, E_FAIL, 73, nil);
  lFailureJson := JsonObjectFrom(
    TAccessibilityAgentBridgeInternals.SerializeProviderNode(lFailureProvider, False, 2, 10));
  try
    Assert.AreEqual(1, JsonPairCount(lFailureJson, 'childCount'));
    Assert.AreEqual(1, JsonPairCount(lFailureJson, 'childrenTruncated'));
    Assert.AreEqual(0, JsonInt(lFailureJson, 'childCount'),
      'A failed child-count query must not publish an undefined out value.');
    Assert.AreEqual('false', JsonText(lFailureJson, 'childrenTruncated'));
  finally
    lFailureJson.Free;
  end;

  lDepthMetrics := Default(TAgentBridgeProviderQueryMetrics);
  lDepthProvider := CreateCountingProvider(lDepthMetrics, S_OK, 4, nil);
  lDepthJson := JsonObjectFrom(TAccessibilityAgentBridgeInternals.SerializeProviderNode(lDepthProvider, False, 0, 10));
  try
    Assert.AreEqual(1, JsonPairCount(lDepthJson, 'childCount'));
    Assert.AreEqual(1, JsonPairCount(lDepthJson, 'childrenTruncated'));
    Assert.AreEqual(0, JsonInt(lDepthJson, 'childCount'));
    Assert.AreEqual('false', JsonText(lDepthJson, 'childrenTruncated'));
    Assert.AreEqual('true', JsonText(lDepthJson, 'depthTruncated'));
    Assert.AreEqual(0, lDepthMetrics.ChildAccessQueries,
      'Depth-truncated nodes should not query child access.');
  finally
    lDepthJson.Free;
  end;

  lChildMetrics := Default(TAgentBridgeProviderQueryMetrics);
  lTruncatedMetrics := Default(TAgentBridgeProviderQueryMetrics);
  lChild := CreateCountingProvider(lChildMetrics, E_FAIL, 0, nil);
  lTruncatedProvider := CreateCountingProvider(lTruncatedMetrics, S_OK, 2, lChild);
  lTruncatedJson := JsonObjectFrom(
    TAccessibilityAgentBridgeInternals.SerializeProviderNode(lTruncatedProvider, False, 2, 1));
  try
    Assert.AreEqual(1, JsonPairCount(lTruncatedJson, 'childCount'));
    Assert.AreEqual(1, JsonPairCount(lTruncatedJson, 'childrenTruncated'));
    Assert.AreEqual(2, JsonInt(lTruncatedJson, 'childCount'));
    Assert.AreEqual('true', JsonText(lTruncatedJson, 'childrenTruncated'));
    lChildren := JsonArrayValue(lTruncatedJson, 'children');
    Assert.AreEqual(1, lChildren.Count, 'The configured child cap should limit serialized children.');
  finally
    lTruncatedJson.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapReturnsNativeAccessibilityRoleAndState;
var
  lCheckBox: TCheckBox;
  lCheckBoxEntry: TJSONObject;
  lCheckBoxState: TJSONObject;
  lForm: TForm;
  lListBox: TListBox;
  lListBoxEntry: TJSONObject;
  lListBoxState: TJSONObject;
  lMap: TJSONObject;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'NativeStateForm';
    lForm.Caption := 'Native State Test';
    lForm.SetBounds(200, 150, 420, 240);

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Name := 'ArchivedCheckBox';
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Checked := True;
    lCheckBox.SetBounds(20, 20, 180, 24);
    lCheckBox.Parent := lForm;

    lListBox := TListBox.Create(lForm);
    lListBox.Name := 'EventsListBox';
    lListBox.Parent := lForm;
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.ItemIndex := 1;
    lListBox.SetBounds(20, 60, 220, 90);

    lForm.HandleNeeded;
    lCheckBox.HandleNeeded;
    lListBox.HandleNeeded;

    lMap := MapForm(lForm);
    try
      lCheckBoxEntry := ControlByName(lMap, 'ArchivedCheckBox');
      Assert.AreEqual(UIA_CheckBoxControlTypeId, JsonInt(lCheckBoxEntry, 'uiaControlTypeId'));
      Assert.AreEqual('CheckBox', JsonText(lCheckBoxEntry, 'uiaControlType'));
      lCheckBoxState := JsonObjectValue(lCheckBoxEntry, 'state');
      Assert.AreEqual('true', JsonText(lCheckBoxState, 'checked'));
      Assert.AreEqual('on', JsonText(lCheckBoxState, 'toggleState'));

      lListBoxEntry := ControlByName(lMap, 'EventsListBox');
      Assert.AreEqual(UIA_ListControlTypeId, JsonInt(lListBoxEntry, 'uiaControlTypeId'));
      Assert.AreEqual('List', JsonText(lListBoxEntry, 'uiaControlType'));
      lListBoxState := JsonObjectValue(lListBoxEntry, 'state');
      Assert.AreEqual(2, JsonInt(lListBoxState, 'itemCount'));
      Assert.AreEqual(1, JsonInt(lListBoxState, 'itemIndex'));
      Assert.AreEqual('Audit warning', JsonText(lListBoxState, 'selectedText'));
    finally
      lMap.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ProviderMapReturnsInProcessProviderTreeWithVirtualChildren;
var
  lForm: TForm;
  lItemNode: TJSONObject;
  lListBox: TListBox;
  lListBoxNode: TJSONObject;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'ProviderTreeForm';
    lForm.Caption := 'Provider Tree Test';
    lForm.SetBounds(200, 150, 420, 260);

    lListBox := TListBox.Create(lForm);
    lListBox.Name := 'OrdersListBox';
    lListBox.Parent := lForm;
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.ItemIndex := 1;
    lListBox.SetBounds(20, 20, 220, 96);

    lForm.HandleNeeded;
    lListBox.HandleNeeded;

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lMap := ProviderMapForm(lForm, 'full', 3, 20);
      try
        AssertOk(lMap);
        Assert.AreEqual('provider.map', JsonText(lMap, 'cmd'));
        Assert.AreEqual('maxlogic-provider', JsonText(lMap, 'source'));
        Assert.AreEqual('full', JsonText(lMap, 'detail'));
        Assert.IsTrue(JsonInt(lMap, 'nodeCount') >= 4, 'Provider map should include virtual listbox items.');

        lListBoxNode := RequireProviderNodeByVclName(lMap, 'OrdersListBox');
        Assert.AreEqual(UIA_ListControlTypeId, JsonInt(lListBoxNode, 'uiaControlTypeId'));
        Assert.AreEqual('List', JsonText(lListBoxNode, 'uiaControlType'));
        Assert.AreEqual(2, JsonInt(lListBoxNode, 'childCount'));

        lItemNode := RequireProviderNodeByName(lMap, 'Audit warning');
        Assert.AreEqual(UIA_ListItemControlTypeId, JsonInt(lItemNode, 'uiaControlTypeId'));
      finally
        lMap.Free;
      end;

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
        'provider.map should use in-process direct child access, not TreeWalker-style Navigate traversal.');
      Assert.AreEqual(0, lMetrics.ProviderGetBoundingRectangleCount,
        'provider.map should use provider direct geometry access, not UIA bounding rectangle callbacks.');
      Assert.AreEqual(0, lMetrics.ProviderGetPropertyValueCount,
        'provider.map should not fall back to public UIA property callbacks after direct-access providers answer.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ProviderMapReusesInstalledManagerProviderWithoutRescanningForm;
var
  lButton: TButton;
  lForm: TForm;
  lMap: TJSONObject;
  lMetrics: TAccessibilityScannerMetrics;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'InstalledProviderMapForm';
    lForm.Caption := 'Installed Provider Map Test';
    lForm.SetBounds(200, 150, 420, 260);

    lButton := TButton.Create(lForm);
    lButton.Name := 'ApplyButton';
    lButton.Caption := 'Apply';
    lButton.Parent := lForm;
    lButton.SetBounds(20, 20, 120, 28);

    lForm.HandleNeeded;
    lButton.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    TAccessibilityDiagnostics.EnableScannerMetrics;
    TAccessibilityDiagnostics.ResetScannerMetrics;
    try
      lMap := ProviderMapForm(lForm, 'geometry', 2, 20);
      try
        AssertOk(lMap);
        Assert.AreEqual('installed', JsonText(lMap, 'providerTreeSource'));
        Assert.IsTrue(JsonInt(lMap, 'nodeCount') >= 2, 'Provider map should still return the installed tree.');
      finally
        lMap.Free;
      end;

      lMetrics := TAccessibilityDiagnostics.ScannerMetrics;
      Assert.AreEqual(0, lMetrics.SortedChildrenCallCount,
        'provider.map should reuse the installed manager provider instead of scanning the form again.');
      Assert.AreEqual(0, lMetrics.RttiPropertyLookupCount,
        'provider.map should not do scanner RTTI reads when the installed provider is reused.');
    finally
      TAccessibilityDiagnostics.DisableScannerMetrics;
      TAccessibilityManager.Uninstall;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapCanSkipAccessibilityScanForFastNativeSnapshot;
var
  lButton: TButton;
  lEdit: TEdit;
  lEditEntry: TJSONObject;
  lForm: TForm;
  lMap: TJSONObject;
  lRoot: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm, False);
    try
      AssertOk(lMap);
      Assert.AreEqual('false', JsonText(lMap, 'includeAccessibility'));

      lRoot := JsonObjectValue(lMap, 'form');
      Assert.AreEqual('BridgeForm', JsonText(lRoot, 'name'));
      Assert.AreEqual('Bridge Test Window', JsonText(lRoot, 'caption'));
      Assert.AreEqual('', JsonText(lRoot, 'accessibleName'));
      Assert.AreEqual('', JsonText(lRoot, 'helpText'));

      lEditEntry := ControlByName(lMap, 'SearchEdit');
      Assert.AreEqual(Format('@s%da1', [JsonInt(lMap, 'snapshotId')]), JsonText(lEditEntry, 'ref'));
      Assert.AreEqual('TEdit', JsonText(lEditEntry, 'className'));
      Assert.AreEqual('Search text', JsonText(lEditEntry, 'hint'));
      Assert.AreEqual('', JsonText(lEditEntry, 'accessibleName'));
      Assert.AreEqual('', JsonText(lEditEntry, 'helpText'));
    finally
      lMap.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapCanReturnOnlyVisibleActivePageControls;
var
  lActiveEdit: TEdit;
  lActivePage: TTabSheet;
  lButton: TButton;
  lControls: TJSONArray;
  lHiddenEdit: TEdit;
  lHiddenPage: TTabSheet;
  lForm: TForm;
  lMap: TJSONObject;
  lPageControl: TPageControl;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'VisibleMapForm';
    lForm.Caption := 'Visible Map Test';
    lForm.SetBounds(200, 150, 420, 260);

    lButton := TButton.Create(lForm);
    lButton.Name := 'TopButton';
    lButton.Caption := 'Top action';
    lButton.SetBounds(16, 16, 96, 28);
    lButton.Parent := lForm;

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Name := 'Pages';
    lPageControl.SetBounds(16, 56, 360, 160);
    lPageControl.Parent := lForm;

    lActivePage := TTabSheet.Create(lForm);
    lActivePage.Name := 'ActivePage';
    lActivePage.Caption := 'Active';
    lActivePage.PageControl := lPageControl;

    lHiddenPage := TTabSheet.Create(lForm);
    lHiddenPage.Name := 'HiddenPage';
    lHiddenPage.Caption := 'Hidden';
    lHiddenPage.PageControl := lPageControl;

    lActiveEdit := TEdit.Create(lForm);
    lActiveEdit.Name := 'ActiveEdit';
    lActiveEdit.Text := 'Visible value';
    lActiveEdit.SetBounds(20, 24, 160, 24);
    lActiveEdit.Parent := lActivePage;

    lHiddenEdit := TEdit.Create(lForm);
    lHiddenEdit.Name := 'HiddenEdit';
    lHiddenEdit.Text := 'Inactive value';
    lHiddenEdit.SetBounds(20, 24, 160, 24);
    lHiddenEdit.Parent := lHiddenPage;

    lPageControl.ActivePage := lActivePage;
    lForm.HandleNeeded;
    lButton.HandleNeeded;
    lPageControl.HandleNeeded;
    lActiveEdit.HandleNeeded;
    lHiddenEdit.HandleNeeded;

    lMap := MapForm(lForm, False, True);
    try
      AssertOk(lMap);
      Assert.AreEqual('false', JsonText(lMap, 'includeAccessibility'));
      Assert.AreEqual('true', JsonText(lMap, 'visibleOnly'));
      lControls := JsonArrayValue(lMap, 'controls');
      Assert.IsTrue(lControls.Count < 5, 'Visible map should skip inactive page descendants.');
      ControlByName(lMap, 'TopButton');
      ControlByName(lMap, 'Pages');
      ControlByName(lMap, 'ActivePage');
      ControlByName(lMap, 'ActiveEdit');
      Assert.IsFalse(ControlExistsByName(lMap, 'HiddenEdit'));
    finally
      lMap.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapGeometryDetailSkipsTextAccessibilityAndState;
var
  lButton: TButton;
  lButtonEntry: TJSONObject;
  lEdit: TEdit;
  lForm: TForm;
  lMap: TJSONObject;
  lRoot: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lButton.Hint := 'Runs the action';
    lMap := MapForm(lForm, True, True, 'geometry');
    try
      AssertOk(lMap);
      Assert.AreEqual('geometry', JsonText(lMap, 'detail'));
      Assert.AreEqual('false', JsonText(lMap, 'includeAccessibility'));
      Assert.AreEqual('true', JsonText(lMap, 'visibleOnly'));

      lRoot := JsonObjectValue(lMap, 'form');
      Assert.AreEqual('BridgeForm', JsonText(lRoot, 'name'));
      Assert.AreEqual('Window', JsonText(lRoot, 'uiaControlType'));
      Assert.IsTrue(JsonHasValue(lRoot, 'screenRect'));
      Assert.IsFalse(JsonHasValue(lRoot, 'caption'), 'Geometry detail should skip Caption RTTI.');
      Assert.IsFalse(JsonHasValue(lRoot, 'accessibleName'), 'Geometry detail should skip accessibility scanning.');
      Assert.IsFalse(JsonHasValue(lRoot, 'state'), 'Geometry detail should skip role-specific native state.');

      lButtonEntry := ControlByName(lMap, 'ApplyButton');
      Assert.AreEqual('Button', JsonText(lButtonEntry, 'uiaControlType'));
      Assert.AreEqual(UIntToStr(NativeUInt(lButton.Handle)), JsonText(lButtonEntry, 'handle'));
      Assert.IsTrue(JsonHasValue(lButtonEntry, 'targetPoints'));
      Assert.IsFalse(JsonHasValue(lButtonEntry, 'caption'), 'Geometry detail should not read captions.');
      Assert.IsFalse(JsonHasValue(lButtonEntry, 'value'), 'Geometry detail should not read values.');
      Assert.IsFalse(JsonHasValue(lButtonEntry, 'hint'), 'Geometry detail should not read hints.');
      Assert.IsFalse(JsonHasValue(lButtonEntry, 'helpText'), 'Geometry detail should not read help text.');
      Assert.IsFalse(JsonHasValue(lButtonEntry, 'state'), 'Geometry detail should not read role state.');
    finally
      lMap.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapGeometryVisibleOnlyScalesOnDeepNestedControls;
const
  cSmallDepth = 120;
  cLargeDepth = 600;
  cMaxTickGrowth = 7;
  cSampleCount = 3;
var
  lLargeTicks: Int64;
  lSmallTicks: Int64;
begin
  lSmallTicks := MeasureBestGeometryMapTicks(cSmallDepth, cSampleCount);
  lLargeTicks := MeasureBestGeometryMapTicks(cLargeDepth, cSampleCount);

  Assert.IsTrue(lLargeTicks < lSmallTicks * cMaxTickGrowth,
    Format('Visible geometry map should scale close to control count. small=%d large=%d', [lSmallTicks, lLargeTicks]));
end;

procedure TAccessibilityAgentBridgeTests.FormMapGeometrySkipsClientOriginForLeafWindowedControls;
const
  cControlCount = 700;
var
  lForm: TForm;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    lForm := BuildFlatGeometryMapForm(cControlCount, True);
    try
      lMap := MapForm(lForm, False, True, 'geometry');
      try
        AssertOk(lMap);
      finally
        lMap.Free;
      end;

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(1, lMetrics.AgentBridgeChildClientOriginProbeCount,
        'Leaf windowed controls should not compute child client origins beyond the form root.');
    finally
      lForm.Free;
    end;

  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapGeometryReadsFocusedHandleOnceForFlatWindowedControls;
const
  cControlCount = 700;
var
  lForm: TForm;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    lForm := BuildFlatGeometryMapForm(cControlCount, True);
    try
      lMap := MapForm(lForm, False, True, 'geometry');
      try
        AssertOk(lMap);
      finally
        lMap.Free;
      end;

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(1, lMetrics.AgentBridgeFocusProbeCount,
        'Flat windowed geometry maps should read the focused HWND once, not once per control.');
    finally
      lForm.Free;
    end;

  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapFullCachesRepeatedRttiPropertyLookups;
const
  cControlCount = 150;
  cMaxRttiLookups = 6;
var
  lForm: TForm;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    lForm := BuildFallbackTextMapForm(cControlCount);
    try
      lMap := MapForm(lForm, False, False);
      try
        AssertOk(lMap);
      finally
        lMap.Free;
      end;

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.IsTrue(lMetrics.AgentBridgeRttiPropertyLookupCount <= cMaxRttiLookups,
        Format('Full bridge map should cache RTTI property lookups by class/property; got %d lookups for %d controls.',
        [lMetrics.AgentBridgeRttiPropertyLookupCount, cControlCount]));
    finally
      lForm.Free;
    end;
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapFullAvoidsRttiForStandardVclStringProperties;
var
  lForm: TForm;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    lForm := BuildStandardNativeStringMapForm;
    try
      lMap := MapForm(lForm, False, True);
      try
        AssertOk(lMap);
      finally
        lMap.Free;
      end;

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.AgentBridgeRttiPropertyLookupCount,
        'Standard VCL bridge maps should use typed VCL access or known-empty string fast paths, not RTTI misses.');
    finally
      lForm.Free;
    end;
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapDoesNotAllocateHiddenControlHandles;
var
  lActivePage: TTabSheet;
  lForm: TForm;
  lHiddenEdit: TEdit;
  lHiddenEditEntry: TJSONObject;
  lHiddenPage: TTabSheet;
  lMap: TJSONObject;
  lPageControl: TPageControl;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'HandleLazyMapForm';
    lForm.SetBounds(220, 180, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Name := 'Pages';
    lPageControl.SetBounds(16, 16, 360, 180);
    lPageControl.Parent := lForm;

    lActivePage := TTabSheet.Create(lForm);
    lActivePage.Name := 'ActivePage';
    lActivePage.Caption := 'Active';
    lActivePage.PageControl := lPageControl;

    lHiddenPage := TTabSheet.Create(lForm);
    lHiddenPage.Name := 'HiddenPage';
    lHiddenPage.Caption := 'Hidden';
    lHiddenPage.PageControl := lPageControl;

    lHiddenEdit := TEdit.Create(lForm);
    lHiddenEdit.Name := 'HiddenEdit';
    lHiddenEdit.Text := 'Inactive value';
    lHiddenEdit.SetBounds(20, 24, 160, 24);
    lHiddenEdit.Parent := lHiddenPage;

    lPageControl.ActivePage := lActivePage;
    lForm.HandleNeeded;
    Assert.IsFalse(lHiddenEdit.HandleAllocated, 'Test setup should keep the inactive edit handle lazy.');

    lMap := MapForm(lForm, False, False, 'geometry');
    try
      AssertOk(lMap);
      lHiddenEditEntry := ControlByName(lMap, 'HiddenEdit');
      Assert.AreEqual('0', JsonText(lHiddenEditEntry, 'handle'));
      Assert.IsFalse(lHiddenEdit.HandleAllocated, 'form.map should not allocate HWNDs for hidden controls.');
    finally
      lMap.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ControlInfoEnrichesOneSnapshotRefWithoutFullMapScan;
var
  lButton: TButton;
  lButtonRef: string;
  lControl: TJSONObject;
  lEdit: TEdit;
  lForm: TForm;
  lMap: TJSONObject;
  lResponse: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm, False, True, 'geometry');
    try
      lButtonRef := ControlRefByName(lMap, 'ApplyButton');
      Assert.IsFalse(JsonHasValue(ControlByName(lMap, 'ApplyButton'), 'caption'),
        'Geometry map should not read caption text for every control.');
    finally
      lMap.Free;
    end;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lButtonRef + '"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('control.info', JsonText(lResponse, 'cmd'));
      Assert.AreEqual('full', JsonText(lResponse, 'detail'));
      Assert.AreEqual('false', JsonText(lResponse, 'includeAccessibility'));

      lControl := JsonObjectValue(lResponse, 'control');
      Assert.AreEqual(lButtonRef, JsonText(lControl, 'ref'));
      Assert.AreEqual('ApplyButton', JsonText(lControl, 'name'));
      Assert.AreEqual('Apply', JsonText(lControl, 'caption'));
      Assert.AreEqual('', JsonText(lControl, 'accessibleName'));
      Assert.AreEqual('', JsonText(lControl, 'helpText'));
    finally
      lResponse.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ControlResolveReportsMdiChildHostContext;
var
  lButton: TButton;
  lChild: TForm;
  lControl: TJSONObject;
  lHost: TForm;
  lResponse: TJSONObject;
begin
  lHost := nil;
  Application.CreateForm(TForm, lHost);
  lHost.Name := 'MdiHostForm';
  lHost.FormStyle := fsMDIForm;
  lHost.Show;
  lChild := TForm.Create(Application);
  try
    lChild.Name := 'MdiChildForm';
    lChild.FormStyle := fsMDIChild;
    lButton := TButton.Create(lChild);
    lButton.Name := 'MdiApplyButton';
    lButton.Parent := lChild;
    lChild.Show;
    Application.ProcessMessages;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.resolve","target":{"formName":"MdiChildForm","controlName":"MdiApplyButton"},' +
      '"detail":"target"}'));
    try
      AssertOk(lResponse);
      lControl := JsonObjectValue(lResponse, 'control');
      Assert.AreEqual('true', JsonText(lControl, 'mdiChild'));
      Assert.AreEqual(UIntToStr(NativeUInt(lChild.Handle)), JsonText(lControl, 'formHandle'));
      Assert.AreEqual(UIntToStr(NativeUInt(lHost.Handle)), JsonText(lControl, 'rootHandle'));
    finally
      lResponse.Free;
    end;
  finally
    lChild.Free;
    lHost.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ControlResolveFindsNamedControlWithoutFullFormMap;
var
  lButton: TButton;
  lControl: TJSONObject;
  lEdit: TEdit;
  lForm: TForm;
  lRef: string;
  lResponse: TJSONObject;
  lSnapshotId: Integer;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  lForm.Show;
  Application.ProcessMessages;
  try
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.resolve","target":{"formName":"BridgeForm","controlName":"ApplyButton"},' +
      '"detail":"target"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('control.resolve', JsonText(lResponse, 'cmd'));
      Assert.AreEqual('snapshot', JsonText(lResponse, 'refModel'));
      Assert.AreEqual('true', JsonText(lResponse, 'snapshotReplaced'));
      Assert.IsFalse(JsonHasValue(lResponse, 'controls'), 'A narrow resolve must not serialize a full form map.');
      lSnapshotId := JsonInt(lResponse, 'snapshotId');
      Assert.IsTrue(lSnapshotId > 0);

      lControl := JsonObjectValue(lResponse, 'control');
      lRef := JsonText(lControl, 'ref');
      Assert.AreEqual(Format('@s%da0', [lSnapshotId]), lRef);
      Assert.AreEqual('ApplyButton', JsonText(lControl, 'name'));
      Assert.AreEqual('TButton', JsonText(lControl, 'className'));
      Assert.AreEqual('BridgeForm', JsonText(lControl, 'formName'));
      Assert.AreEqual(UIntToStr(NativeUInt(lForm.Handle)), JsonText(lControl, 'formHandle'));
      Assert.AreEqual(UIntToStr(NativeUInt(GetAncestor(lForm.Handle, GA_ROOT))), JsonText(lControl, 'rootHandle'));
      Assert.AreEqual(lForm.PixelsPerInch, JsonInt(lControl, 'pixelsPerInch'));
      Assert.AreEqual('screen-physical-pixels', JsonText(lControl, 'coordinateSpace'));
      Assert.AreEqual('true', JsonText(lControl, 'valid'));
      Assert.IsTrue(JsonHasValue(lControl, 'canFocus'));
      Assert.IsTrue(JsonHasValue(lControl, 'activeForm'));
      Assert.IsTrue(JsonHasValue(lControl, 'screenRect'));
      Assert.IsTrue(JsonHasValue(lControl, 'targetPoints'));
      Assert.IsFalse(JsonHasValue(lControl, 'caption'), 'Target detail must not read full control state.');
    finally
      lResponse.Free;
    end;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.resolve","ref":"' + lRef + '","detail":"target"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('false', JsonText(lResponse, 'snapshotReplaced'));
      Assert.AreEqual(lSnapshotId, JsonInt(lResponse, 'snapshotId'));
      Assert.AreEqual(lRef, JsonText(JsonObjectValue(lResponse, 'control'), 'ref'));
    finally
      lResponse.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FocusRejectsDisabledAncestorBeforeMutation;
var
  lEdit: TEdit;
  lForm: TForm;
  lPanel: TPanel;
  lPriorActiveControl: TWinControl;
  lResponse: TJSONObject;
begin
  lForm := TForm.Create(nil);
  lForm.Name := 'FocusContextForm';
  lForm.SetBounds(200, 150, 360, 200);
  lPanel := TPanel.Create(lForm);
  lPanel.Name := 'DisabledParent';
  lPanel.SetBounds(8, 8, 240, 80);
  lPanel.Parent := lForm;
  lEdit := TEdit.Create(lForm);
  lEdit.Name := 'BlockedEdit';
  lEdit.SetBounds(8, 8, 140, 24);
  lEdit.Parent := lPanel;
  lForm.Show;
  Application.ProcessMessages;
  lPanel.Enabled := False;
  lPriorActiveControl := lForm.ActiveControl;
  try
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.focus","target":{"formName":"FocusContextForm","controlName":"BlockedEdit"}}'));
      try
        AssertFailure(lResponse, 'control_disabled');
        Assert.IsTrue(lForm.ActiveControl = lPriorActiveControl);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FocusFailureReportsEffectiveVclContext;
var
  lAncestors: TJSONArray;
  lButton: TButton;
  lControl: TJSONObject;
  lEdit: TAgentBridgeFailingFocusEdit;
  lFailureRef: string;
  lForm: TForm;
  lRef: string;
  lResponse: TJSONObject;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'FocusFailureForm';
    lForm.SetBounds(200, 150, 360, 200);
    lButton := TButton.Create(lForm);
    lButton.Name := 'SafeFocusButton';
    lButton.Parent := lForm;
    lButton.TabOrder := 0;
    lEdit := TAgentBridgeFailingFocusEdit.Create(lForm);
    lEdit.Name := 'FailingFocusEdit';
    lEdit.Parent := lForm;
    lEdit.TabOrder := 1;
    lForm.Show;
    lForm.ActiveControl := lButton;
    Application.ProcessMessages;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.resolve","target":{"formName":"FocusFailureForm",' +
      '"controlName":"FailingFocusEdit"},"detail":"target"}'));
    try
      AssertOk(lResponse);
      lRef := JsonText(JsonObjectValue(lResponse, 'control'), 'ref');
    finally
      lResponse.Free;
    end;

    lEdit.FailFocus := True;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.focus","ref":"' + lRef + '"}'));
      try
        AssertFailure(lResponse, 'focus_failed');
        Assert.IsTrue(Pos('Expected bridge focus failure', JsonText(lResponse, 'message')) > 0);
        Assert.IsTrue(Pos('guarded OS click', JsonText(lResponse, 'recommendedFallback')) > 0);
        lControl := JsonObjectValue(lResponse, 'control');
        lFailureRef := JsonText(lControl, 'ref');
        Assert.IsTrue(lFailureRef <> lRef, 'Failure diagnostics must not resurrect the invalidated ref.');
        Assert.AreEqual('FailingFocusEdit', JsonText(lControl, 'name'));
        Assert.AreEqual('true', JsonText(lControl, 'visible'));
        Assert.AreEqual('true', JsonText(lControl, 'enabled'));
        Assert.AreEqual('true', JsonText(lControl, 'canFocus'));
        Assert.AreEqual(UIntToStr(NativeUInt(lEdit.Handle)), JsonText(lControl, 'handle'));
        Assert.AreEqual(UIntToStr(NativeUInt(GetAncestor(lForm.Handle, GA_ROOT))), JsonText(lControl, 'rootHandle'));
        lAncestors := JsonArrayValue(lResponse, 'ancestors');
        Assert.IsTrue(lAncestors.Count >= 1);
        Assert.AreEqual('FocusFailureForm', JsonText(TJSONObject(lAncestors.Items[0]), 'name'));
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.info","ref":"' + lRef + '"}'));
      try
        AssertFailure(lResponse, 'stale_ref');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.info","ref":"' + lFailureRef + '"}'));
      try
        AssertOk(lResponse);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
      lEdit.FailFocus := False;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ControlInfoReusesSnapshotRectangleForMappedControl;
var
  lButton: TButton;
  lButtonRef: string;
  lEdit: TEdit;
  lForm: TForm;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lResponse: TJSONObject;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm, False, True, 'geometry');
    try
      AssertOk(lMap);
      lButtonRef := ControlRefByName(lMap, 'ApplyButton');
    finally
      lMap.Free;
    end;

    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.info","ref":"' + lButtonRef + '"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('ApplyButton', JsonText(JsonObjectValue(lResponse, 'control'), 'name'));
    finally
      lResponse.Free;
    end;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lMetrics.AgentBridgeScreenRectProbeCount,
      'control.info should reuse screen rectangles from the current form.map snapshot.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.ControlsInfoBatchesSnapshotRefsWithOneFocusProbe;
var
  lButton: TButton;
  lButtonRef: string;
  lControls: TJSONArray;
  lEdit: TEdit;
  lEditRef: string;
  lForm: TForm;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lResponse: TJSONObject;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm, False, True, 'geometry');
    try
      AssertOk(lMap);
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
      lButtonRef := ControlRefByName(lMap, 'ApplyButton');
    finally
      lMap.Free;
    end;

    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"controls.info","refs":["' + lEditRef + '","' + lButtonRef + '"]}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('controls.info', JsonText(lResponse, 'cmd'));
      Assert.AreEqual('full', JsonText(lResponse, 'detail'));
      Assert.AreEqual('false', JsonText(lResponse, 'includeAccessibility'));
      lControls := JsonArrayValue(lResponse, 'controls');
      Assert.AreEqual(2, lControls.Count);
      Assert.AreEqual('SearchEdit', JsonText(TJSONObject(lControls.Items[0]), 'name'));
      Assert.AreEqual('ApplyButton', JsonText(TJSONObject(lControls.Items[1]), 'name'));
      Assert.AreEqual('Apply', JsonText(TJSONObject(lControls.Items[1]), 'caption'));
    finally
      lResponse.Free;
    end;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(1, lMetrics.AgentBridgeFocusProbeCount,
      'controls.info should read the focused HWND once for the whole batch.');
    Assert.AreEqual(0, lMetrics.AgentBridgeScreenRectProbeCount,
      'controls.info should reuse screen rectangles from the current form.map snapshot.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.HitTestReturnsControlFromLastSnapshot;
var
  lButton: TButton;
  lEdit: TEdit;
  lEditRef: string;
  lForm: TForm;
  lHit: TJSONObject;
  lMap: TJSONObject;
  lPoint: TPoint;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm);
    try
      AssertOk(lMap);
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
    finally
      lMap.Free;
    end;

    lPoint := lEdit.ClientToScreen(Point(lEdit.Width div 2, lEdit.Height div 2));
    lHit := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      Format('{"cmd":"hitTest","x":%d,"y":%d}', [lPoint.X, lPoint.Y])));
    try
      AssertOk(lHit);
      Assert.AreEqual(lEditRef, JsonText(lHit, 'ref'));
      Assert.AreEqual('SearchEdit', JsonText(lHit, 'name'));
      Assert.AreEqual('TEdit', JsonText(lHit, 'className'));
    finally
      lHit.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.HitTestUsesSnapshotRectanglesForMappedControls;
var
  lButton: TButton;
  lEdit: TEdit;
  lForm: TForm;
  lHit: TJSONObject;
  lMap: TJSONObject;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPoint: TPoint;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm, False, True, 'geometry');
    try
      AssertOk(lMap);
    finally
      lMap.Free;
    end;

    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lPoint := lEdit.ClientToScreen(Point(lEdit.Width div 2, lEdit.Height div 2));
    lHit := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      Format('{"cmd":"hitTest","x":%d,"y":%d}', [lPoint.X, lPoint.Y])));
    try
      AssertOk(lHit);
      Assert.AreEqual('SearchEdit', JsonText(lHit, 'name'));
    finally
      lHit.Free;
    end;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(0, lMetrics.AgentBridgeScreenRectProbeCount,
      'hitTest should reuse screen rectangles from the current form.map snapshot.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.HitTestSkipsSubtreesOutsideTheTargetPoint;
const
  cSmallDepth = 30;
  cLargeDepth = 600;
  cMaxTickGrowth = 6;
  cSampleCount = 3;
var
  lLargeTicks: Int64;
  lSmallTicks: Int64;
begin
  lSmallTicks := MeasureBestHitTestTicks(cSmallDepth, cSampleCount);
  lLargeTicks := MeasureBestHitTestTicks(cLargeDepth, cSampleCount);

  Assert.IsTrue(lLargeTicks <= lSmallTicks * cMaxTickGrowth,
    Format('hitTest should reject off-point child branches before descending. small=%d large=%d',
    [lSmallTicks, lLargeTicks]));
end;

procedure TAccessibilityAgentBridgeTests.DiagnosticsCommandsExposeProviderHotspotMetrics;
var
  lMetrics: TJSONObject;
  lResponse: TJSONObject;
begin
  TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  try
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"diagnostics.providerHotspots.enable"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('diagnostics.providerHotspots.enable', JsonText(lResponse, 'cmd'));
    finally
      lResponse.Free;
    end;

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"diagnostics.providerHotspots.reset"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('diagnostics.providerHotspots.reset', JsonText(lResponse, 'cmd'));
    finally
      lResponse.Free;
    end;

    TAccessibilityDiagnostics.RecordProviderBoundaryCall(pbcNavigate);
    TAccessibilityDiagnostics.RecordProviderBoundaryCall(pbcGetPropertyValue);
    TAccessibilityDiagnostics.RecordAgentBridgeChildClientOriginProbe;
    TAccessibilityDiagnostics.RecordAgentBridgeFocusProbe;
    TAccessibilityDiagnostics.RecordAgentBridgeRttiPropertyLookup;
    TAccessibilityDiagnostics.RecordAgentBridgeScreenRectProbe;
    TAccessibilityDiagnostics.RecordManagerRetainedHookPassivation(7);
    TAccessibilityDiagnostics.RecordProviderRuntimeIdBlockCopy(3);
    TAccessibilityDiagnostics.RecordProviderRuntimeIdElementCopy(5);

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"diagnostics.providerHotspots"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('diagnostics.providerHotspots', JsonText(lResponse, 'cmd'));
      lMetrics := JsonObjectValue(lResponse, 'metrics');
      Assert.AreEqual('true', JsonText(lMetrics, 'enabled'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'providerNavigateCount'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'providerGetPropertyValueCount'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'agentBridgeChildClientOriginProbeCount'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'agentBridgeFocusProbeCount'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'agentBridgeRttiPropertyLookupCount'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'agentBridgeScreenRectProbeCount'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'managerRetainedHookPassivateCount'));
      Assert.AreEqual(7, JsonInt(lMetrics, 'managerRetainedHookLinearScanCount'));
      Assert.AreEqual(1, JsonInt(lMetrics, 'providerRuntimeIdBlockCopyCount'));
      Assert.AreEqual(3, JsonInt(lMetrics, 'providerRuntimeIdBlockCopyElementCount'));
      Assert.AreEqual(5, JsonInt(lMetrics, 'providerRuntimeIdElementCopyCount'));
    finally
      lResponse.Free;
    end;
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityAgentBridgeTests.KeyboardTabScalesWithTabStopCount;
const
  cControlCount = 400;
var
  lExpectedTabOrder: Integer;
  lForm: TForm;
  lMap: TJSONObject;
  lResponse: TJSONObject;
begin
  lForm := BuildTabOrderStressForm(cControlCount);
  try
    lForm.Show;
    Application.ProcessMessages;
    lMap := MapForm(lForm, False, True, 'geometry');
    try
      AssertOk(lMap);
    finally
      lMap.Free;
    end;

    if lForm.ActiveControl = nil then
    begin
      lExpectedTabOrder := 0;
    end else begin
      lExpectedTabOrder := (lForm.ActiveControl.TabOrder + 1) mod cControlCount;
    end;
    TAgentBridgeTabOrderProbeEdit.ResetTabOrderListCalls;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"keyboard.tab"}'));
      try
        AssertOk(lResponse);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;

    Assert.AreEqual(cControlCount, TAgentBridgeTabOrderProbeEdit.TabOrderListCalls,
      'keyboard.tab must traverse the flat tab-order list exactly once.');
    Assert.IsNotNull(lForm.ActiveControl);
    Assert.AreEqual(lExpectedTabOrder, Integer(lForm.ActiveControl.TabOrder),
      'keyboard.tab must focus the next control in VCL tab order.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.QueuedInvokeReportsLifecycleFailureAndConsumption;
var
  lFailingButton: TAgentBridgeFailingClickButton;
  lFailedOperationId: string;
  lForm: TForm;
  lOperationId: string;
  lProbe: TAgentBridgeOperationProbe;
  lProbeButton: TButton;
  lResponse: TJSONObject;
  lStatus: string;
  lStopwatch: TStopwatch;
begin
  lForm := TForm.Create(nil);
  lForm.Name := 'BridgeQueuedOperationForm';
  lProbe := TAgentBridgeOperationProbe.Create;
  try
    lProbeButton := TButton.Create(lForm);
    lProbeButton.Name := 'QueuedButton';
    lProbeButton.OnClick := lProbe.Click;
    lProbeButton.Parent := lForm;

    lFailingButton := TAgentBridgeFailingClickButton.Create(lForm);
    lFailingButton.Name := 'FailingButton';
    lFailingButton.Parent := lForm;

    lForm.Show;
    Application.ProcessMessages;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.invoke","target":{"formName":"BridgeQueuedOperationForm",' +
        '"controlName":"QueuedButton"}}'));
      try
        AssertOk(lResponse);
        lOperationId := JsonText(lResponse, 'operationId');
        Assert.AreEqual('queued', JsonText(lResponse, 'status'));
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual(0, lProbe.Clicks, 'Queued invoke must not execute inline.');
      finally
        lResponse.Free;
      end;

      lProbe.OperationId := lOperationId;
      lStopwatch := TStopwatch.StartNew;
      while (lProbe.Clicks = 0) and (lStopwatch.ElapsedMilliseconds < 1000) do
      begin
        CheckSynchronize(10);
      end;
      Assert.AreEqual(1, lProbe.Clicks);
      Assert.AreEqual('running', lProbe.ObservedStatus,
        'The operation must expose running state while its VCL action executes.');

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lOperationId + '","consume":true}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('succeeded', JsonText(lResponse, 'status'));
        Assert.AreEqual('true', JsonText(lResponse, 'terminal'));
        Assert.AreEqual('true', JsonText(lResponse, 'consumed'));
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lOperationId + '"}'));
      try
        AssertFailure(lResponse, 'operation_not_found');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.invoke","target":{"formName":"BridgeQueuedOperationForm",' +
        '"controlName":"FailingButton"}}'));
      try
        AssertOk(lResponse);
        lFailedOperationId := JsonText(lResponse, 'operationId');
      finally
        lResponse.Free;
      end;

      lStopwatch := TStopwatch.StartNew;
      repeat
        CheckSynchronize(10);
        lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
          '{"cmd":"operation.status","operationId":"' + lFailedOperationId + '","consume":false}'));
        try
          AssertOk(lResponse);
          lStatus := JsonText(lResponse, 'status');
        finally
          lResponse.Free;
        end;
      until (lStatus = 'failed') or (lStopwatch.ElapsedMilliseconds >= 1000);
      Assert.AreEqual('failed', lStatus, 'The failing queued invoke did not reach a terminal state.');
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lFailedOperationId + '","consume":true}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('failed', JsonText(lResponse, 'status'));
        Assert.AreEqual('invoke_failed', JsonText(lResponse, 'operationErrorCode'));
        Assert.IsTrue(Pos('Expected queued invoke failure', JsonText(lResponse, 'operationMessage')) > 0);
        Assert.AreEqual('true', JsonText(lResponse, 'consumed'));
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lProbe.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.QueuedInvokeCancelsDestroyedTargetsAndDisabledMutations;
var
  lButton: TButton;
  lClickRecorder: TAgentBridgeClickRecorder;
  lForm: TForm;
  lMap: TJSONObject;
  lOperationId: string;
  lRef: string;
  lResponse: TJSONObject;
begin
  lForm := TForm.Create(nil);
  lForm.Name := 'BridgeQueuedLifetimeForm';
  lClickRecorder := TAgentBridgeClickRecorder.Create;
  try
    lButton := TButton.Create(lForm);
    lButton.Name := 'MappedQueuedButton';
    lButton.OnClick := lClickRecorder.Click;
    lButton.Parent := lForm;
    lForm.Show;
    Application.ProcessMessages;

    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lMap := MapForm(lForm);
      try
        lRef := ControlRefByName(lMap, 'MappedQueuedButton');
      finally
        lMap.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.invoke","ref":"' + lRef + '"}'));
      try
        AssertOk(lResponse);
        lOperationId := JsonText(lResponse, 'operationId');
      finally
        lResponse.Free;
      end;

      lMap := MapForm(lForm);
      lMap.Free;
      lButton.Free;
      lButton := TButton.Create(lForm);
      lButton.Name := 'MappedQueuedButton';
      lButton.OnClick := lClickRecorder.Click;
      lButton.Parent := lForm;
      CheckSynchronize(10);

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lOperationId + '"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('failed', JsonText(lResponse, 'status'));
        Assert.AreEqual('target_destroyed', JsonText(lResponse, 'operationErrorCode'));
        Assert.AreEqual(0, lClickRecorder.Clicks);
      finally
        lResponse.Free;
      end;

      lButton := TButton.Create(lForm);
      lButton.Name := 'DisabledQueuedButton';
      lButton.OnClick := lClickRecorder.Click;
      lButton.Parent := lForm;
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.invoke","target":{"formName":"BridgeQueuedLifetimeForm",' +
        '"controlName":"DisabledQueuedButton"}}'));
      try
        AssertOk(lResponse);
        lOperationId := JsonText(lResponse, 'operationId');
      finally
        lResponse.Free;
      end;

      TAccessibilityAgentBridge.SetMutationEnabled(False);
      CheckSynchronize(10);
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lOperationId + '"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('failed', JsonText(lResponse, 'status'));
        Assert.AreEqual('mutation_disabled', JsonText(lResponse, 'operationErrorCode'));
        Assert.AreEqual(0, lClickRecorder.Clicks);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lClickRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.QueuedInvokeBoundsRegistryAndPreservesOtherCallbacks;
const
  cOperationCount = 33;
var
  i: Integer;
  lButton: TButton;
  lClickRecorder: TAgentBridgeClickRecorder;
  lForm: TForm;
  lOperationIds: array[0..Pred(cOperationCount)] of string;
  lQueuedProbe: TAgentBridgeQueuedProbe;
  lResponse: TJSONObject;
  lStopwatch: TStopwatch;

  procedure AssertStatusFailure(const aJson: string; const aErrorCode: string);
  var
    lStatusResponse: TJSONObject;
  begin
    lStatusResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(aJson));
    try
      Assert.AreEqual('false', JsonText(lStatusResponse, 'ok'), aJson);
      Assert.AreEqual(aErrorCode, JsonText(lStatusResponse, 'errorCode'), aJson);
    finally
      lStatusResponse.Free;
    end;
  end;

begin
  lForm := TForm.Create(nil);
  lForm.Name := 'BridgeQueuedRegistryForm';
  lClickRecorder := TAgentBridgeClickRecorder.Create;
  lQueuedProbe := TAgentBridgeQueuedProbe.Create;
  try
    lButton := TButton.Create(lForm);
    lButton.Name := 'QueuedRegistryButton';
    lButton.OnClick := lClickRecorder.Click;
    lButton.Parent := lForm;
    lForm.Show;
    Application.ProcessMessages;

    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      TThread.ForceQueue(nil, lQueuedProbe.Run);
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.invoke","target":{"formName":"BridgeQueuedRegistryForm",' +
        '"controlName":"QueuedRegistryButton"}}'));
      try
        AssertOk(lResponse);
        lOperationIds[0] := JsonText(lResponse, 'operationId');
      finally
        lResponse.Free;
      end;
      TAccessibilityAgentBridge.SetMutationEnabled(False);
      CheckSynchronize(10);
      Assert.AreEqual(1, lQueuedProbe.Calls,
        'Disabling bridge mutations must not remove unrelated queued callbacks.');
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lOperationIds[0] + '"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('mutation_disabled', JsonText(lResponse, 'operationErrorCode'));
      finally
        lResponse.Free;
      end;

      AssertStatusFailure('{"cmd":"operation.status"}', 'invalid_request');
      AssertStatusFailure('{"cmd":"operation.status","operationId":1}', 'invalid_request');
      AssertStatusFailure('{"cmd":"operation.status","operationId":""}', 'invalid_request');
      AssertStatusFailure(
        '{"cmd":"operation.status","operationId":"missing","consume":"yes"}', 'invalid_request');

      TAccessibilityAgentBridge.SetMutationEnabled(True);
      for i := 0 to Pred(cOperationCount) do
      begin
        lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
          '{"cmd":"control.invoke","target":{"formName":"BridgeQueuedRegistryForm",' +
          '"controlName":"QueuedRegistryButton"}}'));
        try
          AssertOk(lResponse);
          lOperationIds[i] := JsonText(lResponse, 'operationId');
        finally
          lResponse.Free;
        end;
        CheckSynchronize(10);
      end;

      lStopwatch := TStopwatch.StartNew;
      while (lClickRecorder.Clicks < cOperationCount) and (lStopwatch.ElapsedMilliseconds < 1000) do
      begin
        CheckSynchronize(10);
      end;
      Assert.AreEqual(cOperationCount, lClickRecorder.Clicks);

      AssertStatusFailure(
        '{"cmd":"operation.status","operationId":"' + lOperationIds[0] + '"}', 'operation_not_found');
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lOperationIds[Pred(cOperationCount)] +
        '","consume":false}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('succeeded', JsonText(lResponse, 'status'));
        Assert.AreEqual('false', JsonText(lResponse, 'consumed'));
      finally
        lResponse.Free;
      end;

      for i := 1 to Pred(cOperationCount) do
      begin
        lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
          '{"cmd":"operation.status","operationId":"' + lOperationIds[i] + '"}'));
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lQueuedProbe.Free;
    lClickRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.BackgroundInvokeSupportsVclAndActionControls;
var
  lAction: TAction;
  lActionRecorder: TAgentBridgeClickRecorder;
  lButton: TButton;
  lButtonRecorder: TAgentBridgeClickRecorder;
  lForm: TForm;
  lPanel: TPanel;
  lSpeedButton: TSpeedButton;
  lSpeedButtonRecorder: TAgentBridgeClickRecorder;

  procedure InvokeAndWait(const aControlName: string; aRecorder: TAgentBridgeClickRecorder;
    aExpectedClicks: Integer);
  var
    lOperationId: string;
    lResponse: TJSONObject;
    lStatus: string;
    lStopwatch: TStopwatch;
  begin
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.invoke","target":{"formName":"BridgeBackgroundActionForm",' +
      '"controlName":"' + aControlName + '"}}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
      Assert.AreEqual('queued-vcl-event-invocation', JsonText(lResponse, 'mutationSemantics'));
      Assert.AreEqual('false', JsonText(lResponse, 'humanEquivalent'));
      Assert.AreEqual('false', JsonText(lResponse, 'userInputEventsGenerated'));
      Assert.AreEqual('false', JsonText(lResponse, 'mayBlockSynchronously'));
      Assert.AreEqual(Pred(aExpectedClicks), aRecorder.Clicks, 'Queued invoke must not execute inline.');
      lOperationId := JsonText(lResponse, 'operationId');
    finally
      lResponse.Free;
    end;

    lStatus := 'queued';
    lStopwatch := TStopwatch.StartNew;
    repeat
      CheckSynchronize(10);
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"operation.status","operationId":"' + lOperationId + '","consume":false}'));
      try
        AssertOk(lResponse);
        lStatus := JsonText(lResponse, 'status');
      finally
        lResponse.Free;
      end;
    until (lStatus = 'succeeded') or (lStatus = 'failed') or (lStopwatch.ElapsedMilliseconds >= 1000);
    Assert.AreEqual('succeeded', lStatus);
    Assert.AreEqual(aExpectedClicks, aRecorder.Clicks);

    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"operation.status","operationId":"' + lOperationId + '"}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('succeeded', JsonText(lResponse, 'status'));
      Assert.AreEqual('true', JsonText(lResponse, 'consumed'));
    finally
      lResponse.Free;
    end;
  end;

begin
  lForm := TForm.Create(nil);
  lForm.Name := 'BridgeBackgroundActionForm';
  lButtonRecorder := TAgentBridgeClickRecorder.Create;
  lSpeedButtonRecorder := TAgentBridgeClickRecorder.Create;
  lActionRecorder := TAgentBridgeClickRecorder.Create;
  try
    lButton := TButton.Create(lForm);
    lButton.Name := 'InvokeButton';
    lButton.OnClick := lButtonRecorder.Click;
    lButton.Parent := lForm;

    lSpeedButton := TSpeedButton.Create(lForm);
    lSpeedButton.Name := 'InvokeSpeedButton';
    lSpeedButton.OnClick := lSpeedButtonRecorder.Click;
    lSpeedButton.Parent := lForm;

    lAction := TAction.Create(lForm);
    lAction.OnExecute := lActionRecorder.Click;
    lPanel := TPanel.Create(lForm);
    lPanel.Name := 'ActionPanel';
    lPanel.Action := lAction;
    lPanel.Parent := lForm;

    lForm.Show;
    Application.ProcessMessages;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      InvokeAndWait('InvokeButton', lButtonRecorder, 1);
      InvokeAndWait('InvokeSpeedButton', lSpeedButtonRecorder, 1);
      InvokeAndWait('ActionPanel', lActionRecorder, 1);
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lActionRecorder.Free;
    lSpeedButtonRecorder.Free;
    lButtonRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.SetCheckedUsesDeterministicVclEvents;
var
  lCheckBox: TCheckBox;
  lCheckRecorder: TAgentBridgeClickRecorder;
  lForm: TForm;
  lRadioButton: TRadioButton;
  lRadioRecorder: TAgentBridgeClickRecorder;
  lResponse: TJSONObject;
begin
  lForm := TForm.Create(nil);
  lForm.Name := 'BridgeCheckedActionForm';
  lCheckRecorder := TAgentBridgeClickRecorder.Create;
  lRadioRecorder := TAgentBridgeClickRecorder.Create;
  try
    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Name := 'OptionsCheckBox';
    lCheckBox.State := cbGrayed;
    lCheckBox.OnClick := lCheckRecorder.Click;
    lCheckBox.Parent := lForm;

    lRadioButton := TRadioButton.Create(lForm);
    lRadioButton.Name := 'ModeRadioButton';
    lRadioButton.Checked := True;
    lRadioButton.OnClick := lRadioRecorder.Click;
    lRadioButton.Parent := lForm;

    lForm.Show;
    Application.ProcessMessages;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeCheckedActionForm",' +
        '"controlName":"OptionsCheckBox"},"checked":false}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual('vcl-checked-state', JsonText(lResponse, 'mutationSemantics'));
        Assert.AreEqual(cbUnchecked, lCheckBox.State);
        Assert.AreEqual(1, lCheckRecorder.Clicks);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeCheckedActionForm",' +
        '"controlName":"OptionsCheckBox"},"checked":false}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(1, lCheckRecorder.Clicks, 'An idempotent checkbox request must not fire OnClick.');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeCheckedActionForm",' +
        '"controlName":"OptionsCheckBox"},"checked":true}'));
      try
        AssertOk(lResponse);
        Assert.IsTrue(lCheckBox.Checked);
        Assert.AreEqual(2, lCheckRecorder.Clicks);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeCheckedActionForm",' +
        '"controlName":"ModeRadioButton"},"checked":false}'));
      try
        AssertOk(lResponse);
        Assert.IsFalse(lRadioButton.Checked);
        Assert.AreEqual(1, lRadioRecorder.Clicks);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeCheckedActionForm",' +
        '"controlName":"ModeRadioButton"},"checked":false}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(1, lRadioRecorder.Clicks, 'An idempotent radio request must not fire OnClick.');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeCheckedActionForm",' +
        '"controlName":"ModeRadioButton"},"checked":true}'));
      try
        AssertOk(lResponse);
        Assert.IsTrue(lRadioButton.Checked);
        Assert.AreEqual(2, lRadioRecorder.Clicks);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lRadioRecorder.Free;
    lCheckRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.SelectUsesStockVclNotificationOncePerChange;
var
  lComboBox: TComboBox;
  lComboClickRecorder: TAgentBridgeClickRecorder;
  lComboRecorder: TAgentBridgeClickRecorder;
  lForm: TForm;
  lListBox: TListBox;
  lListRecorder: TAgentBridgeClickRecorder;
  lResponse: TJSONObject;
begin
  lForm := TForm.Create(nil);
  lForm.Name := 'BridgeSelectionActionForm';
  lListRecorder := TAgentBridgeClickRecorder.Create;
  lComboClickRecorder := TAgentBridgeClickRecorder.Create;
  lComboRecorder := TAgentBridgeClickRecorder.Create;
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Name := 'OptionsListBox';
    lListBox.Parent := lForm;
    lListBox.Items.Add('One');
    lListBox.Items.Add('Two');
    lListBox.Items.Add('Three');
    lListBox.ItemIndex := 0;
    lListBox.OnClick := lListRecorder.Click;

    lComboBox := TComboBox.Create(lForm);
    lComboBox.Name := 'OptionsComboBox';
    lComboBox.Parent := lForm;
    lComboBox.Items.Assign(lListBox.Items);
    lComboBox.ItemIndex := 0;
    lComboBox.OnClick := lComboClickRecorder.Click;
    lComboBox.OnSelect := lComboRecorder.Click;

    lForm.Show;
    Application.ProcessMessages;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.select","target":{"formName":"BridgeSelectionActionForm",' +
        '"controlName":"OptionsListBox"},"index":1}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual('vcl-selection-notification', JsonText(lResponse, 'mutationSemantics'));
        Assert.AreEqual(1, lListBox.ItemIndex);
        Assert.AreEqual(1, lListRecorder.Clicks);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.select","target":{"formName":"BridgeSelectionActionForm",' +
        '"controlName":"OptionsListBox"},"index":1}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(1, lListRecorder.Clicks, 'An idempotent list selection must not fire OnClick.');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.select","target":{"formName":"BridgeSelectionActionForm",' +
        '"controlName":"OptionsListBox"},"text":"Three"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(2, lListBox.ItemIndex);
        Assert.AreEqual(2, lListRecorder.Clicks);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.select","target":{"formName":"BridgeSelectionActionForm",' +
        '"controlName":"OptionsComboBox"},"text":"Two"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(1, lComboBox.ItemIndex);
        Assert.AreEqual(1, lComboClickRecorder.Clicks);
        Assert.AreEqual(1, lComboRecorder.Clicks);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.select","target":{"formName":"BridgeSelectionActionForm",' +
        '"controlName":"OptionsComboBox"},"text":"Two"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(1, lComboClickRecorder.Clicks, 'An idempotent combo selection must not fire OnClick.');
        Assert.AreEqual(1, lComboRecorder.Clicks, 'An idempotent combo selection must not fire OnSelect.');
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.select","target":{"formName":"BridgeSelectionActionForm",' +
        '"controlName":"OptionsComboBox"},"index":2}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(2, lComboBox.ItemIndex);
        Assert.AreEqual(2, lComboClickRecorder.Clicks);
        Assert.AreEqual(2, lComboRecorder.Clicks);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lComboRecorder.Free;
    lComboClickRecorder.Free;
    lListRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.BackgroundActionsRejectInvalidOrUnsupportedRequests;
var
  lButton: TButton;
  lCheckBox: TCheckBox;
  lCheckRecorder: TAgentBridgeClickRecorder;
  lEdit: TEdit;
  lForm: TForm;
  lListBox: TListBox;
  lListRecorder: TAgentBridgeClickRecorder;
  lMultiListBox: TListBox;

  procedure AssertCommandFailure(const aJson: string; const aErrorCode: string);
  var
    lResponse: TJSONObject;
  begin
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(aJson));
    try
      AssertFailure(lResponse, aErrorCode);
    finally
      lResponse.Free;
    end;
  end;

begin
  lForm := TForm.Create(nil);
  lForm.Name := 'BridgeBackgroundErrorForm';
  lCheckRecorder := TAgentBridgeClickRecorder.Create;
  lListRecorder := TAgentBridgeClickRecorder.Create;
  try
    lButton := TButton.Create(lForm);
    lButton.Name := 'DisabledButton';
    lButton.Enabled := False;
    lButton.Parent := lForm;

    lEdit := TEdit.Create(lForm);
    lEdit.Name := 'UnsupportedEdit';
    lEdit.Parent := lForm;

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Name := 'OptionsCheckBox';
    lCheckBox.OnClick := lCheckRecorder.Click;
    lCheckBox.Parent := lForm;

    lListBox := TListBox.Create(lForm);
    lListBox.Name := 'OptionsListBox';
    lListBox.Parent := lForm;
    lListBox.Items.Add('Alpha');
    lListBox.Items.Add('Beta');
    lListBox.ItemIndex := 0;
    lListBox.OnClick := lListRecorder.Click;

    lMultiListBox := TListBox.Create(lForm);
    lMultiListBox.Name := 'MultiListBox';
    lMultiListBox.MultiSelect := True;
    lMultiListBox.Parent := lForm;
    lMultiListBox.Items.Assign(lListBox.Items);
    lMultiListBox.ItemIndex := 0;

    lForm.Show;
    Application.ProcessMessages;
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      AssertCommandFailure(
        '{"cmd":"control.invoke","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"DisabledButton"}}', 'control_disabled');
      AssertCommandFailure(
        '{"cmd":"control.invoke","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"UnsupportedEdit"}}', 'unsupported_control');

      AssertCommandFailure(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"OptionsCheckBox"},"checked":"true"}', 'invalid_request');
      AssertCommandFailure(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"OptionsCheckBox"}}', 'invalid_request');
      AssertCommandFailure(
        '{"cmd":"control.setChecked","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"UnsupportedEdit"},"checked":true}', 'unsupported_control');
      Assert.IsFalse(lCheckBox.Checked);
      Assert.AreEqual(0, lCheckRecorder.Clicks);

      AssertCommandFailure(
        '{"cmd":"control.select","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"OptionsListBox"}}', 'invalid_request');
      AssertCommandFailure(
        '{"cmd":"control.select","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"OptionsListBox"},"index":1,"text":"Beta"}', 'invalid_request');
      AssertCommandFailure(
        '{"cmd":"control.select","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"OptionsListBox"},"index":"1"}', 'invalid_request');
      AssertCommandFailure(
        '{"cmd":"control.select","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"OptionsListBox"},"index":2}', 'index_out_of_bounds');
      AssertCommandFailure(
        '{"cmd":"control.select","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"OptionsListBox"},"text":"beta"}', 'item_not_found');
      AssertCommandFailure(
        '{"cmd":"control.select","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"UnsupportedEdit"},"index":0}', 'unsupported_control');
      AssertCommandFailure(
        '{"cmd":"control.select","target":{"formName":"BridgeBackgroundErrorForm",' +
        '"controlName":"MultiListBox"},"index":1}', 'unsupported_control');
      Assert.AreEqual(0, lListBox.ItemIndex);
      Assert.AreEqual(0, lListRecorder.Clicks);
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;

    AssertCommandFailure(
      '{"cmd":"control.invoke","target":{"formName":"BridgeBackgroundErrorForm",' +
      '"controlName":"UnsupportedEdit"}}', 'mutation_disabled');
  finally
    lListRecorder.Free;
    lCheckRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.MutationsAreGatedAndReportBackgroundSemantics;
var
  lButton: TButton;
  lClickRecorder: TAgentBridgeClickRecorder;
  lEdit: TEdit;
  lEditRef: string;
  lForm: TForm;
  lHandle: string;
  lMap: TJSONObject;
  lResponse: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  lForm.Show;
  Application.ProcessMessages;
  lHandle := UIntToStr(NativeUInt(lForm.Handle));
  lClickRecorder := TAgentBridgeClickRecorder.Create;
  try
    lButton.OnClick := lClickRecorder.Click;
    lMap := MapForm(lForm);
    try
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
    finally
      lMap.Free;
    end;

    lForm.ActiveControl := lButton;
    TAccessibilityAgentBridge.SetMutationEnabled(False);
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.focus","ref":"' + lEditRef + '"}'));
    try
      AssertFailure(lResponse, 'mutation_disabled');
      Assert.AreSame(lButton, lForm.ActiveControl);
    finally
      lResponse.Free;
    end;

    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.focus","ref":"' + lEditRef + '"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('true', JsonText(lResponse, 'snapshotInvalidated'));
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual('vcl-focus-request', JsonText(lResponse, 'mutationSemantics'));
        Assert.AreEqual('false', JsonText(lResponse, 'humanEquivalent'));
        Assert.AreEqual('false', JsonText(lResponse, 'userInputEventsGenerated'));
        Assert.AreSame(lEdit, lForm.ActiveControl);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","target":{"formHandle":' + lHandle +
        ',"controlName":"SearchEdit"},"text":"base"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual('raw-property-assignment', JsonText(lResponse, 'mutationSemantics'));
        Assert.AreEqual('false', JsonText(lResponse, 'humanEquivalent'));
        Assert.AreEqual('false', JsonText(lResponse, 'userInputEventsGenerated'));
        Assert.AreEqual('base', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.typeText","target":{"formName":"BridgeForm","controlName":"SearchEdit"},' +
        '"text":" plus"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual('raw-property-assignment', JsonText(lResponse, 'mutationSemantics'));
        Assert.AreEqual('false', JsonText(lResponse, 'humanEquivalent'));
        Assert.AreEqual('false', JsonText(lResponse, 'userInputEventsGenerated'));
        Assert.AreEqual('base plus', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"keyboard.tab"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual('keyboard-equivalent-navigation', JsonText(lResponse, 'mutationSemantics'));
        Assert.AreEqual('false', JsonText(lResponse, 'humanEquivalent'));
        Assert.AreEqual('false', JsonText(lResponse, 'userInputEventsGenerated'));
        Assert.AreSame(lButton, lForm.ActiveControl);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.click","target":{"formName":"BridgeForm","controlName":"ApplyButton"}}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('background-command', JsonText(lResponse, 'driveMode'));
        Assert.AreEqual('vcl-event-invocation', JsonText(lResponse, 'mutationSemantics'));
        Assert.AreEqual('false', JsonText(lResponse, 'humanEquivalent'));
        Assert.AreEqual('false', JsonText(lResponse, 'userInputEventsGenerated'));
        Assert.AreEqual('true', JsonText(lResponse, 'mayBlockSynchronously'));
        Assert.AreEqual(1, lClickRecorder.Clicks);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lClickRecorder.Free;
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityAgentBridgeTests);

end.
