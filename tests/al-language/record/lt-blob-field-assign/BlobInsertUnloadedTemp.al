// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 73780, table extension 73780 and helper codeunit 73780 of BlobInsertUnloaded.al; own
//   test codeunit 73784
// Probe (AL Runner issue 9286, the shapes named in the second review of AL Runner pull request 9301): follow-up of
//   BlobInsertUnloadedOrigin.al (T1, T2) and BlobInsertUnloaded.al (T12). A temporary row written with a stream ('mem', 'mem-raw',
//   'mem-ext') and inserted, then:
//   - R1: read with Get, Rename, and before any Insert or Modify the record's own Blobs: HasValue, Length and a stream read, then
//     CalcFields and the same three; R1b the same reads after Get without Rename (control); R1c after FindFirst and Rename;
//   - T1 form (read, Rename('T2'), the new key T3, Insert) with the read FindFirst, FindSet then Next (the second row), and
//     GetBySystemId (of T1's SystemId as Insert left it, and of a SystemId given with Insert(false, true)); TS: the SystemIds
//     the temporary rows hold;
//   - T12 form (read, the new key NEW, Insert) with the read FindFirst and GetBySystemId;
//   - O8: a database row read with GetBySystemId, copied under the new key NEW and inserted (the read origins of
//     BlobInsertUnloadedOrigin.al).
//   Readings as in BlobInsertUnloaded.al: own = the record's own Blobs (HasValue and the text a stream reads), before and stored =
//   the row read again with Get, HasValue before and the Blobs after CalcFields; R1 adds len_* (Blob.Length) and calc_* (after
//   CalcFields on the record itself).
//   BC 28 and later: the readings of a local BC 29.0.54011.57673 (Linux, W1, en-US session). BC 27.5: an observe round, not measured
//   yet.
// BC versions: 27, 28, 29 by CI
codeunit 73784 "LT BIU Temp Read Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // A temporary table with T0 ('zero', ...) and T1 ('mem', 'mem-raw', 'mem-ext').
    local procedure SeedTempRows(var T: Record "LT BIU Row" temporary)
    var
        Probe: Codeunit "LT BIU Probe";
    begin
        T.Reset();
        T.DeleteAll();
        T.Init();
        T."No." := 'T0';
        Probe.Write(T, 'zero', 'zero-raw', 'zero-ext');
        T.Insert();
        T.Init();
        T."No." := 'T1';
        Probe.Write(T, 'mem', 'mem-raw', 'mem-ext');
        T.Insert();
    end;

    // As SeedTempRows, with the SystemIds given (Insert(false, true)).
    local procedure SeedTempRowsWithIds(var T: Record "LT BIU Row" temporary)
    var
        Probe: Codeunit "LT BIU Probe";
    begin
        T.Reset();
        T.DeleteAll();
        T.Init();
        T."No." := 'T0';
        T.SystemId := '{00000000-0000-0000-0000-0000000000A0}';
        Probe.Write(T, 'zero', 'zero-raw', 'zero-ext');
        T.Insert(false, true);
        T.Init();
        T."No." := 'T1';
        T.SystemId := '{00000000-0000-0000-0000-0000000000A1}';
        Probe.Write(T, 'mem', 'mem-raw', 'mem-ext');
        T.Insert(false, true);
    end;

    // The record's own Blobs: HasValue, Length and a stream read (own_*), CalcFields, then the same again (calc_*).
    local procedure Reads(var Observer: Codeunit "Probe Observer"; var T: Record "LT BIU Row" temporary)
    var
        Probe: Codeunit "LT BIU Probe";
    begin
        Probe.Own(Observer, T);
        Observer.Observe('len', StrSubstNo('body=%1 raw=%2 ext=%3', T.Body.Length(), T.Raw.Length(), T.Ext.Length()));
        T.CalcFields(Body, Raw, Ext);
        Observer.Observe('calc_body', Probe.ShowBody(T));
        Observer.Observe('calc_raw', Probe.ShowRaw(T));
        Observer.Observe('calc_ext', Probe.ShowExt(T));
        Observer.Observe('calc_len', StrSubstNo('body=%1 raw=%2 ext=%3', T.Body.Length(), T.Raw.Length(), T.Ext.Length()));
    end;

    // The T1 form after the read: Rename('T2'), the new key T3, Insert; then the own Blobs and the stored row T3.
    local procedure RenameInsert(var Observer: Codeunit "Probe Observer"; var T: Record "LT BIU Row" temporary)
    var
        Probe: Codeunit "LT BIU Probe";
    begin
        T.Rename('T2');
        T."No." := 'T3';
        T.Insert();
        Probe.Own(Observer, T);
        Probe.StoredTemp(Observer, T, 'T3');
    end;

    // The T12 form after the read: the new key NEW, Insert; then the own Blobs and the stored row NEW.
    local procedure NewKeyInsert(var Observer: Codeunit "Probe Observer"; var T: Record "LT BIU Row" temporary)
    var
        Probe: Codeunit "LT BIU Probe";
    begin
        T."No." := 'NEW';
        T.Insert();
        Probe.Own(Observer, T);
        Probe.StoredTemp(Observer, T, 'NEW');
    end;

    [Test]
    procedure R1_TempGetRenameReads()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
    begin
        SeedTempRows(T);
        T.Get('T1');
        T.Rename('T2');
        Reads(Observer, T);
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('len', 'body=3 raw=7 ext=7');
        Observer.Expect('calc_body', 'hasValue=No text=[]');
        Observer.Expect('calc_raw', 'hasValue=No text=[]');
        Observer.Expect('calc_ext', 'hasValue=No text=[]');
        Observer.Expect('calc_len', 'body=0 raw=0 ext=0');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure R1b_TempGetReads()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
    begin
        SeedTempRows(T);
        T.Get('T1');
        Reads(Observer, T);
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('len', 'body=3 raw=7 ext=7');
        Observer.Expect('calc_body', 'hasValue=Yes text=[mem]');
        Observer.Expect('calc_raw', 'hasValue=Yes text=[mem-raw]');
        Observer.Expect('calc_ext', 'hasValue=Yes text=[mem-ext]');
        Observer.Expect('calc_len', 'body=3 raw=7 ext=7');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure R1c_TempFindFirstRenameReads()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
    begin
        SeedTempRows(T);
        T.SetRange("No.", 'T1');
        T.FindFirst();
        T.SetRange("No.");
        T.Rename('T2');
        Reads(Observer, T);
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('len', 'body=3 raw=7 ext=7');
        Observer.Expect('calc_body', 'hasValue=No text=[]');
        Observer.Expect('calc_raw', 'hasValue=No text=[]');
        Observer.Expect('calc_ext', 'hasValue=No text=[]');
        Observer.Expect('calc_len', 'body=0 raw=0 ext=0');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure T1_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
    begin
        SeedTempRows(T);
        T.SetRange("No.", 'T1');
        T.FindFirst();
        T.SetRange("No.");
        RenameInsert(Observer, T);
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure T1_FindSetNext()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
    begin
        SeedTempRows(T);
        T.FindSet();
        T.Next();
        Observer.Observe('read', T."No.");
        RenameInsert(Observer, T);
