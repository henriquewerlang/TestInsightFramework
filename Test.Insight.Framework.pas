unit Test.Insight.Framework;

interface

uses System.SysUtils, System.Rtti, System.Generics.Collections, TestInsight.Client, {$IFDEF DCC}Vcl.ExtCtrls{$ENDIF}{$IFDEF PAS2JS}System.Timer, JSApi.JS{$ENDIF};

type
  SetupAttribute = class(TCustomAttribute);
  SetupFixtureAttribute = class(TCustomAttribute);
  TearDownAttribute = class(TCustomAttribute);
  TearDownFixtureAttribute = class(TCustomAttribute);
  TestAttribute = class(TCustomAttribute);
  TestFixtureAttribute = class(TCustomAttribute);
  TObjectResolver = TFunc<TRttiInstanceType, TObject>;
  TTestClassMethod = class;
  TTestInsightFramework = class;

  EAsyncAssert = class(Exception)
  private
    FAssertAsyncProcedure: TProc;
    FTimeOut: Integer;
  public
    constructor Create(const AssertAsyncProcedure: TProc; const TimeOut: Integer);

    property AssertAsyncProcedure: TProc read FAssertAsyncProcedure;
    property TimeOut: Integer read FTimeOut;
  end;

  EAsyncAssertEmptyProcedure = class(Exception)
  public
    constructor Create;
  end;

  EAssertFail = class(Exception)
  public
    constructor Create(const AssertionMessage, Message: String); reintroduce;
  end;

