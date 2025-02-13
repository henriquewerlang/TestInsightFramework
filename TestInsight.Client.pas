{******************************************************************************}
{                                                                              }
{           TestInsight                                                        }
{                                                                              }
{           Copyright (c) 2015-2021 Stefan Glienke - All rights reserved       }
{                                                                              }
{           http://www.dsharp.org                                              }
{                                                                              }
{******************************************************************************}

unit TestInsight.Client;

interface

{.$DEFINE USE_JCLDEBUG}
{.$DEFINE USE_MADEXCEPT}
{$IFDEF USE_MADEXCEPT}
  {.$DEFINE USE_ANSISTRING} // madExcept 3 used AnsiString
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
  {$MACRO ON}
  {$DEFINE CompilerVersion := 21}
  {$DEFINE RTLVersion := 21}
{$ENDIF}

{$IF CompilerVersion >= 25} // XE4 and higher
  {$ZEROBASEDSTRINGS OFF}
  {$LEGACYIFEND ON}
{$IFEND}

uses
{$IFDEF PAS2JS}
  System.Classes,
  System.Generics.Collections,
  JSApi.JS;
{$ELSE}
{$IF RTLVersion <= 22.0}
  Classes,
  Generics.Collections,
  IniFiles,
{$ELSE}
  System.Classes,
  System.Generics.Collections,
  System.IniFiles,
{$IFEND}
  IdHttp;
{$ENDIF}

const
  DefaultUrl = 'http://localhost:8102/';

{$SCOPEDENUMS ON}

type
  TResultType = (Passed, Failed, Error, Warning, Skipped, Running);

  TTestInsightResult = record
    ResultType: TResultType;
    TestName: string;
    FixtureName: string;
    Duration: Cardinal;
    ExceptionMessage: string;
    Status: string;
    UnitName: string;
    ClassName: string;
    MethodName: string;
    Path: string;
    LineNumber: Integer;
    constructor Create(const resultType: TResultType; const testName, fixtureName: string);
    function ToJson: string;
  end;

  TTestInsightOptions = record
    ExecuteTests: Boolean;
    ShowProgress: Boolean;
  end;

  ITestInsightClient = interface
    ['{14BE2648-7815-4026-A3D1-D62E9B0D8E43}']
    procedure ClearTests;
    function GetHasError: Boolean;
    function GetTests: TArray<string>;
    function GetOptions: TTestInsightOptions;
    procedure SetOptions(const value: TTestInsightOptions);

    procedure StartedTesting(const totalCount: Integer);
    procedure FinishedTesting;
    procedure PostResult(const testResult: TTestInsightResult;
      sendImmediately: Boolean = False);
    procedure PostResults(const testResults: array of TTestInsightResult;
      sendImmediately: Boolean = False);

    property HasError: Boolean read GetHasError;
    property Options: TTestInsightOptions read GetOptions write SetOptions;
  end;

  TTestInsightClientBase = class abstract(TInterfacedObject)
  protected
    fOptions: TTestInsightOptions;
    fTestResults: TList<TTestInsightResult>;
    function GetOptions: TTestInsightOptions;
    procedure SetOptions(const value: TTestInsightOptions);
  protected
    procedure Post(url: string; const content: string = ''); virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PostResult(const testResult: TTestInsightResult;
      sendImmediately: Boolean);
    procedure PostResults(const testResults: array of TTestInsightResult;
      sendImmediately: Boolean);
    procedure StartedTesting(const totalCount: Integer);
    procedure FinishedTesting;

    property Options: TTestInsightOptions read GetOptions write SetOptions;
  end;

{$IFNDEF PAS2JS}
  TTestInsightCustomClient = class abstract(TTestInsightClientBase)
  protected
    function OpenIni: TCustomIniFile;
    function ParseOptions(const response: string): TTestInsightOptions;
    function ParseTests(const response: string): TArray<string>;
  end;

  TTestInsightRestClient = class(TTestInsightCustomClient, ITestInsightClient)
  private
    fHttp: TIdHTTP;
    fRequest: TStrings;
    fBaseUrl: string;
    fHasError: Boolean;
  protected
    procedure Post(url: string; const content: string); override;
  public
    constructor Create(baseUrl: string = DefaultUrl);
    destructor Destroy; override;

    procedure ClearTests;
    function GetHasError: Boolean;
    function GetTests: TArray<string>;
  end;
{$ELSE}
  TTestInsightXhrClient = class(TTestInsightClientBase, ITestInsightClient)
  private
    fRequest: string;
    fBaseUrl: string;
    fHasError: Boolean;
  protected
    function ParseOptions(const response: string): TTestInsightOptions;
    function ParseTests(const response: string): TArray<string>;
  protected
    function HttpGet(const url: string): string;
    procedure HttpDelete(const url: string);
    procedure HttpPost(const url, content: string);
    procedure Post(url: string; const content: string); override;
  public
    constructor Create(baseUrl: string = DefaultUrl);
    destructor Destroy; override;

    procedure ClearTests;
    function GetHasError: Boolean;
    function GetTests: TArray<string>;
  end;
  TTestInsightRestClient = TTestInsightXhrClient;
{$ENDIF}

{$IFDEF ANDROID}
  TTestInsightLogcatClient = class(TTestInsightCustomClient, ITestInsightClient)
  strict private
    const
      TAG = 'testinsight';
    var
      fSelectedTests: TArray<string>;
  protected
    procedure Post(url: string; const content: string = ''); override;
  public
    constructor Create;

    procedure ClearTests;
    function GetHasError: Boolean;
    function GetTests: TArray<string>;
  end;
{$ENDIF}

procedure GetExtendedDetails(address: Pointer; var testResult: TTestInsightResult);

implementation

uses
{$IFDEF ANDROID}
  Androidapi.Log,
{$ENDIF}
{$IFDEF PAS2JS}
  BrowserAPI.web,
{$ELSE}
{$IF CompilerVersion >= 27} // XE6 and higher
  System.JSON,
{$ELSE}
{$IF RTLVersion <= 22.0}
  DBXJSON,
{$ELSE}
  Data.DBXJSON,
{$IFEND}
{$IFEND}
{$ENDIF}
{$IFDEF USE_JCLDEBUG}
  JclDebug,
{$ENDIF}
{$IFDEF USE_MADEXCEPT}
  madMapFile,
{$ENDIF}
{$IF RTLVersion <= 22.0}
  System.StrUtils,
  System.SysUtils;
{$ELSE}
  System.StrUtils,
  System.SysUtils;
{$IFEND}

procedure GetExtendedDetails(address: Pointer; var testResult: TTestInsightResult);
{$IF Defined(USE_JCLDEBUG)}
var
  info: TJclLocationInfo;
begin
  info := GetLocationInfo(address);
  testResult.UnitName := info.UnitName;
  testResult.LineNumber := info.LineNumber;
end;
{$ELSEIF Defined(USE_MADEXCEPT)}
var
  moduleName: {$IFDEF USE_ANSISTRING}AnsiString;{$ELSE}string;{$ENDIF}
  unitName: {$IFDEF USE_ANSISTRING}AnsiString;{$ELSE}string;{$ENDIF}
  publicName: {$IFDEF USE_ANSISTRING}AnsiString;{$ELSE}string;{$ENDIF}
  publicAddr: Pointer;
  line: Integer;
begin
  if GetMapFileInfos(address, moduleName, unitName, publicName, publicAddr, line) then
  begin
    testResult.UnitName := string(unitName);
    testResult.LineNumber := line;
  end;
end;
{$ELSE}
begin
end;
{$IFEND}

{$IFNDEF PAS2JS}
{$IF CompilerVersion <= 27} // XE6 and lower
type
  TJSONValueHelper = class helper for TJSONValue
    function ToJSON: string;
  end;

function TJSONValueHelper.ToJSON: string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(ToString) * 6);
  SetLength(LBytes, ToBytes(LBytes, 0));
  Result := TEncoding.Default.GetString(LBytes);
