unit Test.Insight.Framework;

interface

uses System.SysUtils, System.Rtti, System.Generics.Collections, System.Classes, TestInsight.Client, {$IFDEF DCC}Vcl.ExtCtrls{$ELSE}System.Timer, JSApi.JS{$ENDIF};

type
{$IFDEF PAS2JS}
  Variant = JSValue;
{$ENDIF}

  TDelayedProcedureAttribute = class(TCustomAttribute)
  private
    FDelay: Integer;

    constructor Create(const Delay: Integer);
  public
    property Delay: Integer read FDelay write FDelay;
  end;

  SetupAttribute = class(TDelayedProcedureAttribute);
  SetupFixtureAttribute = class(TDelayedProcedureAttribute);
  TearDownAttribute = class(TDelayedProcedureAttribute);
  TearDownFixtureAttribute = class(TDelayedProcedureAttribute);
  TestAttribute = class(TCustomAttribute);
  TestFixtureAttribute = class(TCustomAttribute);
  TObjectResolver = TFunc<TRttiInstanceType, TObject>;
  TTestClassMethod = class;
  TTestInsightFramework = class;

  SetupDelayAttribute = class(SetupAttribute)
  public
    constructor Create; overload;
    constructor Create(const Delay: Integer); overload;
  end;

  SetupFixtureDelayAttribute = class(SetupFixtureAttribute)
  public
    constructor Create; overload;
    constructor Create(const Delay: Integer); overload;
  end;

  TearDownDelayAttribute = class(TearDownAttribute)
  public
    constructor Create; overload;
    constructor Create(const Delay: Integer); overload;
  end;

  TearDownFixtureDelayAttribute = class(TearDownFixtureAttribute)
  public
    constructor Create; overload;
    constructor Create(const Delay: Integer); overload;
  end;

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

  EStopExecution = class(Exception)
  public
    constructor Create;
  end;

  TObjectProcedure = class
  private
    FProc: TProc;
  public
    constructor Create(Proc: TProc);

    procedure Execute;
  end;

