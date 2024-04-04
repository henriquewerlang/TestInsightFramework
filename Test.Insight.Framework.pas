unit Test.Insight.Framework;

interface

uses System.SysUtils, System.Rtti, System.Generics.Collections, TestInsight.Client, {$IFDEF DCC}Vcl.ExtCtrls{$ENDIF}{$IFDEF PAS2JS}JSApi.JS{$ENDIF};

type
  SetupAttribute = class(TCustomAttribute);
  SetupFixtureAttribute = class(TCustomAttribute);
  TearDownAttribute = class(TCustomAttribute);
  TearDownFixtureAttribute = class(TCustomAttribute);
  TestAttribute = class(TCustomAttribute);
  TestFixtureAttribute = class(TCustomAttribute);
  TObjectResolver = TFunc<TRttiInstanceType, TObject>;
  TTestClassMethod = class;
  TTimerType = {$IFDEF PAS2JS}TJSPromise{$ELSE}TTimer{$ENDIF};

  EAssertAsync = class(Exception)
  private
    FAsyncProc: TProc;
    FTimeOut: Integer;
  public
    constructor Create(const AsyncProc: TProc; const TimeOut: Integer);

    property AsyncProc: TProc read FAsyncProc write FAsyncProc;
    property TimeOut: Integer read FTimeOut write FTimeOut;
  end;

  EAssertAsyncEmptyProcedure = class(Exception)
  public
    constructor Create;
  end;

  EAssertFail = class(Exception)
  public
    constructor Create(const AssertionMessage, Message: String); reintroduce;
  end;

  TTestClass = class
  private
    FInstance: TObject;
    FInstanceType: TRttiInstanceType;
    FMethods: TList<TTestClassMethod>;
    FObjectResolver: TObjectResolver;
    FTestSetupFixture: TRttiMethod;
    FTestTearDownFixture: TRttiMethod;

    function GetInstance: TObject;
    function GetLastTest: TTestClassMethod;

    procedure CallMethod(const Method: TRttiMethod);
    procedure LoadSetupAndTearDownMethods;
  public
    constructor Create(const InstanceType: TRttiInstanceType; const ObjectResolver: TObjectResolver);

    destructor Destroy; override;

    function AddTestMethod(const Method: TRttiMethod; const CanExecuteTest: Boolean): TTestClassMethod;

    property Instance: TObject read GetInstance;
    property InstanceType: TRttiInstanceType read FInstanceType;
    property LastTest: TTestClassMethod read GetLastTest;
  end;

  TTestClassMethod = class
  private
    FCanExecuteTest: Boolean;
    FStartedTime: TDateTime;
    FTestClass: TTestClass;
    FTestMethod: TRttiMethod;
    FTestResult: TTestInsightResult;
    FTestSetup: TRttiMethod;
    FTestTearDown: TRttiMethod;

    function GetInstance: TObject;
    function GetInstanceType: TRttiInstanceType;

    procedure CallMethod(const Method: TProc; const PassTest: Boolean = False); overload;
    procedure CallMethod(const Method: TRttiMethod); overload;
    procedure DoExecute(const Method: TProc);
    procedure LoadSetupAndTearDownMethods;
  public
    constructor Create(const TestMethod: TRttiMethod; const TestClass: TTestClass);

    function CanExecute: Boolean;

    procedure Execute;

    property Instance: TObject read GetInstance;
    property InstanceType: TRttiInstanceType read GetInstanceType;
    property StartedTime: TDateTime read FStartedTime write FStartedTime;
    property TestMethod: TRttiMethod read FTestMethod;
    property TestResult: TTestInsightResult read FTestResult;
  end;

  TTestInsightFramework = class
  private
    FAsyncAssert: TProc;
    FAsyncTimer: TTimerType;
    FContext: TRttiContext;
    FCurrentClassTesting: TEnumerator<TTestClass>;
    FCurrentClassMethodTesting: TEnumerator<TTestClassMethod>;
    FObjectResolver: TObjectResolver;
    FTestInsightClient: ITestInsightClient;
    FTestClassesDiscovered: TList<TTestClass>;

    function CreateObject(&Type: TRttiInstanceType): TObject;
    function GetCurrentClassMethod: TTestClassMethod;

    procedure DoExecuteTests;
    procedure OnTimer(Sender: TObject);
    procedure PostTestClassInformation;
    procedure Resume;
    procedure StartAsyncTimer(const AsyncInfo: EAssertAsync);

    property AsyncAssert: TProc read FAsyncAssert write FAsyncAssert;
    property CurrentClassMethod: TTestClassMethod read GetCurrentClassMethod;
  public
    constructor Create(const TestInsightClient: ITestInsightClient; const ObjectResolver: TObjectResolver);

    destructor Destroy; override;

    procedure Run;
    procedure WaitForAsyncExecution;{$IFDEF PAS2JS} async;{$ENDIF}

    class procedure ExecuteTests; overload;{$IFDEF PAS2JS} async;{$ENDIF}
    class procedure ExecuteTests(const ObjectResolver: TObjectResolver); overload;{$IFDEF PAS2JS} async;{$ENDIF}
  end;

  Assert = class
  public
    class procedure AreEqual(const Expected, CurrentValue: String; const Message: String = ''); overload; // compiler problem...
    class procedure AreEqual<T>(const Expected, CurrentValue: T; const Message: String = ''); overload;
    class procedure Async(const Proc: TProc; const TimeOut: Integer = 50; const Message: String = '');
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
  GlobalResolvePromise: TProc;
{$ENDIF}

