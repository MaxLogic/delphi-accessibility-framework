unit AccessibilityDemoMainForm;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes,
  Winapi.Windows,
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
    btnRuntimeSyncStep: TButton;
    btnSave: TSpeedButton;
    btnGlyphInfo: TSpeedButton;
    btnGlyphWarn: TSpeedButton;
    btnShowBalloon: TSpeedButton;
    btnShowModal: TButton;
    btnShowRegularHint: TButton;
    btnToggleDetails: TSpeedButton;
    chkAccessibilityEnabled: TCheckBox;
    chkIncludeArchived: TCheckBox;
    cmbQueue: TComboBox;
    DynamicContentTimer: TTimer;
    edtAmbiguousLabelDemo: TEdit;
    edtDynamicText: TEdit;
    edtSearch: TEdit;
    edtUnlabeledDemo: TEdit;
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
    pnlFilterAmbiguousRow: TPanel;
    pnlFilterLabeledEditRow: TPanel;
    pnlFilterSearchRow: TPanel;
    pnlFilterQueueRow: TPanel;
    pnlFilterOptions: TPanel;
    pnlFilterUnlabeledRow: TPanel;
    pnlInspector: TPanel;
    pnlInspectorButtons: TFlowPanel;
    pnlInspectorEventsRow: TPanel;
    pnlInspectorMetrics: TPanel;
    pnlRuntimeSyncActionRow: TPanel;
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
    staticAmbiguousCandidateA: TStaticText;
    staticAmbiguousCandidateB: TStaticText;
    staticDynamicCaption: TStaticText;
    staticDynamicEditLabel: TStaticText;
    StaticTextEvents: TStaticText;
    StaticTextQueue: TLabel;
    staticRuntimeSyncState: TStaticText;
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
    procedure btnRuntimeSyncStepClick(aSender: TObject);
    procedure btnSaveClick(aSender: TObject);
    procedure btnShowBalloonClick(aSender: TObject);
    procedure btnShowModalClick(aSender: TObject);
    procedure btnShowRegularHintClick(aSender: TObject);
    procedure btnToggleDetailsClick(aSender: TObject);
    procedure chkAccessibilityEnabledClick(aSender: TObject);
    procedure DynamicContentTimerTimer(aSender: TObject);
    procedure FormCreate(aSender: TObject);
    procedure FormDestroy(aSender: TObject);
    procedure ToolButtonClick(aSender: TObject);
  private
    fDynamicContentRevision: Integer;
    fRuntimeSyncAmbiguousCandidateLeft: Integer;
    fRuntimeSyncChild: TEdit;
    fRuntimeSyncInitialCaption: string;
    fRuntimeSyncInitialLabeledEditCaption: string;
    fRuntimeSyncStep: Integer;
    procedure AdvanceRuntimeSyncScenario;
    procedure FillAdvStringGrid;
    procedure FillEventList;
    procedure FillMemo;
    procedure FillOrderGrid(aGrid: TStringGrid);
    procedure FillStringGrid;
    procedure RefreshStatus(const aAction: string);
    procedure SyncAccessibilityToggle;
    procedure UpdateDynamicContent;
    procedure UpdateRuntimeSyncStatus(const aDescription: string);
  end;

var
  AccessibilityDemoMain: TAccessibilityDemoMainForm;

function DemoAccessibilityFrameworkEnabled: Boolean;
procedure SetDemoAccessibilityFrameworkEnabled(aEnabled: Boolean);

implementation

uses
  AutoFree,
  MaxLogic.Accessibility.Manager,
  MaxLogic.Accessibility.TmsAdvStringGridAdapters;

{$R *.dfm}

type
  TWinControlAccess = class(TWinControl);

