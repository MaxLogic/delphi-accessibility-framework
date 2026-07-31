unit MaxLogic.Accessibility.VclAdapters.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('VclAdapters')]
  TAccessibilityVclAdaptersTests = class
  public
    [Test]
    procedure DefaultAdaptersExposeUsefulNonWindowedControlsOnly;
    [Test]
    procedure DefaultAdaptersCacheRepeatedCustomControlRttiLookups;
    [Test]
    procedure DisabledSpeedButtonAutomationDoesNotInvokeClickOrToggle;
    [Test]
    procedure ProviderTreeExposesVclControlProperties;
    [Test]
    procedure DynamicCaptionHintAndEditValueStayCurrent;
    [Test]
    procedure DemoDynamicContentTimerUpdatesAllSamples;
    [Test]
    [Category('VclAdapters,RuntimeSyncDemo')]
    procedure DemoRuntimeSynchronizationWalkthroughCoversEveryPath;
    [Test]
    procedure DemoTmsHiddenBaseMergesStayWithinGridBounds;
    [Test]
    [Category('VclAdapters,LabeledBy')]
    procedure DemoLabeledBySamplesExposeExpectedRelationships;
    [Test]
    procedure FormRootProviderUsesWindowControlType;
    [Test]
    procedure FormRootProviderOverridesNativeWindowTree;
    [Test]
    procedure TextEditProviderExposesEditTypeAndTextHintHelp;
    [Test]
    procedure TextEditValueFallsBackToTextHintWhenEmpty;
    [Test]
    procedure TabSheetProviderBoundsMatchPageControlTabHeader;
    [Test]
    procedure ActiveTabSheetDoesNotMaskSiblingTabHeaderHitTesting;
    [Test]
    procedure ActiveTabSheetBodyHitTestingReturnsNestedLabel;
    [Test]
    procedure CustomWindowedProvidersPublishNativeWindowHandleButLayoutContainersDoNot;
    [Test]
    procedure WindowedButtonAndCheckBoxProvidersExposeCaptionHintAndState;
    [Test]
    procedure RadioButtonProviderUsesSelectionItemPattern;
    [Test]
    procedure VclSelectionContainersUseParentWithoutNavigation;
    [Test]
    procedure DemoStandardControlsExposeIntentionalRoles;
    [Test]
    procedure DemoRadioGroupItemHitTestingReturnsItemProvider;
    [Test]
    [Category('VclAdapters,LabeledBy')]
    procedure TextInputsExposeAssociatedLabelsAndValues;
    [Test]
    [Category('VclAdapters,LabeledBy')]
    procedure TextInputsExposeExactLabeledByProviders;
    [Test]
    [Category('VclAdapters,LabeledBy')]
    procedure TextInputsRejectInvalidLabeledByRelationships;
    [Test]
    [Category('VclAdapters,Memo')]
    procedure MemoProviderCacheRemainsBoundedAcrossScrollHistory;
    [Test]
    [Category('VclAdapters,Memo')]
    procedure MemoHitTestingPrunesScrolledProviders;
    [Test]
    procedure MemoProviderHitTestingReturnsLineUnderPointer;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxProviderCacheRemainsBoundedAcrossScrollHistory;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxSelectionCollapseScalesLinearly;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxPartialSelectionPruneUsesBoundedNativeQueries;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxHitTestingPrunesScrolledProviders;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxSingleSelectionPrunesOldProviders;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxSiblingNavigationReconcilesSelectionOnlyChanges;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxSiblingNavigationRevalidatesResumedTraversal;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxGetFocusPrunesScrolledProviders;
    [Test]
    [Category('VclAdapters,ListBox')]
    procedure ListBoxRetainedItemDisconnectsWhenControlIsDestroyed;
    [Test]
    procedure ListBoxProviderHitTestingAndFocusReturnItems;
    [Test]
    procedure ListBoxProviderReturnsAllSelectedItemsForMultiSelect;
    [Test]
    procedure ListBoxSelectionContainerUsesOwnerWithoutNavigation;
    [Test]
    procedure ListBoxProviderKeepsNativeHwndInternalWithoutPublishingIt;
    [Test]
    procedure ListBoxItemProviderHandlesStaleItemIndex;
    [Test]
    procedure ListBoxProviderStopsReturningFocusItemWhenCachedTextBecomesEmpty;
    [Test]
    procedure StatusBarProviderUsesVisibleStatusText;
    [Test]
    [Category('VclAdapters,RuntimePropertySynchronization')]
    procedure StatusBarProviderUsesCurrentHelpText;
    [Test]
    [Category('VclAdapters,RuntimePropertySynchronization')]
    procedure StringGridProviderUsesCurrentNameAndHelpText;
    [Test]
    [Category('VclAdapters,RuntimePropertySynchronization')]
    procedure FormProviderUsesCurrentName;
    [Test]
    [Category('VclAdapters,RuntimePropertySynchronization')]
    procedure FormProviderUsesCurrentHelpText;
    [Test]
    procedure RootHitTestingReturnsDeepestNonWindowedLabel;
    [Test]
    procedure RootProviderLookupFindsControlsWithoutNavigation;
    [Test]
    procedure RootHitTestingUsesDirectControlBeforeUnrelatedHitTestRoots;
    [Test]
    procedure RootFallbackHitTestingAvoidsProviderNavigation;
    [Test]
    procedure RootHitTestingAvoidsRepeatedProviderTreeWalks;
    [Test]
    procedure SpeedButtonProviderSupportsInvokeAndOptionalToggle;
  end;

implementation

uses
  System.Diagnostics, System.IOUtils, System.Math, System.SysUtils, System.Types, System.Variants, Winapi.ActiveX,
  Winapi.Messages, Winapi.Windows,
  Vcl.Buttons, Vcl.Controls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, DUnitX.Assert,
  MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters, AccessibilityDemoMainForm;

type
  TDynamicTextControlAccess = class(TControl);

  TCaptionGraphicControl = class(TGraphicControl)
  private
    fCaption: string;
  protected
    procedure Paint; override;
  published
    property Caption: string read fCaption write fCaption;
  end;

  TColdCaptionGraphicControl = class(TGraphicControl)
  private
    fCaption: string;
  protected
    procedure Paint; override;
  published
    property Caption: string read fCaption write fCaption;
  end;

  TClickRecorder = class
  private
    fClicks: Integer;
  public
    procedure Click(aSender: TObject);
    property Clicks: Integer read fClicks;
  end;

  TProbeSpeedButton = class(TSpeedButton)
  private
    fClickCalls: Integer;
  public
    procedure Click; override;
    property ClickCalls: Integer read fClickCalls;
  end;

  TSelectionProbeListBox = class(TListBox)
  private
    fBulkSelectionMessageCount: Integer;
    fGetItemCountMessageCount: Integer;
    fGetSelectionMessageCount: Integer;
  protected
    procedure WndProc(var aMessage: TMessage); override;
  public
    procedure ResetGetItemCountMessageCount;
    procedure ResetGetSelectionMessageCount;
    property BulkSelectionMessageCount: Integer read fBulkSelectionMessageCount;
    property GetItemCountMessageCount: Integer read fGetItemCountMessageCount;
    property GetSelectionMessageCount: Integer read fGetSelectionMessageCount;
  end;

  IHostProbeUiaApi = interface(IAccessibilityUiaApi)
    ['{4CA617C1-E8ED-4E75-B789-9E8685454F62}']
    function HostCalls: Integer;
  end;

  THostProbeUiaApi = class(TInterfacedObject, IHostProbeUiaApi)
  private
    fHostCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostCalls: Integer;
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

procedure TCaptionGraphicControl.Paint;
begin
end; //PALOFF WARN27 intentional no-op paint for caption-only test control

procedure TColdCaptionGraphicControl.Paint;
begin
end; //PALOFF WARN27 intentional no-op paint for cold-caption test control

procedure TClickRecorder.Click(aSender: TObject);
begin
  Inc(fClicks);
end;

procedure TProbeSpeedButton.Click;
begin
  Inc(fClickCalls);
  inherited Click;
end;

procedure TSelectionProbeListBox.ResetGetSelectionMessageCount;
begin
  fBulkSelectionMessageCount := 0;
  fGetSelectionMessageCount := 0;
end;

procedure TSelectionProbeListBox.ResetGetItemCountMessageCount;
begin
  fGetItemCountMessageCount := 0;
end;

procedure TSelectionProbeListBox.WndProc(var aMessage: TMessage);
begin
  case aMessage.Msg of
    LB_GETCOUNT:
      Inc(fGetItemCountMessageCount);
    LB_GETSEL:
      Inc(fGetSelectionMessageCount);
    LB_GETSELCOUNT, LB_GETSELITEMS:
      Inc(fBulkSelectionMessageCount);
  end;
  inherited WndProc(aMessage);
end;

procedure FillListBox(aListBox: TCustomListBox; aCount: Integer);
var
  i: Integer;
begin
  aListBox.Items.BeginUpdate;
  try
    for i := 0 to Pred(aCount) do
    begin
      aListBox.Items.Add(Format('List item %.5d', [i]));
    end;
  finally
    aListBox.Items.EndUpdate;
  end;
end;

procedure FillMemo(aMemo: TCustomMemo; aLineCount: Integer);
var
  i: Integer;
begin
  aMemo.Lines.BeginUpdate;
  try
    for i := 0 to Pred(aLineCount) do
    begin
      aMemo.Lines.Add(Format('Memo line %.5d', [i]));
    end;
  finally
    aMemo.Lines.EndUpdate;
  end;
end;

procedure MaterializeListBoxSelection(const aListBoxFragment: IRawElementProviderFragment);
var
  lPattern: IUnknown;
  lSafeArray: PSafeArray;
  lSelection: ISelectionProvider;
  lSimple: IRawElementProviderSimple;
begin
  Assert.IsTrue(Supports(aListBoxFragment, IRawElementProviderSimple, lSimple));
  Assert.AreEqual(S_OK, lSimple.GetPatternProvider(UIA_SelectionPatternId, lPattern));
  Assert.IsTrue(Supports(lPattern, ISelectionProvider, lSelection));
  lSafeArray := nil;
  Assert.AreEqual(S_OK, lSelection.GetSelection(lSafeArray));
  Assert.IsNotNull(lSafeArray);
  SafeArrayDestroy(lSafeArray);
end;

function MeasureListBoxSelectionCollapseTicks(aItemCount: Integer; aKeepUpperHalf: Boolean): Int64;
var
  lAccess: IAccessibilityProviderChildAccess;
  lChildCount: Integer;
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lResult: HResult;
  lStopwatch: TStopwatch;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.MultiSelect := True;
    lListBox.SetBounds(16, 16, 240, 110);
    FillListBox(lListBox, aItemCount);
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    for var i := 0 to Pred(aItemCount) do
    begin
      lListBox.Selected[i] := True;
    end;

    Assert.AreEqual(S_OK, TAccessibilityVclProviderBuilder.BuildForm(lForm).FragmentProvider.Navigate(
      NavigateDirection_FirstChild, lListBoxFragment));
    Assert.IsNotNull(lListBoxFragment);
    MaterializeListBoxSelection(lListBoxFragment);
    Assert.IsTrue(Supports(lListBoxFragment, IAccessibilityProviderChildAccess, lAccess));
    Assert.AreEqual(S_OK, lAccess.DirectChildCount(lChildCount));
    Assert.AreEqual(aItemCount, lChildCount);

    if aKeepUpperHalf then
    begin
      for var i := 0 to Pred(aItemCount div 2) do
      begin
        lListBox.Selected[i] := False;
      end;
    end else begin
      for var i := 0 to Pred(aItemCount) do
      begin
        lListBox.Selected[i] := False;
      end;
    end;
    lStopwatch := TStopwatch.StartNew;
    lResult := lAccess.DirectChildCount(lChildCount);
    Result := lStopwatch.ElapsedTicks;
    Assert.AreEqual(S_OK, lResult);
    Assert.IsTrue(lChildCount < aItemCount, 'Collapsing selection must prune unretained providers.');
  finally
    lForm.Free;
  end;
  if Result < 1 then
  begin
    Result := 1;
  end;
end;

function MeasureBestListBoxSelectionCollapseTicks(aItemCount: Integer; aKeepUpperHalf: Boolean;
  aSampleCount: Integer): Int64;
var
  i: Integer;
  lMeasuredTicks: Int64;
begin
  Result := High(Int64);
  for i := 1 to aSampleCount do
  begin
    lMeasuredTicks := MeasureListBoxSelectionCollapseTicks(aItemCount, aKeepUpperHalf);
    Assert.IsTrue(lMeasuredTicks > 0, Format('Selection collapse sample %d must be positive.', [i]));
    Result := Min(Result, lMeasuredTicks);
  end;
end;

function THostProbeUiaApi.ClientsAreListening: Boolean;
begin
  Result := False;
end;

function THostProbeUiaApi.DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Result := S_OK;
end;

function THostProbeUiaApi.HostCalls: Integer;
begin
  Result := fHostCalls;
end;

function THostProbeUiaApi.HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
begin
  Inc(fHostCalls);
  aProvider := nil;
  Result := S_FALSE;
end;

function THostProbeUiaApi.RaiseAutomationEvent(const aProvider: IRawElementProviderSimple;
  aEventId: EVENTID): HRESULT;
begin
  Result := S_OK;
end;

function THostProbeUiaApi.RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
  aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := S_OK;
end;

function THostProbeUiaApi.RaiseNotification(const aProvider: IRawElementProviderSimple;
  aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Result := S_OK;
end;

function THostProbeUiaApi.RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
  aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Result := S_OK;
end;

function THostProbeUiaApi.ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
  const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Result := 0;
end;

function FirstChildFragment(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragment;
var
  lResult: HResult;
begin
  lResult := aProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, Result);
  Assert.IsTrue(lResult = S_OK, 'First child navigation failed.');
  Assert.IsNotNull(Result);
end;

function FragmentRoot(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragmentRoot;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider.RawElementProvider, IRawElementProviderFragmentRoot, Result));
end;

function NextSiblingFragment(const aFragment: IRawElementProviderFragment): IRawElementProviderFragment;
var
  lResult: HResult;
begin
  lResult := aFragment.Navigate(NavigateDirection_NextSibling, Result);
  Assert.IsTrue(lResult = S_OK, 'Next sibling navigation failed.');
  Assert.IsNotNull(Result);
end;

function NextSiblingFragmentOrNil(const aFragment: IRawElementProviderFragment): IRawElementProviderFragment;
var
  lResult: HResult;
begin
  Result := nil;
  lResult := aFragment.Navigate(NavigateDirection_NextSibling, Result);
  Assert.IsTrue(lResult = S_OK, 'Next sibling navigation failed.');
end;

function SimpleProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Assert.IsTrue(Supports(aFragment, IRawElementProviderSimple, Result));
end;

procedure WriteT113Samples(const aKind: string; const aSamples: TArray<Int64>; aMaxRetained: Integer;
  aInitialTicks: Int64);
var
  i: Integer;
  lDiagnosticsState: string;
  lDirectory: string;
  lFileName: string;
  lText: string;
