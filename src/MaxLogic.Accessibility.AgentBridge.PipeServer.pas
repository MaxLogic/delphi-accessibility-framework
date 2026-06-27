unit MaxLogic.Accessibility.AgentBridge.PipeServer;

interface

type
  TAccessibilityAgentBridgePipeServer = record
  public
    class function DefaultPipeName: string; static;
    class function PipeName: string; static;
    class function PipePath(const aPipeName: string): string; static;
    class function Running: Boolean; static;
    class procedure Start(const aPipeName: string = ''); static;
    class procedure Stop; static;
  end;

implementation

uses
  System.Classes, System.SyncObjs, System.SysUtils,
  Winapi.Windows,
  MaxLogic.Accessibility.AgentBridge;

const
  cPipeBufferSize = 65536;
  cPipePrefix = '\\.\pipe\';
  cPipeRejectRemoteClients = $00000008;
  cReadyTimeoutMs = 5000;

type
  TAccessibilityAgentBridgePipeServerThread = class(TThread)
  private
    fCurrentPipe: THandle;
    fLock: TObject;
    fPipeName: string;
    fPipePath: string;
    fReadyError: string;
    fReadyEvent: TEvent;
    function CurrentPipe: THandle;
    function ExecuteBridge(const aRequest: string): string;
    function ReadRequest(aPipe: THandle; out aRequest: string): Boolean;
    procedure HandleClient(aPipe: THandle);
    procedure MarkReady(const aError: string);
    procedure ReportClientException(aException: Exception);
    procedure SetCurrentPipe(aPipe: THandle);
    procedure WriteResponse(aPipe: THandle; const aResponse: string);
  protected
    procedure Execute; override;
  public
    constructor Create(const aPipeName: string);
    destructor Destroy; override;
    function WaitUntilReady(aTimeoutMs: Cardinal): Boolean;
    procedure RequestStop;
    property PipeName: string read fPipeName;
    property PipePath: string read fPipePath;
    property ReadyError: string read fReadyError;
  end;

var
  gPipeServerLock: TObject;
  gPipeServerThread: TAccessibilityAgentBridgePipeServerThread;

function NormalizePipeName(const aPipeName: string): string;
begin
  Result := aPipeName.Trim;
  if Result = '' then
  begin
    Result := TAccessibilityAgentBridgePipeServer.DefaultPipeName;
  end;
end;

