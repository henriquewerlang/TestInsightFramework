unit Test.Insight.Framework;

interface

uses System.SysUtils, System.Rtti, System.Generics.Collections, System.Classes, TestInsight.Client, {$IFDEF DCC}Vcl.ExtCtrls{$ELSE}System.Timer, JSApi.JS{$ENDIF};

type
{$IFDEF PAS2JS}
  Variant = JSValue;
{$ELSE}
  TJSPromise = TObject;
{$ENDIF}

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
    FInterval: NativeInt;
  public
    constructor Create(const AssertAsyncProcedure: TProc; const Interval: NativeInt);

    property AssertAsyncProcedure: TProc read FAssertAsyncProcedure;
    property Interval: NativeInt read FInterval write FInterval;
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
    FCurrentTest: TTestClassMethod;
    FExecuteAsyncProcedureMethod: TRttiMethod;
    FInstance: TObject;
    FInstanceType: TRttiInstanceType;
    FQueueMethods: TQueue<TObjectProcedure>;
    FTester: TTestInsightFramework;
    FTestMethods: TList<TTestClassMethod>;
    FTestSetup: TRttiMethod;
    FTestSetupFixture: TRttiMethod;
    FTestTearDown: TRttiMethod;
    FTestTearDownFixture: TRttiMethod;
    FTimer: TTimer;
    FTimerEvent: TProc;

    function GetTimer: TTimer;

    procedure CallMethod(const Instance: TObject; const Method: TRttiMethod); overload;
    procedure CallMethod(const Method: TRttiMethod); overload;
    procedure CheckException(const ExceptionObject: TObject);
    procedure CheckForPromises;
    procedure ClassRegisterMethodsFinished;
    procedure ContinueTesting;
    procedure ExecutePromise(const Promise: TJSPromise);
    procedure ExecuteSetupFixture;
    procedure ExecuteTimer(const Proc: TProc; const Interval: NativeInt);
    procedure ExecuteTearDownFixture;
    procedure FinishClassTestExecution;
    procedure FinishMethodTestExecutionError(const Message: String);
    procedure FinishMethodTestExecutionFail(const Message: String);
    procedure FinishMethodTestExecutionPassed;
    procedure LoadSetupAndTearDownMethods;
    procedure OnTimer(Sender: TObject);
    procedure StartMethodTestExecution(const TestMethod: TTestClassMethod);

    property Instance: TObject read FInstance;
    property Timer: TTimer read GetTimer;
  public
    constructor Create(const Tester: TTestInsightFramework; const InstanceType: TRttiInstanceType);

    destructor Destroy; override;

    function AddTestMethod(const Method: TRttiMethod; const CanExecuteTest: Boolean): TTestClassMethod;

    procedure Execute;

    property InstanceType: TRttiInstanceType read FInstanceType;
  published
    procedure ExecuteAsyncProcedure;
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
  private class var
    FAsyncDefaultIntervalValue: NativeInt;
    FWaitForPromisesTimeOut: NativeInt;
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

    class property AsyncDefaultIntervalValue: NativeInt read FAsyncDefaultIntervalValue write FAsyncDefaultIntervalValue;
    class property WaitForPromisesTimeOut: NativeInt read FWaitForPromisesTimeOut write FWaitForPromisesTimeOut;

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
    class procedure Async(const Proc: TProc); overload;
    class procedure Async(const Proc: TProc; const Interval: NativeInt); overload;
    class procedure Async(const Proc: TProc; const Message: String; const Interval: NativeInt); overload;
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

function IgnorePromise(const Promise: TJSPromise): TJSPromise;
function WaitForPromises: TJSPromise; overload;
function WaitForPromises(const Timeout: NativeInt): TJSPromise; overload;

implementation

uses System.DateUtils, {$IFDEF DCC}Vcl.Forms{$ENDIF}{$IFDEF PAS2JS}BrowserApi.Web{$ENDIF};

