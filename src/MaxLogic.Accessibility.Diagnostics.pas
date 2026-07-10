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

implementation

uses
  System.IOUtils, System.SysUtils, Winapi.Windows, MaxLogic.Accessibility.UIAutomationCore;

var
  gAgentBridgePipeMetrics: TAccessibilityAgentBridgePipeMetrics;
  gAgentBridgePipeMetricsEnabled: Boolean;
  gDiagnosticsLock: TObject;
  gListBoxFocusMetrics: TAccessibilityListBoxFocusMetrics;
  gListBoxFocusMetricsEnabled: Boolean;
  gLogFile: string;
  gProviderHotspotMetrics: TAccessibilityProviderHotspotMetrics;
  gProviderHotspotMetricsEnabled: Boolean;
  gScannerMetrics: TAccessibilityScannerMetrics;
  gScannerMetricsEnabled: Boolean;

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
  TMonitor.Enter(gDiagnosticsLock);
  try
    gLogFile := aLogFile;
  finally
    TMonitor.Exit(gDiagnosticsLock);
  end;
end;

class procedure TAccessibilityDiagnostics.Disable;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    gLogFile := '';
  finally
    TMonitor.Exit(gDiagnosticsLock);
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
  TMonitor.Enter(gDiagnosticsLock);
  try
    Result := gLogFile <> '';
  finally
    TMonitor.Exit(gDiagnosticsLock);
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
var
  lDirectory: string;
  lLine: string;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    if gLogFile = '' then
    begin
      Exit;
    end;

    lDirectory := ExtractFilePath(gLogFile);
    if lDirectory <> '' then
    begin
      ForceDirectories(lDirectory);
    end;

    lLine := Format('%s pid=%d tid=%d %s%s',
      [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now), GetCurrentProcessId, GetCurrentThreadId, aMessage,
      sLineBreak]);
    TFile.AppendAllText(gLogFile, lLine, TEncoding.UTF8);
  finally
    TMonitor.Exit(gDiagnosticsLock);
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

initialization
  gDiagnosticsLock := TObject.Create;

finalization
  gDiagnosticsLock.Free;

end.
