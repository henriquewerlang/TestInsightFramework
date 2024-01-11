unit Test.Insight.Framework;

interface

uses System.SysUtils, System.Rtti, System.Generics.Collections, TestInsight.Client;

type
  SetupAttribute = class(TCustomAttribute);
  SetupFixtureAttribute = class(TCustomAttribute);
  TearDownAttribute = class(TCustomAttribute);
  TearDownFixtureAttribute = class(TCustomAttribute);
  TestAttribute = class(TCustomAttribute);
  TestFixtureAttribute = class(TCustomAttribute);
  TObjectResolver = TFunc<TRttiInstanceType, TObject>;
  TTestClassMethod = class;

  TestCaseAttribute = class(TestAttribute)
  public
    constructor Create(const TestName, Param: String); overload;
    constructor Create(const TestName, Param1, Param2: String); overload;
    constructor Create(const TestName, Param1, Param2, Param3: String); overload;
    constructor Create(const TestName, Param1, Param2, Param3, Param4: String); overload;
    constructor Create(const TestName, Param1, Param2, Param3, Param4, Param5: String); overload;
  end;

  EAssertFail = class(Exception)
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
    FTestClass: TTestClass;
    FTestMethod: TRttiMethod;
    FTestResult: TTestInsightResult;
    FTestSetup: TRttiMethod;
    FTestTearDown: TRttiMethod;

    function CallMethod(const Method: TRttiMethod): Boolean;
    function GetInstance: TObject;
    function GetInstanceType: TRttiInstanceType;

    procedure LoadSetupAndTearDownMethods;
  public
    constructor Create(const TestMethod: TRttiMethod; const TestClass: TTestClass);

    function CanExecute: Boolean;

    procedure Execute;

    property Instance: TObject read GetInstance;
    property InstanceType: TRttiInstanceType read GetInstanceType;
    property TestMethod: TRttiMethod read FTestMethod;
    property TestResult: TTestInsightResult read FTestResult;
  end;

  TTestInsightFramework = class
  private
    FTestInsightClient: ITestInsightClient;
    FTestClassesDiscovered: TList<TTestClass>;
    FTestClassMethodsDiscovered: TList<TTestClassMethod>;

    function CreateObject(&Type: TRttiInstanceType): TObject;

    procedure DoExecuteTests;
  public
    constructor Create(const TestInsightClient: ITestInsightClient);

    destructor Destroy; override;

    procedure Run; overload;
    procedure Run(const ObjectResolver: TObjectResolver); overload;

    class procedure ExecuteTests; overload;
    class procedure ExecuteTests(const ObjectResolver: TObjectResolver); overload;
  end;

  Assert = class
  public
    class procedure AreEqual(const Expected, CurrentValue: String); overload; // compiler problem...
    class procedure AreEqual<T>(const Expected, CurrentValue: T); overload;
    class procedure CheckExpectation(const Expectation: String);
    class procedure IsFalse(const Value: Boolean);
    class procedure IsNil(const Value: Pointer);
    class procedure IsNotNil(const Value: Pointer);
    class procedure IsTrue(const Value: Boolean);
    class procedure StartWith(const Expected, Value: String);
    class procedure WillNotRaise(const Proc: TProc);
    class procedure WillRaise(const Proc: TProc; const ExceptionClass: ExceptClass);
  end;

implementation

uses System.DateUtils{$IFDEF PAS2JS}, JS{$ENDIF};

{ TTestInsightFramework }

constructor TTestInsightFramework.Create(const TestInsightClient: ITestInsightClient);
begin
  inherited Create;

  FTestInsightClient := TestInsightClient;
  FTestClassesDiscovered := TObjectList<TTestClass>.Create;
  FTestClassMethodsDiscovered := TList<TTestClassMethod>.Create;
end;

function TTestInsightFramework.CreateObject(&Type: TRttiInstanceType): TObject;
begin
  Result := &Type.MetaclassType.Create;
end;

destructor TTestInsightFramework.Destroy;
begin
  FTestClassesDiscovered.Free;

  FTestClassMethodsDiscovered.Free;

  inherited;
end;

procedure TTestInsightFramework.DoExecuteTests;
var
  TestClassMethod: TTestClassMethod;

  procedure PostTestClassInformation;
  begin
    FTestInsightClient.PostResult(TestClassMethod.TestResult, True);
  end;

begin
  for TestClassMethod in FTestClassMethodsDiscovered do
  begin
    PostTestClassInformation;

    if TestClassMethod.CanExecute then
    begin
      PostTestClassInformation;

      TestClassMethod.Execute;

      PostTestClassInformation;
    end;
  end;

  FTestInsightClient.FinishedTesting;
end;

class procedure TTestInsightFramework.ExecuteTests(const ObjectResolver: TObjectResolver);
var
  TestFramework: TTestInsightFramework;

begin
  TestFramework := TTestInsightFramework.Create(TTestInsightRestClient.Create);

  TestFramework.Run(ObjectResolver);

  TestFramework.Free;
end;

procedure TTestInsightFramework.Run;
begin
  Run(nil);
end;

class procedure TTestInsightFramework.ExecuteTests;
begin
  ExecuteTests(nil);
end;

