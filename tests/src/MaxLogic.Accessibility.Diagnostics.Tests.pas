unit MaxLogic.Accessibility.Diagnostics.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Diagnostics')]
  TAccessibilityDiagnosticsStartupTests = class
  public
    [Test]
    procedure DisabledDiagnosticsDoesNotStartWriterThread;
  end;

  [TestFixture]
  [Category('Diagnostics')]
  TAccessibilityDiagnosticsTests = class
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ConcurrentLogAndDisableDrainsWithoutDeadlock;
    [Test]
    procedure HotPathCallsDoNotWaitForConcurrentDisable;
    [Test]
    procedure EnabledDiagnosticsAppendTimestampedLinesToConfiguredLog;
    [Test]
    procedure LogFileIsBoundedAndReportsDroppedRecords;
    [Test]
    procedure LogFileWritesRunOnBackgroundThread;
    [Test]
    procedure QueueOverflowDropsRecordsWithoutWaitingForWriter;
    [Test]
    procedure ReconfigureTruncatesLogAndAllowsSharedReader;
  end;

  [TestFixture]
  [Category('ListBoxPerformance')]
  TAccessibilityListBoxPerformanceTests = class
  public
    [Test]
    procedure ListBoxNativeHwndNavigationDoesNotUseFrameworkNotificationPath;
    [Test]
    procedure CheckListBoxRapidFocusMovementUsesNativeHwndSpeechPath;
    [Test]
    procedure ListBoxPreparationScalesWithVisibleRows;
    [Test]
    procedure FixedHeightListBoxPreparationAvoidsItemRectProbes;
    [Test]
    procedure ListBoxPreparationInvalidatesWhenVisibleStateChanges;
    [Test]
    procedure ListBoxRepeatedNavigationDoesNotRequeryWindowItemHeight;
    [Test]
    procedure ListBoxNextSiblingNavigationValidatesWindowStateEveryCall;
    [Test]
    procedure ListBoxRepeatedNavigationPreparationIsIdempotent;
    [Test]
    procedure FixedHeightListBoxItemBoundsAvoidItemRectMessage;
    [Test]
    procedure ListBoxCachedFocusProviderAvoidsTextCleanup;
    [Test]
    procedure ListBoxPreparedItemNameUsesCachedText;
  end;

  [TestFixture]
  [Category('ProviderHotspotPerformance')]
  TAccessibilityProviderHotspotPerformanceTests = class
  public
    [Test]
    [Category('ListBoxPerformance')]
    procedure ListBoxProviderHotspotMetricsCaptureGetSelection;
    [Test]
    [Category('ListBoxPerformance')]
    procedure MultiSelectListBoxGetSelectionScalesWithSelectedItems;
    [Test]
    [Category('Memo')]
    procedure MemoProviderHotspotMetricsCapturePreparation;
    [Test]
    [Category('Memo')]
    procedure MemoSiblingNavigationReusesPreparedVisibleLines;
    [Test]
    [Category('Memo')]
    procedure MemoPreparationDoesNotScaleWithTotalMemoText;
    [Test]
    [Category('Memo')]
    procedure MemoPreparationDoesNotProbePastKnownLineCount;
    [Test]
    [Category('Memo')]
    procedure MemoPreparationUsesSingleLineCountAndSkipsCaretLineQuery;
    [Test]
    procedure ProviderBoundaryMetricsCaptureCoreUiaCallbacks;
    [Test]
    procedure ProviderHotspotMetricsCaptureSpeechTiming;
    [Test]
    [Category('StringGrid')]
    procedure StringGridProviderHotspotMetricsCaptureRefresh;
    [Test]
    [Category('StringGrid')]
    procedure StringGridCellBoundsReadsCellRectOnce;
    [Test]
    [Category('StringGrid')]
    procedure StringGridSiblingNavigationReusesPreparedVisibleCells;
    [Test]
    [Category('StringGrid')]
    procedure StringGridFocusQueryUsesPreparedVisibleCells;
    [Test]
    [Category('StringGrid')]
    procedure StringGridRowSelectHotspotMetricsStayVisibleRangeBounded;
    [Test]
    [Category('StringGrid')]
    procedure StringGridRowBoundsUsesVisibleColumnsOnly;
    [Test]
    [Category('StringGrid')]
    procedure StringGridRowTextUsesVisibleColumnsOnly;
    [Test]
    [Category('TmsAdvStringGrid')]
    procedure TmsAdvStringGridProviderHotspotMetricsCaptureRefresh;
    [Test]
    [Category('TmsAdvStringGrid')]
    procedure TmsAdvStringGridDirectChildEnumerationRefreshesVisibleCellsOnce;
    [Test]
    [Category('TmsAdvStringGrid')]
    procedure TmsAdvStringGridFocusQueryUsesPreparedVisibleCells;
    [Test]
    [Category('TmsAdvStringGrid')]
    procedure TmsAdvStringGridSiblingNavigationReusesPreparedVisibleCells;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.Generics.Collections, System.IOUtils, System.JSON, System.SyncObjs,
  System.SysUtils, Winapi.ActiveX, Winapi.Messages, Winapi.Windows, Vcl.CheckLst, Vcl.Controls, Vcl.Forms, Vcl.Grids,
  Vcl.StdCtrls, AdvGrid,
  MaxLogic.Accessibility.Diagnostics,
  MaxLogic.Accessibility.Manager, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.TmsAdvStringGridAdapters,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

type
  IListBoxPerformanceTestUiaApi = interface(IAccessibilityUiaApi)
    ['{BA3E7D6F-95C8-4C63-B132-46A234EAD7B3}']
    function LastNotificationProcessing: NotificationProcessing;
    function LastNotificationText: string;
  end;

  TListBoxPerformanceTestUiaApi = class(TInterfacedObject, IListBoxPerformanceTestUiaApi)
  private
    fLastNotificationProcessing: NotificationProcessing;
    fLastNotificationText: string;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastNotificationProcessing: NotificationProcessing;
    function LastNotificationText: string;
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

  TItemHeightProbeCheckListBox = class(TCheckListBox)
  private
    fItemHeightMessageCount: Integer;
    fItemRectMessageCount: Integer;
    fTopIndexMessageCount: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    property ItemHeightMessageCount: Integer read fItemHeightMessageCount write fItemHeightMessageCount;
    property ItemRectMessageCount: Integer read fItemRectMessageCount write fItemRectMessageCount;
    property TopIndexMessageCount: Integer read fTopIndexMessageCount write fTopIndexMessageCount;
  end;

  TLineProbeMemo = class(TMemo)
  private
    fGetLineCountMessageCount: Integer;
    fLineFromCharMessageCount: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    property GetLineCountMessageCount: Integer read fGetLineCountMessageCount write fGetLineCountMessageCount;
    property LineFromCharMessageCount: Integer read fLineFromCharMessageCount write fLineFromCharMessageCount;
  end;

  TDiagnosticsShutdownContentionProbe = class
  private
    fDisableDone: TEvent;
    fDisableStarted: TEvent;
    fDisableThread: TThread;
    fEnabled: Boolean;
    fLogFile: string;
    fProbeDone: TEvent;
    fProbeThread: TThread;
  public
    constructor Create;
    destructor Destroy; override;
  private
    procedure DisableDiagnostics;
    procedure ProbeHotPath;
  public
    function Execute: TWaitResult;
    property Enabled: Boolean read fEnabled;
  end;

constructor TDiagnosticsShutdownContentionProbe.Create;
begin
  inherited Create;
  fDisableDone := TEvent.Create(nil, True, False, '');
  fDisableStarted := TEvent.Create(nil, True, False, '');
  fLogFile := TPath.GetTempFileName;
  fProbeDone := TEvent.Create(nil, True, False, '');
end;

destructor TDiagnosticsShutdownContentionProbe.Destroy;
begin
  TAccessibilityDiagnosticsInternals.PauseLogWriter(False);
  if fDisableThread <> nil then
  begin
    fDisableDone.WaitFor(5000);
    fDisableThread.WaitFor;
  end;
  if fProbeThread <> nil then
  begin
    fProbeDone.WaitFor(5000);
    fProbeThread.WaitFor;
  end;
  fProbeThread.Free;
  fDisableThread.Free;
  fProbeDone.Free;
  fDisableStarted.Free;
  fDisableDone.Free;
  TAccessibilityDiagnostics.Disable;
  if TFile.Exists(fLogFile) then
  begin
    TFile.Delete(fLogFile);
  end;
  inherited Destroy;
