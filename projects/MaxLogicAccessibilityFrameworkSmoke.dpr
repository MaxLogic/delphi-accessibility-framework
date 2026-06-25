program MaxLogicAccessibilityFrameworkSmoke;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Types, System.Variants, Winapi.ActiveX, Winapi.Messages, Winapi.Windows, Vcl.Buttons,
  Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, AdvGrid,
  MaxLogic.Accessibility.Framework in '..\src\MaxLogic.Accessibility.Framework.pas',
  MaxLogic.Accessibility.Hints in '..\src\MaxLogic.Accessibility.Hints.pas',
  MaxLogic.Accessibility.Manager in '..\src\MaxLogic.Accessibility.Manager.pas',
  MaxLogic.Accessibility.ProviderCore in '..\src\MaxLogic.Accessibility.ProviderCore.pas',
  MaxLogic.Accessibility.TmsAdvStringGridAdapters in '..\src\MaxLogic.Accessibility.TmsAdvStringGridAdapters.pas',
  MaxLogic.Accessibility.UIAutomationCore in '..\src\MaxLogic.Accessibility.UIAutomationCore.pas',
  MaxLogic.Accessibility.VclAdapters in '..\src\MaxLogic.Accessibility.VclAdapters.pas';

type
  TProbeGraphicControl = class(TGraphicControl)
  private
    fCaption: string;
  protected
    procedure Paint; override;
  published
    property Caption: string read fCaption write fCaption;
  end;

  TProbeClickRecorder = class
  private
    fClicks: Integer;
  public
    procedure Click(aSender: TObject);
    property Clicks: Integer read fClicks;
  end;

  // The probe records UIA notifications locally because real delivery depends on an external UIA client.
  IProbeUiaApi = interface(IAccessibilityUiaApi)
    ['{6CA4B57C-626A-48B6-98C9-7313E69692E2}']
    function LastDisplayString: string;
    function NotificationCalls: Integer;
    function ReturnedProvider: IRawElementProviderSimple;
    procedure SetClientsAreListening(aValue: Boolean);
  end;

  TProbeUiaApi = class(TInterfacedObject, IProbeUiaApi)
  private
    fClientsAreListening: Boolean;
    fLastDisplayString: string;
    fNotificationCalls: Integer;
    fReturnedProvider: IRawElementProviderSimple;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastDisplayString: string;
    function NotificationCalls: Integer;
    function ReturnedProvider: IRawElementProviderSimple;
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
    procedure SetClientsAreListening(aValue: Boolean);
  end;

procedure TProbeGraphicControl.Paint;
begin
end;

procedure TProbeClickRecorder.Click(aSender: TObject);
begin
  Inc(fClicks);
end;

function TProbeUiaApi.ClientsAreListening: Boolean;
begin
  Result := fClientsAreListening;
end;

function TProbeUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Result := S_OK;
end;

function TProbeUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function TProbeUiaApi.LastDisplayString: string;
begin
  Result := fLastDisplayString;
end;

function TProbeUiaApi.NotificationCalls: Integer;
begin
  Result := fNotificationCalls;
end;

function TProbeUiaApi.ReturnedProvider: IRawElementProviderSimple;
begin
  Result := fReturnedProvider;
end;

function TProbeUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
begin
  Result := S_OK;
end;

function TProbeUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := S_OK;
end;

function TProbeUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
  aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Inc(fNotificationCalls);
  fLastDisplayString := aDisplayString;
  Result := S_OK;
end;

function TProbeUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Result := S_OK;
end;

function TProbeUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  fReturnedProvider := aProvider;
  Result := 97531;
end;

procedure TProbeUiaApi.SetClientsAreListening(aValue: Boolean);
begin
  fClientsAreListening := aValue;
end;

procedure Require(aCondition: Boolean; const aMessage: string);
begin
  if not aCondition then
  begin
    raise Exception.Create(aMessage);
  end;
end;

function ScaleValue(aValue: Integer): Integer;
begin
  Result := MulDiv(aValue, Screen.PixelsPerInch, 96);
end;

function FragmentProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Require(Supports(aFragment, IRawElementProviderSimple, Result), 'Fragment does not expose simple provider.');
end;

function FragmentFromSimple(const aProvider: IRawElementProviderSimple): IRawElementProviderFragment;
begin
  Result := nil;
  Require(Supports(aProvider, IRawElementProviderFragment, Result), 'Simple provider is not a fragment.');
end;

