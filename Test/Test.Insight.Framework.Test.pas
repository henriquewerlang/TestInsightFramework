unit Test.Insight.Framework.Test;

interface

uses System.SysUtils, System.Generics.Collections, Test.Insight.Framework, DUnitX.TestFramework, TestInsight.Client;

type
  TTestInsightClientMock = class;

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
  private
    FClient: TTestInsightClientMock;
    FKeepWaiting: Boolean;
    FTest: TTestInsightFramework;

    procedure ExecuteTests;
    procedure ExecuteTestsAndWait;
    procedure WaitForTimer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure WhenRunTheTestsMustStartTheTestInTheClient;
    [Test]
    procedure WhenCallTheStartedTestingMustLoadTheTotalTestsToBeExecuted;
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
    [Test]
    procedure WhenExecuteAnAsyncAssertionCantDestroyTheClassBeforeTheResumeIsCalled;
    [Test]
    procedure WhenExecuteATestWithAsyncAssertionMustExecuteTheAssertionWhemCallTheResume;
    [Test]
    procedure WhenAnAsyncAssertIsCalledTheTestsMustStopExecutingUntilResumeIsCalled;
    [Test]
    procedure MustPostTheResumeOfAsyncTestToThResultTests;
    [Test]
    procedure WhenAnInheritedClassHasSetupAndTearDownMethodsMustCallOnlyTheMethodsInTheHigherClassInheritance;
    [Test]
    procedure WhenTerminateTheExecutionMustCallOnTerminateEvent;
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
    procedure ThenCallTheAsyncAssertMustRaiseAsyncException;
    [Test]
    procedure WhenCallTheAsyncAssertMustLoadTheAsyncAssertProcedureWithTheProcedurePassedToTheCaller;
    [Test]
    procedure WhenCallTheAsyncAssertWithANilParamMustRaiseAnError;
    [Test]
    procedure WhenCallTheAsyncAssertWithATimeoutValueMustLoadTheValueAsExpected;
    [Test]
    procedure WhenTheValueIsntGreaterThanMustRaiseAnAssertionError;
    [Test]
    procedure WhenTheStringValueIsNotEmptyMustRaiseAssertionError;
    [Test]
    procedure WhenTheStringValueIsEmptyCantRaiseAssertionError;
    [Test]
    procedure WhenAssertTheIsNotEmptyMustRaiseAssertionErroIfTheStringIsEmpty;
    [Test]
    procedure WhenAssertTheIsNotEmptyMustNOtRaiseAssertionErroIfTheStringIsNotEmpty;
  end;

  TTestInsightClientMock = class(TInterfacedObject, ITestInsightClient)
  private
    FCalledProcedures: String;
    FOptions: TTestInsightOptions;
    FPostedTests: TDictionary<String, TTestInsightResult>;
    FTests: TArray<String>;
    FTotalTests: Integer;

    function GetHasError: Boolean;
    function GetOptions: TTestInsightOptions;
    function GetTests: TArray<string>;

    procedure ClearTests;
    procedure FinishedTesting;
    procedure PostResult(const testResult: TTestInsightResult; sendImmediately: Boolean);
    procedure PostResults(const testResults: array of TTestInsightResult; sendImmediately: Boolean);
    procedure RegisterProcedureCall(const ProcedureName: String);
    procedure SetOptions(const value: TTestInsightOptions);
    procedure StartedTesting(const totalCount: Integer);
  public
    constructor Create;

    destructor Destroy; override;

    property CalledProcedures: String read FCalledProcedures write FCalledProcedures;
    property PostedTests: TDictionary<String, TTestInsightResult> read FPostedTests;
    property Tests: TArray<String> read FTests write FTests;
    property TotalTests: Integer read FTotalTests write FTotalTests;
  end;

implementation

uses System.Rtti, Vcl.Forms, Test.Insight.Framework.Classes.Test;

const
  TEST_COUNT = 32;

{ TAssertTest }

procedure TAssertTest.ThenCallTheAsyncAssertMustRaiseAsyncException;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.Async(ThenCallTheAsyncAssertMustRaiseAsyncException);
    end, EAssertAsync);
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

procedure TAssertTest.WhenAssertTheIsNotEmptyMustNOtRaiseAssertionErroIfTheStringIsNotEmpty;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsNotEmpty('abc');
    end);