begin
  lDirectory := GetEnvironmentVariable('MAXLOGIC_T113_MEASURE_DIR');
  if lDirectory = '' then
  begin
    Exit;
  end;

  ForceDirectories(lDirectory);
  if TAccessibilityDiagnostics.Enabled then
  begin
    lDiagnosticsState := 'buffered';
  end else begin
    lDiagnosticsState := 'disabled';
  end;
  lText := Format('sampleCount=%d,maxRetained=%d,initialTicks=%d,frequency=%d,diagnostics=%s%s',
    [Length(aSamples), aMaxRetained, aInitialTicks, TStopwatch.Frequency, lDiagnosticsState, sLineBreak]);
  for i := 0 to High(aSamples) do
  begin
    if i > 0 then
    begin
      lText := lText + ',';
    end;
    lText := lText + IntToStr(aSamples[i]);
  end;
  lFileName := TPath.Combine(lDirectory, aKind + '.csv');
  TFile.WriteAllText(lFileName, lText, TEncoding.UTF8);
end;

function ProviderIntProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): Integer;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := Integer(lValue);
end;

function ProviderBoolProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): Boolean;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := Boolean(lValue);
end;

function ProviderNativeWindowHandle(const aFragment: IRawElementProviderFragment): HWND;
var
  lNativeWindow: IAccessibilityProviderNativeWindow;
begin
  Assert.IsTrue(Supports(aFragment, IAccessibilityProviderNativeWindow, lNativeWindow));
  Result := lNativeWindow.NativeWindowHandle;
end;

function ProviderPublishedNativeWindowHandle(const aFragment: IRawElementProviderFragment): HWND;
var
  lValue: OleVariant;
begin
  Result := 0;
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(UIA_NativeWindowHandlePropertyId, lValue));
  if not VarIsEmpty(lValue) and not VarIsNull(lValue) then
  begin
    Result := HWND(Integer(lValue));
  end;
end;

function ProviderOptionsFor(const aFragment: IRawElementProviderFragment): ProviderOptions;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).Get_ProviderOptions(Result));
end;

function ProviderPattern(const aFragment: IRawElementProviderFragment; aPatternId: PATTERNID): IUnknown;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPatternProvider(aPatternId, Result));
end;

function SelectionPattern(const aFragment: IRawElementProviderFragment): ISelectionProvider;
var
  lPattern: IUnknown;
begin
  lPattern := ProviderPattern(aFragment, UIA_SelectionPatternId);
  Assert.IsTrue(Supports(lPattern, ISelectionProvider, Result));
end;

function SelectedSimpleProvider(const aSelectionProvider: ISelectionProvider; aIndex: LongInt):
  IRawElementProviderSimple;
var
  lSelectedUnknown: IUnknown;
  lSelection: PSafeArray;
begin
  Assert.AreEqual(S_OK, aSelectionProvider.GetSelection(lSelection));
  try
    Assert.IsNotNull(lSelection);
    Assert.AreEqual(S_OK, SafeArrayGetElement(lSelection, aIndex, lSelectedUnknown));
    Assert.IsTrue(Supports(lSelectedUnknown, IRawElementProviderSimple, Result));
  finally
    if lSelection <> nil then
    begin
      SafeArrayDestroy(lSelection);
    end;
  end;
end;

function ProviderStringProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := string(lValue);
end;

function ControlProvider(const aRoot: IAccessibilityProviderNode; aControl: TControl): IRawElementProviderSimple;
var
  lLookup: IAccessibilityVclProviderLookup;
begin
  Assert.IsTrue(Supports(aRoot, IAccessibilityVclProviderLookup, lLookup));
  Assert.IsTrue(lLookup.TryFindProviderForControl(aControl, Result),
    aControl.Name + ' must have a provider.');
end;

function ElementProviderProperty(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID):
  IRawElementProviderSimple;
var
  lUnknown: IUnknown;
  lValue: OleVariant;
begin
  Result := nil;
  Assert.AreEqual(S_OK, aProvider.GetPropertyValue(aPropertyId, lValue));
  if VarType(lValue) <> varUnknown then
  begin
    Exit;
  end;

  lUnknown := IUnknown(lValue);
  Supports(lUnknown, IRawElementProviderSimple, Result);
end;

function ProvidersAreSame(const aLeft: IRawElementProviderSimple; const aRight: IRawElementProviderSimple):
  Boolean;
var
  lLeft: IUnknown;
  lRight: IUnknown;
begin
  if (aLeft = nil) or (aRight = nil) then
  begin
    Exit(aLeft = aRight);
  end;

  lLeft := aLeft as IUnknown;
  lRight := aRight as IUnknown;
  Result := lLeft = lRight;
end;

procedure AssertControlLabeledBy(const aRoot: IAccessibilityProviderNode; aInput: TControl; aLabel: TControl);
var
  lInputProvider: IRawElementProviderSimple;
  lLabelProvider: IRawElementProviderSimple;
begin
  lInputProvider := ControlProvider(aRoot, aInput);
  lLabelProvider := ControlProvider(aRoot, aLabel);
  Assert.IsTrue(ProvidersAreSame(lLabelProvider,
    ElementProviderProperty(lInputProvider, UIA_LabeledByPropertyId)));
end;

procedure AssertControlHasNoLabeledBy(const aRoot: IAccessibilityProviderNode; aInput: TControl);
begin
  Assert.IsNull(ElementProviderProperty(ControlProvider(aRoot, aInput), UIA_LabeledByPropertyId),
    aInput.Name + ' must not expose LabeledBy.');
end;

function SimpleProviderStringProperty(const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, aProvider.GetPropertyValue(aPropertyId, lValue));
  Result := string(lValue);
end;

procedure CreateExplicitLabeledBySample(aForm: TForm; out aLabel: TLabel; out aEdit: TEdit);
begin
  aLabel := TLabel.Create(aForm);
  aLabel.Name := 'ExplicitAccountLabel';
  aLabel.Caption := 'Account';
  aLabel.Parent := aForm;
  aLabel.SetBounds(12, 16, 90, 23);
  aEdit := TEdit.Create(aForm);
  aEdit.Name := 'ExplicitAccountEdit';
  aEdit.Parent := aForm;
  aEdit.SetBounds(112, 16, 160, 23);
  aEdit.Text := 'Alice';
  aLabel.FocusControl := aEdit;
end;

procedure CreateInferredLabeledBySample(aForm: TForm; out aLabel: TStaticText; out aCombo: TComboBox);
begin
  aLabel := TStaticText.Create(aForm);
  aLabel.Name := 'InferredQueueLabel';
  aLabel.Caption := 'Queue';
  aLabel.Parent := aForm;
  aLabel.SetBounds(12, 56, 160, 20);
  aCombo := TComboBox.Create(aForm);
  aCombo.Name := 'InferredQueueCombo';
  aCombo.Parent := aForm;
  aCombo.SetBounds(12, 80, 160, 23);
  aCombo.Items.Add('Urgent');
  aCombo.ItemIndex := 0;
end;

function CreateLabeledEditSample(aForm: TForm): TLabeledEdit;
begin
  Result := TLabeledEdit.Create(aForm);
  Result.Name := 'ReferenceEdit';
  Result.Parent := aForm;
  Result.SetBounds(112, 136, 160, 23);
  Result.EditLabel.Caption := 'Reference number';
  Result.Text := 'REF-1042';
end;

function CreateRejectedExplicitLabelSample(aForm: TForm; const aName: string; const aCaption: string;
  const aText: string; aTop: Integer; aVisible: Boolean): TEdit;
var
  lLabel: TLabel;
begin
  lLabel := TLabel.Create(aForm);
  lLabel.Caption := aCaption;
  lLabel.Parent := aForm;
  lLabel.SetBounds(12, aTop, 90, 23);
  lLabel.Visible := aVisible;
  Result := TEdit.Create(aForm);
  Result.Name := aName;
  Result.Parent := aForm;
  Result.SetBounds(112, aTop, 160, 23);
  Result.Text := aText;
  lLabel.FocusControl := Result;
end;

function CreateCrossContainerLabelSample(aForm: TForm): TEdit;
var
  lLabel: TLabel;
  lLabelPanel: TPanel;
  lTargetPanel: TPanel;
begin
  lLabelPanel := TPanel.Create(aForm);
  lLabelPanel.Caption := '';
  lLabelPanel.Parent := aForm;
  lLabelPanel.SetBounds(12, 132, 90, 40);
  lLabel := TLabel.Create(aForm);
  lLabel.Caption := 'Other panel';
  lLabel.Parent := lLabelPanel;
  lLabel.SetBounds(0, 0, 90, 23);
  lTargetPanel := TPanel.Create(aForm);
  lTargetPanel.Caption := '';
  lTargetPanel.Parent := aForm;
  lTargetPanel.SetBounds(112, 132, 160, 40);
  Result := TEdit.Create(aForm);
  Result.Name := 'CrossContainerEdit';
  Result.Parent := lTargetPanel;
  Result.SetBounds(0, 0, 160, 23);
  Result.Text := 'Cross value';
  lLabel.FocusControl := Result;
end;

function CreateAmbiguousLabelSample(aForm: TForm): TEdit;
var
  lFirstLabel: TStaticText;
  lSecondLabel: TStaticText;
begin
  lFirstLabel := TStaticText.Create(aForm);
  lFirstLabel.Caption := 'First candidate';
  lFirstLabel.Parent := aForm;
  lFirstLabel.SetBounds(12, 184, 90, 23);
  lSecondLabel := TStaticText.Create(aForm);
  lSecondLabel.Caption := 'Second candidate';
  lSecondLabel.Parent := aForm;
  lSecondLabel.SetBounds(12, 184, 90, 23);
  Result := TEdit.Create(aForm);
  Result.Name := 'AmbiguousEdit';
  Result.Parent := aForm;
  Result.SetBounds(112, 184, 160, 23);
  Result.Text := 'Ambiguous value';
end;

function CreateUnlabeledSample(aForm: TForm): TEdit;
begin
  Result := TEdit.Create(aForm);
  Result.Name := 'UnlabeledEdit';
  Result.Parent := aForm;
  Result.SetBounds(112, 224, 160, 23);
  Result.Text := 'Unlabeled value';
end;

function CreateDistantLabelSample(aForm: TForm): TEdit;
var
  lLabel: TStaticText;
  lPanel: TPanel;
begin
  lPanel := TPanel.Create(aForm);
  lPanel.Caption := '';
  lPanel.Parent := aForm;
  lPanel.SetBounds(300, 12, 180, 140);
  lLabel := TStaticText.Create(aForm);
  lLabel.Caption := 'Distant label';
  lLabel.Parent := lPanel;
  lLabel.SetBounds(0, 0, 160, 20);
  Result := TEdit.Create(aForm);
  Result.Name := 'DistantEdit';
  Result.Parent := lPanel;
  Result.SetBounds(0, 80, 160, 23);
  Result.Text := 'Distant value';
end;

function FindDescendantByName(const aFragment: IRawElementProviderFragment; const aName: string):
  IRawElementProviderFragment;
var
  lChild: IRawElementProviderFragment;
  lCurrent: IRawElementProviderFragment;
  lNext: IRawElementProviderFragment;
  lResult: HResult;
begin
  Result := nil;
  if aFragment = nil then
  begin
    Exit;
  end;

  if SameText(ProviderStringProperty(aFragment, UIA_NamePropertyId), aName) then
  begin
    Exit(aFragment);
  end;

  lResult := aFragment.Navigate(NavigateDirection_FirstChild, lChild);
  Assert.IsTrue(lResult = S_OK, 'First child navigation failed.');
  lCurrent := lChild;
  while lCurrent <> nil do
  begin
    Result := FindDescendantByName(lCurrent, aName);
    if Result <> nil then
    begin
      Exit;
    end;

    lNext := nil;
    lResult := lCurrent.Navigate(NavigateDirection_NextSibling, lNext);
    Assert.IsTrue(lResult = S_OK, 'Next sibling navigation failed.');
    lCurrent := lNext;
  end;
end;

procedure AssertNamedControlType(const aRoot: IRawElementProviderFragment; const aName: string; aControlType: Integer);
var
  lFragment: IRawElementProviderFragment;
begin
  lFragment := FindDescendantByName(aRoot, aName);
  Assert.IsNotNull(lFragment, aName + ' provider is missing.');
  Assert.AreEqual(aControlType, ProviderIntProperty(lFragment, UIA_ControlTypePropertyId), aName);
end;

function SelectionProviderName(const aSelection: PSafeArray; aIndex: LongInt): string;
var
  lFragment: IRawElementProviderFragment;
  lProvider: IRawElementProviderSimple;
  lSelectedUnknown: IUnknown;
begin
  lSelectedUnknown := nil;
  Assert.AreEqual(S_OK, SafeArrayGetElement(aSelection, aIndex, lSelectedUnknown));
  Assert.IsNotNull(lSelectedUnknown);
  Assert.IsTrue(Supports(lSelectedUnknown, IRawElementProviderSimple, lProvider));
  Assert.IsTrue(Supports(lProvider, IRawElementProviderFragment, lFragment));
  Result := ProviderStringProperty(lFragment, UIA_NamePropertyId);
end;

function ValuePattern(const aFragment: IRawElementProviderFragment): IValueProvider;
var
  lPattern: IUnknown;
begin
  lPattern := ProviderPattern(aFragment, UIA_ValuePatternId);
  Assert.IsTrue(Supports(lPattern, IValueProvider, Result));
end;

function ValuePatternText(const aFragment: IRawElementProviderFragment): string;
var
  lValue: WideString;
begin
  Assert.AreEqual(S_OK, ValuePattern(aFragment).Get_Value(lValue));
  Result := string(lValue);
end;

function FragmentFocus(const aRoot: IRawElementProviderFragmentRoot): IRawElementProviderFragment;
begin
  Assert.AreEqual(S_OK, aRoot.GetFocus(Result));
  Assert.IsNotNull(Result);
end;

function PointFromMessageResult(aValue: LRESULT): TPoint;
var
  lRawValue: Int64;
  lSignedValue: Int64;
  lX: Integer;
  lY: Integer;
begin
  lSignedValue := Int64(aValue); //PALOFF WARN63 explicit LPARAM sign normalization
  lRawValue := lSignedValue and $00000000FFFFFFFF;
  lX := Integer(lRawValue and $FFFF); //PALOFF explicit reviewed low-word extraction
  if lX > High(Smallint) then
  begin
    Dec(lX, $10000);
  end;

  lY := Integer((lRawValue shr 16) and $FFFF); //PALOFF explicit reviewed high-word extraction
  if lY > High(Smallint) then
  begin
    Dec(lY, $10000);
  end;

  Result := Point(lX, lY);
end;

function ControlScreenCenter(aControl: TControl): TPoint;
begin
  Result := aControl.ClientToScreen(Point(aControl.Width div 2, aControl.Height div 2));
end;

procedure TAccessibilityVclAdaptersTests.DefaultAdaptersExposeUsefulNonWindowedControlsOnly;
var
  lChildLabel: TLabel;
  lDecorativeGraphic: TCaptionGraphicControl;
  lEmptyLabel: TLabel;
  lEmptyPanel: TPanel;
  lForm: TForm;
  lGraphic: TCaptionGraphicControl;
  lLabel: TLabel;
  lPanelWithChild: TPanel;
  lRegistry: IAccessibilityAdapterRegistry;
  lTree: IAccessibilityScanTree;