end;
{$IFEND}

{$IF CompilerVersion <= 26} // XE5 and lower
type
  TJSONObjectHelper = class helper for TJSONObject
  public
    function GetPair(const I: Integer): TJSONPair; inline;
    function GetValue(const Name: string): TJSONValue;
    property Pairs[const Index: Integer]: TJSONPair read GetPair;
    property Values[const Name: string]: TJSONValue read GetValue;
  end;

  TJSONArrayHelper = class helper for TJSONArray
  public
    function GetCount: Integer; inline;
    function GetValue(const Index: Integer): TJSONValue; inline;
    property Count: Integer read GetCount;
    property Items[const Index: Integer]: TJSONValue read GetValue;
  end;

function TJSONObjectHelper.GetPair(const I: Integer): TJSONPair;
begin
  Result := Get(I);
end;

function TJSONObjectHelper.GetValue(const Name: string): TJSONValue;
var
  LPair: TJSONPair;
begin
  LPair := Get(Name);
  if LPair <> nil then
    Result := LPair.JSONValue
  else
    Result := nil;
end;

function TJSONArrayHelper.GetCount: Integer;
begin
  Result := Size;
end;

function TJSONArrayHelper.GetValue(const Index: Integer): TJSONValue;
begin
  Result := Get(Index);
