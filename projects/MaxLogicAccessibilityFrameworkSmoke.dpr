program MaxLogicAccessibilityFrameworkSmoke;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Variants, Winapi.ActiveX, Winapi.Windows, Vcl.Buttons, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.StdCtrls,
  MaxLogic.Accessibility.Framework in '..\src\MaxLogic.Accessibility.Framework.pas',
  MaxLogic.Accessibility.ProviderCore in '..\src\MaxLogic.Accessibility.ProviderCore.pas',
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

procedure TProbeGraphicControl.Paint;
begin
end;

procedure TProbeClickRecorder.Click(aSender: TObject);
begin
  Inc(fClicks);
end;

procedure Require(aCondition: Boolean; const aMessage: string);
begin
  if not aCondition then
  begin
    raise Exception.Create(aMessage);
  end;
end;

function FragmentProvider(const aFragment: IRawElementProviderFragment): IRawElementProviderSimple;
begin
  Result := nil;
  Require(Supports(aFragment, IRawElementProviderSimple, Result), 'Fragment does not expose simple provider.');
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
  lLabel: TLabel;
  lLabelFragment: IRawElementProviderFragment;
  lNestedFragment: IRawElementProviderFragment;
  lNestedLabel: TLabel;
  lPanel: TPanel;
  lPanelFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lProvider: IAccessibilityProviderNode;
  lRecorder: TProbeClickRecorder;
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

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lForm);
    lLabelFragment := FirstChild(lProvider, 'label fragment');
    lRunFragment := NextSibling(lLabelFragment, 'run speed-button fragment');
    lToggleFragment := NextSibling(lRunFragment, 'toggle speed-button fragment');
    lPanelFragment := NextSibling(lToggleFragment, 'panel fragment');
    lGraphicFragment := NextSibling(lPanelFragment, 'graphic-control fragment');
    Require(OptionalNextSibling(lGraphicFragment, 'decorative-control omission check') = nil,
      'Decorative controls were exposed after the graphic-control fragment.');

    RequireProvider(lLabelFragment, UIA_TextControlTypeId, 'Customer', 'Shown next to customer edit', 'label');
    RequireProvider(lRunFragment, UIA_ButtonControlTypeId, 'Run', 'Runs the command', 'run speed-button');
    RequireProvider(lToggleFragment, UIA_ButtonControlTypeId, 'Pinned', 'Pinned state', 'toggle speed-button');
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

    lPattern := PatternProvider(lToggleFragment, UIA_TogglePatternId);
    Require(Supports(lPattern, IToggleProvider, lToggle), 'Toggle speed-button does not expose Toggle.');
    Require(lToggle.Get_ToggleState(lToggleState) = S_OK, 'Toggle state query failed.');
    Require(lToggleState = ToggleState_Off, 'Initial toggle state mismatch.');
    Require(lToggle.Toggle = S_OK, 'Toggle action failed.');
    Require(lToggleButton.Down, 'Toggle action did not update Down state.');
    Require(lToggle.Get_ToggleState(lToggleState) = S_OK, 'Post-toggle state query failed.');
    Require(lToggleState = ToggleState_On, 'Post-toggle state mismatch.');

    Writeln('UIA_PROBE_OK BasicVclControls: label provider=text name/help; speed button provider=button invoke/toggle; panel provider=pane with child; generic graphic-control provider=text; decorative controls omitted.');
  finally
    lRecorder.Free;
    lForm.Free;
  end;
end;

procedure Run;
begin
  if (ParamCount = 2) and SameText(ParamStr(1), '--uia-probe') and SameText(ParamStr(2), 'BasicVclControls') then
  begin
    RunBasicVclControlsProbe;
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
