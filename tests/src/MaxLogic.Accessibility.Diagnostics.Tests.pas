unit MaxLogic.Accessibility.Diagnostics.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Diagnostics')]
  TAccessibilityDiagnosticsTests = class
  public
    [Test]
    procedure EnabledDiagnosticsAppendTimestampedLinesToConfiguredLog;
  end;

  [TestFixture]
  [Category('ListBoxPerformance')]
  TAccessibilityListBoxPerformanceTests = class
  public
    [Test]
    procedure ListBoxFocusMetricsAreGatedAndCaptureFocusPath;
    [Test]
    procedure ListBoxFocusMovementDoesNotQueueNotificationSpeech;
    [Test]
    procedure ListBoxPreparationScalesWithVisibleRows;
    [Test]
    procedure ListBoxPreparationInvalidatesWhenVisibleStateChanges;
    [Test]
    procedure ListBoxRepeatedNavigationPreparationIsIdempotent;
    [Test]
    procedure ListBoxCachedFocusProviderAvoidsTextCleanup;
    [Test]
    procedure ListBoxFocusBaselineArtifactIsWritten;
  end;

  [TestFixture]
  [Category('ProviderHotspotPerformance')]
  TAccessibilityProviderHotspotPerformanceTests = class
  public
    [Test]
    [Category('ListBoxPerformance')]
    procedure ListBoxProviderHotspotMetricsCaptureGetSelection;
    [Test]
    [Category('Memo')]
    procedure MemoProviderHotspotMetricsCapturePreparation;
    [Test]
    procedure ProviderHotspotBaselineArtifactIsWritten;
    [Test]
    [Category('StringGrid')]
    procedure StringGridProviderHotspotMetricsCaptureRefresh;
    [Test]
    [Category('TmsAdvStringGrid')]
    procedure TmsAdvStringGridProviderHotspotMetricsCaptureRefresh;
  end;

implementation

uses
  System.IOUtils, System.SysUtils, Winapi.ActiveX, Winapi.Messages, Winapi.Windows, Vcl.CheckLst, Vcl.Forms,
  Vcl.Grids, Vcl.StdCtrls, AdvGrid, MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.TmsAdvStringGridAdapters,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

type
  TListBoxPerformanceTestUiaApi = class(TInterfacedObject, IAccessibilityUiaApi)
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
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
  end;

function BaselineArtifactFileName: string;
var
  lAgentsDir: string;
  lRunsDir: string;
begin
  lAgentsDir := TPath.Combine(GetCurrentDir, '.agents');
  lRunsDir := TPath.Combine(lAgentsDir, 'runs');
  ForceDirectories(lRunsDir);
  Result := TPath.Combine(lRunsDir, 'listbox-focus-baseline.json');
end;

function ProviderHotspotArtifactFileName: string;
var
  lAgentsDir: string;
  lRunsDir: string;
begin
  lAgentsDir := TPath.Combine(GetCurrentDir, '.agents');
  lRunsDir := TPath.Combine(lAgentsDir, 'runs');
  ForceDirectories(lRunsDir);
  Result := TPath.Combine(lRunsDir, 'provider-hotspot-baseline.json');
end;

function BuildBaselineJson(const aFrameworkMetrics: TAccessibilityListBoxFocusMetrics;
  const aTodoAppMetrics: TAccessibilityListBoxFocusMetrics): string;
begin
  Result := '[' + aFrameworkMetrics.ToJson('framework-large-checklistbox-fixture', 'Accessibility-Framework') +
    ',' + aTodoAppMetrics.ToJson('todoapp-client-list-checklistbox-fixture',
    'ToDoApp client list compatible TCheckListBox fixture') + ']';
end;

function BuildProviderHotspotJson(const aMetrics: TAccessibilityProviderHotspotMetrics): string;
begin
  Result := '[' + aMetrics.ToJson('provider-hotspot-large-fixture', 'Accessibility-Framework') +
    ',{"scenario":"provider-hotspot-large-fixture","source":"T-048",' +
    '"taskDecisions":{"T-046":"proceed:memo-line-preparation-total-line-work",' +
    '"T-044":"proceed:vcl-stringgrid-full-grid-probe-work",' +
    '"T-045":"proceed:tms-advstringgrid-full-grid-probe-work-after-t-044",' +
    '"T-043":"skip:listbox-getselection-not-hot-for-focus-change",' +
    '"T-049":"proceed:last-host-validation"}}]';
end;

procedure ResetManager;
begin
  TAccessibilityManager.Uninstall;
  TAccessibilityManagerInternals.SetUiaApi(nil);
  TAccessibilityManagerInternals.SetWinEventSink(nil);