end;
{$IFEND}
{$ENDIF}

{ TTestInsightResult }

constructor TTestInsightResult.Create(const resultType: TResultType;
  const testName, fixtureName: string);
begin
  Self.ResultType := resultType;
  Self.TestName := testName;
  Self.FixtureName := fixtureName;
  Self.Duration := 0;
  Self.LineNumber := 0;
end;

function TTestInsightResult.ToJson: string;
const
  ResultTypeStrings: array[TResultType] of string = (
    'Passed', 'Failed', 'Error', 'Warning', 'Skipped', 'Running');
{$IFDEF PAS2JS}
var
  obj: TJSObject;
begin
  obj := TJSObject.new;
  obj['resulttype'] := ResultTypeStrings[ResultType];
  obj['testname'] := TestName;
  obj['fixturename'] := FixtureName;
  obj['duration'] := Duration;
  obj['exceptionmessage'] := ExceptionMessage;
  obj['unitname'] := UnitName;
  obj['classname'] := ClassName;
  obj['methodname'] := MethodName;
  obj['linenumber'] := LineNumber;
  obj['path'] := Path;
  obj['status'] := Status;
  Result := TJSJson.stringify(obj);
end;
{$ELSE}
var
  obj: TJSONObject;
begin
  obj := TJSONObject.Create;
  try
    obj.AddPair('resulttype', ResultTypeStrings[ResultType]);
    obj.AddPair('testname', TestName);
    obj.AddPair('fixturename', FixtureName);
    obj.AddPair('duration', TJSONNumber.Create(Duration));
    obj.AddPair('exceptionmessage', ExceptionMessage);
    obj.AddPair('unitname', UnitName);
    obj.AddPair('classname', ClassName);
    obj.AddPair('methodname', MethodName);
    obj.AddPair('linenumber', TJSONNumber.Create(LineNumber));
    obj.AddPair('path', Path);
    obj.AddPair('status', Status); // Keep it last as it can have very long size
    Result := obj.ToJSON;
  finally
    obj.Free;
  end;
end;
{$ENDIF}

{ TTestInsightClientBase }

constructor TTestInsightClientBase.Create;
begin
  inherited Create;
  fTestResults := TList<TTestInsightResult>.Create;
end;

destructor TTestInsightClientBase.Destroy;
begin
  fTestResults.Free;
  inherited;
end;

procedure TTestInsightClientBase.FinishedTesting;
begin
  if fTestResults.Count > 0 then
    PostResults(fTestResults.ToArray, True);
  Post('tests/finished');
end;

function TTestInsightClientBase.GetOptions: TTestInsightOptions;
begin
  Result := fOptions;
end;

procedure TTestInsightClientBase.PostResult(
  const testResult: TTestInsightResult; sendImmediately: Boolean);
begin
  PostResults([testResult], sendImmediately);
end;

procedure TTestInsightClientBase.PostResults(
  const testResults: array of TTestInsightResult; sendImmediately: Boolean);
var
  testResult: TTestInsightResult;
  content: string;
begin
  if Length(testResults) = 0 then
    Exit;
  if sendImmediately or (fOptions.ShowProgress and fOptions.ExecuteTests) then
  begin
    content := '[';
    for testResult in testResults do
      content := content + testResult.ToJson + ',';
    content[Length(content)] := ']';
    Post('tests/results', content);
  end
  else
    fTestResults.AddRange(testResults);
end;

procedure TTestInsightClientBase.SetOptions(const value: TTestInsightOptions);
begin
  fOptions := value;
  if fOptions.ShowProgress then
    PostResults(fTestResults.ToArray, True);
