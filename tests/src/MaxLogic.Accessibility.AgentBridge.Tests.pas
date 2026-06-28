unit MaxLogic.Accessibility.AgentBridge.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('AgentBridge')]
  TAccessibilityAgentBridgeTests = class
  public
    [Test]
    procedure HelloReportsFrameworkPresenceAndMutationGate;
    [Test]
    procedure WindowInfoReturnsGeometryAndDpi;
    [Test]
    procedure FormMapReturnsSnapshotRefsAndTargetPoints;
    [Test]
    procedure HitTestReturnsControlFromLastSnapshot;
    [Test]
    procedure MutationsAreGatedAndOperateOnLastSnapshotRefs;
  end;

implementation

uses
  System.Generics.Collections, System.JSON, System.SysUtils, System.Types, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  MaxLogic.Accessibility.AgentBridge, MaxLogic.Accessibility.Framework;

type
  TAgentBridgeClickRecorder = class
  private
    fClicks: Integer;
  public
    procedure Click(aSender: TObject);
    property Clicks: Integer read fClicks;
  end;

procedure TAgentBridgeClickRecorder.Click(aSender: TObject);
begin
  Inc(fClicks);
end;

function JsonObjectFrom(const aText: string): TJSONObject;
var
  lValue: TJSONValue;
begin
  lValue := TJSONObject.ParseJSONValue(aText, True, True);
  Assert.IsNotNull(lValue, 'JSON response was empty.');
  Assert.IsTrue(lValue is TJSONObject, 'JSON response is not an object.');
  Result := TJSONObject(lValue);
end;

function JsonObjectValue(aObject: TJSONObject; const aName: string): TJSONObject;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing object value: ' + aName);
  Assert.IsTrue(lValue is TJSONObject, 'Value is not an object: ' + aName);
  Result := TJSONObject(lValue);
end;

function JsonArrayValue(aObject: TJSONObject; const aName: string): TJSONArray;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing array value: ' + aName);
  Assert.IsTrue(lValue is TJSONArray, 'Value is not an array: ' + aName);
  Result := TJSONArray(lValue);
end;

function JsonText(aObject: TJSONObject; const aName: string): string;
var
  lValue: TJSONValue;
begin
  lValue := aObject.GetValue(aName);
  Assert.IsNotNull(lValue, 'Missing text value: ' + aName);
  Result := lValue.Value;
end;

function JsonInt(aObject: TJSONObject; const aName: string): Integer;
begin
  Result := StrToInt(JsonText(aObject, aName));
end;

procedure BuildBridgeTestForm(out aForm: TForm; out aEdit: TEdit; out aButton: TButton);
begin
  aForm := TForm.Create(nil);
  aForm.Name := 'BridgeForm';
  aForm.Caption := 'Bridge Test Window';
  aForm.SetBounds(200, 150, 360, 200);

  aEdit := TEdit.Create(aForm);
  aEdit.Name := 'SearchEdit';
  aEdit.Hint := 'Search text';
  aEdit.TabOrder := 0;
  aEdit.SetBounds(20, 24, 140, 24);
  aEdit.Parent := aForm;

  aButton := TButton.Create(aForm);
  aButton.Name := 'ApplyButton';
  aButton.Caption := 'Apply';
  aButton.TabOrder := 1;
  aButton.SetBounds(20, 64, 90, 28);
  aButton.Parent := aForm;

  aForm.HandleNeeded;
  aEdit.HandleNeeded;
  aButton.HandleNeeded;
end;

function MapForm(aForm: TCustomForm): TJSONObject;
var
  lResponse: string;
begin
  lResponse := TAccessibilityAgentBridge.Execute(
    '{"cmd":"form.map","target":"handle","handle":' + UIntToStr(NativeUInt(aForm.Handle)) + '}');
  Result := JsonObjectFrom(lResponse);
end;

function ControlByName(aMap: TJSONObject; const aName: string): TJSONObject;
var
  i: Integer;
  lControl: TJSONObject;
  lControls: TJSONArray;
begin
  lControls := JsonArrayValue(aMap, 'controls');
  for i := 0 to Pred(lControls.Count) do
  begin
    Assert.IsTrue(lControls.Items[i] is TJSONObject, 'Control entry is not an object.');
    lControl := TJSONObject(lControls.Items[i]);
    if JsonText(lControl, 'name') = aName then
    begin
      Exit(lControl);
    end;
  end;

  Assert.Fail('Control was not found in map: ' + aName);
  Result := nil;