begin
  lForm := TForm.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := '&Customer';
    lLabel.Hint := 'Customer label|Shown next to customer edit';
    lLabel.Parent := lForm;

    lEmptyLabel := TLabel.Create(lForm);
    lEmptyLabel.Name := 'DecorativeLabel';
    lEmptyLabel.Caption := '';
    lEmptyLabel.Parent := lForm;

    lPanelWithChild := TPanel.Create(lForm);
    lPanelWithChild.Name := 'LayoutPanel';
    lPanelWithChild.Caption := '';
    lPanelWithChild.Parent := lForm;

    lChildLabel := TLabel.Create(lForm);
    lChildLabel.Caption := 'Nested value';
    lChildLabel.Parent := lPanelWithChild;

    lEmptyPanel := TPanel.Create(lForm);
    lEmptyPanel.Name := 'DecorativePanel';
    lEmptyPanel.Caption := '';
    lEmptyPanel.Parent := lForm;

    lGraphic := TCaptionGraphicControl.Create(lForm);
    lGraphic.Caption := '&Custom graphic';
    lGraphic.Hint := 'Graphic help';
    lGraphic.Parent := lForm;

    lDecorativeGraphic := TCaptionGraphicControl.Create(lForm);
    lDecorativeGraphic.Name := 'DecorativeGraphic';
    lDecorativeGraphic.Parent := lForm;

    lRegistry := TAccessibilityVclAdapters.CreateDefaultRegistry;
    lTree := TAccessibilityScanner.ScanForm(lForm, lRegistry);

    Assert.AreEqual('Customer', lTree.FindNode(lLabel).Name);
    Assert.AreEqual('Shown next to customer edit', lTree.FindNode(lLabel).HelpText);
    Assert.IsNull(lTree.FindNode(lEmptyLabel));

    Assert.IsNull(lTree.FindNode(lPanelWithChild));
    Assert.AreEqual('Nested value', lTree.FindNode(lChildLabel).Name);
    Assert.IsNull(lTree.FindNode(lEmptyPanel));

    Assert.AreEqual('Custom graphic', lTree.FindNode(lGraphic).Name);
    Assert.AreEqual('Graphic help', lTree.FindNode(lGraphic).HelpText);
    Assert.IsNull(lTree.FindNode(lDecorativeGraphic));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.DefaultAdaptersCacheRepeatedCustomControlRttiLookups;
const
  cControlCount = 60;
  cMaxRttiLookups = 0;
var
  i: Integer;
  lForm: TForm;
  lGraphic: TColdCaptionGraphicControl;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lRegistry: IAccessibilityAdapterRegistry;
  lTree: IAccessibilityScanTree;
begin
  lForm := TForm.Create(nil);
  try
    for i := 1 to cControlCount do
    begin
      lGraphic := TColdCaptionGraphicControl.Create(lForm);
      lGraphic.Caption := Format('Custom graphic %d', [i]);
      lGraphic.Parent := lForm;
    end;

    lRegistry := TAccessibilityVclAdapters.CreateDefaultRegistry;
    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lTree := TAccessibilityScanner.ScanForm(lForm, lRegistry);
      Assert.IsNotNull(lTree.FindNode(lGraphic));
      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.IsTrue(lMetrics.VclAdapterRttiPropertyLookupCount <= cMaxRttiLookups,
        Format('VCL adapters should reuse scanner fallback text instead of rereading RTTI. Expected <= %d, got %d.',
        [cMaxRttiLookups, lMetrics.VclAdapterRttiPropertyLookupCount]));
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.DisabledSpeedButtonAutomationDoesNotInvokeClickOrToggle;
var
  lForm: TForm;
  lInvoke: IInvokeProvider;
  lInvokeFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRunButton: TProbeSpeedButton;
  lToggle: IToggleProvider;
  lToggleButton: TProbeSpeedButton;
  lToggleFragment: IRawElementProviderFragment;
begin
  lForm := TForm.Create(nil);
  try
    lRunButton := TProbeSpeedButton.Create(lForm);
    lRunButton.Caption := '&Run';
    lRunButton.Enabled := False;
    lRunButton.Parent := lForm;

    lToggleButton := TProbeSpeedButton.Create(lForm);
    lToggleButton.Caption := '&Pinned';
    lToggleButton.GroupIndex := 1;
    lToggleButton.AllowAllUp := True;
    lToggleButton.Down := False;
    lToggleButton.Enabled := False;
    lToggleButton.Parent := lForm;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lInvokeFragment := FirstChildFragment(lProvider);
    lToggleFragment := NextSiblingFragment(lInvokeFragment);

    lPattern := ProviderPattern(lInvokeFragment, UIA_InvokePatternId);
    Assert.IsTrue(Supports(lPattern, IInvokeProvider, lInvoke));
    lInvoke.Invoke;
    Assert.AreEqual(0, lRunButton.ClickCalls);

    lPattern := ProviderPattern(lToggleFragment, UIA_InvokePatternId);
    Assert.IsTrue(Supports(lPattern, IInvokeProvider, lInvoke));
    lInvoke.Invoke;
    Assert.AreEqual(0, lToggleButton.ClickCalls);
    Assert.IsFalse(lToggleButton.Down);

    lPattern := ProviderPattern(lToggleFragment, UIA_TogglePatternId);
    Assert.IsTrue(Supports(lPattern, IToggleProvider, lToggle));
    lToggle.Toggle;
    Assert.AreEqual(0, lToggleButton.ClickCalls);
    Assert.IsFalse(lToggleButton.Down);

    lToggleButton.Down := True;
    lToggle.Toggle;
    Assert.AreEqual(0, lToggleButton.ClickCalls);
    Assert.IsTrue(lToggleButton.Down);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ProviderTreeExposesVclControlProperties;
var
  lButtonFragment: IRawElementProviderFragment;
  lDecorativeGraphic: TCaptionGraphicControl;
  lForm: TForm;
  lGraphic: TCaptionGraphicControl;
  lGraphicFragment: IRawElementProviderFragment;
  lLabel: TLabel;
  lLabelFragment: IRawElementProviderFragment;
  lPanel: TPanel;
  lPanelFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lSpeedButton: TSpeedButton;
begin
  lForm := TForm.Create(nil);
  try
    lLabel := TLabel.Create(lForm);
    lLabel.Caption := '&Customer';
    lLabel.Hint := 'Customer label|Shown next to customer edit';
    lLabel.Parent := lForm;

    lSpeedButton := TSpeedButton.Create(lForm);
    lSpeedButton.Caption := '&Run';
    lSpeedButton.Hint := 'Runs the command';
    lSpeedButton.Parent := lForm;

    lPanel := TPanel.Create(lForm);
    lPanel.Caption := '&Options';
    lPanel.Hint := 'Option group';
    lPanel.Parent := lForm;

    lGraphic := TCaptionGraphicControl.Create(lForm);
    lGraphic.Caption := '&Custom graphic';
    lGraphic.Hint := 'Graphic help';
    lGraphic.Parent := lForm;

    lDecorativeGraphic := TCaptionGraphicControl.Create(lForm);
    lDecorativeGraphic.Name := 'DecorativeGraphic';
    lDecorativeGraphic.Parent := lForm;
    Assert.IsNotNull(lDecorativeGraphic);

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lLabelFragment := FirstChildFragment(lProvider);
    lButtonFragment := NextSiblingFragment(lLabelFragment);
    lPanelFragment := NextSiblingFragment(lButtonFragment);
    lGraphicFragment := NextSiblingFragment(lPanelFragment);

    Assert.AreEqual('Customer', ProviderStringProperty(lLabelFragment, UIA_NamePropertyId));
    Assert.AreEqual('Shown next to customer edit', ProviderStringProperty(lLabelFragment, UIA_HelpTextPropertyId));
    Assert.AreEqual(UIA_TextControlTypeId, ProviderIntProperty(lLabelFragment, UIA_ControlTypePropertyId));

    Assert.AreEqual('Run', ProviderStringProperty(lButtonFragment, UIA_NamePropertyId));
    Assert.AreEqual('Runs the command', ProviderStringProperty(lButtonFragment, UIA_HelpTextPropertyId));
    Assert.AreEqual(UIA_ButtonControlTypeId, ProviderIntProperty(lButtonFragment, UIA_ControlTypePropertyId));

    Assert.AreEqual('Options', ProviderStringProperty(lPanelFragment, UIA_NamePropertyId));
    Assert.AreEqual('Option group', ProviderStringProperty(lPanelFragment, UIA_HelpTextPropertyId));
    Assert.AreEqual(UIA_PaneControlTypeId, ProviderIntProperty(lPanelFragment, UIA_ControlTypePropertyId));

    Assert.AreEqual('Custom graphic', ProviderStringProperty(lGraphicFragment, UIA_NamePropertyId));
    Assert.AreEqual('Graphic help', ProviderStringProperty(lGraphicFragment, UIA_HelpTextPropertyId));
    Assert.AreEqual(UIA_TextControlTypeId, ProviderIntProperty(lGraphicFragment, UIA_ControlTypePropertyId));
    Assert.IsNull(NextSiblingFragmentOrNil(lGraphicFragment));
  finally
    lForm.Free;
  end;
end;

function DynamicControlText(aControl: TControl): string;
begin
  if aControl is TCustomEdit then
  begin
    Exit(TDynamicTextControlAccess(aControl).Text);
  end;
  Result := TDynamicTextControlAccess(aControl).Caption;
end;

procedure SetDynamicControlText(aControl: TControl; const aText: string);
begin
  if aControl is TCustomEdit then
  begin
    TDynamicTextControlAccess(aControl).Text := aText;
  end else begin
    TDynamicTextControlAccess(aControl).Caption := aText;
  end;
end;

procedure AssertDynamicControlTextStaysCurrent(aControlClass: TControlClass; const aInitialText: string;
  const aInitialHint: string; const aUpdatedText: string; const aUpdatedHint: string; aSupportsValue: Boolean);
var
  lControl: TControl;
  lFragment: IRawElementProviderFragment;
  lForm: TForm;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lControl := aControlClass.Create(lForm);
    SetDynamicControlText(lControl, aInitialText);
    lControl.Hint := aInitialHint;
    lControl.Parent := lForm;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lFragment := FirstChildFragment(lProvider);

    SetDynamicControlText(lControl, aUpdatedText);
    lControl.Hint := aUpdatedHint;

    Assert.AreEqual(aUpdatedText, ProviderStringProperty(lFragment, UIA_NamePropertyId));
    Assert.AreEqual(aUpdatedHint, ProviderStringProperty(lFragment, UIA_HelpTextPropertyId));
    if aSupportsValue then
    begin
      Assert.AreEqual(aUpdatedText, ValuePatternText(lFragment));
    end;
  finally
    lForm.Free;
  end;
end;

procedure AssertDemoDynamicControlUpdates(aForm: TAccessibilityDemoMainForm; const aComponentName: string;
  aControlClass: TControlClass);
var
  lControl: TControl;
  lInitialText: string;
  lTimer: TTimer;
begin
  Assert.IsTrue(aForm.FindComponent(aComponentName) is aControlClass,
    aComponentName + ' is missing from the demo.');
  lControl := TControl(aForm.FindComponent(aComponentName));
  lInitialText := DynamicControlText(lControl);
  lTimer := TTimer(aForm.FindComponent('DynamicContentTimer'));
  lTimer.OnTimer(lTimer);
  Assert.AreNotEqual(lInitialText, DynamicControlText(lControl));
  Assert.Contains(lControl.Hint, 'updated');
end;

procedure TAccessibilityVclAdaptersTests.DynamicCaptionHintAndEditValueStayCurrent;
begin
  AssertDynamicControlTextStaysCurrent(TStaticText, 'Static text initial', 'Static text initial hint',
    'Static text updated', 'Static text updated hint', False);
  AssertDynamicControlTextStaysCurrent(TLabel, 'Label initial', 'Label initial hint', 'Label updated',
    'Label updated hint', False);
  AssertDynamicControlTextStaysCurrent(TEdit, 'Edit initial', 'Edit initial hint', 'Edit updated',
    'Edit updated hint', True);
  AssertDynamicControlTextStaysCurrent(TButton, 'Button initial', 'Button initial hint', 'Button updated',
    'Button updated hint', False);
  AssertDynamicControlTextStaysCurrent(TBitBtn, 'Bit button initial', 'Bit button initial hint',
    'Bit button updated', 'Bit button updated hint', False);
end;

procedure TAccessibilityVclAdaptersTests.DemoDynamicContentTimerUpdatesAllSamples;
var
  lForm: TAccessibilityDemoMainForm;
  lTimer: TTimer;
begin
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    Assert.IsTrue(lForm.FindComponent('DynamicContentTimer') is TTimer,
      'DynamicContentTimer is missing from the demo.');
    lTimer := TTimer(lForm.FindComponent('DynamicContentTimer'));
    lTimer.Enabled := False;
    Assert.AreEqual(10000, lTimer.Interval);
    Assert.IsTrue(Assigned(lTimer.OnTimer), 'DynamicContentTimer has no update handler.');
    AssertDemoDynamicControlUpdates(lForm, 'staticDynamicCaption', TStaticText);
    AssertDemoDynamicControlUpdates(lForm, 'lblDynamicCaption', TLabel);
    AssertDemoDynamicControlUpdates(lForm, 'edtDynamicText', TEdit);
    AssertDemoDynamicControlUpdates(lForm, 'btnDynamicCaption', TButton);
    AssertDemoDynamicControlUpdates(lForm, 'bitBtnDynamicCaption', TBitBtn);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.DemoRuntimeSynchronizationWalkthroughCoversEveryPath;
var
  lButton: TButton;
  lForm: TAccessibilityDemoMainForm;
  lInitialAdvColCount: Integer;
  lInitialAdvRowCount: Integer;
  lInitialCandidateLeft: Integer;
  lInitialCaption: string;
  lInitialGridColCount: Integer;
  lInitialGridRowCount: Integer;
  lRuntimeChild: TEdit;
  lStatus: TStaticText;