{ TTestInsightFramework }

constructor TTestInsightFramework.Create(const TestInsightClient: ITestInsightClient; const ObjectResolver: TObjectResolver);
begin
  inherited Create;

  FObjectResolver := ObjectResolver;
  FTestClassesDiscovered := TObjectList<TTestClass>.Create;
  FTestInsightClient := TestInsightClient;

  if not Assigned(FObjectResolver) then
    FObjectResolver := CreateObject;
end;

function TTestInsightFramework.CreateObject(&Type: TRttiInstanceType): TObject;
begin
  Result := &Type.MetaclassType.Create;
end;

destructor TTestInsightFramework.Destroy;
begin
  FTestClassesDiscovered.Free;

  FCurrentClassTesting.Free;

  FCurrentClassMethodTesting.Free;

  FContext.Free;

  inherited;
end;

procedure TTestInsightFramework.DoExecuteTests;

  function MoveNextTest: Boolean;
  begin
    Result := Assigned(FCurrentClassMethodTesting) and FCurrentClassMethodTesting.MoveNext;

    if not Result and FCurrentClassTesting.MoveNext then
    begin
      FreeAndNil(FCurrentClassMethodTesting);

      FCurrentClassMethodTesting := FCurrentClassTesting.Current.FMethods.GetEnumerator;

      Result := MoveNextTest;
    end;
  end;

begin
  while MoveNextTest do
  begin
    PostTestClassInformation;

    if CurrentClassMethod.CanExecute then
    begin
      PostTestClassInformation;

      try
        CurrentClassMethod.Execute;
      except
        on AsyncException: EAssertAsync do
        begin
          StartAsyncTimer(AsyncException);

          Exit;
        end
        else
          raise;
      end;

      PostTestClassInformation;
    end;
  end;

  FTestInsightClient.FinishedTesting;

{$IFDEF PAS2JS}
  GlobalResolvePromise();
{$ENDIF}
end;

class procedure TTestInsightFramework.ExecuteTests(const ObjectResolver: TObjectResolver);
var
{$IFDEF PAS2JS}
  Promise: TJSPromise;
{$ENDIF}
  Test: TTestInsightFramework;

begin
{$IFDEF PAS2JS}
  Promise := TJSPromise.New(
    procedure (Resolver: TProc)
    begin
      GlobalResolvePromise := Resolver;
    end);
{$ENDIF}

  Test := TTestInsightFramework.Create(TTestInsightRestClient.Create, ObjectResolver);

  Test.Run;

  {$IFDEF PAS2JS}await{$ENDIF}(Test.WaitForAsyncExecution);

{$IFDEF PAS2JS}
  await(TJSPromise.all([Promise]));
{$ENDIF}

  Test.Free;
end;

function TTestInsightFramework.GetCurrentClassMethod: TTestClassMethod;
begin
  Result := FCurrentClassMethodTesting.Current;
end;

procedure TTestInsightFramework.OnTimer(Sender: TObject);
begin
  if Assigned(AsyncAssert) then
  begin
{$IFDEF DCC}
    FAsyncTimer.OnTimer := nil;

    FAsyncTimer.Free;
{$ENDIF}

    Resume;
  end;
end;

procedure TTestInsightFramework.PostTestClassInformation;
begin
  FTestInsightClient.PostResult(CurrentClassMethod.TestResult, True);
end;

class procedure TTestInsightFramework.ExecuteTests;
begin
  {$IFDEF PAS2JS}await{$ENDIF}(ExecuteTests(nil));
