unit Test.Insight.Framework;

interface

uses System.SysUtils, System.Rtti, TestInsight.Client;

type
  SetupAttribute = class(TCustomAttribute);
  SetupFixtureAttribute = class(TCustomAttribute);
  TearDownAttribute = class(TCustomAttribute);
  TearDownFixtureAttribute = class(TCustomAttribute);
  TestAttribute = class(TCustomAttribute);
  TestFixtureAttribute = class(TCustomAttribute);

  EAssertFail = class(Exception)
  end;

  TTestInsightFramework = class
  private
    FTestInsightClient: ITestInsightClient;

    function CreateObject(&Type: TRttiInstanceType): TObject;
  public
    constructor Create(const TestInsightClient: ITestInsightClient);

    procedure Run; overload;
    procedure Run(ObjectResolver: TFunc<TRttiInstanceType, TObject>); overload;

    class procedure ExecuteTests; overload;
    class procedure ExecuteTests(const ObjectResolver: TFunc<TRttiInstanceType, TObject>); overload;
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

{$IFDEF PAS2JS}
  TTestInsightPAS2JSClient = class(TTestInsightClientBase, ITestInsightClient)
  private
    FRequest: String;
    FBaseUrl: String;
    FHasError: Boolean;
  protected
    function ParseOptions(const response: String): TTestInsightOptions;
    function ParseTests(const response: String): TArray<String>;
  protected
    function HttpGet(const url: String): String;
    procedure HttpDelete(const url: String);
    procedure HttpPost(const url, content: String);
    procedure Post(url: String; const content: String); override;
  public
    constructor Create(baseUrl: String = DefaultUrl);
    destructor Destroy; override;

    procedure ClearTests;
    function GetHasError: Boolean;
    function GetTests: TArray<String>;
  end;
  TTestInsightRestClient = TTestInsightPAS2JSClient;
{$ENDIF}

implementation

uses System.DateUtils{$IFDEF PAS2JS}, Web, JS{$ENDIF};

{$IFDEF PAS2JS}

{ TTestInsightPAS2JSClient }

procedure TTestInsightPAS2JSClient.ClearTests;
begin
  if not fHasError then
  try
    HttpDelete(fBaseUrl + 'tests');
  except
    on JE: TJSError do
    begin
      console.log(JE);
      fHasError := True;
    end;
  end;
end;

constructor TTestInsightPAS2JSClient.Create(baseUrl: String);
var
  settings: TJSObject;
  baseUrlSetting: string;
begin
  inherited Create;

  try
    settings := TJSJson.parseObject(HttpGet('TestInsightSettings.json'));
    baseUrlSetting := JS.ToString(settings['baseUrl']);
    if baseUrlSetting <> '' then
      baseUrl := baseUrlSetting;
  except
  end;

  if (baseUrl <> '') and (baseUrl[Length(baseUrl)] <> '/') then
    baseUrl := baseUrl + '/';
  fBaseUrl := baseUrl;

  try
    fOptions := ParseOptions(HttpGet(fBaseUrl + 'options'));
  except
    on JE: TJSError do
    begin
      console.log(JE);
      FHasError := True;
    end;
  end;
end;

destructor TTestInsightPAS2JSClient.Destroy;
begin
  fTestResults.Free;

  inherited;
end;

function TTestInsightPAS2JSClient.GetHasError: Boolean;
begin
  Result := fHasError;
end;

function TTestInsightPAS2JSClient.GetTests: TArray<String>;
begin
  if not fHasError then
  try
    Result := ParseTests(HttpGet(fBaseUrl + 'tests'));
  except
    on JE: TJSError do
    begin
      console.log(JE);
      fHasError := True;
    end;
  end;
end;

procedure TTestInsightPAS2JSClient.HttpDelete(const url: String);
var
  Xhr: TJSXMLHttpRequest;
begin
  Xhr := TJSXMLHttpRequest.new;
  Xhr.open('DELETE', url, False);
  Xhr.send;
end;

function TTestInsightPAS2JSClient.HttpGet(const url: String): String;
var
  Xhr: TJSXMLHttpRequest;
begin
  Xhr := TJSXMLHttpRequest.new;
  Xhr.open('GET', url, False);
  Xhr.send;
  Result := xhr.responseText;
end;

procedure TTestInsightPAS2JSClient.HttpPost(const url, content: String);
var
  Xhr: TJSXMLHttpRequest;
begin
  Xhr := TJSXMLHttpRequest.new;
  Xhr.open('POST', url, False);
  Xhr.setRequestHeader('content-type', 'application/json');
  Xhr.send(content);
end;

function TTestInsightPAS2JSClient.ParseOptions(const response: String): TTestInsightOptions;
var
  obj: TJSObject;
begin
  obj := TJSJson.parseObject(response);
  Result := Default(TTestInsightOptions);
  if Assigned(obj) then
  begin
    Result.ExecuteTests := Boolean(obj['ExecuteTests']);
    Result.ShowProgress := Boolean(obj['ShowProgress']);
  end;
end;

function TTestInsightPAS2JSClient.ParseTests(const response: String): TArray<String>;
var
  obj: TJSObject;
  arr: TJSArray;
  i: Integer;
begin
  obj := TJSJson.ParseObject(response);
  arr := TJSArray(obj['SelectedTests']);
  SetLength(Result, arr.length);
  for i := 0 to arr.length - 1 do
    Result[i] := string(arr[i]);