begin
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    lForm.HandleNeeded;
    lForm.StringGridOrderCells.HandleNeeded;
    lInitialCaption := lForm.Caption;
    lInitialCandidateLeft := lForm.staticAmbiguousCandidateB.Left;
    lInitialGridColCount := lForm.StringGridOrderCells.ColCount;
    lInitialGridRowCount := lForm.StringGridOrderCells.RowCount;
    lInitialAdvColCount := lForm.AdvStringGridAudit.ColCount;
    lInitialAdvRowCount := lForm.AdvStringGridAudit.RowCount;

    Assert.IsTrue(lForm.FindComponent('btnRuntimeSyncStep') is TButton,
      'The demo must expose the deterministic runtime synchronization walkthrough.');
    Assert.IsTrue(lForm.FindComponent('staticRuntimeSyncState') is TStaticText,
      'The demo must expose the current runtime synchronization step.');
    lButton := TButton(lForm.FindComponent('btnRuntimeSyncStep'));
    lStatus := TStaticText(lForm.FindComponent('staticRuntimeSyncState'));

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 01');
    Assert.IsFalse(lForm.DynamicContentTimer.Enabled);
    Assert.IsFalse(lForm.btnDynamicCaption.Enabled);
    Assert.IsFalse(lForm.bitBtnDynamicCaption.Visible);
    Assert.AreNotEqual(lInitialCaption, lForm.Caption);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 02');
    Assert.IsTrue(lForm.btnDynamicCaption.Enabled);
    Assert.IsTrue(lForm.bitBtnDynamicCaption.Visible);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 03');
    Assert.IsTrue(lForm.FindComponent('edtRuntimeSyncChild') is TEdit);
    lRuntimeChild := TEdit(lForm.FindComponent('edtRuntimeSyncChild'));
    Assert.AreSame(lForm.pnlFilterQueueRow, lRuntimeChild.Parent);
    Assert.AreSame(lRuntimeChild, lForm.StaticTextQueue.FocusControl);
    Assert.IsFalse(lForm.cmbQueue.Visible);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 04');
    Assert.AreSame(lForm.pnlDynamicButtonRow, lRuntimeChild.Parent);
    Assert.AreSame(lForm.cmbQueue, lForm.StaticTextQueue.FocusControl);
    Assert.IsTrue(lForm.cmbQueue.Visible);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 05');
    Assert.IsNull(lForm.FindComponent('edtRuntimeSyncChild'));

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 06');
    Assert.IsTrue(lForm.staticAmbiguousCandidateB.Left > lForm.pnlFilterAmbiguousRow.Width);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 07');
    Assert.AreEqual(lInitialCandidateLeft, lForm.staticAmbiguousCandidateB.Left);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 08');
    Assert.IsFalse(lForm.labeledEditReference.EditLabel.Visible);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 09');
    Assert.IsTrue(lForm.labeledEditReference.EditLabel.Visible);
    Assert.Contains(lForm.labeledEditReference.EditLabel.Caption, 'runtime');

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 10');
    Assert.AreEqual(lInitialGridColCount + 1, lForm.StringGridOrderCells.ColCount);
    Assert.AreEqual(lInitialGridRowCount + 1, lForm.StringGridOrderCells.RowCount);
    Assert.IsTrue(lForm.AdvStringGridAudit.ColCount > lInitialAdvColCount);
    Assert.IsTrue(lForm.AdvStringGridAudit.RowCount > lInitialAdvRowCount);
    Assert.Contains(lForm.StringGridOrderCells.Cells[1, 1], 'runtime');
    Assert.Contains(lForm.AdvStringGridAudit.Cells[2, 2], 'runtime');

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 11');
    Assert.AreEqual(lInitialGridColCount, lForm.StringGridOrderCells.ColCount);
    Assert.AreEqual(lInitialGridRowCount, lForm.StringGridOrderCells.RowCount);
    Assert.AreEqual(lInitialAdvColCount, lForm.AdvStringGridAudit.ColCount);
    Assert.AreEqual(lInitialAdvRowCount, lForm.AdvStringGridAudit.RowCount);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 12');
    Assert.Contains(lStatus.Caption, 'control HWND recreated from');
    Assert.IsTrue(lForm.StringGridOrderCells.HandleAllocated);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 13');
    Assert.Contains(lStatus.Caption, 'form HWND recreated from');
    Assert.IsTrue(lForm.HandleAllocated);

    lButton.Click;
    Assert.Contains(lStatus.Caption, 'Step 00');
    Assert.AreEqual(lInitialCaption, lForm.Caption);
    Assert.AreEqual(lInitialCandidateLeft, lForm.staticAmbiguousCandidateB.Left);
    Assert.IsTrue(lForm.DynamicContentTimer.Enabled);
    Assert.AreEqual('TLabeledEdit reference', lForm.labeledEditReference.EditLabel.Caption);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.DemoTmsHiddenBaseMergesStayWithinGridBounds;
var
  lForm: TAccessibilityDemoMainForm;
begin
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    Assert.IsTrue(lForm.AdvStringGridAudit.ColCount >= 7,
      Format('The hidden-column merge must retain seven visible columns after hiding its base; ColCount=%d.',
        [lForm.AdvStringGridAudit.ColCount]));
    Assert.IsTrue(lForm.AdvStringGridAudit.RowCount >= 10,
      Format('The configured merges must retain ten visible rows after hiding three bases; RowCount=%d.',
        [lForm.AdvStringGridAudit.RowCount]));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.DemoLabeledBySamplesExposeExpectedRelationships;
var
  lForm: TAccessibilityDemoMainForm;
  lInputProvider: IRawElementProviderSimple;
  lLabelProvider: IRawElementProviderSimple;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    lInputProvider := ControlProvider(lProvider, lForm.edtSearch);
    lLabelProvider := ControlProvider(lProvider, lForm.StaticTextSearch);
    Assert.IsTrue(ProvidersAreSame(lLabelProvider,
      ElementProviderProperty(lInputProvider, UIA_LabeledByPropertyId)),
      'The search edit must use geometrically inferred LabeledBy.');

    lInputProvider := ControlProvider(lProvider, lForm.cmbQueue);
    lLabelProvider := ControlProvider(lProvider, lForm.StaticTextQueue);
    Assert.IsTrue(ProvidersAreSame(lLabelProvider,
      ElementProviderProperty(lInputProvider, UIA_LabeledByPropertyId)),
      'The queue combo must use explicit FocusControl LabeledBy.');

    lInputProvider := ControlProvider(lProvider, lForm.labeledEditReference);
    lLabelProvider := ControlProvider(lProvider, lForm.labeledEditReference.EditLabel);
    Assert.IsTrue(ProvidersAreSame(lLabelProvider,
      ElementProviderProperty(lInputProvider, UIA_LabeledByPropertyId)),
      'TLabeledEdit must use its bound label provider.');

    Assert.IsNull(ElementProviderProperty(ControlProvider(lProvider, lForm.edtAmbiguousLabelDemo),
      UIA_LabeledByPropertyId));
    Assert.IsNull(ElementProviderProperty(ControlProvider(lProvider, lForm.edtUnlabeledDemo),
      UIA_LabeledByPropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.RootHitTestingReturnsDeepestNonWindowedLabel;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lLabel: TLabel;
  lPanel: TPanel;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lResult: HResult;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 320, 200);

    lPanel := TPanel.Create(lForm);
    lPanel.Caption := '';
    lPanel.Parent := lForm;
    lPanel.SetBounds(16, 16, 220, 80);

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Command title';
    lLabel.Parent := lPanel;
    lLabel.SetBounds(12, 12, 120, 24);

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lLabel);

    lResult := lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit);
    Assert.IsTrue(lResult = S_OK, 'Label hit testing failed.');
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Command title', ProviderStringProperty(lHit, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.TextInputsExposeAssociatedLabelsAndValues;
var
  lCombo: TComboBox;
  lComboFragment: IRawElementProviderFragment;
  lComboLabel: TLabel;
  lEdit: TEdit;
  lEditFragment: IRawElementProviderFragment;
  lEditLabel: TLabel;
  lForm: TForm;
  lLabeledEdit: TLabeledEdit;
  lLabeledEditFragment: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 240);

    lEditLabel := TLabel.Create(lForm);
    lEditLabel.Caption := 'Customer';
    lEditLabel.Parent := lForm;
    lEditLabel.SetBounds(12, 18, 90, 20);

    lEdit := TEdit.Create(lForm);
    lEdit.Text := 'Alice';
    lEdit.Parent := lForm;
    lEdit.SetBounds(112, 14, 160, 23);

    lComboLabel := TLabel.Create(lForm);
    lComboLabel.Caption := 'Queue';
    lComboLabel.Parent := lForm;
    lComboLabel.SetBounds(12, 58, 90, 20);

    lCombo := TComboBox.Create(lForm);
    lCombo.Parent := lForm;
    lCombo.SetBounds(112, 54, 160, 23);
    lCombo.Items.Add('Urgent');
    lCombo.ItemIndex := 0;

    lLabeledEdit := TLabeledEdit.Create(lForm);
    lLabeledEdit.Parent := lForm;
    lLabeledEdit.EditLabel.Caption := 'Reference number';
    lLabeledEdit.Text := 'REF-1042';
    lLabeledEdit.SetBounds(112, 98, 160, 23);

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    lPoint := ControlScreenCenter(lEdit);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lEditFragment));
    Assert.IsNotNull(lEditFragment);

    lPoint := ControlScreenCenter(lCombo);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lComboFragment));
    Assert.IsNotNull(lComboFragment);

    lPoint := ControlScreenCenter(lLabeledEdit);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lLabeledEditFragment));
    Assert.IsNotNull(lLabeledEditFragment);

    Assert.AreEqual('Customer', ProviderStringProperty(lEditFragment, UIA_NamePropertyId));
    Assert.AreEqual('Alice', ValuePatternText(lEditFragment));

    Assert.AreEqual('Queue', ProviderStringProperty(lComboFragment, UIA_NamePropertyId));
    Assert.AreEqual('Urgent', ValuePatternText(lComboFragment));

    Assert.AreEqual('Reference number', ProviderStringProperty(lLabeledEditFragment, UIA_NamePropertyId));
    Assert.AreEqual('REF-1042', ValuePatternText(lLabeledEditFragment));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.TextInputsExposeExactLabeledByProviders;
