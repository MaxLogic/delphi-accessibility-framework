unit MaxLogic.Accessibility.Scanner.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Scanner')]
  TAccessibilityScannerTests = class
  public
    [Test]
    procedure AdapterRegistryResolvesNearestRegisteredClass;
    [Test]
    procedure RuntimeControlChangesRefreshObservedTree;
    [Test]
    procedure DestroyedWinControlIsUnhookedBeforeObserverRelease;
    [Test]
    procedure LaterWindowProcHookCanCallPriorAfterObserverRelease;
    [Test]
    procedure ScannerWalksVclTreeInStableOrder;
    [Test]
    procedure TextExtractionUsesFallbackPriorityAndSuppressesIconGlyphs;
  end;

implementation

uses
  System.Actions, System.SysUtils, Winapi.Messages, Vcl.ActnList, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  Vcl.StdCtrls, MaxLogic.Accessibility.Scanner;

type
  TAccessibleLabel = class(TLabel)
  private
    fAccessibleName: string;
  published
    property AccessibleName: string read fAccessibleName write fAccessibleName;
  end;

  TNamedAdapter = class(TInterfacedObject, IAccessibilityControlAdapter)
  private
    fName: string;
  public
    constructor Create(const aName: string);
    function CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo): TAccessibilityControlInfo;
  end;

  TDerivedButton = class(TButton);

  TWindowProcChainProbe = class
  private
    fCalls: Integer;
    fControl: TWinControl;
    fPrior: TWndMethod;
  public
    constructor Create(aControl: TWinControl);
    destructor Destroy; override;
    procedure WindowProc(var aMessage: TMessage);
    property Calls: Integer read fCalls;
  end;

constructor TNamedAdapter.Create(const aName: string);
begin
  inherited Create;
  fName := aName;
end;

function TNamedAdapter.CreateInfo(aControl: TControl; const aFallback: TAccessibilityTextInfo):
  TAccessibilityControlInfo;
begin
  Result := TAccessibilityControlInfo.Include(aControl, fName, aFallback.HelpText);
end;

constructor TWindowProcChainProbe.Create(aControl: TWinControl);
begin
  inherited Create;
  fControl := aControl;
  fPrior := aControl.WindowProc;
  aControl.WindowProc := WindowProc;
end;

destructor TWindowProcChainProbe.Destroy;
begin
  if fControl <> nil then
  begin
    fControl.WindowProc := fPrior;
  end;

  inherited Destroy;
end;

procedure TWindowProcChainProbe.WindowProc(var aMessage: TMessage);
begin
  Inc(fCalls);
  fPrior(aMessage);
end;

function FlattenedNames(const aTree: IAccessibilityScanTree): TArray<string>;
var
  i: Integer;
  lNodes: TArray<IAccessibilityScanNode>;
begin
  lNodes := aTree.FlattenedNodes;
  SetLength(Result, Length(lNodes));
  for i := 0 to High(lNodes) do
  begin
    Result[i] := lNodes[i].Name;
  end;
end;

procedure TAccessibilityScannerTests.AdapterRegistryResolvesNearestRegisteredClass;
var
  lButton: TButton;
  lDerivedButton: TDerivedButton;
  lForm: TForm;
  lRegistry: IAccessibilityAdapterRegistry;
  lTree: IAccessibilityScanTree;
begin
  lForm := TForm.Create(nil);
  try
    lButton := TButton.Create(lForm);
    lButton.Parent := lForm;
    lDerivedButton := TDerivedButton.Create(lForm);
    lDerivedButton.Parent := lForm;

    lRegistry := TAccessibilityAdapterRegistry.Create;
    lRegistry.RegisterAdapter(TControl, TNamedAdapter.Create('control adapter'));
    lRegistry.RegisterAdapter(TButton, TNamedAdapter.Create('button adapter'));

    lTree := TAccessibilityScanner.ScanForm(lForm, lRegistry);

    Assert.AreEqual('button adapter', lTree.FindNode(lButton).Name);
    Assert.AreEqual('button adapter', lTree.FindNode(lDerivedButton).Name);

    lRegistry.RegisterAdapter(TDerivedButton, TNamedAdapter.Create('derived adapter'));
    lTree := TAccessibilityScanner.ScanForm(lForm, lRegistry);

    Assert.AreEqual('derived adapter', lTree.FindNode(lDerivedButton).Name);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityScannerTests.RuntimeControlChangesRefreshObservedTree;
var
  lForm: TForm;
  lLabel: TLabel;
  lScan: IAccessibilityObservedFormScan;
begin
  lForm := TForm.Create(nil);
  try
    lScan := TAccessibilityScanner.ObserveForm(lForm);
    Assert.AreEqual(1, lScan.Revision);

    lLabel := TLabel.Create(lForm);
    lLabel.Caption := 'Added';
    lLabel.Parent := lForm;

    Assert.AreEqual(2, lScan.Revision);
    Assert.IsNotNull(lScan.Tree.FindNode(lLabel));
    Assert.AreEqual('Added', lScan.Tree.FindNode(lLabel).Name);

    lLabel.Parent := nil;

    Assert.AreEqual(3, lScan.Revision);
    Assert.IsNull(lScan.Tree.FindNode(lLabel));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityScannerTests.DestroyedWinControlIsUnhookedBeforeObserverRelease;
