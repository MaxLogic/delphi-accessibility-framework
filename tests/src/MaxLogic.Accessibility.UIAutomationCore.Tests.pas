unit MaxLogic.Accessibility.UIAutomationCore.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('UIAutomationCore')]
  TUIAutomationCoreTests = class
  private
    procedure AssertInterfaceGuid(const aExpected: string; const aTypeInfo: Pointer);
  public
    [Test]
    procedure ConcurrentFirstWrapperUseResolvesExportOnce;
    [Test]
    procedure ConstantsMatchWindowsSdk;
    [Test]
    procedure InterfacesHaveExpectedGuids;
    [Test]
    procedure LoadedModuleIsPinnedForFinalizationSafety;
    [Test]
    procedure ImportWrapperFindsRequiredExports;
    [Test]
    procedure ImportWrapperUsesSystemDllSearchPolicy;
    [Test]
    procedure MissingExportKeepsDiagnosticException;
    [Test]
    procedure RepeatedWrapperCallsResolveEachExportOnce;
  end;

implementation

uses
  System.Classes, System.SyncObjs, System.SysUtils,
  System.TypInfo, System.Variants, Winapi.Windows,
  MaxLogic.Accessibility.UIAutomationCore;

procedure ExerciseAllWrappers(aCount: Integer);
var
  i: Integer;
  lNewValue: OleVariant;
  lNotSupportedValue: IUnknown;
  lOldValue: OleVariant;
  lProvider: IRawElementProviderSimple;
  lResultText: string;
  lRuntimeId: array[0..1] of Integer;
begin
  lNewValue := Unassigned;
  lOldValue := Unassigned;
  lResultText := '';
  for i := 1 to aCount do
  begin
    lResultText := lResultText + IntToStr(Integer(UiaClientsAreListening));
    lResultText := lResultText + IntToStr(UiaGetReservedNotSupportedValue(lNotSupportedValue));
    lResultText := lResultText + IntToStr(UiaHostProviderFromHwnd(GetDesktopWindow, lProvider));
    lResultText := lResultText + IntToStr(UiaReturnRawElementProvider(0, 0, UiaRootObjectId, nil));
    lResultText := lResultText + IntToStr(UiaDisconnectProvider(nil));
    lResultText := lResultText + IntToStr(UiaRaiseAutomationEvent(nil, UIA_AutomationFocusChangedEventId));
    lResultText := lResultText +
      IntToStr(UiaRaiseAutomationPropertyChangedEvent(nil, UIA_NamePropertyId, lOldValue, lNewValue));
    lRuntimeId[0] := UiaAppendRuntimeId;
    lRuntimeId[1] := i;
    lResultText := lResultText + IntToStr(UiaRaiseStructureChangedEvent(nil,
      StructureChangeType_ChildrenInvalidated, @lRuntimeId[0], Length(lRuntimeId)));
    lResultText := lResultText + IntToStr(UiaRaiseNotificationEvent(nil, NotificationKind_Other,
      NotificationProcessing_MostRecent, 'probe', 't111-' + IntToStr(i)));
  end;
  Assert.IsTrue(lResultText <> '', 'UIAutomationCore wrapper results were not observed.');
end;

procedure AssertExportAvailable(aExport: TUIAutomationCoreExport; const aName: string);
begin
  Assert.AreEqual(aName, TUIAutomationCoreImports.ExportName(aExport));
  Assert.IsTrue(TUIAutomationCoreImports.HasExport(aExport), Format('%s should be exported by UIAutomationCore.dll.', [aName]));
end;

procedure TUIAutomationCoreTests.AssertInterfaceGuid(const aExpected: string; const aTypeInfo: Pointer);
var
  lGuid: TGUID;
begin
  lGuid := GetTypeData(aTypeInfo)^.Guid;
  Assert.AreEqual(aExpected, GUIDToString(lGuid));
end;

procedure TUIAutomationCoreTests.ConcurrentFirstWrapperUseResolvesExportOnce;
const
  cThreadCount = 16;