var
  lCombo: TComboBox;
  lExplicitEdit: TEdit;
  lExplicitLabel: TLabel;
  lForm: TForm;
  lInferredLabel: TStaticText;
  lLabeledEdit: TLabeledEdit;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    CreateExplicitLabeledBySample(lForm, lExplicitLabel, lExplicitEdit);
    CreateInferredLabeledBySample(lForm, lInferredLabel, lCombo);
    lLabeledEdit := CreateLabeledEditSample(lForm);
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    AssertControlLabeledBy(lProvider, lExplicitEdit, lExplicitLabel);
    AssertControlLabeledBy(lProvider, lCombo, lInferredLabel);
    AssertControlLabeledBy(lProvider, lLabeledEdit, lLabeledEdit.EditLabel);
    Assert.AreEqual('Account', SimpleProviderStringProperty(
      ControlProvider(lProvider, lExplicitEdit), UIA_NamePropertyId),
      'Existing accessible Name fallback must remain available.');
    lExplicitLabel.Caption := 'Current account';
    Assert.AreEqual('Current account', SimpleProviderStringProperty(ElementProviderProperty(
      ControlProvider(lProvider, lExplicitEdit), UIA_LabeledByPropertyId), UIA_NamePropertyId),
      'LabeledBy must expose the current label caption.');
    Assert.AreEqual('Current account', SimpleProviderStringProperty(
      ControlProvider(lProvider, lExplicitEdit), UIA_NamePropertyId),
      'Accessible Name fallback must stay current with LabeledBy.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.TextInputsRejectInvalidLabeledByRelationships;
var
  i: Integer;
  lForm: TForm;
  lInputs: TArray<TControl>;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    SetLength(lInputs, 7);
    lInputs[0] := CreateRejectedExplicitLabelSample(lForm, 'HiddenLabelEdit',
      'Hidden label', 'Hidden value', 12, False);
    lInputs[1] := CreateRejectedExplicitLabelSample(lForm, 'EmptyLabelEdit', '', 'Empty value', 52, True);
    lInputs[2] := CreateRejectedExplicitLabelSample(lForm, 'IconLabelEdit',
      WideChar($E001), 'Icon value', 92, True);
    lInputs[3] := CreateCrossContainerLabelSample(lForm);
    lInputs[4] := CreateAmbiguousLabelSample(lForm);
    lInputs[5] := CreateUnlabeledSample(lForm);
    lInputs[6] := CreateDistantLabelSample(lForm);
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    for i := 0 to High(lInputs) do
    begin
      AssertControlHasNoLabeledBy(lProvider, lInputs[i]);
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.FormRootProviderUsesWindowControlType;
var
  lForm: TForm;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    Assert.AreEqual(UIA_WindowControlTypeId, ProviderIntProperty(lProvider.FragmentProvider,
      UIA_ControlTypePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.FormRootProviderOverridesNativeWindowTree;
var
  lForm: TForm;
  lOptions: ProviderOptions;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    lOptions := ProviderOptionsFor(lProvider.FragmentProvider);

    Assert.IsTrue((Integer(lOptions) and Integer(ProviderOptions_OverrideProvider)) <> 0,
      'The form root provider should override the native VCL form provider so external ControlView walks do not merge the layout-only HWND tree.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.TextEditProviderExposesEditTypeAndTextHintHelp;
var
  lEdit: TEdit;
  lEditFragment: IRawElementProviderFragment;
  lEditLabel: TLabel;
  lForm: TForm;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 120);

    lEditLabel := TLabel.Create(lForm);
    lEditLabel.Caption := 'Search text';
    lEditLabel.Parent := lForm;
    lEditLabel.SetBounds(12, 18, 90, 20);

    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.Hint := 'Search demo orders and audit findings';
    lEdit.TextHint := 'customer, order, or finding';
    lEdit.SetBounds(112, 14, 160, 23);

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lEdit);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lEditFragment));
    Assert.IsNotNull(lEditFragment);
    Assert.AreEqual('Search text', ProviderStringProperty(lEditFragment, UIA_NamePropertyId));
    Assert.AreEqual(UIA_EditControlTypeId, ProviderIntProperty(lEditFragment, UIA_ControlTypePropertyId));
    Assert.AreEqual('customer, order, or finding. Search demo orders and audit findings',
      ProviderStringProperty(lEditFragment, UIA_HelpTextPropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.MemoProviderHitTestingReturnsLineUnderPointer;
var
  lCharIndex: LRESULT;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lLinePoint: TPoint;
  lMemo: TMemo;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lResult: HResult;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lMemo := TMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.ScrollBars := ssNone;
    lMemo.WordWrap := False;
    lMemo.SetBounds(16, 16, 260, 100);
    lMemo.Lines.Text := 'First memo line' + sLineBreak + 'Second memo line' + sLineBreak + 'Third memo line';

    lForm.HandleNeeded;
    lMemo.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lCharIndex := lMemo.Perform(EM_LINEINDEX, 1, 0);
    lLinePoint := PointFromMessageResult(lMemo.Perform(EM_POSFROMCHAR, lCharIndex, 0));
    lPoint := lMemo.ClientToScreen(Point(lLinePoint.X + 4, lLinePoint.Y + 2));

    lResult := lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit);
    Assert.IsTrue(lResult = S_OK, 'Memo hit testing failed.');
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Second memo line', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.AreEqual(UIA_TextControlTypeId, ProviderIntProperty(lHit, UIA_ControlTypePropertyId));

    lForm.ActiveControl := lMemo;
    lResult := lRoot.GetFocus(lFocus);
    Assert.IsTrue(lResult = S_OK, 'Memo focus query failed.');
    Assert.IsNull(lFocus, 'memo framework focus should stay out of native caret-line speech');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.MemoProviderCacheRemainsBoundedAcrossScrollHistory;
const
  cLineCount = 10000;
  cMaximumRetainedLines = 32;
  cScrollCount = 100;
var
  i: Integer;
  lAccess: IAccessibilityProviderChildAccess;
  lChildIndex: Integer;
  lChildName: string;
  lChildProvider: IRawElementProviderSimple;
  lCurrentFirstLine: Integer;
  lForm: TForm;
  lInitialCount: Integer;
  lInitialTicks: Int64;
  lMemo: TMemo;
  lMemoFragment: IRawElementProviderFragment;
  lMaxRetained: Integer;
  lProvider: IAccessibilityProviderNode;
  lPreviousIndex: Integer;
  lRetainedCount: Integer;
  lResult: HResult;
  lSamples: TArray<Int64>;
  lStaleLine: IRawElementProviderSimple;
  lStopwatch: TStopwatch;
  lTargetFirstLine: Integer;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);
    lMemo := TMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.ScrollBars := ssVertical;
    lMemo.WordWrap := False;
    lMemo.SetBounds(16, 16, 260, 100);
    lMemo.Lines.BeginUpdate;
    try
      for i := 0 to Pred(cLineCount) do
      begin
        lMemo.Lines.Add(Format('Memo line %.5d', [i]));
      end;
    finally
      lMemo.Lines.EndUpdate;
    end;

    lForm.HandleNeeded;
    lMemo.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lMemoFragment := FirstChildFragment(lProvider);
    Assert.IsTrue(Supports(lMemoFragment, IAccessibilityProviderChildAccess, lAccess));
    lStopwatch := TStopwatch.StartNew;
    lResult := lAccess.DirectChildCount(lInitialCount);
    lInitialTicks := lStopwatch.ElapsedTicks;
    Assert.AreEqual(S_OK, lResult);
    Assert.IsTrue(lInitialCount > 0);
    Assert.IsTrue(lInitialCount <= cMaximumRetainedLines,
      Format('Initial memo viewport retained %d providers; absolute ceiling is %d.',
      [lInitialCount, cMaximumRetainedLines]));
    Assert.AreEqual(S_OK, lAccess.DirectChildAt(0, lStaleLine));
    Assert.IsNotNull(lStaleLine);
    lMaxRetained := lInitialCount;
    SetLength(lSamples, cScrollCount);

    for i := 1 to cScrollCount do
    begin
      lTargetFirstLine := i * (cLineCount div (cScrollCount + 1));
      lCurrentFirstLine := Integer(SendMessage(lMemo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0));
      SendMessage(lMemo.Handle, EM_LINESCROLL, 0, lTargetFirstLine - lCurrentFirstLine);
      lStopwatch := TStopwatch.StartNew;
      lResult := lAccess.DirectChildCount(lRetainedCount);
      lSamples[Pred(i)] := lStopwatch.ElapsedTicks;
      Assert.AreEqual(S_OK, lResult);
      lMaxRetained := Max(lMaxRetained, lRetainedCount);
    end;

    lCurrentFirstLine := Integer(SendMessage(lMemo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0));
    SendMessage(lMemo.Handle, EM_LINESCROLL, 0, -2);
    Assert.AreEqual(S_OK, lAccess.DirectChildCount(lRetainedCount));
    Assert.AreNotEqual(lCurrentFirstLine,
      Integer(SendMessage(lMemo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0)), 'Memo must scroll upward for the order check.');
    lPreviousIndex := -1;
    for i := 0 to Pred(lRetainedCount) do
    begin
      Assert.AreEqual(S_OK, lAccess.DirectChildAt(i, lChildProvider));
      Assert.AreEqual(S_OK, lChildProvider.GetPropertyValue(UIA_NamePropertyId, lValue));
      lChildName := string(lValue);
      Assert.AreEqual('Memo line ', Copy(lChildName, 1, 10));
      lChildIndex := StrToInt(Copy(lChildName, 11, MaxInt));
      Assert.IsTrue(lChildIndex > lPreviousIndex,
        Format('Memo children are out of line order: %d followed %d.', [lPreviousIndex, lChildIndex]));
      lPreviousIndex := lChildIndex;
    end;

    WriteT113Samples('memo', lSamples, lMaxRetained, lInitialTicks);
    Assert.IsTrue(lMaxRetained <= cMaximumRetainedLines,
      Format('Memo retained up to %d line providers; absolute ceiling is %d.',
      [lMaxRetained, cMaximumRetainedLines]));
    Assert.IsTrue(lMaxRetained <= lInitialCount + 1,
      Format('Memo retained up to %d line providers; viewport bound is %d.', [lMaxRetained, lInitialCount + 1]));
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      lStaleLine.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.IsTrue(VarIsEmpty(lValue), 'A stale memo provider must clear its property value.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.MemoHitTestingPrunesScrolledProviders;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lMemo: TMemo;
  lMemoFragment: IRawElementProviderFragment;
  lMemoRoot: IRawElementProviderFragmentRoot;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lStaleLine: IRawElementProviderFragment;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lMemo := TMemo.Create(lForm);
    lMemo.Parent := lForm;
    lMemo.ScrollBars := ssVertical;
    lMemo.WordWrap := False;
    lMemo.SetBounds(16, 16, 260, 100);
    FillMemo(lMemo, 1000);
    lForm.HandleNeeded;
    lMemo.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lMemoFragment := FirstChildFragment(lProvider);
    Assert.AreEqual(S_OK, lMemoFragment.Navigate(NavigateDirection_FirstChild, lStaleLine));
    Assert.IsNotNull(lStaleLine);

    SendMessage(lMemo.Handle, EM_LINESCROLL, 0, 500);
    Assert.IsTrue(Supports(lMemoFragment, IRawElementProviderFragmentRoot, lMemoRoot));
    lPoint := lMemo.ClientToScreen(Point(8, 8));
    Assert.AreEqual(S_OK, lMemoRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      SimpleProvider(lStaleLine).GetPropertyValue(UIA_NamePropertyId, lValue),
      'A scroll-and-hit-test path must prune providers from the old memo viewport.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxHitTestingPrunesScrolledProviders;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lListBoxRoot: IRawElementProviderFragmentRoot;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lStaleItem: IRawElementProviderFragment;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 240, 110);
    FillListBox(lListBox, 1000);
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    Assert.AreEqual(S_OK, lListBoxFragment.Navigate(NavigateDirection_FirstChild, lStaleItem));
    Assert.IsNotNull(lStaleItem);

    lListBox.TopIndex := 500;
    Assert.IsTrue(Supports(lListBoxFragment, IRawElementProviderFragmentRoot, lListBoxRoot));
    lPoint := lListBox.ClientToScreen(lListBox.ItemRect(500).CenterPoint);
    Assert.AreEqual(S_OK, lListBoxRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      SimpleProvider(lStaleItem).GetPropertyValue(UIA_NamePropertyId, lValue),
      'A scroll-and-hit-test path must prune providers from the old listbox viewport.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxSingleSelectionPrunesOldProviders;
var
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lOldSelection: IRawElementProviderSimple;
  lProvider: IAccessibilityProviderNode;
  lSelectionProvider: ISelectionProvider;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 240, 110);
    FillListBox(lListBox, 1000);
    lListBox.ItemIndex := 0;
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    lSelectionProvider := SelectionPattern(lListBoxFragment);
    lOldSelection := SelectedSimpleProvider(lSelectionProvider, 0);

    lListBox.ItemIndex := 900;
    Assert.AreEqual('List item 00900', ProviderStringProperty(
      SelectedSimpleProvider(lSelectionProvider, 0) as IRawElementProviderFragment, UIA_NamePropertyId));
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      lOldSelection.GetPropertyValue(UIA_NamePropertyId, lValue),
      'Single-select GetSelection must prune the old selected provider.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxSiblingNavigationReconcilesSelectionOnlyChanges;
var
  lCurrent: IRawElementProviderFragment;
  lForm: TForm;
  lListBox: TSelectionProbeListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lNext: IRawElementProviderFragment;
  lOldSelection: IRawElementProviderSimple;
  lProvider: IAccessibilityProviderNode;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TSelectionProbeListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.MultiSelect := True;
    lListBox.SetBounds(16, 16, 240, 110);
    FillListBox(lListBox, 100);
    lListBox.ItemIndex := 0;
    lListBox.Selected[0] := True;
    lListBox.Selected[99] := True;
    lListBox.ItemIndex := 0;
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    lOldSelection := SelectedSimpleProvider(SelectionPattern(lListBoxFragment), 1);
    Assert.AreEqual(S_OK, lOldSelection.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.AreEqual('List item 00099', string(lValue));
    Assert.AreEqual(S_OK, lListBoxFragment.Navigate(NavigateDirection_FirstChild, lCurrent));
    Assert.IsNotNull(lCurrent);
    lCurrent := NextSiblingFragment(lCurrent);

    lListBox.Selected[99] := False;
    lListBox.Selected[98] := True;
    lListBox.ItemIndex := 0;
    Assert.IsFalse(lListBox.Selected[99]);
    Assert.IsTrue(lListBox.Selected[98]);
    Assert.AreEqual(0, lListBox.ItemIndex);
    lListBox.ResetGetSelectionMessageCount;
    Assert.AreEqual(S_OK, lCurrent.Navigate(NavigateDirection_NextSibling, lNext));
    Assert.IsNotNull(lNext);
    Assert.IsTrue(lListBox.BulkSelectionMessageCount > 0,
      'Sibling validation must bulk-read native multi-selection state.');
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      lOldSelection.GetPropertyValue(UIA_NamePropertyId, lValue),
      'Sibling validation must reconcile same-count native selection changes.');
    Assert.IsTrue(VarIsEmpty(lValue), 'A stale selected provider must clear its property value.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxSiblingNavigationRevalidatesResumedTraversal;
var
  lCurrent: IRawElementProviderFragment;
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lNext: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 240, 110);
    FillListBox(lListBox, 100);
    lListBox.ItemIndex := 0;
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    Assert.AreEqual(S_OK, lListBoxFragment.Navigate(NavigateDirection_FirstChild, lCurrent));
    lCurrent := NextSiblingFragment(lCurrent);

    lListBox.TopIndex := 50;
    Assert.AreEqual(S_OK, lCurrent.Navigate(NavigateDirection_NextSibling, lNext));
    Assert.IsNull(lNext, 'Resumed traversal must not return a child from the old viewport.');
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      SimpleProvider(lCurrent).GetPropertyValue(UIA_NamePropertyId, lValue));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxGetFocusPrunesScrolledProviders;
var
  lFirstItem: IRawElementProviderFragment;
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lStaleItem: IRawElementProviderSimple;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 240, 110);
    FillListBox(lListBox, 100);
    lListBox.ItemIndex := 0;
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lListBoxFragment := FirstChildFragment(lProvider);
    Assert.AreEqual(S_OK, lListBoxFragment.Navigate(NavigateDirection_FirstChild, lFirstItem));
    Assert.IsNotNull(lFirstItem);
    lStaleItem := SimpleProvider(NextSiblingFragment(lFirstItem));

    lListBox.TopIndex := 50;
    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus);
    Assert.AreEqual('List item 00000', ProviderStringProperty(lFocus, UIA_NamePropertyId));
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      lStaleItem.GetPropertyValue(UIA_NamePropertyId, lValue),
      'GetFocus must evict providers from the old viewport.');
    Assert.IsTrue(VarIsEmpty(lValue), 'A provider evicted by GetFocus must clear its property value.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxProviderHitTestingAndFocusReturnItems;
var
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lItemRect: TRect;
  lListBox: TListBox;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 240, 110);
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.Items.Add('Completed action');
    lListBox.ItemIndex := 1;

    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    lItemRect := lListBox.ItemRect(2);
    lPoint := lListBox.ClientToScreen(lItemRect.CenterPoint);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit, 'listbox mouse hit-test item');
    Assert.AreEqual('Completed action', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.AreEqual(UIA_ListItemControlTypeId, ProviderIntProperty(lHit, UIA_ControlTypePropertyId));

    lFocus := FragmentFocus(lRoot);
    Assert.IsNotNull(lFocus, 'listbox focused selected item');
    Assert.AreEqual('Audit warning', ProviderStringProperty(lFocus, UIA_NamePropertyId));
    Assert.AreEqual(UIA_ListItemControlTypeId, ProviderIntProperty(lFocus, UIA_ControlTypePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxProviderCacheRemainsBoundedAcrossScrollHistory;
const
  cItemCount = 10000;
  cMaximumRetainedItems = 32;
  cScrollCount = 100;
var
  i: Integer;
  lAccess: IAccessibilityProviderChildAccess;
  lChildIndex: Integer;
  lChildName: string;
  lChildProvider: IRawElementProviderSimple;
  lFocusedItem: IRawElementProviderFragment;
  lForm: TForm;
  lInitialCount: Integer;
  lInitialTicks: Int64;
  lItemRect: TRect;
  lListBox: TSelectionProbeListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lListBoxRoot: IRawElementProviderFragmentRoot;
  lMaxRetained: Integer;
  lNextSibling: IRawElementProviderFragment;
  lPersistentSelectedItem: IRawElementProviderSimple;
  lPersistentSelectedUnknown: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lPoint: TPoint;
  lPreviousIndex: Integer;
  lRetainedCount: Integer;
  lRetainedSelectedItem: IRawElementProviderSimple;
  lResult: HResult;
  lSamples: TArray<Int64>;
  lSelectedItem: IRawElementProviderSimple;
  lSelectedIndex: LongInt;
  lSelectedUnknown: IUnknown;
  lSelection: PSafeArray;
  lSelectionProvider: ISelectionProvider;
  lStaleItem: IRawElementProviderSimple;
  lStaleItemFragment: IRawElementProviderFragment;
  lStopwatch: TStopwatch;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);
    lListBox := TSelectionProbeListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.MultiSelect := True;
    lListBox.SetBounds(16, 16, 240, 110);
    lListBox.Items.BeginUpdate;
    try
      for i := 0 to Pred(cItemCount) do
      begin
        lListBox.Items.Add(Format('List item %.5d', [i]));
      end;
    finally
      lListBox.Items.EndUpdate;
    end;

    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lListBox.Selected[5] := True;
    lListBox.Selected[Pred(cItemCount)] := True;
    lListBox.ItemIndex := cItemCount div 2;
    lListBox.TopIndex := 0;
    lForm.ActiveControl := lListBox;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    Assert.IsTrue(Supports(lListBoxFragment, IRawElementProviderFragmentRoot, lListBoxRoot));
    Assert.AreEqual(S_OK, lListBoxRoot.GetFocus(lFocusedItem));
    Assert.IsNotNull(lFocusedItem);
    Assert.IsTrue(Supports(lListBoxFragment, IAccessibilityProviderChildAccess, lAccess));
    lStopwatch := TStopwatch.StartNew;
    lResult := lAccess.DirectChildCount(lInitialCount);
    lInitialTicks := lStopwatch.ElapsedTicks;
    Assert.AreEqual(S_OK, lResult);
    Assert.IsTrue(lInitialCount > 0);
    Assert.IsTrue(lInitialCount <= cMaximumRetainedItems,
      Format('Initial listbox viewport retained %d providers; absolute ceiling is %d.',
      [lInitialCount, cMaximumRetainedItems]));
    Assert.AreEqual(S_OK, lAccess.DirectChildAt(1, lRetainedSelectedItem));
    Assert.IsNotNull(lRetainedSelectedItem);
    lItemRect := lListBox.ItemRect(0);
    lPoint := lListBox.ClientToScreen(lItemRect.CenterPoint);
    Assert.AreEqual(S_OK, lListBoxRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lStaleItemFragment));
    Assert.IsNotNull(lStaleItemFragment);
    lStaleItem := SimpleProvider(lStaleItemFragment);

    lSelectionProvider := SelectionPattern(lListBoxFragment);
    Assert.AreEqual(S_OK, lSelectionProvider.GetSelection(lSelection));
    try
      Assert.IsNotNull(lSelection);
      lSelectedIndex := 0;
      Assert.AreEqual(S_OK, SafeArrayGetElement(lSelection, lSelectedIndex, lSelectedUnknown));
      Assert.IsTrue(Supports(lSelectedUnknown, IRawElementProviderSimple, lSelectedItem));
      lSelectedIndex := 1;
      Assert.AreEqual(S_OK, SafeArrayGetElement(lSelection, lSelectedIndex, lPersistentSelectedUnknown));
      Assert.IsTrue(Supports(lPersistentSelectedUnknown, IRawElementProviderSimple, lPersistentSelectedItem));
    finally
      if lSelection <> nil then
      begin
        SafeArrayDestroy(lSelection);
      end;
    end;
    Assert.AreEqual(S_OK, lAccess.DirectChildCount(lInitialCount));
    Assert.IsTrue(lInitialCount <= cMaximumRetainedItems,
      Format('Initial listbox selection materialized %d providers; absolute ceiling is %d.',
      [lInitialCount, cMaximumRetainedItems]));
    lListBox.Selected[5] := False;
    lListBox.Selected[1] := True;
    lListBox.ItemIndex := cItemCount div 2;
    lListBox.TopIndex := cItemCount div (cScrollCount + 1);
    Assert.AreEqual(S_OK, lStaleItemFragment.Navigate(NavigateDirection_NextSibling, lNextSibling));
    Assert.IsNull(lNextSibling, 'Sibling navigation must reconcile the new viewport before returning a child.');
    Assert.AreEqual(S_OK, lAccess.DirectChildCount(lRetainedCount));
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      lSelectedItem.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.AreEqual(S_OK, lRetainedSelectedItem.GetPropertyValue(UIA_NamePropertyId, lValue),
      'Newly selected native item must remain live after reconciliation.');
    Assert.AreEqual('List item 00001', string(lValue));
    Assert.AreEqual(S_OK, lPersistentSelectedItem.GetPropertyValue(UIA_NamePropertyId, lValue),
      'Persistently selected item must remain live after reconciliation.');
    Assert.AreEqual('List item 09999', string(lValue));

    lPreviousIndex := -1;
    for i := 0 to Pred(lRetainedCount) do
    begin
      Assert.AreEqual(S_OK, lAccess.DirectChildAt(i, lChildProvider),
        Format('Retained child %d must remain enumerable.', [i]));
      Assert.AreEqual(S_OK, lChildProvider.GetPropertyValue(UIA_NamePropertyId, lValue),
        Format('Retained child %d must remain live.', [i]));
      lChildName := string(lValue);
      Assert.AreEqual('List item ', Copy(lChildName, 1, 10));
      lChildIndex := StrToInt(Copy(lChildName, 11, MaxInt));
      Assert.IsTrue(lChildIndex > lPreviousIndex,
        Format('Listbox children are out of index order: %d followed %d.', [lPreviousIndex, lChildIndex]));
      lPreviousIndex := lChildIndex;
    end;

    lMaxRetained := Max(lInitialCount, lRetainedCount);
    SetLength(lSamples, cScrollCount);
    lListBox.ResetGetSelectionMessageCount;

    for i := 1 to cScrollCount do
    begin
      lListBox.TopIndex := i * (cItemCount div (cScrollCount + 1));
      lStopwatch := TStopwatch.StartNew;
      lResult := lAccess.DirectChildCount(lRetainedCount);
      lSamples[Pred(i)] := lStopwatch.ElapsedTicks;
      Assert.AreEqual(S_OK, lResult);
      lMaxRetained := Max(lMaxRetained, lRetainedCount);
    end;

    WriteT113Samples('listbox', lSamples, lMaxRetained, lInitialTicks);
    Assert.AreEqual(0, lListBox.GetSelectionMessageCount,
      'Scrolling should use one bulk selection snapshot instead of per-item LB_GETSEL queries.');
    Assert.IsTrue(lListBox.BulkSelectionMessageCount > 0,
      'Scrolling a multi-select listbox must refresh its native selection snapshot.');
    Assert.IsTrue(lListBox.BulkSelectionMessageCount <= (cScrollCount * 2),
      Format('Scrolling used %d bulk selection messages; expected at most two per reconciliation.',
      [lListBox.BulkSelectionMessageCount]));
    Assert.IsTrue(lMaxRetained <= cMaximumRetainedItems,
      Format('Listbox retained up to %d item providers; absolute ceiling is %d.',
      [lMaxRetained, cMaximumRetainedItems]));
    Assert.IsTrue(lMaxRetained <= lInitialCount + 1,
      Format('Listbox retained up to %d item providers; viewport/focus/selection bound is %d.',
      [lMaxRetained, lInitialCount + 1]));
    Assert.AreEqual(S_OK, lRetainedSelectedItem.GetPropertyValue(UIA_NamePropertyId, lValue),
      'Newly selected native item must survive all scrolls.');
    Assert.AreEqual('List item 00001', string(lValue));
    Assert.AreEqual(S_OK, lPersistentSelectedItem.GetPropertyValue(UIA_NamePropertyId, lValue),
      'Persistently selected item must survive all scrolls.');
    Assert.AreEqual('List item 09999', string(lValue));
    Assert.AreEqual(S_OK, SimpleProvider(lFocusedItem).GetPropertyValue(UIA_NamePropertyId, lValue),
      'Focused item must survive all scrolls.');
    Assert.AreEqual('List item 05000', string(lValue));
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      lStaleItem.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.IsTrue(VarIsEmpty(lValue), 'A stale listbox provider must clear its property value.');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxSelectionCollapseScalesLinearly;
const
  cGrowthFactor = 4;
  cMaximumTickGrowth = 12;
  cSmallItemCount = 512;
var
  lLargeTicks: Int64;
  lSmallTicks: Int64;
begin
  lSmallTicks := MeasureListBoxSelectionCollapseTicks(128, False);
  Assert.IsTrue(lSmallTicks > 0, 'Selection-collapse warm-up must be positive.');
  lSmallTicks := MeasureBestListBoxSelectionCollapseTicks(cSmallItemCount, False, 3);
  lLargeTicks := MeasureBestListBoxSelectionCollapseTicks(cSmallItemCount * cGrowthFactor, False, 3);

  Assert.IsTrue(lLargeTicks <= lSmallTicks * cMaximumTickGrowth,
    Format('Selection collapse grew from %d to %d ticks for %dx items.',
    [lSmallTicks, lLargeTicks, cGrowthFactor]));
end;

procedure TAccessibilityVclAdaptersTests.ListBoxPartialSelectionPruneUsesBoundedNativeQueries;
const
  cItemCount = 256;
  cMaximumBulkSelectionMessages = 2;
  cMaximumItemCountReads = 8;
var
  i: Integer;
  lAccess: IAccessibilityProviderChildAccess;
  lChildCount: Integer;
  lForm: TForm;
  lListBox: TSelectionProbeListBox;
  lListBoxFragment: IRawElementProviderFragment;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TSelectionProbeListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.MultiSelect := True;
    lListBox.SetBounds(16, 16, 240, 110);
    FillListBox(lListBox, cItemCount);
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    for i := 0 to Pred(cItemCount) do
    begin
      lListBox.Selected[i] := True;
    end;

    Assert.AreEqual(S_OK, TAccessibilityVclProviderBuilder.BuildForm(lForm).FragmentProvider.Navigate(
      NavigateDirection_FirstChild, lListBoxFragment));
    MaterializeListBoxSelection(lListBoxFragment);
    Assert.IsTrue(Supports(lListBoxFragment, IAccessibilityProviderChildAccess, lAccess));
    Assert.AreEqual(S_OK, lAccess.DirectChildCount(lChildCount));
    Assert.AreEqual(cItemCount, lChildCount);
    for i := 0 to Pred(cItemCount div 2) do
    begin
      lListBox.Selected[i] := False;
    end;

    lListBox.ResetGetItemCountMessageCount;
    lListBox.ResetGetSelectionMessageCount;
    Assert.AreEqual(S_OK, lAccess.DirectChildCount(lChildCount));
    Assert.IsTrue(lChildCount < cItemCount, 'Partial pruning must remove unretained providers.');
    Assert.AreEqual(0, lListBox.GetSelectionMessageCount,
      'Partial pruning must use a bulk selection snapshot instead of per-item LB_GETSEL queries.');
    Assert.IsTrue(lListBox.BulkSelectionMessageCount <= cMaximumBulkSelectionMessages,
      Format('Partial pruning used %d bulk selection messages; expected at most %d.',
      [lListBox.BulkSelectionMessageCount, cMaximumBulkSelectionMessages]));
    Assert.IsTrue(lListBox.GetItemCountMessageCount <= cMaximumItemCountReads,
      Format('Partial pruning queried LB_GETCOUNT %d times; expected at most %d.',
      [lListBox.GetItemCountMessageCount, cMaximumItemCountReads]));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxRetainedItemDisconnectsWhenControlIsDestroyed;
var
  lForm: TForm;
  lItem: IRawElementProviderSimple;
  lItemFragment: IRawElementProviderFragment;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lValue: OleVariant;
begin
  lForm := TForm.Create(nil);
  try
    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.Items.Add('Retained item');
    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    Assert.AreEqual(S_OK, lListBoxFragment.Navigate(NavigateDirection_FirstChild, lItemFragment));
    Assert.IsNotNull(lItemFragment);
    lItem := SimpleProvider(lItemFragment);

    FreeAndNil(lListBox);
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lItem.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.IsTrue(VarIsEmpty(lValue));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxProviderReturnsAllSelectedItemsForMultiSelect;
var
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lSelection: PSafeArray;
  lSelectionProvider: ISelectionProvider;
  lUpperBound: LongInt;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.MultiSelect := True;
    lListBox.SetBounds(16, 16, 240, 110);
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.Items.Add('Completed action');
    lListBox.Selected[0] := True;
    lListBox.Selected[2] := True;
    lListBox.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    lSelectionProvider := SelectionPattern(lListBoxFragment);
    lSelection := nil;
    Assert.AreEqual(S_OK, lSelectionProvider.GetSelection(lSelection));
    try
      Assert.IsNotNull(lSelection);
      Assert.AreEqual(S_OK, SafeArrayGetUBound(lSelection, 1, lUpperBound));
      Assert.AreEqual(1, Integer(lUpperBound));
      Assert.AreEqual('Queued order', SelectionProviderName(lSelection, 0));
      Assert.AreEqual('Completed action', SelectionProviderName(lSelection, 1));
    finally
      if lSelection <> nil then
      begin
        SafeArrayDestroy(lSelection);
      end;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxSelectionContainerUsesOwnerWithoutNavigation;
var
  lContainer: IRawElementProviderSimple;
  lContainerFragment: IRawElementProviderFragment;
  lForm: TForm;
  lItem: IRawElementProviderFragment;
  lListBox: TListBox;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lSelectionItem: ISelectionItemProvider;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 360, 240);

    lListBox := TListBox.Create(lForm);
    lListBox.Name := 'EventList';
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 240, 100);
    lListBox.Items.Add('First event');
    lListBox.Items.Add('Second event');
    lListBox.ItemIndex := 1;

    lForm.HandleNeeded;
    lListBox.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lItem := FindDescendantByName(lProvider.FragmentProvider, 'Second event');
    Assert.IsNotNull(lItem);
    lPattern := ProviderPattern(lItem, UIA_SelectionItemPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lContainer := nil;
      Assert.AreEqual(S_OK, lSelectionItem.Get_SelectionContainer(lContainer));
      Assert.IsNotNull(lContainer);
      Assert.IsTrue(Supports(lContainer, IRawElementProviderFragment, lContainerFragment));
      Assert.AreEqual('EventList', ProviderStringProperty(lContainerFragment, UIA_NamePropertyId));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
        'Listbox selection items should return their owner directly instead of calling public Navigate(Parent).');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxProviderKeepsNativeHwndInternalWithoutPublishingIt;