end;

function FragmentRoot(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragmentRoot;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider.RawElementProvider, IRawElementProviderFragmentRoot, Result));
end;

function SimpleProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Assert.IsTrue(Supports(aFragment, IRawElementProviderSimple, Result));
end;

procedure RunCheckListBoxFocusScenario(aItemCount: Integer; out aMetrics: TAccessibilityListBoxFocusMetrics);
var
  i: Integer;
  lApi: IAccessibilityUiaApi;
  lForm: TForm;
  lListBox: TCheckListBox;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableListBoxFocusMetrics;
  TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
  lApi := TListBoxPerformanceTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lListBox := TCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to Pred(aItemCount) do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lListBox.ItemIndex := 0;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;

    TAccessibilityManager.Install(lForm);
    lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);
    aMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  end;
end;

procedure ExerciseMemoHotspotProvider;
var
  i: Integer;
  lForm: TForm;
  lLine: IRawElementProviderFragment;
  lMemo: TMemo;
  lMemoFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lMemo := TMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.SetBounds(16, 16, 280, 120);
    for i := 0 to 39 do
    begin
      lMemo.Lines.Add(Format('Memo line %.4d', [i]));
    end;
    lForm.HandleNeeded;
    lMemo.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lMemoFragment));
    Assert.IsNotNull(lMemoFragment, 'Memo provider was not reachable from the form root.');
    Assert.AreEqual(S_OK, lMemoFragment.Navigate(NavigateDirection_FirstChild, lLine));
  finally
    lForm.Free;
  end;
end;

procedure ExerciseStringGridHotspotProvider;
var
  lCol: Integer;
  lForm: TForm;
  lGrid: TStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRow: Integer;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);
    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.SetBounds(8, 8, 180, 90);
    lGrid.ColCount := 12;
    lGrid.RowCount := 80;
    lGrid.FixedCols := 1;
    lGrid.FixedRows := 1;
    lGrid.DefaultColWidth := 55;
    lGrid.DefaultRowHeight := 20;
    for lRow := 0 to Pred(lGrid.RowCount) do
    begin
      for lCol := 0 to Pred(lGrid.ColCount) do
      begin
        lGrid.Cells[lCol, lRow] := Format('R%d C%d', [lRow, lCol]);
      end;
    end;
    lGrid.Col := 2;
    lGrid.Row := 1;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.IsNotNull(lProvider);
  finally
    lForm.Free;
  end;
end;

procedure ExerciseTmsAdvStringGridHotspotProvider;
var
  lCol: Integer;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRow: Integer;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);
    lGrid := TAdvStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.SetBounds(8, 8, 180, 90);
    lGrid.ColCount := 12;
    lGrid.RowCount := 80;
    lGrid.FixedCols := 1;
    lGrid.FixedRows := 1;
    lGrid.DefaultColWidth := 55;
    lGrid.DefaultRowHeight := 22;
    for lRow := 0 to Pred(lGrid.RowCount) do
    begin
      for lCol := 0 to Pred(lGrid.ColCount) do
      begin
        lGrid.Cells[lCol, lRow] := Format('R%d C%d', [lRow, lCol]);
      end;
    end;
    lGrid.Col := 2;
    lGrid.Row := 1;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
    Assert.IsNotNull(lProvider);
  finally
    lForm.Free;
  end;
end;

procedure ExerciseListBoxSelectionHotspotProvider;
var
  i: Integer;
  lForm: TForm;
  lListBox: TCheckListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lSelection: ISelectionProvider;
  lSelectionArray: PSafeArray;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to 49 do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lListBox.ItemIndex := 7;
    lForm.HandleNeeded;
    lListBox.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lListBoxFragment));
    Assert.IsNotNull(lListBoxFragment, 'Listbox provider was not reachable from the form root.');
    Assert.AreEqual(S_OK, SimpleProvider(lListBoxFragment).GetPatternProvider(UIA_SelectionPatternId, lPattern));
    Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelection));
    lSelectionArray := nil;
    Assert.AreEqual(S_OK, lSelection.GetSelection(lSelectionArray));
    if lSelectionArray <> nil then
    begin
      SafeArrayDestroy(lSelectionArray);
    end;
  finally
    lForm.Free;
  end;
end;

procedure NavigateListBoxFirstChild(const aRoot: IRawElementProviderFragment; out aItem: IRawElementProviderFragment);
var
  lListBox: IRawElementProviderFragment;