var
  i: Integer;
  lClientsListeningCount: Integer;
  lDone: TCountdownEvent;
  lNoClientsListeningCount: Integer;
  lStart: TEvent;
  lThreads: TArray<TThread>;
begin
  TUIAutomationCoreInternals.ResetExportCache;
  lClientsListeningCount := 0;
  lNoClientsListeningCount := 0;
  lDone := TCountdownEvent.Create(cThreadCount);
  lStart := TEvent.Create(nil, True, False, '');
  SetLength(lThreads, cThreadCount);
  try
    for i := 0 to Pred(cThreadCount) do
    begin
      lThreads[i] := TThread.CreateAnonymousThread(
        procedure
        begin
          lStart.WaitFor(INFINITE);
          try
            if UiaClientsAreListening then
            begin
              TInterlocked.Increment(lClientsListeningCount);
            end else begin
              TInterlocked.Increment(lNoClientsListeningCount);
            end
          finally
            lDone.Signal;
          end;
        end);
      lThreads[i].FreeOnTerminate := False;
      lThreads[i].Start;
    end;

    lStart.SetEvent;
    Assert.AreEqual(wrSignaled, lDone.WaitFor(5000), 'Concurrent UIAutomationCore wrapper calls did not finish.');
    for i := 0 to Pred(cThreadCount) do
    begin
      lThreads[i].WaitFor;
      Assert.IsNull(lThreads[i].FatalException, Format('UIAutomationCore worker %d raised an exception.', [i]));
    end;
    Assert.AreEqual(cThreadCount, lClientsListeningCount + lNoClientsListeningCount,
      'Not every concurrent wrapper call returned.');
    Assert.AreEqual(1, TUIAutomationCoreInternals.ExportResolveCount(uiceClientsAreListening),
      'Concurrent first use resolved UiaClientsAreListening more than once.');
  finally
    lStart.SetEvent;
    for i := 0 to Pred(cThreadCount) do
    begin
      if lThreads[i] <> nil then
      begin
        lThreads[i].WaitFor;
        lThreads[i].Free;
      end;
    end;
    lStart.Free;
    lDone.Free;
  end;
end;

