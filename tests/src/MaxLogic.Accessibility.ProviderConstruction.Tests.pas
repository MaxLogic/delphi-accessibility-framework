unit MaxLogic.Accessibility.ProviderConstruction.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('ProviderConstruction')]
  TAccessibilityProviderConstructionTests = class
  public
    [Test]
    procedure ActivatedTabSupportsFocusNavigationHitTestAndSelection;
    [Test]
    procedure FirstActivationPublishesOneStructureChange;
    [Test]
    procedure RuntimeAdditionToDeferredTabWaitsForActivation;
    [Test]
    procedure RetainedProviderUsesLiveCaptionAndDisconnectsAfterDestroy;
    [Test]
    procedure TabActivationWithoutLabelsMaterializesProviders;
    [Test]
    procedure ReparentIntoDeferredTabPreservesIdentityWithoutMaterializingSiblings;
    [Test]
    procedure FirstTabActivationMaterializesAndRetainsProviders;
    [Test]
    procedure InitialConstructionDefersInactiveTabDescendants;
    [Test]
    [Category('ProviderConstructionPerformance')]
    procedure LargeTabbedFormReportsConstructionMetrics;
  end;

implementation

uses
  System.Diagnostics, System.Generics.Collections, System.SysUtils, System.Types, System.Variants,
  Winapi.Windows,
  Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls,
  MaxLogic.Accessibility.Manager, MaxLogic.Accessibility.ProviderCore, MaxLogic.Accessibility.UIAutomationCore,
  MaxLogic.Accessibility.VclAdapters;

const
  cControlCountPerTab = 23;
  cLabelCountPerTab = cControlCountPerTab - 1;
  cSampleCount = 7;
  cTabCount = 26;