{$IFDEF PAS2JS}
var
  AcquireExceptionObject: TObject; external name '$e';
  GPromises: TList<TJSPromise> = nil;
  GRealPromise: class of TJSPromise;
  GKeepChecking: NativeInt;

procedure RemovePromise(const Promise: TJSPromise);
begin
  GPromises.Remove(Promise);
end;

function HasPromises: Boolean;
begin
  Result := not GPromises.IsEmpty;
end;

procedure TryToResolve(Resolver: TProc);
begin
  Window.SetTimeout(
    procedure
    begin
      if (GKeepChecking > 0) and not GPromises.IsEmpty then
        TryToResolve(Resolver)
      else
      begin
        Window.ClearTimeout(GKeepChecking);

        Resolver;
      end;
    end, 1);
end;

{$ENDIF}

function IgnorePromise(const Promise: TJSPromise): TJSPromise;
begin
  Result := Promise;
{$IFDEF PAS2JS}

  RemovePromise(Promise);
{$ENDIF}
end;

function WaitForPromises: TJSPromise;
begin
  Result := WaitForPromises(TTestInsightFramework.WaitForPromisesTimeOut);
end;

function WaitForPromises(const Timeout: NativeInt): TJSPromise;
begin
{$IFDEF PAS2JS}
  Result := GRealPromise.New(
    procedure (Resolve: TProc)
    begin
      GKeepChecking := Window.SetTimeout(
        procedure
        begin
          GKeepChecking := 0;
        end, Timeout);

      TryToResolve(Resolve);
    end);
{$ELSE}
  Result := nil;
{$ENDIF}
end;

procedure StopExecution;
begin
  raise EStopExecution.Create;
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
  FTestResult.MethodName := TestMethod.TestMethod.Name;
  FTestResult.Path := TestMethod.FTestClass.InstanceType.QualifiedName;
  FTestResult.ResultType := TResultType.Skipped;
  FTestResult.Status := EmptyStr;
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
  begin
    FTestResult.ExceptionMessage := 'No assertion was made during the test';
    FTestResult.ResultType := TResultType.Warning;
  end;

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

class procedure Assert.Async(const Proc: TProc; const Message: String; const Interval: NativeInt);
begin
  if not Assigned(Proc) then
    raise EAsyncAssertEmptyProcedure.Create;

  raise EAsyncAssert.Create(Proc, Interval);
end;

class procedure Assert.Async(const Proc: TProc; const Interval: NativeInt);
begin
  Async(Proc, EmptyStr, Interval);
end;

class procedure Assert.Async(const Proc: TProc);
begin
  Async(Proc, EmptyStr, TTestInsightFramework.AsyncDefaultIntervalValue);
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
  FTestClass.FCurrentTest := Self;

  FTestClass.CallMethod(FTestMethod);
end;

procedure TTestClassMethod.Setup;
begin
  FTestClass.StartMethodTestExecution(Self);

  FTestClass.CallMethod(FTestClass.FTestSetup);

  FTestClass.CheckForPromises;
end;

procedure TTestClassMethod.TearDown;
begin
  FTestClass.FCurrentTest := nil;

  FTestClass.CallMethod(FTestClass.FTestTearDown);

  FTestClass.CheckForPromises;
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

procedure TTestClass.CallMethod(const Method: TRttiMethod);
begin
  CallMethod(Instance, Method);
end;

procedure TTestClass.CallMethod(const Instance: TObject; const Method: TRttiMethod);

  procedure FinishExecution;
  begin
    if Assigned(FCurrentTest) then
      FinishMethodTestExecutionPassed;
  end;

{$IFDEF PAS2JS}
  procedure RegisterExecution(const Promise: TJSPromise);
  begin
    ExecutePromise(Promise
      .&Then(
        procedure
        begin
          FinishExecution;
        end));
  end;
{$ENDIF}

begin
  try
    if Assigned(Method) then
{$IFDEF PAS2JS}
      if Method.IsAsyncCall then
        RegisterExecution(Method.Invoke(Instance, []).AsType<TJSPromise>)
      else
{$ENDIF}
      Method.Invoke(Instance, []);

    FinishExecution;
  except
    CheckException(AcquireExceptionObject);
  end;