var
  lApi: IHostProbeUiaApi;
  lForm: TForm;
  lHost: IRawElementProviderSimple;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
begin
  lApi := THostProbeUiaApi.Create;
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.Name := 'Events';
    lListBox.SetBounds(16, 16, 240, 110);
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm, IAccessibilityAdapterRegistry(nil), lApi);
    lListBoxFragment := FindDescendantByName(lProvider.FragmentProvider, 'Events');
    Assert.IsNotNull(lListBoxFragment);
    Assert.AreEqual(Integer(lListBox.Handle), Integer(ProviderNativeWindowHandle(lListBoxFragment)));
    Assert.AreEqual(0, Integer(ProviderPublishedNativeWindowHandle(lListBoxFragment)));
    Assert.AreEqual(S_FALSE, SimpleProvider(lListBoxFragment).Get_HostRawElementProvider(lHost));
    Assert.AreEqual(0, lApi.HostCalls);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxItemProviderHandlesStaleItemIndex;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lIsSelected: BOOL;
  lItemPattern: ISelectionItemProvider;
  lItemRect: TRect;
  lListBox: TListBox;
  lPattern: IUnknown;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.MultiSelect := True;
    lListBox.SetBounds(16, 16, 240, 110);
    lListBox.Items.Add('Queued order');
    lListBox.Items.Add('Audit warning');
    lListBox.Items.Add('Completed action');
    lListBox.Selected[2] := True;

    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lItemRect := lListBox.ItemRect(2);
    lPoint := lListBox.ClientToScreen(lItemRect.CenterPoint);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    lPattern := ProviderPattern(lHit, UIA_SelectionItemPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lItemPattern));

    lListBox.Items.Clear;
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lItemPattern.Get_IsSelected(lIsSelected));
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE, lItemPattern.RemoveFromSelection);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ListBoxProviderStopsReturningFocusItemWhenCachedTextBecomesEmpty;
var
  lFocus: IRawElementProviderFragment;
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lListBoxRoot: IRawElementProviderFragmentRoot;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.SetBounds(16, 16, 240, 110);
    lListBox.Items.Add('Queued order');
    lListBox.ItemIndex := 0;

    lForm.HandleNeeded;
    lListBox.HandleNeeded;
    lForm.ActiveControl := lListBox;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lListBoxFragment := FirstChildFragment(lProvider);
    Assert.IsTrue(Supports(lListBoxFragment, IRawElementProviderFragmentRoot, lListBoxRoot));

    Assert.AreEqual(S_OK, lListBoxRoot.GetFocus(lFocus));
    Assert.IsNotNull(lFocus, 'listbox focused item before text change');

    lListBox.Items[0] := '   ';
    Assert.AreEqual(S_OK, lListBoxRoot.GetFocus(lFocus));
    Assert.IsNull(lFocus, 'empty cleaned listbox text must not stay exposed through a cached item provider');
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.StatusBarProviderUsesVisibleStatusText;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lStatusBar: TStatusBar;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lStatusBar := TStatusBar.Create(lForm);
    lStatusBar.Parent := lForm;
    lStatusBar.SimplePanel := True;
    lStatusBar.SimpleText := 'Ready. High severity checks: 4';
    lStatusBar.SetBounds(0, 170, 420, 24);

    lForm.HandleNeeded;
    lStatusBar.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lStatusBar);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Ready. High severity checks: 4', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.AreEqual(UIA_StatusBarControlTypeId, ProviderIntProperty(lHit, UIA_ControlTypePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.StatusBarProviderUsesCurrentHelpText;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lStatusBar: TStatusBar;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lStatusBar := TStatusBar.Create(lForm);
    lStatusBar.Parent := lForm;
    lStatusBar.Hint := 'Initial status help';
    lStatusBar.SetBounds(0, 170, 420, 24);

    lForm.HandleNeeded;
    lStatusBar.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lStatusBar);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.AreEqual('Initial status help', ProviderStringProperty(lHit, UIA_HelpTextPropertyId));

    lStatusBar.Hint := 'Updated status help';

    Assert.AreEqual('Updated status help', ProviderStringProperty(lHit, UIA_HelpTextPropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.StringGridProviderUsesCurrentNameAndHelpText;
var
  lForm: TForm;
  lGrid: TStringGrid;
  lGridFragment: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lGrid := TStringGrid.Create(lForm);
    lGrid.Name := 'InitialGrid';
    lGrid.Parent := lForm;
    lGrid.Hint := 'Initial grid help';
    lForm.HandleNeeded;
    lGrid.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lGridFragment := FirstChildFragment(lProvider);
    Assert.AreEqual('Initial grid help', ProviderStringProperty(lGridFragment, UIA_NamePropertyId));
    Assert.AreEqual('Initial grid help', ProviderStringProperty(lGridFragment, UIA_HelpTextPropertyId));

    lGrid.Name := 'UpdatedGrid';
    lGrid.Hint := 'Updated grid help';

    Assert.AreEqual('Updated grid help', ProviderStringProperty(lGridFragment, UIA_NamePropertyId));
    Assert.AreEqual('Updated grid help', ProviderStringProperty(lGridFragment, UIA_HelpTextPropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.FormProviderUsesCurrentHelpText;
var
  lForm: TForm;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Caption := 'Runtime form';
    lForm.Hint := 'Initial form help';
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.AreEqual('Initial form help',
      ProviderStringProperty(lProvider.FragmentProvider, UIA_HelpTextPropertyId));

    lForm.Hint := 'Updated form help';

    Assert.AreEqual('Updated form help',
      ProviderStringProperty(lProvider.FragmentProvider, UIA_HelpTextPropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.FormProviderUsesCurrentName;
var
  lForm: TForm;
  lProvider: IAccessibilityProviderNode;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Caption := 'Initial window title';
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.AreEqual('Initial window title',
      ProviderStringProperty(lProvider.FragmentProvider, UIA_NamePropertyId));

    lForm.Caption := 'Updated window title';

    Assert.AreEqual('Updated window title',
      ProviderStringProperty(lProvider.FragmentProvider, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.TabSheetProviderBoundsMatchPageControlTabHeader;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lHeaderPoint: TPoint;
  lInactiveHit: IRawElementProviderFragment;
  lPageControl: TPageControl;
  lInactivePoint: TPoint;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lTabBounds: UiaRect;
  lTabOrders: TTabSheet;
  lTabTms: TTabSheet;
  lTabRect: TRect;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lTabRect := lPageControl.TabRect(lTabOrders.TabIndex);
    lPoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Orders', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.AreEqual(S_OK, lHit.Get_BoundingRectangle(lTabBounds));
    lHeaderPoint := lPageControl.ClientToScreen(lTabRect.TopLeft);
    Assert.AreEqual(lHeaderPoint.X, Integer(Round(lTabBounds.Left)));
    Assert.AreEqual(lHeaderPoint.Y, Integer(Round(lTabBounds.Top)));
    Assert.AreEqual(lTabRect.Width, Integer(Round(lTabBounds.Width)));
    Assert.AreEqual(lTabRect.Height, Integer(Round(lTabBounds.Height)));

    lTabRect := lPageControl.TabRect(lTabTms.TabIndex);
    lInactivePoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lInactivePoint.X, lInactivePoint.Y, lInactiveHit));
    Assert.IsNotNull(lInactiveHit);
    Assert.AreEqual('TMS grid', ProviderStringProperty(lInactiveHit, UIA_NamePropertyId));
    Assert.IsFalse(ProviderBoolProperty(lInactiveHit, UIA_IsOffscreenPropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ActiveTabSheetDoesNotMaskSiblingTabHeaderHitTesting;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lTabDetails: TTabSheet;
  lTabOrders: TTabSheet;
  lTabRect: TRect;
  lTabTms: TTabSheet;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lTabDetails := TTabSheet.Create(lForm);
    lTabDetails.Caption := 'Details';
    lTabDetails.PageControl := lPageControl;

    lPageControl.ActivePage := lTabTms;
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lTabRect := lPageControl.TabRect(lTabOrders.TabIndex);
    lPoint := lPageControl.ClientToScreen(lTabRect.CenterPoint);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Orders', ProviderStringProperty(lHit, UIA_NamePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.ActiveTabSheetBodyHitTestingReturnsNestedLabel;
var
  lForm: TForm;
  lGrid: TStringGrid;
  lHeaderPanel: TPanel;
  lHit: IRawElementProviderFragment;
  lLabel: TLabel;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lTabOrders: TTabSheet;
  lTabTms: TTabSheet;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 460, 320);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Name := 'PageControl';
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 400, 250);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'TStringGrid rows';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lHeaderPanel := TPanel.Create(lForm);
    lHeaderPanel.Parent := lTabOrders;
    lHeaderPanel.SetBounds(16, 16, 340, 42);
    lHeaderPanel.Caption := '';
    lHeaderPanel.BevelOuter := bvNone;

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'TStringGrid row-select keyboard demo';
    lLabel.Parent := lHeaderPanel;
    lLabel.SetBounds(8, 8, 260, 24);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lTabOrders;
    lGrid.SetBounds(24, 70, 300, 130);
    lGrid.ColCount := 2;
    lGrid.RowCount := 2;
    lGrid.Cells[1, 1] := 'Contoso';

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lHeaderPanel.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lLabel);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('TStringGrid row-select keyboard demo', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.AreEqual(UIA_TextControlTypeId, ProviderIntProperty(lHit, UIA_ControlTypePropertyId));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.TextEditValueFallsBackToTextHintWhenEmpty;
var
  lEdit: TEdit;
  lEditFragment: IRawElementProviderFragment;
  lForm: TForm;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 120);

    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.TextHint := 'customer, order, or finding';
    lEdit.SetBounds(112, 14, 160, 23);

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lEdit);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lEditFragment));
    Assert.IsNotNull(lEditFragment);
    Assert.AreEqual('customer, order, or finding', ValuePatternText(lEditFragment));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.CustomWindowedProvidersPublishNativeWindowHandleButLayoutContainersDoNot;
var
  lEdit: TEdit;
  lEditFragment: IRawElementProviderFragment;
  lForm: TForm;
  lListBox: TListBox;
  lListBoxFragment: IRawElementProviderFragment;
  lPanel: TPanel;
  lPanelFragment: IRawElementProviderFragment;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 220);

    lEdit := TEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.TextHint := 'search text';
    lEdit.SetBounds(112, 14, 160, 23);

    lListBox := TListBox.Create(lForm);
    lListBox.Parent := lForm;
    lListBox.Name := 'Events';
    lListBox.Items.Add('Queued order');
    lListBox.SetBounds(112, 48, 160, 80);

    lPanel := TPanel.Create(lForm);
    lPanel.Parent := lForm;
    lPanel.Caption := 'Layout panel';
    lPanel.SetBounds(112, 144, 160, 40);

    lForm.HandleNeeded;
    lEdit.HandleNeeded;
    lListBox.HandleNeeded;
    lPanel.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);

    lPoint := ControlScreenCenter(lEdit);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lEditFragment));
    Assert.IsNotNull(lEditFragment);
    Assert.AreEqual(Integer(lEdit.Handle), Integer(ProviderNativeWindowHandle(lEditFragment)));
    Assert.AreEqual(0, Integer(ProviderPublishedNativeWindowHandle(lEditFragment)));
    Assert.AreEqual(Integer(ProviderOptions_ServerSideProvider), Integer(ProviderOptionsFor(lEditFragment)));

    lListBoxFragment := FindDescendantByName(lProvider.FragmentProvider, 'Events');
    Assert.IsNotNull(lListBoxFragment);
    Assert.AreEqual(Integer(lListBox.Handle), Integer(ProviderNativeWindowHandle(lListBoxFragment)));
    Assert.AreEqual(0, Integer(ProviderPublishedNativeWindowHandle(lListBoxFragment)));
    Assert.AreEqual(Integer(ProviderOptions_ServerSideProvider), Integer(ProviderOptionsFor(lListBoxFragment)));

    lPanelFragment := FindDescendantByName(lProvider.FragmentProvider, 'Layout panel');
    Assert.IsNotNull(lPanelFragment);
    Assert.AreEqual(Integer(lPanel.Handle), Integer(ProviderNativeWindowHandle(lPanelFragment)));
    Assert.AreEqual(0, Integer(ProviderPublishedNativeWindowHandle(lPanelFragment)));
    Assert.AreEqual(Integer(ProviderOptions_ServerSideProvider), Integer(ProviderOptionsFor(lPanelFragment)));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.WindowedButtonAndCheckBoxProvidersExposeCaptionHintAndState;