function FragmentRoot(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragmentRoot;
begin
  Result := nil;
  Require(Supports(aProvider.RawElementProvider, IRawElementProviderFragmentRoot, Result),
    'Provider does not expose a fragment root.');
end;

function NavigateFragment(const aFragment: IRawElementProviderFragment; aDirection: NavigateDirection;
  const aDescription: string; aRequired: Boolean): IRawElementProviderFragment;
var
  lResult: HResult;
begin
  Result := nil;
  lResult := aFragment.Navigate(aDirection, Result);
  Require(lResult = S_OK, Format('%s navigation returned 0x%x.', [aDescription, Cardinal(lResult)]));
  if aRequired then
  begin
    Require(Result <> nil, aDescription + ' was not found.');
  end;
end;

function FirstChild(const aProvider: IAccessibilityProviderNode; const aDescription: string): IRawElementProviderFragment;
begin
  Result := NavigateFragment(aProvider.FragmentProvider, NavigateDirection_FirstChild, aDescription, True);
end;

function FirstNestedChild(const aFragment: IRawElementProviderFragment; const aDescription: string):
  IRawElementProviderFragment;
begin
  Result := NavigateFragment(aFragment, NavigateDirection_FirstChild, aDescription, True);
end;

function NextSibling(const aFragment: IRawElementProviderFragment; const aDescription: string):
  IRawElementProviderFragment;
begin
  Result := NavigateFragment(aFragment, NavigateDirection_NextSibling, aDescription, True);
end;

function OptionalNextSibling(const aFragment: IRawElementProviderFragment; const aDescription: string):
  IRawElementProviderFragment;
begin
  Result := NavigateFragment(aFragment, NavigateDirection_NextSibling, aDescription, False);
end;

function PatternProvider(const aFragment: IRawElementProviderFragment; aPatternId: PATTERNID): IUnknown;
var
  lResult: HResult;
begin
  Result := nil;
  lResult := FragmentProvider(aFragment).GetPatternProvider(aPatternId, Result);
  Require(lResult = S_OK, Format('Pattern %d returned 0x%x.', [aPatternId, Cardinal(lResult)]));
end;

function ProviderIntProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): Integer;
var
  lResult: HResult;
  lValue: OleVariant;
begin
  lValue := Unassigned;
  lResult := FragmentProvider(aFragment).GetPropertyValue(aPropertyId, lValue);
  Require(lResult = S_OK, Format('Property %d returned 0x%x.', [aPropertyId, Cardinal(lResult)]));
  Result := Integer(lValue);
end;

function ProviderStringProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lResult: HResult;
  lValue: OleVariant;
begin
  lValue := Unassigned;
  lResult := FragmentProvider(aFragment).GetPropertyValue(aPropertyId, lValue);
  Require(lResult = S_OK, Format('Property %d returned 0x%x.', [aPropertyId, Cardinal(lResult)]));
  Result := string(lValue);
end;

function ScreenCellCenter(aGrid: TStringGrid; aCol: Integer; aRow: Integer): TPoint;
var
  lCellRect: TRect;
begin
  lCellRect := aGrid.CellRect(aCol, aRow);
  Require((lCellRect.Width > 0) and (lCellRect.Height > 0), 'Probe target cell is not visible.');
  Result := aGrid.ClientToScreen(Point((lCellRect.Left + lCellRect.Right) div 2,
    (lCellRect.Top + lCellRect.Bottom) div 2));
end;

function PointFromMessageResult(aValue: LRESULT): TPoint;
begin
  Result := Point(Smallint(Word(aValue and $FFFF)), Smallint(Word((aValue shr 16) and $FFFF)));
end;

function AdvCellVisibleRect(aGrid: TAdvStringGrid; aCol: Integer; aRow: Integer; out aRect: TRect): Boolean;
var
  lBaseCell: TPoint;
  lCellRect: TRect;
  lExpectedCell: TPoint;
  lHitCell: TPoint;
  lHitCol: Integer;
  lHitPoint: TPoint;
  lHitRow: Integer;
  lRealCell: TPoint;
  lRealHitCell: TPoint;
begin
  aRect := TRect.Empty;
  lRealCell := Point(aGrid.RealColIndex(aCol), aRow);
  if aGrid.IsHiddenColumn(lRealCell.X) or aGrid.IsHiddenRow(aGrid.RealRowIndex(aRow)) or
    aGrid.IsMergedNonBaseCell(lRealCell.X, lRealCell.Y) then
  begin
    Exit(False);
  end;

  lCellRect := aGrid.CellRect(aCol, aRow);
  if not ((lCellRect.Width > 0) and (lCellRect.Height > 0) and
    IntersectRect(aRect, lCellRect, Rect(0, 0, aGrid.ClientWidth, aGrid.ClientHeight)) and
    (aRect.Width > 0) and (aRect.Height > 0)) then
  begin
    Exit(False);
  end;

  lHitPoint := Point((aRect.Left + aRect.Right) div 2, (aRect.Top + aRect.Bottom) div 2);
  lHitPoint := aGrid.ClientToScreen(lHitPoint);
  aGrid.ScreenToCell(lHitPoint, lHitCol, lHitRow);
  lExpectedCell := Point(aCol, aRow);
  lHitCell := Point(lHitCol, lHitRow);
  if (lHitCol >= 0) and (lHitCol < aGrid.ColCount) and (lHitRow >= 0) and (lHitRow < aGrid.RowCount) then
  begin
    lRealHitCell := Point(aGrid.RealColIndex(lHitCol), lHitRow);
    if aGrid.IsMergedNonBaseCell(lRealHitCell.X, lRealHitCell.Y) then
    begin
      lBaseCell := aGrid.BaseCell(lRealHitCell.X, lRealHitCell.Y);
      lHitCell := Point(aGrid.DisplColIndex(lBaseCell.X), lBaseCell.Y);
    end;
  end;

  Result := (lHitCell.X = lExpectedCell.X) and (lHitCell.Y = lExpectedCell.Y);
end;

function ScreenAdvCellCenter(aGrid: TAdvStringGrid; aCol: Integer; aRow: Integer): TPoint;
var
  lCellRect: TRect;