end;

procedure TTestClass.CheckException(const ExceptionObject: TObject);
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
    begin
      FAsyncProcedure := AssertAsync.AssertAsyncProcedure;

{$IFDEF PAS2JS}
      ExecutePromise(WaitForPromises(AssertAsync.Interval)
        .&Then(
          procedure
          begin
            CallMethod(Self, FExecuteAsyncProcedureMethod);
          end));

{$ENDIF}
      StopExecution;
    end
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

procedure TTestClass.CheckForPromises;
begin
{$IFDEF PAS2JS}
  ExecutePromise(WaitForPromises
    .&Then(
      procedure
      begin
        GPromises.Clear;
      end));
{$ENDIF}
end;

procedure TTestClass.ClassRegisterMethodsFinished;
begin
  if not FQueueMethods.IsEmpty then
    FQueueMethods.Enqueue(TObjectProcedure.Create(ExecuteTearDownFixture));

  FQueueMethods.Enqueue(TObjectProcedure.Create(FinishClassTestExecution));
end;

procedure TTestClass.ContinueTesting;
begin
  ExecuteTimer(FTester.DoExecuteTests, 1);
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

  FExecuteAsyncProcedureMethod := RttiType.GetMethod('ExecuteAsyncProcedure');

  LoadSetupAndTearDownMethods;
end;

destructor TTestClass.Destroy;
begin
  FTimer.Free;

  FInstance.Free;

  FQueueMethods.Free;

  FTestMethods.Free;

  inherited;
end;

procedure TTestClass.ExecuteAsyncProcedure;
begin
  FAsyncProcedure();
end;

procedure TTestClass.ExecutePromise(const Promise: TJSPromise);
begin
{$IFDEF PAS2JS}
  Promise
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
{$ENDIF}
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

procedure TTestClass.ExecuteTearDownFixture;
begin
  CallMethod(FTestTearDownFixture);
end;

procedure TTestClass.ExecuteTimer(const Proc: TProc; const Interval: NativeInt);
begin
{$IFDEF PAS2JS}
  Window.SetTimeOut(Proc, Interval);
{$ELSE}
  FTimerEvent := Proc;
  Timer.Interval := Interval;

  Timer.Enabled := True;
{$ENDIF}
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

function TTestClass.GetTimer: TTimer;
begin
  if not Assigned(FTimer) then
  begin
    FTimer := TTimer.Create(nil);
    FTimer.Enabled := False;
    FTimer.OnTimer := OnTimer;
  end;

  Result := FTimer;
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

procedure TTestClass.OnTimer(Sender: TObject);
begin
  FTimer.Enabled := False;

  FTimerEvent();
end;

procedure TTestClass.StartMethodTestExecution(const TestMethod: TTestClassMethod);
begin
  FTester.StartTestMethodExecution(TestMethod);
end;

{ EAsyncAssert }

constructor EAsyncAssert.Create(const AssertAsyncProcedure: TProc; const Interval: NativeInt);
begin
  inherited Create('Async Assert');

  FAssertAsyncProcedure := AssertAsyncProcedure;
  FInterval := Interval;
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

initialization
  GPromises := TList<TJSPromise>.Create;
  GRealPromise := TJSPromise;
{$IFDEF PAS2JS}
asm
  class TestInsightPromise extends Promise {
    constructor (executor) {
      let MyResolve = null;
      let MyReject = null;

      super((resolve, reject) =>
        {
          MyResolve = resolve;
          MyReject = reject;
        });

      let Impl = pas["Test.Insight.Framework"].$impl;

      Impl.GPromises.Add(this);

      executor(
        (value) =>
          {
            Impl.RemovePromise(this);

            MyResolve(value);
          },
        (value) =>
          {
            Impl.RemovePromise(this);

            MyReject(value);
          }
        );
    }
  };

  Promise = TestInsightPromise;
end;
{$ENDIF}

end.