procedure TUIAutomationCoreTests.ConstantsMatchWindowsSdk;
begin
  Assert.AreEqual(Integer(-25), Integer(UiaRootObjectId));
  Assert.AreEqual(3, UiaAppendRuntimeId);

  Assert.AreEqual($00000002, ProviderOptions_ServerSideProvider);
  Assert.AreEqual($00000100, ProviderOptions_UseClientCoordinates);

  Assert.AreEqual(0, NavigateDirection_Parent);
  Assert.AreEqual(1, NavigateDirection_NextSibling);
  Assert.AreEqual(4, NavigateDirection_LastChild);

  Assert.AreEqual(0, TreeScope_None);
  Assert.AreEqual(1, TreeScope_Element);
  Assert.AreEqual(7, TreeScope_Subtree);

  Assert.AreEqual(50000, UIA_ButtonControlTypeId);
  Assert.AreEqual(50002, UIA_CheckBoxControlTypeId);
  Assert.AreEqual(50003, UIA_ComboBoxControlTypeId);
  Assert.AreEqual(50004, UIA_EditControlTypeId);
  Assert.AreEqual(50013, UIA_RadioButtonControlTypeId);
  Assert.AreEqual(50017, UIA_StatusBarControlTypeId);
  Assert.AreEqual(50018, UIA_TabControlTypeId);
  Assert.AreEqual(50020, UIA_TextControlTypeId);
  Assert.AreEqual(50021, UIA_ToolBarControlTypeId);
  Assert.AreEqual(50026, UIA_GroupControlTypeId);
  Assert.AreEqual(50028, UIA_DataGridControlTypeId);
  Assert.AreEqual(50029, UIA_DataItemControlTypeId);
  Assert.AreEqual(50032, UIA_WindowControlTypeId);
  Assert.AreEqual(50033, UIA_PaneControlTypeId);

  Assert.AreEqual(10000, UIA_InvokePatternId);
  Assert.AreEqual(10001, UIA_SelectionPatternId);
  Assert.AreEqual(10002, UIA_ValuePatternId);
  Assert.AreEqual(10006, UIA_GridPatternId);
  Assert.AreEqual(10007, UIA_GridItemPatternId);
  Assert.AreEqual(10010, UIA_SelectionItemPatternId);
  Assert.AreEqual(10012, UIA_TablePatternId);
  Assert.AreEqual(10013, UIA_TableItemPatternId);
  Assert.AreEqual(10015, UIA_TogglePatternId);

  Assert.AreEqual(30000, UIA_RuntimeIdPropertyId);
  Assert.AreEqual(30003, UIA_ControlTypePropertyId);
  Assert.AreEqual(30005, UIA_NamePropertyId);
  Assert.AreEqual(30013, UIA_HelpTextPropertyId);
  Assert.AreEqual(30016, UIA_IsControlElementPropertyId);
  Assert.AreEqual(30017, UIA_IsContentElementPropertyId);
  Assert.AreEqual(30079, UIA_SelectionItemIsSelectedPropertyId);
  Assert.AreEqual(30080, UIA_SelectionItemSelectionContainerPropertyId);
  Assert.AreEqual(30086, UIA_ToggleToggleStatePropertyId);
  Assert.AreEqual(30107, UIA_ProviderDescriptionPropertyId);

  Assert.AreEqual(20000, UIA_ToolTipOpenedEventId);
  Assert.AreEqual(20001, UIA_ToolTipClosedEventId);
  Assert.AreEqual(20004, UIA_AutomationPropertyChangedEventId);
  Assert.AreEqual(20005, UIA_AutomationFocusChangedEventId);
  Assert.AreEqual(20009, UIA_Invoke_InvokedEventId);
  Assert.AreEqual(20012, UIA_SelectionItem_ElementSelectedEventId);
  Assert.AreEqual(20035, UIA_NotificationEventId);

  Assert.AreEqual(SizeOf(Integer), SizeOf(TEXTATTRIBUTEID));
end;

procedure TUIAutomationCoreTests.LoadedModuleIsPinnedForFinalizationSafety;
var
  lListening: BOOL;
begin
  lListening := UiaClientsAreListening;
  Assert.IsTrue(TUIAutomationCoreInternals.ModulePinned,
    Format('Cached UIAutomationCore pointers require the loaded module to remain pinned through finalization ' +
      '(clients listening=%s).', [BoolToStr(lListening, True)]));
end;

procedure TUIAutomationCoreTests.ImportWrapperFindsRequiredExports;
begin
  Assert.AreEqual('UIAutomationCore.dll', TUIAutomationCoreImports.LibraryName);

  AssertExportAvailable(uiceClientsAreListening, 'UiaClientsAreListening');
  AssertExportAvailable(uiceGetReservedNotSupportedValue, 'UiaGetReservedNotSupportedValue');
  AssertExportAvailable(uiceHostProviderFromHwnd, 'UiaHostProviderFromHwnd');
  AssertExportAvailable(uiceReturnRawElementProvider, 'UiaReturnRawElementProvider');
  AssertExportAvailable(uiceDisconnectProvider, 'UiaDisconnectProvider');
  AssertExportAvailable(uiceRaiseAutomationEvent, 'UiaRaiseAutomationEvent');
  AssertExportAvailable(uiceRaiseAutomationPropertyChangedEvent, 'UiaRaiseAutomationPropertyChangedEvent');
  AssertExportAvailable(uiceRaiseStructureChangedEvent, 'UiaRaiseStructureChangedEvent');
  AssertExportAvailable(uiceRaiseNotificationEvent, 'UiaRaiseNotificationEvent');

  Assert.IsTrue(TUIAutomationCoreImports.RequiredExportsAvailable);
end;

procedure TUIAutomationCoreTests.ImportWrapperUsesSystemDllSearchPolicy;
begin
  Assert.AreEqual(Integer($00000800), Integer(TUIAutomationCoreImports.LibraryLoadFlags));
