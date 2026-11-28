// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-minimumactiverowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67516 "LT RV Row" (PlTRowVersionValue.al)
// Measured on BC 27.5, 28.5 and 29.0 (Linux legs): Min is fixed per test codeunit. Its first read in a codeunit is LastUsedRowVersion() + 1, and
// it does not move again for the rest of the codeunit: not through an open Insert or Modify, not through Commit, not through a second write, a
// DeleteAll, or the next test (also under RequiredTestIsolation = Codeunit and = Function). LastUsedRowVersion() grows with each Insert and Modify,
// so after the first write Min is below LastUsedRowVersion() + 1. The first row inserted after the first read has SystemRowVersion = Min; later rows
// are above Min; a row's SystemRowVersion is never above LastUsedRowVersion(). The distance Min - Last differs between BC versions and runs and is not asserted.
// Other sessions (issue 1660): MinimumActiveRowVersion and LastUsedRowVersion are database wide, so a write of any other session on the same
// database counts too. An idle BC 28.5 test container moved LastUsedRowVersion 5 times (13 versions) in 45 seconds while the test wrote nothing,
// and 1 of 300 repeats of the FirstTest window (first read, Insert, read) had a foreign version in it. In a FirstTest nothing of the codeunit holds
// a row version yet, so such a write changes the result. CI legs (BC 28.5 and 29.0, different FirstTests) gave 'ins row/min = greater' (the other
// session took the next version and still held it) and 'ins min/first = greater' (it took the next version and committed). This is not an ordering
// effect of earlier tests and cannot be made deterministic from AL. So a FirstTest asserts the exact relations (Min = Last + 1 at the first read, first row = Min, Min unchanged
// at every stage) only in a quiet run: Min = Last + 1 at the first read and the first Insert got Last + 1, so no other session held or took a
// version before the first Insert. From then on the open first Insert holds the lowest active version, and later writes of other sessions cannot
// move Min. In a run that is not quiet, the FirstTest asserts only what holds either way: Min at the first read is not above Last + 1 ('same or
// less'), the first row is not below Min and Min never drops below an earlier read ('same or greater'), and every other relation as in a quiet
// run. A runner with one session is always quiet. The SecondTests need no gate: the open write of their FirstTest already holds Min.
// Probe: how Database.MinimumActiveRowVersion() relates to LastUsedRowVersion() and to the SystemRowVersion of a written row, read in a
// fixed order of stages: the first read of a test (no write yet), an open Insert, an open Modify, after Commit, a second write after Commit,
// and a DeleteAll with and without Commit. The same sequence runs in a codeunit with the default TestIsolation, with RequiredTestIsolation = Codeunit
// and with RequiredTestIsolation = Function. Only relations are asserted (same, greater, less), plus the difference Min - Last where it is stable.
// The codeunits are new (not an extension of "LT RV Tests", 67515) because the first read of a test must come before any write of the
// codeunit, and because RequiredTestIsolation is a property of the whole codeunit.
// Observation names: <test tag> <stage> <what>; stages: first (before any write), ins and mod (open Insert and Modify of row 1), com (after Commit),
// ins2, mod2 and com2 (the same for row 2), del (DeleteAll of both rows, open) and delcom (after its Commit). 'min/first' is Min compared with the first
// read, 'min/prev' with the previous stage, 'last/first' is LastUsedRowVersion against its first read, 'row/min' and 'row/last' compare the row's SystemRowVersion,
// 'tx' is IsInWriteTransaction.
// local object: the helper codeunit exists only to share one sequence between three test codeunits.
// BC versions: 27+

