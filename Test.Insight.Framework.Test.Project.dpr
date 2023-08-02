program Test.Insight.Framework.Test.Project;

{$STRONGLINKTYPES ON}

uses
  FastMM5,
  DUnitX.MemoryLeakMonitor.FastMM5,
  TestInsight.DUnitX,
  DUnitX.TestFramework,
  Test.Insight.Framework in 'Test.Insight.Framework.pas',
  Test.Insight.Framework.Test in 'Test\Test.Insight.Framework.Test.pas',
  MyClassTest in 'Test\MyClassTest.pas';

begin
  TestInsight.DUnitX.RunRegisteredTests;
end.
