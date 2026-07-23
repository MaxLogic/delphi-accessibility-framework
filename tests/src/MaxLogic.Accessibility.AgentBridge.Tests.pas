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
    procedure WindowInfoReturnsGeometryAndDpi;
    [Test]
    procedure FormMapReturnsSnapshotRefsAndTargetPoints;
    [Test]
    procedure FormMapAppliesConfiguredDepthAndChildBounds;
    [Test]
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
    procedure MutationsAreGatedAndOperateOnLastSnapshotRefs;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.Generics.Collections, System.IOUtils, System.JSON, System.SyncObjs, System.SysUtils,
  System.Types, System.TypInfo, System.Variants, Winapi.Windows, Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  Vcl.Grids, Vcl.StdCtrls, MaxLogic.Accessibility.AgentBridge, MaxLogic.Accessibility.Diagnostics,
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
    Assert.AreEqual(1, JsonInt(lResponse, 'protocolVersion'));
    Assert.AreEqual('false', JsonText(lResponse, 'mutationEnabled'));
  finally
    lResponse.Free;
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
      Assert.AreEqual(1, JsonInt(lResponse, 'protocolVersion'));

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
      Assert.AreEqual('@a0', JsonText(lRoot, 'ref'));
      Assert.AreEqual('BridgeForm', JsonText(lRoot, 'name'));
      Assert.AreEqual('TForm', JsonText(lRoot, 'className'));
      Assert.AreEqual('Bridge Test Window', JsonText(lRoot, 'caption'));

      lEditEntry := ControlByName(lMap, 'SearchEdit');
      Assert.AreEqual('@a1', JsonText(lEditEntry, 'ref'));
      Assert.AreEqual('@a0', JsonText(lEditEntry, 'parentRef'));
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

      Assert.AreEqual('@a2', ControlRefByName(lMap, 'ApplyButton'));
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
      Assert.AreEqual('@a1', JsonText(lEditEntry, 'ref'));
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
    finally
      lMap.Free;
    end;

    lPoint := lEdit.ClientToScreen(Point(lEdit.Width div 2, lEdit.Height div 2));
    lHit := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      Format('{"cmd":"hitTest","x":%d,"y":%d}', [lPoint.X, lPoint.Y])));
    try
      AssertOk(lHit);
      Assert.AreEqual('@a1', JsonText(lHit, 'ref'));
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

procedure TAccessibilityAgentBridgeTests.MutationsAreGatedAndOperateOnLastSnapshotRefs;
var
  lButton: TButton;
  lButtonRef: string;
  lClickRecorder: TAgentBridgeClickRecorder;
  lEdit: TEdit;
  lEditRef: string;
  lForm: TForm;
  lMap: TJSONObject;
  lResponse: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  lForm.Show;
  Application.ProcessMessages;
  lClickRecorder := TAgentBridgeClickRecorder.Create;
  try
    lButton.OnClick := lClickRecorder.Click;
    lMap := MapForm(lForm);
    try
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
      lButtonRef := ControlRefByName(lMap, 'ApplyButton');
    finally
      lMap.Free;
    end;

    lForm.ActiveControl := lButton;
    TAccessibilityAgentBridge.SetMutationEnabled(False);
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.focus","ref":"' + lEditRef + '"}'));
    try
      Assert.AreEqual('false', JsonText(lResponse, 'ok'));
      Assert.AreEqual('mutation_disabled', JsonText(lResponse, 'errorCode'));
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
        Assert.AreSame(lEdit, lForm.ActiveControl);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","ref":"' + lEditRef + '","text":"base"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('base', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.typeText","ref":"' + lEditRef + '","text":" plus"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('base plus', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"keyboard.tab"}'));
      try
        AssertOk(lResponse);
        Assert.AreSame(lButton, lForm.ActiveControl);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.click","ref":"' + lButtonRef + '"}'));
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

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityAgentBridgeTests);

end.