end;

procedure TDiagnosticsShutdownContentionProbe.DisableDiagnostics;
begin
  fDisableStarted.SetEvent;
  TAccessibilityDiagnostics.Disable;
  fDisableDone.SetEvent;
end;

function TDiagnosticsShutdownContentionProbe.Execute: TWaitResult;
var
  lStartedAt: UInt64;
begin
  TAccessibilityDiagnosticsInternals.PauseLogWriter(True);
  TAccessibilityDiagnostics.Configure(fLogFile);
  TAccessibilityDiagnostics.Log('blocked shutdown probe');
  Assert.AreEqual(1, TAccessibilityDiagnosticsInternals.PendingLogRecordCount,
    'Test setup did not leave one record waiting for the paused writer.');

  fDisableThread := TThread.CreateAnonymousThread(DisableDiagnostics);
  fDisableThread.FreeOnTerminate := False;
  fDisableThread.Start;
  Assert.AreEqual(wrSignaled, fDisableStarted.WaitFor(5000), 'Diagnostics shutdown did not start.');
  lStartedAt := GetTickCount64;
  while TAccessibilityDiagnosticsInternals.WriterAcceptingRecords and ((GetTickCount64 - lStartedAt) < 5000) do
  begin
    Sleep(1);
  end;
  Assert.IsFalse(TAccessibilityDiagnosticsInternals.WriterAcceptingRecords,
    'Diagnostics shutdown did not disable record intake.');

  fProbeThread := TThread.CreateAnonymousThread(ProbeHotPath);
  fProbeThread.FreeOnTerminate := False;
  fProbeThread.Start;
  Result := fProbeDone.WaitFor(250);
end;

procedure TDiagnosticsShutdownContentionProbe.ProbeHotPath;
begin
  try
    fEnabled := TAccessibilityDiagnostics.Enabled;
    TAccessibilityDiagnostics.Log('shutdown contention probe');
  finally
    fProbeDone.SetEvent;
  end;
end;

function ReadSharedLogText(const aLogFile: string): string;
var
  lByteCount: Integer;
  lBytes: TBytes;
  lStream: TFileStream;
begin
  lStream := TFileStream.Create(aLogFile, fmOpenRead or fmShareDenyNone);
  try
    if lStream.Size > MaxInt then
    begin
      raise EStreamError.Create('Diagnostics test log is too large to read.');
    end;
    lByteCount := Integer(lStream.Size); //PALOFF STWA6 guarded by MaxInt range check
    SetLength(lBytes, lByteCount);
    if lByteCount > 0 then
    begin
      lStream.ReadBuffer(lBytes[0], lByteCount);
    end;
    Result := TEncoding.UTF8.GetString(lBytes);
  finally
    lStream.Free;
  end;
end;

function JsonIntValue(const aJson: string; const aName: string): Int64;
var
  lJson: TJSONObject;
  lValue: TJSONValue;
begin
  lJson := TJSONObject.ParseJSONValue(aJson) as TJSONObject;
  try
    Assert.IsNotNull(lJson, 'Metrics JSON is not an object.');
    lValue := lJson.GetValue(aName);
    Assert.IsNotNull(lValue, 'Missing metrics field: ' + aName);
    Result := StrToInt64(lValue.Value);
  finally
    lJson.Free;
  end;
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

function DirectChildProvider(const aProvider: IRawElementProviderSimple; aIndex: Integer;
  const aMessage: string): IRawElementProviderSimple;
var
  lAccess: IAccessibilityProviderChildAccess;
  lCount: Integer;
  lResult: HResult;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider, IAccessibilityProviderChildAccess, lAccess),
    aMessage + ' direct child access missing.');
  lResult := lAccess.DirectChildCount(lCount);
  Assert.IsTrue(lResult = S_OK, aMessage + ' direct child count failed.');
  Assert.IsTrue((aIndex >= 0) and (aIndex < lCount),
    Format('%s direct child index %d is outside count %d.', [aMessage, aIndex, lCount]));
  lResult := lAccess.DirectChildAt(aIndex, Result);
  Assert.IsTrue(lResult = S_OK, aMessage + ' direct child lookup failed.');
  Assert.IsNotNull(Result, aMessage + ' direct child lookup returned nil.');
end;

function DirectChildFragment(const aProvider: IRawElementProviderSimple; aIndex: Integer;
  const aMessage: string): IRawElementProviderFragment;
var
  lChild: IRawElementProviderSimple;
begin
  Result := nil;
  lChild := DirectChildProvider(aProvider, aIndex, aMessage);
  Assert.IsTrue(Supports(lChild, IRawElementProviderFragment, Result),
    aMessage + ' child fragment missing.');
end;

procedure RunCheckListBoxFocusScenario(aItemCount: Integer; aMoveCount: Integer;
  out aMetrics: TAccessibilityListBoxFocusMetrics; out aLastNotificationText: string;
  out aLastNotificationProcessing: NotificationProcessing; aResetAfterInstall: Boolean = True); overload;
var
  i: Integer;
  lApi: IListBoxPerformanceTestUiaApi;
  lForm: TForm;
  lListBox: TCheckListBox;
  lMoveIndex: Integer;
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
    if aResetAfterInstall then
    begin
      TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
    end;
    for lMoveIndex := 1 to aMoveCount do
    begin
      lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);
    end;
    aMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
    aLastNotificationText := lApi.LastNotificationText;
    aLastNotificationProcessing := lApi.LastNotificationProcessing;
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  end;
end;

procedure RunCheckListBoxFocusScenario(aItemCount: Integer; out aMetrics: TAccessibilityListBoxFocusMetrics); overload;
var
  lLastNotificationProcessing: NotificationProcessing;
  lLastNotificationText: string;
begin
  RunCheckListBoxFocusScenario(aItemCount, 1, aMetrics, lLastNotificationText, lLastNotificationProcessing);
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

    lMemoFragment := DirectChildFragment(lProvider.RawElementProvider, 0, 'Memo provider root');
    lLine := DirectChildFragment(SimpleProvider(lMemoFragment), 0, 'Memo provider line');
    Assert.IsNotNull(lLine, 'Memo provider line was not reachable from the memo provider.');
  finally
    lForm.Free;
  end;
end;

procedure ExerciseMemoSiblingNavigationHotspotProvider;
var
  i: Integer;
  lForm: TForm;
  lLine: IRawElementProviderFragment;
  lMemo: TMemo;
  lMemoFragment: IRawElementProviderFragment;
  lNavigateResult: HResult;
  lNextLine: IRawElementProviderFragment;
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

    lNavigateResult := lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lMemoFragment);
    Assert.IsTrue(lNavigateResult = S_OK, 'Memo provider root navigation failed.');
    Assert.IsNotNull(lMemoFragment, 'Memo provider was not reachable from the form root.');
    lNavigateResult := lMemoFragment.Navigate(NavigateDirection_FirstChild, lLine);
    Assert.IsTrue(lNavigateResult = S_OK, 'Memo provider line navigation failed.');
    for i := 1 to 4 do
    begin
      lNavigateResult := lLine.Navigate(NavigateDirection_NextSibling, lNextLine);
      Assert.IsTrue(lNavigateResult = S_OK, 'Memo provider next-line navigation failed.');
      Assert.IsNotNull(lNextLine, 'Memo provider should expose enough prepared visible lines.');
      lLine := lNextLine;
    end;
  finally
    lForm.Free;
  end;
end;

function MeasureMemoPreparationMetrics(aLineCount: Integer;
  aLineLength: Integer): TAccessibilityProviderHotspotMetrics;