resourcestring
  rsActionApplied = 'Filters applied';
  rsAccessibilityDisabled = 'Accessibility framework disabled';
  rsAccessibilityEnabled = 'Accessibility framework enabled';
  rsActionOpened = 'Toolbar command executed';
  rsActionRefreshed = 'Demo data refreshed';
  rsActionSaved = 'Demo state saved';
  rsAgentControlModalMessage = 'This modal dialog is available for deterministic agent-control discovery and shutdown checks.';
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
  rsRuntimeChildHint = 'Control added and reparented by the runtime synchronization walkthrough';
  rsRuntimeChildText = 'Runtime hierarchy child';
  rsRuntimeControlRecreatedFormat = 'control HWND recreated from %d to %d';
  rsRuntimeEditHint = 'TEdit runtime hint';
  rsRuntimeEditValue = 'TEdit runtime value';
  rsRuntimeExplicitAdded = 'control added and explicit label reassigned';
  rsRuntimeAdvStringGridEdge = 'runtime TAdvStringGrid edge';
  rsRuntimeBitButtonCaption = 'TBitBtn runtime caption';
  rsRuntimeBitButtonHint = 'TBitBtn runtime hint';
  rsRuntimeButtonCaption = 'TButton runtime caption';
  rsRuntimeButtonHint = 'TButton runtime hint';
  rsRuntimeFormCaption = 'Accessibility Framework Demo - runtime properties';
  rsRuntimeFormRecreatedCaption = 'Accessibility Framework Demo - runtime properties - recreated';
  rsRuntimeFormRecreatedFormat = 'form HWND recreated from %d to %d';
  rsRuntimeGridText = 'runtime grid value';
  rsRuntimeGridsGrown = 'grid values changed and shapes grown';
  rsRuntimeGridsReset = 'grid shapes shrunk to their original bounds';
  rsRuntimeHierarchyRemoved = 'runtime control removed';
  rsRuntimeHierarchyReparented = 'runtime control reparented and explicit label restored';
  rsRuntimeInferredAmbiguous = 'inferred label returned to the ambiguous state';
  rsRuntimeInferredResolved = 'ambiguous input now has one inferred label';
  rsRuntimeLabelCaption = 'TLabel runtime caption';
  rsRuntimeLabelHint = 'TLabel runtime hint';
  rsRuntimeLabeledEditHidden = 'TLabeledEdit label hidden and relationship removed';
  rsRuntimeLabeledEditRestored = 'TLabeledEdit label restored with current text';
  rsRuntimeLabeledEditText = 'TLabeledEdit runtime label';
  rsRuntimeNextStepFormat = 'Next runtime sync step (%d)';
  rsRuntimePropertiesChanged = 'form and control properties changed';
  rsRuntimePropertiesRestored = 'control visibility, enabled state, and bounds restored';
  rsRuntimeReady = 'ready';
  rsRuntimeReset = 'Reset runtime sync walkthrough';
  rsRuntimeStaticCaption = 'TStaticText runtime caption';
  rsRuntimeStaticHint = 'TStaticText runtime hint';
  rsRuntimeStatusFormat = 'Step %.2d: %s';
  rsRuntimeStringGridEdge = 'runtime TStringGrid edge';
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
    TAccessibilityManager.Install(Application, [TAccessibilityTmsAdvStringGridAdapters.RegisterAdapters]);
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

procedure TAccessibilityDemoMainForm.AdvanceRuntimeSyncScenario;
var
  lDescription: string;
  lOldHandle: HWND;
