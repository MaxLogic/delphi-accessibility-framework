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
    [Test]
    [Category('AgentBridge,AgentBridgeModalWorkflow')]
    procedure SynchronousPipeClickWaitsForModalDismissal;
    [Test]
    [Category('AgentBridge,AgentBridgeModalWorkflow')]
    procedure QueuedPipeInvokeControlsOpenModalOnSameConnection;
  end;

implementation

uses
  System.Classes, System.Diagnostics, System.JSON, System.SyncObjs, System.SysUtils, Winapi.Messages, Winapi.Windows,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  MaxLogic.Accessibility.AgentBridge, MaxLogic.Accessibility.AgentBridge.PipeServer,
  MaxLogic.Accessibility.Diagnostics;

type
  TAgentBridgeModalController = class
  private
    fCurrentModalHandle: HWND;
    fLastModalHandle: HWND;
    fModalReady: TEvent;
  public
    constructor Create(aModalReady: TEvent);
    procedure OpenModal(aSender: TObject);
    property CurrentModalHandle: HWND read fCurrentModalHandle;
    property LastModalHandle: HWND read fLastModalHandle;
  end;

constructor TAgentBridgeModalController.Create(aModalReady: TEvent);
begin
  inherited Create;
  fModalReady := aModalReady;
end;

procedure TAgentBridgeModalController.OpenModal(aSender: TObject);
var
  lButton: TButton;
  lForm: TForm;
begin
  lForm := TForm.Create(nil);
  try
    lForm.Name := 'BridgeQueuedModalForm';
    lForm.Caption := 'Bridge queued modal form';
    lButton := TButton.Create(lForm);
    lButton.Name := 'ModalOkButton';
    lButton.Caption := 'OK';
    lButton.ModalResult := mrOk;
    lButton.Parent := lForm;
    lForm.HandleNeeded;
    fCurrentModalHandle := lForm.Handle;
    fLastModalHandle := fCurrentModalHandle;
    fModalReady.SetEvent;
    lForm.ShowModal;
  finally
    fCurrentModalHandle := 0;
    lForm.Free;
  end;
end;

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

function OpenPipe(const aPipeName: string): THandle;
var
  lPipePath: string;
