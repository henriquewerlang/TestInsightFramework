unit Test.Insight.Framework.Test;

interface

uses Test.Insight.Framework, DUnitX.TestFramework, TestInsight.Client;

type
  [TestFixture]
  TTestInsightFrameworkTest = class
  public
    [Test]
    procedure WhenRunTheTestsMustStartTheTestInTheClient;
    [Test]
    procedure AfterRunTheTestsMustCallTheFinishedTesting;
    [Test]
    procedure MustPostResultOfAllClassesWithTheTestFixtureAttribute;
    [Test]
    procedure TheTestResultMustBeFilledHasExpected;
    [Test]
    procedure WhenTheTestIsExecutedMustPostTheResultHasSuccess;
    [Test]
    procedure WhenATestFailMustPostTheResultError;
    [Test]
    procedure WhenATestRaiseAnErrorMustPostTheError;
    [Test]
    procedure TheDurationOfTheTestMustBeFilledWithTheTimeToExecuteTheTest;
  end;

  [TestFixture]
  TAssertTest = class
  public
    [Test]
    procedure WhenTheValuesAreNotEqualMustRaiseAnError;
    [Test]
    procedure WhenTheValueAreEqualCantRaiseAnyError;
  end;

  TTestInsightClientMock = class(TInterfacedObject, ITestInsightClient)
  private
    FCalledProcedures: String;
    FPostedTestes: TArray<TTestInsightResult>;

    function GetHasError: Boolean;
    function GetOptions: TTestInsightOptions;
    function GetTests: TArray<string>;

    procedure ClearTests;
    procedure FinishedTesting;
    procedure PostResult(const testResult: TTestInsightResult; sendImmediately: Boolean = False);
    procedure PostResults(const testResults: array of TTestInsightResult; sendImmediately: Boolean = False);
    procedure RegisterProcedureCall(const ProcedureName: String);
    procedure SetOptions(const value: TTestInsightOptions);
    procedure StartedTesting(const totalCount: Integer);
  public
    property CalledProcedures: String read FCalledProcedures write FCalledProcedures;
    property PostedTestes: TArray<TTestInsightResult> read FPostedTestes write FPostedTestes;
  end;

implementation

uses System.SysUtils, MyClassTest;

{ TAssertTest }

procedure TAssertTest.WhenTheValueAreEqualCantRaiseAnyError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.AreEqual(10, 10);
    end);
end;

procedure TAssertTest.WhenTheValuesAreNotEqualMustRaiseAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.AreEqual(10, 20);
    end, EAssertFail);
end;

{ TTestInsightFrameworkTest }

procedure TTestInsightFrameworkTest.AfterRunTheTestsMustCallTheFinishedTesting;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.EndsWith('FinishedTesting;', Client.CalledProcedures);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.MustPostResultOfAllClassesWithTheTestFixtureAttribute;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.AreEqual<NativeInt>(12, Length(Client.PostedTestes));

  Test.Free;
end;

procedure TTestInsightFrameworkTest.TheDurationOfTheTestMustBeFilledWithTheTimeToExecuteTheTest;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);
  WaitForTest := True;

  Test.Run;

  WaitForTest := False;

  var TestResult := Client.PostedTestes[7];

  Assert.IsTrue(TestResult.Duration >= 500);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.TheTestResultMustBeFilledHasExpected;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTestes[0];

  Assert.AreEqual(TResultType.Running, TestResult.ResultType);
  Assert.AreEqual('MyClassTest', TestResult.UnitName);
  Assert.AreEqual('TMyClassTest', TestResult.ClassName);
  Assert.AreEqual('Test', TestResult.MethodName);
  Assert.AreEqual('MyClassTest.TMyClassTest', TestResult.Path);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenATestFailMustPostTheResultError;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTestes[3];

  Assert.AreEqual(TResultType.Failed, TestResult.ResultType);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenATestRaiseAnErrorMustPostTheError;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTestes[5];

  Assert.AreEqual(TResultType.Error, TestResult.ResultType);
  Assert.AreEqual('An error!', TestResult.ExceptionMessage);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenRunTheTestsMustStartTheTestInTheClient;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.StartsWith('StartedTesting;', Client.CalledProcedures);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheTestIsExecutedMustPostTheResultHasSuccess;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTestes[1];

  Assert.AreEqual(TResultType.Passed, TestResult.ResultType);

  Test.Free;
end;

{ TTestInsightClientMock }

procedure TTestInsightClientMock.ClearTests;
begin
  RegisterProcedureCall('ClearTests');
end;

procedure TTestInsightClientMock.FinishedTesting;
begin
  RegisterProcedureCall('FinishedTesting');
end;

function TTestInsightClientMock.GetHasError: Boolean;
begin
  RegisterProcedureCall('GetHasError');

  Result := False;
end;

function TTestInsightClientMock.GetOptions: TTestInsightOptions;
begin
  RegisterProcedureCall('GetOptions');
end;

function TTestInsightClientMock.GetTests: TArray<string>;
begin
  RegisterProcedureCall('GetTests');

  Result := nil;
end;

procedure TTestInsightClientMock.PostResult(const testResult: TTestInsightResult; sendImmediately: Boolean);
begin
  FPostedTestes := FPostedTestes + [testResult];

  RegisterProcedureCall(Format('PostResult.%s', [BoolToStr(sendImmediately, True)]));
end;

procedure TTestInsightClientMock.PostResults(const testResults: array of TTestInsightResult; sendImmediately: Boolean);
begin
  SetLength(FPostedTestes, Length(testResults));

  for var A := Low(testResults) to High(testResults) do
    FPostedTestes[A] := testResults[A];

  RegisterProcedureCall(Format('PostResults.%d.%s', [Length(testResults), BoolToStr(sendImmediately)]));
end;

procedure TTestInsightClientMock.RegisterProcedureCall(const ProcedureName: String);
begin
  CalledProcedures := CalledProcedures + ProcedureName + ';';
end;

procedure TTestInsightClientMock.SetOptions(const value: TTestInsightOptions);
begin
  RegisterProcedureCall('SetOptions');
end;

procedure TTestInsightClientMock.StartedTesting(const totalCount: Integer);
begin
  RegisterProcedureCall('StartedTesting');
end;

end.