type
  IProviderConstructionUiaRecorder = interface(IAccessibilityUiaApi)
    ['{C8EE02E6-1B2C-4FA4-A24F-EDE0C8977105}']
    function LastStructureChangeType: StructureChangeType;
    procedure ResetStructureCalls;
    function StructureCalls: Integer;
  end;

  // The real UIA listener bus is externally timed, so exact event counts require a deterministic boundary recorder.
  TProviderConstructionUiaRecorder = class(TInterfacedObject, IAccessibilityUiaApi,
    IProviderConstructionUiaRecorder)
  private
    fLastStructureChangeType: StructureChangeType;
    fStructureCalls: Integer;
  public
    function ClientsAreListening: Boolean;
    function DisconnectProvider(const aProvider: IRawElementProviderSimple): HRESULT;
    function HostProviderFromHwnd(aHwnd: HWND; out aProvider: IRawElementProviderSimple): HRESULT;
    function LastStructureChangeType: StructureChangeType;
    function RaiseAutomationEvent(const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
    function RaiseAutomationPropertyChanged(const aProvider: IRawElementProviderSimple;
      aPropertyId: PROPERTYID; const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
    function RaiseNotification(const aProvider: IRawElementProviderSimple;
      aNotificationKind: NotificationKind; aNotificationProcessing: NotificationProcessing;
      const aDisplayString: WideString; const aActivityId: WideString): HRESULT;
    function RaiseStructureChanged(const aProvider: IRawElementProviderSimple;
      aStructureChangeType: StructureChangeType; const aRuntimeId: TArray<Integer>): HRESULT;
    procedure ResetStructureCalls;
    function ReturnRawElementProvider(aHwnd: HWND; aWParam: WPARAM; aLParam: LPARAM;
      const aProvider: IRawElementProviderSimple): LRESULT;
    function StructureCalls: Integer;
  end;

  TProviderConstructionFormFixture = class
  private
    fControls: TList<TControl>;
    fForm: TForm;
    fLabels: TArray<TLabel>;
    fPageControl: TPageControl;
    fPanels: TArray<TPanel>;
    fTabSheets: TArray<TTabSheet>;
    function ControlIsActive(aControl: TControl): Boolean;
    function FindProviderSubtree(const aProvider: IRawElementProviderSimple;
      aControl: TControl; out aControlProvider: IRawElementProviderSimple): Boolean;
    procedure CountProviderSubtree(const aProvider: IRawElementProviderSimple;
      var aActiveCount: Integer; var aInactiveCount: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ActivateTab(aIndex: Integer);
    procedure ConstructedProviderCounts(const aProvider: IAccessibilityProviderNode;
      out aActiveCount: Integer; out aInactiveCount: Integer);
    function ExpectedActiveProviderCount: Integer;
    function ExpectedProviderCount: Integer;
    function FindProviderForControl(const aProvider: IAccessibilityProviderNode;
      aControl: TControl; out aControlProvider: IRawElementProviderSimple): Boolean;
    function LabelForTab(aIndex: Integer): TLabel;
    function PanelForTab(aIndex: Integer): TPanel;
    function TabSheet(aIndex: Integer): TTabSheet;
    property Form: TForm read fForm;
  end;

function TProviderConstructionUiaRecorder.ClientsAreListening: Boolean;
begin
  Result := True;
end;

function TProviderConstructionUiaRecorder.DisconnectProvider(
  const aProvider: IRawElementProviderSimple): HRESULT;
begin
  Result := S_OK;
end;

function TProviderConstructionUiaRecorder.HostProviderFromHwnd(aHwnd: HWND;
  out aProvider: IRawElementProviderSimple): HRESULT;
begin
  aProvider := nil;
  Result := S_FALSE;
end;

function TProviderConstructionUiaRecorder.LastStructureChangeType: StructureChangeType;
begin
  Result := fLastStructureChangeType;
end;

function TProviderConstructionUiaRecorder.RaiseAutomationEvent(
  const aProvider: IRawElementProviderSimple; aEventId: EVENTID): HRESULT;
begin
  Result := S_OK;
end;

function TProviderConstructionUiaRecorder.RaiseAutomationPropertyChanged(
  const aProvider: IRawElementProviderSimple; aPropertyId: PROPERTYID;
  const aOldValue: OleVariant; const aNewValue: OleVariant): HRESULT;
begin
  Result := S_OK;
end;

function TProviderConstructionUiaRecorder.RaiseNotification(
  const aProvider: IRawElementProviderSimple; aNotificationKind: NotificationKind;
  aNotificationProcessing: NotificationProcessing; const aDisplayString: WideString;
  const aActivityId: WideString): HRESULT;
begin
  Result := S_OK;
end;

function TProviderConstructionUiaRecorder.RaiseStructureChanged(
  const aProvider: IRawElementProviderSimple; aStructureChangeType: StructureChangeType;
  const aRuntimeId: TArray<Integer>): HRESULT;
begin
  Inc(fStructureCalls);
  fLastStructureChangeType := aStructureChangeType;
  Result := S_OK;
end;

procedure TProviderConstructionUiaRecorder.ResetStructureCalls;
begin
  fStructureCalls := 0;
end;

function TProviderConstructionUiaRecorder.ReturnRawElementProvider(aHwnd: HWND;
  aWParam: WPARAM; aLParam: LPARAM; const aProvider: IRawElementProviderSimple): LRESULT;
begin
  Result := 0;
end;

function TProviderConstructionUiaRecorder.StructureCalls: Integer;
begin
  Result := fStructureCalls;
end;

procedure RunManagerIdle;
var
  lDone: Boolean;
begin
  lDone := False;
  if Assigned(Application.OnIdle) then
  begin
    Application.OnIdle(Application, lDone);
  end;
  Assert.IsFalse(lDone, 'Provider synchronization must not request continuous idle processing.');
end;

constructor TProviderConstructionFormFixture.Create;
var
  i: Integer;
  j: Integer;
  lLabel: TLabel;
  lPanel: TPanel;
  lTabSheet: TTabSheet;
begin
  inherited Create;
  fControls := TList<TControl>.Create;
  fForm := TForm.Create(nil);
  fForm.SetBounds(100, 100, 1200, 800);

  fPageControl := TPageControl.Create(fForm);
  fPageControl.Parent := fForm;
  fPageControl.Align := alClient;
  fControls.Add(fPageControl);

  SetLength(fTabSheets, cTabCount);
  SetLength(fLabels, cTabCount);
  SetLength(fPanels, cTabCount);
  for i := 0 to Pred(cTabCount) do
  begin
    lTabSheet := TTabSheet.Create(fForm);
    lTabSheet.Caption := Format('Section %d', [Succ(i)]);
    lTabSheet.PageControl := fPageControl;
    fTabSheets[i] := lTabSheet;
    fControls.Add(lTabSheet);

    lPanel := TPanel.Create(fForm);
    lPanel.Parent := lTabSheet;
    lPanel.Caption := Format('Section %d content', [Succ(i)]);
    lPanel.Align := alClient;
    fPanels[i] := lPanel;
    fControls.Add(lPanel);

    for j := 0 to Pred(cLabelCountPerTab) do
    begin
      lLabel := TLabel.Create(fForm);
      lLabel.Parent := lPanel;
      lLabel.Caption := Format('Section %d field %d', [Succ(i), Succ(j)]);
      lLabel.SetBounds(12 + ((j mod 2) * 260), 12 + ((j div 2) * 28), 240, 24);
      if j = 0 then
      begin
        fLabels[i] := lLabel;
      end;
      fControls.Add(lLabel);
    end;
  end;

  fPageControl.ActivePage := fTabSheets[0];
  fForm.HandleNeeded;
  fPageControl.HandleNeeded;
end;

function TProviderConstructionFormFixture.FindProviderSubtree(
  const aProvider: IRawElementProviderSimple; aControl: TControl;
  out aControlProvider: IRawElementProviderSimple): Boolean;
var
  i: Integer;
  lAccess: IAccessibilityProviderChildAccess;
  lChildCount: Integer;
  lChildProvider: IRawElementProviderSimple;
  lControlInfo: IAccessibilityVclControlProviderInfo;
begin
  aControlProvider := nil;
  if Supports(aProvider, IAccessibilityVclControlProviderInfo, lControlInfo) and
    (lControlInfo.Control = aControl) then
  begin
    aControlProvider := aProvider;
    Exit(True);
  end;

  if not Supports(aProvider, IAccessibilityProviderChildAccess, lAccess) then
  begin
    Exit(False);
  end;
  Assert.AreEqual(S_OK, lAccess.DirectChildCount(lChildCount));
  for i := 0 to Pred(lChildCount) do
  begin
    Assert.AreEqual(S_OK, lAccess.DirectChildAt(i, lChildProvider));
    if FindProviderSubtree(lChildProvider, aControl, aControlProvider) then
    begin
      Exit(True);
    end;
  end;
  Result := False;
end;

destructor TProviderConstructionFormFixture.Destroy;
begin
  fForm.Free;
  fControls.Free;
  inherited Destroy;
end;

procedure TProviderConstructionFormFixture.ActivateTab(aIndex: Integer);
begin
  fPageControl.ActivePage := fTabSheets[aIndex];
  fPageControl.Update;
end;

function TProviderConstructionFormFixture.ControlIsActive(aControl: TControl): Boolean;
var
  lParent: TWinControl;
begin
  if aControl is TTabSheet then
  begin
    Exit(True);
  end;

  lParent := aControl.Parent;
  while lParent <> nil do
  begin
    if lParent is TTabSheet then
    begin
      Exit(fPageControl.ActivePage = TTabSheet(lParent));
    end;
    lParent := lParent.Parent;
  end;
  Result := True;
end;

procedure TProviderConstructionFormFixture.CountProviderSubtree(
  const aProvider: IRawElementProviderSimple; var aActiveCount: Integer;
  var aInactiveCount: Integer);
var
  i: Integer;
  lAccess: IAccessibilityProviderChildAccess;
  lChildCount: Integer;
  lChildProvider: IRawElementProviderSimple;
  lControlInfo: IAccessibilityVclControlProviderInfo;
begin
  if Supports(aProvider, IAccessibilityVclControlProviderInfo, lControlInfo) then
  begin
    if ControlIsActive(lControlInfo.Control) then
    begin
      Inc(aActiveCount);
    end else begin
      Inc(aInactiveCount);
    end;
  end;

  if not Supports(aProvider, IAccessibilityProviderChildAccess, lAccess) then
  begin
    Exit;
  end;
  Assert.AreEqual(S_OK, lAccess.DirectChildCount(lChildCount));
  for i := 0 to Pred(lChildCount) do
  begin
    Assert.AreEqual(S_OK, lAccess.DirectChildAt(i, lChildProvider));
    Assert.IsNotNull(lChildProvider);
    CountProviderSubtree(lChildProvider, aActiveCount, aInactiveCount);
  end;
end;

procedure TProviderConstructionFormFixture.ConstructedProviderCounts(
  const aProvider: IAccessibilityProviderNode; out aActiveCount: Integer;
  out aInactiveCount: Integer);
begin
  aActiveCount := 0;
  aInactiveCount := 0;
  CountProviderSubtree(aProvider.RawElementProvider, aActiveCount, aInactiveCount);
end;

function TProviderConstructionFormFixture.ExpectedActiveProviderCount: Integer;
begin
  Result := 1 + cTabCount + cControlCountPerTab;
end;

function TProviderConstructionFormFixture.ExpectedProviderCount: Integer;
begin
  Result := fControls.Count;
end;

function TProviderConstructionFormFixture.FindProviderForControl(
  const aProvider: IAccessibilityProviderNode; aControl: TControl;
  out aControlProvider: IRawElementProviderSimple): Boolean;
begin
  Result := FindProviderSubtree(aProvider.RawElementProvider, aControl, aControlProvider);
end;

function TProviderConstructionFormFixture.LabelForTab(aIndex: Integer): TLabel;
begin
  Result := fLabels[aIndex];
end;

function TProviderConstructionFormFixture.PanelForTab(aIndex: Integer): TPanel;
begin
  Result := fPanels[aIndex];
end;

function TProviderConstructionFormFixture.TabSheet(aIndex: Integer): TTabSheet;
begin
  Result := fTabSheets[aIndex];
end;

procedure TAccessibilityProviderConstructionTests.ActivatedTabSupportsFocusNavigationHitTestAndSelection;
var
  lButton: TButton;
  lButtonFragment: IRawElementProviderFragment;
  lButtonProvider: IRawElementProviderSimple;
  lFixture: TProviderConstructionFormFixture;
  lFocusProvider: IRawElementProviderFragment;
  lHitProvider: IRawElementProviderFragment;
  lParentFragment: IRawElementProviderFragment;
  lPattern: IUnknown;
  lPoint: TPoint;
  lProvider: IAccessibilityProviderNode;
  lRoot: IRawElementProviderFragmentRoot;
  lRootProvider: IRawElementProviderSimple;
  lSelected: BOOL;
  lSelectionItem: ISelectionItemProvider;
  lTabProvider: IRawElementProviderSimple;
begin
  TAccessibilityManager.Uninstall;
  lFixture := TProviderConstructionFormFixture.Create;
  try
    lButton := TButton.Create(lFixture.Form);
    lButton.Parent := lFixture.PanelForTab(1);
    lButton.Caption := 'Activated action';
    lButton.SetBounds(600, 20, 160, 32);
    lFixture.Form.Show;
    lFixture.Form.Update;

    TAccessibilityManager.Install(lFixture.Form);
    Assert.IsTrue(TAccessibilityManagerInternals.TryGetInstalledFormProvider(
      lFixture.Form, lRootProvider));
    Assert.IsTrue(Supports(lRootProvider, IAccessibilityProviderNode, lProvider));
    Assert.IsTrue(Supports(lRootProvider, IRawElementProviderFragmentRoot, lRoot));

    lFixture.ActivateTab(1);
    RunManagerIdle;
    Assert.IsTrue(lFixture.FindProviderForControl(lProvider, lButton, lButtonProvider));
    Assert.IsTrue(Supports(lButtonProvider, IRawElementProviderFragment, lButtonFragment));

    Assert.AreEqual(S_OK, lButtonFragment.Navigate(NavigateDirection_Parent, lParentFragment));
    Assert.IsNotNull(lParentFragment, 'The activated control must join fragment navigation.');

    lButton.SetFocus;
    Assert.AreEqual(S_OK, lRoot.GetFocus(lFocusProvider));
    Assert.IsNull(lFocusProvider,
      'Standard HWND focus must remain on the native accessibility path after activation.');

    lPoint := lButton.ClientToScreen(Point(lButton.ClientWidth div 2, lButton.ClientHeight div 2));
    Assert.AreEqual(S_OK, lRoot.ElementProviderFromPoint(lPoint.X, lPoint.Y, lHitProvider));
    Assert.IsTrue((lHitProvider as IUnknown) = (lButtonProvider as IUnknown),
      'The activated control must participate in hit testing.');

    Assert.IsTrue(lFixture.FindProviderForControl(lProvider,
      lFixture.TabSheet(1), lTabProvider));
    Assert.AreEqual(S_OK, lTabProvider.GetPatternProvider(UIA_SelectionItemPatternId, lPattern));
    Assert.IsTrue(Supports(lPattern, ISelectionItemProvider, lSelectionItem));
    Assert.AreEqual(S_OK, lSelectionItem.Get_IsSelected(lSelected));
    Assert.IsTrue(lSelected, 'The active tab header must expose selected state.');
  finally
    lProvider := nil;
    lRootProvider := nil;
    lFixture.Free;
    TAccessibilityManager.Uninstall;
  end;
end;

procedure TAccessibilityProviderConstructionTests.FirstActivationPublishesOneStructureChange;
var
  lApi: IProviderConstructionUiaRecorder;
  lFixture: TProviderConstructionFormFixture;
begin
  TAccessibilityManager.Uninstall;
  lApi := TProviderConstructionUiaRecorder.Create;
  TAccessibilityManagerInternals.SetUiaApi(lApi);
  lFixture := TProviderConstructionFormFixture.Create;
  try
    TAccessibilityManager.Install(lFixture.Form);
    lApi.ResetStructureCalls;

    lFixture.ActivateTab(1);
    RunManagerIdle;
    RunManagerIdle;

    Assert.AreEqual(1, lApi.StructureCalls,
      'First activation must publish exactly one structure change across consecutive idle cycles.');
    Assert.AreEqual(StructureChangeType_ChildrenInvalidated,
      lApi.LastStructureChangeType);
  finally
    lFixture.Free;
    TAccessibilityManager.Uninstall;
    TAccessibilityManagerInternals.SetUiaApi(nil);
  end;
end;

procedure TAccessibilityProviderConstructionTests.RuntimeAdditionToDeferredTabWaitsForActivation;
var
  lAddedLabel: TLabel;
  lFixture: TProviderConstructionFormFixture;
  lProvider: IAccessibilityProviderNode;
  lRootProvider: IRawElementProviderSimple;
  lRuntimeProvider: IRawElementProviderSimple;
  lValue: OleVariant;
begin
  TAccessibilityManager.Uninstall;
  lFixture := TProviderConstructionFormFixture.Create;
  try
    TAccessibilityManager.Install(lFixture.Form);
    Assert.IsTrue(TAccessibilityManagerInternals.TryGetInstalledFormProvider(
      lFixture.Form, lRootProvider));
    Assert.IsTrue(Supports(lRootProvider, IAccessibilityProviderNode, lProvider));

    lAddedLabel := TLabel.Create(lFixture.Form);
    lAddedLabel.Parent := lFixture.PanelForTab(2);
    lAddedLabel.Caption := 'Added before first visit';
    RunManagerIdle;
    Assert.IsFalse(lFixture.FindProviderForControl(lProvider, lAddedLabel, lRuntimeProvider),
      'Runtime additions to never-visited tabs must remain deferred.');

    lFixture.ActivateTab(2);
    RunManagerIdle;
    Assert.IsTrue(lFixture.FindProviderForControl(lProvider, lAddedLabel, lRuntimeProvider),
      'First activation must materialize runtime additions using current VCL state.');
    Assert.AreEqual(S_OK, lRuntimeProvider.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.AreEqual('Added before first visit', string(lValue));
  finally
    lProvider := nil;
    lRuntimeProvider := nil;
    lRootProvider := nil;
    lFixture.Free;
    TAccessibilityManager.Uninstall;
  end;
end;

procedure TAccessibilityProviderConstructionTests.RetainedProviderUsesLiveCaptionAndDisconnectsAfterDestroy;
var
  lFixture: TProviderConstructionFormFixture;
  lLabel: TLabel;
  lProvider: IAccessibilityProviderNode;
  lRootProvider: IRawElementProviderSimple;
  lRetainedProvider: IRawElementProviderSimple;
  lValue: OleVariant;
begin
  TAccessibilityManager.Uninstall;
  lFixture := TProviderConstructionFormFixture.Create;
  try
    TAccessibilityManager.Install(lFixture.Form);
    Assert.IsTrue(TAccessibilityManagerInternals.TryGetInstalledFormProvider(
      lFixture.Form, lRootProvider));
    Assert.IsTrue(Supports(lRootProvider, IAccessibilityProviderNode, lProvider));
    lLabel := lFixture.LabelForTab(0);
    Assert.IsTrue(lFixture.FindProviderForControl(lProvider, lLabel, lRetainedProvider));

    lFixture.ActivateTab(1);
    RunManagerIdle;
    lLabel.Caption := 'Updated while inactive';
    Assert.AreEqual(S_OK, lRetainedProvider.GetPropertyValue(UIA_NamePropertyId, lValue));
    Assert.AreEqual('Updated while inactive', string(lValue),
      'Retained providers must read cheap VCL text properties live.');

    lLabel.Free;
    RunManagerIdle;
    Assert.AreEqual(UIA_E_ELEMENTNOTAVAILABLE,
      lRetainedProvider.GetPropertyValue(UIA_NamePropertyId, lValue),
      'A provider must disconnect when its VCL control is destroyed.');
    Assert.IsTrue(VarIsEmpty(lValue), 'A disconnected provider must clear its property result.');
  finally
    lProvider := nil;
    lRetainedProvider := nil;
    lRootProvider := nil;
    lFixture.Free;
    TAccessibilityManager.Uninstall;
  end;
end;

procedure TAccessibilityProviderConstructionTests.TabActivationWithoutLabelsMaterializesProviders;
var
  lButton: TButton;
  lButtonProvider: IRawElementProviderSimple;
  lForm: TForm;
  lLookup: IAccessibilityVclProviderLookup;
  lPageControl: TPageControl;
  lRootProvider: IRawElementProviderSimple;
  lTabOne: TTabSheet;
  lTabTwo: TTabSheet;
begin
  TAccessibilityManager.Uninstall;
  lForm := TForm.Create(nil);
  try
    lPageControl := TPageControl.Create(lForm);
    lPageControl.Parent := lForm;
    lPageControl.Align := alClient;

    lTabOne := TTabSheet.Create(lForm);
    lTabOne.Caption := 'First';
    lTabOne.PageControl := lPageControl;
    lButton := TButton.Create(lForm);
    lButton.Parent := lTabOne;
    lButton.Caption := 'First action';

    lTabTwo := TTabSheet.Create(lForm);
    lTabTwo.Caption := 'Second';
    lTabTwo.PageControl := lPageControl;
    lButton := TButton.Create(lForm);
    lButton.Parent := lTabTwo;
    lButton.Caption := 'Second action';

    lPageControl.ActivePage := lTabOne;
    lForm.HandleNeeded;
    lPageControl.HandleNeeded;
    TAccessibilityManager.Install(lForm);
    Assert.IsTrue(TAccessibilityManagerInternals.TryGetInstalledFormProvider(lForm, lRootProvider));
    Assert.IsTrue(Supports(lRootProvider, IAccessibilityVclProviderLookup, lLookup));

    lPageControl.ActivePage := lTabTwo;
    lPageControl.Update;
    RunManagerIdle;

    Assert.IsTrue(lLookup.TryFindProviderForControl(lButton, lButtonProvider),
      'A page selection must materialize controls without label relationships.');
  finally
    lButtonProvider := nil;
    lRootProvider := nil;
    lForm.Free;
    TAccessibilityManager.Uninstall;
  end;
end;

procedure TAccessibilityProviderConstructionTests.ReparentIntoDeferredTabPreservesIdentityWithoutMaterializingSiblings;
var
  lActiveCount: Integer;
  lAfterProvider: IRawElementProviderSimple;
  lBeforeProvider: IRawElementProviderSimple;
  lFixture: TProviderConstructionFormFixture;
  lInactiveCount: Integer;
  lMovedFragment: IRawElementProviderFragment;
  lParentControlInfo: IAccessibilityVclControlProviderInfo;
  lParentFragment: IRawElementProviderFragment;
  lParentProvider: IRawElementProviderSimple;
  lProvider: IAccessibilityProviderNode;
  lRootProvider: IRawElementProviderSimple;
  lUntouchedProvider: IRawElementProviderSimple;
begin
  TAccessibilityManager.Uninstall;
  lFixture := TProviderConstructionFormFixture.Create;
  try
    TAccessibilityManager.Install(lFixture.Form);
    Assert.IsTrue(TAccessibilityManagerInternals.TryGetInstalledFormProvider(
      lFixture.Form, lRootProvider));
    Assert.IsTrue(Supports(lRootProvider, IAccessibilityProviderNode, lProvider));
    Assert.IsTrue(lFixture.FindProviderForControl(lProvider,
      lFixture.LabelForTab(0), lBeforeProvider));

    lFixture.ActivateTab(1);
    RunManagerIdle;
    lFixture.LabelForTab(0).Parent := lFixture.PanelForTab(2);
    RunManagerIdle;

    Assert.IsTrue(lFixture.FindProviderForControl(lProvider,
      lFixture.LabelForTab(0), lAfterProvider));
    Assert.IsTrue((lBeforeProvider as IUnknown) = (lAfterProvider as IUnknown),
      'Reparenting must preserve the constructed provider identity.');
    Assert.IsTrue(Supports(lAfterProvider, IRawElementProviderFragment, lMovedFragment));
    Assert.AreEqual(S_OK, lMovedFragment.Navigate(NavigateDirection_Parent, lParentFragment));
    Assert.IsTrue(Supports(lParentFragment, IRawElementProviderSimple, lParentProvider));
    Assert.IsTrue(Supports(lParentProvider, IAccessibilityVclControlProviderInfo,
      lParentControlInfo));
    Assert.AreSame(lFixture.PanelForTab(2), lParentControlInfo.Control,
      'The retained provider must move below its new VCL parent.');
    Assert.IsFalse(lFixture.FindProviderForControl(lProvider,
      lFixture.LabelForTab(2), lUntouchedProvider),
      'Unvisited destination siblings must remain deferred.');

    lFixture.ConstructedProviderCounts(lProvider, lActiveCount, lInactiveCount);
    Assert.AreEqual(lFixture.ExpectedActiveProviderCount, lActiveCount);
    Assert.AreEqual(cControlCountPerTab + 1, lInactiveCount,
      'Only the moved provider and its missing destination panel may be added.');
  finally
    lProvider := nil;
    lRootProvider := nil;
    lFixture.Free;
    TAccessibilityManager.Uninstall;
  end;
end;

procedure TAccessibilityProviderConstructionTests.FirstTabActivationMaterializesAndRetainsProviders;
var
  lActiveCount: Integer;
  lFixture: TProviderConstructionFormFixture;
  lInactiveCount: Integer;
  lProvider: IAccessibilityProviderNode;
  lRootProvider: IRawElementProviderSimple;
begin
  TAccessibilityManager.Uninstall;
  lFixture := TProviderConstructionFormFixture.Create;
  try
    TAccessibilityManager.Install(lFixture.Form);
    Assert.IsTrue(TAccessibilityManagerInternals.TryGetInstalledFormProvider(
      lFixture.Form, lRootProvider));
    Assert.IsTrue(Supports(lRootProvider, IAccessibilityProviderNode, lProvider));

    lFixture.ActivateTab(1);
    RunManagerIdle;
    lFixture.ConstructedProviderCounts(lProvider, lActiveCount, lInactiveCount);

    Assert.AreEqual(lFixture.ExpectedActiveProviderCount, lActiveCount,
      'The newly active tab must materialize its complete provider subtree.');
    Assert.AreEqual(cControlCountPerTab, lInactiveCount,
      'The previously active tab providers must remain retained offscreen.');
  finally
    lProvider := nil;
    lRootProvider := nil;
    lFixture.Free;
    TAccessibilityManager.Uninstall;
  end;
end;

procedure TAccessibilityProviderConstructionTests.InitialConstructionDefersInactiveTabDescendants;
var
  lActiveCount: Integer;
  lFixture: TProviderConstructionFormFixture;
  lInactiveCount: Integer;
  lProvider: IAccessibilityProviderNode;
begin
  lFixture := TProviderConstructionFormFixture.Create;
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lFixture.Form);
    lFixture.ConstructedProviderCounts(lProvider, lActiveCount, lInactiveCount);

    Assert.AreEqual(lFixture.ExpectedActiveProviderCount, lActiveCount,
      'Initial construction must retain every tab header and the active tab content.');
    Assert.AreEqual(0, lInactiveCount,
      'Initial construction must defer descendants of never-visited inactive tabs.');
  finally
    lProvider := nil;
    lFixture.Free;
  end;
end;

procedure TAccessibilityProviderConstructionTests.LargeTabbedFormReportsConstructionMetrics;
var
  i: Integer;
  lActiveCount: Integer;
  lConstructedCount: Integer;
  lFixture: TProviderConstructionFormFixture;
  lMedianTicks: Int64;
  lInactiveCount: Integer;
  lP95Ticks: Int64;
  lProvider: IAccessibilityProviderNode;
  lSamples: TArray<Int64>;
  lStopwatch: TStopwatch;
begin
  lFixture := TProviderConstructionFormFixture.Create;
  try
    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lFixture.Form);
    Assert.IsNotNull(lProvider.RawElementProvider, 'Warmup construction must produce a form root.');
    lProvider := nil;

    SetLength(lSamples, cSampleCount);
    for i := 0 to Pred(cSampleCount) do
    begin
      lStopwatch := TStopwatch.StartNew;
      lProvider := TAccessibilityVclProviderBuilder.BuildForm(lFixture.Form);
      lSamples[i] := lStopwatch.ElapsedTicks;
      lProvider := nil;
    end;
    TArray.Sort<Int64>(lSamples);
    lMedianTicks := lSamples[cSampleCount div 2];
    lP95Ticks := lSamples[High(lSamples)];

    lProvider := TAccessibilityVclProviderBuilder.BuildForm(lFixture.Form);
    lFixture.ConstructedProviderCounts(lProvider, lActiveCount, lInactiveCount);
    lConstructedCount := lActiveCount + lInactiveCount;

    Writeln(Format(
      'PROVIDER_CONSTRUCTION_METRIC samples=%d tabs=%d nestedControls=%d totalControls=%d activeControls=%d constructedActive=%d constructedInactive=%d constructedTotal=%d medianTicks=%d p95Ticks=%d maxTicks=%d frequency=%d',
      [cSampleCount, cTabCount, cTabCount * cControlCountPerTab, lFixture.ExpectedProviderCount,
      lFixture.ExpectedActiveProviderCount, lActiveCount, lInactiveCount, lConstructedCount,
      lMedianTicks, lP95Ticks, lSamples[High(lSamples)], TStopwatch.Frequency]));
    Assert.AreEqual(625, lFixture.ExpectedProviderCount, 'Fixture total control count changed.');
    Assert.AreEqual(50, lFixture.ExpectedActiveProviderCount, 'Fixture active control count changed.');
    Assert.AreEqual(lFixture.ExpectedActiveProviderCount, lActiveCount,
      'Release construction must include tab headers and active tab content.');
    Assert.AreEqual(0, lInactiveCount,
      'Release construction must not create never-visited inactive tab descendants.');
    Assert.AreEqual(lFixture.ExpectedActiveProviderCount, lConstructedCount);
    Assert.IsTrue(lMedianTicks > 0, 'Median construction duration must be positive.');
  finally
    lProvider := nil;
    lFixture.Free;
  end;
end;

initialization

  TDUnitX.RegisterTestFixture(TAccessibilityProviderConstructionTests);

end.
