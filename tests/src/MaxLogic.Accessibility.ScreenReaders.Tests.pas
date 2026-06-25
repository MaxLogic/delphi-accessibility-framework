unit MaxLogic.Accessibility.ScreenReaders.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('ScreenReaders')]
  TAccessibilityScreenReaderTests = class
  public
    [Test]
    procedure DetectReturnsInactiveWhenNoSignalsArePresent;
    [Test]
    procedure DetectUsesSystemScreenReaderParameterSignal;
    [Test]
    procedure DetectUsesUiaClientListenerSignal;
    [Test]
    procedure DetectSurvivesSystemParameterFailureWhenUiaClientListens;
    [Test]
    procedure DefaultDetectorUsesWindowsProbeWithoutRaising;
  end;

implementation

uses
  DUnitX.Assert,
  MaxLogic.Accessibility.ScreenReaders;

type
  // The real OS screen-reader state is process-external and nondeterministic, so tests use a fake probe.
  TFakeScreenReaderProbe = class(TInterfacedObject, IAccessibilityScreenReaderProbe)
  private
    fSystemEnabled: Boolean;
    fSystemQuerySucceeded: Boolean;
    fUiaListening: Boolean;
  public
    constructor Create(aSystemQuerySucceeded: Boolean; aSystemEnabled: Boolean; aUiaListening: Boolean);
    function TryGetSystemScreenReaderParameter(out aEnabled: Boolean): Boolean;
    function UiaClientsAreListening: Boolean;
  end;

constructor TFakeScreenReaderProbe.Create(aSystemQuerySucceeded: Boolean; aSystemEnabled: Boolean;
  aUiaListening: Boolean);
begin
  inherited Create;
  fSystemQuerySucceeded := aSystemQuerySucceeded;
  fSystemEnabled := aSystemEnabled;
  fUiaListening := aUiaListening;
end;

function TFakeScreenReaderProbe.TryGetSystemScreenReaderParameter(out aEnabled: Boolean): Boolean;
begin
  aEnabled := fSystemEnabled;
  Result := fSystemQuerySucceeded;
end;

function TFakeScreenReaderProbe.UiaClientsAreListening: Boolean;
begin
  Result := fUiaListening;
end;

procedure TAccessibilityScreenReaderTests.DefaultDetectorUsesWindowsProbeWithoutRaising;
var
  lDetection: TAccessibilityScreenReaderDetection;
begin
  lDetection := TAccessibilityScreenReaderDetector.Detect;

  Assert.IsTrue(lDetection.SystemScreenReaderQuerySucceeded,
    'SystemParametersInfo(SPI_GETSCREENREADER) should be queryable on supported Windows versions.');
end;

procedure TAccessibilityScreenReaderTests.DetectReturnsInactiveWhenNoSignalsArePresent;
var
  lDetection: TAccessibilityScreenReaderDetection;
begin
  lDetection := TAccessibilityScreenReaderDetector.Detect(TFakeScreenReaderProbe.Create(True, False, False));

  Assert.IsFalse(lDetection.LikelyActive);
  Assert.IsTrue(lDetection.Signals = []);
  Assert.IsTrue(lDetection.SystemScreenReaderQuerySucceeded);
  Assert.IsFalse(lDetection.SystemScreenReaderParameter);
  Assert.IsFalse(lDetection.UiaClientsListening);
end;

procedure TAccessibilityScreenReaderTests.DetectSurvivesSystemParameterFailureWhenUiaClientListens;
var
  lDetection: TAccessibilityScreenReaderDetection;
begin
  lDetection := TAccessibilityScreenReaderDetector.Detect(TFakeScreenReaderProbe.Create(False, True, True));

  Assert.IsTrue(lDetection.LikelyActive);
  Assert.IsTrue(srsUiaClientListener in lDetection.Signals);
  Assert.IsFalse(srsSystemScreenReaderParameter in lDetection.Signals);
  Assert.IsFalse(lDetection.SystemScreenReaderQuerySucceeded);
  Assert.IsFalse(lDetection.SystemScreenReaderParameter);
  Assert.IsTrue(lDetection.UiaClientsListening);
end;

procedure TAccessibilityScreenReaderTests.DetectUsesSystemScreenReaderParameterSignal;
var
  lDetection: TAccessibilityScreenReaderDetection;
begin
  lDetection := TAccessibilityScreenReaderDetector.Detect(TFakeScreenReaderProbe.Create(True, True, False));

  Assert.IsTrue(lDetection.LikelyActive);
  Assert.IsTrue(srsSystemScreenReaderParameter in lDetection.Signals);
  Assert.IsFalse(srsUiaClientListener in lDetection.Signals);
  Assert.IsTrue(lDetection.SystemScreenReaderQuerySucceeded);
  Assert.IsTrue(lDetection.SystemScreenReaderParameter);
  Assert.IsFalse(lDetection.UiaClientsListening);
end;

procedure TAccessibilityScreenReaderTests.DetectUsesUiaClientListenerSignal;
var
  lDetection: TAccessibilityScreenReaderDetection;
begin
  lDetection := TAccessibilityScreenReaderDetector.Detect(TFakeScreenReaderProbe.Create(True, False, True));

  Assert.IsTrue(lDetection.LikelyActive);
  Assert.IsFalse(srsSystemScreenReaderParameter in lDetection.Signals);
  Assert.IsTrue(srsUiaClientListener in lDetection.Signals);
  Assert.IsTrue(lDetection.SystemScreenReaderQuerySucceeded);
  Assert.IsFalse(lDetection.SystemScreenReaderParameter);
  Assert.IsTrue(lDetection.UiaClientsListening);
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityScreenReaderTests);

end.
