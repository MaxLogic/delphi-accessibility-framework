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
    procedure TextInputsExposeAssociatedLabelsAndValues;
    [Test]
    procedure MemoProviderHitTestingReturnsLineUnderPointer;
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
  System.SysUtils, System.Types, System.Variants, Winapi.ActiveX, Winapi.Messages, Winapi.Windows,
  Vcl.Buttons, Vcl.Controls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, DUnitX.Assert,
  MaxLogic.Accessibility.Diagnostics, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters, AccessibilityDemoMainForm;

type
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
end;

procedure TColdCaptionGraphicControl.Paint;
begin
end;

procedure TClickRecorder.Click(aSender: TObject);
begin
  Inc(fClicks);
end;

procedure TProbeSpeedButton.Click;
begin
  Inc(fClickCalls);
  inherited Click;
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
  lResult := aFragment.Navigate(NavigateDirection_NextSibling, Result);
  Assert.IsTrue(lResult = S_OK, 'Next sibling navigation failed.');
end;

function SimpleProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Assert.IsTrue(Supports(aFragment, IRawElementProviderSimple, Result));
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

function ProviderStringProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := string(lValue);
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
  lSignedValue := Int64(aValue);
  lRawValue := lSignedValue and $00000000FFFFFFFF;
  lX := Integer(lRawValue and $FFFF);
  if lX > High(Smallint) then
  begin
    Dec(lX, $10000);
  end;

  lY := Integer((lRawValue shr 16) and $FFFF);
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
  lContainerFragment: IRawElementProviderFragment;
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