end;

procedure TTestInsightClientBase.StartedTesting(const totalCount: Integer);
begin
  Post(Format('tests/started?totalcount=%d', [totalCount]));
end;

{ TTestInsightCustomClient }

{$IFNDEF PAS2JS}
function TTestInsightCustomClient.OpenIni: TCustomIniFile;
var
  fileName: string;
begin
  Result := nil;
{$IFDEF ANDROID}
  fileName := '/storage/emulated/0/';
{$ELSE}
  fileName := ExtractFilePath(ParamStr(0));
{$ENDIF}
  fileName := fileName + 'TestInsightSettings.ini';
  if FileExists(fileName) then
  begin
    try
      // Use TMemIniFile it does not save the content on destroy
      Result := TMemIniFile.Create(fileName);
    except
      on EFOpenError do
        Exit; // Enable Read External Storage permission in project options
      else
        raise;
    end;
  end;
end;

function TTestInsightCustomClient.ParseOptions(const response: string): TTestInsightOptions;
var
  obj: TJSONObject;
begin
  obj := TJSONObject.ParseJSONValue(response) as TJSONObject;
  try
    Result := Default(TTestInsightOptions);
    if Assigned(obj) then
    begin
      Result.ExecuteTests := obj.Values['ExecuteTests'] is TJSONTrue;
      Result.ShowProgress := obj.Values['ShowProgress'] is TJSONTrue;
    end;
  finally
    obj.Free;
  end;
end;

function TTestInsightCustomClient.ParseTests(const response: string): TArray<string>;
var
  obj: TJSONObject;
  arr: TJSONArray;
  i: Integer;
begin
  obj := TJSONObject.ParseJSONValue(response) as TJSONObject;
  try
    arr := TJSONArray(obj.Pairs[0].JsonValue);
    SetLength(Result, arr.Count);
    for i := 0 to arr.Count - 1 do
      Result[i] := TJSONString(arr.Items[i]).Value;
  finally
    obj.Free;
  end;
end;

{ TTestInsightRestClient }

constructor TTestInsightRestClient.Create(baseUrl: string);
var
  iniFile: TCustomIniFile;
begin
  inherited Create;
  fHttp := TIdHttp.Create(nil);
  fHttp.HTTPOptions := fHttp.HTTPOptions + [hoKeepOrigProtocol] - [hoForceEncodeParams];
  fHttp.Request.ContentType := 'application/json';
  fHttp.ReadTimeout := 5000;
  fHttp.UseNagle := False;
  fRequest := TStringList.Create;

  iniFile := OpenIni;
  if Assigned(iniFile) then
  try
    baseUrl := iniFile.ReadString('Config', 'BaseUrl', baseUrl);
  finally
    iniFile.Free;
  end;

  if (baseUrl <> '') and (baseUrl[Length(baseUrl)] <> '/') then
    baseUrl := baseUrl + '/';
  fBaseUrl := baseUrl;

  try
    fOptions := ParseOptions(fHttp.Get(fBaseUrl + 'options'));
  except
    fHasError := True;
  end;
end;

destructor TTestInsightRestClient.Destroy;
begin
  fTestResults.Free;
  fRequest.Free;
{$IFNDEF AUTOREFCOUNT}
  fHttp.Free;
{$ELSE}
  fHttp.DisposeOf; // Fixes Indy leak bugs
{$ENDIF}
end;

procedure TTestInsightRestClient.ClearTests;
begin
  if not fHasError then
  try
    fHttp.Delete(fBaseUrl + 'tests');
  except
    fHasError := True;
  end;
end;

function TTestInsightRestClient.GetHasError: Boolean;
begin
  Result := fHasError;
end;

function TTestInsightRestClient.GetTests: TArray<string>;
begin
  if not fHasError then
  try
    Result := ParseTests(fHttp.Get(fBaseUrl + 'tests'));
  except
    fHasError := True;
  end;
end;

procedure TTestInsightRestClient.Post(url: string; const content: string);
begin
  if not fHasError then
  try
    fRequest.Text := content;
    try
      fHttp.Post(fBaseUrl + url, fRequest);
    finally
      fRequest.Clear;
    end;
  except
    fHasError := True;
  end;
end;
{$ENDIF}