{$M+}
  TTestClass = class
  private
    FAsyncProcedure: TProc;
    FExecuteAsyncProcedureMethod: TRttiMethod;
    FInstance: TObject;
    FInstanceType: TRttiInstanceType;
    FQueueMethods: TQueue<TObjectProcedure>;
    FTester: TTestInsightFramework;
    FTestMethods: TList<TTestClassMethod>;
    FTestSetup: TRttiMethod;
    FTestSetupFixture: TRttiMethod;
    FTestTearDown: TRttiMethod;
    FTestTearDownTestClass: TRttiMethod;
    FTestTearDownFixture: TRttiMethod;

    procedure CallMethod(const Instance: TObject; const Method: TRttiMethod; const SuccessProcedure: TProc = nil); overload;
    procedure CallMethod(const Method: TRttiMethod; const SuccessProcedure: TProc = nil); overload;
    procedure CheckException(ExceptionObject: TObject);
    procedure ClassRegisterMethodsFinished;
    procedure ContinueTesting;
    procedure CreateAsyncTimer(const AsyncProcedure: TProc; const TimerEvent: TNotifyEvent; const Interval: Integer);
    procedure ExecuteSetupFixture;
    procedure ExecuteTearDownFixture;
    procedure ExecuteTestMethod(const Instance: TObject; const TestMethod: TRttiMethod);
    procedure FinishClassTestExecution;
    procedure FinishMethodTestExecutionError(const Message: String);
    procedure FinishMethodTestExecutionFail(const Message: String);
    procedure FinishMethodTestExecutionPassed;
    procedure LoadSetupAndTearDownMethods;
    procedure OnTimerAssertAsync(Sender: TObject);
    procedure OnTimerDelayProcedure(Sender: TObject);
    procedure StartMethodTestExecution(const TestMethod: TTestClassMethod);

    class function CreateTimer(const Interval: Integer; const OnTimer: TNotifyEvent): TTimer;

    class procedure FreeTimer(const Sender: TObject);

    property Instance: TObject read FInstance;
  public
    constructor Create(const Tester: TTestInsightFramework; const InstanceType: TRttiInstanceType);

    destructor Destroy; override;

    function AddTestMethod(const Method: TRttiMethod; const CanExecuteTest: Boolean): TTestClassMethod;

    procedure Execute;

    property InstanceType: TRttiInstanceType read FInstanceType;
  published
    procedure ExecutAsyncProcedure;
    procedure ExecuteTearDown;{$IFDEF PAS2JS} async;{$ENDIF}
  end;

  TTestClassMethod = class
  private
    FTestClass: TTestClass;
    FTestMethod: TRttiMethod;
  public
    constructor Create(const TestMethod: TRttiMethod; const TestClass: TTestClass);

    procedure Setup;
    procedure ExecuteTest;
    procedure TearDown;

    property TestMethod: TRttiMethod read FTestMethod;
  end;

  TTestInsightFramework = class
  private
    FAutoDestroy: Boolean;
    FContext: TRttiContext;
    FObjectResolver: TObjectResolver;
    FOnTerminate: TProc;
    FTestClasses: TList<TTestClass>;
    FTestCount: Integer;
    FTestInsightClient: ITestInsightClient;
    FTestQueue: TQueue<TTestClass>;
    FTestResult: TTestInsightResult;
    FTestStartedTime: TDateTime;

    function CreateObject(&Type: TRttiInstanceType): TObject;

    procedure DoExecuteTests;
    procedure FillTestResult(const TestMethod: TTestClassMethod);
    procedure FinishTestClassExecution;
    procedure FinishTestExecution;
    procedure FinishTestMethodExecutionError(Message: String);
    procedure FinishTestMethodExecutionFail(Message: String);
    procedure FinishTestMethodExecutionPassed;
    procedure FinishTestMethodExecutionPostResult;
    procedure PostTestResult;
    procedure ShowException(const Error: TObject);
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
    property TestCount: Integer read FTestCount;
  end;

  Assert = class
  private class var
    FAssertionCalled: Boolean;
  private
    class procedure ExecuteAssertion(const Proc: TProc);
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
    class procedure AreEqual(const Expected, CurrentValue: Variant; const Message: String = ''); overload;
    class procedure Async(const Proc: TProc; const TimeOut: Integer = 100; const Message: String = '');
    class procedure CheckExpectation(const Expectation: String; const Message: String = '');
    class procedure GreaterThan(const Expected, CurrentValue: NativeInt; const Message: String = ''); overload;
    class procedure GreaterThan(const Expected, CurrentValue: Double; const Message: String = ''); overload;
    class procedure IsEmpty(const Value: String; const Message: String = '');
    class procedure IsFalse(const Value: Boolean; const Message: String = '');
    class procedure IsNil(const Value: Pointer; const Message: String = '');
    class procedure IsNotEmpty(const Value: String; const Message: String = '');
    class procedure IsNotNil(const Value: Pointer; const Message: String = '');
    class procedure IsTrue(const Value: Boolean; const Message: String = '');
    class procedure StartWith(const Expected, Value: String; const Message: String = '');
    class procedure WillNotRaise(const Proc: TProc; const Message: String = '');
    class procedure WillRaise(const Proc: TProc; const ExceptionClass: ExceptClass; const Message: String = '');

    class property AssertionCalled: Boolean read FAssertionCalled write FAssertionCalled;
  end;

procedure WaitForPromises(const Timeout: Integer = 5000);{$IFDEF PAS2JS} async;{$ENDIF}

implementation

uses System.DateUtils, {$IFDEF DCC}Vcl.Forms{$ENDIF}{$IFDEF PAS2JS}BrowserApi.Web{$ENDIF};

{$IFDEF PAS2JS}
var
  AcquireExceptionObject: TObject; external name '$e';
{$ENDIF}

procedure StopExecution;
begin
  raise EStopExecution.Create;
end;

procedure WaitForPromises(const Timeout: Integer);
{$IFDEF PAS2JS}
var
  ContinuePromise: TJSPromiseResolvers;
  Timer: TTimer;
  WaitingPromise: TJSPromise;

  procedure ResolvePromise;
  begin
    TTestClass.FreeTimer(Timer);

    ContinuePromise.Resolve;
  end;

  procedure RaiseError;
  begin
    TTestClass.FreeTimer(Timer);

    raise Exception.Create('Timeout execution!');
  end;

