unit MaxLogic.Accessibility.AgentBridge.PipeServer.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('AgentBridge')]
  TAccessibilityAgentBridgePipeServerTests = class
  public
    [Test]
    procedure PipeRoundTripExecutesBridgeOnMainThread;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.JSON, System.SyncObjs, System.SysUtils, Winapi.Windows,
  MaxLogic.Accessibility.AgentBridge.PipeServer;

function JsonObjectFrom(const aText: string): TJSONObject;
var
  lValue: TJSONValue;
begin
  lValue := TJSONObject.ParseJSONValue(aText, True, True);
  Assert.IsNotNull(lValue, 'JSON response was empty.');
  Assert.IsTrue(lValue is TJSONObject, 'JSON response is not an object: ' + aText);
  Result := TJSONObject(lValue);
end;

function JsonText(aObject: TJSONObject; const aName: string): string;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing text value: ' + aName);
  Result := lValue.Value;
end;

function ReadPipeLine(aPipe: THandle): string;
var
  i: Integer;
  lBuffer: array[0..255] of Byte;
  lBytes: TBytes;
  lBytesRead: DWORD;
  lLength: Integer;
begin
  SetLength(lBytes, 0);
  while True do
  begin
    if not ReadFile(aPipe, lBuffer, SizeOf(lBuffer), lBytesRead, nil) then
    begin
      RaiseLastOSError;
    end;

    for i := 0 to Pred(lBytesRead) do
    begin
      if lBuffer[i] = 10 then
      begin
        Exit(TEncoding.UTF8.GetString(lBytes));
      end;

      if lBuffer[i] <> 13 then
      begin
        lLength := Length(lBytes);
        SetLength(lBytes, Succ(lLength));
        lBytes[lLength] := lBuffer[i];
      end;
    end;
  end;
end;

function RequestPipeLine(const aPipeName: string; const aRequest: string): string;
var
  lBytes: TBytes;
  lBytesWritten: DWORD;
  lPipe: THandle;
  lPipePath: string;
begin
  lPipePath := TAccessibilityAgentBridgePipeServer.PipePath(aPipeName);
  if not WaitNamedPipe(PChar(lPipePath), 5000) then
  begin
    RaiseLastOSError;
  end;

  lPipe := CreateFile(PChar(lPipePath), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if lPipe = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end;

  try
    lBytes := TEncoding.UTF8.GetBytes(aRequest + #10);
    if (Length(lBytes) > 0) and not WriteFile(lPipe, lBytes[0], DWORD(Length(lBytes)), lBytesWritten, nil) then
    begin
      RaiseLastOSError;
    end;
    Result := ReadPipeLine(lPipe);
  finally
    CloseHandle(lPipe);
  end;
end;

procedure TAccessibilityAgentBridgePipeServerTests.PipeRoundTripExecutesBridgeOnMainThread;
var
  lDone: TEvent;
  lError: string;
  lPipeName: string;
  lResponse: string;
  lResponseJson: TJSONObject;
  lStopwatch: TStopwatch;
  lThread: TThread;
begin
  lPipeName := Format('MaxLogicA11yBridgeTest.%d.%d', [GetCurrentProcessId, GetTickCount]);
  lDone := TEvent.Create(nil, True, False, '');
  try
    TAccessibilityAgentBridgePipeServer.Start(lPipeName);
    try
      Assert.IsTrue(TAccessibilityAgentBridgePipeServer.Running);
      Assert.AreEqual(lPipeName, TAccessibilityAgentBridgePipeServer.PipeName);
      TAccessibilityAgentBridgePipeServer.Start(lPipeName);
      Assert.AreEqual(lPipeName, TAccessibilityAgentBridgePipeServer.PipeName);

      lThread := TThread.CreateAnonymousThread(
        procedure
        begin
          try
            lResponse := RequestPipeLine(lPipeName, '{"cmd":"hello"}');
          except
            on lException: Exception do
            begin
              lError := lException.ClassName + ': ' + lException.Message;
            end;
          end;
          lDone.SetEvent;
        end);
      lThread.FreeOnTerminate := False;
      try
        lThread.Start;
        lStopwatch := TStopwatch.StartNew;
        while lDone.WaitFor(10) = TWaitResult.wrTimeout do
        begin
          CheckSynchronize(10);
          if lStopwatch.ElapsedMilliseconds > 5000 then
          begin
            Assert.Fail('Timed out waiting for named pipe response.');
          end;
        end;
        CheckSynchronize(10);
        lThread.WaitFor;
      finally
        lThread.Free;
      end;

      Assert.AreEqual('', lError);
      lResponseJson := JsonObjectFrom(lResponse);
      try
        Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lResponse);
        Assert.AreEqual('hello', JsonText(lResponseJson, 'cmd'));
        Assert.IsNull(lResponseJson.GetValue('errorCode'), lResponse);
      finally
        lResponseJson.Free;
      end;
    finally
      TAccessibilityAgentBridgePipeServer.Stop;
    end;

    Assert.IsFalse(TAccessibilityAgentBridgePipeServer.Running);
    TAccessibilityAgentBridgePipeServer.Stop;
  finally
    lDone.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityAgentBridgePipeServerTests);

end.