var
  i: Integer;
  lForm: TForm;
  lLine: IRawElementProviderFragment;
  lMemo: TMemo;
  lMemoFragment: IRawElementProviderFragment;
  lNavigateResult: HResult;
  lPayload: string;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lMemo := TMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.WordWrap := False;
    lMemo.SetBounds(16, 16, 280, 120);
    lPayload := StringOfChar('x', aLineLength);
    for i := 0 to Pred(aLineCount) do
    begin
      lMemo.Lines.Add(IntToStr(i) + ' ' + lPayload);
    end;
    lForm.HandleNeeded;
    lMemo.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lNavigateResult := lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lMemoFragment);
    Assert.IsTrue(lNavigateResult = S_OK, 'Memo provider root navigation failed.');
    Assert.IsNotNull(lMemoFragment, 'Memo provider was not reachable from the form root.');
    lNavigateResult := lMemoFragment.Navigate(NavigateDirection_FirstChild, lLine);
    Assert.IsTrue(lNavigateResult = S_OK, 'Memo provider line navigation failed.');

    Result := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.AreEqual(1, Result.MemoPrepareChildrenCount);
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

procedure ExerciseStringGridCellBoundsHotspotProvider;
var
  lBounds: UiaRect;
  lCell: IRawElementProviderSimple;
  lCellFragment: IRawElementProviderFragment;
  lCol: Integer;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lPattern: IUnknown;
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
    lGrid.Col := 1;
    lGrid.Row := 1;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lGridFragment));
    Assert.IsNotNull(lGridFragment);
    Assert.AreEqual(S_OK, SimpleProvider(lGridFragment).GetPatternProvider(UIA_GridPatternId, lPattern));
    Assert.IsTrue(Supports(lPattern, IGridProvider, lGridPattern));
    Assert.AreEqual(S_OK, lGridPattern.GetItem(1, 1, lCell));
    Assert.IsNotNull(lCell);
    Assert.IsTrue(Supports(lCell, IRawElementProviderFragment, lCellFragment));
    Assert.AreEqual(S_OK, lCellFragment.Get_BoundingRectangle(lBounds));
    Assert.IsTrue(lBounds.Width > 0, 'Cell provider bounds should include the visible cell.');
  finally
    lForm.Free;
  end;
end;

procedure ExerciseStringGridSiblingNavigationHotspotProvider;
var
  i: Integer;
  lCol: Integer;
  lCurrent: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lNavigateResult: HResult;
  lNext: IRawElementProviderFragment;
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
    lNavigateResult := lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lGridFragment);
    Assert.IsTrue(lNavigateResult = S_OK, 'StringGrid provider root navigation failed.');
    Assert.IsNotNull(lGridFragment, 'StringGrid provider was not reachable from the form root.');
    lNavigateResult := lGridFragment.Navigate(NavigateDirection_FirstChild, lCurrent);
    Assert.IsTrue(lNavigateResult = S_OK, 'StringGrid provider cell navigation failed.');
    Assert.IsNotNull(lCurrent, 'StringGrid provider did not expose prepared cells.');

    for i := 1 to 4 do
    begin
      lNavigateResult := lCurrent.Navigate(NavigateDirection_NextSibling, lNext);
      Assert.IsTrue(lNavigateResult = S_OK, 'StringGrid provider next-cell navigation failed.');
      Assert.IsNotNull(lNext, 'StringGrid provider should expose enough prepared visible cells.');
      lCurrent := lNext;
    end;
  finally
    lForm.Free;
  end;
end;

procedure ExerciseStringGridPreparedFocusHotspotProvider;
var
  lCol: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridRoot: IRawElementProviderFragmentRoot;
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
    lForm.ActiveControl := lGrid;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lGridFragment));
    Assert.IsNotNull(lGridFragment);
    Assert.IsTrue(Supports(lGridFragment, IRawElementProviderFragmentRoot, lGridRoot));

    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    Assert.AreEqual(S_OK, lGridRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
  finally
    lForm.Free;
  end;
end;

procedure ExerciseStringGridRowSelectHotspotProvider;
var
  lCol: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
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
    lGrid.Options := lGrid.Options + [goRowSelect];
    for lRow := 0 to Pred(lGrid.RowCount) do
    begin
      for lCol := 0 to Pred(lGrid.ColCount) do
      begin
        lGrid.Cells[lCol, lRow] := Format('R%d C%d', [lRow, lCol]);
      end;
    end;
    lGrid.Col := 2;
    lGrid.Row := 2;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.IsTrue(Supports(lProvider.RawElementProvider, IRawElementProviderFragmentRoot, lRoot));
    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
  finally
    lForm.Free;
  end;
end;

procedure ExerciseStringGridRowTextHotspotProvider;
var
  lCol: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lName: OleVariant;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lRow: Integer;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);
    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.SetBounds(8, 8, 180, 90);
    lGrid.ColCount := 80;
    lGrid.RowCount := 20;
    lGrid.FixedCols := 1;
    lGrid.FixedRows := 1;
    lGrid.DefaultColWidth := 55;
    lGrid.DefaultRowHeight := 20;
    lGrid.Options := lGrid.Options + [goRowSelect];
    for lRow := 0 to Pred(lGrid.RowCount) do
    begin
      for lCol := 0 to Pred(lGrid.ColCount) do
      begin
        lGrid.Cells[lCol, lRow] := Format('R%d C%d', [lRow, lCol]);
      end;
    end;
    lGrid.Col := 2;
    lGrid.Row := 2;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.IsTrue(Supports(lProvider.RawElementProvider, IRawElementProviderFragmentRoot, lRoot));
    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    Assert.AreEqual(S_OK, SimpleProvider(lFocus).GetPropertyValue(UIA_NamePropertyId, lName));
    Assert.Contains(string(lName), 'R2 C');
  finally
    lForm.Free;
  end;
end;

procedure ExerciseStringGridRowBoundsHotspotProvider;
var
  lBounds: UiaRect;
  lCol: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lRow: Integer;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);
    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.SetBounds(8, 8, 180, 90);
    lGrid.ColCount := 500;
    lGrid.RowCount := 20;
    lGrid.FixedCols := 1;
    lGrid.FixedRows := 1;
    lGrid.DefaultColWidth := 55;
    lGrid.DefaultRowHeight := 20;
    lGrid.Options := lGrid.Options + [goRowSelect];
    for lRow := 0 to Pred(lGrid.RowCount) do
    begin
      for lCol := 0 to Pred(lGrid.ColCount) do
      begin
        lGrid.Cells[lCol, lRow] := Format('R%d C%d', [lRow, lCol]);
      end;
    end;
    lGrid.Col := 2;
    lGrid.Row := 2;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;
    lForm.ActiveControl := lGrid;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.IsTrue(Supports(lProvider.RawElementProvider, IRawElementProviderFragmentRoot, lRoot));
    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    Assert.AreEqual(S_OK, lFocus.Get_BoundingRectangle(lBounds));
    Assert.IsTrue(lBounds.Width > 0, 'Row provider bounds should include visible row cells.');
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

procedure ExerciseTmsAdvStringGridPreparedFocusHotspotProvider;
var
  lCol: Integer;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridRoot: IRawElementProviderFragmentRoot;
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
    lForm.ActiveControl := lGrid;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lGridFragment));
    Assert.IsNotNull(lGridFragment);
    Assert.IsTrue(Supports(lGridFragment, IRawElementProviderFragmentRoot, lGridRoot));

    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    Assert.AreEqual(S_OK, lGridRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
  finally
    lForm.Free;
  end;
end;

procedure ExerciseTmsAdvStringGridDirectChildEnumerationHotspotProvider;
var
  i: Integer;
  lAccess: IAccessibilityProviderChildAccess;
  lChild: IRawElementProviderSimple;
  lChildCount: Integer;
  lCol: Integer;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
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
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lGridFragment));
    Assert.IsNotNull(lGridFragment);
    Assert.IsTrue(Supports(lGridFragment, IAccessibilityProviderChildAccess, lAccess));

    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    Assert.AreEqual(S_OK, lAccess.DirectChildCount(lChildCount));
    Assert.IsTrue(lChildCount > 1, 'TMS AdvStringGrid fixture should expose multiple visible cells.');
    for i := 0 to Pred(lChildCount) do
    begin
      lChild := nil;
      Assert.AreEqual(S_OK, lAccess.DirectChildAt(i, lChild));
      Assert.IsNotNull(lChild);
    end;
  finally
    lForm.Free;
  end;
end;