{$ENDIF}
begin
{$IFDEF PAS2JS}
  asm
    if (!Promise.hasPromises())
      return;

    ContinuePromise = Promise.continuePromise();
    WaitingPromise = Promise.waitForAll();
  end;

  Timer := TTestClass.CreateTimer(Timeout, TNotifyEvent(@RaiseError));

  await(TJSPromise.Any([WaitingPromise, ContinuePromise.Promise]));

  ResolvePromise;
{$ENDIF}
end;

{ TTestInsightFramework }

constructor TTestInsightFramework.Create(const TestInsightClient: ITestInsightClient; const ObjectResolver: TObjectResolver; const AutoDestroy: Boolean);
begin
  inherited Create;

  FAutoDestroy := AutoDestroy;
  FContext := TRttiContext.Create;
  FObjectResolver := ObjectResolver;
  FTestClasses := TObjectList<TTestClass>.Create;
  FTestInsightClient := TestInsightClient;
  FTestQueue := TQueue<TTestClass>.Create;

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
  FContext.Free;

  FTestQueue.Free;

  FTestClasses.Free;

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
end;

procedure TTestInsightFramework.FinishTestExecution;
begin
  FTestInsightClient.FinishedTesting;

  if Assigned(FOnTerminate) then
    OnTerminate();

  if FAutoDestroy then
    Free;
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
  if Assert.AssertionCalled then
    FTestResult.ResultType := TResultType.Passed
  else
    FTestResult.ResultType := TResultType.Warning;

  FinishTestMethodExecutionPostResult;
end;

procedure TTestInsightFramework.FinishTestMethodExecutionPostResult;
begin
  if FTestStartedTime > 0 then
    FTestResult.Duration := MilliSecondsBetween(Now, FTestStartedTime)
  else
    FTestResult.Duration := 0;

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
    RttiMethod: TRttiMethod;
    RttiType: TRttiType;
    TestMethod: TTestClassMethod;
    WillExecute: Boolean;

  begin
    ExecuteTests := FTestInsightClient.Options.ExecuteTests;
    SelectedTests := FTestInsightClient.GetTests;

    for RttiType in Context.GetTypes do
      if RttiType.IsInstance and RttiType.HasAttribute<TestFixtureAttribute> then
      begin
        TestClass := TTestClass.Create(Self, RttiType.AsInstance);

        FTestClasses.Add(TestClass);

        FTestQueue.Enqueue(TestClass);

        for RttiMethod in RttiType.GetMethods do
          if RttiMethod.HasAttribute<TestAttribute> then
          begin
            WillExecute := CanExecuteTest(RttiMethod.Name);

            TestMethod := TestClass.AddTestMethod(RttiMethod, WillExecute);

            if not WillExecute then
            begin
              FillTestResult(TestMethod);

              PostTestResult;
            end;

            Inc(FTestCount);
          end;

        TestClass.ClassRegisterMethodsFinished;
      end;
  end;

begin
  DiscoveryAllTests;

  FTestInsightClient.StartedTesting(TestCount);

  DoExecuteTests;
end;

procedure TTestInsightFramework.ShowException(const Error: TObject);
begin
  if Error is EStopExecution then
{$IFDEF DCC}
    Error.Free
{$ENDIF}
  else
    raise Error;
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
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Integer; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Int64; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Extended; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: TDateTime; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: TObject; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
 end;

class procedure Assert.Async(const Proc: TProc; const TimeOut: Integer; const Message: String);
begin
  if not Assigned(Proc) then
    raise EAsyncAssertEmptyProcedure.Create;

  raise EAsyncAssert.Create(Proc, TimeOut);
end;

class procedure Assert.CheckExpectation(const Expectation, Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if not Expectation.IsEmpty then
        raise EAssertFail.Create(Format('Expectation not achieved [%s]', [Expectation]), Message);
    end);
end;

class procedure Assert.ExecuteAssertion(const Proc: TProc);
begin
  AssertionCalled := True;

  Proc();
end;

class procedure Assert.GreaterThan(const Expected, CurrentValue: Double; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if not (CurrentValue > Expected) then
        raise EAssertFail.Create(Format('The value must be greater than %s, current value %s!', [Expected.ToString, CurrentValue.ToString]), Message);
    end);
end;

class procedure Assert.GreaterThan(const Expected, CurrentValue: NativeInt; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if not (CurrentValue > Expected) then
        raise EAssertFail.Create(Format('The value must be greater than %s, current value %s!', [Expected.ToString, CurrentValue.ToString]), Message);
    end);