end;

procedure TTestInsightFramework.Resume;
begin
  CurrentClassMethod.DoExecute(AsyncAssert);

  AsyncAssert := nil;

  PostTestClassInformation;

  DoExecuteTests;
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
    FContext := TRttiContext.Create;
    ExecuteTests := FTestInsightClient.Options.ExecuteTests;
    SelectedTests := FTestInsightClient.GetTests;

    for RttiType in FContext.GetTypes do
      if RttiType.IsInstance and RttiType.HasAttribute<TestFixtureAttribute> then
      begin
        TestClass := TTestClass.Create(RttiType.AsInstance, FObjectResolver);

        FTestClassesDiscovered.Add(TestClass);

        for TestMethod in RttiType.GetMethods do
          if TestMethod.HasAttribute<TestAttribute> then
            TestClass.AddTestMethod(TestMethod, CanExecuteTest(TestMethod.Name));
      end;
  end;

  function GetTestCount: Integer;
  var
    TestClass: TTestClass;

    TestClassMethod: TTestClassMethod;

  begin
    Result := 0;

    for TestClass in FTestClassesDiscovered do
      for TestClassMethod in TestClass.FMethods do
        Inc(Result);
  end;

begin
  DiscoveryAllTests;

  FTestInsightClient.StartedTesting(GetTestCount);

  FCurrentClassTesting := FTestClassesDiscovered.GetEnumerator;

  DoExecuteTests;
end;

procedure TTestInsightFramework.StartAsyncTimer(const AsyncInfo: EAssertAsync);
begin
  FAsyncAssert := AsyncInfo.AsyncProc;
{$IFDEF DCC}
  FAsyncTimer := TTimer.Create(nil);
  FAsyncTimer.Interval := AsyncInfo.TimeOut;
  FAsyncTimer.OnTimer := OnTimer;
{$ELSE}
  FAsyncTimer := TJSPromise.New(
    procedure (Resolver: TProc)
    begin
      Window.SetTimeOut(
        procedure
        begin
          OnTimer(nil);

          Resolver;
        end, AsyncInfo.TimeOut);
    end);
{$ENDIF}
end;

procedure TTestInsightFramework.WaitForAsyncExecution;
begin
  if Assigned(FAsyncTimer) then
{$IFDEF PAS2JS}
    await(TJSPromise.all([FAsyncTimer]));
{$ELSE}
  begin
    Sleep(FAsyncTimer.Interval + 50);

    Application.ProcessMessages;
  end;
{$ENDIF}
end;

{ Assert }

class procedure Assert.AreEqual(const Expected, CurrentValue, Message: String);
begin
  if Expected <> CurrentValue then
    raise EAssertFail.Create(Format('The value expected is %s and the current value is %s', [Expected, CurrentValue]), Message);
end;

class procedure Assert.AreEqual<T>(const Expected, CurrentValue: T; const Message: String);
begin
  if Expected <> CurrentValue then
    raise EAssertFail.Create(Format('The value expected is %s and the current value is %s', [TValue.From<T>(Expected).ToString, TValue.From<T>(CurrentValue).ToString]), Message);
end;

class procedure Assert.Async(const Proc: TProc; const TimeOut: Integer; const Message: String);
begin
  if not Assigned(Proc) then
    raise EAssertAsyncEmptyProcedure.Create;

  raise EAssertAsync.Create(Proc, TimeOut);
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
  if not Value.IsEmpty then
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
  if Value.IsEmpty then
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
  end;

  raise EAssertFail.Create('No exceptions raised!', Message);
end;

{ TTestClassMethod }

procedure TTestClassMethod.CallMethod(const Method: TProc; const PassTest: Boolean);

  procedure PostResultWithMessage(const ResultType: TResultType; const Message: String);
  begin
    FTestResult.ExceptionMessage := Message;
    FTestResult.ResultType := ResultType;
  end;

begin
  try
    Method();

    if PassTest then
    begin
      FTestResult.Duration := MilliSecondsBetween(Now, StartedTime);
      FTestResult.ResultType := TResultType.Passed;
    end;
  except
    on AsyncAssert: EAssertAsync do
      raise;

    on TestFail: EAssertFail do
      PostResultWithMessage(TResultType.Failed, TestFail.Message);

    on Error: Exception do
      PostResultWithMessage(TResultType.Error, Error.Message);
{$IFDEF PAS2JS}

    on JSErro: TJSError do
      PostResultWithMessage(TResultType.Error, JSErro.Message);
{$ENDIF}
  end;