end;

procedure TAssertTest.WhenAssertTheIsNotEmptyMustRaiseAssertionErroIfTheStringIsEmpty;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsNotEmpty('');
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

procedure TAssertTest.WhenCallTheAsyncAssertMustLoadTheAsyncAssertProcedureWithTheProcedurePassedToTheCaller;
begin
  try
    Test.Insight.Framework.Assert.Async(WhenCallTheAsyncAssertMustLoadTheAsyncAssertProcedureWithTheProcedurePassedToTheCaller);
  except
    on AsynErro: EAssertAsync do
      Assert.IsTrue(Assigned(AsynErro.AssertAsyncProcedure));
    else
      raise;
  end;
end;

procedure TAssertTest.WhenCallTheAsyncAssertWithANilParamMustRaiseAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.Async(nil);
    end, EAssertAsyncEmptyProcedure);
end;

procedure TAssertTest.WhenCallTheAsyncAssertWithATimeoutValueMustLoadTheValueAsExpected;
begin
  try
    Test.Insight.Framework.Assert.Async(WhenCallTheAsyncAssertMustLoadTheAsyncAssertProcedureWithTheProcedurePassedToTheCaller, 150);
  except
    on AsynErro: EAssertAsync do
      Assert.AreEqual(150, AsynErro.TimeOut);
    else
      raise;
  end;
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

procedure TAssertTest.WhenTheStringValueIsEmptyCantRaiseAssertionError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsEmpty('');
    end);
end;

procedure TAssertTest.WhenTheStringValueIsNotEmptyMustRaiseAssertionError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.IsEmpty('abc');
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

procedure TAssertTest.WhenTheValueIsntGreaterThanMustRaiseAnAssertionError;
begin
  Assert.WillRaise(
    procedure
    begin
      Test.Insight.Framework.Assert.GreaterThan(10, 5);
    end, EAssertFail);
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
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];

  TClassWithSetupAndTearDownFixture.TearDownFixtureCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassWithSetupAndTearDownFixture.TearDownFixtureCalled);
end;

procedure TTestInsightFrameworkTest.AfterRunTheTestsMustCallTheFinishedTesting;
begin
  ExecuteTestsAndWait;

  Assert.EndsWith('FinishedTesting;', FClient.CalledProcedures);
end;

procedure TTestInsightFrameworkTest.BeforeStartTheTestMustCallTheSetupFixtureMethodOfTheExecutingClass;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];

  TClassWithSetupAndTearDownFixture.SetupFixtureCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassWithSetupAndTearDownFixture.SetupFixtureCalled);
end;

procedure TTestInsightFrameworkTest.EvenTheTestGivingErrorMustCallTheTearDownProcedure;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];

  TClassWithSetupAndTearDownFixture.TearDownCalled := 0;

  ExecuteTests;

  Assert.AreEqual(3, TClassWithSetupAndTearDownFixture.TearDownCalled);
end;

procedure TTestInsightFrameworkTest.ExecuteTests;
begin
  FKeepWaiting := True;

  FTest.Run;
end;

procedure TTestInsightFrameworkTest.ExecuteTestsAndWait;
begin
  ExecuteTests;

  WaitForTimer;
end;

procedure TTestInsightFrameworkTest.MustCreateTheClassOnlyIfWillExecuteAnTest;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TMyClassTest3.Test2'];

  ExecuteTestsAndWait;

  Assert.AreEqual(0, TClassWithoutTest.CreationCount);
end;

procedure TTestInsightFrameworkTest.MustPostResultOfAllClassesWithTheTestFixtureAttribute;
begin
  ExecuteTestsAndWait;

  Assert.AreEqual(TEST_COUNT, FClient.PostedTests.Count);
end;

procedure TTestInsightFrameworkTest.MustPostTheResumeOfAsyncTestToThResultTests;
begin
  var TestName := 'Test.Insight.Framework.Classes.Test.TClassWithAsyncTest.AsyncAssert';

  FClient.Tests := [TestName];

  ExecuteTestsAndWait;

  Assert.AreEqual(TResultType.Passed, FClient.PostedTests[TestName].ResultType);
end;

