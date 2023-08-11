unit Test.Insight.Framework.Test;

interface

uses System.SysUtils, Test.Insight.Framework, DUnitX.TestFramework, TestInsight.Client;

type
  EExpectedError = class(Exception)
  public
    constructor Create;
  end;

  ENotExpectedError = class(Exception)
  public
    constructor Create;
  end;

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
    [Test]
    procedure WhenHasSelectedTestsMustRunOnlyTheSelectedTests;
    [Test]
    procedure MustExecuteOnlyTheSelectedTest;
  end;

  [TestFixture]
  TAssertTest = class
  public
    [Test]
    procedure WhenTheValuesAreNotEqualMustRaiseAnError;
    [Test]
    procedure WhenTheValueAreEqualCantRaiseAnyError;
    [Test]
    procedure WhenCallTheAssertWillRaiseMustCallTheInternalProcedurePassedInTheParameter;
    [Test]
    procedure WhenRaiseAnExceptionNoExpectedTheWillRaiseMustRaiseAnAssertError;
    [Test]
    procedure WhenTheExceptionRaiseInTheProcedureIsExpectedCantRaiseAssertError;
    [Test]
    procedure WheWillNotRaiseIsCalledMustExecuteTheInternalProcedure;
    [Test]
    procedure WhenAnExceptionIsRaisedInsideTheWillNotRaiseAssertMustRaiseAnAssertionError;
  end;

  TTestInsightClientMock = class(TInterfacedObject, ITestInsightClient)
  private
    FCalledProcedures: String;
    FPostedTests: TArray<TTestInsightResult>;
    FTests: TArray<String>;

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
    property PostedTests: TArray<TTestInsightResult> read FPostedTests write FPostedTests;
    property Tests: TArray<String> read FTests write FTests;
  end;

implementation

uses MyClassTest;

{ TAssertTest }

procedure TAssertTest.WhenAnExceptionIsRaisedInsideTheWillNotRaiseAssertMustRaiseAnAssertionError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.WillNotRaise(
        procedure
        begin
          raise EExpectedError.Create;
        end);
    end, EAssertFail);
end;

procedure TAssertTest.WhenCallTheAssertWillRaiseMustCallTheInternalProcedurePassedInTheParameter;
begin
  var Executed := False;

  Test.Insight.Framework.Assert.WillRaise(
    procedure
    begin
      Executed := True;
    end, EExpectedError);

  Assert.IsTrue(Executed);
end;

procedure TAssertTest.WhenRaiseAnExceptionNoExpectedTheWillRaiseMustRaiseAnAssertError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.WillRaise(
        procedure
        begin
          raise ENotExpectedError.Create;
        end, EExpectedError);
    end, EAssertFail);
end;

procedure TAssertTest.WhenTheExceptionRaiseInTheProcedureIsExpectedCantRaiseAssertError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.WillRaise(
        procedure
        begin
          raise EExpectedError.Create;
        end, EExpectedError);
    end, EAssertFail);
end;

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

procedure TAssertTest.WheWillNotRaiseIsCalledMustExecuteTheInternalProcedure;
begin
  var Executed := False;

  Test.Insight.Framework.Assert.WillNotRaise(
    procedure
    begin
      Executed := True;
    end);

  Assert.IsTrue(Executed);
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

procedure TTestInsightFrameworkTest.MustExecuteOnlyTheSelectedTest;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['MyClassTest.TMyClassTest3.Test2'];
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.AreEqual('MyClassTest.TMyClassTest3.Test2', Format('%s.%s', [Client.PostedTests[1].Path, Client.PostedTests[1].TestName]));

  Test.Free;
end;

procedure TTestInsightFrameworkTest.MustPostResultOfAllClassesWithTheTestFixtureAttribute;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.AreEqual<NativeInt>(12, Length(Client.PostedTests));

  Test.Free;
end;

procedure TTestInsightFrameworkTest.TheDurationOfTheTestMustBeFilledWithTheTimeToExecuteTheTest;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);
  WaitForTest := True;

  Test.Run;

  WaitForTest := False;

  var TestResult := Client.PostedTests[7];

  Assert.IsTrue(TestResult.Duration >= 500);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.TheTestResultMustBeFilledHasExpected;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTests[0];

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

  var TestResult := Client.PostedTests[3];

  Assert.AreEqual(TResultType.Failed, TestResult.ResultType);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenATestRaiseAnErrorMustPostTheError;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTests[5];

  Assert.AreEqual(TResultType.Error, TestResult.ResultType);
  Assert.AreEqual('An error!', TestResult.ExceptionMessage);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenHasSelectedTestsMustRunOnlyTheSelectedTests;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['MyClassTest.TMyClassTest3.Test2'];
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.AreEqual<NativeInt>(2, Length(Client.PostedTests));

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

  var TestResult := Client.PostedTests[1];

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
  Result := False;

  RegisterProcedureCall('GetHasError');
end;

function TTestInsightClientMock.GetOptions: TTestInsightOptions;
begin
  RegisterProcedureCall('GetOptions');
end;

function TTestInsightClientMock.GetTests: TArray<string>;
begin
  Result := Tests;

  RegisterProcedureCall('GetTests');
end;

procedure TTestInsightClientMock.PostResult(const testResult: TTestInsightResult; sendImmediately: Boolean);
begin
  FPostedTests := FPostedTests + [testResult];

  RegisterProcedureCall(Format('PostResult.%s', [BoolToStr(sendImmediately, True)]));
end;

procedure TTestInsightClientMock.PostResults(const testResults: array of TTestInsightResult; sendImmediately: Boolean);
begin
  SetLength(FPostedTests, Length(testResults));

  for var A := Low(testResults) to High(testResults) do
    FPostedTests[A] := testResults[A];

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

{ EExpectedError }

constructor EExpectedError.Create;
begin
  inherited Create('Excepted error!');
end;

{ ENotExpectedError }

constructor ENotExpectedError.Create;
begin
  inherited Create('Not excepted error!');
end;

end.