procedure ExerciseTmsAdvStringGridSiblingNavigationHotspotProvider;
var
  i: Integer;
  lCol: Integer;
  lCurrent: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lNext: IRawElementProviderFragment;
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
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lGridFragment));
    Assert.IsNotNull(lGridFragment);
    Assert.AreEqual(S_OK, lGridFragment.Navigate(NavigateDirection_FirstChild, lCurrent));
    Assert.IsNotNull(lCurrent);

    for i := 1 to 4 do
    begin
      lNext := nil;
      Assert.AreEqual(S_OK, lCurrent.Navigate(NavigateDirection_NextSibling, lNext));
      Assert.IsNotNull(lNext, 'TMS AdvStringGrid should expose enough visible cell siblings.');
      lCurrent := lNext;
    end;
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
  lResult: HResult;
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
    lListBoxFragment := DirectChildFragment(lProvider.RawElementProvider, 0, 'Listbox provider root');
    lResult := SimpleProvider(lListBoxFragment).GetPatternProvider(UIA_SelectionPatternId, lPattern);
    Assert.IsTrue(lResult = S_OK, 'Listbox selection pattern lookup failed.');
    Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelection));
    lSelectionArray := nil;
    lResult := lSelection.GetSelection(lSelectionArray);
    Assert.IsTrue(lResult = S_OK, 'Listbox selection query failed.');
    if lSelectionArray <> nil then
    begin
      SafeArrayDestroy(lSelectionArray);
    end;
  finally
    lForm.Free;
  end;
end;

procedure ExerciseMultiSelectListBoxSelectionHotspotProvider;
const
  cSelectedIndexes: array[0..2] of Integer = (7, 199, 389);
var
  i: Integer;
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lResult: HResult;
  lSelection: ISelectionProvider;
  lSelectionArray: PSafeArray;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.MultiSelect := True;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to 399 do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lForm.HandleNeeded;
    lListBox.HandleNeeded;

    for i := Low(cSelectedIndexes) to High(cSelectedIndexes) do
    begin
      lListBox.Selected[cSelectedIndexes[i]] := True;
    end;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lResult := lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lListBoxFragment);
    Assert.IsTrue(lResult = S_OK, 'Multi-select listbox provider root navigation failed.');
    Assert.IsNotNull(lListBoxFragment, 'Multi-select listbox provider was not reachable from the form root.');
    lResult := SimpleProvider(lListBoxFragment).GetPatternProvider(UIA_SelectionPatternId, lPattern);
    Assert.IsTrue(lResult = S_OK, 'Multi-select listbox selection pattern lookup failed.');
    Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelection));
    lSelectionArray := nil;
    lResult := lSelection.GetSelection(lSelectionArray);
    Assert.IsTrue(lResult = S_OK, 'Multi-select listbox selection query failed.');
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
  lResult: HResult;
begin
  aItem := nil;
  lListBox := nil;
  lResult := aRoot.Navigate(NavigateDirection_FirstChild, lListBox);
  Assert.IsTrue(lResult = S_OK, 'Listbox root navigation failed.');
  Assert.IsNotNull(lListBox, 'Listbox provider was not reachable from the form root.');
  lResult := lListBox.Navigate(NavigateDirection_FirstChild, aItem);
  Assert.IsTrue(lResult = S_OK, 'Listbox first item navigation failed.');
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

function TListBoxPerformanceTestUiaApi.LastNotificationProcessing: NotificationProcessing;
begin
  Result := fLastNotificationProcessing;
end;

function TListBoxPerformanceTestUiaApi.LastNotificationText: string;
begin
  Result := fLastNotificationText;
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
  fLastNotificationProcessing := aNotificationProcessing;
  fLastNotificationText := aDisplayString;
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

procedure TItemHeightProbeCheckListBox.WndProc(var aMessage: TMessage);
begin
  if aMessage.Msg = LB_GETITEMHEIGHT then
  begin
    Inc(fItemHeightMessageCount);
  end else if aMessage.Msg = LB_GETITEMRECT then
  begin
    Inc(fItemRectMessageCount);
  end else if aMessage.Msg = LB_GETTOPINDEX then
  begin
    Inc(fTopIndexMessageCount);
  end;

  inherited WndProc(aMessage);
end;

procedure TLineProbeMemo.WndProc(var aMessage: TMessage);
begin
  if aMessage.Msg = EM_GETLINECOUNT then
  begin
    Inc(fGetLineCountMessageCount);
  end else if aMessage.Msg = EM_LINEFROMCHAR then
  begin
    Inc(fLineFromCharMessageCount);
  end;

  inherited WndProc(aMessage);
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
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.FlushLog(5000), 'Diagnostics did not become idle.');

    Assert.IsTrue(TFile.Exists(lLogFile), 'Diagnostics did not create a log file.');
    lLogText := ReadSharedLogText(lLogFile);
    Assert.Contains(lLogText, 'diagnostic probe message');
    Assert.Contains(lLogText, 'T');
  finally
    TAccessibilityDiagnostics.Disable;
    if TFile.Exists(lLogFile) then
    begin
      TFile.Delete(lLogFile);
    end;
  end;
end;

procedure TAccessibilityDiagnosticsTests.ConcurrentLogAndDisableDrainsWithoutDeadlock;
const
  cLogCount = 400;
var
  lDone: TEvent;
  lLogFile: string;
  lStarted: TEvent;
  lThread: TThread;
begin
  lDone := TEvent.Create(nil, True, False, '');
  lLogFile := TPath.GetTempFileName;
  lStarted := TEvent.Create(nil, True, False, '');
  lThread := nil;
  try
    TAccessibilityDiagnostics.Configure(lLogFile);
    lThread := TThread.CreateAnonymousThread(
      procedure
      var
        i: Integer;
      begin
        try
          lStarted.SetEvent;
          for i := 1 to cLogCount do
          begin
            TAccessibilityDiagnostics.Log('concurrent shutdown probe');
          end;
        finally
          lDone.SetEvent;
        end;
      end);
    lThread.FreeOnTerminate := False;
    lThread.Start;
    Assert.AreEqual(wrSignaled, lStarted.WaitFor(5000), 'Diagnostics producer did not start.');

    TAccessibilityDiagnostics.Disable;

    Assert.AreEqual(wrSignaled, lDone.WaitFor(5000), 'Diagnostics producer did not finish after Disable.');
    lThread.WaitFor;
    Assert.AreEqual(0, TAccessibilityDiagnosticsInternals.PendingLogRecordCount,
      'Disable returned with queued diagnostics records.');
    Assert.IsFalse(TAccessibilityDiagnostics.Enabled, 'Disable left diagnostics enabled.');
  finally
    lThread.Free;
    lStarted.Free;
    lDone.Free;
    TAccessibilityDiagnostics.Disable;
    if TFile.Exists(lLogFile) then
    begin
      TFile.Delete(lLogFile);
    end;
  end;
end;

procedure TAccessibilityDiagnosticsTests.HotPathCallsDoNotWaitForConcurrentDisable;
var
  lProbe: TDiagnosticsShutdownContentionProbe;
  lProbeWaitResult: TWaitResult;
begin
  lProbe := TDiagnosticsShutdownContentionProbe.Create;
  try
    lProbeWaitResult := lProbe.Execute;

    Assert.AreEqual(wrSignaled, lProbeWaitResult,
      'Diagnostics hot-path calls waited for shutdown file I/O.');
    Assert.IsFalse(lProbe.Enabled, 'Diagnostics remained enabled after concurrent shutdown started.');
  finally
    lProbe.Free;
  end;
end;

procedure TAccessibilityDiagnosticsStartupTests.DisabledDiagnosticsDoesNotStartWriterThread;
begin
  TAccessibilityDiagnostics.Disable;
  Assert.IsFalse(TAccessibilityDiagnosticsInternals.WriterStarted,
    'Disabled diagnostics must not create a polling background thread.');
end;

procedure TAccessibilityDiagnosticsTests.LogFileIsBoundedAndReportsDroppedRecords;
const
  cMaximumBytes = 1024;
var
  lLogFile: string;
