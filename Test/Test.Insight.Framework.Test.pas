unit Test.Insight.Framework.Test;

interface

uses System.SysUtils, System.Generics.Collections, Test.Insight.Framework, DUnitX.TestFramework, TestInsight.Client;

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
    [Test]
    procedure MustCreateTheClassOnlyIfWillExecuteAnTest;
    [Test]
    procedure BeforeStartTheTestMustCallTheSetupFixtureMethodOfTheExecutingClass;
    [Test]
    procedure AfterExecuteTheTestsOfAnClassMustCallTearDownFixtureOfTheClass;
    [Test]
    procedure WhenExecuteTheTestsOfAClassMustCallTheSetupProcedureForEveryTestProcedureCalled;
    [Test]
    procedure WhenExecuteTheTestsOfAClassMustCallTheTearDownProcedureForEveryTestProcedureCalled;
    [Test]
    procedure EvenTheTestGivingErrorMustCallTheTearDownProcedure;
    [Test]
    procedure WhenTheTestFailMustRegisterTheErrorMessageInTheResult;
    [Test]
    procedure WhenAClassInheritesTheSetupFixtureMustCallOnlyOneTimeTheFunction;
    [Test]
    procedure WhenAClassInheritesTheSetupFunctionMustCallOnlyOneByTest;
    [Test]
    procedure WhenAClassInheritesTheTearDownFixtureMustCallOnlyOneTimeTheFunction;
    [Test]
    procedure WhenAClassInheritesTheTearDownFunctionMustCallOnlyOneByTest;
    [Test]
    procedure WhenAClassInheritesTheSetupFixtureMustCallTheProcedureFromInheritedClass;
    [Test]
    procedure WhenAClassInheritesTheSetupFunctionMustCallTheProcedureFromInheritedClass;
    [Test]
    procedure WhenAClassInheritesTheTearDownFixtureMustCallTheProcedureFromInheritedClass;
    [Test]
    procedure WhenAClassInheritesTheTearDownFunctionMustCallTheProcedureFromInheritedClass;
    [Test]
    procedure WhenTheTestIsntExecutedMustRegisterTheTestAsSkiped;
    [Test]
    procedure WhenTheObjectResolverFunctionIsFilledMustCallTheFunctionToCreateTheObjectInstance;
    [Test]
    procedure WhenDiscoveringTestsCantExecuteAnyTest;
    [Test]
    procedure WhenTheSetupFixtureRaiseAnErrorCantStopExecutingTheTests;
    [Test]
    procedure WhenTheTearDownFixtureRaiseAnErrorCantStopExecutingTheTest;
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
    procedure WhenExpectAnExceptionInAssertionAndNoneHappensMustRaiseAssertError;
    [Test]
    procedure WheWillNotRaiseIsCalledMustExecuteTheInternalProcedure;
    [Test]
    procedure WhenAnExceptionIsRaisedInsideTheWillNotRaiseAssertMustRaiseAnAssertionError;
    [Test]
    procedure WhenCheckAnExpectationAndIsntEmptyMustRaiseAssertError;
    [Test]
    procedure WhenCheckAnEmptyExpectationCantRaiseAnyError;
    [Test]
    procedure WhenChekAPointerNilMustRaiseAssertErrorInIsNotNilAssertion;
    [Test]
    procedure WhenThePointerIsntNilCantRaiseAnyError;
    [Test]
    procedure WhenATrueValueIsExpectedAndAFalseValueIsPasseMustRaiseAssertionError;
    [Test]
    procedure WhenATrueValueIsExpectedAndATrueValueIsPassedCantRaiseAnyError;
    [Test]
    procedure WhenAFalseValueIsExpectedAndATrueValueIsPassedMustRaiseAssertionError;
    [Test]
    procedure WhenAFalseValueIsExpectedAndAFalseValueIsPassedCantRaiseAnyError;
    [Test]
    procedure WhenStartWithDontStartWithTheExpectedStringMustRaiseAnError;
    [Test]
    procedure WhenTheValueStartWithTheValueExpectedCantRaiseAnyError;
    [Test]
    procedure WhenCheckANilPointerInTheIsNilFunctionCantRaiseAssertionError;
    [Test]
    procedure WhenCheckAPointerWithValueInTheIsNilFunctionMustRaiseAssertionError;
    [Test]
    procedure BeforeExecuteTheTestsMustClearAllTests;
  end;

  TTestInsightClientMock = class(TInterfacedObject, ITestInsightClient)
  private
    FCalledProcedures: String;
    FOptions: TTestInsightOptions;
    FPostedTests: TDictionary<String, TTestInsightResult>;
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
    constructor Create;

    destructor Destroy; override;

    property CalledProcedures: String read FCalledProcedures write FCalledProcedures;
    property PostedTests: TDictionary<String, TTestInsightResult> read FPostedTests;
    property Tests: TArray<String> read FTests write FTests;
  end;