#if BC28PLUS
        Observer.Expect('read', 'T1');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure T1_GetBySystemId()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
        Id: Guid;
    begin
        SeedTempRows(T);
        T.Get('T1');
        Id := T.SystemId;
        Clear(T);
        T.GetBySystemId(Id);
        Observer.Observe('read', T."No.");
        RenameInsert(Observer, T);
#if BC28PLUS
        Observer.Expect('read', 'T0');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    // The SystemIds of the temporary rows SeedTempRows inserts.
    [Test]
    procedure TS_TempSystemIds()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
        Id0: Guid;
    begin
        SeedTempRows(T);
        T.Get('T0');
        Id0 := T.SystemId;
        Observer.Observe('t0_null', Format(IsNullGuid(T.SystemId)));
        T.Get('T1');
        Observer.Observe('t1_null', Format(IsNullGuid(T.SystemId)));
        Observer.Observe('same', Format(T.SystemId = Id0));
#if BC28PLUS
        Observer.Expect('t0_null', 'Yes');
        Observer.Expect('t1_null', 'Yes');
        Observer.Expect('same', 'Yes');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    // GetBySystemId with the SystemIds given: reads T1.
    [Test]
    procedure T1_GetBySystemIdGiven()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
    begin
        SeedTempRowsWithIds(T);
        Clear(T);
        T.GetBySystemId('{00000000-0000-0000-0000-0000000000A1}');
        Observer.Observe('read', T."No.");
        RenameInsert(Observer, T);
#if BC28PLUS
        Observer.Expect('read', 'T1');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure T12_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
    begin
        SeedTempRows(T);
        T.SetRange("No.", 'T1');
        T.FindFirst();
        T.SetRange("No.");
        NewKeyInsert(Observer, T);
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure T12_GetBySystemId()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BIU Row" temporary;
        Id: Guid;
    begin
        SeedTempRows(T);
        T.Get('T1');
        Id := T.SystemId;
        Clear(T);
        T.GetBySystemId(Id);
        Observer.Observe('read', T."No.");
        NewKeyInsert(Observer, T);
#if BC28PLUS
        Observer.Expect('read', 'T0');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure O8_GetBySystemId()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
        Id: Guid;
    begin
        Probe.Seed();
        Src.Get('SRC');
        Id := Src.SystemId;
        Clear(Src);
        Src.GetBySystemId(Id);
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
#if BC28PLUS
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;
}
