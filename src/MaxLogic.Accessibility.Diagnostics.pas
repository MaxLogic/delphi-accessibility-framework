unit MaxLogic.Accessibility.Diagnostics;

interface

type
  TAccessibilityProviderBoundaryCall = (pbcGetBoundingRectangle, pbcGetFragmentRoot, pbcGetHostRawElementProvider,
    pbcGetPatternProvider, pbcGetPropertyValue, pbcGetProviderOptions, pbcGetRuntimeId, pbcNavigate, pbcSetFocus,
    pbcRootElementProviderFromPoint, pbcRootGetFocus);

  TAccessibilityListBoxFocusMetrics = record
  public
    Enabled: Boolean;
    FocusMovementCount: Integer;
    AutomationEventCount: Integer;
    SelectionEventCount: Integer;
    NotificationCount: Integer;
    GetFocusCount: Integer;
    GetSelectionCount: Integer;
    PrepareChildrenCount: Integer;
    VisibleItemProbeCount: Integer;
    EnsureItemProviderCount: Integer;
    CreatedItemProviderCount: Integer;
    ItemTextProbeCount: Integer;
    NativeHandlePublicationCheckCount: Integer;
    GridFocusProbeCount: Integer;
    ItemIndexProbeCount: Integer;
    LastElapsedTicks: Int64;
    TotalElapsedTicks: Int64;
    function ToJson(const aScenario: string; const aSource: string): string;
  end;

  TAccessibilityAgentBridgePipeMetrics = record
  public
    Enabled: Boolean;
    RequestReadCount: Integer;
    RequestReadByteCount: Integer;
    RequestReadResizeCount: Integer;
    RequestReadLastElapsedTicks: Int64;
    RequestReadTotalElapsedTicks: Int64;
  end;

  TAccessibilityScannerMetrics = record
  public
    Enabled: Boolean;
    FlattenedNodesBuildCount: Integer;
    FlattenedNodesBuildItemCount: Integer;
    FlattenedNodesSnapshotCount: Integer;
    FlattenedNodesSnapshotItemCount: Integer;
    RttiPropertyCacheKeyBuildCount: Integer;
    RttiPropertyLookupCount: Integer;
    SortedChildrenAlreadyOrderedCount: Integer;
    SortedChildrenCallCount: Integer;
    SortedChildrenItemCount: Integer;
    SortedChildrenSortCount: Integer;
  end;

  TAccessibilityProviderHotspotMetrics = record
  public
    Enabled: Boolean;
    MemoPrepareChildrenCount: Integer;
    MemoLineProbeCount: Integer;
    MemoLineProviderCreatedCount: Integer;
    MemoPrepareChildrenLastElapsedTicks: Int64;
    MemoPrepareChildrenTotalElapsedTicks: Int64;
    StringGridRefreshCount: Integer;
    StringGridCellProbeCount: Integer;
    StringGridCellProviderCreatedCount: Integer;
    StringGridRefreshScratchListAllocationCount: Integer;
    StringGridRefreshLastElapsedTicks: Int64;
    StringGridRefreshTotalElapsedTicks: Int64;
    StringGridCellBoundsBuildCount: Integer;
    StringGridCellBoundsCellProbeCount: Integer;
    StringGridCellBoundsLastElapsedTicks: Int64;
    StringGridCellBoundsTotalElapsedTicks: Int64;
    StringGridRowRefreshCount: Integer;
    StringGridRowProbeCount: Integer;
    StringGridRowProviderCreatedCount: Integer;
    StringGridRowRefreshScratchListAllocationCount: Integer;
    StringGridRowRefreshLastElapsedTicks: Int64;
    StringGridRowRefreshTotalElapsedTicks: Int64;
    StringGridRowBoundsBuildCount: Integer;
    StringGridRowBoundsCellProbeCount: Integer;
    StringGridRowBoundsLastElapsedTicks: Int64;
    StringGridRowBoundsTotalElapsedTicks: Int64;
    StringGridRowTextBuildCount: Integer;
    StringGridRowTextCellProbeCount: Integer;
    StringGridRowTextHeaderProbeCount: Integer;
    StringGridRowTextLastElapsedTicks: Int64;
    StringGridRowTextTotalElapsedTicks: Int64;
    TmsAdvStringGridRefreshCount: Integer;
    TmsAdvStringGridCellProbeCount: Integer;
    TmsAdvStringGridCellProviderCreatedCount: Integer;
    TmsAdvStringGridRefreshScratchListAllocationCount: Integer;
    TmsAdvStringGridRefreshLastElapsedTicks: Int64;
    TmsAdvStringGridRefreshTotalElapsedTicks: Int64;
    ListBoxGetSelectionCount: Integer;
    ListBoxSelectionItemProbeCount: Integer;
    ListBoxSelectionProviderCount: Integer;
    ListBoxSelectionProviderListAllocationCount: Integer;
    ListBoxGetSelectionLastElapsedTicks: Int64;
    ListBoxGetSelectionTotalElapsedTicks: Int64;
    AgentBridgeChildClientOriginProbeCount: Integer;
    AgentBridgeFocusProbeCount: Integer;
    AgentBridgeRttiPropertyLookupCount: Integer;
    AgentBridgeScreenRectProbeCount: Integer;
    ActiveVisibleTreeProbeCount: Integer;
    VclAdapterRttiPropertyLookupCount: Integer;
    HintTextPreparationCount: Integer;
    ProviderFocusAnnouncementTextCount: Integer;
    ProviderFocusAnnouncementDetailProbeCount: Integer;
    ProviderFocusAnnouncementTextLastElapsedTicks: Int64;
    ProviderFocusAnnouncementTextTotalElapsedTicks: Int64;
    ProviderNotificationCount: Integer;
    ProviderNotificationLastElapsedTicks: Int64;
    ProviderNotificationTotalElapsedTicks: Int64;
    ProviderEventBatchCount: Integer;
    ManagerHookLookupCount: Integer;
    ManagerHookLookupProbeCount: Integer;
    ManagerRetainedHookPassivateCount: Integer;
    ManagerRetainedHookLinearScanCount: Integer;
    ProviderBoundaryTotalElapsedTicks: Int64;
    ProviderChildListAllocationCount: Integer;
    ProviderRuntimeIdBlockCopyCount: Integer;
    ProviderRuntimeIdBlockCopyElementCount: Integer;
    ProviderRuntimeIdElementCopyCount: Integer;
    ProviderGetBoundingRectangleCount: Integer;
    ProviderGetBoundingRectangleTotalElapsedTicks: Int64;
    ProviderGetFragmentRootCount: Integer;
    ProviderGetFragmentRootTotalElapsedTicks: Int64;
    ProviderGetHostRawElementProviderCount: Integer;
    ProviderGetHostRawElementProviderTotalElapsedTicks: Int64;
    ProviderGetPatternProviderCount: Integer;
    ProviderGetPatternProviderTotalElapsedTicks: Int64;
    ProviderGetPropertyValueCount: Integer;
    ProviderGetPropertyValueTotalElapsedTicks: Int64;
    ProviderGetProviderOptionsCount: Integer;
    ProviderGetProviderOptionsTotalElapsedTicks: Int64;
    ProviderGetRuntimeIdCount: Integer;
    ProviderGetRuntimeIdTotalElapsedTicks: Int64;
    ProviderNavigateCount: Integer;
    ProviderNavigateTotalElapsedTicks: Int64;
    ProviderSetFocusCount: Integer;
    ProviderSetFocusTotalElapsedTicks: Int64;
    ProviderRootElementProviderFromPointCount: Integer;
    ProviderRootElementProviderFromPointTotalElapsedTicks: Int64;
    ProviderRootGetFocusCount: Integer;
    ProviderRootGetFocusTotalElapsedTicks: Int64;
    function ToJson(const aScenario: string; const aSource: string): string;
  end;

  TAccessibilityDiagnostics = record
  public
    class procedure Configure(const aLogFile: string); static;
    class procedure Disable; static;
    class procedure DisableAgentBridgePipeMetrics; static;
    class procedure DisableListBoxFocusMetrics; static;
    class procedure DisableProviderHotspotMetrics; static;
    class procedure DisableScannerMetrics; static;
    class function Enabled: Boolean; static;
    class function AgentBridgePipeMetrics: TAccessibilityAgentBridgePipeMetrics; static;
    class function AgentBridgePipeMetricsEnabled: Boolean; static;
    class procedure EnableAgentBridgePipeMetrics; static;
    class procedure EnableListBoxFocusMetrics; static;
    class procedure EnableProviderHotspotMetrics; static;
    class procedure EnableScannerMetrics; static;
    class function ListBoxFocusMetrics: TAccessibilityListBoxFocusMetrics; static;
    class function ListBoxFocusMetricsEnabled: Boolean; static;
    class procedure Log(const aMessage: string); static;
    class procedure RecordAgentBridgePipeRequestRead(aByteCount: Integer; aResizeCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordAgentBridgeChildClientOriginProbe; static;
    class procedure RecordAgentBridgeFocusProbe; static;
    class procedure RecordAgentBridgeRttiPropertyLookup; static;
    class procedure RecordAgentBridgeScreenRectProbe; static;
    class procedure RecordActiveVisibleTreeProbe; static;
    class procedure RecordVclAdapterRttiPropertyLookup; static;
    class function ProviderHotspotMetrics: TAccessibilityProviderHotspotMetrics; static;
    class function ProviderHotspotMetricsEnabled: Boolean; static;
    class procedure RecordListBoxAutomationEvent(aEventId: Integer); static;
    class procedure RecordListBoxEnsureItemProvider(aCreated: Boolean); static;
    class procedure RecordListBoxFocusMovement(aElapsedTicks: Int64); static;
    class procedure RecordListBoxGetFocus; static;
    class procedure RecordListBoxGetSelection; static;
    class procedure RecordListBoxItemTextProbe; static;
    class procedure RecordListBoxNativeHandlePublicationCheck; static;
    class procedure RecordListBoxGridFocusProbe; static;
    class procedure RecordListBoxItemIndexProbe; static;
    class procedure RecordListBoxNotification(aDisplayStringLength: Integer); static;
    class procedure RecordListBoxPrepareChildren; static;
    class procedure RecordListBoxVisibleItemProbe; static;
    class procedure RecordMemoPrepareChildren(aLineProbeCount: Integer; aProviderCreatedCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordProviderHotspotListBoxGetSelection(aItemProbeCount: Integer; aProviderCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordProviderHotspotListBoxSelectionProviderListAllocation; static;
    class procedure RecordHintTextPreparation; static;
    class procedure RecordManagerHookLookup(aProbeCount: Integer); static;
    class procedure RecordManagerRetainedHookPassivation(aLinearScanCount: Integer); static;
    class procedure RecordProviderFocusAnnouncementText(aDetailProbeCount: Integer); overload; static;
    class procedure RecordProviderFocusAnnouncementText(aDetailProbeCount: Integer; aElapsedTicks: Int64); overload;
      static;
    class procedure RecordProviderNotification(aElapsedTicks: Int64); static;
    class procedure RecordProviderEventBatch; static;
    class procedure RecordProviderBoundaryCall(aCall: TAccessibilityProviderBoundaryCall); overload; static;
    class procedure RecordProviderBoundaryCall(aCall: TAccessibilityProviderBoundaryCall; aElapsedTicks: Int64);
      overload; static;
    class procedure RecordProviderChildListAllocation; static;
    class procedure RecordProviderRuntimeIdBlockCopy(aElementCount: Integer); static;
    class procedure RecordProviderRuntimeIdElementCopy(aElementCount: Integer); static;
    class procedure RecordScannerFlattenedNodesBuild(aItemCount: Integer); static;
    class procedure RecordScannerFlattenedNodesSnapshot(aItemCount: Integer); static;
    class procedure RecordScannerRttiPropertyCacheKeyBuild; static;
    class procedure RecordScannerRttiPropertyLookup; static;
    class procedure RecordScannerSortedChildren(aItemCount: Integer; aSorted: Boolean); static;
    class procedure RecordStringGridRefresh(aCellProbeCount: Integer; aProviderCreatedCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordStringGridRefreshScratchListAllocation(aCount: Integer); static;
    class procedure RecordStringGridCellBounds(aCellProbeCount: Integer; aElapsedTicks: Int64); static;
    class procedure RecordStringGridRowRefresh(aRowProbeCount: Integer; aProviderCreatedCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordStringGridRowRefreshScratchListAllocation(aCount: Integer); static;
    class procedure RecordStringGridRowBounds(aCellProbeCount: Integer; aElapsedTicks: Int64); static;
    class procedure RecordStringGridRowText(aCellProbeCount: Integer; aHeaderProbeCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordTmsAdvStringGridRefresh(aCellProbeCount: Integer; aProviderCreatedCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordTmsAdvStringGridRefreshScratchListAllocation(aCount: Integer); static;
    class procedure ResetListBoxFocusMetrics; static;
    class procedure ResetAgentBridgePipeMetrics; static;
    class procedure ResetProviderHotspotMetrics; static;
    class procedure ResetScannerMetrics; static;
    class function ScannerMetrics: TAccessibilityScannerMetrics; static;
    class function ScannerMetricsEnabled: Boolean; static;
  end;

  TAccessibilityDiagnosticsInternals = record
  public
    class function DroppedLogRecordCount: Int64; static;
    class function FlushLog(aTimeoutMs: Cardinal): Boolean; static;
    class function LogFileWriteThreadId: Cardinal; static;
    class function PendingLogRecordCount: Integer; static;
    class procedure PauseLogWriter(aPaused: Boolean); static;
    class function QueueCapacity: Integer; static;
    class procedure SetMaximumLogBytes(aMaxBytes: Int64); static;
    class function WriterAcceptingRecords: Boolean; static;
    class function WriterStarted: Boolean; static;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.SyncObjs, System.SysUtils, System.Types, Winapi.Windows,
  MaxLogic.Accessibility.UIAutomationCore;

const
  cDiagnosticsLogMaximumBytes = 8 * 1024 * 1024;
  cDiagnosticsLogQueueCapacity = 1024;
  cDiagnosticsLogSummaryReserve = 512;

type
  TAccessibilityDiagnosticLogEntry = record
    Message: string;
    ThreadId: Cardinal;
    Timestamp: TDateTime;
  end;

  TAccessibilityDiagnosticWriter = class;

  TAccessibilityDiagnosticWriterThread = class(TThread)
  private
    fOwner: TAccessibilityDiagnosticWriter;
  protected
    procedure Execute; override;
  public
    constructor Create(aOwner: TAccessibilityDiagnosticWriter);
  end;

  TAccessibilityDiagnosticWriter = class
  private
    fActiveProducerCount: Integer;
    fBytesWritten: Int64;
    fDroppedRecordCount: Int64;
    fDroppedUnreportedCount: Int64;
    fEnabled: Integer;
    fFileHandle: THandle;
    fIdleEvent: TEvent;
    fLastWriteError: string;
    fLogFileWriteThreadId: Cardinal;
    fMaximumLogBytes: Int64;
    fPauseEvent: TEvent;
    fPendingRecordCount: Integer;
    fProcessId: Cardinal;
    fQueue: TThreadedQueue<TAccessibilityDiagnosticLogEntry>;
    fThread: TAccessibilityDiagnosticWriterThread;
    fThreadStarted: Boolean;
    fWriterBusy: Integer;
    fWriteFailed: Integer;
    procedure AddDroppedRecord;
    function CompleteEntry: Boolean;
    function CurrentProducerCount: Integer;
    function CurrentPendingCount: Integer;
    procedure EnsureThread;
    procedure HandleWriterException(aException: Exception);
    function IsIdle: Boolean;
    procedure ProcessEntry(const aEntry: TAccessibilityDiagnosticLogEntry);
    procedure WaitForProducers;
    procedure WriteDroppedSummary;
    procedure WriteLine(const aLine: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configure(const aLogFile: string);
    procedure Disable;
    function DroppedRecordCount: Int64;
    procedure Enqueue(const aMessage: string);
    function Flush(aTimeoutMs: Cardinal): Boolean;
    function IsEnabled: Boolean;
    function LogFileWriteThreadId: Cardinal;
    function PendingRecordCount: Integer;
    procedure Pause(aPaused: Boolean);
    procedure SetMaximumLogBytes(aMaxBytes: Int64);
    function WriterStarted: Boolean;
  end;

var
  gAgentBridgePipeMetrics: TAccessibilityAgentBridgePipeMetrics;
  gAgentBridgePipeMetricsEnabled: Boolean;
  gDiagnosticsLock: TObject;
  gDiagnosticsWriter: TAccessibilityDiagnosticWriter;
  gDiagnosticsWriterLock: TLightweightMREW;
  gListBoxFocusMetrics: TAccessibilityListBoxFocusMetrics;
  gListBoxFocusMetricsEnabled: Boolean;
  gProviderHotspotMetrics: TAccessibilityProviderHotspotMetrics;
  gProviderHotspotMetricsEnabled: Boolean;
  gScannerMetrics: TAccessibilityScannerMetrics;
  gScannerMetricsEnabled: Boolean;

procedure WriteAllBytes(aHandle: THandle; const aBytes: TBytes);
var
  lOffset: Integer;
  lWritten: Cardinal;
begin
  lOffset := 0;
  while lOffset < Length(aBytes) do
  begin
    lWritten := 0;
    if not WriteFile(aHandle, aBytes[lOffset], Cardinal(Length(aBytes) - lOffset), lWritten, nil) then
    begin
      RaiseLastOSError;
    end;
    if lWritten = 0 then
    begin
      raise EWriteError.Create('Diagnostics file write returned zero bytes.');
    end;
    Inc(lOffset, lWritten);
  end;
end;

constructor TAccessibilityDiagnosticWriterThread.Create(aOwner: TAccessibilityDiagnosticWriter);
begin
  inherited Create(True);
  fOwner := aOwner;
  FreeOnTerminate := False;
end;

procedure TAccessibilityDiagnosticWriterThread.Execute;
var
  lBecameIdle: Boolean;
  lEntry: TAccessibilityDiagnosticLogEntry;
  lWaitResult: TWaitResult;
begin
  while not Terminated do
  begin
    if fOwner.fPauseEvent.WaitFor(INFINITE) <> wrSignaled then
    begin
      Continue;
    end;

    lWaitResult := fOwner.fQueue.PopItem(lEntry);
    if Terminated then
    begin
      Break;
    end;
    if lWaitResult <> wrSignaled then
    begin
      Continue;
    end;

    fOwner.fPauseEvent.WaitFor(INFINITE);
    TInterlocked.Exchange(fOwner.fWriterBusy, 1);
    lBecameIdle := False;
    try
      try
        fOwner.ProcessEntry(lEntry);
      except
        on E: Exception do
        begin
          fOwner.HandleWriterException(E);
        end;
      end;
    finally
      try
        lBecameIdle := fOwner.CompleteEntry;
      except
        on E: Exception do
        begin
          fOwner.HandleWriterException(E);
          lBecameIdle := fOwner.CurrentPendingCount = 0;
        end;
      end;
      TInterlocked.Exchange(fOwner.fWriterBusy, 0);
      if lBecameIdle and (fOwner.CurrentPendingCount = 0) then
      begin
        fOwner.fIdleEvent.SetEvent;
      end;
    end;
  end;
end;

constructor TAccessibilityDiagnosticWriter.Create;
begin
  inherited Create;
  fFileHandle := INVALID_HANDLE_VALUE;
  fIdleEvent := TEvent.Create(nil, True, True, '');
  fMaximumLogBytes := cDiagnosticsLogMaximumBytes;
  fPauseEvent := TEvent.Create(nil, True, True, '');
  fProcessId := GetCurrentProcessId;
  fQueue := TThreadedQueue<TAccessibilityDiagnosticLogEntry>.Create(cDiagnosticsLogQueueCapacity, 0, INFINITE);
end;

destructor TAccessibilityDiagnosticWriter.Destroy;
begin
  if fPauseEvent <> nil then
  begin
    fPauseEvent.SetEvent;
  end;
  if fThreadStarted then
  begin
    Disable;
  end;
  if fThread <> nil then
  begin
    fThread.Terminate;
  end;
  if fQueue <> nil then
  begin
    fQueue.DoShutDown;
  end;
  fThread.Free;
  fQueue.Free;
  fPauseEvent.Free;
  fIdleEvent.Free;
  inherited Destroy;
end;

procedure TAccessibilityDiagnosticWriter.AddDroppedRecord;
begin
  TInterlocked.Increment(fDroppedRecordCount);
  TInterlocked.Increment(fDroppedUnreportedCount);
end;

function TAccessibilityDiagnosticWriter.CompleteEntry: Boolean;
begin
  Result := TInterlocked.Decrement(fPendingRecordCount) = 0;
  if Result then
  begin
    WriteDroppedSummary;
    Result := CurrentPendingCount = 0;
  end;
end;

procedure TAccessibilityDiagnosticWriter.Configure(const aLogFile: string);
var
  lDirectory: string;
  lFileHandle: THandle;
  lPreamble: TBytes;
begin
  Disable;
  if aLogFile = '' then
  begin
    Exit;
  end;

  EnsureThread;

  lDirectory := ExtractFilePath(aLogFile);
  if (lDirectory <> '') and not ForceDirectories(lDirectory) then
  begin
    raise EInOutError.CreateFmt('Unable to create diagnostics directory: %s', [lDirectory]);
  end;

  lFileHandle := CreateFile(PChar(aLogFile), GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
    nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if lFileHandle = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end;

  try
    lPreamble := TEncoding.UTF8.GetPreamble;
    WriteAllBytes(lFileHandle, lPreamble);
  except
    CloseHandle(lFileHandle);
    raise;
  end;

  fFileHandle := lFileHandle;
  fBytesWritten := Length(lPreamble);
  TInterlocked.Exchange(fDroppedRecordCount, 0);
  TInterlocked.Exchange(fDroppedUnreportedCount, 0);
  fLastWriteError := '';
  fLogFileWriteThreadId := 0;
  TInterlocked.Exchange(fWriteFailed, 0);
  fIdleEvent.SetEvent;
  TInterlocked.Exchange(fEnabled, 1);
end;

function TAccessibilityDiagnosticWriter.CurrentProducerCount: Integer;
begin
  Result := TInterlocked.CompareExchange(fActiveProducerCount, 0, 0);
end;

function TAccessibilityDiagnosticWriter.CurrentPendingCount: Integer;
begin
  Result := TInterlocked.CompareExchange(fPendingRecordCount, 0, 0);
end;

procedure TAccessibilityDiagnosticWriter.EnsureThread;
var
  lThread: TAccessibilityDiagnosticWriterThread;
begin
  if fThreadStarted then
  begin
    Exit;
  end;

  lThread := TAccessibilityDiagnosticWriterThread.Create(Self);
  try
    lThread.Start;
    fThread := lThread;
    fThreadStarted := True;
  except
    lThread.Free;
    raise;
  end;
end;

procedure TAccessibilityDiagnosticWriter.Disable;
begin
  TInterlocked.Exchange(fEnabled, 0);
  WaitForProducers;
  Flush(INFINITE);
  if fFileHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(fFileHandle);
    fFileHandle := INVALID_HANDLE_VALUE;
  end;
end;

function TAccessibilityDiagnosticWriter.DroppedRecordCount: Int64;
begin
  Result := TInterlocked.Read(fDroppedRecordCount);
end;

procedure TAccessibilityDiagnosticWriter.Enqueue(const aMessage: string);
var
  lEntry: TAccessibilityDiagnosticLogEntry;
  lPendingCount: Integer;
begin
  if not IsEnabled then
  begin
    Exit;
  end;

  TInterlocked.Increment(fActiveProducerCount);
  try
    if not IsEnabled then
    begin
      Exit;
    end;

    lEntry.Message := aMessage;
    lEntry.ThreadId := GetCurrentThreadId;
    lEntry.Timestamp := Now;
    lPendingCount := TInterlocked.Increment(fPendingRecordCount);
    if lPendingCount = 1 then
    begin
      fIdleEvent.ResetEvent;
    end;

    if fQueue.PushItem(lEntry) <> wrSignaled then
    begin
      AddDroppedRecord;
      if TInterlocked.Decrement(fPendingRecordCount) = 0 then
      begin
        fIdleEvent.SetEvent;
      end;
    end;
  finally
    TInterlocked.Decrement(fActiveProducerCount);
  end;
end;

function TAccessibilityDiagnosticWriter.Flush(aTimeoutMs: Cardinal): Boolean;
var
  lElapsedMs: UInt64;
  lStartedAt: UInt64;
  lWaitMs: Cardinal;
begin
  Result := False;
  lStartedAt := GetTickCount64;
  while not Result do
  begin
    fIdleEvent.ResetEvent;
    if IsIdle then
    begin
      Result := True;
      Break;
    end;

    if aTimeoutMs = INFINITE then
    begin
      lWaitMs := INFINITE;
    end else begin
      lElapsedMs := GetTickCount64 - lStartedAt;
      if lElapsedMs >= aTimeoutMs then
      begin
        Break;
      end;
      lWaitMs := Cardinal(aTimeoutMs - lElapsedMs);
    end;

    if fIdleEvent.WaitFor(lWaitMs) <> wrSignaled then
    begin
      Break;
    end;
  end;
end;

procedure TAccessibilityDiagnosticWriter.HandleWriterException(aException: Exception);
begin
  fLastWriteError := aException.ClassName + ': ' + aException.Message;
  AddDroppedRecord;
  TInterlocked.Exchange(fWriteFailed, 1);
  TInterlocked.Exchange(fEnabled, 0);
end;

function TAccessibilityDiagnosticWriter.IsEnabled: Boolean;
begin
  Result := TInterlocked.CompareExchange(fEnabled, 0, 0) <> 0;
end;

function TAccessibilityDiagnosticWriter.IsIdle: Boolean;
begin
  Result := (CurrentProducerCount = 0) and (CurrentPendingCount = 0) and
    (TInterlocked.CompareExchange(fWriterBusy, 0, 0) = 0);
end;

function TAccessibilityDiagnosticWriter.LogFileWriteThreadId: Cardinal;
begin
  Result := fLogFileWriteThreadId;
end;

function TAccessibilityDiagnosticWriter.PendingRecordCount: Integer;
begin
  Result := CurrentPendingCount;
end;

function TAccessibilityDiagnosticWriter.WriterStarted: Boolean;
begin
  Result := fThreadStarted;
end;

procedure TAccessibilityDiagnosticWriter.Pause(aPaused: Boolean);
begin
  if aPaused then
  begin
    fPauseEvent.ResetEvent;
  end else begin
    fPauseEvent.SetEvent;
  end;
end;

procedure TAccessibilityDiagnosticWriter.ProcessEntry(const aEntry: TAccessibilityDiagnosticLogEntry);
var
  lDataLimit: Int64;
  lLine: string;
begin
  if (fFileHandle = INVALID_HANDLE_VALUE) or (TInterlocked.CompareExchange(fWriteFailed, 0, 0) <> 0) then
  begin
    AddDroppedRecord;
    Exit;
  end;

  lLine := Format('%s pid=%d tid=%d %s%s',
    [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', aEntry.Timestamp), fProcessId, aEntry.ThreadId, aEntry.Message,
    sLineBreak]);
  lDataLimit := fMaximumLogBytes - cDiagnosticsLogSummaryReserve;
  if (lDataLimit < 0) or (fBytesWritten + TEncoding.UTF8.GetByteCount(lLine) > lDataLimit) then
  begin
    AddDroppedRecord;
    TInterlocked.Exchange(fEnabled, 0);
    Exit;
  end;

  WriteLine(lLine);
end;

procedure TAccessibilityDiagnosticWriter.SetMaximumLogBytes(aMaxBytes: Int64);
begin
  if IsEnabled or (fFileHandle <> INVALID_HANDLE_VALUE) then
  begin
    raise EInvalidOperation.Create('Disable diagnostics before changing the maximum log size.');
  end;
  if aMaxBytes = 0 then
  begin
    fMaximumLogBytes := cDiagnosticsLogMaximumBytes;
  end else if aMaxBytes < cDiagnosticsLogSummaryReserve then
  begin
    raise EArgumentOutOfRangeException.CreateFmt('Maximum diagnostics log size must be at least %d bytes.',
      [cDiagnosticsLogSummaryReserve]);
  end else begin
    fMaximumLogBytes := aMaxBytes;
  end;
end;

procedure TAccessibilityDiagnosticWriter.WaitForProducers;
begin
  while CurrentProducerCount <> 0 do
  begin
    Sleep(0);
  end;
end;

procedure TAccessibilityDiagnosticWriter.WriteDroppedSummary;
var
  lDroppedCount: Int64;
  lLine: string;
begin
  lDroppedCount := TInterlocked.Exchange(fDroppedUnreportedCount, 0);
  if (lDroppedCount = 0) or (fFileHandle = INVALID_HANDLE_VALUE) or
    (TInterlocked.CompareExchange(fWriteFailed, 0, 0) <> 0) then
  begin
    Exit;
  end;

  lLine := Format('%s pid=%d tid=%d Diagnostics dropped %d record(s) because a queue or file bound was reached.%s',
    [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now), fProcessId, GetCurrentThreadId, lDroppedCount, sLineBreak]);
  if fBytesWritten + TEncoding.UTF8.GetByteCount(lLine) > fMaximumLogBytes then
  begin
    Exit;
  end;

  WriteLine(lLine);
end;

procedure TAccessibilityDiagnosticWriter.WriteLine(const aLine: string);
var
  lBytes: TBytes;
begin
  lBytes := TEncoding.UTF8.GetBytes(aLine);
  WriteAllBytes(fFileHandle, lBytes);
  Inc(fBytesWritten, Length(lBytes));
  fLogFileWriteThreadId := GetCurrentThreadId;
end;

function JsonBoolean(aValue: Boolean): string;
begin
  if aValue then
  begin
    Result := 'true';
  end else begin
    Result := 'false';
  end;
end;

function JsonEscape(const aValue: string): string;
var
  i: Integer;
  lChar: Char;
begin
  Result := '';
  for i := 1 to Length(aValue) do
  begin
    lChar := aValue[i];
    case lChar of
      '\':
        Result := Result + '\\';
      '"':
        Result := Result + '\"';
      #8:
        Result := Result + '\b';
      #9:
        Result := Result + '\t';
      #10:
        Result := Result + '\n';
      #12:
        Result := Result + '\f';
      #13:
        Result := Result + '\r';
    else
      if Ord(lChar) < 32 then
      begin
        Result := Result + '\u' + IntToHex(Ord(lChar), 4);
      end else begin
        Result := Result + lChar;
      end;
    end;
  end;
end;

function TAccessibilityListBoxFocusMetrics.ToJson(const aScenario: string; const aSource: string): string;
begin
  Result := '{"scenario":"' + JsonEscape(aScenario) + '","source":"' + JsonEscape(aSource) + '","enabled":' +
    JsonBoolean(Enabled) + ',"focusMovementCount":' + IntToStr(FocusMovementCount) + ',"automationEventCount":' +
    IntToStr(AutomationEventCount) + ',"selectionEventCount":' + IntToStr(SelectionEventCount) +
    ',"notificationCount":' + IntToStr(NotificationCount) + ',"getFocusCount":' + IntToStr(GetFocusCount) +
    ',"getSelectionCount":' + IntToStr(GetSelectionCount) + ',"prepareChildrenCount":' +
    IntToStr(PrepareChildrenCount) + ',"visibleItemProbeCount":' + IntToStr(VisibleItemProbeCount) +
    ',"ensureItemProviderCount":' + IntToStr(EnsureItemProviderCount) + ',"createdItemProviderCount":' +
    IntToStr(CreatedItemProviderCount) + ',"itemTextProbeCount":' + IntToStr(ItemTextProbeCount) +
    ',"nativeHandlePublicationCheckCount":' + IntToStr(NativeHandlePublicationCheckCount) +
    ',"gridFocusProbeCount":' + IntToStr(GridFocusProbeCount) +
    ',"itemIndexProbeCount":' + IntToStr(ItemIndexProbeCount) +
    ',"lastElapsedTicks":' + IntToStr(LastElapsedTicks) + ',"totalElapsedTicks":' +
    IntToStr(TotalElapsedTicks) + '}';
end;

function TAccessibilityProviderHotspotMetrics.ToJson(const aScenario: string; const aSource: string): string;
begin
  Result := '{"scenario":"' + JsonEscape(aScenario) + '","source":"' + JsonEscape(aSource) + '","enabled":' +
    JsonBoolean(Enabled) + ',"memoPrepareChildrenCount":' + IntToStr(MemoPrepareChildrenCount) +
    ',"memoLineProbeCount":' + IntToStr(MemoLineProbeCount) + ',"memoLineProviderCreatedCount":' +
    IntToStr(MemoLineProviderCreatedCount) + ',"memoPrepareChildrenLastElapsedTicks":' +
    IntToStr(MemoPrepareChildrenLastElapsedTicks) + ',"memoPrepareChildrenTotalElapsedTicks":' +
    IntToStr(MemoPrepareChildrenTotalElapsedTicks) + ',"stringGridRefreshCount":' +
    IntToStr(StringGridRefreshCount) + ',"stringGridCellProbeCount":' + IntToStr(StringGridCellProbeCount) +
    ',"stringGridCellProviderCreatedCount":' + IntToStr(StringGridCellProviderCreatedCount) +
    ',"stringGridRefreshScratchListAllocationCount":' +
    IntToStr(StringGridRefreshScratchListAllocationCount) +
    ',"stringGridRefreshLastElapsedTicks":' + IntToStr(StringGridRefreshLastElapsedTicks) +
    ',"stringGridRefreshTotalElapsedTicks":' + IntToStr(StringGridRefreshTotalElapsedTicks) +
    ',"stringGridCellBoundsBuildCount":' + IntToStr(StringGridCellBoundsBuildCount) +
    ',"stringGridCellBoundsCellProbeCount":' + IntToStr(StringGridCellBoundsCellProbeCount) +
    ',"stringGridCellBoundsLastElapsedTicks":' + IntToStr(StringGridCellBoundsLastElapsedTicks) +
    ',"stringGridCellBoundsTotalElapsedTicks":' + IntToStr(StringGridCellBoundsTotalElapsedTicks) +
    ',"stringGridRowRefreshCount":' + IntToStr(StringGridRowRefreshCount) +
    ',"stringGridRowProbeCount":' + IntToStr(StringGridRowProbeCount) +
    ',"stringGridRowProviderCreatedCount":' + IntToStr(StringGridRowProviderCreatedCount) +
    ',"stringGridRowRefreshScratchListAllocationCount":' +
    IntToStr(StringGridRowRefreshScratchListAllocationCount) +
    ',"stringGridRowRefreshLastElapsedTicks":' + IntToStr(StringGridRowRefreshLastElapsedTicks) +
    ',"stringGridRowRefreshTotalElapsedTicks":' + IntToStr(StringGridRowRefreshTotalElapsedTicks) +
    ',"stringGridRowBoundsBuildCount":' + IntToStr(StringGridRowBoundsBuildCount) +
    ',"stringGridRowBoundsCellProbeCount":' + IntToStr(StringGridRowBoundsCellProbeCount) +
    ',"stringGridRowBoundsLastElapsedTicks":' + IntToStr(StringGridRowBoundsLastElapsedTicks) +
    ',"stringGridRowBoundsTotalElapsedTicks":' + IntToStr(StringGridRowBoundsTotalElapsedTicks) +
    ',"stringGridRowTextBuildCount":' + IntToStr(StringGridRowTextBuildCount) +
    ',"stringGridRowTextCellProbeCount":' + IntToStr(StringGridRowTextCellProbeCount) +
    ',"stringGridRowTextHeaderProbeCount":' + IntToStr(StringGridRowTextHeaderProbeCount) +
    ',"stringGridRowTextLastElapsedTicks":' + IntToStr(StringGridRowTextLastElapsedTicks) +
    ',"stringGridRowTextTotalElapsedTicks":' + IntToStr(StringGridRowTextTotalElapsedTicks) +
    ',"tmsAdvStringGridRefreshCount":' + IntToStr(TmsAdvStringGridRefreshCount) +
    ',"tmsAdvStringGridCellProbeCount":' + IntToStr(TmsAdvStringGridCellProbeCount) +
    ',"tmsAdvStringGridCellProviderCreatedCount":' + IntToStr(TmsAdvStringGridCellProviderCreatedCount) +
    ',"tmsAdvStringGridRefreshScratchListAllocationCount":' +
    IntToStr(TmsAdvStringGridRefreshScratchListAllocationCount) +
    ',"tmsAdvStringGridRefreshLastElapsedTicks":' + IntToStr(TmsAdvStringGridRefreshLastElapsedTicks) +
    ',"tmsAdvStringGridRefreshTotalElapsedTicks":' + IntToStr(TmsAdvStringGridRefreshTotalElapsedTicks) +
    ',"listBoxGetSelectionCount":' + IntToStr(ListBoxGetSelectionCount) + ',"listBoxSelectionItemProbeCount":' +
    IntToStr(ListBoxSelectionItemProbeCount) + ',"listBoxSelectionProviderCount":' +
    IntToStr(ListBoxSelectionProviderCount) + ',"listBoxSelectionProviderListAllocationCount":' +
    IntToStr(ListBoxSelectionProviderListAllocationCount) + ',"listBoxGetSelectionLastElapsedTicks":' +
    IntToStr(ListBoxGetSelectionLastElapsedTicks) + ',"listBoxGetSelectionTotalElapsedTicks":' +
    IntToStr(ListBoxGetSelectionTotalElapsedTicks) + ',"agentBridgeChildClientOriginProbeCount":' +
    IntToStr(AgentBridgeChildClientOriginProbeCount) + ',"agentBridgeFocusProbeCount":' +
    IntToStr(AgentBridgeFocusProbeCount) + ',"agentBridgeRttiPropertyLookupCount":' +
    IntToStr(AgentBridgeRttiPropertyLookupCount) + ',"agentBridgeScreenRectProbeCount":' +
    IntToStr(AgentBridgeScreenRectProbeCount) + ',"activeVisibleTreeProbeCount":' +
    IntToStr(ActiveVisibleTreeProbeCount) + ',"vclAdapterRttiPropertyLookupCount":' +
    IntToStr(VclAdapterRttiPropertyLookupCount) + ',"hintTextPreparationCount":' +
    IntToStr(HintTextPreparationCount) + ',"providerFocusAnnouncementTextCount":' +
    IntToStr(ProviderFocusAnnouncementTextCount) + ',"providerFocusAnnouncementDetailProbeCount":' +
    IntToStr(ProviderFocusAnnouncementDetailProbeCount) +
    ',"providerFocusAnnouncementTextLastElapsedTicks":' +
    IntToStr(ProviderFocusAnnouncementTextLastElapsedTicks) +
    ',"providerFocusAnnouncementTextTotalElapsedTicks":' +
    IntToStr(ProviderFocusAnnouncementTextTotalElapsedTicks) + ',"providerNotificationCount":' +
    IntToStr(ProviderNotificationCount) + ',"providerNotificationLastElapsedTicks":' +
    IntToStr(ProviderNotificationLastElapsedTicks) + ',"providerNotificationTotalElapsedTicks":' +
    IntToStr(ProviderNotificationTotalElapsedTicks) + ',"providerEventBatchCount":' +
    IntToStr(ProviderEventBatchCount) + ',"managerHookLookupCount":' + IntToStr(ManagerHookLookupCount) +
    ',"managerHookLookupProbeCount":' + IntToStr(ManagerHookLookupProbeCount) +
    ',"managerRetainedHookPassivateCount":' + IntToStr(ManagerRetainedHookPassivateCount) +
    ',"managerRetainedHookLinearScanCount":' + IntToStr(ManagerRetainedHookLinearScanCount) +
    ',"providerBoundaryTotalElapsedTicks":' +
    IntToStr(ProviderBoundaryTotalElapsedTicks) + ',"providerChildListAllocationCount":' +
    IntToStr(ProviderChildListAllocationCount) + ',"providerRuntimeIdBlockCopyCount":' +
    IntToStr(ProviderRuntimeIdBlockCopyCount) + ',"providerRuntimeIdBlockCopyElementCount":' +
    IntToStr(ProviderRuntimeIdBlockCopyElementCount) + ',"providerRuntimeIdElementCopyCount":' +
    IntToStr(ProviderRuntimeIdElementCopyCount) + ',"providerGetBoundingRectangleCount":' +
    IntToStr(ProviderGetBoundingRectangleCount) + ',"providerGetBoundingRectangleTotalElapsedTicks":' +
    IntToStr(ProviderGetBoundingRectangleTotalElapsedTicks) + ',"providerGetFragmentRootCount":' +
    IntToStr(ProviderGetFragmentRootCount) + ',"providerGetFragmentRootTotalElapsedTicks":' +
    IntToStr(ProviderGetFragmentRootTotalElapsedTicks) + ',"providerGetHostRawElementProviderCount":' +
    IntToStr(ProviderGetHostRawElementProviderCount) + ',"providerGetHostRawElementProviderTotalElapsedTicks":' +
    IntToStr(ProviderGetHostRawElementProviderTotalElapsedTicks) + ',"providerGetPatternProviderCount":' +
    IntToStr(ProviderGetPatternProviderCount) + ',"providerGetPatternProviderTotalElapsedTicks":' +
    IntToStr(ProviderGetPatternProviderTotalElapsedTicks) + ',"providerGetPropertyValueCount":' +
    IntToStr(ProviderGetPropertyValueCount) + ',"providerGetPropertyValueTotalElapsedTicks":' +
    IntToStr(ProviderGetPropertyValueTotalElapsedTicks) + ',"providerGetProviderOptionsCount":' +
    IntToStr(ProviderGetProviderOptionsCount) + ',"providerGetProviderOptionsTotalElapsedTicks":' +
    IntToStr(ProviderGetProviderOptionsTotalElapsedTicks) + ',"providerGetRuntimeIdCount":' +
    IntToStr(ProviderGetRuntimeIdCount) + ',"providerGetRuntimeIdTotalElapsedTicks":' +
    IntToStr(ProviderGetRuntimeIdTotalElapsedTicks) + ',"providerNavigateCount":' + IntToStr(ProviderNavigateCount) +
    ',"providerNavigateTotalElapsedTicks":' + IntToStr(ProviderNavigateTotalElapsedTicks) +
    ',"providerSetFocusCount":' + IntToStr(ProviderSetFocusCount) +
    ',"providerSetFocusTotalElapsedTicks":' + IntToStr(ProviderSetFocusTotalElapsedTicks) +
    ',"providerRootElementProviderFromPointCount":' + IntToStr(ProviderRootElementProviderFromPointCount) +
    ',"providerRootElementProviderFromPointTotalElapsedTicks":' +
    IntToStr(ProviderRootElementProviderFromPointTotalElapsedTicks) + ',"providerRootGetFocusCount":' +
    IntToStr(ProviderRootGetFocusCount) + ',"providerRootGetFocusTotalElapsedTicks":' +
    IntToStr(ProviderRootGetFocusTotalElapsedTicks) + '}';
end;

class procedure TAccessibilityDiagnostics.Configure(const aLogFile: string);
begin
  gDiagnosticsWriterLock.BeginWrite;
  try
    if gDiagnosticsWriter <> nil then
    begin
      gDiagnosticsWriter.Configure(aLogFile);
    end;
  finally
    gDiagnosticsWriterLock.EndWrite;
  end;
end;

class procedure TAccessibilityDiagnostics.Disable;
begin
  gDiagnosticsWriterLock.BeginWrite;
  try
    if gDiagnosticsWriter <> nil then
    begin
      gDiagnosticsWriter.Disable;
    end;
  finally
    gDiagnosticsWriterLock.EndWrite;
  end;
end;

class procedure TAccessibilityDiagnostics.DisableAgentBridgePipeMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gAgentBridgePipeMetricsEnabled := False;
    gAgentBridgePipeMetrics := Default(TAccessibilityAgentBridgePipeMetrics);
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.DisableListBoxFocusMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gListBoxFocusMetricsEnabled := False;
    gListBoxFocusMetrics := Default(TAccessibilityListBoxFocusMetrics);
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gProviderHotspotMetricsEnabled := False;
    gProviderHotspotMetrics := Default(TAccessibilityProviderHotspotMetrics);
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.DisableScannerMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gScannerMetricsEnabled := False;
    gScannerMetrics := Default(TAccessibilityScannerMetrics);
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnostics.AgentBridgePipeMetrics: TAccessibilityAgentBridgePipeMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    Result := gAgentBridgePipeMetrics;
    Result.Enabled := gAgentBridgePipeMetricsEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnostics.AgentBridgePipeMetricsEnabled: Boolean;
begin
  Result := gAgentBridgePipeMetricsEnabled;
end;

class function TAccessibilityDiagnostics.Enabled: Boolean;
begin
  if not gDiagnosticsWriterLock.TryBeginRead then
  begin
    Exit(False);
  end;
  try
    Result := (gDiagnosticsWriter <> nil) and gDiagnosticsWriter.IsEnabled;
  finally
    gDiagnosticsWriterLock.EndRead;
  end;
end;

class procedure TAccessibilityDiagnostics.EnableAgentBridgePipeMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gAgentBridgePipeMetricsEnabled := True;
    gAgentBridgePipeMetrics.Enabled := True;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.EnableListBoxFocusMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gListBoxFocusMetricsEnabled := True;
    gListBoxFocusMetrics.Enabled := True;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gProviderHotspotMetricsEnabled := True;
    gProviderHotspotMetrics.Enabled := True;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.EnableScannerMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gScannerMetricsEnabled := True;
    gScannerMetrics.Enabled := True;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnostics.ListBoxFocusMetrics: TAccessibilityListBoxFocusMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    Result := gListBoxFocusMetrics;
    Result.Enabled := gListBoxFocusMetricsEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnostics.ProviderHotspotMetrics: TAccessibilityProviderHotspotMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    Result := gProviderHotspotMetrics;
    Result.Enabled := gProviderHotspotMetricsEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnostics.ProviderHotspotMetricsEnabled: Boolean;
begin
  Result := gProviderHotspotMetricsEnabled;
end;

class function TAccessibilityDiagnostics.ScannerMetrics: TAccessibilityScannerMetrics;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    Result := gScannerMetrics;
    Result.Enabled := gScannerMetricsEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnostics.ScannerMetricsEnabled: Boolean;
begin
  Result := gScannerMetricsEnabled;
end;

class function TAccessibilityDiagnostics.ListBoxFocusMetricsEnabled: Boolean;
begin
  Result := gListBoxFocusMetricsEnabled;
end;

class procedure TAccessibilityDiagnostics.RecordAgentBridgePipeRequestRead(aByteCount: Integer;
  aResizeCount: Integer; aElapsedTicks: Int64);
begin
  if not gAgentBridgePipeMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gAgentBridgePipeMetricsEnabled then
    begin
      Inc(gAgentBridgePipeMetrics.RequestReadCount);
      Inc(gAgentBridgePipeMetrics.RequestReadByteCount, aByteCount);
      Inc(gAgentBridgePipeMetrics.RequestReadResizeCount, aResizeCount);
      gAgentBridgePipeMetrics.RequestReadLastElapsedTicks := aElapsedTicks;
      Inc(gAgentBridgePipeMetrics.RequestReadTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordAgentBridgeChildClientOriginProbe;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.AgentBridgeChildClientOriginProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordAgentBridgeFocusProbe;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.AgentBridgeFocusProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordAgentBridgeRttiPropertyLookup;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.AgentBridgeRttiPropertyLookupCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordAgentBridgeScreenRectProbe;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.AgentBridgeScreenRectProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordActiveVisibleTreeProbe;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ActiveVisibleTreeProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordVclAdapterRttiPropertyLookup;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.VclAdapterRttiPropertyLookupCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.Log(const aMessage: string);
begin
  if not gDiagnosticsWriterLock.TryBeginRead then
  begin
    Exit;
  end;
  try
    if gDiagnosticsWriter <> nil then
    begin
      gDiagnosticsWriter.Enqueue(aMessage);
    end;
  finally
    gDiagnosticsWriterLock.EndRead;
  end;
end;

class procedure TAccessibilityDiagnostics.RecordMemoPrepareChildren(aLineProbeCount: Integer; aProviderCreatedCount:
  Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.MemoPrepareChildrenCount);
      Inc(gProviderHotspotMetrics.MemoLineProbeCount, aLineProbeCount);
      Inc(gProviderHotspotMetrics.MemoLineProviderCreatedCount, aProviderCreatedCount);
      gProviderHotspotMetrics.MemoPrepareChildrenLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.MemoPrepareChildrenTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderHotspotListBoxGetSelection(aItemProbeCount: Integer;
  aProviderCount: Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ListBoxGetSelectionCount);
      Inc(gProviderHotspotMetrics.ListBoxSelectionItemProbeCount, aItemProbeCount);
      Inc(gProviderHotspotMetrics.ListBoxSelectionProviderCount, aProviderCount);
      gProviderHotspotMetrics.ListBoxGetSelectionLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.ListBoxGetSelectionTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderHotspotListBoxSelectionProviderListAllocation;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ListBoxSelectionProviderListAllocationCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderBoundaryCall(aCall: TAccessibilityProviderBoundaryCall);
begin
  RecordProviderBoundaryCall(aCall, 0);
end;

class procedure TAccessibilityDiagnostics.RecordHintTextPreparation;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.HintTextPreparationCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordManagerHookLookup(aProbeCount: Integer);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ManagerHookLookupCount);
      Inc(gProviderHotspotMetrics.ManagerHookLookupProbeCount, aProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordManagerRetainedHookPassivation(aLinearScanCount: Integer);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ManagerRetainedHookPassivateCount);
      Inc(gProviderHotspotMetrics.ManagerRetainedHookLinearScanCount, aLinearScanCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderFocusAnnouncementText(aDetailProbeCount: Integer);
begin
  RecordProviderFocusAnnouncementText(aDetailProbeCount, 0);
end;

class procedure TAccessibilityDiagnostics.RecordProviderFocusAnnouncementText(aDetailProbeCount: Integer;
  aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ProviderFocusAnnouncementTextCount);
      Inc(gProviderHotspotMetrics.ProviderFocusAnnouncementDetailProbeCount, aDetailProbeCount);
      if aElapsedTicks > 0 then
      begin
        gProviderHotspotMetrics.ProviderFocusAnnouncementTextLastElapsedTicks := aElapsedTicks;
        Inc(gProviderHotspotMetrics.ProviderFocusAnnouncementTextTotalElapsedTicks, aElapsedTicks);
      end;
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderNotification(aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ProviderNotificationCount);
      if aElapsedTicks > 0 then
      begin
        gProviderHotspotMetrics.ProviderNotificationLastElapsedTicks := aElapsedTicks;
        Inc(gProviderHotspotMetrics.ProviderNotificationTotalElapsedTicks, aElapsedTicks);
      end;
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderEventBatch;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ProviderEventBatchCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderChildListAllocation;
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ProviderChildListAllocationCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderRuntimeIdBlockCopy(aElementCount: Integer);
begin
  if (aElementCount <= 0) or (not gProviderHotspotMetricsEnabled) then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ProviderRuntimeIdBlockCopyCount);
      Inc(gProviderHotspotMetrics.ProviderRuntimeIdBlockCopyElementCount, aElementCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderRuntimeIdElementCopy(aElementCount: Integer);
begin
  if (aElementCount <= 0) or (not gProviderHotspotMetricsEnabled) then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.ProviderRuntimeIdElementCopyCount, aElementCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordProviderBoundaryCall(aCall: TAccessibilityProviderBoundaryCall;
  aElapsedTicks: Int64);

  procedure AddBoundaryMetrics(var aCount: Integer; var aTotalElapsedTicks: Int64);
  begin
    Inc(aCount);
    Inc(aTotalElapsedTicks, aElapsedTicks);
    Inc(gProviderHotspotMetrics.ProviderBoundaryTotalElapsedTicks, aElapsedTicks);
  end;

begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if not gProviderHotspotMetricsEnabled then
    begin
      Exit;
    end;

    case aCall of
      pbcGetBoundingRectangle:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderGetBoundingRectangleCount,
          gProviderHotspotMetrics.ProviderGetBoundingRectangleTotalElapsedTicks);
      pbcGetFragmentRoot:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderGetFragmentRootCount,
          gProviderHotspotMetrics.ProviderGetFragmentRootTotalElapsedTicks);
      pbcGetHostRawElementProvider:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderGetHostRawElementProviderCount,
          gProviderHotspotMetrics.ProviderGetHostRawElementProviderTotalElapsedTicks);
      pbcGetPatternProvider:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderGetPatternProviderCount,
          gProviderHotspotMetrics.ProviderGetPatternProviderTotalElapsedTicks);
      pbcGetPropertyValue:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderGetPropertyValueCount,
          gProviderHotspotMetrics.ProviderGetPropertyValueTotalElapsedTicks);
      pbcGetProviderOptions:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderGetProviderOptionsCount,
          gProviderHotspotMetrics.ProviderGetProviderOptionsTotalElapsedTicks);
      pbcGetRuntimeId:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderGetRuntimeIdCount,
          gProviderHotspotMetrics.ProviderGetRuntimeIdTotalElapsedTicks);
      pbcNavigate:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderNavigateCount,
          gProviderHotspotMetrics.ProviderNavigateTotalElapsedTicks);
      pbcSetFocus:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderSetFocusCount,
          gProviderHotspotMetrics.ProviderSetFocusTotalElapsedTicks);
      pbcRootElementProviderFromPoint:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderRootElementProviderFromPointCount,
          gProviderHotspotMetrics.ProviderRootElementProviderFromPointTotalElapsedTicks);
      pbcRootGetFocus:
        AddBoundaryMetrics(gProviderHotspotMetrics.ProviderRootGetFocusCount,
          gProviderHotspotMetrics.ProviderRootGetFocusTotalElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordScannerFlattenedNodesBuild(aItemCount: Integer);
begin
  if not gScannerMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gScannerMetricsEnabled then
    begin
      Inc(gScannerMetrics.FlattenedNodesBuildCount);
      Inc(gScannerMetrics.FlattenedNodesBuildItemCount, aItemCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordScannerFlattenedNodesSnapshot(aItemCount: Integer);
begin
  if not gScannerMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gScannerMetricsEnabled then
    begin
      Inc(gScannerMetrics.FlattenedNodesSnapshotCount);
      Inc(gScannerMetrics.FlattenedNodesSnapshotItemCount, aItemCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordScannerRttiPropertyCacheKeyBuild;
begin
  if not gScannerMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gScannerMetricsEnabled then
    begin
      Inc(gScannerMetrics.RttiPropertyCacheKeyBuildCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordScannerRttiPropertyLookup;
begin
  if not gScannerMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gScannerMetricsEnabled then
    begin
      Inc(gScannerMetrics.RttiPropertyLookupCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordScannerSortedChildren(aItemCount: Integer; aSorted: Boolean);
begin
  if not gScannerMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gScannerMetricsEnabled then
    begin
      Inc(gScannerMetrics.SortedChildrenCallCount);
      Inc(gScannerMetrics.SortedChildrenItemCount, aItemCount);
      if aSorted then
      begin
        Inc(gScannerMetrics.SortedChildrenSortCount);
      end else begin
        Inc(gScannerMetrics.SortedChildrenAlreadyOrderedCount);
      end;
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordStringGridRefresh(aCellProbeCount: Integer; aProviderCreatedCount:
  Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.StringGridRefreshCount);
      Inc(gProviderHotspotMetrics.StringGridCellProbeCount, aCellProbeCount);
      Inc(gProviderHotspotMetrics.StringGridCellProviderCreatedCount, aProviderCreatedCount);
      gProviderHotspotMetrics.StringGridRefreshLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.StringGridRefreshTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordStringGridRefreshScratchListAllocation(aCount: Integer);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.StringGridRefreshScratchListAllocationCount, aCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordStringGridCellBounds(aCellProbeCount: Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.StringGridCellBoundsBuildCount);
      Inc(gProviderHotspotMetrics.StringGridCellBoundsCellProbeCount, aCellProbeCount);
      gProviderHotspotMetrics.StringGridCellBoundsLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.StringGridCellBoundsTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordStringGridRowRefresh(aRowProbeCount: Integer;
  aProviderCreatedCount: Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.StringGridRowRefreshCount);
      Inc(gProviderHotspotMetrics.StringGridRowProbeCount, aRowProbeCount);
      Inc(gProviderHotspotMetrics.StringGridRowProviderCreatedCount, aProviderCreatedCount);
      gProviderHotspotMetrics.StringGridRowRefreshLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.StringGridRowRefreshTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordStringGridRowRefreshScratchListAllocation(aCount: Integer);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.StringGridRowRefreshScratchListAllocationCount, aCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordStringGridRowText(aCellProbeCount: Integer;
  aHeaderProbeCount: Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.StringGridRowTextBuildCount);
      Inc(gProviderHotspotMetrics.StringGridRowTextCellProbeCount, aCellProbeCount);
      Inc(gProviderHotspotMetrics.StringGridRowTextHeaderProbeCount, aHeaderProbeCount);
      gProviderHotspotMetrics.StringGridRowTextLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.StringGridRowTextTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordStringGridRowBounds(aCellProbeCount: Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.StringGridRowBoundsBuildCount);
      Inc(gProviderHotspotMetrics.StringGridRowBoundsCellProbeCount, aCellProbeCount);
      gProviderHotspotMetrics.StringGridRowBoundsLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.StringGridRowBoundsTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordTmsAdvStringGridRefreshScratchListAllocation(aCount: Integer);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.TmsAdvStringGridRefreshScratchListAllocationCount, aCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordTmsAdvStringGridRefresh(aCellProbeCount: Integer;
  aProviderCreatedCount: Integer; aElapsedTicks: Int64);
begin
  if not gProviderHotspotMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gProviderHotspotMetricsEnabled then
    begin
      Inc(gProviderHotspotMetrics.TmsAdvStringGridRefreshCount);
      Inc(gProviderHotspotMetrics.TmsAdvStringGridCellProbeCount, aCellProbeCount);
      Inc(gProviderHotspotMetrics.TmsAdvStringGridCellProviderCreatedCount, aProviderCreatedCount);
      gProviderHotspotMetrics.TmsAdvStringGridRefreshLastElapsedTicks := aElapsedTicks;
      Inc(gProviderHotspotMetrics.TmsAdvStringGridRefreshTotalElapsedTicks, aElapsedTicks);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxAutomationEvent(aEventId: Integer);
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if not gListBoxFocusMetricsEnabled then
    begin
      Exit;
    end;

    Inc(gListBoxFocusMetrics.AutomationEventCount);
    if aEventId = UIA_SelectionItem_ElementSelectedEventId then
    begin
      Inc(gListBoxFocusMetrics.SelectionEventCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxEnsureItemProvider(aCreated: Boolean);
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if not gListBoxFocusMetricsEnabled then
    begin
      Exit;
    end;

    Inc(gListBoxFocusMetrics.EnsureItemProviderCount);
    if aCreated then
    begin
      Inc(gListBoxFocusMetrics.CreatedItemProviderCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxFocusMovement(aElapsedTicks: Int64);
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if not gListBoxFocusMetricsEnabled then
    begin
      Exit;
    end;

    Inc(gListBoxFocusMetrics.FocusMovementCount);
    gListBoxFocusMetrics.LastElapsedTicks := aElapsedTicks;
    Inc(gListBoxFocusMetrics.TotalElapsedTicks, aElapsedTicks);
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxGetFocus;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.GetFocusCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxGetSelection;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.GetSelectionCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxItemTextProbe;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.ItemTextProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxNativeHandlePublicationCheck;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.NativeHandlePublicationCheckCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxGridFocusProbe;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.GridFocusProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxItemIndexProbe;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.ItemIndexProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxNotification(aDisplayStringLength: Integer);
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled and (aDisplayStringLength > 0) then
    begin
      Inc(gListBoxFocusMetrics.NotificationCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxPrepareChildren;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.PrepareChildrenCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.RecordListBoxVisibleItemProbe;
begin
  if not gListBoxFocusMetricsEnabled then
  begin
    Exit;
  end;

  TMonitor.Enter(gDiagnosticsLock);
  try
    if gListBoxFocusMetricsEnabled then
    begin
      Inc(gListBoxFocusMetrics.VisibleItemProbeCount);
    end;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.ResetAgentBridgePipeMetrics;
var
  lEnabled: Boolean;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    lEnabled := gAgentBridgePipeMetricsEnabled;
    gAgentBridgePipeMetrics := Default(TAccessibilityAgentBridgePipeMetrics);
    gAgentBridgePipeMetrics.Enabled := lEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.ResetListBoxFocusMetrics;
var
  lEnabled: Boolean;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    lEnabled := gListBoxFocusMetricsEnabled;
    gListBoxFocusMetrics := Default(TAccessibilityListBoxFocusMetrics);
    gListBoxFocusMetrics.Enabled := lEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
var
  lEnabled: Boolean;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    lEnabled := gProviderHotspotMetricsEnabled;
    gProviderHotspotMetrics := Default(TAccessibilityProviderHotspotMetrics);
    gProviderHotspotMetrics.Enabled := lEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.ResetScannerMetrics;
var
  lEnabled: Boolean;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    lEnabled := gScannerMetricsEnabled;
    gScannerMetrics := Default(TAccessibilityScannerMetrics);
    gScannerMetrics.Enabled := lEnabled;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class function TAccessibilityDiagnosticsInternals.DroppedLogRecordCount: Int64;
begin
  gDiagnosticsWriterLock.BeginRead;
  try
    if gDiagnosticsWriter <> nil then
    begin
      Exit(gDiagnosticsWriter.DroppedRecordCount);
    end;
    Result := 0;
  finally
    gDiagnosticsWriterLock.EndRead;
  end;
end;

class function TAccessibilityDiagnosticsInternals.FlushLog(aTimeoutMs: Cardinal): Boolean;
begin
  gDiagnosticsWriterLock.BeginRead;
  try
    Result := (gDiagnosticsWriter = nil) or gDiagnosticsWriter.Flush(aTimeoutMs);
  finally
    gDiagnosticsWriterLock.EndRead;
  end;
end;

class function TAccessibilityDiagnosticsInternals.LogFileWriteThreadId: Cardinal;
begin
  gDiagnosticsWriterLock.BeginRead;
  try
    if gDiagnosticsWriter <> nil then
    begin
      Exit(gDiagnosticsWriter.LogFileWriteThreadId);
    end;
    Result := 0;
  finally
    gDiagnosticsWriterLock.EndRead;
  end;
end;

class function TAccessibilityDiagnosticsInternals.PendingLogRecordCount: Integer;
begin
  gDiagnosticsWriterLock.BeginRead;
  try
    if gDiagnosticsWriter <> nil then
    begin
      Exit(gDiagnosticsWriter.PendingRecordCount);
    end;
    Result := 0;
  finally
    gDiagnosticsWriterLock.EndRead;
  end;
end;

class procedure TAccessibilityDiagnosticsInternals.PauseLogWriter(aPaused: Boolean);
begin
  if gDiagnosticsWriter <> nil then
  begin
    gDiagnosticsWriter.Pause(aPaused);
  end;
end;

class function TAccessibilityDiagnosticsInternals.QueueCapacity: Integer;
begin
  Result := cDiagnosticsLogQueueCapacity;
end;

class procedure TAccessibilityDiagnosticsInternals.SetMaximumLogBytes(aMaxBytes: Int64);
begin
  gDiagnosticsWriterLock.BeginWrite;
  try
    if gDiagnosticsWriter <> nil then
    begin
      gDiagnosticsWriter.SetMaximumLogBytes(aMaxBytes);
    end;
  finally
    gDiagnosticsWriterLock.EndWrite;
  end;
end;

class function TAccessibilityDiagnosticsInternals.WriterAcceptingRecords: Boolean;
begin
  Result := (gDiagnosticsWriter <> nil) and gDiagnosticsWriter.IsEnabled;
end;

class function TAccessibilityDiagnosticsInternals.WriterStarted: Boolean;
begin
  gDiagnosticsWriterLock.BeginRead;
  try
    Result := (gDiagnosticsWriter <> nil) and gDiagnosticsWriter.WriterStarted;
  finally
    gDiagnosticsWriterLock.EndRead;
  end;
end;

initialization
  gDiagnosticsLock := TObject.Create;
  gDiagnosticsWriter := TAccessibilityDiagnosticWriter.Create;

finalization
  gDiagnosticsWriterLock.BeginWrite;
  try
    FreeAndNil(gDiagnosticsWriter);
  finally
    gDiagnosticsWriterLock.EndWrite;
  end;
  gDiagnosticsLock.Free;

end.