implementation

uses System.Rtti, Test.Insight.Framework.Classes.Test;

{ TAssertTest }

procedure TAssertTest.BeforeExecuteTheTestsMustClearAllTests;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.StartsWith('ClearTests;', Client.CalledProcedures);

  Test.Free;
end;

procedure TAssertTest.WhenAFalseValueIsExpectedAndAFalseValueIsPassedCantRaiseAnyError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsFalse(False);
    end);
end;

procedure TAssertTest.WhenAFalseValueIsExpectedAndATrueValueIsPassedMustRaiseAssertionError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsFalse(True);
    end, EAssertFail);
end;

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

procedure TAssertTest.WhenATrueValueIsExpectedAndAFalseValueIsPasseMustRaiseAssertionError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsTrue(False);
    end, EAssertFail);
end;

procedure TAssertTest.WhenATrueValueIsExpectedAndATrueValueIsPassedCantRaiseAnyError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsTrue(True);
    end);
end;

procedure TAssertTest.WhenCallTheAssertWillRaiseMustCallTheInternalProcedurePassedInTheParameter;
begin
  var Executed := False;

  Test.Insight.Framework.Assert.WillRaise(
    procedure
    begin
      Executed := True;

      raise EExpectedError.Create;
    end, EExpectedError);

  Assert.IsTrue(Executed);
end;

procedure TAssertTest.WhenCheckAnEmptyExpectationCantRaiseAnyError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.CheckExpectation(EmptyStr);
    end);
end;

procedure TAssertTest.WhenCheckAnExpectationAndIsntEmptyMustRaiseAssertError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.CheckExpectation('The expectation error!');
    end, EAssertFail);
end;

procedure TAssertTest.WhenCheckANilPointerInTheIsNilFunctionCantRaiseAssertionError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsNil(nil);
    end);
end;

procedure TAssertTest.WhenCheckAPointerWithValueInTheIsNilFunctionMustRaiseAssertionError;
begin
  Assert.WillRaise(
    procedure
    begin
      var AObject := TObject.Create;

      try
        Test.Insight.Framework.Assert.IsNil(AObject);
      finally
        AObject.Free;
      end;
    end, EAssertFail);
end;

procedure TAssertTest.WhenChekAPointerNilMustRaiseAssertErrorInIsNotNilAssertion;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsNotNil(nil);
    end, EAssertFail);
end;

procedure TAssertTest.WhenExpectAnExceptionInAssertionAndNoneHappensMustRaiseAssertError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.WillRaise(
        procedure
        begin

        end, EExpectedError);
    end, EAssertFail);
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

procedure TAssertTest.WhenStartWithDontStartWithTheExpectedStringMustRaiseAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.StartWith('abc', 'def');
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

procedure TAssertTest.WhenThePointerIsntNilCantRaiseAnyError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      var AObject := TObject.Create;

      Test.Insight.Framework.Assert.IsNotNil(AObject);

      AObject.Free;
    end);
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

procedure TAssertTest.WhenTheValueStartWithTheValueExpectedCantRaiseAnyError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.StartWith('abc', 'abcdef');
    end);
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

