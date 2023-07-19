unit Test.Insight.Framework;

interface

uses System.SysUtils, TestInsight.Client;

type
  TestFixtureAttribute = class(TCustomAttribute);
  TestAttribute = class(TCustomAttribute);

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
  end;

implementation

uses System.Rtti, System.DateUtils;

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

  procedure PostResult(const Result: TResultType);
  begin
    TestResult.ResultType := Result;

    FTestInsightClient.PostResult(TestResult, True);
  end;

begin
  Context := TRttiContext.Create;

{$IFDEF DCC}
  FillChar(TestResult, SizeOf(TestResult), 0);
{$ENDIF}

  FTestInsightClient.StartedTesting(0);

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
        if AMethod.HasAttribute<TestAttribute> then
        begin
          StartedTime := Now;
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
end;

{ Assert }

class procedure Assert.AreEqual<T>(const Expected, CurrentValue: T);
begin
  if Expected <> CurrentValue then
    raise EAssertFail.CreateFmt('The value expected is %s and the current value is %s', [TValue.From<T>(Expected).ToString, TValue.From<T>(CurrentValue).ToString]);
end;

end.

