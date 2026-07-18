unit AccessibilityDemoMainForm;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Buttons, Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.Grids,
  Vcl.StdCtrls,
  AdvGrid;

type
  TAccessibilityDemoMainForm = class(TForm)
    AdvStringGridAudit: TAdvStringGrid;
    BalloonHideTimer: TTimer;
    BalloonHint: TBalloonHint;
    bitBtnDynamicCaption: TBitBtn;
    btnApplyFilters: TButton;
    btnClose: TButton;
    btnDynamicCaption: TButton;
    btnNewWindow: TSpeedButton;
    btnRefresh: TSpeedButton;
    btnSave: TSpeedButton;
    btnGlyphInfo: TSpeedButton;
    btnGlyphWarn: TSpeedButton;
    btnShowBalloon: TSpeedButton;
    btnShowRegularHint: TButton;
    btnToggleDetails: TSpeedButton;
    chkAccessibilityEnabled: TCheckBox;
    chkIncludeArchived: TCheckBox;
    cmbQueue: TComboBox;
    DynamicContentTimer: TTimer;
    edtDynamicText: TEdit;
    edtSearch: TEdit;
    grpViewMode: TGroupBox;
    lblAuditMetric: TLabel;
    lblCellsSummary: TLabel;
    lblCommandTitle: TLabel;
    lblDetailsHeading: TLabel;
    lblDynamicCaption: TLabel;
    lblDynamicInstructions: TLabel;
    lblInspectorTitle: TLabel;
    lblMetricsHeading: TLabel;
    lblOrdersSummary: TLabel;
    lblSearchHelp: TLabel;
    lblSeverityMetric: TLabel;
    lblTmsSummary: TLabel;
    lblWrappedMemoHeading: TLabel;
    labeledEditReference: TLabeledEdit;
    lstEvents: TListBox;
    memoDetailsUnwrapped: TMemo;
    memoDetailsWrapped: TMemo;
    PageControl: TPageControl;
    pnlActions: TFlowPanel;
    pnlClient: TPanel;
    pnlCellsHeader: TPanel;
    pnlCommandBar: TPanel;
    pnlDetailsMemoRow: TPanel;
    pnlDynamicBitButtonRow: TPanel;
    pnlDynamicButtonRow: TPanel;
    pnlDynamicContent: TPanel;
    pnlDynamicEditRow: TPanel;
    pnlDynamicLabelRow: TPanel;
    pnlDynamicStaticTextRow: TPanel;
    pnlFilters: TPanel;
    pnlFilterLabeledEditRow: TPanel;
    pnlFilterSearchRow: TPanel;
    pnlFilterQueueRow: TPanel;
    pnlFilterOptions: TPanel;
    pnlInspector: TPanel;
    pnlInspectorButtons: TFlowPanel;
    pnlInspectorEventsRow: TPanel;
    pnlInspectorMetrics: TPanel;
    pnlWrappedMemoRow: TPanel;
    pnlOrdersHeader: TPanel;
    pnlTmsHeader: TPanel;
    radioGroupDensity: TRadioGroup;
    rbViewCompact: TRadioButton;
    rbViewDetailed: TRadioButton;
    SplitterInspector: TSplitter;
    SplitterFilters: TSplitter;
    StaticTextDetails: TStaticText;
    StaticTextDetailsWrapped: TStaticText;
    staticDynamicCaption: TStaticText;
    staticDynamicEditLabel: TStaticText;
    StaticTextEvents: TStaticText;
    StaticTextQueue: TLabel;
    StaticTextSearch: TStaticText;
    StatusBar: TStatusBar;
    StringGridOrderCells: TStringGrid;
    StringGridOrders: TStringGrid;
    tabOrderCells: TTabSheet;
    tabMemoNoWrap: TTabSheet;
    tabMemoWrap: TTabSheet;
    tabDynamicContent: TTabSheet;
    tabOrders: TTabSheet;
    tabTms: TTabSheet;
    ToolBar: TToolBar;
    ToolButtonAudit: TToolButton;
    ToolButtonExport: TToolButton;
    ToolButtonOpen: TToolButton;
    ToolButtonSeparator: TToolButton;
    procedure BalloonHideTimerTimer(aSender: TObject);
    procedure btnApplyFiltersClick(aSender: TObject);
    procedure btnCloseClick(aSender: TObject);
    procedure btnNewWindowClick(aSender: TObject);
    procedure btnRefreshClick(aSender: TObject);
    procedure btnSaveClick(aSender: TObject);
    procedure btnShowBalloonClick(aSender: TObject);
    procedure btnShowRegularHintClick(aSender: TObject);
    procedure btnToggleDetailsClick(aSender: TObject);
    procedure chkAccessibilityEnabledClick(aSender: TObject);
    procedure DynamicContentTimerTimer(aSender: TObject);
    procedure FormCreate(aSender: TObject);
    procedure FormDestroy(aSender: TObject);
    procedure ToolButtonClick(aSender: TObject);
  private
    fDynamicContentRevision: Integer;
    procedure FillAdvStringGrid;
    procedure FillEventList;
    procedure FillMemo;
    procedure FillOrderGrid(aGrid: TStringGrid);
    procedure FillStringGrid;
    procedure RefreshStatus(const aAction: string);
    procedure SyncAccessibilityToggle;
    procedure UpdateDynamicContent;
  end;