procedure TTestInsightFrameworkTest.Setup;
begin
  FClient := TTestInsightClientMock.Create;
  FTest := TTestInsightFramework.Create(FClient, nil, False);

  FTest.OnTerminate :=
    procedure
    begin
      FKeepWaiting := False;
    end;
end;

procedure TTestInsightFrameworkTest.TearDown;
begin
  WaitForTimer;

  FTest.Free;
end;

procedure TTestInsightFrameworkTest.TheDurationOfTheTestMustBeFilledWithTheTimeToExecuteTheTest;
begin
  WaitForTest := True;

  ExecuteTests;

  WaitForTest := False;

  var TestResult := FClient.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest2.Test2'];

  Assert.IsTrue(TestResult.Duration >= 500);
end;

procedure TTestInsightFrameworkTest.TheTestResultMustBeFilledHasExpected;
begin
  ExecuteTests;

  var TestResult := FClient.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test'];

  Assert.AreEqual(TResultType.Passed, TestResult.ResultType);
  Assert.AreEqual('Test.Insight.Framework.Classes.Test', TestResult.UnitName);
  Assert.AreEqual('TMyClassTest', TestResult.ClassName);
  Assert.AreEqual('Test', TestResult.MethodName);
  Assert.AreEqual('Test.Insight.Framework.Classes.Test.TMyClassTest', TestResult.Path);
end;

procedure TTestInsightFrameworkTest.WaitForTimer;
begin
  while FKeepWaiting do
  begin
    Application.ProcessMessages;

    Sleep(10);
  end;
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFixtureMustCallOnlyOneTimeTheFunction;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];

  TClassInheritedFromAnotherClass.SetupFixtureCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.SetupFixtureCalled);
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFixtureMustCallTheProcedureFromInheritedClass;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];

  TClassInheritedFromWithoutSetupAndTearDown.SetupFixtureCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassInheritedFromWithoutSetupAndTearDown.SetupFixtureCalled);
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFunctionMustCallOnlyOneByTest;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];

  TClassInheritedFromAnotherClass.SetupCalled := 0;

  ExecuteTests;

  Assert.AreEqual(3, TClassInheritedFromAnotherClass.SetupCalled);
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheSetupFunctionMustCallTheProcedureFromInheritedClass;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];

  TClassInheritedFromWithoutSetupAndTearDown.SetupCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassInheritedFromWithoutSetupAndTearDown.SetupCalled);
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFixtureMustCallOnlyOneTimeTheFunction;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];

  TClassInheritedFromAnotherClass.TearDownFixtureCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassInheritedFromAnotherClass.TearDownFixtureCalled);
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFixtureMustCallTheProcedureFromInheritedClass;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];

  TClassInheritedFromWithoutSetupAndTearDown.TearDownFixtureCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassInheritedFromWithoutSetupAndTearDown.TearDownFixtureCalled);
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFunctionMustCallOnlyOneByTest;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test11', 'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test12',
    'Test.Insight.Framework.Classes.Test.TClassInheritedFromAnotherClass.Test13'];

  TClassInheritedFromAnotherClass.TearDownCalled := 0;

  ExecuteTests;

  Assert.AreEqual(3, TClassInheritedFromAnotherClass.TearDownCalled);
end;

procedure TTestInsightFrameworkTest.WhenAClassInheritesTheTearDownFunctionMustCallTheProcedureFromInheritedClass;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];

  TClassInheritedFromWithoutSetupAndTearDown.TearDownCalled := 0;

  ExecuteTests;

  Assert.AreEqual(1, TClassInheritedFromWithoutSetupAndTearDown.TearDownCalled);
end;

procedure TTestInsightFrameworkTest.WhenAnAsyncAssertIsCalledTheTestsMustStopExecutingUntilResumeIsCalled;
begin
  var ExecutedCount := 0;
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithAsyncTest.Test1', 'Test.Insight.Framework.Classes.Test.TClassWithAsyncTest.Test2', 'Test.Insight.Framework.Classes.Test.TClassWithAsyncTest.Test3',
    'Test.Insight.Framework.Classes.Test.TClassWithAsyncTest.Test4', 'Test.Insight.Framework.Classes.Test.TClassWithAsyncTest.AsyncAssert'];

  ExecuteTests;

  for var Result in FClient.PostedTests.Values do
    if Result.ResultType <> TResultType.Skipped then
      Inc(ExecutedCount);

  Assert.AreEqual(3, ExecutedCount);