constructor TAccessibilityAgentBridgePipeServerThread.Create(const aPipeName: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  fCurrentPipe := INVALID_HANDLE_VALUE;
  fLock := TObject.Create;
  try
    fReadyEvent := TEvent.Create(nil, True, False, '');
    fPipeName := aPipeName;
    fPipePath := TAccessibilityAgentBridgePipeServer.PipePath(aPipeName);
  except
    fReadyEvent.Free;
    fLock.Free;
    raise;
  end;
end;

destructor TAccessibilityAgentBridgePipeServerThread.Destroy;
begin
  fReadyEvent.Free;
  fLock.Free;
  inherited Destroy;
end;

function TAccessibilityAgentBridgePipeServerThread.CurrentPipe: THandle;
begin
  TMonitor.Enter(fLock);
  try
    Result := fCurrentPipe;
  finally
    TMonitor.Exit(fLock);
  end;
end;

procedure TAccessibilityAgentBridgePipeServerThread.Execute;
var
  lConnected: Boolean;
  lError: DWORD;
  lPipe: THandle;
  lReadyMarked: Boolean;
begin
  lReadyMarked := False;
  while not Terminated do
  begin
    lPipe := CreateNamedPipe(PChar(fPipePath), PIPE_ACCESS_DUPLEX,
      PIPE_TYPE_BYTE or PIPE_READMODE_BYTE or PIPE_WAIT or cPipeRejectRemoteClients, 1, cPipeBufferSize,
      cPipeBufferSize, 0, nil);
    if lPipe = INVALID_HANDLE_VALUE then
    begin
      MarkReady(SysErrorMessage(GetLastError));
      Exit;
    end;

    SetCurrentPipe(lPipe);
    if not lReadyMarked then
    begin
      MarkReady('');
      lReadyMarked := True;
    end;

    try
      lConnected := ConnectNamedPipe(lPipe, nil);
      if not lConnected then
      begin
        lError := GetLastError;
        lConnected := lError = ERROR_PIPE_CONNECTED;
      end;

      try
        if lConnected and not Terminated then
        begin
          HandleClient(lPipe);
        end;
      except
        on lException: Exception do
        begin
          ReportClientException(lException);
        end;
      end;
      DisconnectNamedPipe(lPipe);
    finally
      SetCurrentPipe(INVALID_HANDLE_VALUE);
      CloseHandle(lPipe);
    end;
  end;
end;

function TAccessibilityAgentBridgePipeServerThread.ExecuteBridge(const aRequest: string): string;
var
  lResponse: string;
begin
  if GetCurrentThreadId = MainThreadID then
  begin
    Exit(TAccessibilityAgentBridge.Execute(aRequest));
  end;

  lResponse := '';
  TThread.Synchronize(nil,
    procedure
    begin
      lResponse := TAccessibilityAgentBridge.Execute(aRequest);
    end);
  Result := lResponse;
end;

procedure TAccessibilityAgentBridgePipeServerThread.HandleClient(aPipe: THandle);
var
  lRequest: string;
  lResponse: string;
begin
  if not ReadRequest(aPipe, lRequest) then
  begin
    Exit;
  end;

  lResponse := ExecuteBridge(lRequest);
  WriteResponse(aPipe, lResponse);
end;

procedure TAccessibilityAgentBridgePipeServerThread.MarkReady(const aError: string);
begin
  fReadyError := aError;
  fReadyEvent.SetEvent;
end;

procedure TAccessibilityAgentBridgePipeServerThread.ReportClientException(aException: Exception);
begin
  if Terminated then
  begin
    Exit;
  end;

  OutputDebugString(PChar('MaxLogic accessibility agent bridge pipe request failed: ' + aException.ClassName + ': ' +
    aException.Message));
end;

function TAccessibilityAgentBridgePipeServerThread.ReadRequest(aPipe: THandle; out aRequest: string): Boolean;
var
  i: Integer;
  lBuffer: array[0..511] of Byte;
  lBytes: TBytes;
  lBytesRead: DWORD;
  lError: DWORD;
  lLength: Integer;
begin
  SetLength(lBytes, 0);
  while not Terminated do
  begin
    if not ReadFile(aPipe, lBuffer, SizeOf(lBuffer), lBytesRead, nil) then
    begin
      lError := GetLastError;
      if (lError = ERROR_BROKEN_PIPE) or (lError = ERROR_OPERATION_ABORTED) then
      begin
        aRequest := '';
        Exit(False);
      end;
      RaiseLastOSError(lError);
    end;

    if lBytesRead = 0 then
    begin
      aRequest := '';
      Exit(False);
    end;

    for i := 0 to Pred(lBytesRead) do
    begin
      if lBuffer[i] = 10 then
      begin
        aRequest := TEncoding.UTF8.GetString(lBytes);
        Exit(True);
      end;

      if lBuffer[i] <> 13 then
      begin
        lLength := Length(lBytes);
        SetLength(lBytes, Succ(lLength));
        lBytes[lLength] := lBuffer[i];
      end;
    end;
  end;

  aRequest := '';
  Result := False;
end;

procedure TAccessibilityAgentBridgePipeServerThread.RequestStop;
var
  lPipe: THandle;
begin
  Terminate;
  if Handle <> 0 then
  begin
    CancelSynchronousIo(Handle);
  end;

  if CurrentPipe <> INVALID_HANDLE_VALUE then
  begin
    lPipe := CreateFile(PChar(fPipePath), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);
    if lPipe <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle(lPipe);
    end;
  end;
end;

procedure TAccessibilityAgentBridgePipeServerThread.SetCurrentPipe(aPipe: THandle);
begin
  TMonitor.Enter(fLock);
  try
    fCurrentPipe := aPipe;
  finally
    TMonitor.Exit(fLock);
  end;
end;

function TAccessibilityAgentBridgePipeServerThread.WaitUntilReady(aTimeoutMs: Cardinal): Boolean;
begin
  Result := fReadyEvent.WaitFor(aTimeoutMs) = TWaitResult.wrSignaled;
end;

procedure TAccessibilityAgentBridgePipeServerThread.WriteResponse(aPipe: THandle; const aResponse: string);
var
  lBytes: TBytes;
  lBytesWritten: DWORD;
begin
  lBytes := TEncoding.UTF8.GetBytes(aResponse + #10);
  if (Length(lBytes) > 0) and not WriteFile(aPipe, lBytes[0], DWORD(Length(lBytes)), lBytesWritten, nil) then
  begin
    RaiseLastOSError;
  end;
  FlushFileBuffers(aPipe);
end;

class function TAccessibilityAgentBridgePipeServer.DefaultPipeName: string;
begin
  Result := Format('MaxLogicAccessibilityAgentBridge.%d', [GetCurrentProcessId]);
end;

class function TAccessibilityAgentBridgePipeServer.PipeName: string;
begin
  TMonitor.Enter(gPipeServerLock);
  try
    if gPipeServerThread = nil then
    begin
      Exit('');
    end;
    Result := gPipeServerThread.PipeName;
  finally
    TMonitor.Exit(gPipeServerLock);
  end;
end;

class function TAccessibilityAgentBridgePipeServer.PipePath(const aPipeName: string): string;
var
  lPipeName: string;
begin
  lPipeName := aPipeName.Trim;
  if lPipeName = '' then
  begin
    raise EArgumentException.Create('Pipe name must not be empty.');
  end;

  if SameText(Copy(lPipeName, 1, Length(cPipePrefix)), cPipePrefix) then
  begin
    Result := lPipeName;
  end else begin
    Result := cPipePrefix + lPipeName;
  end;
end;

class function TAccessibilityAgentBridgePipeServer.Running: Boolean;
begin
  TMonitor.Enter(gPipeServerLock);
  try
    Result := (gPipeServerThread <> nil) and not gPipeServerThread.Finished;
  finally
    TMonitor.Exit(gPipeServerLock);
  end;
end;

class procedure TAccessibilityAgentBridgePipeServer.Start(const aPipeName: string);
var
  lPipeName: string;
  lThread: TAccessibilityAgentBridgePipeServerThread;
begin
  lPipeName := NormalizePipeName(aPipeName);
  TMonitor.Enter(gPipeServerLock);
  try
    if (gPipeServerThread <> nil) and not gPipeServerThread.Finished then
    begin
      if SameText(gPipeServerThread.PipeName, lPipeName) then
      begin
        Exit;
      end;
      raise Exception.CreateFmt('Agent bridge pipe server is already running as "%s".',
        [gPipeServerThread.PipeName]);
    end;

    FreeAndNil(gPipeServerThread);
    lThread := TAccessibilityAgentBridgePipeServerThread.Create(lPipeName);
    try
      gPipeServerThread := lThread;
      lThread.Start;
      if not lThread.WaitUntilReady(cReadyTimeoutMs) then
      begin
        gPipeServerThread := nil;
        lThread.RequestStop;
        lThread.WaitFor;
        raise Exception.Create('Timed out while starting agent bridge pipe server.');
      end;

      if lThread.ReadyError <> '' then
      begin
        gPipeServerThread := nil;
        lThread.RequestStop;
        lThread.WaitFor;
        raise Exception.Create('Could not start agent bridge pipe server: ' + lThread.ReadyError);
      end;
    except
      if gPipeServerThread = lThread then
      begin
        gPipeServerThread := nil;
      end;
      lThread.Free;
      raise;
    end;
  finally
    TMonitor.Exit(gPipeServerLock);
  end;
end;

class procedure TAccessibilityAgentBridgePipeServer.Stop;
var
  lThread: TAccessibilityAgentBridgePipeServerThread;
begin
  TMonitor.Enter(gPipeServerLock);
  try
    lThread := gPipeServerThread;
    gPipeServerThread := nil;
  finally
    TMonitor.Exit(gPipeServerLock);
  end;

  if lThread = nil then
  begin
    Exit;
  end;

  lThread.RequestStop;
  lThread.WaitFor;
  lThread.Free;
end;

initialization
  gPipeServerLock := TObject.Create;

finalization
  TAccessibilityAgentBridgePipeServer.Stop;
  FreeAndNil(gPipeServerLock);

end.