end;

class procedure Assert.IsEmpty(const Value, Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if {$IFDEF PAS2JS}not IsString(Value) or {$ENDIF} not Value.IsEmpty then
        raise EAssertFail.Create('The string must be empty!', Message);
    end);
end;

class procedure Assert.IsFalse(const Value: Boolean; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Value then
        raise EAssertFail.Create('A FALSE value is expected!', Message);
    end);
end;

class procedure Assert.IsNil(const Value: Pointer; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Assigned(Value) then
        raise EAssertFail.Create('A nil pointer expected!', Message);
    end);
end;

class procedure Assert.IsNotEmpty(const Value, Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if {$IFDEF PAS2JS}not IsString(Value) or {$ENDIF}Value.IsEmpty then
        raise EAssertFail.Create('The string must not be empty!', Message);
    end);
end;

class procedure Assert.IsNotNil(const Value: Pointer; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if not Assigned(Value) then
        raise EAssertFail.Create('Not nil pointer expected!', Message);
    end);
end;

class procedure Assert.IsTrue(const Value: Boolean; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if not Value then
        raise EAssertFail.Create('A TRUE value is expected!', Message);
    end);
end;

class procedure Assert.RaiseAssert(const Expected, CurrentValue: TValue; const Message: String);
begin
  raise EAssertFail.Create(Format('The value expected is %s and the current value is %s', [Expected.ToString, CurrentValue.ToString]), Message);
end;

class procedure Assert.StartWith(const Expected, Value, Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if not Value.StartsWith(Expected) then
        raise EAssertFail.Create(Format('Expected start with "%s" but started with "%s"', [Expected, Value]), Message);
    end);
end;

class procedure Assert.WillNotRaise(const Proc: TProc; const Message: String);
begin
  ExecuteAssertion(
    procedure
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
    end);
end;

class procedure Assert.WillRaise(const Proc: TProc; const ExceptionClass: ExceptClass; const Message: String);
begin
  ExecuteAssertion(
    procedure
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
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Variant; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.{$IFDEF PAS2JS}FromJSValue{$ELSE}FromVariant{$ENDIF}(Expected), TValue.{$IFDEF PAS2JS}FromJSValue{$ELSE}FromVariant{$ENDIF}(CurrentValue), Message);
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: TClass; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
end;

class procedure Assert.AreEqual(const Expected, CurrentValue: Pointer; const Message: String);
begin
  ExecuteAssertion(
    procedure
    begin
      if Expected <> CurrentValue then
        RaiseAssert(TValue.From(Expected), TValue.From(CurrentValue), Message);
    end);
end;

{ TTestClassMethod }

constructor TTestClassMethod.Create(const TestMethod: TRttiMethod; const TestClass: TTestClass);
begin
  inherited Create;

  FTestClass := TestClass;
  FTestMethod := TestMethod;
end;

procedure TTestClassMethod.ExecuteTest;
begin
  Assert.AssertionCalled := False;

  FTestClass.CallMethod(FTestMethod, FTestClass.FinishMethodTestExecutionPassed);
end;

procedure TTestClassMethod.Setup;
begin
  FTestClass.StartMethodTestExecution(Self);

  FTestClass.CallMethod(FTestClass.FTestSetup);
end;

procedure TTestClassMethod.TearDown;
begin
  FTestClass.CallMethod(FTestClass, FTestClass.FTestTearDownTestClass);
end;

{ TTestClass }

function TTestClass.AddTestMethod(const Method: TRttiMethod; const CanExecuteTest: Boolean): TTestClassMethod;
var
  TestMethod: TTestClassMethod;

begin
  TestMethod := TTestClassMethod.Create(Method, Self);

  Result := TestMethod;

  FTestMethods.Add(TestMethod);

  if CanExecuteTest then
  begin
    if FQueueMethods.IsEmpty then
      FQueueMethods.Enqueue(TObjectProcedure.Create(ExecuteSetupFixture));

    FQueueMethods.Enqueue(TObjectProcedure.Create(TestMethod.Setup));

    FQueueMethods.Enqueue(TObjectProcedure.Create(TestMethod.ExecuteTest));

    FQueueMethods.Enqueue(TObjectProcedure.Create(TestMethod.TearDown));
  end;
end;

