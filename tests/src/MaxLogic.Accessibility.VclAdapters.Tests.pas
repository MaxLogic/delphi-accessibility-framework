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
    procedure ProviderTreeExposesVclControlProperties;
    [Test]
    procedure SpeedButtonProviderSupportsInvokeAndOptionalToggle;
  end;

implementation

uses
  System.SysUtils, System.Variants, Winapi.ActiveX, Winapi.Windows, Vcl.Buttons, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.StdCtrls, DUnitX.Assert, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.Scanner,
  MaxLogic.Accessibility.UIAutomationCore, MaxLogic.Accessibility.VclAdapters;

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

procedure TCaptionGraphicControl.Paint;
begin
end;

procedure TClickRecorder.Click(aSender: TObject);
begin
  Inc(fClicks);
end;

function FirstChildFragment(const aProvider: IAccessibilityProviderNode): IRawElementProviderFragment;
begin
  Assert.AreEqual(S_OK, aProvider.FragmentProvider.Navigate(NavigateDirection_FirstChild, Result));
  Assert.IsNotNull(Result);
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

function ProviderPattern(const aFragment: IRawElementProviderFragment; aPatternId: PATTERNID): IUnknown;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPatternProvider(aPatternId, Result));
end;

function ProviderStringProperty(const aFragment: IRawElementProviderFragment; aPropertyId: PROPERTYID): string;
var
  lValue: OleVariant;
begin
  Assert.AreEqual(S_OK, SimpleProvider(aFragment).GetPropertyValue(aPropertyId, lValue));
  Result := string(lValue);
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