var
  lButton: TButton;
  lButtonFragment: IRawElementProviderFragment;
  lCheckBox: TCheckBox;
  lCheckBoxFragment: IRawElementProviderFragment;
  lForm: TForm;
  lInvoke: IInvokeProvider;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRecorder: TClickRecorder;
  lToggle: IToggleProvider;
  lToggleState: ToggleState;
begin
  lForm := TForm.Create(nil);
  lRecorder := TClickRecorder.Create;
  try
    lButton := TButton.Create(lForm);
    lButton.Caption := '&Apply Filters';
    lButton.Hint := 'Apply the selected filters';
    lButton.OnClick := lRecorder.Click;
    lButton.Parent := lForm;
    lButton.HandleNeeded;

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Hint := 'Toggle archived rows in the demo grids';
    lCheckBox.Checked := True;
    lCheckBox.Parent := lForm;
    lCheckBox.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lButtonFragment := FirstChildFragment(lProvider);
    lCheckBoxFragment := NextSiblingFragment(lButtonFragment);

    Assert.AreEqual('Apply Filters', ProviderStringProperty(lButtonFragment, UIA_NamePropertyId));
    Assert.AreEqual('Apply the selected filters', ProviderStringProperty(lButtonFragment, UIA_HelpTextPropertyId));
    Assert.AreEqual(UIA_ButtonControlTypeId, ProviderIntProperty(lButtonFragment, UIA_ControlTypePropertyId));
    Assert.AreEqual(Integer(lButton.Handle), Integer(ProviderNativeWindowHandle(lButtonFragment)));

    lPattern := ProviderPattern(lButtonFragment, UIA_InvokePatternId);
    Assert.IsTrue(Supports(lPattern, IInvokeProvider, lInvoke));
    Assert.AreEqual(S_OK, lInvoke.Invoke);
    Assert.AreEqual(1, lRecorder.Clicks);

    Assert.AreEqual('Include archived rows', ProviderStringProperty(lCheckBoxFragment, UIA_NamePropertyId));
    Assert.AreEqual('Toggle archived rows in the demo grids', ProviderStringProperty(lCheckBoxFragment,
      UIA_HelpTextPropertyId));
    Assert.AreEqual(UIA_CheckBoxControlTypeId, ProviderIntProperty(lCheckBoxFragment, UIA_ControlTypePropertyId));
    Assert.AreEqual(Integer(lCheckBox.Handle), Integer(ProviderNativeWindowHandle(lCheckBoxFragment)));
    Assert.IsNull(ProviderPattern(lCheckBoxFragment, UIA_InvokePatternId));

    lPattern := ProviderPattern(lCheckBoxFragment, UIA_TogglePatternId);
    Assert.IsTrue(Supports(lPattern, IToggleProvider, lToggle));
    Assert.AreEqual(S_OK, lToggle.Get_ToggleState(lToggleState));
    Assert.AreEqual(ToggleState_On, lToggleState);
    Assert.AreEqual(S_OK, lToggle.Toggle);
    Assert.IsFalse(lCheckBox.Checked);
    Assert.AreEqual(S_OK, lToggle.Get_ToggleState(lToggleState));
    Assert.AreEqual(ToggleState_Off, lToggleState);
  finally
    lRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.RadioButtonProviderUsesSelectionItemPattern;
var
  lFirstRadio: TRadioButton;
  lFirstRadioFragment: IRawElementProviderFragment;
  lForm: TForm;
  lIsSelected: BOOL;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lSecondRadio: TRadioButton;
  lSecondRadioFragment: IRawElementProviderFragment;
  lSelectionItem: ISelectionItemProvider;