procedure TTestClass.CallMethod(const Method: TRttiMethod; const SuccessProcedure: TProc);
begin
  CallMethod(Instance, Method, SuccessProcedure);
end;

procedure TTestClass.CallMethod(const Instance: TObject; const Method: TRttiMethod; const SuccessProcedure: TProc);

  procedure CheckDelayExecution;
  var
    Attribute: TDelayedProcedureAttribute;

  begin
    if Assigned(Method) then
    begin
      Attribute := Method.GetAttribute<TDelayedProcedureAttribute>;

      if Assigned(Attribute) and (Attribute.Delay > 0) then
        CreateAsyncTimer(ContinueTesting, {$IFDEF PAS2JS}@{$ENDIF}OnTimerDelayProcedure, Attribute.Delay);
    end;
  end;

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
              ContinueTesting;
            end)
          .Catch(
            procedure (Exception: TObject)
            begin
              FTester.ShowException(Exception);
            end);

        StopExecution;
      end
      else
{$ENDIF}
      Method.Invoke(Instance, []);

    ExecuteSuccess;
  except
    CheckException(AcquireExceptionObject);
  end;

  CheckDelayExecution;
end;

procedure TTestClass.CheckException(ExceptionObject: TObject);
var
  AssertAsync: EAsyncAssert absolute ExceptionObject;
  Error: Exception absolute ExceptionObject;
  TestFail: EAssertFail absolute ExceptionObject;
{$IFDEF PAS2JS}
  JSErro: TJSError absolute ExceptionObject;
  JSMessage: String absolute ExceptionObject;
{$ENDIF}

begin
  try
    if ExceptionObject is EAsyncAssert then
      CreateAsyncTimer(AssertAsync.AssertAsyncProcedure, {$IFDEF PAS2JS}@{$ENDIF}OnTimerAssertAsync, AssertAsync.TimeOut)
    else if ExceptionObject is EStopExecution then
      StopExecution
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

procedure TTestClass.ClassRegisterMethodsFinished;
begin
  if not FQueueMethods.IsEmpty then
    FQueueMethods.Enqueue(TObjectProcedure.Create(ExecuteTearDownFixture));

  FQueueMethods.Enqueue(TObjectProcedure.Create(FinishClassTestExecution));
end;

procedure TTestClass.ContinueTesting;
begin
  FTester.DoExecuteTests;
end;

constructor TTestClass.Create(const Tester: TTestInsightFramework; const InstanceType: TRttiInstanceType);
var
  RttiType: TRttiType;

begin
  inherited Create;

  FInstanceType := InstanceType;
  FQueueMethods := TQueue<TObjectProcedure>.Create;
  FTester := Tester;
  FTestMethods := TObjectList<TTestClassMethod>.Create;
  RttiType := FTester.Context.GetType(ClassType);

  FExecuteAsyncProcedureMethod := RttiType.GetMethod('ExecutAsyncProcedure');
  FTestTearDownTestClass := RttiType.GetMethod('ExecuteTearDown');

  LoadSetupAndTearDownMethods;
end;

procedure TTestClass.CreateAsyncTimer(const AsyncProcedure: TProc; const TimerEvent: TNotifyEvent; const Interval: Integer);
begin
  FAsyncProcedure := AsyncProcedure;

  CreateTimer(Interval, TimerEvent);

  StopExecution;
end;

class function TTestClass.CreateTimer(const Interval: Integer; const OnTimer: TNotifyEvent): TTimer;
begin
  Result := TTimer.Create(nil);
  Result.Enabled := False;
  Result.Interval := Interval;
  Result.OnTimer := OnTimer;

  Result.Enabled := True;
end;

destructor TTestClass.Destroy;
begin
  FInstance.Free;

  FQueueMethods.Free;

  FTestMethods.Free;

  inherited;
end;

procedure TTestClass.ExecutAsyncProcedure;
begin
  FAsyncProcedure();
end;

procedure TTestClass.Execute;
var
  Proc: TObjectProcedure;

begin
  while not FQueueMethods.IsEmpty do
  begin
    Proc := FQueueMethods.Dequeue;

    try
      Proc.Execute;
    finally
      Proc.Free;
    end;
  end;
end;

procedure TTestClass.ExecuteSetupFixture;
begin
  FInstance := FTester.FObjectResolver(InstanceType);

  CallMethod(FTestSetupFixture);
end;