begin
  Require(AdvCellVisibleRect(aGrid, aCol, aRow, lCellRect), 'Probe target TMS cell is not visible.');
  Result := aGrid.ClientToScreen(Point((lCellRect.Left + lCellRect.Right) div 2,
    (lCellRect.Top + lCellRect.Bottom) div 2));
end;

function ChildNameExists(const aGridFragment: IRawElementProviderFragment; const aName: string): Boolean;
var
  lCell: IRawElementProviderFragment;
begin
  Result := False;
  lCell := NavigateFragment(aGridFragment, NavigateDirection_FirstChild, 'first grid cell fragment', False);
  while lCell <> nil do
  begin
    if ProviderStringProperty(lCell, UIA_NamePropertyId) = aName then
    begin
      Exit(True);
    end;

    lCell := NavigateFragment(lCell, NavigateDirection_NextSibling, 'next grid cell fragment', False);
  end;
end;

procedure RequireProvider(const aFragment: IRawElementProviderFragment; aControlTypeId: Integer; const aName: string;
  const aHelpText: string; const aDescription: string);
begin
  Require(ProviderIntProperty(aFragment, UIA_ControlTypePropertyId) = aControlTypeId,
    aDescription + ' control type mismatch.');
  Require(ProviderStringProperty(aFragment, UIA_NamePropertyId) = aName, aDescription + ' name mismatch.');
  Require(ProviderStringProperty(aFragment, UIA_HelpTextPropertyId) = aHelpText,
    aDescription + ' help text mismatch.');
end;

procedure RunBasicVclControlsProbe;
var
  lDecorativeGraphic: TProbeGraphicControl;
  lDecorativeLabel: TLabel;
  lEmptyPanel: TPanel;
  lForm: TForm;
  lGraphic: TProbeGraphicControl;
  lGraphicFragment: IRawElementProviderFragment;
  lInvoke: IInvokeProvider;
  lApi: IProbeUiaApi;
  lApplyButton: TButton;
  lApplyFragment: IRawElementProviderFragment;
  lCheckBox: TCheckBox;
  lCheckBoxFragment: IRawElementProviderFragment;
  lLabel: TLabel;
  lLabelFragment: IRawElementProviderFragment;
  lMessage: TMessage;
  lNestedFragment: IRawElementProviderFragment;
  lNestedLabel: TLabel;
  lPanel: TPanel;
  lPanelFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lRecorder: TProbeClickRecorder;
  lRootFragment: IRawElementProviderFragment;
  lRunButton: TSpeedButton;
  lRunFragment: IRawElementProviderFragment;
  lToggle: IToggleProvider;
  lToggleButton: TSpeedButton;
  lToggleFragment: IRawElementProviderFragment;
  lToggleState: ToggleState;