begin
  lDescription := '';
  case fRuntimeSyncStep of
    1:
      begin
        DynamicContentTimer.Enabled := False;
        Caption := rsRuntimeFormCaption;
        staticDynamicCaption.Caption := rsRuntimeStaticCaption;
        staticDynamicCaption.Hint := rsRuntimeStaticHint;
        staticDynamicCaption.Align := alLeft;
        staticDynamicCaption.Width := ScaleValue(300);
        lblDynamicCaption.Caption := rsRuntimeLabelCaption;
        lblDynamicCaption.Hint := rsRuntimeLabelHint;
        edtDynamicText.Text := rsRuntimeEditValue;
        edtDynamicText.Hint := rsRuntimeEditHint;
        btnDynamicCaption.Caption := rsRuntimeButtonCaption;
        btnDynamicCaption.Hint := rsRuntimeButtonHint;
        btnDynamicCaption.Enabled := False;
        bitBtnDynamicCaption.Caption := rsRuntimeBitButtonCaption;
        bitBtnDynamicCaption.Hint := rsRuntimeBitButtonHint;
        bitBtnDynamicCaption.Visible := False;
        lDescription := rsRuntimePropertiesChanged;
      end;
    2:
      begin
        btnDynamicCaption.Enabled := True;
        bitBtnDynamicCaption.Visible := True;
        staticDynamicCaption.Align := alClient;
        UpdateDynamicContent;
        lDescription := rsRuntimePropertiesRestored;
      end;
    3:
      begin
        cmbQueue.Visible := False;
        fRuntimeSyncChild := TEdit.Create(Self);
        fRuntimeSyncChild.Name := 'edtRuntimeSyncChild';
        fRuntimeSyncChild.Text := rsRuntimeChildText;
        fRuntimeSyncChild.Hint := rsRuntimeChildHint;
        fRuntimeSyncChild.ShowHint := True;
        fRuntimeSyncChild.Parent := pnlFilterQueueRow;
        fRuntimeSyncChild.Align := alBottom;
        fRuntimeSyncChild.TabOrder := 0;
        StaticTextQueue.FocusControl := fRuntimeSyncChild;
        lDescription := rsRuntimeExplicitAdded;
      end;
    4:
      begin
        StaticTextQueue.FocusControl := cmbQueue;
        cmbQueue.Visible := True;
        fRuntimeSyncChild.Parent := pnlDynamicButtonRow;
        fRuntimeSyncChild.Align := alRight;
        fRuntimeSyncChild.Width := ScaleValue(240);
        lDescription := rsRuntimeHierarchyReparented;
      end;
    5:
      begin
        FreeAndNil(fRuntimeSyncChild);
        lDescription := rsRuntimeHierarchyRemoved;
      end;
    6:
      begin
        staticAmbiguousCandidateB.Left := pnlFilterAmbiguousRow.Width + ScaleValue(32);
        lDescription := rsRuntimeInferredResolved;
      end;
    7:
      begin
        staticAmbiguousCandidateB.Left := fRuntimeSyncAmbiguousCandidateLeft;
        lDescription := rsRuntimeInferredAmbiguous;
      end;
    8:
      begin
        labeledEditReference.EditLabel.Visible := False;
        lDescription := rsRuntimeLabeledEditHidden;
      end;
    9:
      begin
        labeledEditReference.EditLabel.Caption := rsRuntimeLabeledEditText;
        labeledEditReference.EditLabel.Visible := True;
        lDescription := rsRuntimeLabeledEditRestored;
      end;
    10:
      begin
        StringGridOrderCells.ColCount := StringGridOrderCells.ColCount + 1;
        StringGridOrderCells.RowCount := StringGridOrderCells.RowCount + 1;
        StringGridOrderCells.Cells[1, 1] := rsRuntimeGridText;
        StringGridOrderCells.Cells[Pred(StringGridOrderCells.ColCount),
          Pred(StringGridOrderCells.RowCount)] := rsRuntimeStringGridEdge;
        AdvStringGridAudit.UnHideColumnsAll;
        AdvStringGridAudit.UnHideRowsAll;
        AdvStringGridAudit.SplitAllCells;
        AdvStringGridAudit.ColCount := AdvStringGridAudit.ColCount + 1;
        AdvStringGridAudit.RowCount := AdvStringGridAudit.RowCount + 1;
        AdvStringGridAudit.Cells[2, 2] := rsRuntimeGridText;
        AdvStringGridAudit.Cells[Pred(AdvStringGridAudit.ColCount),
          Pred(AdvStringGridAudit.RowCount)] := rsRuntimeAdvStringGridEdge;
        lDescription := rsRuntimeGridsGrown;
      end;
    11:
      begin
        FillStringGrid;
        FillAdvStringGrid;
        lDescription := rsRuntimeGridsReset;
      end;
    12:
      begin
        lOldHandle := StringGridOrderCells.Handle;
        TWinControlAccess(StringGridOrderCells).RecreateWnd;
        lDescription := Format(rsRuntimeControlRecreatedFormat,
          [lOldHandle, StringGridOrderCells.Handle]);
      end;
    13:
      begin
        lOldHandle := Handle;
        Caption := rsRuntimeFormRecreatedCaption;
        RecreateWnd;
        lDescription := Format(rsRuntimeFormRecreatedFormat, [lOldHandle, Handle]);
      end;
  else
    begin
      fRuntimeSyncStep := 0;
      FreeAndNil(fRuntimeSyncChild);
      Caption := fRuntimeSyncInitialCaption;
      StaticTextQueue.FocusControl := cmbQueue;
      cmbQueue.Visible := True;
      staticAmbiguousCandidateB.Left := fRuntimeSyncAmbiguousCandidateLeft;
      labeledEditReference.EditLabel.Caption := fRuntimeSyncInitialLabeledEditCaption;
      labeledEditReference.EditLabel.Visible := True;
      btnDynamicCaption.Enabled := True;
      bitBtnDynamicCaption.Visible := True;
      staticDynamicCaption.Align := alClient;
      FillStringGrid;
      FillAdvStringGrid;
      UpdateDynamicContent;
      DynamicContentTimer.Enabled := True;
      lDescription := rsRuntimeReady;
    end;
  end;
  UpdateRuntimeSyncStatus(lDescription);
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

procedure TAccessibilityDemoMainForm.btnRuntimeSyncStepClick(aSender: TObject);
begin
  Inc(fRuntimeSyncStep);
  AdvanceRuntimeSyncScenario;
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
  BalloonHideTimer.Enabled := True; // FI:W508 - disabling then enabling intentionally restarts the timeout.
  RefreshStatus(rsBalloonTitle);
end;

procedure TAccessibilityDemoMainForm.btnShowModalClick(aSender: TObject);
var
  g: TGarbos; //PALOFF Delphi initializes this managed record before GC aggregation
  lDialog: TForm;
begin
  GC(lDialog, CreateMessageDialog(rsAgentControlModalMessage, mtInformation, [mbOK]), g);
  lDialog.ShowModal;
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
  fRuntimeSyncInitialCaption := Caption;
  fRuntimeSyncInitialLabeledEditCaption := labeledEditReference.EditLabel.Caption;
  fRuntimeSyncAmbiguousCandidateLeft := staticAmbiguousCandidateB.Left;
  fRuntimeSyncStep := 0;
  fDynamicContentRevision := 0;
  UpdateDynamicContent;
  UpdateRuntimeSyncStatus(rsRuntimeReady);
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

procedure TAccessibilityDemoMainForm.UpdateRuntimeSyncStatus(const aDescription: string);
begin
  staticRuntimeSyncState.Caption := Format(rsRuntimeStatusFormat, [fRuntimeSyncStep, aDescription]);
  if fRuntimeSyncStep >= 13 then
  begin
    btnRuntimeSyncStep.Caption := rsRuntimeReset;
  end else begin
    btnRuntimeSyncStep.Caption := Format(rsRuntimeNextStepFormat, [Succ(fRuntimeSyncStep)]);
  end;
end;

end.