end;

procedure TUIAutomationCoreTests.MissingExportKeepsDiagnosticException;
var
  lProc: Pointer;
  lRaised: Boolean;
begin
  lProc := nil;
  lRaised := False;
  try
    lProc := TUIAutomationCoreInternals.ResolveNamedExport('MaxLogicMissingUiaExport');
  except
    on E: EExternalException do
    begin
      lRaised := True;
      Assert.Contains(E.Message, 'UI Automation Core export not found: MaxLogicMissingUiaExport');
    end;
  end;
  Assert.IsNull(lProc, 'A missing UIAutomationCore export unexpectedly returned an address.');
  Assert.IsTrue(lRaised, 'A missing UIAutomationCore export did not raise EExternalException.');
end;

procedure TUIAutomationCoreTests.RepeatedWrapperCallsResolveEachExportOnce;
var
  lExport: TUIAutomationCoreExport;
begin
  TUIAutomationCoreInternals.ResetExportCache;
  ExerciseAllWrappers(2);

  for lExport := Low(TUIAutomationCoreExport) to High(TUIAutomationCoreExport) do
  begin
    Assert.AreEqual(1, TUIAutomationCoreInternals.ExportResolveCount(lExport),
      Format('%s resolved more than once.', [TUIAutomationCoreImports.ExportName(lExport)]));
  end;
end;

procedure TUIAutomationCoreTests.InterfacesHaveExpectedGuids;
begin
  AssertInterfaceGuid('{D6DD68D1-86FD-4332-8666-9ABEDEA2D24C}', TypeInfo(IRawElementProviderSimple));
  AssertInterfaceGuid('{F7063DA8-8359-439C-9297-BBC5299A7D87}', TypeInfo(IRawElementProviderFragment));
  AssertInterfaceGuid('{620CE2A5-AB8F-40A9-86CB-DE3C75599B58}', TypeInfo(IRawElementProviderFragmentRoot));
  AssertInterfaceGuid('{A407B27B-0F6D-4427-9292-473C7BF93258}', TypeInfo(IRawElementProviderAdviseEvents));
  AssertInterfaceGuid('{54FCB24B-E18E-47A2-B4D3-ECCBE77599A2}', TypeInfo(IInvokeProvider));
  AssertInterfaceGuid('{C7935180-6FB3-4201-B174-7DF73ADBF64A}', TypeInfo(IValueProvider));
  AssertInterfaceGuid('{56D00BD0-C4F4-433C-A836-1A52A57E0892}', TypeInfo(IToggleProvider));
  AssertInterfaceGuid('{B17D6187-0907-464B-A168-0EF17A1572B1}', TypeInfo(IGridProvider));
  AssertInterfaceGuid('{D02541F1-FB81-4D64-AE32-F520F8A6DBD1}', TypeInfo(IGridItemProvider));
  AssertInterfaceGuid('{9C860395-97B3-490A-B52A-858CC22AF166}', TypeInfo(ITableProvider));
  AssertInterfaceGuid('{B9734FA6-771F-4D78-9C90-2517999349CD}', TypeInfo(ITableItemProvider));
  AssertInterfaceGuid('{FB8B03AF-3BDF-48D4-BD36-1A65793BE168}', TypeInfo(ISelectionProvider));
  AssertInterfaceGuid('{2ACAD808-B2D4-452D-A407-91FF1AD167B2}', TypeInfo(ISelectionItemProvider));
  AssertInterfaceGuid('{B38B8077-1FC3-42A5-8CAE-D40C2215055A}', TypeInfo(IScrollProvider));
  AssertInterfaceGuid('{3589C92C-63F3-4367-99BB-ADA653B77CF2}', TypeInfo(ITextProvider));
  AssertInterfaceGuid('{5347AD7B-C355-46F8-AFF5-909033582F63}', TypeInfo(ITextRangeProvider));
end;

initialization
  TDUnitX.RegisterTestFixture(TUIAutomationCoreTests);

end.
