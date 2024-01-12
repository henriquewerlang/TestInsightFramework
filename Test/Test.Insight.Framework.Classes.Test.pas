unit Test.Insight.Framework.Classes.Test;

interface

uses System.SysUtils, Test.Insight.Framework;

type
  EIgnoreDebugError = class(Exception);

  [TestFixture]
  TClassWithSetupError = class
  public
    class var SetupFixtureRaiseError: Boolean;
    class var TearDownFixtureRaiseError: Boolean;

    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure Test;
  end;

  [TestFixture]
  TMyClassTest = class
  public
    [Test]
    procedure Test;
    [Test]
    procedure Test2;
  end;

  [TestFixture]
  TMyClassTest2 = class
  public
    [Test]
    procedure Test;
    [Test]
    procedure Test2;
  end;

  [TestFixture]
  TMyClassTest3 = class
  public
    [Test]
    procedure Test;
    [Test]
    procedure Test2;
  end;

  [TestFixture]
  TClassWithoutTest = class
  public
    class var CreationCount: Integer;

    constructor Create;
  end;

  [TestFixture]
  TClassWithSetupAndTearDownFixture = class
  public
    class var SetupCalled: Integer;
    class var SetupFixtureCalled: Integer;
    class var TearDownCalled: Integer;
    class var TearDownFixtureCalled: Integer;
    class var TestCalled: Integer;

    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Test;
    [Test]
    procedure Test2;
    [Test]
    procedure Test3;
  end;

  [TestFixture]
  TClassInheritedFromAnotherClass = class(TClassWithSetupAndTearDownFixture)
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Test11;
    [Test]
    procedure Test12;
    [Test]
    procedure Test13;
  end;

  [TestFixture]
  TClassInheritedFromWithoutSetupAndTearDown = class(TClassWithSetupAndTearDownFixture)
  public
    [Test]
    procedure Test11;
  end;

  [TestFixture]
  TClassWithAsyncTest = class
  private
    class var FAssertCalled: Boolean;
    class var FDestroyCalled: Boolean;
    class var FTearDownCalled: Boolean;
    class var FTearDownFixtureCalled: Boolean;
  public
    destructor Destroy; override;

    [TearDownFixture]
    procedure TearDownFixture;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Test1;
    [Test]
    procedure Test2;
    [Test]
    procedure AsyncAssert;
    [Test]
    procedure Test3;
    [Test]
    procedure Test4;

    class property AssertCalled: Boolean read FAssertCalled write FAssertCalled;
    class property DestroyCalled: Boolean read FDestroyCalled write FDestroyCalled;
    class property TearDownCalled: Boolean read FTearDownCalled write FTearDownCalled;
    class property TearDownFixtureCalled: Boolean read FTearDownFixtureCalled write FTearDownFixtureCalled;
  end;

var
  WaitForTest: Boolean = False;

implementation

{ TMyClassTest }

procedure TMyClassTest.Test;
begin

end;

procedure TMyClassTest.Test2;
begin
  Assert.AreEqual(10, 20);
end;

{ TMyClassTest2 }

procedure TMyClassTest2.Test;
begin
  raise EIgnoreDebugError.Create('An error!');
end;

procedure TMyClassTest2.Test2;
begin
  if WaitForTest then
    Sleep(500);
end;

{ TMyClassTest3 }

procedure TMyClassTest3.Test;
begin

end;

procedure TMyClassTest3.Test2;
begin

end;

{ TClassWithoutTest }

constructor TClassWithoutTest.Create;
begin
  inherited;

  Inc(CreationCount);
end;

{ TClassWithSetupAndTearDownFixture }

procedure TClassWithSetupAndTearDownFixture.Setup;
begin
  Inc(SetupCalled);
end;

procedure TClassWithSetupAndTearDownFixture.SetupFixture;
begin
  Inc(SetupFixtureCalled);
end;

procedure TClassWithSetupAndTearDownFixture.TearDown;
begin
  Inc(TearDownCalled);
end;

procedure TClassWithSetupAndTearDownFixture.TearDownFixture;
begin
  Inc(TearDownFixtureCalled);
end;

procedure TClassWithSetupAndTearDownFixture.Test;
begin
  Inc(TestCalled);
end;

procedure TClassWithSetupAndTearDownFixture.Test2;
begin
  Inc(TestCalled);
end;

procedure TClassWithSetupAndTearDownFixture.Test3;
begin
  Inc(TestCalled);

  raise EIgnoreDebugError.Create('Any error!');
end;

{ TClassInheritedFromAnotherClass }

procedure TClassInheritedFromAnotherClass.Setup;
begin
  Inc(SetupCalled);
end;

procedure TClassInheritedFromAnotherClass.SetupFixture;
begin
  Inc(SetupFixtureCalled);
end;

procedure TClassInheritedFromAnotherClass.TearDown;
begin
  Inc(TearDownCalled);
end;

procedure TClassInheritedFromAnotherClass.TearDownFixture;
begin
  Inc(TearDownFixtureCalled);
end;

procedure TClassInheritedFromAnotherClass.Test11;
begin

end;

procedure TClassInheritedFromAnotherClass.Test12;
begin

end;

procedure TClassInheritedFromAnotherClass.Test13;
begin

end;

{ TClassInheritedFromWithoutSetupAndTearDown }

procedure TClassInheritedFromWithoutSetupAndTearDown.Test11;
begin

end;

{ TClassWithSetupError }

procedure TClassWithSetupError.SetupFixture;
begin
  if SetupFixtureRaiseError then
    raise EIgnoreDebugError.Create('SetupFixture Error!');
end;

procedure TClassWithSetupError.TearDownFixture;
begin
  if TearDownFixtureRaiseError then
    raise EIgnoreDebugError.Create('TeardownFixture Error');
end;

procedure TClassWithSetupError.Test;
begin

end;

{ TClassWithAsyncTest }

procedure TClassWithAsyncTest.AsyncAssert;
begin
  Assert.Async(
    procedure
    begin
      FAssertCalled := True;
      Assert.IsTrue(True);
    end);
end;

destructor TClassWithAsyncTest.Destroy;
begin
  DestroyCalled := True;

  inherited;
end;

procedure TClassWithAsyncTest.TearDown;
begin

end;

procedure TClassWithAsyncTest.TearDownFixture;
begin

end;

procedure TClassWithAsyncTest.Test1;
begin

end;

procedure TClassWithAsyncTest.Test2;
begin

end;

procedure TClassWithAsyncTest.Test3;
begin

end;

procedure TClassWithAsyncTest.Test4;
begin

end;

end.