begin
  lLogFile := TPath.GetTempFileName;
  try
    TAccessibilityDiagnosticsInternals.SetMaximumLogBytes(cMaximumBytes);
    TAccessibilityDiagnostics.Configure(lLogFile);
    TAccessibilityDiagnostics.Log(StringOfChar('x', cMaximumBytes * 2));
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.FlushLog(5000), 'Diagnostics did not become idle.');

    Assert.IsTrue(TFile.GetSize(lLogFile) <= cMaximumBytes, 'Diagnostics log exceeded its configured bound.');
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.DroppedLogRecordCount > 0,
      'Diagnostics did not report the record dropped at the file-size bound.');
    Assert.Contains(ReadSharedLogText(lLogFile), 'Diagnostics dropped 1 record(s)',
      'Diagnostics log did not report the file-size drop.');
  finally
    TAccessibilityDiagnostics.Disable;
    if TFile.Exists(lLogFile) then
    begin
      TFile.Delete(lLogFile);
    end;
  end;
end;

procedure TAccessibilityDiagnosticsTests.LogFileWritesRunOnBackgroundThread;
var
  lCallerThreadId: Cardinal;
  lLogFile: string;
  lWriterThreadId: Cardinal;
begin
  lLogFile := TPath.GetTempFileName;
  try
    TAccessibilityDiagnostics.Configure(lLogFile);
    lCallerThreadId := GetCurrentThreadId;
    TAccessibilityDiagnostics.Log('background writer probe');
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.FlushLog(5000), 'Diagnostics did not become idle.');
    lWriterThreadId := TAccessibilityDiagnosticsInternals.LogFileWriteThreadId;

    Assert.IsTrue(lWriterThreadId <> 0, 'Diagnostics did not record a filesystem writer thread.');
    Assert.AreNotEqual(lCallerThreadId, lWriterThreadId,
      'Diagnostics filesystem writes must not run on the caller thread.');
  finally
    TAccessibilityDiagnostics.Disable;
    if TFile.Exists(lLogFile) then
    begin
      TFile.Delete(lLogFile);
    end;
  end;
end;

procedure TAccessibilityDiagnosticsTests.QueueOverflowDropsRecordsWithoutWaitingForWriter;
var
  i: Integer;
  lCapacity: Integer;
  lLogFile: string;
begin
  lLogFile := TPath.GetTempFileName;
  TAccessibilityDiagnosticsInternals.PauseLogWriter(True);
  try
    TAccessibilityDiagnostics.Configure(lLogFile);
    lCapacity := TAccessibilityDiagnosticsInternals.QueueCapacity;
    for i := 0 to Succ(lCapacity) do
    begin
      TAccessibilityDiagnostics.Log('bounded queue probe');
    end;

    Assert.IsTrue(TAccessibilityDiagnosticsInternals.PendingLogRecordCount <= Succ(lCapacity),
      'Diagnostics retained more records than the bounded queue permits.');
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.DroppedLogRecordCount > 0,
      'A full diagnostics queue must drop records instead of waiting for the writer.');
    TAccessibilityDiagnosticsInternals.PauseLogWriter(False);
    Assert.IsTrue(TAccessibilityDiagnosticsInternals.FlushLog(5000), 'Diagnostics did not drain after resuming.');
    Assert.Contains(ReadSharedLogText(lLogFile), 'Diagnostics dropped ',
      'Diagnostics log did not report the queue-overflow drop.');
  finally
    TAccessibilityDiagnosticsInternals.PauseLogWriter(False);
    TAccessibilityDiagnostics.Disable;
    if TFile.Exists(lLogFile) then
    begin
      TFile.Delete(lLogFile);
    end;
  end;
end;

procedure TAccessibilityDiagnosticsTests.ReconfigureTruncatesLogAndAllowsSharedReader;
var
  lLogFile: string;
  lLogText: string;
  lReader: TFileStream;
begin
  lLogFile := TPath.GetTempFileName;
  try
    TFile.WriteAllText(lLogFile, 'previous run', TEncoding.UTF8);
    TAccessibilityDiagnostics.Configure(lLogFile);
    lReader := TFileStream.Create(lLogFile, fmOpenRead or fmShareDenyNone);
    try
      TAccessibilityDiagnostics.Log('current run');
      Assert.IsTrue(TAccessibilityDiagnosticsInternals.FlushLog(5000), 'Diagnostics did not become idle.');
    finally
      lReader.Free;
    end;

    lLogText := ReadSharedLogText(lLogFile);
    Assert.DoesNotContain(lLogText, 'previous run');
    Assert.Contains(lLogText, 'current run');
  finally
    TAccessibilityDiagnostics.Disable;
    if TFile.Exists(lLogFile) then
    begin
      TFile.Delete(lLogFile);
    end;
  end;
end;