var
  AccessibilityDemoMain: TAccessibilityDemoMainForm;

function DemoAccessibilityFrameworkEnabled: Boolean;
procedure SetDemoAccessibilityFrameworkEnabled(aEnabled: Boolean);

implementation

uses
  MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.TmsAdvStringGridAdapters;

{$R *.dfm}

resourcestring
  rsActionApplied = 'Filters applied';
  rsAccessibilityDisabled = 'Accessibility framework disabled';
  rsAccessibilityEnabled = 'Accessibility framework enabled';
  rsActionOpened = 'Toolbar command executed';
  rsActionRefreshed = 'Demo data refreshed';
  rsActionSaved = 'Demo state saved';
  rsBalloonDescription = 'The accessibility manager observes hints and exposes them through UI Automation.';
  rsBalloonTitle = 'Balloon hint raised';
  rsDetailsHidden = 'Details panel hidden';
  rsDetailsVisible = 'Details panel visible';
  rsDynamicBitButtonCaptionFormat = 'TBitBtn caption %d';
  rsDynamicBitButtonHintFormat = 'TBitBtn hint updated for cycle %d';
  rsDynamicButtonCaptionFormat = 'TButton caption %d';
  rsDynamicButtonHintFormat = 'TButton hint updated for cycle %d';
  rsDynamicEditHintFormat = 'TEdit hint updated for cycle %d';
  rsDynamicEditTextFormat = 'TEdit text %d';
  rsDynamicLabelCaptionFormat = 'TLabel caption %d';
  rsDynamicLabelHintFormat = 'TLabel hint updated for cycle %d';
  rsDynamicStaticTextCaptionFormat = 'TStaticText caption %d';
  rsDynamicStaticTextHintFormat = 'TStaticText hint updated for cycle %d';
  rsStatusFormat = '%s at %s';
  rsWindowCaptionFormat = 'Accessibility Framework Demo - Window %d';

var
  gAccessibilityFrameworkEnabled: Boolean;
  gSyncingAccessibilityToggle: Boolean;
  gWindowCount: Integer;

function DemoAccessibilityFrameworkEnabled: Boolean;
begin
  Result := gAccessibilityFrameworkEnabled;
end;

procedure SyncDemoAccessibilityToggles;
var
  i: Integer;
  lForm: TAccessibilityDemoMainForm;
begin
  gSyncingAccessibilityToggle := True;
  try
    for i := 0 to Pred(Screen.FormCount) do
    begin
      if Screen.Forms[i] is TAccessibilityDemoMainForm then
      begin
        lForm := TAccessibilityDemoMainForm(Screen.Forms[i]);
        lForm.SyncAccessibilityToggle;
      end;
    end;
  finally
    gSyncingAccessibilityToggle := False;
  end;
end;

procedure SetDemoAccessibilityFrameworkEnabled(aEnabled: Boolean);
begin
  if gAccessibilityFrameworkEnabled = aEnabled then
  begin
    SyncDemoAccessibilityToggles;
    Exit;
  end;

  if aEnabled then
  begin
    TAccessibilityManager.Install(Application, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);
  end else begin
    TAccessibilityManager.Uninstall;
  end;

  gAccessibilityFrameworkEnabled := aEnabled;
  SyncDemoAccessibilityToggles;
end;

procedure TAccessibilityDemoMainForm.BalloonHideTimerTimer(aSender: TObject);
begin
  BalloonHideTimer.Enabled := False;
  BalloonHint.HideHint;
end;

procedure TAccessibilityDemoMainForm.btnApplyFiltersClick(aSender: TObject);
begin
  RefreshStatus(rsActionApplied);
end;

procedure TAccessibilityDemoMainForm.btnCloseClick(aSender: TObject);
begin
  Close;
end;

procedure TAccessibilityDemoMainForm.btnNewWindowClick(aSender: TObject);
var
  lForm: TAccessibilityDemoMainForm;