begin
  lForm := TForm.Create(nil);
  try
    lFirstRadio := TRadioButton.Create(lForm);
    lFirstRadio.Caption := '&Compact';
    lFirstRadio.Hint := 'Use compact layout';
    lFirstRadio.Checked := True;
    lFirstRadio.Parent := lForm;
    lFirstRadio.HandleNeeded;

    lSecondRadio := TRadioButton.Create(lForm);
    lSecondRadio.Caption := '&Detailed';
    lSecondRadio.Hint := 'Use detailed layout';
    lSecondRadio.Parent := lForm;
    lSecondRadio.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lFirstRadioFragment := FirstChildFragment(lProvider);
    lSecondRadioFragment := NextSiblingFragment(lFirstRadioFragment);

    Assert.AreEqual('Compact', ProviderStringProperty(lFirstRadioFragment, UIA_NamePropertyId));
    Assert.AreEqual('Use compact layout', ProviderStringProperty(lFirstRadioFragment, UIA_HelpTextPropertyId));
    Assert.AreEqual(UIA_RadioButtonControlTypeId, ProviderIntProperty(lFirstRadioFragment, UIA_ControlTypePropertyId));
    Assert.AreEqual(Integer(lFirstRadio.Handle), Integer(ProviderNativeWindowHandle(lFirstRadioFragment)));
    Assert.IsNull(ProviderPattern(lFirstRadioFragment, UIA_TogglePatternId));

    lPattern := ProviderPattern(lFirstRadioFragment, UIA_SelectionItemPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
    Assert.AreEqual(S_OK, lSelectionItem.Get_IsSelected(lIsSelected));
    Assert.IsTrue(lIsSelected);

    lPattern := ProviderPattern(lSecondRadioFragment, UIA_SelectionItemPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
    Assert.AreEqual(S_OK, lSelectionItem.Get_IsSelected(lIsSelected));
    Assert.IsFalse(lIsSelected);
    Assert.AreEqual(S_OK, lSelectionItem.Select);
    Assert.IsFalse(lFirstRadio.Checked);
    Assert.IsTrue(lSecondRadio.Checked);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.VclSelectionContainersUseParentWithoutNavigation;
var
  lContainer: IRawElementProviderSimple;
  lContainerFragment: IRawElementProviderFragment; //PALOFF WARN46 output argument verifies fragment lookup
  lForm: TForm;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPageControl: TPageControl;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRadio: TRadioButton;
  lRadioFragment: IRawElementProviderFragment;
  lSelectionItem: ISelectionItemProvider;
  lTabFragment: IRawElementProviderFragment;
  lTabSheet: TTabSheet;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Caption := 'Settings';

    lRadio := TRadioButton.Create(lForm);
    lRadio.Parent := lForm;
    lRadio.Caption := 'Compact';
    lRadio.Checked := True;
    lRadio.HandleNeeded;

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 36, 300, 160);

    lTabSheet := TTabSheet.Create(lForm);
    lTabSheet.Caption := 'Orders';
    lTabSheet.PageControl := lPageControl;
    lPageControl.ActivePage := lTabSheet;
    lForm.HandleNeeded;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRadioFragment := FindDescendantByName(lProvider.FragmentProvider, 'Compact');
    lTabFragment := FindDescendantByName(lProvider.FragmentProvider, 'Orders');
    Assert.IsNotNull(lRadioFragment);
    Assert.IsNotNull(lTabFragment);

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      lPattern := ProviderPattern(lRadioFragment, UIA_SelectionItemPatternId);
      Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
      Assert.AreEqual(S_OK, lSelectionItem.Get_SelectionContainer(lContainer));
      Assert.IsTrue(Supports(lContainer, IRawElementProviderFragment, lContainerFragment));
      Assert.AreEqual('Settings', ProviderStringProperty(lContainerFragment, UIA_NamePropertyId));

      lPattern := ProviderPattern(lTabFragment, UIA_SelectionItemPatternId);
      Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
      Assert.AreEqual(S_OK, lSelectionItem.Get_SelectionContainer(lContainer));
      Assert.IsTrue(Supports(lContainer, IRawElementProviderFragment, lContainerFragment));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
        'Selection item container queries should use the in-process parent pointer, not public UIA Navigate.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.DemoStandardControlsExposeIntentionalRoles;
var
  lButton: TButton;
  lCheckBox: TCheckBox;
  lComboBox: TComboBox;
  lEdit: TEdit;
  lForm: TForm;
  lGroupBox: TGroupBox;
  lInvoke: IInvokeProvider;
  lLabel: TLabel;
  lListBox: TListBox;
  lMemo: TMemo;
  lPageControl: TPageControl;
  lPanel: TPanel;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRadioGroup: TRadioGroup;
  lRadioOne: TRadioButton;
  lRadioTwo: TRadioButton;
  lRecorder: TClickRecorder;
  lSpeedButton: TSpeedButton;
  lStatusBar: TStatusBar;
  lStringGrid: TStringGrid;
  lTabSheet: TTabSheet;
  lToolBar: TToolBar;
  lToolButton: TToolButton;
  lToolButtonFragment: IRawElementProviderFragment;
  lRadioGroupItemFragment: IRawElementProviderFragment;
  lSelectionItem: ISelectionItemProvider;
begin
  lForm := TForm.Create(nil);
  lRecorder := TClickRecorder.Create;
  try
    lForm.SetBounds(100, 100, 700, 560);

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Command title';
    lLabel.Parent := lForm;

    lButton := TButton.Create(lForm);
    lButton.Caption := 'Apply Filters';
    lButton.Parent := lForm;

    lSpeedButton := TSpeedButton.Create(lForm);
    lSpeedButton.Caption := 'Refresh';
    lSpeedButton.Parent := lForm;

    lCheckBox := TCheckBox.Create(lForm);
    lCheckBox.Caption := 'Include archived rows';
    lCheckBox.Parent := lForm;

    lComboBox := TComboBox.Create(lForm);
    lComboBox.Parent := lForm;
    lComboBox.Items.Add('All queues');
    lComboBox.ItemIndex := 0;

    lEdit := TEdit.Create(lForm);
    lEdit.Text := 'Search text';
    lEdit.Parent := lForm;

    lMemo := TMemo.Create(lForm);
    lMemo.Name := 'DetailsMemo';
    lMemo.Parent := lForm;

    lListBox := TListBox.Create(lForm);
    lListBox.Name := 'EventList';
    lListBox.Parent := lForm;
    lListBox.Items.Add('Audit event');

    lPanel := TPanel.Create(lForm);
    lPanel.Caption := 'Inspector';
    lPanel.Parent := lForm;

    lGroupBox := TGroupBox.Create(lForm);
    lGroupBox.Caption := 'View mode';
    lGroupBox.Parent := lForm;

    lRadioOne := TRadioButton.Create(lForm);
    lRadioOne.Caption := 'Compact';
    lRadioOne.Parent := lGroupBox;

    lRadioTwo := TRadioButton.Create(lForm);
    lRadioTwo.Caption := 'Detailed';
    lRadioTwo.Parent := lGroupBox;

    lRadioGroup := TRadioGroup.Create(lForm);
    lRadioGroup.Caption := 'Density';
    lRadioGroup.Parent := lForm;
    lRadioGroup.Items.Add('Comfortable');
    lRadioGroup.Items.Add('Compact density');
    lRadioGroup.ItemIndex := 0;

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Name := 'DemoTabs';
    lPageControl.Parent := lForm;
    lTabSheet := TTabSheet.Create(lForm);
    lTabSheet.Caption := 'Orders';
    lTabSheet.PageControl := lPageControl;

    lToolBar := TToolBar.Create(lForm);
    lToolBar.Caption := 'Command toolbar';
    lToolBar.Parent := lForm;
    lToolButton := TToolButton.Create(lForm);
    lToolButton.Caption := 'Open record';
    lToolButton.OnClick := lRecorder.Click;
    lToolButton.Parent := lToolBar;

    lStatusBar := TStatusBar.Create(lForm);
    lStatusBar.Parent := lForm;
    lStatusBar.SimplePanel := True;
    lStatusBar.SimpleText := 'Ready';

    lStringGrid := TStringGrid.Create(lForm);
    lStringGrid.Name := 'OrdersGrid';
    lStringGrid.Parent := lForm;
    lStringGrid.ColCount := 1;
    lStringGrid.RowCount := 2;
    lStringGrid.Cells[0, 0] := 'Order';
    lStringGrid.Cells[0, 1] := '#24018';

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);

    AssertNamedControlType(lProvider.FragmentProvider, 'Command title', UIA_TextControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Apply Filters', UIA_ButtonControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Refresh', UIA_ButtonControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Include archived rows', UIA_CheckBoxControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'All queues', UIA_ComboBoxControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Search text', UIA_EditControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'DetailsMemo', UIA_EditControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'EventList', UIA_ListControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Inspector', UIA_PaneControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'View mode', UIA_GroupControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Compact', UIA_RadioButtonControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Detailed', UIA_RadioButtonControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Density', UIA_GroupControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Comfortable', UIA_RadioButtonControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Compact density', UIA_RadioButtonControlTypeId);
    lRadioGroupItemFragment := FindDescendantByName(lProvider.FragmentProvider, 'Comfortable');
    lPattern := ProviderPattern(lRadioGroupItemFragment, UIA_SelectionItemPatternId);
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
    AssertNamedControlType(lProvider.FragmentProvider, 'DemoTabs', UIA_TabControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Orders', UIA_TabItemControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Command toolbar', UIA_ToolBarControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'Open record', UIA_ButtonControlTypeId);
    lToolButtonFragment := FindDescendantByName(lProvider.FragmentProvider, 'Open record');
    lPattern := ProviderPattern(lToolButtonFragment, UIA_InvokePatternId);
    Assert.IsTrue(Supports(lPattern, IInvokeProvider, lInvoke), 'Open record should support InvokePattern.');
    Assert.AreEqual(S_OK, lInvoke.Invoke);
    Assert.AreEqual(1, lRecorder.Clicks);
    AssertNamedControlType(lProvider.FragmentProvider, 'Ready', UIA_StatusBarControlTypeId);
    AssertNamedControlType(lProvider.FragmentProvider, 'OrdersGrid', UIA_DataGridControlTypeId);
  finally
    lRecorder.Free;
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.DemoRadioGroupItemHitTestingReturnsItemProvider;
var
  lButton: TRadioButton;
  lForm: TAccessibilityDemoMainForm;
  lHit: IRawElementProviderFragment;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lScreenPoint: TPoint;
begin
  lForm := TAccessibilityDemoMainForm.Create(nil);
  try
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lButton := lForm.radioGroupDensity.Buttons[0];

    Assert.IsTrue(Supports(lProvider.FragmentProvider, IRawElementProviderFragmentRoot, lRoot));
    lScreenPoint := lButton.ClientToScreen(Point(lButton.Width div 2, lButton.Height div 2));
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lScreenPoint.X, lScreenPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Comfortable', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.AreEqual(UIA_RadioButtonControlTypeId, ProviderIntProperty(lHit, UIA_ControlTypePropertyId));
    Assert.AreEqual(Integer(lButton.Handle), Integer(ProviderNativeWindowHandle(lHit)));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.RootProviderLookupFindsControlsWithoutNavigation;
const
  cControlCount = 700;
var
  i: Integer;
  lForm: TForm;
  lFragment: IRawElementProviderFragment;
  lLabel: TLabel;
  lLookup: IAccessibilityVclProviderLookup;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lProvider: IAccessibilityProviderNode;
  lSimple: IRawElementProviderSimple;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 900, 900);

    for i := 1 to cControlCount do
    begin
      lLabel := TLabel.Create(lForm);
      lLabel.Caption := Format('Lookup node %d', [i]);
      lLabel.Parent := lForm;
      lLabel.SetBounds(8 + ((i - 1) mod 20) * 40, 8 + ((i - 1) div 20) * 22, 36, 18);
    end;

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    Assert.IsTrue(Supports(lProvider.RawElementProvider, IAccessibilityVclProviderLookup, lLookup),
      'VCL root should expose a native control-to-provider lookup.');

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      Assert.IsTrue(lLookup.TryFindProviderForControl(lLabel, lSimple));
      Assert.IsTrue(Supports(lSimple, IRawElementProviderFragment, lFragment));
      Assert.AreEqual(Format('Lookup node %d', [cControlCount]),
        ProviderStringProperty(lFragment, UIA_NamePropertyId));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
        'Native provider lookup should not walk the UIA fragment tree.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.RootHitTestingUsesDirectControlBeforeUnrelatedHitTestRoots;
var
  lButton: TButton;
  lForm: TForm;
  lGrid: TStringGrid;
  lHit: IRawElementProviderFragment;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lGrid := TStringGrid.Create(lForm);
    lGrid.Parent := lForm;
    lGrid.ColCount := 3;
    lGrid.RowCount := 3;
    lGrid.Cells[1, 1] := 'Grid item';
    lGrid.SetBounds(16, 16, 180, 80);
    lGrid.HandleNeeded;

    lButton := TButton.Create(lForm);
    lButton.Parent := lForm;
    lButton.Caption := 'Run';
    lButton.SetBounds(230, 24, 90, 32);
    lButton.HandleNeeded;

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lButton);

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
      Assert.AreEqual('Run', ProviderStringProperty(lHit, UIA_NamePropertyId));

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(1, lMetrics.ProviderRootElementProviderFromPointCount,
        'Root hit testing over a direct VCL control should not probe unrelated child fragment roots.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.RootFallbackHitTestingAvoidsProviderNavigation;
var
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPageControl: TPageControl;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lTabOrders: TTabSheet;
  lTabTms: TTabSheet;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 420, 260);

    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.SetBounds(12, 12, 360, 200);

    lTabOrders := TTabSheet.Create(lForm);
    lTabOrders.Caption := 'Orders';
    lTabOrders.PageControl := lPageControl;

    lTabTms := TTabSheet.Create(lForm);
    lTabTms.Caption := 'TMS grid';
    lTabTms.PageControl := lPageControl;

    lPageControl.ActivePage := lTabOrders;
    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := lTabOrders.ClientToScreen(Point(40, 90));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
      Assert.IsNotNull(lHit);

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
        'Fallback root hit testing should use direct in-process child access, not UIA Navigate.');
      Assert.AreEqual(0, lMetrics.ProviderGetBoundingRectangleCount,
        'Fallback root hit testing should use direct VCL geometry, not provider bounding rectangle callbacks.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.RootHitTestingAvoidsRepeatedProviderTreeWalks;
const
  cControlCount = 700;
  cIterations = 100;
var
  i: Integer;
  lForm: TForm;
  lHit: IRawElementProviderFragment;
  lLabel: TLabel;
  lMetrics: TAccessibilityProviderHotspotMetrics;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
begin
  lForm := TForm.Create(nil);
  try
    lForm.SetBounds(100, 100, 900, 900);

    for i := 1 to cControlCount do
    begin
      lLabel := TLabel.Create(lForm);
      lLabel.Caption := Format('Hit node %d', [i]);
      lLabel.Parent := lForm;
      lLabel.SetBounds(8 + ((i - 1) mod 20) * 40, 8 + ((i - 1) div 20) * 22, 36, 18);
    end;

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lLabel);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.AreEqual(Format('Hit node %d', [cControlCount]), ProviderStringProperty(lHit, UIA_NamePropertyId));

    TAccessibilityDiagnostics.EnableProviderHotspotMetrics;
    TAccessibilityDiagnostics.ResetProviderHotspotMetrics;
    try
      for i := 1 to cIterations do
      begin
        lHit := nil;
        Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
        Assert.IsNotNull(lHit);
      end;

      lMetrics := TAccessibilityDiagnostics.ProviderHotspotMetrics;
      Assert.AreEqual(cIterations, lMetrics.ProviderRootElementProviderFromPointCount);
      Assert.AreEqual(0, lMetrics.ProviderNavigateCount,
        'Root hit testing should avoid repeated full provider-tree walks for direct VCL controls.');
    finally
      TAccessibilityDiagnostics.DisableProviderHotspotMetrics;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityVclAdaptersTests.SpeedButtonProviderSupportsInvokeAndOptionalToggle;
var
  lForm: TForm;
  lInvoke: IInvokeProvider;
  lInvokeFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRecorder: TClickRecorder;
  lRunButton: TSpeedButton;
  lToggle: IToggleProvider;
  lToggleButton: TSpeedButton;
  lToggleFragment: IRawElementProviderFragment;
  lToggleState: ToggleState;
begin
  lForm := TForm.Create(nil);
  lRecorder := TClickRecorder.Create;
  try
    lRunButton := TSpeedButton.Create(lForm);
    lRunButton.Caption := '&Run';
    lRunButton.OnClick := lRecorder.Click;
    lRunButton.Parent := lForm;

    lToggleButton := TSpeedButton.Create(lForm);
    lToggleButton.Caption := '&Pinned';
    lToggleButton.GroupIndex := 1;
    lToggleButton.AllowAllUp := True;
    lToggleButton.Down := False;
    lToggleButton.OnClick := lRecorder.Click;
    lToggleButton.Parent := lForm;

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lInvokeFragment := FirstChildFragment(lProvider);
    lToggleFragment := NextSiblingFragment(lInvokeFragment);

    lPattern := ProviderPattern(lInvokeFragment, UIA_InvokePatternId);
    Assert.IsTrue(Supports(lPattern, IInvokeProvider, lInvoke));
    Assert.AreEqual(S_OK, lInvoke.Invoke);
    Assert.AreEqual(1, lRecorder.Clicks);
    Assert.IsNull(ProviderPattern(lInvokeFragment, UIA_TogglePatternId));

    lPattern := ProviderPattern(lToggleFragment, UIA_InvokePatternId);
    Assert.IsTrue(Supports(lPattern, IInvokeProvider, lInvoke));
    Assert.AreEqual(S_OK, lInvoke.Invoke);
    Assert.AreEqual(2, lRecorder.Clicks);

    lPattern := ProviderPattern(lToggleFragment, UIA_TogglePatternId);
    Assert.IsTrue(Supports(lPattern, IToggleProvider, lToggle));
    Assert.AreEqual(S_OK, lToggle.Get_ToggleState(lToggleState));
    Assert.AreEqual(ToggleState_Off, lToggleState);
    Assert.AreEqual(S_OK, lToggle.Toggle);
    Assert.IsTrue(lToggleButton.Down);
    Assert.AreEqual(3, lRecorder.Clicks);
    Assert.AreEqual(S_OK, lToggle.Get_ToggleState(lToggleState));
    Assert.AreEqual(ToggleState_On, lToggleState);
  finally
    lRecorder.Free;
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityVclAdaptersTests);

end.