codeunit 97985 "MRV Sequence"
{
    local procedure Rel(Value: BigInteger; Other: BigInteger): Text
    begin
        if Value = Other then
            exit('same');
        if Value > Other then
            exit('greater');
        exit('less');
    end;

    // Where another session may have taken a row version (see the header), a relation is reported in the form that holds either way.
    local procedure NotBelow(Value: BigInteger; Other: BigInteger): Text
    begin
        if Value >= Other then
            exit('same or greater');
        exit('less');
    end;

    local procedure NotAbove(Value: BigInteger; Other: BigInteger): Text
    begin
        if Value <= Other then
            exit('same or less');
        exit('greater');
    end;

    local procedure Stage(var Observer: Codeunit "Probe Observer"; Tag: Text; Min0: BigInteger; Last0: BigInteger; var PrevMin: BigInteger; RowVersion: BigInteger; MinExact: Boolean; RowExact: Boolean)
    var
        Min: BigInteger;
        Last: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        if MinExact then begin
            Observer.Observe(Tag + ' min/first', Rel(Min, Min0));
            Observer.Observe(Tag + ' min/prev', Rel(Min, PrevMin));
        end else begin
            Observer.Observe(Tag + ' min/first', NotBelow(Min, Min0));
            Observer.Observe(Tag + ' min/prev', NotBelow(Min, PrevMin));
        end;
        Observer.Observe(Tag + ' last/first', Rel(Last, Last0));
        Observer.Observe(Tag + ' min/last+1', Rel(Min, Last + 1));
        if RowVersion <> 0 then begin
            if RowExact then
                Observer.Observe(Tag + ' row/min', Rel(RowVersion, Min))
            else
                Observer.Observe(Tag + ' row/min', NotBelow(RowVersion, Min));
            Observer.Observe(Tag + ' row<=last', Format(RowVersion <= Last));
        end;
        Observer.Observe(Tag + ' tx', Format(IsInWriteTransaction()));
        PrevMin := Min;
    end;

    local procedure Expect(var Observer: Codeunit "Probe Observer"; Tag: Text; HasRow: Boolean; RowVsMin: Text; Tx: Text; MinExact: Boolean)
    begin
        if MinExact then begin
            Observer.Expect(Tag + ' min/first', 'same');
            Observer.Expect(Tag + ' min/prev', 'same');
        end else begin
            Observer.Expect(Tag + ' min/first', 'same or greater');
            Observer.Expect(Tag + ' min/prev', 'same or greater');
        end;
        Observer.Expect(Tag + ' last/first', 'greater');
        Observer.Expect(Tag + ' min/last+1', 'less');
        if HasRow then begin
            Observer.Expect(Tag + ' row/min', RowVsMin);
            Observer.Expect(Tag + ' row<=last', 'Yes');
        end;
        Observer.Expect(Tag + ' tx', Tx);
    end;

    // FirstTest: the first test of its codeunit (nothing written yet), so Min = Last + 1 at the first read and the first row has SystemRowVersion = Min,
    // unless another session took a row version between the first read and the Insert or still held an open one (Quiet is false then).
    procedure Run(var Observer: Codeunit "Probe Observer"; Tag: Text; FirstTest: Boolean)
    var
        Row: Record "LT RV Row";
        Min0: BigInteger;
        Last0: BigInteger;
        PrevMin: BigInteger;
        FirstTx: Boolean;
        Quiet: Boolean;
        FirstRowVsMin: Text;
    begin
        Min0 := MinimumActiveRowVersion();
        Last0 := LastUsedRowVersion();
        FirstTx := IsInWriteTransaction();
        PrevMin := Min0;
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        // No other session held or took a row version up to the Insert: Min0 was Last0 + 1 and the Insert got Last0 + 1. From then on the open
        // Insert holds the lowest active version, so later writes of other sessions cannot move Min. A SecondTest does not need it: the open
        // write of the FirstTest already holds Min.
        Quiet := (not FirstTest) or ((Min0 = Last0 + 1) and (Row.SystemRowVersion = Last0 + 1));
        if Quiet then
            Observer.Observe(Tag + ' first min/last+1', Rel(Min0, Last0 + 1))
        else
            Observer.Observe(Tag + ' first min/last+1', NotAbove(Min0, Last0 + 1));
        Observer.Observe(Tag + ' first min>0', Format(Min0 > 0));
        Observer.Observe(Tag + ' first tx', Format(FirstTx));
        Stage(Observer, Tag + ' ins', Min0, Last0, PrevMin, Row.SystemRowVersion, Quiet, Quiet);
        Row.Name := 'x';
        Row.Modify();
        Row.Get(1);
        Stage(Observer, Tag + ' mod', Min0, Last0, PrevMin, Row.SystemRowVersion, Quiet, true);
        Commit();
        Stage(Observer, Tag + ' com', Min0, Last0, PrevMin, Row.SystemRowVersion, Quiet, true);
        Row.Id := 2;
        Row.Insert();
        Row.Get(2);
        Stage(Observer, Tag + ' ins2', Min0, Last0, PrevMin, Row.SystemRowVersion, Quiet, true);
        Row.Name := 'y';
        Row.Modify();
        Row.Get(2);
        Stage(Observer, Tag + ' mod2', Min0, Last0, PrevMin, Row.SystemRowVersion, Quiet, true);
        Commit();
        Stage(Observer, Tag + ' com2', Min0, Last0, PrevMin, Row.SystemRowVersion, Quiet, true);
        Row.DeleteAll();
        Stage(Observer, Tag + ' del', Min0, Last0, PrevMin, 0, Quiet, true);
        Commit();
        Stage(Observer, Tag + ' delcom', Min0, Last0, PrevMin, 0, Quiet, true);

        if not Quiet then begin
            Observer.Expect(Tag + ' first min/last+1', 'same or less');
            FirstRowVsMin := 'same or greater';
        end else
            if FirstTest then begin
                Observer.Expect(Tag + ' first min/last+1', 'same');
                FirstRowVsMin := 'same';
            end else begin
                Observer.Expect(Tag + ' first min/last+1', 'less');
                FirstRowVsMin := 'greater';
            end;
        Observer.Expect(Tag + ' first min>0', 'Yes');
        Observer.Expect(Tag + ' first tx', 'No');
        Expect(Observer, Tag + ' ins', true, FirstRowVsMin, 'Yes', Quiet);
        Expect(Observer, Tag + ' mod', true, 'greater', 'Yes', Quiet);
        Expect(Observer, Tag + ' com', true, 'greater', 'No', Quiet);
        Expect(Observer, Tag + ' ins2', true, 'greater', 'Yes', Quiet);
        Expect(Observer, Tag + ' mod2', true, 'greater', 'Yes', Quiet);
        Expect(Observer, Tag + ' com2', true, 'greater', 'No', Quiet);
        Expect(Observer, Tag + ' del', false, '', 'Yes', Quiet);
        Expect(Observer, Tag + ' delcom', false, '', 'No', Quiet);
    end;
}