procedure TTestInsightFrameworkTest.AfterExecuteTheTestsOfAnClassMustCallTearDownFixtureOfTheClass;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];
  var Test := TTestInsightFramework.Create(Client);

  TClassWithSetupAndTearDownFixture.TearDownFixtureCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassWithSetupAndTearDownFixture.TearDownFixtureCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.AfterRunTheTestsMustCallTheFinishedTesting;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.EndsWith('FinishedTesting;', Client.CalledProcedures);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.BeforeStartTheTestMustCallTheSetupFixtureMethodOfTheExecutingClass;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];
  var Test := TTestInsightFramework.Create(Client);

  TClassWithSetupAndTearDownFixture.SetupFixtureCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassWithSetupAndTearDownFixture.SetupFixtureCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.EvenTheTestGivingErrorMustCallTheTearDownProcedure;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];
  var Test := TTestInsightFramework.Create(Client);

  TClassWithSetupAndTearDownFixture.TearDownCalled := 0;

  Test.Run;

  Assert.AreEqual(3, TClassWithSetupAndTearDownFixture.TearDownCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.MustCreateTheClassOnlyIfWillExecuteAnTest;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TMyClassTest3.Test2'];
  var Test := TTestInsightFramework.Create(Client);

  Assert.AreEqual(0, TClassWithoutTest.CreationCount);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.MustExecuteOnlyTheSelectedTest;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TMyClassTest3.Test2'];
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.IsTrue(Client.PostedTests.ContainsKey('Test.Insight.Framework.Classes.Test.TMyClassTest3.Test2'));

  Test.Free;
end;

procedure TTestInsightFrameworkTest.MustPostResultOfAllClassesWithTheTestFixtureAttribute;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.AreEqual(20, Client.PostedTests.Count);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.TheDurationOfTheTestMustBeFilledWithTheTimeToExecuteTheTest;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);
  WaitForTest := True;

  Test.Run;

  WaitForTest := False;

  var TestResult := Client.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest2.Test2'];

  Assert.IsTrue(TestResult.Duration >= 500);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.TheTestResultMustBeFilledHasExpected;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test'];

  Assert.AreEqual(TResultType.Passed, TestResult.ResultType);
  Assert.AreEqual('Test.Insight.Framework.Classes.Test', TestResult.UnitName);
  Assert.AreEqual('TMyClassTest', TestResult.ClassName);
  Assert.AreEqual('Test', TestResult.MethodName);
  Assert.AreEqual('Test.Insight.Framework.Classes.Test.TMyClassTest', TestResult.Path);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFixtureMustCallOnlyOneTimeTheFunction;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.SetupFixtureCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.SetupFixtureCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFixtureMustCallTheProcedureFromInheritedClass;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.SetupFixtureCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.SetupFixtureCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFunctionMustCallOnlyOneByTest;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.SetupCalled := 0;

  Test.Run;

  Assert.AreEqual(3, TClassInheritedFromAnotherClass.SetupCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFunctionMustCallTheProcedureFromInheritedClass;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.SetupCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.SetupCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFixtureMustCallOnlyOneTimeTheFunction;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.TearDownFixtureCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.TearDownFixtureCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFixtureMustCallTheProcedureFromInheritedClass;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.TearDownFixtureCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.TearDownFixtureCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFunctionMustCallOnlyOneByTest;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.TearDownCalled := 0;

  Test.Run;

  Assert.AreEqual(3, TClassInheritedFromAnotherClass.TearDownCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFunctionMustCallTheProcedureFromInheritedClass;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];
  var Test := TTestInsightFramework.Create(Client);

  TClassInheritedFromAnotherClass.TearDownCalled := 0;

  Test.Run;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.TearDownCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenATestFailMustPostTheResultError;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'];

  Assert.AreEqual(TResultType.Failed, TestResult.ResultType);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenATestRaiseAnErrorMustPostTheError;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest2.Test'];

  Assert.AreEqual(TResultType.Error, TestResult.ResultType);
  Assert.AreEqual('An error!', TestResult.ExceptionMessage);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenDiscoveringTestsCantExecuteAnyTest;
begin
  var Client := TTestInsightClientMock.Create;
  Client.FOptions.ExecuteTests := False;
  var Test := TTestInsightFramework.Create(Client);

  TClassWithSetupAndTearDownFixture.SetupCalled := 0;
  TClassWithSetupAndTearDownFixture.SetupFixtureCalled := 0;
  TClassWithSetupAndTearDownFixture.TearDownCalled := 0;
  TClassWithSetupAndTearDownFixture.TearDownFixtureCalled := 0;
  TClassWithSetupAndTearDownFixture.TestCalled := 0;

  Test.Run;

  Assert.AreEqual(0, TClassWithSetupAndTearDownFixture.SetupCalled + TClassWithSetupAndTearDownFixture.SetupFixtureCalled + TClassWithSetupAndTearDownFixture.TearDownCalled
    + TClassWithSetupAndTearDownFixture.TearDownFixtureCalled + TClassWithSetupAndTearDownFixture.TestCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenExecuteTheTestsOfAClassMustCallTheSetupProcedureForEveryTestProcedureCalled;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];
  var Test := TTestInsightFramework.Create(Client);

  TClassWithSetupAndTearDownFixture.SetupCalled := 0;

  Test.Run;

  Assert.AreEqual(3, TClassWithSetupAndTearDownFixture.SetupCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenExecuteTheTestsOfAClassMustCallTheTearDownProcedureForEveryTestProcedureCalled;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];
  var Test := TTestInsightFramework.Create(Client);

  TClassWithSetupAndTearDownFixture.TearDownCalled := 0;

  Test.Run;

  Assert.AreEqual(3, TClassWithSetupAndTearDownFixture.TearDownCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenHasSelectedTestsMustRunOnlyTheSelectedTests;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TMyClassTest3.Test2'];
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  for var TheTest in Client.PostedTests.Values do
    if TheTest.ResultType = TResultType.Passed then
      Assert.AreEqual('Test.Insight.Framework.Classes.Test.TMyClassTest3.Test2', TheTest.Path + '.' + TheTest.TestName);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenRunTheTestsMustStartTheTestInTheClient;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.StartsWith('ClearTests;StartedTesting;', Client.CalledProcedures);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheObjectResolverFunctionIsFilledMustCallTheFunctionToCreateTheObjectInstance;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];
  var FunctionExecuted := False;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run(
    function (&Type: TRttiInstanceType): TObject
    begin
      FunctionExecuted := True;
      Result := TClassInheritedFromWithoutSetupAndTearDown.Create;
    end);

  Assert.IsTrue(FunctionExecuted);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheSetupFixtureRaiseAnErrorCantStopExecutingTheTests;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);
  TClassWithSetupError.SetupFixtureRaiseError := True;

  Test.Run;

  Assert.AreEqual(20, Client.PostedTests.Count);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheTearDownFixtureRaiseAnErrorCantStopExecutingTheTest;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);
  TClassWithSetupError.TearDownFixtureRaiseError := True;

  Test.Run;

  Assert.AreEqual(20, Client.PostedTests.Count);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheTestFailMustRegisterTheErrorMessageInTheResult;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'];

  Assert.AreEqual('The value expected is 10 and the current value is 20', TestResult.ExceptionMessage);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheTestIsExecutedMustPostTheResultHasSuccess;
