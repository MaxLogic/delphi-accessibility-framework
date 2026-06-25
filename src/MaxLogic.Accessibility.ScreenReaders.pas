unit MaxLogic.Accessibility.ScreenReaders;

interface

type
  TAccessibilityScreenReaderSignal = (
    srsSystemScreenReaderParameter,
    srsUiaClientListener
  );
  TAccessibilityScreenReaderSignals = set of TAccessibilityScreenReaderSignal;

  TAccessibilityScreenReaderDetection = record
  private
    fSignals: TAccessibilityScreenReaderSignals;
    fSystemScreenReaderParameter: Boolean;
    fSystemScreenReaderQuerySucceeded: Boolean;
    fUiaClientsListening: Boolean;
    function GetLikelyActive: Boolean;
  public
    property LikelyActive: Boolean read GetLikelyActive;
    property Signals: TAccessibilityScreenReaderSignals read fSignals;
    property SystemScreenReaderParameter: Boolean read fSystemScreenReaderParameter;
    property SystemScreenReaderQuerySucceeded: Boolean read fSystemScreenReaderQuerySucceeded;
    property UiaClientsListening: Boolean read fUiaClientsListening;
  end;

  IAccessibilityScreenReaderProbe = interface
    ['{8ACF64F7-576E-42BF-A926-8B1606931664}']
    function TryGetSystemScreenReaderParameter(out aEnabled: Boolean): Boolean;
    function UiaClientsAreListening: Boolean;
  end;

  TAccessibilityScreenReaderDetector = record
  public
    class function Detect: TAccessibilityScreenReaderDetection; overload; static;
    class function Detect(const aProbe: IAccessibilityScreenReaderProbe): TAccessibilityScreenReaderDetection; overload; static;
    class function IsLikelyActive: Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  MaxLogic.Accessibility.UIAutomationCore;

type
  TWindowsAccessibilityScreenReaderProbe = class(TInterfacedObject, IAccessibilityScreenReaderProbe)
  public
    function TryGetSystemScreenReaderParameter(out aEnabled: Boolean): Boolean;
    function UiaClientsAreListening: Boolean;
  end;

function TWindowsAccessibilityScreenReaderProbe.TryGetSystemScreenReaderParameter(out aEnabled: Boolean): Boolean;
var
  lEnabled: BOOL;
begin
  lEnabled := BOOL(False);
  Result := SystemParametersInfo(SPI_GETSCREENREADER, 0, @lEnabled, 0);
  aEnabled := Result and (lEnabled <> BOOL(False));
end;

function TWindowsAccessibilityScreenReaderProbe.UiaClientsAreListening: Boolean;
begin
  Result := MaxLogic.Accessibility.UIAutomationCore.UiaClientsAreListening <> BOOL(False);
end;

function TAccessibilityScreenReaderDetection.GetLikelyActive: Boolean;
begin
  Result := fSignals <> [];
end;

class function TAccessibilityScreenReaderDetector.Detect: TAccessibilityScreenReaderDetection;
begin
  Result := Detect(TWindowsAccessibilityScreenReaderProbe.Create);
end;

class function TAccessibilityScreenReaderDetector.Detect(
  const aProbe: IAccessibilityScreenReaderProbe): TAccessibilityScreenReaderDetection;
var
  lSystemEnabled: Boolean;
begin
  if aProbe = nil then
  begin
    raise EArgumentException.Create('Screen-reader probe is required.');
  end;

  Result := Default(TAccessibilityScreenReaderDetection);
  lSystemEnabled := False;
  Result.fSystemScreenReaderQuerySucceeded := aProbe.TryGetSystemScreenReaderParameter(lSystemEnabled);
  if Result.fSystemScreenReaderQuerySucceeded then
  begin
    Result.fSystemScreenReaderParameter := lSystemEnabled;
    if lSystemEnabled then
    begin
      Include(Result.fSignals, srsSystemScreenReaderParameter);
    end;
  end;

  Result.fUiaClientsListening := aProbe.UiaClientsAreListening;
  if Result.fUiaClientsListening then
  begin
    Include(Result.fSignals, srsUiaClientListener);
  end;
end;

class function TAccessibilityScreenReaderDetector.IsLikelyActive: Boolean;
begin
  Result := Detect.LikelyActive;
end;

end.