procedure TTestInsightFramework.Run(const ObjectResolver: TObjectResolver);
var
  ExecuteTests: Boolean;
  SelectedTests: TArray<String>;
  TestClass: TTestClass;
  TestClassMethod: TTestClassMethod;

  function GetObjectResolver: TObjectResolver;
  begin
    if Assigned(ObjectResolver) then
      Result := ObjectResolver
    else
      Result := CreateObject;
  end;

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
    Context: TRttiContext;
    RttiType: TRttiType;
    TestMethod: TRttiMethod;

  begin
    Context := TRttiContext.Create;
    ExecuteTests := FTestInsightClient.Options.ExecuteTests;
    SelectedTests := FTestInsightClient.GetTests;

    for RttiType in Context.GetTypes do
      if RttiType.IsInstance and RttiType.HasAttribute<TestFixtureAttribute> then
      begin
        TestClass := TTestClass.Create(RttiType.AsInstance, GetObjectResolver());

        FTestClassesDiscovered.Add(TestClass);

        for TestMethod in RttiType.GetMethods do
          if TestMethod.HasAttribute<TestAttribute> then
            FTestClassMethodsDiscovered.Add(TestClass.AddTestMethod(TestMethod, CanExecuteTest(TestMethod.Name)));
      end;

    Context.Free;
  end;

begin
  FTestInsightClient.ClearTests;

  FTestInsightClient.StartedTesting(FTestClassMethodsDiscovered.Count);

  DiscoveryAllTests;

  DoExecuteTests;
end;

{ Assert }

class procedure Assert.AreEqual(const Expected, CurrentValue: String);
begin
  if Expected <> CurrentValue then
    raise EAssertFail.CreateFmt('The value expected is %s and the current value is %s', [Expected, CurrentValue]);
end;

class procedure Assert.AreEqual<T>(const Expected, CurrentValue: T);
begin
  if Expected <> CurrentValue then
    raise EAssertFail.CreateFmt('The value expected is %s and the current value is %s', [TValue.From<T>(Expected).ToString, TValue.From<T>(CurrentValue).ToString]);
end;

class procedure Assert.CheckExpectation(const Expectation: String);
begin
  if not Expectation.IsEmpty then
    raise EAssertFail.CreateFmt('Expectation not achieved [%s]', [Expectation]);
end;

class procedure Assert.IsFalse(const Value: Boolean);
begin
  if Value then
    raise EAssertFail.Create('A FALSE value is expected!');
end;

class procedure Assert.IsNil(const Value: Pointer);
begin
  if Assigned(Value) then
    raise EAssertFail.Create('A nil pointer expected!');
end;

class procedure Assert.IsNotNil(const Value: Pointer);
begin
  if not Assigned(Value) then
    raise EAssertFail.Create('Not nil pointer expected!');
end;

class procedure Assert.IsTrue(const Value: Boolean);
begin
  if not Value then
    raise EAssertFail.Create('A TRUE value is expected!');
end;

class procedure Assert.StartWith(const Expected, Value: String);
begin
  if not Value.StartsWith(Expected) then
    raise EAssertFail.CreateFmt('Expected start with "%s" but started with "%s"', [Expected, Value]);
end;

class procedure Assert.WillNotRaise(const Proc: TProc);
begin
  try
    Proc();
  except
    on Error: Exception do
      raise EAssertFail.CreateFmt('Unexpected exception raised %s!', [Error.ClassName]);
  end;
end;

class procedure Assert.WillRaise(const Proc: TProc; const ExceptionClass: ExceptClass);
begin
  try
    Proc();
  except
    on Error: Exception do
      if Error is ExceptionClass then
        Exit
      else
        raise EAssertFail.CreateFmt('Unexpected exception raised %s!', [Error.ClassName]);
  end;

  raise EAssertFail.Create('No exceptions raised!');
end;

{ TestCaseAttribute }

constructor TestCaseAttribute.Create(const TestName, Param: String);
begin

end;

constructor TestCaseAttribute.Create(const TestName, Param1, Param2: String);
begin

end;

constructor TestCaseAttribute.Create(const TestName, Param1, Param2, Param3: String);
begin

end;

constructor TestCaseAttribute.Create(const TestName, Param1, Param2, Param3, Param4: String);
begin

end;

constructor TestCaseAttribute.Create(const TestName, Param1, Param2, Param3, Param4, Param5: String);
begin

end;

{ TTestClassMethod }

function TTestClassMethod.CallMethod(const Method: TRttiMethod): Boolean;

  procedure PostResultWithMessage(const ResultType: TResultType; const Message: String);
  begin
    FTestResult.ExceptionMessage := Message;
    FTestResult.ResultType := ResultType;
  end;

begin
  Result := False;

  try
    FTestClass.CallMethod(Method);

    Result := True;
  except
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

procedure TTestClassMethod.Execute;
var
  StartedTime: TDateTime;

begin
  StartedTime := Now;

  CallMethod(FTestSetup);

  if CallMethod(FTestMethod) then
  begin
    FTestResult.Duration := MilliSecondsBetween(Now, StartedTime);
    FTestResult.ResultType := TResultType.Passed;
  end;

  CallMethod(FTestTearDown);

  if FTestClass.LastTest = Self then
    CallMethod(FTestClass.FTestTearDownFixture);
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
    if Method.HasAttribute<SetupAttribute> then
      FTestSetup := Method
    else if Method.HasAttribute<TearDownAttribute> then
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
    if Method.HasAttribute<SetupFixtureAttribute> then
      FTestSetupFixture := Method
    else if Method.HasAttribute<TearDownFixtureAttribute> then
      FTestTearDownFixture := Method;
end;

end.