end;

function ControlRefByName(aMap: TJSONObject; const aName: string): string;
begin
  Result := JsonText(ControlByName(aMap, aName), 'ref');
end;

procedure AssertOk(aResponse: TJSONObject);
begin
  Assert.AreEqual('true', JsonText(aResponse, 'ok'), aResponse.ToJSON);
end;

procedure TAccessibilityAgentBridgeTests.HelloReportsFrameworkPresenceAndMutationGate;
var
  lResponse: TJSONObject;
begin
  TAccessibilityAgentBridge.SetMutationEnabled(False);
  lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"hello"}'));
  try
    AssertOk(lResponse);
    Assert.AreEqual(cAccessibilityFrameworkName, JsonText(lResponse, 'frameworkName'));
    Assert.AreEqual(1, JsonInt(lResponse, 'protocolVersion'));
    Assert.AreEqual('false', JsonText(lResponse, 'mutationEnabled'));
  finally
    lResponse.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.WindowInfoReturnsGeometryAndDpi;
var
  lButton: TButton;
  lClientRect: TJSONObject;
  lClientScreenRect: TJSONObject;
  lEdit: TEdit;
  lForm: TForm;
  lPoint: TPoint;
  lResponse: TJSONObject;
  lWindow: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"window.info","target":"handle","handle":' + UIntToStr(NativeUInt(lForm.Handle)) + '}'));
    try
      AssertOk(lResponse);
      Assert.AreEqual('window.info', JsonText(lResponse, 'cmd'));
      Assert.AreEqual(1, JsonInt(lResponse, 'protocolVersion'));

      lWindow := JsonObjectValue(lResponse, 'window');
      Assert.AreEqual('BridgeForm', JsonText(lWindow, 'name'));
      Assert.AreEqual(UIntToStr(NativeUInt(lForm.Handle)), JsonText(lWindow, 'handle'));
      Assert.AreEqual(lForm.PixelsPerInch, JsonInt(lWindow, 'pixelsPerInch'));

      lClientRect := JsonObjectValue(lWindow, 'clientRect');
      Assert.AreEqual(0, JsonInt(lClientRect, 'left'));
      Assert.AreEqual(0, JsonInt(lClientRect, 'top'));
      Assert.AreEqual(lForm.ClientWidth, JsonInt(lClientRect, 'width'));
      Assert.AreEqual(lForm.ClientHeight, JsonInt(lClientRect, 'height'));

      lClientScreenRect := JsonObjectValue(lWindow, 'clientScreenRect');
      lPoint := lForm.ClientToScreen(Point(0, 0));
      Assert.AreEqual(lPoint.X, JsonInt(lClientScreenRect, 'left'));
      Assert.AreEqual(lPoint.Y, JsonInt(lClientScreenRect, 'top'));
      Assert.AreEqual(lForm.ClientWidth, JsonInt(lClientScreenRect, 'width'));
      Assert.AreEqual(lForm.ClientHeight, JsonInt(lClientScreenRect, 'height'));
    finally
      lResponse.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.FormMapReturnsSnapshotRefsAndTargetPoints;
var
  lButton: TButton;
  lCenter: TJSONObject;
  lEdit: TEdit;
  lEditEntry: TJSONObject;
  lForm: TForm;
  lMap: TJSONObject;
  lPoint: TPoint;
  lRoot: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm);
    try
      AssertOk(lMap);
      Assert.AreEqual('snapshot', JsonText(lMap, 'refModel'));
      Assert.IsTrue(JsonInt(lMap, 'snapshotId') > 0, 'Snapshot id should be positive.');

      lRoot := JsonObjectValue(lMap, 'form');
      Assert.AreEqual('@a0', JsonText(lRoot, 'ref'));
      Assert.AreEqual('BridgeForm', JsonText(lRoot, 'name'));
      Assert.AreEqual('TForm', JsonText(lRoot, 'className'));
      Assert.AreEqual('Bridge Test Window', JsonText(lRoot, 'caption'));

      lEditEntry := ControlByName(lMap, 'SearchEdit');
      Assert.AreEqual('@a1', JsonText(lEditEntry, 'ref'));
      Assert.AreEqual('@a0', JsonText(lEditEntry, 'parentRef'));
      Assert.AreEqual('TEdit', JsonText(lEditEntry, 'className'));
      Assert.AreEqual('Search text', JsonText(lEditEntry, 'hint'));
      Assert.AreEqual('true', JsonText(lEditEntry, 'visible'));
      Assert.AreEqual('true', JsonText(lEditEntry, 'enabled'));
      Assert.AreEqual('true', JsonText(lEditEntry, 'tabStop'));
      Assert.AreEqual(0, JsonInt(lEditEntry, 'tabOrder'));

      lCenter := JsonObjectValue(JsonObjectValue(lEditEntry, 'targetPoints'), 'center');
      lPoint := lEdit.ClientToScreen(Point(lEdit.Width div 2, lEdit.Height div 2));
      Assert.AreEqual(lPoint.X, JsonInt(lCenter, 'x'));
      Assert.AreEqual(lPoint.Y, JsonInt(lCenter, 'y'));

      Assert.AreEqual('@a2', ControlRefByName(lMap, 'ApplyButton'));
    finally
      lMap.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.HitTestReturnsControlFromLastSnapshot;
