unit Test.Insight.Framework;

interface

uses System.SysUtils, TestInsight.Client;

type
  TestAttribute = class(TCustomAttribute);
  TestFixtureAttribute = class(TCustomAttribute);

  EAssertFail = class(Exception)
  end;

  TTestInsightFramework = class
  private
    FTestInsightClient: ITestInsightClient;
  public
    constructor Create(const TestInsightClient: ITestInsightClient);

    procedure Run;

    class procedure ExecuteTests;
  end;

  Assert = class
  public
    class procedure AreEqual<T>(const Expected, CurrentValue: T);
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

uses System.Rtti, System.DateUtils{$IFDEF PAS2JS}, Web, JS{$ENDIF};

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

class procedure TTestInsightFramework.ExecuteTests;
var
  TestFramework: TTestInsightFramework;

begin
  TestFramework := TTestInsightFramework.Create(TTestInsightRestClient.Create);

  TestFramework.Run;

  TestFramework.Free;
end;

procedure TTestInsightFramework.Run;
var
  Context: TRttiContext;

  ConstructorMethod: TRttiMethod;

  TestResult: TTestInsightResult;

  Instance: TObject;

  StartedTime: TDateTime;

  AType: TRttiType;

  AMethod: TRttiMethod;

  SelectedTests: TArray<String>;

  procedure PostResult(const Result: TResultType);
  begin
    TestResult.ResultType := Result;

    FTestInsightClient.PostResult(TestResult, True);
  end;

  function CanExecuteTest: Boolean;
  begin
    Result := Length(SelectedTests) = 0;

    if not Result then
    begin
      var CurrentTestName := Format('%s.%s', [AType.QualifiedName, AMethod.Name]);

      for var TestName in SelectedTests do
        if CurrentTestName = TestName then
          Result := True;
    end;

    Result := Result and AMethod.HasAttribute<TestAttribute>;
  end;

begin
  Context := TRttiContext.Create;

{$IFDEF DCC}
  FillChar(TestResult, SizeOf(TestResult), 0);
{$ENDIF}

  FTestInsightClient.StartedTesting(0);

  SelectedTests := FTestInsightClient.GetTests;

  for AType in Context.GetTypes do
    if AType.IsInstance and AType.HasAttribute<TestFixtureAttribute> then
    begin
      ConstructorMethod := nil;

      for AMethod in AType.GetMethods do
        if AMethod.IsConstructor and (AMethod.GetParameters = nil) then
        begin
          ConstructorMethod := AMethod;

          Break;
        end;

      Instance := ConstructorMethod.Invoke(AType.AsInstance.MetaclassType, []).AsObject;

      for AMethod in AType.GetMethods do
        if CanExecuteTest then
        begin
          StartedTime := Now;
          TestResult := TTestInsightResult.Create(TResultType.Running, AMethod.Name, AType.AsInstance.DeclaringUnitName);
          TestResult.ClassName := AType.Name;
          TestResult.Duration := 0;
          TestResult.ExceptionMessage := EmptyStr;
          TestResult.MethodName := AMethod.Name;
          TestResult.Path := AType.QualifiedName;
          TestResult.UnitName := AType.AsInstance.DeclaringUnitName;

          PostResult(TResultType.Running);

          try
            AMethod.Invoke(Instance, []);

            TestResult.Duration := MilliSecondsBetween(Now, StartedTime);

            PostResult(TResultType.Passed);
          except
            on TestFail: EAssertFail do
              PostResult(TResultType.Failed);

            on Error: Exception do
            begin
              TestResult.ExceptionMessage := Error.Message;

              PostResult(TResultType.Error);
            end;
          end;
        end;

      Instance.Free;
    end;

  FTestInsightClient.FinishedTesting;

  Context.Free;
end;

{ Assert }

class procedure Assert.AreEqual<T>(const Expected, CurrentValue: T);
begin
  if Expected <> CurrentValue then
    raise EAssertFail.CreateFmt('The value expected is %s and the current value is %s', [TValue.From<T>(Expected).ToString, TValue.From<T>(CurrentValue).ToString]);
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