{$M+}
  TTestClass = class
  private
    FAssertAsyncProcedure: TProc;
    FInstance: TObject;
    FInstanceType: TRttiInstanceType;
    FMethods: TList<TTestClassMethod>;
    FQueueMethods: TQueue<TTestClassMethod>;
    FTester: TTestInsightFramework;
    FTestSetup: TRttiMethod;
    FTestSetupFixture: TRttiMethod;
    FTestTearDown: TRttiMethod;
    FTestTearDownFixture: TRttiMethod;

    procedure CallMethod(const Instance: TObject; const Method: TRttiMethod; const NextProcedure: TProc; const SuccessProcedure: TProc = nil); overload;
    procedure CallMethod(const Method: TRttiMethod; const NextProcedure: TProc; const SuccessProcedure: TProc = nil); overload;
    procedure CheckException(ExceptionObject: TObject);
    procedure ContinueTesting;
    procedure ExecuteTestMethod(const Instance: TObject; const TestMethod: TRttiMethod);
    procedure ExecuteTests;
    procedure FinishClassTestExecution;
    procedure FinishMethodTestExecution;
    procedure FinishMethodTestExecutionError(const Message: String);
    procedure FinishMethodTestExecutionFail(const Message: String);
    procedure FinishMethodTestExecutionPassed;
    procedure LoadSetupAndTearDownMethods;
    procedure OnTimerAssertAsync(Sender: TObject);
    procedure StartMethodTestExecution(const TestMethod: TTestClassMethod);
    procedure TearDownMethod;

    property Instance: TObject read FInstance;
  public
    constructor Create(const InstanceType: TRttiInstanceType; const Tester: TTestInsightFramework);

    destructor Destroy; override;

    function AddTestMethod(const Method: TRttiMethod; const CanExecuteTest: Boolean): TTestClassMethod;

    procedure Execute;

    property InstanceType: TRttiInstanceType read FInstanceType;
  published
    procedure ExecutEAsyncAssert;
  end;

  TTestClassMethod = class
  private
    FTestClass: TTestClass;
    FTestMethod: TRttiMethod;

    procedure ExecuteTest;
  public
    constructor Create(const TestMethod: TRttiMethod; const TestClass: TTestClass);

    procedure Execute;

    property TestMethod: TRttiMethod read FTestMethod;
  end;

  TTestInsightFramework = class
  private
    FAutoDestroy: Boolean;
    FContext: TRttiContext;
    FObjectResolver: TObjectResolver;
    FOnTerminate: TProc;
    FTestInsightClient: ITestInsightClient;
    FTestQueue: TQueue<TTestClass>;
    FTestResult: TTestInsightResult;
    FTestStartedTime: TDateTime;

    function CreateObject(&Type: TRttiInstanceType): TObject;

    procedure DoExecuteTests;
    procedure FillTestResult(const TestMethod: TTestClassMethod);
    procedure FinishTestClassExecution;
    procedure FinishTestExecution;
    procedure FinishTestMethodExecution;
    procedure FinishTestMethodExecutionError(Message: String);
    procedure FinishTestMethodExecutionFail(Message: String);
    procedure FinishTestMethodExecutionPassed;
    procedure FinishTestMethodExecutionPostResult;
    procedure PostTestResult;
    procedure ShowException(const Error: TObject);
    procedure StartTestClassExecution(const TestClass: TTestClass);
    procedure StartTestMethodExecution(const TestMethod: TTestClassMethod);

    property Context: TRttiContext read FContext;
  public
    constructor Create(const ObjectResolver: TObjectResolver; const AutoDestroy: Boolean); overload;
    constructor Create(const TestInsightClient: ITestInsightClient; const ObjectResolver: TObjectResolver; const AutoDestroy: Boolean); overload;

    destructor Destroy; override;

    procedure Run;

    class procedure ExecuteTests; overload;
    class procedure ExecuteTests(const ObjectResolver: TObjectResolver); overload;

    property OnTerminate: TProc read FOnTerminate write FOnTerminate;
  end;

  Assert = class
  private
    class procedure RaiseAssert(const Expected, CurrentValue: TValue; const Message: String);
  public
    class procedure AreEqual(const Expected, CurrentValue: Integer; const Message: String = ''); overload;
    class procedure AreEqual(const Expected, CurrentValue: Int64; const Message: String = ''); overload;
    class procedure AreEqual(const Expected, CurrentValue: Extended; const Message: String = ''); overload;
    class procedure AreEqual(const Expected, CurrentValue: String; const Message: String = ''); overload;
    class procedure AreEqual(const Expected, CurrentValue: Pointer; const Message: String = ''); overload;
    class procedure AreEqual(const Expected, CurrentValue: TClass; const Message: String = ''); overload;
    class procedure AreEqual(const Expected, CurrentValue: TDateTime; const Message: String = ''); overload;
    class procedure AreEqual(const Expected, CurrentValue: TObject; const Message: String = ''); overload;
{$IFDEF DCC}
    class procedure AreEqual(const Expected, CurrentValue: Variant; const Message: String = ''); overload;
{$ENDIF}
    class procedure Async(const Proc: TProc; const TimeOut: Integer = 100; const Message: String = '');
    class procedure CheckExpectation(const Expectation: String; const Message: String = '');
    class procedure GreaterThan(const Expected, CurrentValue: NativeInt; const Message: String = '');
    class procedure IsEmpty(const Value: String; const Message: String = '');
    class procedure IsFalse(const Value: Boolean; const Message: String = '');
    class procedure IsNil(const Value: Pointer; const Message: String = '');
    class procedure IsNotEmpty(const Value: String; const Message: String = '');
    class procedure IsNotNil(const Value: Pointer; const Message: String = '');
    class procedure IsTrue(const Value: Boolean; const Message: String = '');
    class procedure StartWith(const Expected, Value: String; const Message: String = '');
    class procedure WillNotRaise(const Proc: TProc; const Message: String = '');
    class procedure WillRaise(const Proc: TProc; const ExceptionClass: ExceptClass; const Message: String = '');
  end;

implementation

uses System.DateUtils, {$IFDEF DCC}Vcl.Forms{$ENDIF}{$IFDEF PAS2JS}BrowserApi.Web{$ENDIF};