begin
  lForm := TForm.Create(nil);
  lRecorder := TProbeClickRecorder.Create;
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := '&Customer';
    lLabel.Hint := 'Customer label|Shown next to customer edit';
    lLabel.Parent := lForm;

    lDecorativeLabel := TLabel.Create(lForm);
    lDecorativeLabel.Name := 'DecorativeLabel';
    lDecorativeLabel.Caption := '';
    lDecorativeLabel.Parent := lForm;

    lRunButton := TSpeedButton.Create(lForm);
    lRunButton.Caption := '&Run';
    lRunButton.Hint := 'Runs the command';
    lRunButton.OnClick := lRecorder.Click;
    lRunButton.Parent := lForm;

    lToggleButton := TSpeedButton.Create(lForm);
    lToggleButton.Caption := '&Pinned';
    lToggleButton.Hint := 'Pinned state';
    lToggleButton.GroupIndex := 1;
    lToggleButton.AllowAllUp := True;
    lToggleButton.OnClick := lRecorder.Click;
    lToggleButton.Parent := lForm;

    lApplyButton := TButton.Create(lForm);
    lApplyButton.Caption := '&Apply Filters';
    lApplyButton.Hint := 'Apply the selected filters';
    lApplyButton.OnClick := lRecorder.Click;
    lApplyButton.Parent := lForm;

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Hint := 'Toggle archived rows in the demo grids';
    lCheckBox.Checked := True;
    lCheckBox.Parent := lForm;

    lPanel := TPanel.Create(lForm);
    lPanel.Name := 'LayoutPanel';
    lPanel.Caption := '';
    lPanel.Parent := lForm;

    lNestedLabel := TLabel.Create(lForm);
    lNestedLabel.Caption := 'Nested value';
    lNestedLabel.Parent := lPanel;

    lEmptyPanel := TPanel.Create(lForm);
    lEmptyPanel.Name := 'DecorativePanel';
    lEmptyPanel.Caption := '';
    lEmptyPanel.Parent := lForm;

    lGraphic := TProbeGraphicControl.Create(lForm);
    lGraphic.Caption := '&Custom graphic';
    lGraphic.Hint := 'Graphic help';
    lGraphic.Parent := lForm;

    lDecorativeGraphic := TProbeGraphicControl.Create(lForm);
    lDecorativeGraphic.Name := 'DecorativeGraphic';
    lDecorativeGraphic.Parent := lForm;

    lApi := TProbeUiaApi.Create;
    TAccessibilityManagerInternals.SetUiaApi(lApi);
    try
      TAccessibilityManager.Install(lForm);
      lForm.HandleNeeded;

      lMessage := Default(TMessage);
      lMessage.Msg := WM_GETOBJECT;
      lMessage.LParam := UiaRootObjectId;
      lForm.WindowProc(lMessage);
      Require(lMessage.Result = 97531, 'Manager install path did not return a UIA provider message result.');
      Require(lApi.ReturnedProvider <> nil, 'Manager install path did not pass a provider to UIA.');

      lRootFragment := FragmentFromSimple(lApi.ReturnedProvider);
    finally
      TAccessibilityManagerInternals.SetUiaApi(nil);
    end;

    lLabelFragment := FirstNestedChild(lRootFragment, 'label fragment');
    lRunFragment := NextSibling(lLabelFragment, 'run speed-button fragment');
    lToggleFragment := NextSibling(lRunFragment, 'toggle speed-button fragment');
    lApplyFragment := NextSibling(lToggleFragment, 'apply button fragment');
    lCheckBoxFragment := NextSibling(lApplyFragment, 'checkbox fragment');
    lPanelFragment := NextSibling(lCheckBoxFragment, 'panel fragment');
    lGraphicFragment := NextSibling(lPanelFragment, 'graphic-control fragment');
    Require(OptionalNextSibling(lGraphicFragment, 'decorative-control omission check') = nil,
      'Decorative controls were exposed after the graphic-control fragment.');

    RequireProvider(lLabelFragment, UIA_TextControlTypeId, 'Customer', 'Shown next to customer edit', 'label');
    RequireProvider(lRunFragment, UIA_ButtonControlTypeId, 'Run', 'Runs the command', 'run speed-button');
    RequireProvider(lToggleFragment, UIA_ButtonControlTypeId, 'Pinned', 'Pinned state', 'toggle speed-button');
    RequireProvider(lApplyFragment, UIA_ButtonControlTypeId, 'Apply Filters', 'Apply the selected filters',
      'apply button');
    RequireProvider(lCheckBoxFragment, UIA_CheckBoxControlTypeId, 'Include archived rows',
      'Toggle archived rows in the demo grids', 'checkbox');
    RequireProvider(lPanelFragment, UIA_PaneControlTypeId, '', '', 'panel-with-child');
    RequireProvider(lGraphicFragment, UIA_TextControlTypeId, 'Custom graphic', 'Graphic help', 'graphic-control');

    lNestedFragment := FirstNestedChild(lPanelFragment, 'panel child label fragment');
    RequireProvider(lNestedFragment, UIA_TextControlTypeId, 'Nested value', '', 'nested label');
    Require(OptionalNextSibling(lNestedFragment, 'panel child decorative omission check') = nil,
      'Unexpected extra child under panel.');

    lPattern := PatternProvider(lRunFragment, UIA_InvokePatternId);
    Require(Supports(lPattern, IInvokeProvider, lInvoke), 'Run speed-button does not expose Invoke.');
    Require(lInvoke.Invoke = S_OK, 'Run speed-button Invoke failed.');
    Require(lRecorder.Clicks = 1, 'Run speed-button Invoke did not click.');
    Require(PatternProvider(lRunFragment, UIA_TogglePatternId) = nil, 'Plain speed-button exposed Toggle.');

    lPattern := PatternProvider(lToggleFragment, UIA_InvokePatternId);
    Require(Supports(lPattern, IInvokeProvider, lInvoke), 'Toggle speed-button does not expose Invoke.');
    Require(lInvoke.Invoke = S_OK, 'Toggle speed-button Invoke failed.');
    Require(lRecorder.Clicks = 2, 'Toggle speed-button Invoke did not click.');

    lPattern := PatternProvider(lApplyFragment, UIA_InvokePatternId);
    Require(Supports(lPattern, IInvokeProvider, lInvoke), 'Apply button does not expose Invoke.');
    Require(lInvoke.Invoke = S_OK, 'Apply button Invoke failed.');
    Require(lRecorder.Clicks = 3, 'Apply button Invoke did not click.');

    lPattern := PatternProvider(lToggleFragment, UIA_TogglePatternId);
    Require(Supports(lPattern, IToggleProvider, lToggle), 'Toggle speed-button does not expose Toggle.');
    Require(lToggle.Get_ToggleState(lToggleState) = S_OK, 'Toggle state query failed.');
    Require(lToggleState = ToggleState_Off, 'Initial toggle state mismatch.');
    Require(lToggle.Toggle = S_OK, 'Toggle action failed.');
    Require(lToggleButton.Down, 'Toggle action did not update Down state.');
    Require(lToggle.Get_ToggleState(lToggleState) = S_OK, 'Post-toggle state query failed.');
    Require(lToggleState = ToggleState_On, 'Post-toggle state mismatch.');

    lPattern := PatternProvider(lCheckBoxFragment, UIA_TogglePatternId);
    Require(Supports(lPattern, IToggleProvider, lToggle), 'Checkbox does not expose Toggle.');
    Require(lToggle.Get_ToggleState(lToggleState) = S_OK, 'Checkbox state query failed.');
    Require(lToggleState = ToggleState_On, 'Initial checkbox state mismatch.');
    Require(lToggle.Toggle = S_OK, 'Checkbox toggle action failed.');
    Require(not lCheckBox.Checked, 'Checkbox toggle action did not clear Checked state.');
    Require(lToggle.Get_ToggleState(lToggleState) = S_OK, 'Post-checkbox state query failed.');
    Require(lToggleState = ToggleState_Off, 'Post-checkbox state mismatch.');
    Require(PatternProvider(lCheckBoxFragment, UIA_InvokePatternId) = nil, 'Checkbox exposed Invoke.');

    Writeln('UIA_PROBE_OK BasicVclControls: install-path=manager-wm-getobject; ' +
      'label provider=text name/help; button provider=button invoke; ' +
      'speed button provider=button invoke/toggle; checkbox provider=checkbox toggle; ' +
      'panel provider=pane with child; generic graphic-control provider=text; decorative controls omitted.');
  finally
    TAccessibilityManager.Uninstall;
    lRecorder.Free;
    lForm.Free;
  end;