begin
  lForm := TAccessibilityDemoMainForm.Create(Application);
  lForm.Show;
end;

procedure TAccessibilityDemoMainForm.btnRefreshClick(aSender: TObject);
begin
  FillStringGrid;
  FillAdvStringGrid;
  FillEventList;
  FillMemo;
  RefreshStatus(rsActionRefreshed);
end;

procedure TAccessibilityDemoMainForm.btnSaveClick(aSender: TObject);
begin
  RefreshStatus(rsActionSaved);
end;

procedure TAccessibilityDemoMainForm.btnShowBalloonClick(aSender: TObject);
begin
  BalloonHint.Title := rsBalloonTitle;
  BalloonHint.Description := rsBalloonDescription;
  BalloonHint.ShowHint(btnShowBalloon);
  BalloonHideTimer.Enabled := False;
  BalloonHideTimer.Enabled := True;
  RefreshStatus(rsBalloonTitle);
end;

procedure TAccessibilityDemoMainForm.btnShowRegularHintClick(aSender: TObject);
begin
  Application.ActivateHint(btnShowRegularHint.ClientToScreen(Point(btnShowRegularHint.Width div 2,
    btnShowRegularHint.Height div 2)));
end;

procedure TAccessibilityDemoMainForm.btnToggleDetailsClick(aSender: TObject);
begin
  pnlInspector.Visible := not pnlInspector.Visible;
  SplitterInspector.Visible := pnlInspector.Visible;
  if pnlInspector.Visible then
  begin
    RefreshStatus(rsDetailsVisible);
  end else begin
    RefreshStatus(rsDetailsHidden);
  end;
end;

procedure TAccessibilityDemoMainForm.chkAccessibilityEnabledClick(aSender: TObject);
begin
  if gSyncingAccessibilityToggle then
  begin
    Exit;
  end;

  SetDemoAccessibilityFrameworkEnabled(chkAccessibilityEnabled.Checked);
  if DemoAccessibilityFrameworkEnabled then
  begin
    RefreshStatus(rsAccessibilityEnabled);
  end else begin
    RefreshStatus(rsAccessibilityDisabled);
  end;
end;

procedure TAccessibilityDemoMainForm.DynamicContentTimerTimer(aSender: TObject);
begin
  Inc(fDynamicContentRevision);
  UpdateDynamicContent;
end;

procedure TAccessibilityDemoMainForm.FillAdvStringGrid;
begin
  AdvStringGridAudit.UnHideColumnsAll;
  AdvStringGridAudit.UnHideRowsAll;
  AdvStringGridAudit.SplitAllCells;
  AdvStringGridAudit.ColCount := 8;
  AdvStringGridAudit.RowCount := 14;
  AdvStringGridAudit.FixedCols := 1;
  AdvStringGridAudit.FixedRows := 1;
  AdvStringGridAudit.Cells[0, 0] := 'Area';
  AdvStringGridAudit.Cells[1, 0] := 'Owner';
  AdvStringGridAudit.Cells[2, 0] := 'Finding';
  AdvStringGridAudit.Cells[3, 0] := 'Severity';
  AdvStringGridAudit.Cells[4, 0] := 'Next step';
  AdvStringGridAudit.Cells[0, 1] := 'Labels';
  AdvStringGridAudit.Cells[1, 1] := 'UI';
  AdvStringGridAudit.Cells[2, 1] := 'TLabel exposed by framework tree';
  AdvStringGridAudit.Cells[3, 1] := 'Info';
  AdvStringGridAudit.Cells[4, 1] := 'Verify with NVDA object navigation';
  AdvStringGridAudit.Cells[0, 2] := 'Speed buttons';
  AdvStringGridAudit.Cells[1, 2] := 'Commands';
  AdvStringGridAudit.Cells[2, 2] := 'Invoke pattern should click the control';
  AdvStringGridAudit.Cells[3, 2] := 'High';
  AdvStringGridAudit.Cells[4, 2] := 'Activate toolbar buttons';
  AdvStringGridAudit.Cells[0, 3] := 'Hints';
  AdvStringGridAudit.Cells[1, 3] := 'Notifications';
  AdvStringGridAudit.Cells[2, 3] := 'Short and long hint text available';
  AdvStringGridAudit.Cells[3, 3] := 'Medium';
  AdvStringGridAudit.Cells[4, 3] := 'Hover or press balloon hint';
  AdvStringGridAudit.Cells[0, 4] := 'TStringGrid';
  AdvStringGridAudit.Cells[1, 4] := 'Orders';
  AdvStringGridAudit.Cells[2, 4] := 'Cell hit testing reads one cell';
  AdvStringGridAudit.Cells[3, 4] := 'High';
  AdvStringGridAudit.Cells[4, 4] := 'Move mouse across rows';
  AdvStringGridAudit.Cells[0, 5] := 'TAdvStringGrid';
  AdvStringGridAudit.Cells[1, 5] := 'Audit';
  AdvStringGridAudit.Cells[2, 5] := 'Opt-in TMS adapter exposes cells';
  AdvStringGridAudit.Cells[3, 5] := 'High';
  AdvStringGridAudit.Cells[4, 5] := 'Move mouse across rows';
  AdvStringGridAudit.Cells[0, 6] := 'Panels';
  AdvStringGridAudit.Cells[1, 6] := 'Layout';
  AdvStringGridAudit.Cells[2, 6] := 'Named regions exposed as groups';
  AdvStringGridAudit.Cells[3, 6] := 'Info';
  AdvStringGridAudit.Cells[4, 6] := 'Review UIA tree';
  AdvStringGridAudit.Cells[0, 7] := 'Future forms';
  AdvStringGridAudit.Cells[1, 7] := 'Manager';
  AdvStringGridAudit.Cells[2, 7] := 'App-wide install scans new windows';
  AdvStringGridAudit.Cells[3, 7] := 'High';
  AdvStringGridAudit.Cells[4, 7] := 'Press New Window';
  AdvStringGridAudit.MergeCells(5, 1, 3, 1);
  AdvStringGridAudit.Cells[5, 1] := 'Hidden column merge base';
  AdvStringGridAudit.MergeCells(1, 8, 1, 3);
  AdvStringGridAudit.WideCells[1, 8] := 'Hidden row merge base';
  AdvStringGridAudit.MergeCells(2, 11, 1, 2);
  AdvStringGridAudit.Cells[2, 11] := 'Fully hidden merge';
  AdvStringGridAudit.HideColumn(5);
  AdvStringGridAudit.HideRow(8);
  AdvStringGridAudit.HideRow(11);
  AdvStringGridAudit.HideRow(12);
