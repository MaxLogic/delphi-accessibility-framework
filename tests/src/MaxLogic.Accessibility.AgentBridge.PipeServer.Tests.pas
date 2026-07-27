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
    procedure LargeRequestReadDoesNotResizeBufferPerByte;
    [Test]
    procedure PipeConnectionAcceptsSequentialRequests;
    [Test]
    procedure PipeFormMapCapturesOnMainThreadAndSerializesOnWorker;
    [Test]
    procedure PipeRoundTripExecutesBridgeOnMainThread;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.JSON, System.SyncObjs, System.SysUtils, Winapi.Windows,
  Vcl.Forms, Vcl.StdCtrls,
  MaxLogic.Accessibility.AgentBridge, MaxLogic.Accessibility.AgentBridge.PipeServer,
  MaxLogic.Accessibility.Diagnostics;

function JsonObjectFrom(const aText: string): TJSONObject;
var
  lValue: TJSONValue;
begin
  lValue := TJSONObject.ParseJSONValue(aText, True, True);
  Assert.IsNotNull(lValue, 'JSON response was empty.');
  Assert.IsTrue(lValue is TJSONObject, 'JSON response is not an object: ' + aText);
  Result := TJSONObject(lValue); //PALOFF STWA6 guarded by JSON type assertion
end;

function JsonText(aObject: TJSONObject; const aName: string): string;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing text value: ' + aName);
  Result := lValue.Value;
end;

function JsonInt64(aObject: TJSONObject; const aName: string): Int64;
begin
  Result := StrToInt64(JsonText(aObject, aName));
end;

function ReadPipeLine(aPipe: THandle): string;
var
  i: Integer;
  lBuffer: array[0..255] of Byte;
  lBytes: TBytes;
  lBytesRead: DWORD;
  lLength: Integer;
begin
  Result := '';
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