end;

procedure RunTStringGridCellsProbe;
var
  lCellFragment: IRawElementProviderFragment;
  lCellProvider: IRawElementProviderSimple;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lHit: IRawElementProviderFragment;
  lPattern: IUnknown;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(420), ScaleValue(260));

    lGrid := TStringGrid.Create(lForm);
    lGrid.Name := 'OrdersGrid';
    lGrid.Parent := lForm;
    lGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(250), ScaleValue(115));
    lGrid.ColCount := 4;
    lGrid.RowCount := 4;
    lGrid.FixedCols := 1;
    lGrid.FixedRows := 1;
    lGrid.DefaultColWidth := ScaleValue(55);
    lGrid.DefaultRowHeight := ScaleValue(20);
    lGrid.ColWidths[3] := 0;
    lGrid.RowHeights[3] := 0;
    lGrid.Cells[0, 0] := 'ID';
    lGrid.Cells[1, 0] := 'Name';
    lGrid.Cells[2, 0] := 'Status';
    lGrid.Cells[0, 1] := '100';
    lGrid.Cells[1, 1] := 'Alice';
    lGrid.Cells[2, 1] := 'Running';
    lGrid.Cells[3, 3] := 'Hidden far cell';
    lGrid.Col := 2;
    lGrid.Row := 1;
    lForm.ActiveControl := lGrid;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lGridFragment := FirstChild(lProvider, 'string grid fragment');
    Require(ProviderIntProperty(lGridFragment, UIA_ControlTypePropertyId) = UIA_DataGridControlTypeId,
      'String grid did not expose the DataGrid control type.');

    lPattern := PatternProvider(lGridFragment, UIA_GridPatternId);
    Require(Supports(lPattern, IGridProvider, lGridPattern), 'String grid did not expose Grid pattern.');
    Require(lGridPattern.GetItem(1, 1, lCellProvider) = S_OK, 'Grid pattern GetItem failed.');
    lCellFragment := FragmentFromSimple(lCellProvider);
    Require(ProviderStringProperty(lCellFragment, UIA_NamePropertyId) = 'Alice', 'Grid cell name mismatch.');
    Require(ProviderIntProperty(lCellFragment, UIA_ControlTypePropertyId) = UIA_DataItemControlTypeId,
      'Grid cell did not expose the DataItem control type.');
    Require(not ChildNameExists(lGridFragment, 'Hidden far cell'), 'Hidden grid cell was exposed.');

    lPoint := ScreenCellCenter(lGrid, 1, 1);
    Require(lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit) = S_OK, 'Grid hit testing failed.');
    Require(lHit <> nil, 'Grid hit testing returned no cell provider.');
    Require(ProviderStringProperty(lHit, UIA_NamePropertyId) = 'Alice',
      'Grid hit testing returned the wrong cell provider.');
    Require(Pos('row', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) = 0,
      'Grid hit testing added row context to the default cell name.');
    Require(Pos('column', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) = 0,
      'Grid hit testing added column context to the default cell name.');

    Require(lRoot.GetFocus(lFocus) = S_OK, 'Grid focus query failed.');
    Require(lFocus <> nil, 'Grid focus query returned no cell provider.');
    Require(ProviderStringProperty(lFocus, UIA_NamePropertyId) = 'Running',
      'Grid focus query did not return the current cell.');

    Writeln('UIA_PROBE_OK TStringGridCells: DataGrid provider, visible cell fragments, per-cell provider hit testing, current-cell focus, hidden-cell omission, and cell-only names confirmed.');
  finally
    lForm.Free;
  end;
end;