end;

procedure TTestClassMethod.CallMethod(const Method: TRttiMethod);
begin
  CallMethod(
    procedure
    begin
      FTestClass.CallMethod(Method);
    end);
end;

function TTestClassMethod.CanExecute: Boolean;
begin
  FTestResult.ResultType := TResultType.Running;
  Result := FCanExecuteTest;
end;

constructor TTestClassMethod.Create(const TestMethod: TRttiMethod; const TestClass: TTestClass);
begin
  inherited Create;

  FTestClass := TestClass;
  FTestMethod := TestMethod;
  FTestResult := TTestInsightResult.Create(TResultType.Skipped, TestMethod.Name, InstanceType.DeclaringUnitName);
  FTestResult.ClassName := InstanceType.Name;
  FTestResult.Duration := 0;
  FTestResult.ExceptionMessage := EmptyStr;
  FTestResult.MethodName := TestMethod.Name;
  FTestResult.Path := InstanceType.QualifiedName;
  FTestResult.UnitName := InstanceType.DeclaringUnitName;

  LoadSetupAndTearDownMethods;
end;

procedure TTestClassMethod.DoExecute(const Method: TProc);
begin
  CallMethod(Method, True);

  CallMethod(FTestTearDown);

  if FTestClass.LastTest = Self then
    CallMethod(FTestClass.FTestTearDownFixture);
end;

procedure TTestClassMethod.Execute;
begin
  StartedTime := Now;

  CallMethod(FTestSetup);

  DoExecute(
    procedure
    begin
      FTestClass.CallMethod(FTestMethod);
    end);
end;

function TTestClassMethod.GetInstance: TObject;
begin
  Result := FTestClass.Instance;
end;

function TTestClassMethod.GetInstanceType: TRttiInstanceType;
begin
  Result := FTestClass.InstanceType;
end;

procedure TTestClassMethod.LoadSetupAndTearDownMethods;
var
  Method: TRttiMethod;

begin
  for Method in InstanceType.GetMethods do
    if Method.HasAttribute<SetupAttribute> and not Assigned(FTestSetup) then
      FTestSetup := Method
    else if Method.HasAttribute<TearDownAttribute> and not Assigned(FTestTearDown) then
      FTestTearDown := Method;
end;

{ TTestClass }

function TTestClass.AddTestMethod(const Method: TRttiMethod; const CanExecuteTest: Boolean): TTestClassMethod;
begin
  Result := TTestClassMethod.Create(Method, Self);
  Result.FCanExecuteTest := CanExecuteTest;

  FMethods.Add(Result);
end;

procedure TTestClass.CallMethod(const Method: TRttiMethod);
begin
  if Assigned(Method) then
    Method.Invoke(Instance, []);
end;

constructor TTestClass.Create(const InstanceType: TRttiInstanceType; const ObjectResolver: TObjectResolver);
begin
  inherited Create;

  FInstanceType := InstanceType;
  FMethods := TObjectList<TTestClassMethod>.Create;
  FObjectResolver := ObjectResolver;

  LoadSetupAndTearDownMethods;
end;

destructor TTestClass.Destroy;
begin
  FInstance.Free;

  FMethods.Free;

  inherited;
end;

function TTestClass.GetInstance: TObject;
begin
  if not Assigned(FInstance) then
  begin
    FInstance := FObjectResolver(InstanceType);

    CallMethod(FTestSetupFixture);
  end;

  Result := FInstance;
end;

function TTestClass.GetLastTest: TTestClassMethod;
var
  Test: TTestClassMethod;

begin
  Result := nil;

  for Test in FMethods do
    if Test.FCanExecuteTest then
      Result := Test;
end;

procedure TTestClass.LoadSetupAndTearDownMethods;
var
  Method: TRttiMethod;

begin
  for Method in InstanceType.GetMethods do
    if Method.HasAttribute<SetupFixtureAttribute> and not Assigned(FTestSetupFixture) then
      FTestSetupFixture := Method
    else if Method.HasAttribute<TearDownFixtureAttribute> and not Assigned(FTestTearDownFixture) then
      FTestTearDownFixture := Method;
end;

{ EAssertAsync }

constructor EAssertAsync.Create(const AsyncProc: TProc; const TimeOut: Integer);
begin
  inherited Create(EmptyStr);

  FAsyncProc := AsyncProc;
  FTimeOut := TimeOut;
end;

{ EAssertAsyncEmptyProcedure }

constructor EAssertAsyncEmptyProcedure.Create;
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