var
  lButton: TButton;
  lEdit: TEdit;
  lForm: TForm;
  lHit: TJSONObject;
  lMap: TJSONObject;
  lPoint: TPoint;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  try
    lMap := MapForm(lForm);
    try
      AssertOk(lMap);
    finally
      lMap.Free;
    end;

    lPoint := lEdit.ClientToScreen(Point(lEdit.Width div 2, lEdit.Height div 2));
    lHit := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      Format('{"cmd":"hitTest","x":%d,"y":%d}', [lPoint.X, lPoint.Y])));
    try
      AssertOk(lHit);
      Assert.AreEqual('@a1', JsonText(lHit, 'ref'));
      Assert.AreEqual('SearchEdit', JsonText(lHit, 'name'));
      Assert.AreEqual('TEdit', JsonText(lHit, 'className'));
    finally
      lHit.Free;
    end;
  finally
    lForm.Free;
  end;
end;

procedure TAccessibilityAgentBridgeTests.MutationsAreGatedAndOperateOnLastSnapshotRefs;
var
  lButton: TButton;
  lButtonRef: string;
  lClickRecorder: TAgentBridgeClickRecorder;
  lEdit: TEdit;
  lEditRef: string;
  lForm: TForm;
  lMap: TJSONObject;
  lResponse: TJSONObject;
begin
  BuildBridgeTestForm(lForm, lEdit, lButton);
  lForm.Show;
  Application.ProcessMessages;
  lClickRecorder := TAgentBridgeClickRecorder.Create;
  try
    lButton.OnClick := lClickRecorder.Click;
    lMap := MapForm(lForm);
    try
      lEditRef := ControlRefByName(lMap, 'SearchEdit');
      lButtonRef := ControlRefByName(lMap, 'ApplyButton');
    finally
      lMap.Free;
    end;

    lForm.ActiveControl := lButton;
    TAccessibilityAgentBridge.SetMutationEnabled(False);
    lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
      '{"cmd":"control.focus","ref":"' + lEditRef + '"}'));
    try
      Assert.AreEqual('false', JsonText(lResponse, 'ok'));
      Assert.AreEqual('mutation_disabled', JsonText(lResponse, 'errorCode'));
      Assert.AreSame(lButton, lForm.ActiveControl);
    finally
      lResponse.Free;
    end;

    TAccessibilityAgentBridge.SetMutationEnabled(True);
    try
      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.focus","ref":"' + lEditRef + '"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('true', JsonText(lResponse, 'snapshotInvalidated'));
        Assert.AreSame(lEdit, lForm.ActiveControl);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.setText","ref":"' + lEditRef + '","text":"base"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('base', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.typeText","ref":"' + lEditRef + '","text":" plus"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual('base plus', lEdit.Text);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute('{"cmd":"keyboard.tab"}'));
      try
        AssertOk(lResponse);
        Assert.AreSame(lButton, lForm.ActiveControl);
      finally
        lResponse.Free;
      end;

      lResponse := JsonObjectFrom(TAccessibilityAgentBridge.Execute(
        '{"cmd":"control.click","ref":"' + lButtonRef + '"}'));
      try
        AssertOk(lResponse);
        Assert.AreEqual(1, lClickRecorder.Clicks);
      finally
        lResponse.Free;
      end;
    finally
      TAccessibilityAgentBridge.SetMutationEnabled(False);
    end;
  finally
    lClickRecorder.Free;
    lForm.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAccessibilityAgentBridgeTests);

end.