procedure RunMemoListStatusProbe;
var
  lApi: IProbeUiaApi;
  lCharIndex: LRESULT;
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lItemRect: TRect;
  lLinePoint: TPoint;
  lListBox: TListBox;
  lMemo: TMemo;
  lMessage: TMessage;
  lPoint: TPoint;
  lRoot: IRawElementProviderFragmentRoot;
  lStatusBar: TStatusBar;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(460), ScaleValue(260));

    lMemo := TMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.ScrollBars := ssNone;
    lMemo.WordWrap := False;
    lMemo.SetBounds(ScaleValue(12), ScaleValue(12), ScaleValue(220), ScaleValue(80));
    lMemo.Lines.Text := 'First memo line' + sLineBreak + 'Second memo line';
    lMemo.HandleNeeded;

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(ScaleValue(250), ScaleValue(12), ScaleValue(160), ScaleValue(80));
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.Items.Add('Completed action');
    lListBox.ItemIndex := 1;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;

    lStatusBar := TStatusBar.Create(lForm);
    lStatusBar.Parent := lForm;
    lStatusBar.SimplePanel := True;
    lStatusBar.SimpleText := 'Ready. High severity checks: 4';
    lStatusBar.SetBounds(0, ScaleValue(210), ScaleValue(460), ScaleValue(24));
    lStatusBar.HandleNeeded;

    lApi := TProbeUiaApi.Create;
    lApi.SetClientsAreListening(True);
    TAccessibilityManagerInternals.SetUiaApi(lApi);
    try
      TAccessibilityManager.Install(lForm);
      lForm.HandleNeeded;

      lMessage := Default(TMessage);
      lMessage.Msg := WM_GETOBJECT;
      lMessage.LParam := UiaRootObjectId;
      lForm.WindowProc(lMessage);
      Require(lMessage.Result = 97531, 'MemoListStatus manager install path did not return a UIA provider.');
      Require(lApi.ReturnedProvider <> nil, 'MemoListStatus manager install path did not pass a provider.');
      Require(Supports(lApi.ReturnedProvider, IRawElementProviderFragmentRoot, lRoot),
        'MemoListStatus root provider does not expose hit testing.');

      lCharIndex := lMemo.Perform(EM_LINEINDEX, 1, 0);
      lLinePoint := PointFromMessageResult(lMemo.Perform(EM_POSFROMCHAR, lCharIndex, 0));
      lPoint := lMemo.ClientToScreen(Point(lLinePoint.X + ScaleValue(4), lLinePoint.Y + ScaleValue(2)));
      Require(lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit) = S_OK,
        'MemoListStatus memo hit-test failed.');
      Require(lHit <> nil, 'MemoListStatus memo hit-test returned nil.');
      RequireProvider(lHit, UIA_TextControlTypeId, 'Second memo line', '', 'memo line');

      lItemRect := lListBox.ItemRect(2);
      lPoint := lListBox.ClientToScreen(lItemRect.CenterPoint);
      Require(lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit) = S_OK,
        'MemoListStatus listbox hit-test failed.');
      Require(lHit <> nil, 'MemoListStatus listbox hit-test returned nil.');
      RequireProvider(lHit, UIA_ListItemControlTypeId, 'Completed action', '', 'listbox item');

      lPoint := lStatusBar.ClientToScreen(Point(ScaleValue(8), ScaleValue(8)));
      Require(lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit) = S_OK,
        'MemoListStatus statusbar hit-test failed.');
      Require(lHit <> nil, 'MemoListStatus statusbar hit-test returned nil.');
      RequireProvider(lHit, 50017, 'Ready. High severity checks: 4', '', 'statusbar');

      lMemo.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(lLinePoint.X + ScaleValue(4),
        lLinePoint.Y + ScaleValue(2))));
      Require(lApi.NotificationCalls = 1, 'MemoListStatus memo hover did not raise a notification.');
      Require(lApi.LastDisplayString = 'Second memo line', 'MemoListStatus memo hover text mismatch.');

      lListBox.Perform(WM_MOUSEMOVE, 0, PointToLParam(lItemRect.CenterPoint));
      Require(lApi.NotificationCalls = 2, 'MemoListStatus listbox hover did not raise a notification.');
      Require(lApi.LastDisplayString = 'Completed action', 'MemoListStatus listbox hover text mismatch.');

      lStatusBar.Perform(WM_MOUSEMOVE, 0, PointToLParam(Point(ScaleValue(8), ScaleValue(8))));
      Require(lApi.NotificationCalls = 3, 'MemoListStatus statusbar hover did not raise a notification.');
      Require(lApi.LastDisplayString = 'Ready. High severity checks: 4',
        'MemoListStatus statusbar hover text mismatch.');

      lListBox.Perform(WM_KEYDOWN, VK_DOWN, 0);
      Require(lListBox.ItemIndex = 2, 'MemoListStatus listbox arrow key did not move selection.');
      Require(lApi.NotificationCalls = 4, 'MemoListStatus listbox arrow key did not raise a notification.');
      Require(lApi.LastDisplayString = 'Completed action', 'MemoListStatus listbox arrow key text mismatch.');
    finally
      TAccessibilityManager.Uninstall;
      TAccessibilityManagerInternals.SetUiaApi(nil);
    end;

    Writeln('UIA_PROBE_OK MemoListStatus: manager-installed memo line hit testing, listbox item hit/focus notifications, and statusbar text hover confirmed.');
  finally
    lForm.Free;
  end;
end;