begin
  lPipePath := TAccessibilityAgentBridgePipeServer.PipePath(aPipeName);
  if not WaitNamedPipe(PChar(lPipePath), 5000) then
  begin
    RaiseLastOSError;
  end;

  Result := CreateFile(PChar(lPipePath), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if Result = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end;
end;

procedure WritePipeLine(aPipe: THandle; const aRequest: string);
var
  lBytes: TBytes;
  lBytesWritten: DWORD;
begin
  lBytes := TEncoding.UTF8.GetBytes(aRequest + #10);
  if (Length(lBytes) > 0) and
    not WriteFile(aPipe, lBytes[0], DWORD(Length(lBytes)), lBytesWritten, nil) then
  begin
    RaiseLastOSError;
  end;
end;

function ExchangePipeLine(aPipe: THandle; const aRequest: string): string;
begin
  WritePipeLine(aPipe, aRequest);
  Result := ReadPipeLine(aPipe);
end;

function ResponseText(const aResponse: string; const aName: string): string;
var
  lJson: TJSONValue;
  lValue: TJSONValue;
begin
  lJson := TJSONObject.ParseJSONValue(aResponse, True, True);
  try
    if not (lJson is TJSONObject) then
    begin
      raise EInvalidOperation.Create('Pipe response is not a JSON object.');
    end;
    lValue := TJSONObject(lJson).GetValue(aName); //PALOFF STWA6 guarded by is TJSONObject
    if lValue = nil then
    begin
      raise EInvalidOperation.Create('Pipe response is missing ' + aName + '.');
    end;
    Result := lValue.Value;
  finally
    lJson.Free;
  end;
end;

procedure PumpUntilSignaled(aEvent: TEvent; aTimeoutMs: Int64; const aFailureMessage: string);
var
  lStopwatch: TStopwatch;
begin
  lStopwatch := TStopwatch.StartNew;
  while aEvent.WaitFor(10) = TWaitResult.wrTimeout do
  begin
    CheckSynchronize(10);
    Application.ProcessMessages;
    if lStopwatch.ElapsedMilliseconds >= aTimeoutMs then
    begin
      Assert.Fail(aFailureMessage);
    end;
  end;
  CheckSynchronize(10);
  Application.ProcessMessages;
end;

procedure CancelAndJoinWorker(var aThread: TThread; aCancelIo: Boolean);
var
  lStopwatch: TStopwatch;
  lWaitResult: DWORD;
begin
  if aThread = nil then
  begin
    Exit;
  end;

  aThread.Terminate;
  if aCancelIo then
  begin
    CancelSynchronousIo(aThread.Handle);
  end;
  lStopwatch := TStopwatch.StartNew;
  while (WaitForSingleObject(aThread.Handle, 0) = WAIT_TIMEOUT) and
    (lStopwatch.ElapsedMilliseconds < 2000) do
  begin
    CheckSynchronize(10);
    Application.ProcessMessages;
  end;
  if WaitForSingleObject(aThread.Handle, 0) = WAIT_TIMEOUT then
  begin
    // Last-resort test cleanup keeps our runner bounded after a broken pipe or synchronization path.
    if not Winapi.Windows.TerminateThread(aThread.Handle, ERROR_CANCELLED) then
    begin
      RaiseLastOSError;
    end;
  end;
  lWaitResult := WaitForSingleObject(aThread.Handle, 2000);
  if lWaitResult <> WAIT_OBJECT_0 then
  begin
    raise EInvalidOperation.CreateFmt('Worker thread did not terminate; wait result %d.', [lWaitResult]);
  end;
  aThread.Free;
  aThread := nil;
end;

procedure StopPipeServerBounded;
var
  lDone: TEvent;
  lError: string;
  lStopwatch: TStopwatch;
  lThread: TThread;
  lTimedOut: Boolean;
begin
  lDone := TEvent.Create(nil, True, False, '');
  lThread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        TAccessibilityAgentBridgePipeServer.Stop;
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
    while (lDone.WaitFor(10) = TWaitResult.wrTimeout) and
      (lStopwatch.ElapsedMilliseconds < 5000) do
    begin
      CheckSynchronize(10);
      Application.ProcessMessages;
    end;
    lTimedOut := lDone.WaitFor(0) = TWaitResult.wrTimeout;
    CancelAndJoinWorker(lThread, False);
    if lTimedOut then
    begin
      raise EInvalidOperation.Create('Timed out while stopping the modal test pipe server.');
    end;
    if lError <> '' then
    begin
      raise EInvalidOperation.Create(lError);
    end;
  finally
    CancelAndJoinWorker(lThread, False);
    lDone.Free;
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
    Assert.AreEqual<NativeInt>(2, Length(lResponses));
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

procedure TAccessibilityAgentBridgePipeServerTests.SynchronousPipeClickWaitsForModalDismissal;
var
  lButton: TButton;
  lClientDone: TEvent;
  lClientError: string;
  lClientThread: TThread;
  lController: TAgentBridgeModalController;
  lFallbackDone: TEvent;
  lFallbackError: string;
  lFallbackStop: TEvent;
  lFallbackThread: TThread;
  lFallbackUsed: Boolean;
  lForm: TForm;
  lModalReady: TEvent;
  lPipeName: string;
  lResponse: string;
  lResponseBlocked: Boolean;
  lResponseDone: TEvent;
  lResponseJson: TJSONObject;
begin
  lModalReady := TEvent.Create(nil, True, False, '');
  lResponseDone := TEvent.Create(nil, True, False, '');
  lClientDone := TEvent.Create(nil, True, False, '');
  lFallbackDone := TEvent.Create(nil, True, False, '');
  lFallbackStop := TEvent.Create(nil, True, False, '');
  lController := TAgentBridgeModalController.Create(lModalReady);
  lForm := TForm.Create(nil);
  lClientThread := nil;
  lFallbackThread := nil;
  try
    lForm.Name := 'PipeSynchronousModalHostForm';
    lButton := TButton.Create(lForm);
    lButton.Name := 'OpenModalButton';
    lButton.OnClick := lController.OpenModal;
    lButton.Parent := lForm;
    lForm.Show;
    Application.ProcessMessages;

    lPipeName := Format('MaxLogicA11yBridgeSynchronousModalTest.%d.%d',
      [GetCurrentProcessId, GetTickCount]);
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    TAccessibilityAgentBridgePipeServer.Start(lPipeName);
    try
      lFallbackThread := TThread.CreateAnonymousThread(
        procedure
        begin
          try
            while (lModalReady.WaitFor(10) = TWaitResult.wrTimeout) and
              (lFallbackStop.WaitFor(0) = TWaitResult.wrTimeout) do
            begin
              Sleep(1);
            end;
            if lModalReady.WaitFor(0) = TWaitResult.wrSignaled then
            begin
              lResponseBlocked := lResponseDone.WaitFor(250) = TWaitResult.wrTimeout;
              lFallbackUsed := True;
              if lController.CurrentModalHandle <> 0 then
              begin
                PostMessage(lController.CurrentModalHandle, WM_CLOSE, 0, 0);
              end;
            end;
          except
            on lException: Exception do
            begin
              lFallbackError := lException.ClassName + ': ' + lException.Message;
            end;
          end;
          lFallbackDone.SetEvent;
        end);
      lFallbackThread.FreeOnTerminate := False;

      lClientThread := TThread.CreateAnonymousThread(
        procedure
        begin
          try
            lResponse := RequestPipeLine(lPipeName,
              '{"cmd":"control.click","target":{"formName":"PipeSynchronousModalHostForm",' +
              '"controlName":"OpenModalButton"}}');
          except
            on lException: Exception do
            begin
              lClientError := lException.ClassName + ': ' + lException.Message;
            end;
          end;
          lResponseDone.SetEvent;
          lClientDone.SetEvent;
        end);
      lClientThread.FreeOnTerminate := False;
      try
        lFallbackThread.Start;
        lClientThread.Start;
        PumpUntilSignaled(lClientDone, 8000, 'Timed out waiting for the synchronous modal response.');
        PumpUntilSignaled(lFallbackDone, 1000, 'The synchronous modal fallback worker did not stop.');
        lClientThread.WaitFor;
        lFallbackThread.WaitFor;

        Assert.AreEqual('', lClientError);
        Assert.AreEqual('', lFallbackError);
        Assert.IsTrue(lFallbackUsed, 'The characterization fallback did not dismiss the modal.');
        Assert.IsTrue(lResponseBlocked,
          'Legacy control.click returned before its modal VCL handler completed.');
        lResponseJson := JsonObjectFrom(lResponse);
        try
          Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lResponse);
          Assert.AreEqual('control.click', JsonText(lResponseJson, 'cmd'));
        finally
          lResponseJson.Free;
        end;
      finally
        if lController.CurrentModalHandle <> 0 then
        begin
          PostMessage(lController.CurrentModalHandle, WM_CLOSE, 0, 0);
        end;
        lResponseDone.SetEvent;
        CancelAndJoinWorker(lClientThread, True);
      end;
    finally
      try
        StopPipeServerBounded;
      finally
        lFallbackStop.SetEvent;
        try
          CancelAndJoinWorker(lFallbackThread, False);
        finally
          TAccessibilityAgentBridge.SetMutationEnabled(False);
        end;
      end;
    end;
  finally
    lForm.Free;
    lController.Free;
    lFallbackStop.Free;
    lFallbackDone.Free;
    lClientDone.Free;
    lResponseDone.Free;
    lModalReady.Free;
  end;
end;

procedure TAccessibilityAgentBridgePipeServerTests.QueuedPipeInvokeControlsOpenModalOnSameConnection;
var
  lBridgeDismissed: TEvent;
  lButton: TButton;
  lCancelClient: TEvent;
  lCancelFallback: TEvent;
  lClientDone: TEvent;
  lClientError: string;
  lClientThread: TThread;
  lController: TAgentBridgeModalController;
  lDismissOperationId: string;
  lDismissResponse: string;
  lDismissStatusResponse: string;
  lFallbackDone: TEvent;
  lFallbackError: string;
  lFallbackStop: TEvent;
  lFallbackThread: TThread;
  lFallbackUsed: Boolean;
  lForm: TForm;
  lFormsResponse: string;
  lInvokeResponse: string;
  lInvokeResponseDone: TEvent;
  lModalReady: TEvent;
  lOpenOperationId: string;
  lOpenRunningResponse: string;
  lOpenStatusResponse: string;
  lPipeName: string;
  lResponseJson: TJSONObject;
begin
  lModalReady := TEvent.Create(nil, True, False, '');
  lInvokeResponseDone := TEvent.Create(nil, True, False, '');
  lBridgeDismissed := TEvent.Create(nil, True, False, '');
  lCancelClient := TEvent.Create(nil, True, False, '');
  lCancelFallback := TEvent.Create(nil, True, False, '');
  lClientDone := TEvent.Create(nil, True, False, '');
  lFallbackDone := TEvent.Create(nil, True, False, '');
  lFallbackStop := TEvent.Create(nil, True, False, '');
  lController := TAgentBridgeModalController.Create(lModalReady);
  lForm := TForm.Create(nil);
  lClientThread := nil;
  lFallbackThread := nil;
  try
    lForm.Name := 'PipeQueuedModalHostForm';
    lButton := TButton.Create(lForm);
    lButton.Name := 'OpenModalButton';
    lButton.OnClick := lController.OpenModal;
    lButton.Parent := lForm;
    lForm.Show;
    Application.ProcessMessages;

    lPipeName := Format('MaxLogicA11yBridgeQueuedModalTest.%d.%d',
      [GetCurrentProcessId, GetTickCount]);
    TAccessibilityAgentBridge.SetMutationEnabled(True);
    TAccessibilityAgentBridgePipeServer.Start(lPipeName);
    try
      lFallbackThread := TThread.CreateAnonymousThread(
        procedure
        var
          lDeadline: UInt64;
        begin
          try
            while (lModalReady.WaitFor(10) = TWaitResult.wrTimeout) and
              (lFallbackStop.WaitFor(0) = TWaitResult.wrTimeout) do
            begin
              Sleep(1);
            end;
            if lModalReady.WaitFor(0) = TWaitResult.wrSignaled then
            begin
              lDeadline := GetTickCount64 + 3000;
              while (lBridgeDismissed.WaitFor(10) = TWaitResult.wrTimeout) and
                (lCancelFallback.WaitFor(0) = TWaitResult.wrTimeout) and
                (lFallbackStop.WaitFor(0) = TWaitResult.wrTimeout) and
                (GetTickCount64 < lDeadline) do
              begin
                Sleep(1);
              end;
              if lBridgeDismissed.WaitFor(0) = TWaitResult.wrTimeout then
              begin
                lFallbackUsed := True;
                if lController.CurrentModalHandle <> 0 then
                begin
                  PostMessage(lController.CurrentModalHandle, WM_CLOSE, 0, 0);
                end;
              end;
            end;
          except
            on lException: Exception do
            begin
              lFallbackError := lException.ClassName + ': ' + lException.Message;
            end;
          end;
          lFallbackDone.SetEvent;
        end);
      lFallbackThread.FreeOnTerminate := False;

      lClientThread := TThread.CreateAnonymousThread(
        procedure
        var
          lDeadline: UInt64;
          lPipe: THandle;
          lStatus: string;
        begin
          lPipe := INVALID_HANDLE_VALUE;
          try
            lPipe := OpenPipe(lPipeName);
            lInvokeResponse := ExchangePipeLine(lPipe,
              '{"cmd":"control.invoke","target":{"formName":"PipeQueuedModalHostForm",' +
              '"controlName":"OpenModalButton"}}');
            lOpenOperationId := ResponseText(lInvokeResponse, 'operationId');
            lInvokeResponseDone.SetEvent;
            if lModalReady.WaitFor(5000) <> TWaitResult.wrSignaled then
            begin
              raise EInvalidOperation.Create('Queued invoke response arrived, but the modal form did not open.');
            end;

            lOpenRunningResponse := ExchangePipeLine(lPipe,
              '{"cmd":"operation.status","operationId":"' + lOpenOperationId +
              '","consume":false}');
            lFormsResponse := ExchangePipeLine(lPipe, '{"cmd":"forms.list"}');
            lDismissResponse := ExchangePipeLine(lPipe,
              '{"cmd":"control.invoke","target":{"formHandle":' +
              UIntToStr(NativeUInt(lController.LastModalHandle)) + ',"controlName":"ModalOkButton"}}');
            lDismissOperationId := ResponseText(lDismissResponse, 'operationId');

            lDeadline := GetTickCount64 + 5000;
            repeat
              lDismissStatusResponse := ExchangePipeLine(lPipe,
                '{"cmd":"operation.status","operationId":"' + lDismissOperationId +
                '","consume":false}');
              lStatus := ResponseText(lDismissStatusResponse, 'status');
              if (lStatus <> 'succeeded') and (lStatus <> 'failed') then
              begin
                Sleep(10);
              end;
            until (lStatus = 'succeeded') or (lStatus = 'failed') or (GetTickCount64 >= lDeadline) or
              (lCancelClient.WaitFor(0) = TWaitResult.wrSignaled);
            if lStatus <> 'succeeded' then
            begin
              raise EInvalidOperation.Create('Modal dismiss operation did not succeed: ' +
                lDismissStatusResponse);
            end;
            lBridgeDismissed.SetEvent;

            lDeadline := GetTickCount64 + 5000;
            repeat
              lOpenStatusResponse := ExchangePipeLine(lPipe,
                '{"cmd":"operation.status","operationId":"' + lOpenOperationId +
                '","consume":false}');
              lStatus := ResponseText(lOpenStatusResponse, 'status');
              if (lStatus <> 'succeeded') and (lStatus <> 'failed') then
              begin
                Sleep(10);
              end;
            until (lStatus = 'succeeded') or (lStatus = 'failed') or (GetTickCount64 >= lDeadline) or
              (lCancelClient.WaitFor(0) = TWaitResult.wrSignaled);
            if lStatus <> 'succeeded' then
            begin
              raise EInvalidOperation.Create('Modal opener operation did not succeed: ' + lOpenStatusResponse);
            end;

            lDismissStatusResponse := ExchangePipeLine(lPipe,
              '{"cmd":"operation.status","operationId":"' + lDismissOperationId + '"}');
            lOpenStatusResponse := ExchangePipeLine(lPipe,
              '{"cmd":"operation.status","operationId":"' + lOpenOperationId + '"}');
          except
            on lException: Exception do
            begin
              lClientError := lException.ClassName + ': ' + lException.Message;
            end;
          end;
          if lPipe <> INVALID_HANDLE_VALUE then
          begin
            CloseHandle(lPipe);
          end;
          lClientDone.SetEvent;
        end);
      lClientThread.FreeOnTerminate := False;
      try
        lFallbackThread.Start;
        lClientThread.Start;
        PumpUntilSignaled(lInvokeResponseDone, 5000,
          'Queued control.invoke did not return before the modal workflow continued.');
        PumpUntilSignaled(lClientDone, 10000, 'Timed out waiting for the queued modal workflow.');
        PumpUntilSignaled(lFallbackDone, 1000, 'The queued modal fallback worker did not stop.');
        lClientThread.WaitFor;
        lFallbackThread.WaitFor;

        Assert.AreEqual('', lClientError);
        Assert.AreEqual('', lFallbackError);
        Assert.IsFalse(lFallbackUsed, 'The bridge did not dismiss the modal before the fallback timeout.');

        lResponseJson := JsonObjectFrom(lInvokeResponse);
        try
          Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lInvokeResponse);
          Assert.AreEqual('queued', JsonText(lResponseJson, 'status'));
        finally
          lResponseJson.Free;
        end;
        lResponseJson := JsonObjectFrom(lOpenRunningResponse);
        try
          Assert.AreEqual('running', JsonText(lResponseJson, 'status'), lOpenRunningResponse);
        finally
          lResponseJson.Free;
        end;
        Assert.IsTrue(Pos('BridgeQueuedModalForm', lFormsResponse) > 0, lFormsResponse);
        Assert.IsTrue(Pos(UIntToStr(NativeUInt(lController.LastModalHandle)), lFormsResponse) > 0,
          lFormsResponse);
        lResponseJson := JsonObjectFrom(lDismissResponse);
        try
          Assert.AreEqual('true', JsonText(lResponseJson, 'ok'), lDismissResponse);
          Assert.AreEqual('queued', JsonText(lResponseJson, 'status'));
        finally
          lResponseJson.Free;
        end;
        lResponseJson := JsonObjectFrom(lDismissStatusResponse);
        try
          Assert.AreEqual('succeeded', JsonText(lResponseJson, 'status'), lDismissStatusResponse);
          Assert.AreEqual('true', JsonText(lResponseJson, 'consumed'), lDismissStatusResponse);
        finally
          lResponseJson.Free;
        end;
        lResponseJson := JsonObjectFrom(lOpenStatusResponse);
        try
          Assert.AreEqual('succeeded', JsonText(lResponseJson, 'status'), lOpenStatusResponse);
          Assert.AreEqual('true', JsonText(lResponseJson, 'consumed'), lOpenStatusResponse);
        finally
          lResponseJson.Free;
        end;
      finally
        lCancelClient.SetEvent;
        lCancelFallback.SetEvent;
        if lController.CurrentModalHandle <> 0 then
        begin
          PostMessage(lController.CurrentModalHandle, WM_CLOSE, 0, 0);
        end;
        CancelAndJoinWorker(lClientThread, True);
      end;
    finally
      try
        StopPipeServerBounded;
      finally
        lFallbackStop.SetEvent;
        try
          CancelAndJoinWorker(lFallbackThread, False);
        finally
          TAccessibilityAgentBridge.SetMutationEnabled(False);
        end;
      end;
    end;
  finally
    lForm.Free;
    lController.Free;
    lFallbackStop.Free;
    lFallbackDone.Free;
    lClientDone.Free;
    lCancelFallback.Free;
    lCancelClient.Free;
    lBridgeDismissed.Free;
    lInvokeResponseDone.Free;
    lModalReady.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityAgentBridgePipeServerTests);

end.