var
  lForm: TForm;
  lPanel: TPanel;
  lScan: IAccessibilityObservedFormScan;
begin
  lForm := TForm.Create(nil);
  try
    lScan := TAccessibilityScanner.ObserveForm(lForm);
    lPanel := TPanel.Create(lForm);
    lPanel.Caption := 'Panel';
    lPanel.Parent := lForm;

    Assert.IsNotNull(lScan.Tree.FindNode(lPanel));

    lPanel.Free;

    Assert.IsNull(lScan.Tree.FindNode(lPanel));
    lScan := nil;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityScannerTests.LaterWindowProcHookCanCallPriorAfterObserverRelease;
var
  lForm: TForm;
  lMessage: TMessage;
  lProbe: TWindowProcChainProbe;
  lScan: IAccessibilityObservedFormScan;
begin
  lForm := TForm.Create(nil);
  try
    lScan := TAccessibilityScanner.ObserveForm(lForm);
    lProbe := TWindowProcChainProbe.Create(lForm);
    try
      lScan := nil;
      lMessage := Default(TMessage);
      lMessage.Msg := CM_CONTROLCHANGE;
      lMessage.LParam := 1;

      lForm.WindowProc(lMessage);

      Assert.AreEqual(1, lProbe.Calls);
    finally
      lProbe.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityScannerTests.ScannerWalksVclTreeInStableOrder;
var
  lForm: TForm;
  lGroup: TPanel;
  lNested: TLabel;
  lNames: TArray<string>;
  lOuter: TLabel;
  lSecond: TLabel;
  lTree: IAccessibilityScanTree;
begin
  lForm := TForm.Create(nil);
  try
    lOuter := TLabel.Create(lForm);
    lOuter.Caption := 'Outer';
    lOuter.Parent := lForm;

    lGroup := TPanel.Create(lForm);
    lGroup.Caption := 'Group';
    lGroup.Parent := lForm;

    lNested := TLabel.Create(lForm);
    lNested.Caption := 'Nested';
    lNested.Parent := lGroup;

    lSecond := TLabel.Create(lForm);
    lSecond.Caption := 'Second';
    lSecond.Parent := lForm;

    lTree := TAccessibilityScanner.ScanForm(lForm);
    lNames := FlattenedNames(lTree);

    Assert.AreEqual(4, Length(lNames));
    Assert.AreEqual('Outer', lNames[0]);
    Assert.AreEqual('Group', lNames[1]);
    Assert.AreEqual('Nested', lNames[2]);
    Assert.AreEqual('Second', lNames[3]);
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityScannerTests.TextExtractionUsesFallbackPriorityAndSuppressesIconGlyphs;
var
  lAction: TAction;
  lActionButton: TButton;
  lCaptionLabel: TLabel;
  lEdit: TEdit;
  lExplicitLabel: TAccessibleLabel;
  lForm: TForm;
  lHintLabel: TLabel;
  lIconLabel: TLabel;
  lNameLabel: TLabel;
  lText: TAccessibilityTextInfo;
begin
  lForm := TForm.Create(nil);
  try
    lExplicitLabel := TAccessibleLabel.Create(lForm);
    lExplicitLabel.AccessibleName := 'Explicit name';
    lExplicitLabel.Caption := 'Caption name';
    lExplicitLabel.Hint := 'Explicit help';
    lText := TAccessibilityTextExtractor.Extract(lExplicitLabel);
    Assert.AreEqual('Explicit name', lText.Name);
    Assert.AreEqual('Explicit help', lText.HelpText);

    lAction := TAction.Create(lForm);
    lAction.Caption := 'Action name';
    lAction.Hint := 'Action help';
    lActionButton := TButton.Create(lForm);
    lActionButton.Action := lAction;
    lText := TAccessibilityTextExtractor.Extract(lActionButton);
    Assert.AreEqual('Action name', lText.Name);
    Assert.AreEqual('Action help', lText.HelpText);

    lCaptionLabel := TLabel.Create(lForm);
    lCaptionLabel.Caption := '&Caption name';
    lText := TAccessibilityTextExtractor.Extract(lCaptionLabel);
    Assert.AreEqual('Caption name', lText.Name);

    lEdit := TEdit.Create(lForm);
    lEdit.Text := 'Typed text';
    lText := TAccessibilityTextExtractor.Extract(lEdit);
    Assert.AreEqual('Typed text', lText.Name);

    lHintLabel := TLabel.Create(lForm);
    lHintLabel.Hint := 'Short hint|Long hint';
    lText := TAccessibilityTextExtractor.Extract(lHintLabel);
    Assert.AreEqual('Short hint', lText.Name);
    Assert.AreEqual('Long hint', lText.HelpText);

    lNameLabel := TLabel.Create(lForm);
    lNameLabel.Name := 'FallbackName';
    lText := TAccessibilityTextExtractor.Extract(lNameLabel);
    Assert.AreEqual('FallbackName', lText.Name);

    lIconLabel := TLabel.Create(lForm);
    lIconLabel.Name := 'IconFallbackShouldNotSpeak';
    lIconLabel.Caption := WideChar($E001);
    lText := TAccessibilityTextExtractor.Extract(lIconLabel);
    Assert.IsTrue(lText.IsEmpty);
  finally
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityScannerTests);

end.