begin
  aItem := nil;
  lListBox := nil;
  Assert.AreEqual(S_OK, aRoot.Navigate(NavigateDirection_FirstChild, lListBox));
  Assert.IsNotNull(lListBox, 'Listbox provider was not reachable from the form root.');
  Assert.AreEqual(S_OK, lListBox.Navigate(NavigateDirection_FirstChild, aItem));
  Assert.IsNotNull(aItem, 'Listbox item provider was not reachable from the listbox provider.');
end;

function TListBoxPerformanceTestUiaApi.ClientsAreListening: Boolean;
begin
  Result := True;
end;

function TListBoxPerformanceTestUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Result := S_OK;
end;

function TListBoxPerformanceTestUiaApi.HostProviderFromHwnd(aHwnd: HWND;
  out aProvider: IRawElementProviderSimple): HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function TListBoxPerformanceTestUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID): HRESULT;
begin
  Result := S_OK;
end;

function TListBoxPerformanceTestUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := S_OK;
end;

function TListBoxPerformanceTestUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Result := S_OK;
end;

function TListBoxPerformanceTestUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Result := S_OK;
end;

function TListBoxPerformanceTestUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Result := 1;
end;

procedure TAccessibilityDiagnosticsTests.EnabledDiagnosticsAppendTimestampedLinesToConfiguredLog;
var
  lLogFile: string;
  lLogText: string;