end;

procedure TAccessibilityDemoMainForm.FillEventList;
begin
  lstEvents.Items.BeginUpdate;
  try
    lstEvents.Items.Clear;
    lstEvents.Items.Add('09:00 Order #24018 received');
    lstEvents.Items.Add('09:12 QA note added to selected order');
    lstEvents.Items.Add('09:35 Shipping window changed');
    lstEvents.Items.Add('10:05 Audit rule flagged missing label');
    lstEvents.Items.Add('10:42 Balloon hint test ready');
  finally
    lstEvents.Items.EndUpdate;
  end;
end;

procedure TAccessibilityDemoMainForm.FillMemo;
begin
  memoDetailsUnwrapped.Lines.BeginUpdate;
  try
    memoDetailsUnwrapped.Lines.Clear;
    memoDetailsUnwrapped.Lines.Add('This memo has WordWrap disabled, so each logical line stays on one visual line.');
    memoDetailsUnwrapped.Lines.Add('Hover the first, second, and third lines to verify the framework reports the line under the pointer.');
    memoDetailsUnwrapped.Lines.Add('Use the New Window button to create another form instance after app-wide installation.');
  finally
    memoDetailsUnwrapped.Lines.EndUpdate;
  end;

  memoDetailsWrapped.Lines.BeginUpdate;
  try
    memoDetailsWrapped.Lines.Clear;
    memoDetailsWrapped.Lines.Add('This memo has WordWrap enabled and intentionally contains a long sentence that should wrap across several visual rows inside the memo client area.');
    memoDetailsWrapped.Lines.Add('Move the mouse over each wrapped visual row to compare NVDA speech against the no-wrap memo tab.');
    memoDetailsWrapped.Lines.Add('Keyboard arrow movement should continue to use the native edit behavior for both memo variants.');
  finally
    memoDetailsWrapped.Lines.EndUpdate;
  end;
end;