end;

procedure TTestInsightFrameworkTest.WhenAnInheritedClassHasSetupAndTearDownMethodsMustCallOnlyTheMethodsInTheHigherClassInheritance;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixtureHighInheritance.MyTest'];

  TClassWithSetupAndTearDownFixtureHighInheritance.SetupCalled := 0;
  TClassWithSetupAndTearDownFixtureHighInheritance.SetupFixtureCalled := 0;
  TClassWithSetupAndTearDownFixtureHighInheritance.TearDownCalled := 0;
  TClassWithSetupAndTearDownFixtureHighInheritance.TearDownFixtureCalled := 0;

  ExecuteTestsAndWait;

  Assert.AreEqual(1, TClassWithSetupAndTearDownFixtureHighInheritance.SetupCalled, 'Setup');
  Assert.AreEqual(1, TClassWithSetupAndTearDownFixtureHighInheritance.SetupFixtureCalled, 'Setup fixture');
  Assert.AreEqual(1, TClassWithSetupAndTearDownFixtureHighInheritance.TearDownCalled, 'Tear down');
  Assert.AreEqual(1, TClassWithSetupAndTearDownFixtureHighInheritance.TearDownFixtureCalled, 'Tear down fixture');
end;

procedure TTestInsightFrameworkTest.WhenATestFailMustPostTheResultError;
begin
  ExecuteTests;

  var TestResult := FClient.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'];

  Assert.AreEqual(TResultType.Failed, TestResult.ResultType);
end;

procedure TTestInsightFrameworkTest.WhenATestRaiseAnErrorMustPostTheError;
begin
  ExecuteTests;

  var TestResult := FClient.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest2.Test'];

  Assert.AreEqual(TResultType.Error, TestResult.ResultType);
  Assert.AreEqual('An error!', TestResult.ExceptionMessage);
end;

procedure TTestInsightFrameworkTest.WhenCallTheStartedTestingMustLoadTheTotalTestsToBeExecuted;
begin
  ExecuteTests;

  Assert.AreEqual(TEST_COUNT, FClient.TotalTests);
end;

procedure TTestInsightFrameworkTest.WhenDiscoveringTestsCantExecuteAnyTest;
begin
  FClient.FOptions.ExecuteTests := False;

  TClassWithSetupAndTearDownFixture.SetupCalled := 0;
  TClassWithSetupAndTearDownFixture.SetupFixtureCalled := 0;
  TClassWithSetupAndTearDownFixture.TearDownCalled := 0;
  TClassWithSetupAndTearDownFixture.TearDownFixtureCalled := 0;
  TClassWithSetupAndTearDownFixture.TestCalled := 0;

  ExecuteTests;

  Assert.AreEqual(0, TClassWithSetupAndTearDownFixture.SetupCalled + TClassWithSetupAndTearDownFixture.SetupFixtureCalled + TClassWithSetupAndTearDownFixture.TearDownCalled
    + TClassWithSetupAndTearDownFixture.TearDownFixtureCalled + TClassWithSetupAndTearDownFixture.TestCalled);
end;

procedure TTestInsightFrameworkTest.WhenExecuteAnAsyncAssertionCantDestroyTheClassBeforeTheResumeIsCalled;
begin
  TClassWithAsyncTest.DestroyCalled := False;

  ExecuteTests;

  Assert.IsFalse(TClassWithAsyncTest.DestroyCalled);
end;

procedure TTestInsightFrameworkTest.WhenExecuteATestWithAsyncAssertionMustExecuteTheAssertionWhemCallTheResume;
begin
  TClassWithAsyncTest.AssertCalled := False;

  ExecuteTests;

  Assert.IsFalse(TClassWithAsyncTest.AssertCalled);

  WaitForTimer;

  Assert.IsTrue(TClassWithAsyncTest.AssertCalled);
end;

procedure TTestInsightFrameworkTest.WhenExecuteTheTestsOfAClassMustCallTheSetupProcedureForEveryTestProcedureCalled;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];

  TClassWithSetupAndTearDownFixture.SetupCalled := 0;

  ExecuteTests;

  Assert.AreEqual(3, TClassWithSetupAndTearDownFixture.SetupCalled);
