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
    procedure DisabledSpeedButtonAutomationDoesNotInvokeClickOrToggle;
    [Test]
    procedure ProviderTreeExposesVclControlProperties;
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
    procedure WindowedControlProviderExposesNativeWindowHandle;
    [Test]
    procedure WindowedButtonAndCheckBoxProvidersExposeCaptionHintAndState;
    [Test]
    procedure RadioButtonProviderUsesSelectionItemPattern;
    [Test]
    procedure DemoStandardControlsExposeIntentionalRoles;
    [Test]
    procedure TextInputsExposeAssociatedLabelsAndValues;
    [Test]
    procedure MemoProviderHitTestingReturnsLineUnderPointer;
    [Test]
    procedure ListBoxProviderHitTestingAndFocusReturnItems;
    [Test]
    procedure ListBoxProviderReturnsAllSelectedItemsForMultiSelect;
    [Test]
    procedure ListBoxItemProviderHandlesStaleItemIndex;
    [Test]
    procedure ListBoxProviderStopsReturningFocusItemWhenCachedTextBecomesEmpty;
    [Test]
    procedure StatusBarProviderUsesVisibleStatusText;
    [Test]
    procedure RootHitTestingReturnsDeepestNonWindowedLabel;
    [Test]
    procedure SpeedButtonProviderSupportsInvokeAndOptionalToggle;
  end;

implementation

uses
  System.SysUtils, System.Types, System.Variants, Winapi.ActiveX, Winapi.Messages, Winapi.Windows, Vcl.Buttons,
  Vcl.Controls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, DUnitX.Assert,
  MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner, MaxLogic.Accessibility.UIAutomationCore,
  MaxLogic.Accessibility.VclAdapters;

type
  TCaptionGraphicControl = class(TGraphicControl)
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

procedure TCaptionGraphicControl.Paint;
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

function FirstChildFragment(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragment;
begin
  Assert.AreEqual(S_OK, aProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, Result));
  Assert.IsNotNull(Result);
end;

function FragmentRoot(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragmentRoot;
begin
  Result := nil;
  Assert.IsTrue(Supports(aProvider.RawElementProvider, IRawElementProviderFragmentRoot, Result));
end;

function NextSiblingFragment(const aFragment: IRawElementProviderFragment): IRawElementProviderFragment;
begin
  Assert.AreEqual(S_OK, aFragment.Navigate(NavigateDirection_NextSibling, Result));
  Assert.IsNotNull(Result);
end;

function NextSiblingFragmentOrNil(const aFragment: IRawElementProviderFragment): IRawElementProviderFragment;
begin
  Assert.AreEqual(S_OK, aFragment.Navigate(NavigateDirection_NextSibling, Result));
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
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(UIA_NativeWindowHandlePropertyId, lValue));
  Result := HWND(Integer(lValue));
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

  Assert.AreEqual(S_OK, aFragment.Navigate(NavigateDirection_FirstChild, lChild));
  lCurrent := lChild;
  while lCurrent <> nil do
  begin
    Result := FindDescendantByName(lCurrent, aName);
    if Result <> nil then
    begin
      Exit;
    end;

    lNext := nil;
    Assert.AreEqual(S_OK, lCurrent.Navigate(NavigateDirection_NextSibling, lNext));
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
begin
  Result := Point(Smallint(Word(aValue and $FFFF)), Smallint(Word((aValue shr 16) and $FFFF)));
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

    Assert.IsNotNull(lTree.FindNode(lPanelWithChild));
    Assert.AreEqual('', lTree.FindNode(lPanelWithChild).Name);
    Assert.AreEqual('Nested value', lTree.FindNode(lChildLabel).Name);
    Assert.IsNull(lTree.FindNode(lEmptyPanel));

    Assert.AreEqual('Custom graphic', lTree.FindNode(lGraphic).Name);
    Assert.AreEqual('Graphic help', lTree.FindNode(lGraphic).HelpText);
    Assert.IsNull(lTree.FindNode(lDecorativeGraphic));
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

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
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

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHit));
    Assert.IsNotNull(lHit);
    Assert.AreEqual('Second memo line', ProviderStringProperty(lHit, UIA_NamePropertyId));
    Assert.AreEqual(UIA_TextControlTypeId, ProviderIntProperty(lHit, UIA_ControlTypePropertyId));

    lForm.ActiveControl := lMemo;
    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocus));
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

procedure TAccessibilityVclAdaptersTests.WindowedControlProviderExposesNativeWindowHandle;
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
    lEdit.TextHint := 'search text';
    lEdit.SetBounds(112, 14, 160, 23);

    lForm.HandleNeeded;
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lRoot := FragmentRoot(lProvider);
    lPoint := ControlScreenCenter(lEdit);

    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lEditFragment));
    Assert.IsNotNull(lEditFragment);
    Assert.AreEqual(Integer(lEdit.Handle), Integer(ProviderNativeWindowHandle(lEditFragment)));
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