function RequestPipeLines(const aPipeName: string; const aRequests: array of string): TArray<string>;
var
  i: Integer;
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
    SetLength(Result, Length(aRequests));
    for i := 0 to Pred(Length(aRequests)) do
    begin
      lBytes := TEncoding.UTF8.GetBytes(aRequests[i] + #10);
      if (Length(lBytes) > 0) and not WriteFile(lPipe, lBytes[0], DWORD(Length(lBytes)), lBytesWritten, nil) then
      begin
        RaiseLastOSError;
      end;
      Result[i] := ReadPipeLine(lPipe);
    end;
  finally
    CloseHandle(lPipe);
  end;
end;

function RequestPipeLineFromWorker(const aPipeName: string; const aRequest: string): string;
var
  lDone: TEvent;
  lError: string;
  lResponse: string;
  lStopwatch: TStopwatch;
  lThread: TThread;
begin
  lDone := TEvent.Create(nil, True, False, '');
  try
    lThread := TThread.CreateAnonymousThread(
      procedure
      begin
        try
          lResponse := RequestPipeLine(aPipeName, aRequest);
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
    Result := lResponse;
  finally
    lDone.Free;
  end;
end;

function RequestPipeLinesFromWorker(const aPipeName: string; const aRequests: array of string): TArray<string>;
var
  i: Integer;
  lDone: TEvent;
  lError: string;
  lRequests: TArray<string>;
  lResponses: TArray<string>;
  lStopwatch: TStopwatch;
  lThread: TThread;
begin
  SetLength(lRequests, Length(aRequests));
  for i := 0 to Pred(Length(aRequests)) do
  begin
    lRequests[i] := aRequests[i];
  end;

  lDone := TEvent.Create(nil, True, False, '');
  try
    lThread := TThread.CreateAnonymousThread(
      procedure
      begin
        try
          lResponses := RequestPipeLines(aPipeName, lRequests);
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
          Assert.Fail('Timed out waiting for named pipe responses.');
        end;
      end;
      CheckSynchronize(10);
      lThread.WaitFor;
    finally
      lThread.Free;
    end;

    Assert.AreEqual('', lError);
    Result := lResponses;
  finally
    lDone.Free;
  end;
end;

procedure TAccessibilityAgentBridgePipeServerTests.LargeRequestReadDoesNotResizeBufferPerByte;
const
  cPaddingLength = 32768;
var
  lMetrics: TAccessibilityAgentBridgePipeMetrics;
  lPipeName: string;
  lRequest: string;
  lResponse: string;
  lResponseJson: TJSONObject;
begin
  lPipeName := Format('MaxLogicA11yBridgeLargeRequestTest.%d.%d', [GetCurrentProcessId, GetTickCount]);
  TAccessibilityDiagnostics.EnableAgentBridgePipeMetrics;
  TAccessibilityDiagnostics.ResetAgentBridgePipeMetrics;
  try
    TAccessibilityAgentBridgePipeServer.Start(lPipeName);
    try
      lRequest := '{"cmd":"hello","padding":"' + StringOfChar('x', cPaddingLength) + '"}';
      lResponse := RequestPipeLineFromWorker(lPipeName, lRequest);
      lResponseJson := JsonObjectFrom(lResponse);
      try
        Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lResponse);
        Assert.AreEqual('hello', JsonText(lResponseJson, 'cmd'));
      finally
        lResponseJson.Free;
      end;

      lMetrics := TAccessibilityDiagnostics.AgentBridgePipeMetrics;
      Assert.IsTrue(lMetrics.Enabled);
      Assert.AreEqual(1, lMetrics.RequestReadCount);
      Assert.IsTrue(lMetrics.RequestReadByteCount >= cPaddingLength,
        'Pipe read metrics did not capture the large request payload.');
      Assert.IsTrue(lMetrics.RequestReadResizeCount <= 16,
        Format('Pipe request read resized the request buffer %d times for %d bytes; expected chunked growth.',
        [lMetrics.RequestReadResizeCount, lMetrics.RequestReadByteCount]));
    finally
      TAccessibilityAgentBridgePipeServer.Stop;
    end;
  finally
    TAccessibilityDiagnostics.DisableAgentBridgePipeMetrics;
  end;
end;

procedure TAccessibilityAgentBridgePipeServerTests.PipeConnectionAcceptsSequentialRequests;
var
  i: Integer;
  lPipeName: string;
  lResponseJson: TJSONObject;
  lResponses: TArray<string>;
begin
  lPipeName := Format('MaxLogicA11yBridgeSequenceTest.%d.%d', [GetCurrentProcessId, GetTickCount]);
  TAccessibilityAgentBridgePipeServer.Start(lPipeName);
  try
    lResponses := RequestPipeLinesFromWorker(lPipeName, ['{"cmd":"hello"}', '{"cmd":"hello"}']);
    Assert.AreEqual(2, Length(lResponses));
    for i := 0 to Pred(Length(lResponses)) do
    begin
      lResponseJson := JsonObjectFrom(lResponses[i]);
      try
        Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lResponses[i]);
        Assert.AreEqual('hello', JsonText(lResponseJson, 'cmd'));
      finally
        lResponseJson.Free;
      end;
    end;
  finally
    TAccessibilityAgentBridgePipeServer.Stop;
  end;
end;

function CreatePipeBridgeForm: TForm;
var
  lButton: TButton;
  lEdit: TEdit;
begin
  Result := TForm.Create(nil);
  Result.Name := 'PipeBridgeForm';
  Result.Caption := 'Pipe bridge form';
  lEdit := TEdit.Create(Result);
  lEdit.Name := 'PipeEdit';
  lEdit.Parent := Result;
  lButton := TButton.Create(Result);
  lButton.Name := 'PipeButton';
  lButton.Parent := Result;
  Result.HandleNeeded;
end;

procedure AssertPipeHelloEquivalent(const aPipeName: string);
var
  lDirectHello: TJSONObject;
  lPipeHello: TJSONObject;
begin
  lDirectHello := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"hello"}'));
  try
    Assert.AreEqual(Int64(MainThreadID), JsonInt64(lDirectHello, 'captureThreadId'));
    Assert.AreEqual(Int64(MainThreadID), JsonInt64(lDirectHello, 'serializationThreadId'));
    lPipeHello := JsonObjectFrom(RequestPipeLineFromWorker(aPipeName, '{"cmd":"hello"}'));
    try
      Assert.AreEqual(JsonText(lDirectHello, 'frameworkName'), JsonText(lPipeHello, 'frameworkName'));
      Assert.AreEqual(JsonText(lDirectHello, 'processId'), JsonText(lPipeHello, 'processId'));
      Assert.AreEqual(JsonText(lDirectHello, 'mutationEnabled'), JsonText(lPipeHello, 'mutationEnabled'));
    finally
      lPipeHello.Free;
    end;
  finally
    lDirectHello.Free;
  end;