{$IFDEF PAS2JS}
var
  AcquireExceptionObject: TObject; external name '$e';
{$ENDIF}


{ TTestInsightFramework }

constructor TTestInsightFramework.Create(const TestInsightClient: ITestInsightClient; const ObjectResolver: TObjectResolver; const AutoDestroy: Boolean);
begin
  inherited Create;

  FAutoDestroy := AutoDestroy;
  FContext := TRttiContext.Create;
  FObjectResolver := ObjectResolver;
  FTestInsightClient := TestInsightClient;
  FTestQueue := TObjectQueue<TTestClass>.Create;

  if not Assigned(FObjectResolver) then
    FObjectResolver := CreateObject;
end;

constructor TTestInsightFramework.Create(const ObjectResolver: TObjectResolver; const AutoDestroy: Boolean);
begin
  Create(TTestInsightRestClient.Create as ITestInsightClient, ObjectResolver, AutoDestroy);
end;

function TTestInsightFramework.CreateObject(&Type: TRttiInstanceType): TObject;
begin
  Result := &Type.MetaclassType.Create;
end;

destructor TTestInsightFramework.Destroy;
begin
  FTestQueue.Free;

  inherited;
end;

procedure TTestInsightFramework.DoExecuteTests;
begin
  try
    while not FTestQueue.IsEmpty do
      FTestQueue.Peek.Execute;

    FinishTestExecution;
  except
    ShowException(AcquireExceptionObject);
  end;
end;

class procedure TTestInsightFramework.ExecuteTests(const ObjectResolver: TObjectResolver);
var
  Test: TTestInsightFramework;

begin
  Test := TTestInsightFramework.Create(ObjectResolver, True);

  Test.Run;
end;

procedure TTestInsightFramework.FillTestResult(const TestMethod: TTestClassMethod);
begin
  FTestResult.ClassName := TestMethod.FTestClass.InstanceType.Name;
  FTestResult.Duration := 0;
  FTestResult.ExceptionMessage := EmptyStr;
  FTestResult.FixtureName := TestMethod.FTestClass.InstanceType.DeclaringUnitName;
  FTestResult.LineNumber := 0;
  FTestResult.MethodName := EmptyStr;
  FTestResult.MethodName := TestMethod.TestMethod.Name;
  FTestResult.Path := TestMethod.FTestClass.InstanceType.QualifiedName;
  FTestResult.ResultType := TResultType.Skipped;
  FTestResult.Status := EmptyStr;
  FTestResult.TestName := EmptyStr;
  FTestResult.TestName := TestMethod.TestMethod.Name;
  FTestResult.UnitName := TestMethod.FTestClass.InstanceType.DeclaringUnitName;
end;

procedure TTestInsightFramework.FinishTestClassExecution;
begin
  FTestQueue.Dequeue;

  FinishTestMethodExecution;
end;

procedure TTestInsightFramework.FinishTestExecution;
begin
  FTestInsightClient.FinishedTesting;

  if Assigned(FOnTerminate) then
    OnTerminate();

  if FAutoDestroy then
    Free;
end;

procedure TTestInsightFramework.FinishTestMethodExecution;
begin

end;

procedure TTestInsightFramework.FinishTestMethodExecutionError(Message: String);
begin
  FTestResult.ExceptionMessage := Message;
  FTestResult.ResultType := TResultType.Error;

  FinishTestMethodExecutionPostResult;
end;

procedure TTestInsightFramework.FinishTestMethodExecutionFail(Message: String);
begin
  FTestResult.ExceptionMessage := Message;
  FTestResult.ResultType := TResultType.Failed;

  FinishTestMethodExecutionPostResult;
end;

procedure TTestInsightFramework.FinishTestMethodExecutionPassed;
begin
  FTestResult.ResultType := TResultType.Passed;

  FinishTestMethodExecutionPostResult;
end;