{ TTestInsightLogcatClient }

{$IFDEF ANDROID}
procedure TTestInsightLogcatClient.ClearTests;
begin
  __android_log_write(ANDROID_LOG_DEBUG, TAG, 'tests/delete');
end;

constructor TTestInsightLogcatClient.Create;
var
  iniFile: TCustomIniFile;
begin
  inherited;

  iniFile := OpenIni;
  if Assigned(iniFile) then
  try
    if iniFile.ValueExists('Config', 'SelectedTests') then
    begin
      fSelectedTests := ParseTests(iniFile.ReadString('Config',
        'SelectedTests', ''));
    end;
  finally
    iniFile.Free;
  end;
end;

function TTestInsightLogcatClient.GetHasError: Boolean;
begin
  Result := False;
end;

function TTestInsightLogcatClient.GetTests: TArray<string>;
begin
  Result := fSelectedTests;
end;

procedure TTestInsightLogcatClient.Post(url: string; const content: string = '');
const
  MAX_PAYLOAD_SIZE = (4 * 1024) - 32 {~sizeof(logger_entry)}; // Hardcoded in android
  MESSAGE_SPLIT = MAX_PAYLOAD_SIZE - 100; // Keep some reserve

  procedure SendData(const data: string); //noinline - let the marshaller to free data ASAP
  var
    m: TMarshaller;
  begin
    __android_log_write(ANDROID_LOG_DEBUG, TAG, m.AsAnsi(data).ToPointer);
  end;

  procedure SendChunked(const data: string);
  var
    i: Integer;
  begin
    i := 1;
    SendData('chunk:start');
    while i <= Length(data) do
    begin
      SendData(Format('chunk:%d|', [i]) + Copy(data, i, MESSAGE_SPLIT));
      Inc(i, MESSAGE_SPLIT);
    end;
    SendData('chunk:end');
  end;

begin
  if content <> '' then
  begin
    if Pos('?', url) = 0 then
      url := url + '?';
    url := url + content;
  end;

  if (Length(url) > MAX_PAYLOAD_SIZE) then
    SendChunked(url)
  else
    SendData(url);
end;
{$ENDIF}

{ TTestInsightXhrClient }

{$IFDEF PAS2JS}
constructor TTestInsightXhrClient.Create(baseUrl: string);
var
  settings: TJSObject;
  baseUrlSetting: string;
begin
  inherited Create;

  try
    settings := TJSJson.parseObject(HttpGet('TestInsightSettings.json'));
    baseUrlSetting := JSApi.JS.ToString(settings['baseUrl']);
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
      fHasError := True;
    end;
  end;
end;

destructor TTestInsightXhrClient.Destroy;
begin
  fTestResults.Free;
  inherited;
end;

procedure TTestInsightXhrClient.ClearTests;
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

function TTestInsightXhrClient.GetHasError: Boolean;
begin
  Result := fHasError;
end;

function TTestInsightXhrClient.GetTests: TArray<string>;
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

procedure TTestInsightXhrClient.HttpDelete(const url: string);
var
  Xhr: TJSXMLHttpRequest;
begin
  Xhr := TJSXMLHttpRequest.new;
  Xhr.open('DELETE', url, False);
  Xhr.send;
  if Xhr.status >= 400 then
    fHasError := True;
end;

function TTestInsightXhrClient.HttpGet(const url: string): string;
var
  Xhr: TJSXMLHttpRequest;
begin
  Xhr := TJSXMLHttpRequest.new;
  Xhr.open('GET', url, False);
  Xhr.send;
  Result := xhr.responseText;
  if Xhr.status >= 400 then
    fHasError := True
end;

procedure TTestInsightXhrClient.HttpPost(const url, content: string);
var
  Xhr: TJSXMLHttpRequest;
begin
  Xhr := TJSXMLHttpRequest.new;
  Xhr.open('POST', url, False);
  Xhr.setRequestHeader('content-type', 'application/json');
  Xhr.send(content);
  if Xhr.status >= 400 then
    fHasError := True;
end;

function TTestInsightXhrClient.ParseOptions(const response: string): TTestInsightOptions;
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

function TTestInsightXhrClient.ParseTests(const response: string): TArray<string>;
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

procedure TTestInsightXhrClient.Post(url: string; const content: string);
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

end.