procedure TAccessibilityDiagnosticsTests.TearDown;
begin
  TAccessibilityDiagnosticsInternals.PauseLogWriter(False);
  TAccessibilityDiagnostics.Disable;
  Assert.AreEqual(0, TAccessibilityDiagnosticsInternals.PendingLogRecordCount,
    'Diagnostics teardown left queued records.');
  TAccessibilityDiagnosticsInternals.SetMaximumLogBytes(0);
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
    Assert.AreEqual(0, lMetrics.ListBoxSelectionProviderListAllocationCount,
      'Single-select listbox GetSelection should avoid a transient provider-list allocation.');
    Assert.IsTrue(lMetrics.ListBoxGetSelectionLastElapsedTicks > 0,
      'Listbox GetSelection elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.MultiSelectListBoxGetSelectionScalesWithSelectedItems;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseMultiSelectListBoxSelectionHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.ListBoxGetSelectionCount);
    Assert.AreEqual(3, lMetrics.ListBoxSelectionProviderCount);
    Assert.IsTrue(lMetrics.ListBoxSelectionItemProbeCount <= 3,
      Format('Multi-select listbox GetSelection probed %d items for 3 selected rows; expected selected-index work.',
      [lMetrics.ListBoxSelectionItemProbeCount]));
    Assert.AreEqual(0, lMetrics.ListBoxSelectionProviderListAllocationCount,
      'Multi-select listbox GetSelection should fill the selection SAFEARRAY without a transient provider-list allocation.');
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
      Format('Memo line probe count was %d; expected preparation to stay within visible lines.',
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

procedure TAccessibilityProviderHotspotPerformanceTests.MemoSiblingNavigationReusesPreparedVisibleLines;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseMemoSiblingNavigationHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.MemoPrepareChildrenCount,
      'Memo next-sibling navigation should reuse the prepared visible line snapshot.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.MemoPreparationDoesNotScaleWithTotalMemoText;
const
  cLargeLineCount = 2500;
  cLargeLineLength = 512;
  cSmallLineCount = 40;
  cSmallLineLength = 24;
var
  lLargeMetrics: TAccessibilityProviderHotspotMetrics;
  lSmallMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  try
    lSmallMetrics := MeasureMemoPreparationMetrics(cSmallLineCount, cSmallLineLength);
    lLargeMetrics := MeasureMemoPreparationMetrics(cLargeLineCount, cLargeLineLength);

    Assert.AreEqual(lSmallMetrics.MemoLineProbeCount, lLargeMetrics.MemoLineProbeCount,
      'Memo preparation should probe the same visible-line count regardless of total memo text.');
    Assert.AreEqual(lSmallMetrics.MemoLineProviderCreatedCount, lLargeMetrics.MemoLineProviderCreatedCount,
      'Memo preparation should create the same visible provider count regardless of total memo text.');
    Assert.IsTrue(lLargeMetrics.MemoLineProbeCount <= 12,
      Format('Large memo preparation probed %d lines; expected visible-line-bounded work.',
      [lLargeMetrics.MemoLineProbeCount]));
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.MemoPreparationDoesNotProbePastKnownLineCount;
var
  lForm: TForm;
  lLine: IRawElementProviderFragment;
  lMemo: TMemo;
  lMemoFragment: IRawElementProviderFragment;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProvider: IAccessibilityProviderNode;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    lForm := TForm.Create(nil);
    try
      lForm.SetBounds(100, 100, 420, 520);
      lMemo := TMemo.Create(lForm);
      lMemo.Parent := lForm;
      lMemo.WordWrap := False;
      lMemo.SetBounds(16, 16, 320, 420);
      lMemo.Text := 'Memo short line 0000'#13#10'Memo short line 0001'#13#10'Memo short line 0002';
      lForm.HandleNeeded;
      lMemo.HandleNeeded;
      lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

      lMemoFragment := DirectChildFragment(lProvider.RawElementProvider, 0, 'Short memo provider root');
      lLine := DirectChildFragment(SimpleProvider(lMemoFragment), 0, 'Short memo provider line');
      Assert.IsNotNull(lLine);

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.IsTrue(lMetrics.Enabled);
      Assert.AreEqual(1, lMetrics.MemoPrepareChildrenCount);
      Assert.AreEqual(3, lMetrics.MemoLineProbeCount,
        Format('Memo preparation probed %d candidate lines for a 3-line memo; expected no probes past EM_GETLINECOUNT.',
        [lMetrics.MemoLineProbeCount]));
      Assert.AreEqual(3, lMetrics.MemoLineProviderCreatedCount);
    finally
      lForm.Free;
    end;
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.MemoPreparationUsesSingleLineCountAndSkipsCaretLineQuery;
const
  cLineCount = 2500;
  cLineLength = 256;
var
  i: Integer;
  lForm: TForm;
  lLine: IRawElementProviderFragment;
  lMemo: TLineProbeMemo;
  lMemoFragment: IRawElementProviderFragment;
  lPayload: string;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 240);
    lMemo := TLineProbeMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.WordWrap := False;
    lMemo.SetBounds(16, 16, 320, 120);
    lPayload := StringOfChar('x', cLineLength);
    for i := 0 to Pred(cLineCount) do
    begin
      lMemo.Lines.Add(IntToStr(i) + ' ' + lPayload);
    end;
    lForm.HandleNeeded;
    lMemo.HandleNeeded;
    lMemo.SelStart := Length(lMemo.Text);
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    lMemo.GetLineCountMessageCount := 0;
    lMemo.LineFromCharMessageCount := 0;

    lMemoFragment := DirectChildFragment(lProvider.RawElementProvider, 0, 'Probe memo provider root');
    lLine := DirectChildFragment(SimpleProvider(lMemoFragment), 0, 'Probe memo provider line');
    Assert.IsNotNull(lLine);

    Assert.AreEqual(1, lMemo.GetLineCountMessageCount,
      Format('Memo preparation asked for line count %d times; expected one native line-count read.',
      [lMemo.GetLineCountMessageCount]));
    Assert.AreEqual(0, lMemo.LineFromCharMessageCount,
      Format('Memo preparation asked for caret line %d times; visible-line preparation should not query off-screen caret.',
      [lMemo.LineFromCharMessageCount]));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.ProviderBoundaryMetricsCaptureCoreUiaCallbacks;
var
  lBounds: UiaRect;
  lChild: IAccessibilityProviderNode;
  lFragment: IRawElementProviderFragment;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lOptions: ProviderOptions;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lJson: string;
  lRoot: IRawElementProviderFragmentRoot;
  lRuntimeId: PSafeArray;
  lSimple: IRawElementProviderSimple;
  lValue: OleVariant;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  lRuntimeId := nil;
  try
    lProvider := TAccessibilityProviderFactory.CreateRoot([100], 0);
    lProvider.SetProperty(UIA_NamePropertyId, 'Root');
    lChild := TAccessibilityProviderFactory.CreateFragment([101]);
    lProvider.AddChild(lChild);
    lSimple := lProvider.RawElementProvider;
    Assert.AreEqual(S_OK, lSimple.Get_ProviderOptions(lOptions));
    Assert.AreEqual(S_OK, lSimple.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.AreEqual(S_OK, lSimple.GetPatternProvider(UIA_InvokePatternId, lPattern));
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.GetRuntimeId(lRuntimeId));
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Get_BoundingRectangle(lBounds));
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Get_FragmentRoot(lRoot));
    Assert.AreEqual(S_OK, lProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, lFragment));

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.ProviderGetProviderOptionsCount);
    Assert.AreEqual(1, lMetrics.ProviderGetPropertyValueCount);
    Assert.AreEqual(1, lMetrics.ProviderGetPatternProviderCount);
    Assert.AreEqual(1, lMetrics.ProviderGetRuntimeIdCount);
    Assert.AreEqual(1, lMetrics.ProviderGetBoundingRectangleCount);
    Assert.AreEqual(1, lMetrics.ProviderGetFragmentRootCount);
    Assert.AreEqual(1, lMetrics.ProviderNavigateCount);
    Assert.IsTrue(lMetrics.ProviderBoundaryTotalElapsedTicks > 0);
    Assert.IsTrue(lMetrics.ProviderGetPropertyValueTotalElapsedTicks > 0);
    lJson := lMetrics.ToJson('provider-boundary-timing-fixture', 'Accessibility-Framework');
    Assert.Contains(lJson, '"providerGetPropertyValueTotalElapsedTicks":');
  finally
    if lRuntimeId <> nil then
    begin
      SafeArrayDestroy(lRuntimeId);
    end;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.ProviderHotspotMetricsCaptureSpeechTiming;
var
  lApi: IListBoxPerformanceTestUiaApi;
  lEdit: TEdit;
  lForm: TForm;
  lJson: string;
  lProvider: IAccessibilityProviderNode;