procedure RunTAdvStringGridCellsProbe;
var
  lApi: IProbeUiaApi;
  lCellFragment: IRawElementProviderFragment;
  lCellProvider: IRawElementProviderSimple;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lGrid: TAdvStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lGridPattern: IGridProvider;
  lHit: IRawElementProviderFragment;
  lMessage: TMessage;
  lPattern: IUnknown;
  lPoint: TPoint;
  lRootFragment: IRawElementProviderFragment;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(ScaleValue(100), ScaleValue(100), ScaleValue(440), ScaleValue(280));

    lGrid := TAdvStringGrid.Create(lForm);
    lGrid.Name := 'AdvOrdersGrid';
    lGrid.Parent := lForm;
    lGrid.SetBounds(ScaleValue(8), ScaleValue(8), ScaleValue(280), ScaleValue(135));
    lGrid.ColCount := 8;
    lGrid.RowCount := 8;
    lGrid.FixedCols := 1;
    lGrid.FixedRows := 1;
    lGrid.DefaultColWidth := ScaleValue(50);
    lGrid.DefaultRowHeight := ScaleValue(22);
    lGrid.Cells[1, 0] := 'Name';
    lGrid.Cells[2, 0] := 'Notes';
    lGrid.Cells[1, 1] := '<b>Alice</b>';
    lGrid.WideCells[2, 1] := 'Zazolc gesla jazn';
    lGrid.Cells[3, 1] := 'Hidden TMS column';
    lGrid.Cells[4, 1] := 'After hidden TMS column';
    lGrid.Cells[1, 3] := 'Hidden TMS row';
    lGrid.Cells[1, 4] := 'After hidden TMS row';
    lGrid.Cells[7, 7] := 'Scrolled TMS cell';
    lGrid.HideColumn(3);
    lGrid.HideRow(3);
    lGrid.Col := 2;
    lGrid.Row := 1;
    lForm.ActiveControl := lGrid;
    lForm.HandleNeeded;
    lGrid.HandleNeeded;

    lApi := TProbeUiaApi.Create;
    TAccessibilityManagerInternals.SetUiaApi(lApi);
    TAccessibilityManager.Install(lForm, TAccessibilityTmsAdvStringGridAdapters.CreateRegistry);

    lMessage := Default(TMessage);
    lMessage.Msg := WM_GETOBJECT;
    lMessage.LParam := UiaRootObjectId;
    lForm.WindowProc(lMessage);
    Require(lMessage.Result = 97531, 'TMS manager install path did not return a UIA provider message result.');
    Require(lApi.ReturnedProvider <> nil, 'TMS manager install path did not pass a provider to UIA.');

    lRootFragment := FragmentFromSimple(lApi.ReturnedProvider);
    Require(Supports(lApi.ReturnedProvider, IRawElementProviderFragmentRoot, lRoot),
      'TMS manager root does not expose a fragment root.');
    lGridFragment := FirstNestedChild(lRootFragment, 'TMS string grid fragment');
    Require(ProviderIntProperty(lGridFragment, UIA_ControlTypePropertyId) = UIA_DataGridControlTypeId,
      'TMS string grid did not expose the DataGrid control type.');

    lPattern := PatternProvider(lGridFragment, UIA_GridPatternId);
    Require(Supports(lPattern, IGridProvider, lGridPattern), 'TMS string grid did not expose Grid pattern.');
    Require(lGridPattern.GetItem(1, 1, lCellProvider) = S_OK, 'TMS grid pattern GetItem failed.');
    lCellFragment := FragmentFromSimple(lCellProvider);
    Require(ProviderStringProperty(lCellFragment, UIA_NamePropertyId) = 'Alice',
      'TMS grid HTML cell was not stripped.');
    Require(ProviderIntProperty(lCellFragment, UIA_ControlTypePropertyId) = UIA_DataItemControlTypeId,
      'TMS grid cell did not expose the DataItem control type.');

    Require(lGridPattern.GetItem(1, 2, lCellProvider) = S_OK, 'TMS grid wide-cell GetItem failed.');
    Require(ProviderStringProperty(FragmentFromSimple(lCellProvider), UIA_NamePropertyId) = 'Zazolc gesla jazn',
      'TMS grid wide-cell fallback mismatch.');
    Require(not ChildNameExists(lGridFragment, 'Hidden TMS column'), 'Hidden TMS grid column was exposed.');
    Require(lGridPattern.GetItem(1, 3, lCellProvider) = S_OK, 'TMS grid after-hidden-column GetItem failed.');
    Require(ProviderStringProperty(FragmentFromSimple(lCellProvider), UIA_NamePropertyId) =
      'After hidden TMS column', 'TMS grid visible column after hidden column was not exposed.');
    Require(not ChildNameExists(lGridFragment, 'Hidden TMS row'), 'Hidden TMS grid row was exposed.');
    Require(lGridPattern.GetItem(3, 1, lCellProvider) = S_OK, 'TMS grid after-hidden-row GetItem failed.');
    Require(ProviderStringProperty(FragmentFromSimple(lCellProvider), UIA_NamePropertyId) = 'After hidden TMS row',
      'TMS grid visible row after hidden row was not exposed.');

    lPoint := ScreenAdvCellCenter(lGrid, 1, 1);
    Require(lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit) = S_OK, 'TMS grid hit testing failed.');
    Require(lHit <> nil, 'TMS grid hit testing returned no cell provider.');
    Require(ProviderStringProperty(lHit, UIA_NamePropertyId) = 'Alice',
      'TMS grid hit testing returned the wrong cell provider.');
    Require(Pos('row', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) = 0,
      'TMS grid hit testing added row context to the default cell name.');
    Require(Pos('column', LowerCase(ProviderStringProperty(lHit, UIA_NamePropertyId))) = 0,
      'TMS grid hit testing added column context to the default cell name.');

    Require(lRoot.GetFocus(lFocus) = S_OK, 'TMS grid focus query failed.');
    Require(lFocus <> nil, 'TMS grid focus query returned no cell provider.');
    Require(ProviderStringProperty(lFocus, UIA_NamePropertyId) = 'Zazolc gesla jazn',
      'TMS grid focus query did not return the current cell.');

    lGrid.ScrollInView(6, 6);
    lPoint := ScreenAdvCellCenter(lGrid, 6, 6);
    Require(lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit) = S_OK,
      'Scrolled TMS grid hit testing failed.');
    Require(lHit <> nil, 'Scrolled TMS grid hit testing returned no cell provider.');
    Require(ProviderStringProperty(lHit, UIA_NamePropertyId) = 'Scrolled TMS cell',
      'Scrolled TMS grid hit testing returned the wrong cell provider.');

    lGrid.ScrollInView(1, 1);
    Require(not ChildNameExists(lGridFragment, 'Scrolled TMS cell'), 'Scrolled-out TMS grid cell was exposed.');

    Writeln('UIA_PROBE_OK TAdvStringGridCells: install-path=manager-custom-registry-wm-getobject; opt-in TMS DataGrid provider, stripped HTML text, wide-cell fallback, per-cell hit testing, current-cell focus, hidden-column and hidden-row remapping, hidden-cell omission, and scrolled-cell pruning confirmed.');
  finally
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
    lForm.Free;
  end;