procedure TTestInsightFramework.FinishTestMethodExecutionPostResult;
begin
  FTestResult.Duration := MilliSecondsBetween(Now, FTestStartedTime);

  FinishTestMethodExecution;

  PostTestResult;
end;

procedure TTestInsightFramework.PostTestResult;
begin
  FTestInsightClient.PostResult(FTestResult);
end;

class procedure TTestInsightFramework.ExecuteTests;
begin
  ExecuteTests(nil);
end;

procedure TTestInsightFramework.Run;
var
  ExecuteTests: Boolean;
  SelectedTests: TArray<String>;
  TestClass: TTestClass;

  function CanExecuteTest(const MethodName: String): Boolean;
  var
    TestName: String;

  begin
    Result := ExecuteTests and (Length(SelectedTests) = 0);

    if not Result then
      for TestName in SelectedTests do
        if Format('%s.%s', [TestClass.InstanceType.QualifiedName, MethodName]) = TestName then
          Result := True;
  end;

  procedure DiscoveryAllTests;
  var
    RttiType: TRttiType;
    TestMethod: TRttiMethod;

  begin
    ExecuteTests := FTestInsightClient.Options.ExecuteTests;
    SelectedTests := FTestInsightClient.GetTests;

    for RttiType in Context.GetTypes do
      if RttiType.IsInstance and RttiType.HasAttribute<TestFixtureAttribute> then
      begin
        TestClass := TTestClass.Create(RttiType.AsInstance, Self);

        FTestQueue.Enqueue(TestClass);

        for TestMethod in RttiType.GetMethods do
          if TestMethod.HasAttribute<TestAttribute> then
          begin
            FillTestResult(TestClass.AddTestMethod(TestMethod, CanExecuteTest(TestMethod.Name)));

            PostTestResult;
          end;
      end;
  end;

  function GetTestCount: Integer;
  var
    TestClass: TTestClass;

    TestClassMethod: TTestClassMethod;

  begin
    Result := 0;

    for TestClass in FTestQueue do
      for TestClassMethod in TestClass.FMethods do
        Inc(Result);
  end;

begin
  DiscoveryAllTests;

  FTestInsightClient.StartedTesting(GetTestCount);

  DoExecuteTests;
end;

procedure TTestInsightFramework.ShowException(const Error: TObject);
begin
  if Error is EAbort then
{$IFDEF DCC}
    Error.Free
{$ENDIF}
  else
    raise Error;
end;

procedure TTestInsightFramework.StartTestClassExecution(const TestClass: TTestClass);
begin
  FTestStartedTime := Now;
end;

procedure TTestInsightFramework.StartTestMethodExecution(const TestMethod: TTestClassMethod);
begin
  FTestStartedTime := Now;

  FillTestResult(TestMethod);

  FTestResult.ResultType := TResultType.Running;

  PostTestResult;
end;

{ Assert }