codeunit 97987 "MRV Default Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Sequence: Codeunit "MRV Sequence";

    [Test]
    procedure MinRowVersion_DefaultIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'a', true);
        Observer.Verify();
    end;

    [Test]
    procedure MinRowVersion_DefaultIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b', false);
        Observer.Verify();
    end;
}

codeunit 97988 "MRV Codeunit Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Sequence: Codeunit "MRV Sequence";

    [Test]
    procedure MinRowVersion_CodeunitIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'a', true);
        Observer.Verify();
    end;

    [Test]
    procedure MinRowVersion_CodeunitIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b', false);
        Observer.Verify();
    end;
}

codeunit 97989 "MRV Function Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    var
        Sequence: Codeunit "MRV Sequence";

    [Test]
    procedure MinRowVersion_FunctionIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'a', true);
        Observer.Verify();
    end;

    [Test]
    procedure MinRowVersion_FunctionIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b', false);
        Observer.Verify();
    end;
}

codeunit 97990 "MRV Open First Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Hypothesis checked here: Min is fixed when the codeunit starts, not at the first read, so after three writes Min is below Last + 1 and
    // the last written row is above Min.
    [Test]
    procedure MinRowVersion_OpenWriteBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Min: BigInteger;
        Last: BigInteger;
    begin
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Row.Get(3);
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        if Min = Last + 1 then
            Observer.Observe('open write first min/last+1', 'same')
        else
            if Min > Last + 1 then
                Observer.Observe('open write first min/last+1', 'greater')
            else
                Observer.Observe('open write first min/last+1', 'less');
        Observer.Observe('open write first row/min', Format(Row.SystemRowVersion > Min));
        Observer.Observe('open write first tx', Format(IsInWriteTransaction()));
        Observer.Expect('open write first min/last+1', 'less');
        Observer.Expect('open write first row/min', 'Yes');
        Observer.Expect('open write first tx', 'Yes');
        Observer.Verify();
    end;
}

codeunit 97991 "MRV Committed First Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Hypothesis checked here: Min is fixed when the codeunit starts, not at the first read, so after three writes Min is below Last + 1 and
    // the last written row is above Min.
    [Test]
    procedure MinRowVersion_CommittedWriteBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Min: BigInteger;
        Last: BigInteger;
    begin
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Commit();
        Row.Get(3);
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        if Min = Last + 1 then
            Observer.Observe('committed write first min/last+1', 'same')
        else
            if Min > Last + 1 then
                Observer.Observe('committed write first min/last+1', 'greater')
            else
                Observer.Observe('committed write first min/last+1', 'less');
        Observer.Observe('committed write first row/min', Format(Row.SystemRowVersion > Min));
        Observer.Observe('committed write first tx', Format(IsInWriteTransaction()));
        Observer.Expect('committed write first min/last+1', 'less');
        Observer.Expect('committed write first row/min', 'Yes');
        Observer.Expect('committed write first tx', 'No');
        Observer.Verify();
    end;
}