begin
  lLogFile := TPath.Combine(TPath.GetTempPath, Format('maxlogic-a11y-diagnostics-%d.log', [GetTickCount]));
  try
    TAccessibilityDiagnostics.Configure(lLogFile);
    TAccessibilityDiagnostics.Log('diagnostic probe message');

    Assert.IsTrue(TFile.Exists(lLogFile), 'Diagnostics did not create a log file.');
    lLogText := TFile.ReadAllText(lLogFile, TEncoding.UTF8);
    Assert.Contains(lLogText, 'diagnostic probe message');
    Assert.Contains(lLogText, 'T');
  finally
    TAccessibilityDiagnostics.Disable;
    TFile.Delete(lLogFile);
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.ListBoxProviderHotspotMetricsCaptureGetSelection;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseListBoxSelectionHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.ListBoxGetSelectionCount);
    Assert.AreEqual(1, lMetrics.ListBoxSelectionItemProbeCount);
    Assert.AreEqual(1, lMetrics.ListBoxSelectionProviderCount);
    Assert.IsTrue(lMetrics.ListBoxGetSelectionLastElapsedTicks > 0,
      'Listbox GetSelection elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.MemoProviderHotspotMetricsCapturePreparation;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseMemoHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.MemoPrepareChildrenCount);
    Assert.IsTrue(lMetrics.MemoLineProbeCount <= 12,
      Format('Memo line probe count was %d; expected preparation to stay within visible lines plus focus line.',
      [lMetrics.MemoLineProbeCount]));
    Assert.IsTrue(lMetrics.MemoLineProviderCreatedCount > 0, 'Memo line provider creation was not captured.');
    Assert.IsTrue(lMetrics.MemoLineProviderCreatedCount <= 12,
      Format('Memo line provider creation was %d; expected bounded visible-line preparation.',
      [lMetrics.MemoLineProviderCreatedCount]));
    Assert.IsTrue(lMetrics.MemoPrepareChildrenLastElapsedTicks > 0,
      'Memo preparation elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.ProviderHotspotBaselineArtifactIsWritten;
var
  lArtifactFile: string;
  lJson: string;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseMemoHotspotProvider;
    ExerciseStringGridHotspotProvider;
    ExerciseTmsAdvStringGridHotspotProvider;
    ExerciseListBoxSelectionHotspotProvider;

    lJson := BuildProviderHotspotJson(TAccessibilityDiagnostics.ProviderHotspotMetrics);
    lArtifactFile := ProviderHotspotArtifactFileName;
    TFile.WriteAllText(lArtifactFile, lJson, TEncoding.UTF8);

    Assert.IsTrue(TFile.Exists(lArtifactFile), 'Provider hotspot artifact was not written.');
    lJson := TFile.ReadAllText(lArtifactFile, TEncoding.UTF8);
    Assert.Contains(lJson, 'provider-hotspot-large-fixture');
    Assert.Contains(lJson, '"memoPrepareChildrenCount":1');
    Assert.Contains(lJson, '"stringGridRefreshCount":1');
    Assert.Contains(lJson, '"tmsAdvStringGridRefreshCount":1');
    Assert.Contains(lJson, '"listBoxGetSelectionCount":1');
    Assert.Contains(lJson, '"taskDecisions"');
    Assert.Contains(lJson, '"T-046":"proceed:memo-line-preparation-total-line-work"');
    Assert.Contains(lJson, '"T-044":"proceed:vcl-stringgrid-full-grid-probe-work"');
    Assert.Contains(lJson, '"T-045":"proceed:tms-advstringgrid-full-grid-probe-work-after-t-044"');
    Assert.Contains(lJson, '"T-043":"skip:listbox-getselection-not-hot-for-focus-change"');
    Assert.Contains(lJson, '"T-049":"proceed:last-host-validation"');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.StringGridProviderHotspotMetricsCaptureRefresh;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseStringGridHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.StringGridRefreshCount);
    Assert.AreEqual(960, lMetrics.StringGridCellProbeCount);
    Assert.IsTrue(lMetrics.StringGridCellProviderCreatedCount > 0, 'StringGrid cell provider creation was not captured.');
    Assert.IsTrue(lMetrics.StringGridRefreshLastElapsedTicks > 0,
      'StringGrid refresh elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.TmsAdvStringGridProviderHotspotMetricsCaptureRefresh;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseTmsAdvStringGridHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.TmsAdvStringGridRefreshCount);
    Assert.AreEqual(960, lMetrics.TmsAdvStringGridCellProbeCount);
    Assert.IsTrue(lMetrics.TmsAdvStringGridCellProviderCreatedCount > 0,
      'TMS AdvStringGrid cell provider creation was not captured.');
    Assert.IsTrue(lMetrics.TmsAdvStringGridRefreshLastElapsedTicks > 0,
      'TMS AdvStringGrid refresh elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxFocusBaselineArtifactIsWritten;
var
  lBaselineFile: string;
  lFrameworkMetrics: TAccessibilityListBoxFocusMetrics;
  lJson: string;
  lTodoAppMetrics: TAccessibilityListBoxFocusMetrics;
begin
  RunCheckListBoxFocusScenario(180, lFrameworkMetrics);
  RunCheckListBoxFocusScenario(90, lTodoAppMetrics);
  lJson := BuildBaselineJson(lFrameworkMetrics, lTodoAppMetrics);
  lBaselineFile := BaselineArtifactFileName;
  TFile.WriteAllText(lBaselineFile, lJson, TEncoding.UTF8);

  Assert.IsTrue(TFile.Exists(lBaselineFile), 'Baseline artifact was not written.');
  lJson := TFile.ReadAllText(lBaselineFile, TEncoding.UTF8);
  Assert.Contains(lJson, 'framework-large-checklistbox-fixture');
  Assert.Contains(lJson, 'todoapp-client-list-checklistbox-fixture');
  Assert.Contains(lJson, '"focusMovementCount":1');
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxFocusMovementDoesNotQueueNotificationSpeech;
var
  lMetrics: TAccessibilityListBoxFocusMetrics;
begin
  RunCheckListBoxFocusScenario(90, lMetrics);

  Assert.AreEqual(1, lMetrics.FocusMovementCount);
  Assert.AreEqual(2, lMetrics.AutomationEventCount,
    'Listbox focus movement should keep the focused-item focus event and the real selection event.');
  Assert.AreEqual(1, lMetrics.SelectionEventCount);
  Assert.AreEqual(0, lMetrics.NotificationCount,
    'Listbox focus movement must not also queue notification speech for the same item.');
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxPreparationScalesWithVisibleRows;
var
  lMaxProbeCount: Integer;
  lMetrics: TAccessibilityListBoxFocusMetrics;
begin
  RunCheckListBoxFocusScenario(180, lMetrics);

  Assert.IsTrue(lMetrics.PrepareChildrenCount > 0, 'Listbox child preparation was not measured.');
  lMaxProbeCount := lMetrics.PrepareChildrenCount * 24;
  Assert.IsTrue(lMetrics.VisibleItemProbeCount <= lMaxProbeCount,
    Format('Listbox preparation inspected %d item rects; expected no more than %d for visible rows.',
    [lMetrics.VisibleItemProbeCount, lMaxProbeCount]));
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxPreparationInvalidatesWhenVisibleStateChanges;
var
  i: Integer;
  lForm: TForm;
  lItem: IRawElementProviderFragment;
  lListBox: TCheckListBox;
  lMetrics: TAccessibilityListBoxFocusMetrics;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragment;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableListBoxFocusMetrics;
  TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lListBox := TCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to 179 do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lListBox.ItemIndex := 0;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := lProvider.FragmentProvider;

    NavigateListBoxFirstChild(lRoot, lItem);
    NavigateListBoxFirstChild(lRoot, lItem);
    lListBox.TopIndex := 3;
    NavigateListBoxFirstChild(lRoot, lItem);
    lListBox.Height := lListBox.Height + 32;
    NavigateListBoxFirstChild(lRoot, lItem);
    lListBox.Items.Add('Client 0180');
    NavigateListBoxFirstChild(lRoot, lItem);
    lListBox.ItemIndex := 2;
    NavigateListBoxFirstChild(lRoot, lItem);

    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
    Assert.AreEqual(5, lMetrics.PrepareChildrenCount,
      'Listbox preparation should run once initially, skip the unchanged repeat, then run once per visible/focus state change.');
    Assert.IsTrue(lMetrics.VisibleItemProbeCount <= 120,
      Format('Listbox invalidation probe count was %d; expected no more than one visible pass per changed state.',
      [lMetrics.VisibleItemProbeCount]));
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  end;
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxRepeatedNavigationPreparationIsIdempotent;
var
  lMaxEnsureCount: Integer;
  lMaxProbeCount: Integer;
  lMetrics: TAccessibilityListBoxFocusMetrics;
begin
  RunCheckListBoxFocusScenario(180, lMetrics);

  lMaxProbeCount := 24;
  lMaxEnsureCount := 26;
  Assert.IsTrue(lMetrics.PrepareChildrenCount <= 2,
    Format('Listbox repeated unchanged navigation prepared children %d times; expected at most 2 real passes.',
    [lMetrics.PrepareChildrenCount]));
  Assert.IsTrue(lMetrics.VisibleItemProbeCount <= lMaxProbeCount,
    Format('Listbox repeated unchanged navigation inspected %d item rects; expected no more than %d.',
    [lMetrics.VisibleItemProbeCount, lMaxProbeCount]));
  Assert.IsTrue(lMetrics.EnsureItemProviderCount <= lMaxEnsureCount,
    Format('Listbox repeated unchanged navigation ensured %d item providers; expected no more than %d.',
    [lMetrics.EnsureItemProviderCount, lMaxEnsureCount]));
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxCachedFocusProviderAvoidsTextCleanup;
var
  i: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lItem: IRawElementProviderFragment;
  lListBox: TCheckListBox;
  lMetrics: TAccessibilityListBoxFocusMetrics;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableListBoxFocusMetrics;
  TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lListBox := TCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to 29 do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lListBox.ItemIndex := 0;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    NavigateListBoxFirstChild(lProvider.FragmentProvider, lItem);
    TAccessibilityDiagnostics.ResetListBoxFocusMetrics;

    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus, 'Cached focused listbox item provider was not returned.');

    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
    Assert.AreEqual(1, lMetrics.GetFocusCount);
    Assert.AreEqual(1, lMetrics.EnsureItemProviderCount);
    Assert.AreEqual(0, lMetrics.CreatedItemProviderCount);
    Assert.AreEqual(0, lMetrics.ItemTextProbeCount,
      'Cached focused listbox item provider should return without re-cleaning item text.');
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  end;
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxFocusMetricsAreGatedAndCaptureFocusPath;
var
  lApi: IAccessibilityUiaApi;
  lForm: TForm;
  lListBox: TCheckListBox;
  lMetrics: TAccessibilityListBoxFocusMetrics;
begin
  ResetManager;
  TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
  lApi := TListBoxPerformanceTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lListBox := TCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.Items.Add('Client 0001');
    lListBox.Items.Add('Client 0002');
    lListBox.Items.Add('Client 0003');
    lListBox.ItemIndex := 0;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;

    TAccessibilityManager.Install(lForm);
    lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);
    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
    Assert.IsFalse(lMetrics.Enabled);
    Assert.AreEqual(0, lMetrics.FocusMovementCount);

    TAccessibilityDiagnostics.EnableListBoxFocusMetrics;
    TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
    lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);
    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;

    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.FocusMovementCount);
    Assert.IsTrue(lMetrics.LastElapsedTicks > 0, 'Focus movement elapsed ticks were not captured.');
    Assert.IsTrue(lMetrics.AutomationEventCount > 0, 'Automation event count was not captured.');
    Assert.IsTrue(lMetrics.GetFocusCount > 0, 'Provider GetFocus count was not captured.');
    Assert.IsTrue(lMetrics.EnsureItemProviderCount > 0, 'Item provider ensure count was not captured.');
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityDiagnosticsTests);
  TDUnitX.RegisterTestFixture(TAccessibilityListBoxPerformanceTests);
  TDUnitX.RegisterTestFixture(TAccessibilityProviderHotspotPerformanceTests);

end.
