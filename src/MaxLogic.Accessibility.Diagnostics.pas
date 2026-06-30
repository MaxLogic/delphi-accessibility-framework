unit MaxLogic.Accessibility.Diagnostics;

interface

type
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
    LastElapsedTicks: Int64;
    TotalElapsedTicks: Int64;
    function ToJson(const aScenario: string; const aSource: string): string;
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
    StringGridRefreshLastElapsedTicks: Int64;
    StringGridRefreshTotalElapsedTicks: Int64;
    TmsAdvStringGridRefreshCount: Integer;
    TmsAdvStringGridCellProbeCount: Integer;
    TmsAdvStringGridCellProviderCreatedCount: Integer;
    TmsAdvStringGridRefreshLastElapsedTicks: Int64;
    TmsAdvStringGridRefreshTotalElapsedTicks: Int64;
    ListBoxGetSelectionCount: Integer;
    ListBoxSelectionItemProbeCount: Integer;
    ListBoxSelectionProviderCount: Integer;
    ListBoxGetSelectionLastElapsedTicks: Int64;
    ListBoxGetSelectionTotalElapsedTicks: Int64;
    function ToJson(const aScenario: string; const aSource: string): string;
  end;

  TAccessibilityDiagnostics = record
  public
    class procedure Configure(const aLogFile: string); static;
    class procedure Disable; static;
    class procedure DisableListBoxFocusMetrics; static;
    class procedure DisableProviderHotspotMetrics; static;
    class function Enabled: Boolean; static;
    class procedure EnableListBoxFocusMetrics; static;
    class procedure EnableProviderHotspotMetrics; static;
    class function ListBoxFocusMetrics: TAccessibilityListBoxFocusMetrics; static;
    class function ListBoxFocusMetricsEnabled: Boolean; static;
    class procedure Log(const aMessage: string); static;
    class function ProviderHotspotMetrics: TAccessibilityProviderHotspotMetrics; static;
    class function ProviderHotspotMetricsEnabled: Boolean; static;
    class procedure RecordListBoxAutomationEvent(aEventId: Integer); static;
    class procedure RecordListBoxEnsureItemProvider(aCreated: Boolean); static;
    class procedure RecordListBoxFocusMovement(aElapsedTicks: Int64); static;
    class procedure RecordListBoxGetFocus; static;
    class procedure RecordListBoxGetSelection; static;
    class procedure RecordListBoxItemTextProbe; static;
    class procedure RecordListBoxNotification(aDisplayStringLength: Integer); static;
    class procedure RecordListBoxPrepareChildren; static;
    class procedure RecordListBoxVisibleItemProbe; static;
    class procedure RecordMemoPrepareChildren(aLineProbeCount: Integer; aProviderCreatedCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordProviderHotspotListBoxGetSelection(aItemProbeCount: Integer; aProviderCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordStringGridRefresh(aCellProbeCount: Integer; aProviderCreatedCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure RecordTmsAdvStringGridRefresh(aCellProbeCount: Integer; aProviderCreatedCount: Integer;
      aElapsedTicks: Int64); static;
    class procedure ResetListBoxFocusMetrics; static;
    class procedure ResetProviderHotspotMetrics; static;
  end;

implementation

uses
  System.IOUtils, System.SysUtils, Winapi.Windows, MaxLogic.Accessibility.UIAutomationCore;

var
  gDiagnosticsLock: TObject;
  gListBoxFocusMetrics: TAccessibilityListBoxFocusMetrics;
  gListBoxFocusMetricsEnabled: Boolean;
  gLogFile: string;
  gProviderHotspotMetrics: TAccessibilityProviderHotspotMetrics;
  gProviderHotspotMetricsEnabled: Boolean;

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
    ',"lastElapsedTicks":' + IntToStr(LastElapsedTicks) + ',"totalElapsedTicks":' + IntToStr(TotalElapsedTicks) +
    '}';
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
    ',"stringGridRefreshLastElapsedTicks":' + IntToStr(StringGridRefreshLastElapsedTicks) +
    ',"stringGridRefreshTotalElapsedTicks":' + IntToStr(StringGridRefreshTotalElapsedTicks) +
    ',"tmsAdvStringGridRefreshCount":' + IntToStr(TmsAdvStringGridRefreshCount) +
    ',"tmsAdvStringGridCellProbeCount":' + IntToStr(TmsAdvStringGridCellProbeCount) +
    ',"tmsAdvStringGridCellProviderCreatedCount":' + IntToStr(TmsAdvStringGridCellProviderCreatedCount) +
    ',"tmsAdvStringGridRefreshLastElapsedTicks":' + IntToStr(TmsAdvStringGridRefreshLastElapsedTicks) +
    ',"tmsAdvStringGridRefreshTotalElapsedTicks":' + IntToStr(TmsAdvStringGridRefreshTotalElapsedTicks) +
    ',"listBoxGetSelectionCount":' + IntToStr(ListBoxGetSelectionCount) + ',"listBoxSelectionItemProbeCount":' +
    IntToStr(ListBoxSelectionItemProbeCount) + ',"listBoxSelectionProviderCount":' +
    IntToStr(ListBoxSelectionProviderCount) + ',"listBoxGetSelectionLastElapsedTicks":' +
    IntToStr(ListBoxGetSelectionLastElapsedTicks) + ',"listBoxGetSelectionTotalElapsedTicks":' +
    IntToStr(ListBoxGetSelectionTotalElapsedTicks) + '}';
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

class function TAccessibilityDiagnostics.Enabled: Boolean;
begin
  TMonitor.Enter(gDiagnosticsLock);
  try
    Result := gLogFile <> '';
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

class function TAccessibilityDiagnostics.ListBoxFocusMetricsEnabled: Boolean;
begin
  Result := gListBoxFocusMetricsEnabled;
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

initialization
  gDiagnosticsLock := TObject.Create;

finalization
  gDiagnosticsLock.Free;

end.
