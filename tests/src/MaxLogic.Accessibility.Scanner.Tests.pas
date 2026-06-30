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
    procedure RuntimeControlChangesCoalesceUntilObservedTreeIsRead;
    [Test]
    procedure DestroyedWinControlIsUnhookedBeforeObserverRelease;
    [Test]
    procedure LaterWindowProcHookCanCallPriorAfterObserverRelease;
    [Test]
    procedure ScanTreeFindNodeUsesIndexedLookupForRepeatedQueries;
    [Test]
    procedure ScanFormSortsLargeReorderedControlTreesWithoutQuadraticCost;
    [Test]
    procedure ScannerWalksVclTreeInStableOrder;
    [Test]
    procedure TextExtractionUsesFallbackPriorityAndSuppressesIconGlyphs;
    [Test]
    procedure TextExtractionUsesLabeledEditCaptionBeforeEditText;
  end;

implementation

uses
  System.Actions, System.Diagnostics, System.SysUtils, Winapi.Messages, Vcl.ActnList, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.StdCtrls, MaxLogic.Accessibility.Scanner;

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

function MeasureFindNodeTicks(const aTree: IAccessibilityScanTree; aControl: TControl; aIterations: Integer): Int64;
var
  i: Integer;
  lNode: IAccessibilityScanNode;
  lStopwatch: TStopwatch;
begin
  lStopwatch := TStopwatch.StartNew;
  for i := 1 to aIterations do
  begin
    lNode := aTree.FindNode(aControl);
    if lNode = nil then
    begin
      raise EAssertionFailed.Create('FindNode returned nil during measurement.');
    end;
  end;
  lStopwatch.Stop;
  Result := lStopwatch.ElapsedTicks;
end;

function BuildReorderedLabelForm(aControlCount: Integer): TForm;
var
  i: Integer;
  lLabel: TLabel;
begin
  Result := TForm.Create(nil);
  for i := 1 to aControlCount do
  begin
    lLabel := TLabel.Create(Result);
    lLabel.Caption := Format('Sorted node %d', [i]);
    lLabel.Parent := Result;
    lLabel.SendToBack;
  end;
end;

function MeasureScanFormTicks(aControlCount: Integer): Int64;
var
  lForm: TForm;
  lStopwatch: TStopwatch;
  lTree: IAccessibilityScanTree;
begin
  lForm := BuildReorderedLabelForm(aControlCount);
  try
    lStopwatch := TStopwatch.StartNew;
    lTree := TAccessibilityScanner.ScanForm(lForm);
    lStopwatch.Stop;

    if Length(lTree.FlattenedNodes) <> aControlCount then
    begin
      raise EAssertionFailed.Create('ScanForm returned an unexpected node count during measurement.');
    end;

    Result := lStopwatch.ElapsedTicks;
  finally
    lForm.Free;
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

procedure TAccessibilityScannerTests.RuntimeControlChangesCoalesceUntilObservedTreeIsRead;
const
  cControlCount = 25;
var
  i: Integer;
  lForm: TForm;
  lLabel: TLabel;
  lLastLabel: TLabel;
  lScan: IAccessibilityObservedFormScan;
begin
  lForm := TForm.Create(nil);
  try
    lScan := TAccessibilityScanner.ObserveForm(lForm);
    Assert.AreEqual(1, lScan.Revision);

    for i := 1 to cControlCount do
    begin
      lLabel := TLabel.Create(lForm);
      lLabel.Caption := Format('Added %d', [i]);
      lLabel.Parent := lForm;
      lLastLabel := lLabel;
    end;

    Assert.AreEqual(2, lScan.Revision);
    Assert.AreEqual(Format('Added %d', [cControlCount]), lScan.Tree.FindNode(lLastLabel).Name);
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

procedure TAccessibilityScannerTests.ScanTreeFindNodeUsesIndexedLookupForRepeatedQueries;
const
  cControlCount = 800;
  cIterations = 2000;
  cMaxTickRatio = 8;
var
  i: Integer;
  lFirstLabel: TLabel;
  lFirstTicks: Int64;
  lForm: TForm;
  lLabel: TLabel;
  lLastLabel: TLabel;
  lLastTicks: Int64;
  lTree: IAccessibilityScanTree;
begin
  lForm := TForm.Create(nil);
  try
    lFirstLabel := nil;

    for i := 1 to cControlCount do
    begin
      lLabel := TLabel.Create(lForm);
      lLabel.Caption := Format('Node %d', [i]);
      lLabel.Parent := lForm;

      if lFirstLabel = nil then
      begin
        lFirstLabel := lLabel;
      end;
      lLastLabel := lLabel;
    end;

    lTree := TAccessibilityScanner.ScanForm(lForm);

    Assert.AreEqual('Node 1', lTree.FindNode(lFirstLabel).Name);
    Assert.AreEqual(Format('Node %d', [cControlCount]), lTree.FindNode(lLastLabel).Name);

    lFirstTicks := MeasureFindNodeTicks(lTree, lFirstLabel, cIterations);
    lLastTicks := MeasureFindNodeTicks(lTree, lLastLabel, cIterations);

    Assert.IsTrue(lLastTicks <= lFirstTicks * cMaxTickRatio,
      Format('FindNode should use an indexed lookup; first=%d ticks last=%d ticks.', [lFirstTicks, lLastTicks]));
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityScannerTests.ScanFormSortsLargeReorderedControlTreesWithoutQuadraticCost;
const
  cSmallControlCount = 200;
  cLargeControlCount = 800;
  cMaxTickGrowth = 10;
var
  lLargeTicks: Int64;
  lSmallTicks: Int64;
begin
  lSmallTicks := MeasureScanFormTicks(cSmallControlCount);
  lLargeTicks := MeasureScanFormTicks(cLargeControlCount);

  Assert.IsTrue(lLargeTicks <= lSmallTicks * cMaxTickGrowth,
    Format('Reordered ScanForm should avoid quadratic child sorting; %d controls=%d ticks, %d controls=%d ticks.',
    [cSmallControlCount, lSmallTicks, cLargeControlCount, lLargeTicks]));
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

procedure TAccessibilityScannerTests.TextExtractionUsesLabeledEditCaptionBeforeEditText;
var
  lEdit: TLabeledEdit;
  lForm: TForm;
  lText: TAccessibilityTextInfo;
begin
  lForm := TForm.Create(nil);
  try
    lEdit := TLabeledEdit.Create(lForm);
    lEdit.Parent := lForm;
    lEdit.EditLabel.Caption := 'Reference number';
    lEdit.Text := 'REF-1042';
    lEdit.Hint := 'Reference short|Reference long help';

    lText := TAccessibilityTextExtractor.Extract(lEdit);

    Assert.AreEqual('Reference number', lText.Name);
    Assert.AreEqual('Reference long help', lText.HelpText);
  finally
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityScannerTests);

end.