begin
  var Client := TTestInsightClientMock.Create;
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  var TestResult := Client.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test'];

  Assert.AreEqual(TResultType.Passed, TestResult.ResultType);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheTestIsntExecutedMustRegisterTheTestAsSkiped;
begin
  var Client := TTestInsightClientMock.Create;
  Client.Tests := ['Test.Insight.Framework.Classes.Test.TMyClassTest.Test'];
  var Test := TTestInsightFramework.Create(Client);

  Test.Run;

  Assert.IsTrue(Client.PostedTests.ContainsKey('Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'));

  var TestResult := Client.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'];

  Assert.AreEqual(TResultType.Skipped, TestResult.ResultType);

  Test.Free;
end;

{ TTestInsightClientMock }

procedure TTestInsightClientMock.ClearTests;
begin
  RegisterProcedureCall('ClearTests');
end;

constructor TTestInsightClientMock.Create;
begin
  inherited;

  FOptions.ExecuteTests := True;
  FPostedTests := TDictionary<String, TTestInsightResult>.Create;
end;

destructor TTestInsightClientMock.Destroy;
begin
  FPostedTests.Free;

  inherited;
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
  Result := FOptions;

  RegisterProcedureCall('GetOptions');
end;

function TTestInsightClientMock.GetTests: TArray<string>;
begin
  Result := Tests;

  RegisterProcedureCall('GetTests');
end;

procedure TTestInsightClientMock.PostResult(const testResult: TTestInsightResult; sendImmediately: Boolean);
begin
  FPostedTests.AddOrSetValue(Format('%s.%s', [testResult.Path, testResult.TestName]), testResult);

  RegisterProcedureCall(Format('PostResult.%s', [BoolToStr(sendImmediately, True)]));
end;

procedure TTestInsightClientMock.PostResults(const testResults: array of TTestInsightResult; sendImmediately: Boolean);
begin
  for var Test in testResults do
    PostResult(Test, sendImmediately);
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