end;

procedure TTestInsightFrameworkTest.WhenExecuteTheTestsOfAClassMustCallTheTearDownProcedureForEveryTestProcedureCalled;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test', 'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test2',
    'Test.Insight.Framework.Classes.Test.TClassWithSetupAndTearDownFixture.Test3'];

  TClassWithSetupAndTearDownFixture.TearDownCalled := 0;

  ExecuteTests;

  Assert.AreEqual(3, TClassWithSetupAndTearDownFixture.TearDownCalled);
end;

procedure TTestInsightFrameworkTest.WhenHasSelectedTestsMustRunOnlyTheSelectedTests;
begin
  var ExecutedCount := 0;
  var TestName := 'Test.Insight.Framework.Classes.Test.TMyClassTest3.Test2';

  FClient.Tests := [TestName];

  ExecuteTests;

  for var Result in FClient.PostedTests.Values do
    if Result.ResultType <> TResultType.Skipped then
      Inc(ExecutedCount);

  Assert.AreEqual(1, ExecutedCount);

  Assert.AreEqual(TResultType.Passed, FClient.PostedTests[TestName].ResultType);
end;

procedure TTestInsightFrameworkTest.WhenRunTheTestsMustStartTheTestInTheClient;
begin
  ExecuteTests;

  Assert.IsTrue(FClient.CalledProcedures.Contains(';StartedTesting;'));
end;

procedure TTestInsightFrameworkTest.WhenTerminateTheExecutionMustCallOnTerminateEvent;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];
  var OnTerminateCalled := False;
  var Test := TTestInsightFramework.Create(FClient, nil, False);

  Test.OnTerminate :=
    procedure
    begin
      OnTerminateCalled := True;
    end;

  Test.Run;

  Sleep(100);

  Assert.IsTrue(OnTerminateCalled);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheObjectResolverFunctionIsFilledMustCallTheFunctionToCreateTheObjectInstance;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TClassInheritedFromWithoutSetupAndTearDown.Test11'];
  var FunctionExecuted := False;
  var Test := TTestInsightFramework.Create(FClient,
    function (&Type: TRttiInstanceType): TObject
    begin
      FunctionExecuted := True;
      Result := TClassInheritedFromWithoutSetupAndTearDown.Create;
    end, False);

  Test.Run;

  Assert.IsTrue(FunctionExecuted);

  Test.Free;
end;

procedure TTestInsightFrameworkTest.WhenTheSetupFixtureRaiseAnErrorCantStopExecutingTheTests;
begin
  TClassWithSetupError.SetupFixtureRaiseError := True;

  ExecuteTestsAndWait;

  Assert.AreEqual(TEST_COUNT, FClient.PostedTests.Count);
end;

procedure TTestInsightFrameworkTest.WhenTheTearDownFixtureRaiseAnErrorCantStopExecutingTheTest;
begin
  TClassWithSetupError.TearDownFixtureRaiseError := True;

  ExecuteTestsAndWait;

  Assert.AreEqual(TEST_COUNT, FClient.PostedTests.Count);
end;

procedure TTestInsightFrameworkTest.WhenTheTestFailMustRegisterTheErrorMessageInTheResult;
begin
  ExecuteTests;

  var TestResult := FClient.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'];

  Assert.AreEqual('The value expected is 10 and the current value is 20', TestResult.ExceptionMessage);
end;

procedure TTestInsightFrameworkTest.WhenTheTestIsExecutedMustPostTheResultHasSuccess;
begin
  ExecuteTests;

  var TestResult := FClient.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test'];

  Assert.AreEqual(TResultType.Passed, TestResult.ResultType);
end;

procedure TTestInsightFrameworkTest.WhenTheTestIsntExecutedMustRegisterTheTestAsSkiped;
begin
  FClient.Tests := ['Test.Insight.Framework.Classes.Test.TMyClassTest.Test'];

  ExecuteTests;

  Assert.IsTrue(FClient.PostedTests.ContainsKey('Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'));

  var TestResult := FClient.PostedTests['Test.Insight.Framework.Classes.Test.TMyClassTest.Test2'];

  Assert.AreEqual(TResultType.Skipped, TestResult.ResultType);
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
  TotalTests := totalCount;

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