class procedure Assert.AreEqual(const Expected, CurrentValue, Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Integer; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Int64; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Extended; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: TDateTime; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: TObject; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
 end;

class procedure Assert.Async(const Proc: TProc; const TimeOut: Integer; const Message: String);
begin
  if not Assigned(Proc) then
    raise EAsyncAssertEmptyProcedure.Create;

  raise EAsyncAssert.Create(Proc, TimeOut);
end;

class procedure Assert.CheckExpectation(const Expectation, Message: String);
begin
  if not Expectation.IsEmpty then
    raise EAssertFail.Create(Format('Expectation not achieved [%s]', [Expectation]), Message);
end;

class procedure Assert.GreaterThan(const Expected, CurrentValue: NativeInt; const Message: String);
begin
  if not (CurrentValue > Expected) then
    raise EAssertFail.Create(Format('The value must be greater than %s, current value %s!', [Expected.ToString, CurrentValue.ToString]), Message);
end;

class procedure Assert.IsEmpty(const Value, Message: String);
begin
  if {$IFDEF PAS2JS}not IsString(Value) or {$ENDIF} not Value.IsEmpty then
    raise EAssertFail.Create('The string must be empty!', Message);
end;

class procedure Assert.IsFalse(const Value: Boolean; const Message: String);
begin
  if Value then
    raise EAssertFail.Create('A FALSE value is expected!', Message);
end;

class procedure Assert.IsNil(const Value: Pointer; const Message: String);
begin
  if Assigned(Value) then
    raise EAssertFail.Create('A nil pointer expected!', Message);
end;

class procedure Assert.IsNotEmpty(const Value, Message: String);
begin
  if {$IFDEF PAS2JS}not IsString(Value) or {$ENDIF}Value.IsEmpty then
    raise EAssertFail.Create('The string must not be empty!', Message);
end;

class procedure Assert.IsNotNil(const Value: Pointer; const Message: String);
begin
  if not Assigned(Value) then
    raise EAssertFail.Create('Not nil pointer expected!', Message);
end;

class procedure Assert.IsTrue(const Value: Boolean; const Message: String);
begin
  if not Value then
    raise EAssertFail.Create('A TRUE value is expected!', Message);
end;

class procedure Assert.RaiseAssert(const Expected, CurrentValue: TValue; const Message: String);
begin
  raise EAssertFail.Create(Format('The value expected is %s and the current value is %s', [Expected.ToString, CurrentValue.ToString]), Message);
end;

class procedure Assert.StartWith(const Expected, Value, Message: String);
begin
  if not Value.StartsWith(Expected) then
    raise EAssertFail.Create(Format('Expected start with "%s" but started with "%s"', [Expected, Value]), Message);
end;

class procedure Assert.WillNotRaise(const Proc: TProc; const Message: String);
begin
  try
    Proc();
  except
    on Error: Exception do
      raise EAssertFail.Create(Format('Unexpected exception raised %s!', [Error.ClassName]), Message);
{$IFDEF PAS2JS}
    on JSError: TJSError do
      raise EAssertFail.Create(Format('Unexpected exception raised %s!', [JSError.ToString]), Message);
{$ENDIF}
  end;
end;

class procedure Assert.WillRaise(const Proc: TProc; const ExceptionClass: ExceptClass; const Message: String);
begin
  try
    Proc();
  except
    on Error: Exception do
      if Error is ExceptionClass then
        Exit
      else
        raise EAssertFail.Create(Format('Unexpected exception raised %s!', [Error.ClassName]), Message);
{$IFDEF PAS2JS}
    on JSError: TJSError do
      raise EAssertFail.Create(Format('Unexpected exception raised %s!', [JSError.ToString]), Message);
{$ENDIF}
  end;

  raise EAssertFail.Create('No exceptions raised!', Message);
end;

{$IFDEF DCC}
class procedure Assert.AreEqual(const Expected, CurrentValue: Variant; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.FromVariant(Expected), TValue.FromVariant(CurrentValue), Message);
end;
{$ENDIF}

class procedure Assert.AreEqual(const Expected, CurrentValue: TClass; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Pointer; const Message: String);
begin
  if Expected <> CurrentValue then
    RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
end;

{ TTestClassMethod }

constructor TTestClassMethod.Create(const TestMethod: TRttiMethod; const TestClass: TTestClass);
begin
  inherited Create;

  FTestClass := TestClass;
  FTestMethod := TestMethod;
end;

procedure TTestClassMethod.Execute;
begin
  FTestClass.StartMethodTestExecution(Self);

  FTestClass.CallMethod(FTestClass.FTestSetup, ExecuteTest);
end;

procedure TTestClassMethod.ExecuteTest;
begin
  FTestClass.ExecuteTestMethod(FTestClass.Instance, FTestMethod);
end;

{ TTestClass }

function TTestClass.AddTestMethod(const Method: TRttiMethod; const CanExecuteTest: Boolean): TTestClassMethod;
begin
  Result := TTestClassMethod.Create(Method, Self);

  FMethods.Add(Result);

  if CanExecuteTest then
    FQueueMethods.Enqueue(Result);
end;

procedure TTestClass.CallMethod(const Method: TRttiMethod; const NextProcedure, SuccessProcedure: TProc);
begin
  CallMethod(Instance, Method, NextProcedure, SuccessProcedure);
end;

procedure TTestClass.CallMethod(const Instance: TObject; const Method: TRttiMethod; const NextProcedure, SuccessProcedure: TProc);

  procedure ExecuteSuccess;
  begin
    if Assigned(SuccessProcedure) then
      SuccessProcedure;
  end;

begin
  try
    if Assigned(Method) then
{$IFDEF PAS2JS}
      if Method.IsAsyncCall then
      begin
        Method.Invoke(Instance, []).AsType<TJSPromise>
          .&Then(
            procedure
            begin
              ExecuteSuccess;
            end)
          .Catch(
            procedure (Exception: TObject)
            begin
              CheckException(Exception);
            end)
          .&Then(
            procedure
            begin
              NextProcedure;

              ContinueTesting;
            end)
          .Catch(
            procedure (Exception: TObject)
            begin
              FTester.ShowException(Exception);
            end);

        Abort;
      end
      else
{$ENDIF}
      Method.Invoke(Instance, []);

    ExecuteSuccess;
  except
    CheckException(AcquireExceptionObject);
  end;

  NextProcedure;
end;

procedure TTestClass.CheckException(ExceptionObject: TObject);
var
  AssertAsync: EAsyncAssert absolute ExceptionObject;
  Error: Exception absolute ExceptionObject;
  TestFail: EAssertFail absolute ExceptionObject;
  Timer: TTimer;
{$IFDEF PAS2JS}
  JSErro: TJSError absolute ExceptionObject;
  JSMessage: String absolute ExceptionObject;
{$ENDIF}

begin
  try
    if ExceptionObject is EAsyncAssert then
    begin
      FAssertAsyncProcedure := AssertAsync.AssertAsyncProcedure;

      Timer := TTimer.Create(nil);
      Timer.Interval := AssertAsync.TimeOut;
      Timer.OnTimer := OnTimerAssertAsync;

      Abort;
    end
    else if ExceptionObject is EAbort then
      Abort
    else if ExceptionObject is EAssertFail then
      FinishMethodTestExecutionFail(TestFail.Message)
{$IFDEF PAS2JS}
    else if JSValue(ExceptionObject) is TJSError then
      FinishMethodTestExecutionError(JSErro.Message)
    else if isString(ExceptionObject) then
      FinishMethodTestExecutionError(JSMessage)
{$ENDIF}
    else if ExceptionObject is Exception then
      if Error.Message.IsEmpty then
        FinishMethodTestExecutionError(Error.QualifiedClassName)
      else
        FinishMethodTestExecutionError(Error.Message);
  finally
{$IFDEF DCC}
    ExceptionObject.Free;
{$ENDIF}
  end;
end;

procedure TTestClass.ContinueTesting;
begin
  FTester.DoExecuteTests;
end;

constructor TTestClass.Create(const InstanceType: TRttiInstanceType; const Tester: TTestInsightFramework);
begin
  inherited Create;

  FInstanceType := InstanceType;
  FMethods := TObjectList<TTestClassMethod>.Create;
  FQueueMethods := TQueue<TTestClassMethod>.Create;
  FTester := Tester;

  LoadSetupAndTearDownMethods;
end;

destructor TTestClass.Destroy;
begin
  FInstance.Free;

  FQueueMethods.Free;

  FMethods.Free;

  inherited;
end;

procedure TTestClass.Execute;
begin
  FTester.StartTestClassExecution(Self);

  if not FQueueMethods.IsEmpty then
  begin
    if Assigned(FInstance) then
      ExecuteTests
    else
    begin
      FInstance := FTester.FObjectResolver(InstanceType);

      CallMethod(FTestSetupFixture, ExecuteTests);
    end;
  end
  else if Assigned(FInstance) then
    CallMethod(FTestTearDownFixture, FinishClassTestExecution)
  else
    FinishClassTestExecution;
end;

procedure TTestClass.ExecutEAsyncAssert;
begin
  FAssertAsyncProcedure();
end;

procedure TTestClass.ExecuteTestMethod(const Instance: TObject; const TestMethod: TRttiMethod);
begin
  CallMethod(Instance, TestMethod, TearDownMethod, FinishMethodTestExecutionPassed);
end;

procedure TTestClass.ExecuteTests;
begin
  FQueueMethods.Peek.Execute;
end;

procedure TTestClass.FinishClassTestExecution;
begin
  FTester.FinishTestClassExecution;
end;

procedure TTestClass.FinishMethodTestExecution;
begin
  FQueueMethods.Dequeue;

  FTester.FinishTestMethodExecution;
end;

procedure TTestClass.FinishMethodTestExecutionError(const Message: String);
begin
  FTester.FinishTestMethodExecutionError(Message);
end;

procedure TTestClass.FinishMethodTestExecutionFail(const Message: String);
begin
  FTester.FinishTestMethodExecutionFail(Message);
end;

procedure TTestClass.FinishMethodTestExecutionPassed;
begin
  FTester.FinishTestMethodExecutionPassed;
end;

procedure TTestClass.LoadSetupAndTearDownMethods;
var
  Method: TRttiMethod;

begin
  for Method in InstanceType.GetMethods do
    if Method.HasAttribute<SetupFixtureAttribute> and not Assigned(FTestSetupFixture) then
      FTestSetupFixture := Method
    else if Method.HasAttribute<TearDownFixtureAttribute> and not Assigned(FTestTearDownFixture) then
      FTestTearDownFixture := Method
    else if Method.HasAttribute<SetupAttribute> and not Assigned(FTestSetup) then
      FTestSetup := Method
    else if Method.HasAttribute<TearDownAttribute> and not Assigned(FTestTearDown) then
      FTestTearDown := Method;
end;

procedure TTestClass.OnTimerAssertAsync(Sender: TObject);
var
  ExecutEAsyncAssertMethod: TRttiMethod;
  Timer: TTimer absolute Sender;

begin
  ExecutEAsyncAssertMethod := FTester.Context.GetType(ClassType).GetMethod('ExecutEAsyncAssert');
  Timer.Enabled := False;

  Timer.Free;

  try
    ExecuteTestMethod(Self, ExecutEAsyncAssertMethod);

    ContinueTesting;
  except
    FTester.ShowException(AcquireExceptionObject);
  end;
end;

procedure TTestClass.StartMethodTestExecution(const TestMethod: TTestClassMethod);
begin
  FTester.StartTestMethodExecution(TestMethod);
end;

procedure TTestClass.TearDownMethod;
begin
  CallMethod(FTestTearDown, FinishMethodTestExecution);
end;

{ EAsyncAssert }

constructor EAsyncAssert.Create(const AssertAsyncProcedure: TProc; const TimeOut: Integer);
begin
  inherited Create('Async Assert');

  FAssertAsyncProcedure := AssertAsyncProcedure;
  FTimeOut := TimeOut;
end;

{ EAsyncAssertEmptyProcedure }

constructor EAsyncAssertEmptyProcedure.Create;
begin
  inherited Create('The asynchronous procedure can''t be nil!');
end;

{ EAssertFail }

constructor EAssertFail.Create(const AssertionMessage, Message: String);
begin
  if Message.IsEmpty then
    inherited Create(AssertionMessage)
  else
    inherited CreateFmt('%s, Message: %s', [AssertionMessage, Message]);
end;

end.