end;

procedure TTestInsightPAS2JSClient.Post(url: String; const content: String);
begin
  if not fHasError then
  try
    fRequest := content;
    try
      HttpPost(fBaseUrl + url, fRequest);
    finally
      fRequest := '';
    end;
  except
    on JE: TJSError do
    begin
      console.log(JE);
      fHasError := True;
    end;
  end;
end;
{$ENDIF}

{ TTestInsightFramework }

constructor TTestInsightFramework.Create(const TestInsightClient: ITestInsightClient);
begin
  inherited Create;

  FTestInsightClient := TestInsightClient;
end;

function TTestInsightFramework.CreateObject(&Type: TRttiInstanceType): TObject;
var
  Method: TRttiMethod;

begin
  Result := nil;

  for Method in &Type.GetMethods do
    if Method.IsConstructor and (Method.GetParameters = nil) then
      Exit(Method.Invoke(&Type.AsInstance.MetaclassType, []).AsObject);
end;

class procedure TTestInsightFramework.ExecuteTests(const ObjectResolver: TFunc<TRttiInstanceType, TObject>);
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

procedure TTestInsightFramework.Run(ObjectResolver: TFunc<TRttiInstanceType, TObject>);
var
  AMethod: TRttiMethod;
  AType: TRttiType;
  Context: TRttiContext;
  Instance: TObject;
  SelectedTests: TArray<String>;
  StartedTime: TDateTime;
  TestResult: TTestInsightResult;

  procedure PostResult(const Result: TResultType);
  begin
    TestResult.ResultType := Result;

    FTestInsightClient.PostResult(TestResult, True);
  end;

  procedure PostError(const Result: TResultType; const Message: String);
  begin
    TestResult.ExceptionMessage := Message;

    PostResult(Result);
  end;

  function CanExecuteTest: Boolean;
  var
    CurrentTestName, TestName: String;

  begin
    Result := Length(SelectedTests) = 0;

    if not Result then
    begin
      CurrentTestName := Format('%s.%s', [AType.QualifiedName, AMethod.Name]);

      for TestName in SelectedTests do
        if CurrentTestName = TestName then
          Result := True;
    end;
  end;

  procedure CallProcedureWithAttribute(const AttributeClass: TCustomAttributeClass);
  var
    AMethod: TRttiMethod;

  begin
    for AMethod in AType.GetMethods do
      if AMethod.HasAttribute(AttributeClass) then
      begin
        AMethod.Invoke(Instance, []);

        Exit;
      end;
  end;

  procedure CallSetup;
  begin
    CallProcedureWithAttribute(SetupAttribute);
  end;

  procedure CallSetupFixture;
  begin
    CallProcedureWithAttribute(SetupFixtureAttribute);
  end;

  procedure CallTearDownFixture;
  begin
    CallProcedureWithAttribute(TearDownFixtureAttribute);
  end;

  procedure CallTearDown;
  begin
    CallProcedureWithAttribute(TearDownAttribute);
  end;

  procedure CheckInstance;
  begin
    if not Assigned(Instance) then
    begin
      Instance := ObjectResolver(AType.AsInstance);

      CallSetupFixture;
    end;
  end;

begin
  Context := TRttiContext.Create;

{$IFDEF DCC}
  FillChar(TestResult, SizeOf(TestResult), 0);
{$ENDIF}

  if not Assigned(ObjectResolver) then
    ObjectResolver := CreateObject;

  FTestInsightClient.StartedTesting(0);

  SelectedTests := FTestInsightClient.GetTests;

  for AType in Context.GetTypes do
    if AType.IsInstance and AType.HasAttribute<TestFixtureAttribute> then
    begin
      Instance := nil;

      for AMethod in AType.GetMethods do
        if AMethod.HasAttribute<TestAttribute> then
        begin
          TestResult := TTestInsightResult.Create(TResultType.Skipped, AMethod.Name, AType.AsInstance.DeclaringUnitName);
          TestResult.ClassName := AType.Name;
          TestResult.Duration := 0;
          TestResult.ExceptionMessage := EmptyStr;
          TestResult.MethodName := AMethod.Name;
          TestResult.Path := AType.QualifiedName;
          TestResult.UnitName := AType.AsInstance.DeclaringUnitName;

          PostResult(TResultType.Skipped);

          if CanExecuteTest then
          begin
            StartedTime := Now;

            PostResult(TResultType.Running);

            try
              CheckInstance;

              CallSetup;

              try
                AMethod.Invoke(Instance, []);

                TestResult.Duration := MilliSecondsBetween(Now, StartedTime);

                PostResult(TResultType.Passed);
              finally
                CallTearDown;
              end;
            except
              on TestFail: EAssertFail do
                PostError(TResultType.Failed, TestFail.Message);

              on Error: Exception do
                PostError(TResultType.Error, Error.Message);
            end;
          end;
        end;

      if Assigned(Instance) then
        CallTearDownFixture;

      Instance.Free;
    end;

  FTestInsightClient.FinishedTesting;

  Context.Free;
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
  WillRaise(Proc, nil);
end;

class procedure Assert.WillRaise(const Proc: TProc; const ExceptionClass: ExceptClass);
begin
  try
    Proc();
  except
    on Error: Exception do
      if not (Error is ExceptionClass) then
        raise EAssertFail.CreateFmt('Unexpected exception raised %s!', [Error.ClassName]);
  end;
end;

end.