end;

procedure AssertPipeFormMapTiming(aForm: TForm; const aPipeName: string);
var
  lRequest: string;
  lResponse: string;
  lResponseJson: TJSONObject;
begin
  lRequest := '{"cmd":"form.map","target":"handle","handle":' + UIntToStr(NativeUInt(aForm.Handle)) +
    ',"includeAccessibility":false,"visibleOnly":true,"detail":"geometry"}';
  lResponse := RequestPipeLineFromWorker(aPipeName, lRequest);
  lResponseJson := JsonObjectFrom(lResponse);
  try
    Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lResponse);
    Assert.AreEqual(Int64(MainThreadID), JsonInt64(lResponseJson, 'captureThreadId'));
    Assert.AreNotEqual(Int64(MainThreadID), JsonInt64(lResponseJson, 'serializationThreadId'));
    Assert.IsTrue(JsonInt64(lResponseJson, 'captureBuildElapsedTicks') > 0);
    Assert.IsTrue(JsonInt64(lResponseJson, 'synchronizedElapsedTicks') >=
      JsonInt64(lResponseJson, 'captureBuildElapsedTicks'));
    Assert.IsTrue(JsonInt64(lResponseJson, 'serializationElapsedTicks') > 0);
    Assert.IsTrue(JsonInt64(lResponseJson, 'elapsedTicks') >=
      JsonInt64(lResponseJson, 'synchronizedElapsedTicks'));
    Assert.IsTrue(JsonInt64(lResponseJson, 'elapsedTicks') >=
      JsonInt64(lResponseJson, 'serializationElapsedTicks'));
  finally
    lResponseJson.Free;
  end;
end;

procedure AssertPipeControlResolveIsNarrow(aForm: TForm; const aPipeName: string);
var
  lControl: TJSONObject;
  lRequest: string;
  lResponse: string;
  lResponseJson: TJSONObject;
begin
  lRequest := '{"cmd":"control.resolve","target":{"formName":"' + aForm.Name +
    '","controlName":"PipeButton"},"detail":"target"}';
  lResponse := RequestPipeLineFromWorker(aPipeName, lRequest);
  lResponseJson := JsonObjectFrom(lResponse);
  try
    Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lResponse);
    Assert.AreEqual('control.resolve', JsonText(lResponseJson, 'cmd'));
    Assert.IsNull(lResponseJson.GetValue('controls'), 'Narrow pipe resolution serialized a complete control map.');
    lControl := TJSONObject(lResponseJson.GetValue('control')); //PALOFF STWA6 response contract checked below
    Assert.IsNotNull(lControl, lResponse);
    Assert.AreEqual('PipeButton', JsonText(lControl, 'name'));
    Assert.AreEqual('PipeBridgeForm', JsonText(lControl, 'formName'));
  finally
    lResponseJson.Free;
  end;
end;

procedure TAccessibilityAgentBridgePipeServerTests.PipeFormMapCapturesOnMainThreadAndSerializesOnWorker;
var
  lForm: TForm;
  lPipeName: string;
begin
  lForm := CreatePipeBridgeForm;
  try
    lPipeName := Format('MaxLogicA11yBridgeDetachedMapTest.%d.%d',
      [GetCurrentProcessId, GetTickCount]);
    TAccessibilityAgentBridgePipeServer.Start(lPipeName);
    try
      AssertPipeHelloEquivalent(lPipeName);
      AssertPipeFormMapTiming(lForm, lPipeName);
      AssertPipeControlResolveIsNarrow(lForm, lPipeName);
    finally
      TAccessibilityAgentBridgePipeServer.Stop;
    end;
  finally
    lForm.Free;
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
