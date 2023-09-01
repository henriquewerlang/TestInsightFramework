unit Test.Insight.Framework.Classes.Test;

interface

uses Test.Insight.Framework;

type
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

var
  WaitForTest: Boolean = False;

implementation

uses System.SysUtils;

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
  raise Exception.Create('An error!');
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

end;

procedure TClassWithSetupAndTearDownFixture.Test2;
begin

end;

procedure TClassWithSetupAndTearDownFixture.Test3;
begin
  raise Exception.Create('Any error!');
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

end.