begin
  ResetManager;
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  lApi := TListBoxPerformanceTestUiaApi.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lForm := TForm.Create(nil);
  try
    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.Text := 'Alice';
    lEdit.Hint := 'Search current orders';
    lEdit.HandleNeeded;

    TAccessibilityManager.Install(lForm);
    lEdit.Perform(CM_ENTER, 0, 0);

    lProvider := TAccessibilityProviderFactory.CreateRoot([9001], 0);
    Assert.IsTrue(TAccessibilityProviderEvents.RaiseNotification(lProvider.RawElementProvider,
      NotificationKind_Other, NotificationProcessing_MostRecent, 'Probe', 'diagnostics-test', lApi));

    lJson := TAccessibilityDiagnostics.ProviderHotspotMetrics.ToJson('speech-timing-fixture',
      'Accessibility-Framework');
    Assert.AreEqual(Int64(1), JsonIntValue(lJson, 'providerFocusAnnouncementTextCount'));
    Assert.IsTrue(JsonIntValue(lJson, 'providerFocusAnnouncementTextLastElapsedTicks') > 0,
      'Focus announcement text timing should identify whether speech text construction is slow.');
    Assert.IsTrue(JsonIntValue(lJson, 'providerFocusAnnouncementTextTotalElapsedTicks') > 0,
      'Focus announcement total timing should accumulate speech text construction cost.');
    Assert.AreEqual(Int64(2), JsonIntValue(lJson, 'providerNotificationCount'));
    Assert.IsTrue(JsonIntValue(lJson, 'providerNotificationLastElapsedTicks') > 0,
      'Notification timing should identify whether UIA event dispatch is slow.');
    Assert.IsTrue(JsonIntValue(lJson, 'providerNotificationTotalElapsedTicks') > 0,
      'Notification total timing should accumulate UIA event dispatch cost.');
  finally
    lForm.Free;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    ResetManager;
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
    Assert.IsTrue(lMetrics.StringGridCellProbeCount <= 24,
      Format('StringGrid cell probe count was %d; expected visible-range refresh instead of full 12x80 scan.',
      [lMetrics.StringGridCellProbeCount]));
    Assert.AreEqual(0, lMetrics.StringGridRefreshScratchListAllocationCount,
      'StringGrid refresh should not allocate scratch row/column lists on the speech-navigation path.');
    Assert.IsTrue(lMetrics.ActiveVisibleTreeProbeCount <= 2,
      Format('StringGrid refresh checked active visibility %d times; expected one refresh-level check plus snapshot remember.',
      [lMetrics.ActiveVisibleTreeProbeCount]));
    Assert.IsTrue(lMetrics.StringGridCellProviderCreatedCount > 0, 'StringGrid cell provider creation was not captured.');
    Assert.IsTrue(lMetrics.StringGridRefreshLastElapsedTicks > 0,
      'StringGrid refresh elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.StringGridCellBoundsReadsCellRectOnce;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseStringGridCellBoundsHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.StringGridCellBoundsBuildCount);
    Assert.AreEqual(1, lMetrics.StringGridCellBoundsCellProbeCount,
      Format('StringGrid cell bounds probed %d cells; expected one visible CellRect read.',
      [lMetrics.StringGridCellBoundsCellProbeCount]));
    Assert.IsTrue(lMetrics.StringGridCellBoundsLastElapsedTicks > 0,
      'StringGrid cell bounds elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.StringGridSiblingNavigationReusesPreparedVisibleCells;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseStringGridSiblingNavigationHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.StringGridRefreshCount,
      'StringGrid next-sibling navigation should reuse the prepared visible cell snapshot.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.StringGridFocusQueryUsesPreparedVisibleCells;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseStringGridPreparedFocusHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(0, lMetrics.StringGridRefreshCount,
      'StringGrid focus queries should reuse the prepared visible-cell snapshot when it is still current.');
    Assert.AreEqual(0, lMetrics.StringGridCellProbeCount,
      'StringGrid focus queries should not reprobe visible cells when the focused cell is already prepared.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.StringGridRowSelectHotspotMetricsStayVisibleRangeBounded;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseStringGridRowSelectHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.StringGridRowRefreshCount);
    Assert.IsTrue(lMetrics.StringGridRowProbeCount <= 12,
      Format('StringGrid row-select refresh probed %d rows; expected visible-range refresh instead of full row scan.',
      [lMetrics.StringGridRowProbeCount]));
    Assert.AreEqual(0, lMetrics.StringGridRowRefreshScratchListAllocationCount,
      'StringGrid row-select refresh should not allocate scratch row lists on the speech-navigation path.');
    Assert.IsTrue(lMetrics.StringGridRowProviderCreatedCount > 0,
      'StringGrid row provider creation was not captured.');
    Assert.IsTrue(lMetrics.StringGridRowRefreshLastElapsedTicks > 0,
      'StringGrid row refresh elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.StringGridRowTextUsesVisibleColumnsOnly;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseStringGridRowTextHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.StringGridRowTextBuildCount);
    Assert.IsTrue(lMetrics.StringGridRowTextCellProbeCount <= 8,
      Format('StringGrid row text probed %d cells; expected fixed plus visible columns only.',
      [lMetrics.StringGridRowTextCellProbeCount]));
    Assert.IsTrue(lMetrics.StringGridRowTextHeaderProbeCount <= lMetrics.StringGridRowTextCellProbeCount,
      'StringGrid row text header probes must stay within the visible cell probe count.');
    Assert.IsTrue(lMetrics.StringGridRowTextLastElapsedTicks > 0,
      'StringGrid row text elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.StringGridRowBoundsUsesVisibleColumnsOnly;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseStringGridRowBoundsHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.StringGridRowBoundsBuildCount);
    Assert.IsTrue(lMetrics.StringGridRowBoundsCellProbeCount <= 8,
      Format('StringGrid row bounds probed %d cells; expected fixed plus visible columns only.',
      [lMetrics.StringGridRowBoundsCellProbeCount]));
    Assert.IsTrue(lMetrics.StringGridRowBoundsLastElapsedTicks > 0,
      'StringGrid row bounds elapsed ticks were not captured.');
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
    Assert.IsTrue(lMetrics.TmsAdvStringGridCellProbeCount <= 24,
      Format('TMS AdvStringGrid cell probe count was %d; expected visible-range refresh instead of full 12x80 scan.',
      [lMetrics.TmsAdvStringGridCellProbeCount]));
    Assert.AreEqual(0, lMetrics.TmsAdvStringGridRefreshScratchListAllocationCount,
      'TMS AdvStringGrid refresh should not allocate scratch row/column lists on the speech-navigation path.');
    Assert.IsTrue(lMetrics.ActiveVisibleTreeProbeCount <= 2,
      Format('TMS AdvStringGrid refresh checked active visibility %d times; expected one refresh-level check plus snapshot remember.',
      [lMetrics.ActiveVisibleTreeProbeCount]));
    Assert.IsTrue(lMetrics.TmsAdvStringGridCellProviderCreatedCount > 0,
      'TMS AdvStringGrid cell provider creation was not captured.');
    Assert.IsTrue(lMetrics.TmsAdvStringGridRefreshLastElapsedTicks > 0,
      'TMS AdvStringGrid refresh elapsed ticks were not captured.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.TmsAdvStringGridDirectChildEnumerationRefreshesVisibleCellsOnce;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseTmsAdvStringGridDirectChildEnumerationHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.IsTrue(lMetrics.TmsAdvStringGridRefreshCount <= 1,
      Format('TMS AdvStringGrid direct-child enumeration refreshed visible cells %d times; expected at most one refresh.',
      [lMetrics.TmsAdvStringGridRefreshCount]));
    Assert.IsTrue(lMetrics.TmsAdvStringGridCellProbeCount <= 24,
      Format('TMS AdvStringGrid direct-child enumeration probed %d cells; expected one visible-range refresh.',
      [lMetrics.TmsAdvStringGridCellProbeCount]));
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.TmsAdvStringGridFocusQueryUsesPreparedVisibleCells;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseTmsAdvStringGridPreparedFocusHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(0, lMetrics.TmsAdvStringGridRefreshCount,
      'TMS AdvStringGrid focus queries should reuse the prepared visible-cell snapshot when it is still current.');
    Assert.AreEqual(0, lMetrics.TmsAdvStringGridCellProbeCount,
      'TMS AdvStringGrid focus queries should not reprobe visible cells when the focused cell is already prepared.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityProviderHotspotPerformanceTests.TmsAdvStringGridSiblingNavigationReusesPreparedVisibleCells;
var
  lMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
  TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
  try
    ExerciseTmsAdvStringGridSiblingNavigationHotspotProvider;

    lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(1, lMetrics.TmsAdvStringGridRefreshCount,
      'TMS AdvStringGrid next-sibling navigation should reuse the prepared visible cell snapshot.');
  finally
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

procedure TAccessibilityListBoxPerformanceTests.CheckListBoxRapidFocusMovementUsesNativeHwndSpeechPath;
var
  lLastNotificationProcessing: NotificationProcessing;
  lLastNotificationText: string;
  lMetrics: TAccessibilityListBoxFocusMetrics;
begin
  RunCheckListBoxFocusScenario(90, 8, lMetrics, lLastNotificationText, lLastNotificationProcessing);

  Assert.AreEqual(0, lMetrics.FocusMovementCount);
  Assert.AreEqual(0, lMetrics.AutomationEventCount,
    'Listbox rapid focus movement should not raise extra custom provider focus/selection events.');
  Assert.AreEqual(0, lMetrics.SelectionEventCount);
  Assert.AreEqual(0, lMetrics.GetFocusCount,
    'Listbox rapid focus movement should not query the custom item provider to speak the focused item.');
  Assert.AreEqual(0, lMetrics.EnsureItemProviderCount,
    'Native-HWND listbox movement should not prepare custom item providers.');
  Assert.AreEqual(0, lMetrics.ItemTextProbeCount,
    'Listbox rapid focus movement should not clean text through provider item probes.');
  Assert.AreEqual(0, lMetrics.NotificationCount,
    'Native-HWND listbox movement should let native accessibility speak items without duplicate framework notifications.');
  Assert.IsTrue(lMetrics.NativeHandlePublicationCheckCount <= 1,
    Format('Listbox rapid focus movement checked native-handle publication %d times; expected at most one cached check.',
    [lMetrics.NativeHandlePublicationCheckCount]));
  Assert.AreEqual(0, lMetrics.GridFocusProbeCount,
    'Native-HWND listbox movement should not enter the grid focus-change probe path.');
  Assert.AreEqual(0, lMetrics.ItemIndexProbeCount,
    'Native-HWND listbox movement should not probe framework selection state for speech.');
  Assert.AreEqual(NotificationProcessing_ImportantAll, lLastNotificationProcessing);
  Assert.AreEqual('', lLastNotificationText);
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxPreparationScalesWithVisibleRows;
var
  lLastNotificationProcessing: NotificationProcessing;
  lLastNotificationText: string;
  lMaxProbeCount: Integer;
  lMetrics: TAccessibilityListBoxFocusMetrics;
begin
  RunCheckListBoxFocusScenario(180, 1, lMetrics, lLastNotificationText, lLastNotificationProcessing, False);

  Assert.IsTrue(lMetrics.PrepareChildrenCount > 0, 'Listbox child preparation was not measured.');
  lMaxProbeCount := lMetrics.PrepareChildrenCount * 24;
  Assert.IsTrue(lMetrics.VisibleItemProbeCount <= lMaxProbeCount,
    Format('Listbox preparation inspected %d item rects; expected no more than %d for visible rows.',
    [lMetrics.VisibleItemProbeCount, lMaxProbeCount]));
end;

procedure TAccessibilityListBoxPerformanceTests.FixedHeightListBoxPreparationAvoidsItemRectProbes;
var
  lLastNotificationProcessing: NotificationProcessing;
  lLastNotificationText: string;
  lMetrics: TAccessibilityListBoxFocusMetrics;
begin
  RunCheckListBoxFocusScenario(180, 1, lMetrics, lLastNotificationText, lLastNotificationProcessing, False);

  Assert.IsTrue(lMetrics.PrepareChildrenCount > 0, 'Listbox child preparation was not measured.');
  Assert.IsTrue(lMetrics.EnsureItemProviderCount > 0, 'Listbox child preparation did not create visible providers.');
  Assert.AreEqual(0, lMetrics.VisibleItemProbeCount,
    'Fixed-height listbox preparation should derive visible item indexes from TopIndex/ItemHeight/ClientHeight ' +
    'instead of calling ItemRect for every visible row.');
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
    lListBox.ItemIndex := 4;
    NavigateListBoxFirstChild(lRoot, lItem);

    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
    Assert.AreEqual(4, lMetrics.PrepareChildrenCount,
      'Listbox preparation should run once initially, skip unchanged/focus-only repeats, then run once per visible state change.');
    Assert.IsTrue(lMetrics.VisibleItemProbeCount <= 120,
      Format('Listbox invalidation probe count was %d; expected no more than one visible pass per changed state.',
      [lMetrics.VisibleItemProbeCount]));
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  end;
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxRepeatedNavigationDoesNotRequeryWindowItemHeight;
var
  i: Integer;
  lForm: TForm;
  lItem: IRawElementProviderFragment;
  lListBox: TItemHeightProbeCheckListBox;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragment;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lListBox := TItemHeightProbeCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to 179 do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := lProvider.FragmentProvider;

    NavigateListBoxFirstChild(lRoot, lItem);
    lListBox.ItemHeightMessageCount := 0;
    for i := 1 to 8 do
    begin
      NavigateListBoxFirstChild(lRoot, lItem);
    end;

    Assert.AreEqual(0, lListBox.ItemHeightMessageCount,
      'Repeated unchanged listbox navigation should use cached VCL state, not LB_GETITEMHEIGHT messages.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxNextSiblingNavigationValidatesWindowStateEveryCall;
var
  i: Integer;
  lCurrent: IRawElementProviderFragment;
  lForm: TForm;
  lListBox: TItemHeightProbeCheckListBox;
  lNext: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragment;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lListBox := TItemHeightProbeCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to 179 do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := lProvider.FragmentProvider;

    NavigateListBoxFirstChild(lRoot, lCurrent);
    lListBox.ItemHeightMessageCount := 0;
    lListBox.TopIndexMessageCount := 0;
    for i := 1 to 4 do
    begin
      Assert.AreEqual(S_OK, lCurrent.Navigate(NavigateDirection_NextSibling, lNext));
      Assert.IsNotNull(lNext);
      lCurrent := lNext;
      Assert.AreEqual(i, lListBox.TopIndexMessageCount,
        'Each sibling call must perform exactly one TopIndex validation.');
    end;

    Assert.AreEqual(4, lListBox.TopIndexMessageCount,
      'Each sibling call must validate TopIndex because a traversal can be paused and resumed after scrolling.');
    Assert.AreEqual(0, lListBox.ItemHeightMessageCount,
      'A fixed-height sibling chain should reuse the prepared item height.');
  finally
    lForm.Free;
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

procedure TAccessibilityListBoxPerformanceTests.FixedHeightListBoxItemBoundsAvoidItemRectMessage;
var
  i: Integer;
  lBounds: UiaRect;
  lForm: TForm;
  lItem: IRawElementProviderFragment;
  lListBox: TItemHeightProbeCheckListBox;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);
    lListBox := TItemHeightProbeCheckListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 280, 140);
    for i := 0 to 179 do
    begin
      lListBox.Items.Add(Format('Client %.4d', [i]));
    end;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    NavigateListBoxFirstChild(lProvider.FragmentProvider, lItem);
    Assert.IsNotNull(lItem, 'Prepared listbox item provider was not returned.');
    lListBox.ItemHeightMessageCount := 0;
    lListBox.ItemRectMessageCount := 0;

    Assert.AreEqual(S_OK, lItem.Get_BoundingRectangle(lBounds));
    Assert.IsTrue(lBounds.Width > 0, 'Listbox item bounds were not returned.');
    Assert.AreEqual(0, lListBox.ItemHeightMessageCount,
      'Prepared fixed-height listbox item bounds should reuse the cached item height.');
    Assert.AreEqual(0, lListBox.ItemRectMessageCount,
      'Fixed-height listbox item bounds should derive the item rectangle without LB_GETITEMRECT.');
  finally
    lForm.Free;
  end;
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

procedure TAccessibilityListBoxPerformanceTests.ListBoxPreparedItemNameUsesCachedText;
var
  i: Integer;
  lForm: TForm;
  lItem: IRawElementProviderFragment;
  lListBox: TCheckListBox;
  lMetrics: TAccessibilityListBoxFocusMetrics;
  lProvider: IAccessibilityProviderNode;
  lSimple: IRawElementProviderSimple;
  lValue: OleVariant;
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
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    NavigateListBoxFirstChild(lProvider.FragmentProvider, lItem);
    Assert.IsNotNull(lItem, 'Prepared listbox item provider was not returned.');
    lSimple := SimpleProvider(lItem);
    TAccessibilityDiagnostics.ResetListBoxFocusMetrics;

    Assert.AreEqual(S_OK, lSimple.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.AreEqual('Client 0000', string(lValue));
    Assert.AreEqual(S_OK, lSimple.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.AreEqual('Client 0000', string(lValue));

    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
    Assert.AreEqual(0, lMetrics.ItemTextProbeCount,
      'Prepared item name queries should reuse the cleaned listbox item text.');
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  end;
end;

procedure TAccessibilityListBoxPerformanceTests.ListBoxNativeHwndNavigationDoesNotUseFrameworkNotificationPath;
var
  lApi: IListBoxPerformanceTestUiaApi;
  lForm: TForm;
  lListBox: TCheckListBox;
  lMetrics: TAccessibilityListBoxFocusMetrics;
  lProviderMetrics: TAccessibilityProviderHotspotMetrics;
begin
  ResetManager;
  TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
  TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
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
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);
    lMetrics := TAccessibilityDiagnostics.ListBoxFocusMetrics;
    lProviderMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;

    Assert.IsTrue(lMetrics.Enabled);
    Assert.AreEqual(0, lMetrics.FocusMovementCount);
    Assert.AreEqual(Int64(0), lMetrics.LastElapsedTicks);
    Assert.AreEqual(0, lMetrics.NotificationCount,
      'Native-HWND listbox movement should not raise duplicate framework notifications.');
    Assert.AreEqual(0, lMetrics.AutomationEventCount,
      'Listbox focus movement should not raise extra custom provider events.');
    Assert.AreEqual(0, lMetrics.GetFocusCount, 'Listbox focus movement should not query provider focus.');
    Assert.AreEqual(0, lMetrics.EnsureItemProviderCount,
      'Listbox focus movement should not prepare item providers.');
    Assert.AreEqual(0, lProviderMetrics.ProviderGetPatternProviderCount,
      'Native-HWND listbox movement should not capture custom provider state.');
    Assert.AreEqual(0, lProviderMetrics.ProviderGetPropertyValueCount,
      'Native-HWND listbox movement should not query framework provider properties.');
    Assert.IsTrue(lMetrics.NativeHandlePublicationCheckCount <= 1,
      Format('Listbox focus movement checked native-handle publication %d times; expected at most one cached check.',
      [lMetrics.NativeHandlePublicationCheckCount]));
  finally
    lForm.Free;
    ResetManager;
    TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
    TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityDiagnosticsStartupTests);
  TDUnitX.RegisterTestFixture(TAccessibilityDiagnosticsTests);
  TDUnitX.RegisterTestFixture(TAccessibilityListBoxPerformanceTests);
  TDUnitX.RegisterTestFixture(TAccessibilityProviderHotspotPerformanceTests);

end.
