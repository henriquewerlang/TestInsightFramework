unit MyClassTest;

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

end.