end;

procedure RunHintsProbe;
var
  lApi: IProbeUiaApi;
  lBalloonHint: TBalloonHint;
  lBalloonLabel: TLabel;
  lController: TAccessibilityHintController;
  lForm: TForm;
  lHintProvider: IAccessibilityProviderNode;
  lLabel: TLabel;
  lLabelFragment: IRawElementProviderFragment;
  lMessage: TMessage;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := TProbeUiaApi.Create;
  lApi.SetClientsAreListening(True);
  lForm := TForm.Create(nil);
  lBalloonHint := TBalloonHint.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := '&Name';
    lLabel.Hint := 'Short hint|Long help text';
    lLabel.Parent := lForm;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, nil, lApi);
    lLabelFragment := FirstChild(lProvider, 'hint label fragment');
    Require(ProviderStringProperty(lLabelFragment, UIA_HelpTextPropertyId) = 'Long help text',
      'Label hint was not exposed as UIA HelpText.');

    lHintProvider := TAccessibilityProviderFactory.CreateRoot([710], 0, lApi);
    lController := TAccessibilityHintController.Create(nil, lHintProvider, lApi);
    try
      lController.NotifyVisibleHint('Short hint|Long help text');
      Require(lApi.NotificationCalls = 1, 'Visible hint notification was not raised.');
      Require(lApi.LastDisplayString = 'Long help text', 'Visible hint notification text mismatch.');

      lController.NotifyVisibleHint('Short hint|Long help text');
      Require(lApi.NotificationCalls = 1, 'Duplicate hint notification was not throttled.');

      lController.NotifyBalloonHint('Upload complete', '5 files were processed');
      Require(lApi.NotificationCalls = 2, 'Balloon hint notification was not raised.');
      Require(lApi.LastDisplayString = 'Upload complete: 5 files were processed',
        'Balloon hint notification text mismatch.');
    finally
      lController.Free;
    end;

    lBalloonLabel := TLabel.Create(lForm);
    lBalloonLabel.Caption := 'Upload';
    lBalloonLabel.Hint := 'Processed|Custom hint text';
    lBalloonLabel.CustomHint := lBalloonHint;
    lBalloonLabel.ShowHint := True;
    lBalloonLabel.Parent := lForm;

    TAccessibilityManagerInternals.SetUiaApi(lApi);
    try
      TAccessibilityManager.Install(Application);
      lMessage := Default(TMessage);
      lMessage.Msg := CM_MOUSEENTER;
      lMessage.LParam := Winapi.Windows.LPARAM(lBalloonLabel);
      lForm.WindowProc(lMessage);
    finally
      TAccessibilityManager.Uninstall;
      TAccessibilityManagerInternals.SetUiaApi(nil);
    end;

    Require(lApi.NotificationCalls = 3, 'Manager-installed balloon hint observer did not raise one event.');
    Require(lApi.LastDisplayString = 'Processed: Custom hint text',
      'Manager-installed balloon hint observer text mismatch.');

    Writeln('UIA_PROBE_OK Hints: help text, visible hint notification, duplicate throttling, direct balloon notification, and manager-installed balloon mouse-enter notification confirmed.');
  finally
    lBalloonHint.Free;
    lForm.Free;
  end;
end;

procedure Run;
begin
  if (ParamCount = 2) and SameText(ParamStr(1), '--uia-probe') and SameText(ParamStr(2), 'BasicVclControls') then
  begin
    RunBasicVclControlsProbe;
  end else if (ParamCount = 2) and SameText(ParamStr(1), '--uia-probe') and SameText(ParamStr(2), 'Hints') then
  begin
    RunHintsProbe;
  end else if (ParamCount = 2) and SameText(ParamStr(1), '--uia-probe') and SameText(ParamStr(2), 'MemoListStatus') then
  begin
    RunMemoListStatusProbe;
  end else if (ParamCount = 2) and SameText(ParamStr(1), '--uia-probe') and SameText(ParamStr(2), 'TStringGridCells') then
  begin
    RunTStringGridCellsProbe;
  end else if (ParamCount = 2) and SameText(ParamStr(1), '--uia-probe') and SameText(ParamStr(2), 'TAdvStringGridCells') then
  begin
    RunTAdvStringGridCellsProbe;
  end else begin
    Writeln(cAccessibilityFrameworkName);
  end;
end;

begin
  try
    Run;
  except
    on lException: Exception do
    begin
      Writeln(lException.ClassName, ': ', lException.Message);
      System.ExitCode := 1;
    end;
  end;
end.