procedure TTestClass.ExecuteTearDown;
begin
  {$IFDEF PAS2JS}
  await(WaitForPromises);
  {$ENDIF}

  CallMethod(FTestTearDown);
end;

procedure TTestClass.ExecuteTearDownFixture;
begin
  CallMethod(FTestTearDownFixture);
end;

procedure TTestClass.ExecuteTestMethod(const Instance: TObject; const TestMethod: TRttiMethod);
begin
  CallMethod(Instance, TestMethod, FinishMethodTestExecutionPassed);
end;

procedure TTestClass.FinishClassTestExecution;
begin
  FTester.FinishTestClassExecution;
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

class procedure TTestClass.FreeTimer(const Sender: TObject);
var
  Timer: TTimer absolute Sender;

begin
  Timer.Enabled := False;

  Timer.Free;
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
begin
  FreeTimer(Sender);

  try
    ExecuteTestMethod(Self, FExecuteAsyncProcedureMethod);

    ContinueTesting;
  except
    FTester.ShowException(AcquireExceptionObject);
  end;
end;

procedure TTestClass.OnTimerDelayProcedure(Sender: TObject);
begin
  FreeTimer(Sender);

  try
    ExecutAsyncProcedure;
  except
    FTester.ShowException(AcquireExceptionObject);
  end;
end;

procedure TTestClass.StartMethodTestExecution(const TestMethod: TTestClassMethod);
begin
  FTester.StartTestMethodExecution(TestMethod);
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

{ TDelayedProcedureAttribute }

constructor TDelayedProcedureAttribute.Create(const Delay: Integer);
begin
  inherited Create;

  FDelay := Delay;
end;

{ SetupDelayAttribute }

constructor SetupDelayAttribute.Create;
begin
  Create(10);
end;

constructor SetupDelayAttribute.Create(const Delay: Integer);
begin
  inherited Create(Delay);
end;

{ SetupFixtureDelayAttribute }

constructor SetupFixtureDelayAttribute.Create;
begin
  Create(10);
end;

constructor SetupFixtureDelayAttribute.Create(const Delay: Integer);
begin
  inherited Create(Delay);
end;

{ TearDownDelayAttribute }

constructor TearDownDelayAttribute.Create;
begin
  Create(10);
end;

constructor TearDownDelayAttribute.Create(const Delay: Integer);
begin
  inherited Create(Delay);
end;

{ TearDownFixtureDelayAttribute }

constructor TearDownFixtureDelayAttribute.Create;
begin
  Create(10);
end;

constructor TearDownFixtureDelayAttribute.Create(const Delay: Integer);
begin
  inherited Create(Delay);
end;

{ TObjectProcedure }

constructor TObjectProcedure.Create(Proc: TProc);
begin
  inherited Create;

  FProc := Proc;
end;

procedure TObjectProcedure.Execute;
begin
  FProc();
end;

{ EStopExecution }

constructor EStopExecution.Create;
begin
  inherited Create('Stop the execution.');
end;

{$IFDEF PAS2JS}
initialization
asm
  class TestInsightPromise extends Promise {
    static PromiseList = [];
    static Promise = Promise;

    constructor (resolver) {
      let MyResolve = null;
      let MyReject = null;

      super((resolve, reject) =>
        {
          MyResolve = resolve;
          MyReject = reject;
        });

      resolver(
        (value) =>
          {
            this.removeFromList();

            MyResolve(value);
          },
        (value) =>
          {
            this.removeFromList();

            MyReject(value);
          }
        );

      if (!TestInsightPromise.PromiseList)
        TestInsightPromise.PromiseList = [];

      TestInsightPromise.PromiseList.push(this);
    }

    removeFromList()
    {
      TestInsightPromise.PromiseList = TestInsightPromise.PromiseList.slice(TestInsightPromise.PromiseList.indexOf(this), 1);
    }

    static hasPromises()
    {
      return TestInsightPromise.PromiseList && TestInsightPromise.PromiseList.length > 0;
    }

    static async waitForAll()
    {
      while (this.hasPromises())
        await TestInsightPromise.Promise.allSettled(TestInsightPromise.PromiseList);
    }

    static continuePromise()
    {
      return TestInsightPromise.Promise.withResolvers();
    }
  };

  Promise = TestInsightPromise;
end;
{$ENDIF}

end.