procedure TAccessibilityDemoMainForm.FillOrderGrid(aGrid: TStringGrid);
begin
  aGrid.ColCount := 5;
  aGrid.RowCount := 7;
  aGrid.FixedCols := 0;
  aGrid.FixedRows := 1;
  aGrid.Cells[0, 0] := 'Order';
  aGrid.Cells[1, 0] := 'Customer';
  aGrid.Cells[2, 0] := 'State';
  aGrid.Cells[3, 0] := 'Value';
  aGrid.Cells[4, 0] := 'Hint';
  aGrid.Cells[0, 1] := '#24018';
  aGrid.Cells[1, 1] := 'Northwind';
  aGrid.Cells[2, 1] := 'Packed';
  aGrid.Cells[3, 1] := '1,240.00';
  aGrid.Cells[4, 1] := 'Mouse over should read this cell only';
  aGrid.Cells[0, 2] := '#24019';
  aGrid.Cells[1, 2] := 'Contoso';
  aGrid.Cells[2, 2] := 'Waiting';
  aGrid.Cells[3, 2] := '560.00';
  aGrid.Cells[4, 2] := 'Second order note';
  aGrid.Cells[0, 3] := '#24020';
  aGrid.Cells[1, 3] := 'Fabrikam';
  aGrid.Cells[2, 3] := 'Blocked';
  aGrid.Cells[3, 3] := '3,430.00';
  aGrid.Cells[4, 3] := 'Blocked by missing address';
  aGrid.Cells[0, 4] := '#24021';
  aGrid.Cells[1, 4] := 'Adventure Works';
  aGrid.Cells[2, 4] := 'Ready';
  aGrid.Cells[3, 4] := '980.00';
  aGrid.Cells[4, 4] := 'Ready for courier';
  aGrid.Cells[0, 5] := '#24022';
  aGrid.Cells[1, 5] := 'Wide World Importers';
  aGrid.Cells[2, 5] := 'Review';
  aGrid.Cells[3, 5] := '2,115.00';
  aGrid.Cells[4, 5] := 'Manual accessibility review';
  aGrid.Cells[0, 6] := '#24023';
  aGrid.Cells[1, 6] := 'Tailspin';
  aGrid.Cells[2, 6] := 'New';
  aGrid.Cells[3, 6] := '430.00';
  aGrid.Cells[4, 6] := 'New record';
end;

procedure TAccessibilityDemoMainForm.FillStringGrid;
begin
  FillOrderGrid(StringGridOrders);
  FillOrderGrid(StringGridOrderCells);
end;

procedure TAccessibilityDemoMainForm.FormCreate(aSender: TObject);
begin
  Inc(gWindowCount);
  Caption := Format(rsWindowCaptionFormat, [gWindowCount]);
  fDynamicContentRevision := 0;
  UpdateDynamicContent;
  SyncAccessibilityToggle;
  cmbQueue.ItemIndex := 0;
  FillStringGrid;
  FillAdvStringGrid;
  FillEventList;
  FillMemo;
  RefreshStatus(rsActionRefreshed);
end;

procedure TAccessibilityDemoMainForm.FormDestroy(aSender: TObject);
begin
  BalloonHideTimer.Enabled := False;
  DynamicContentTimer.Enabled := False;
  BalloonHint.HideHint;
end;

procedure TAccessibilityDemoMainForm.RefreshStatus(const aAction: string);
begin
  StatusBar.SimpleText := Format(rsStatusFormat, [aAction, DateTimeToStr(Now)]);
end;

procedure TAccessibilityDemoMainForm.SyncAccessibilityToggle;
begin
  chkAccessibilityEnabled.Checked := DemoAccessibilityFrameworkEnabled;
end;

procedure TAccessibilityDemoMainForm.ToolButtonClick(aSender: TObject);
begin
  RefreshStatus(rsActionOpened);
end;

procedure TAccessibilityDemoMainForm.UpdateDynamicContent;
begin
  staticDynamicCaption.Caption := Format(rsDynamicStaticTextCaptionFormat, [fDynamicContentRevision]);
  staticDynamicCaption.Hint := Format(rsDynamicStaticTextHintFormat, [fDynamicContentRevision]);
  lblDynamicCaption.Caption := Format(rsDynamicLabelCaptionFormat, [fDynamicContentRevision]);
  lblDynamicCaption.Hint := Format(rsDynamicLabelHintFormat, [fDynamicContentRevision]);
  edtDynamicText.Text := Format(rsDynamicEditTextFormat, [fDynamicContentRevision]);
  edtDynamicText.Hint := Format(rsDynamicEditHintFormat, [fDynamicContentRevision]);
  btnDynamicCaption.Caption := Format(rsDynamicButtonCaptionFormat, [fDynamicContentRevision]);
  btnDynamicCaption.Hint := Format(rsDynamicButtonHintFormat, [fDynamicContentRevision]);
  bitBtnDynamicCaption.Caption := Format(rsDynamicBitButtonCaptionFormat, [fDynamicContentRevision]);
  bitBtnDynamicCaption.Hint := Format(rsDynamicBitButtonHintFormat, [fDynamicContentRevision]);
end;

end.
