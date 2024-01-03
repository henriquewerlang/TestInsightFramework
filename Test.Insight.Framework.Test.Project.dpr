program Test.Insight.Framework.Test.Project;

{$STRONGLINKTYPES ON}

uses
  TestInsight.DUnitX,
  DUnitX.TestFramework,
  Test.Insight.Framework in 'Test.Insight.Framework.pas',
  Test.Insight.Framework.Test in 'Test\Test.Insight.Framework.Test.pas',
  Test.Insight.Framework.Classes.Test in 'Test\Test.Insight.Framework.Classes.Test.pas';

begin
  ReportMemoryLeaksOnShutdown := True;

  TestInsight.DUnitX.RunRegisteredTests;
end.

