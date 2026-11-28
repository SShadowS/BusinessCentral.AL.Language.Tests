// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-deleteall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 90660 to 90663, table extension 90664, SingleInstance log codeunit 90665
//   (used only by test codeunit 90667), static subscriber codeunit 90666 (table events and "Global Triggers" events of the own tables only).
// local object: the OnDelete triggers, the table extension delete triggers and the subscribers log the order of the row code of DeleteAll;
//   that order is what is under test.
// Probe (al-runner issue 9401): the order in which DeleteAll runs its row code over two or more rows, by the record's sort order:
//   Ascending(false) and Ascending(true) on the primary key, a filter, a secondary key with ties (ascending, descending, SetAscending),
//   MarkedOnly, a temporary record, a RecordRef; and the row code that runs: OnDelete alone, OnBeforeDeleteEvent and OnAfterDeleteEvent
//   subscribers alone, the "Global Triggers" OnDatabaseDelete alone, and all of them together with OnGlobalDelete and the table extension
//   OnBeforeDelete, OnDelete and OnAfterDelete triggers; DeleteAll(false) and DeleteAll() as controls.
// Every test records what BC produced with Observer.Expect and ends in Verify().
// BC versions: 27, 28, 29

// OnDelete only.
table 90660 "DRO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp) { }
    }

    trigger OnDelete()
    var
        Log: Codeunit "DRO Log";
    begin
        Log.Add('T' + Format(Id));
    end;
}

// No OnDelete; OnBeforeDeleteEvent and OnAfterDeleteEvent subscribers only.
table 90661 "DRO Ev Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp) { }
    }
}

// No OnDelete; "Global Triggers" OnDatabaseDelete only.
table 90662 "DRO Db Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp) { }
    }
}

// OnDelete, table extension triggers, table event subscribers, OnGlobalDelete (mask 4) and OnDatabaseDelete.
table 90663 "DRO All Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp) { }
    }

    trigger OnDelete()
    var
        Log: Codeunit "DRO Log";
    begin
        Log.Add('T' + Format(Id));
    end;
}

tableextension 90664 "DRO All Row Ext" extends "DRO All Row"
{
    trigger OnBeforeDelete()
    var
        Log: Codeunit "DRO Log";
    begin
        Log.Add('xB' + Format(Id));
    end;

    trigger OnDelete()
    var
        Log: Codeunit "DRO Log";
    begin
        Log.Add('xT' + Format(Id));
    end;

    trigger OnAfterDelete()
    var
        Log: Codeunit "DRO Log";
    begin
        Log.Add('xA' + Format(Id));
    end;
}

codeunit 90665 "DRO Log"
{
    SingleInstance = true;

    var
        Seen: Text;

    procedure Add(Entry: Text)
    begin
        if Seen <> '' then
            Seen += ',';
        Seen += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Seen;
        Seen := '';
    end;
}

codeunit 90666 "DRO Subs"
{
    var
        Log: Codeunit "DRO Log";

    [EventSubscriber(ObjectType::Table, Database::"DRO Ev Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure EvBefore(var Rec: Record "DRO Ev Row"; RunTrigger: Boolean)
    begin
        Log.Add('B' + Format(Rec.Id) + '/' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"DRO Ev Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure EvAfter(var Rec: Record "DRO Ev Row"; RunTrigger: Boolean)
    begin
        Log.Add('A' + Format(Rec.Id) + '/' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"DRO All Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure AllBefore(var Rec: Record "DRO All Row"; RunTrigger: Boolean)
    begin
        Log.Add('B' + Format(Rec.Id) + '/' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"DRO All Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AllAfter(var Rec: Record "DRO All Row"; RunTrigger: Boolean)
    begin
        Log.Add('A' + Format(Rec.Id) + '/' + Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure OnGetMask(TableId: Integer; var TableTriggerMask: Integer)
    begin
        if TableId = Database::"DRO All Row" then
            TableTriggerMask := 4;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnGetSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId in [Database::"DRO Db Row", Database::"DRO All Row"] then
            OnDatabaseDelete := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalDelete', '', false, false)]
    local procedure OnGlobalDelete(RecRef: RecordRef)
    begin
        if RecRef.Number() in [Database::"DRO Db Row", Database::"DRO All Row"] then
            Log.Add('g' + Format(RecRef.Field(1).Value()));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    begin
        if RecRef.Number() in [Database::"DRO Db Row", Database::"DRO All Row"] then
            Log.Add('d' + Format(RecRef.Field(1).Value()));
    end;
}

codeunit 90667 "DRO Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "DRO Log";

    // Rows 1..Rows; with five rows Grp is 2,1,2,1,3 (ties on Grp, so the primary key decides inside a Grp value).
    local procedure Seed(TableNo: Integer; Rows: Integer)
    var
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(TableNo);
        RecRef.DeleteAll(false);
        for i := 1 to Rows do begin
            RecRef.Init();
            RecRef.Field(1).Value := i;
            RecRef.Field(2).Value := GrpOf(i);
            RecRef.Insert(false);
        end;
        RecRef.Close();
        Log.Take();
    end;

    local procedure GrpOf(i: Integer): Integer
    begin
        case i of
            1, 3:
                exit(2);
            2, 4:
                exit(1);
        end;
        exit(3);
    end;

    local procedure Left(TableNo: Integer) Result: Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        if RecRef.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(RecRef.Field(1).Value());
            until RecRef.Next() = 0;
        if Result = '' then
            Result := '<none>';
    end;

    // The reporter's repro: OnDelete only, three rows, primary key descending and ascending.
    [Test]
    procedure OnDeleteOnly_PrimaryKey_Order()
    var
        Row: Record "DRO Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO Row", 3);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('pk_descending', Log.Take());
        Observer.Observe('pk_descending|left', Left(Database::"DRO Row"));

        Seed(Database::"DRO Row", 3);
        Clear(Row);
        Row.Ascending(true);
        Row.DeleteAll(true);
        Observer.Observe('pk_ascending', Log.Take());
        Observer.Observe('pk_ascending|left', Left(Database::"DRO Row"));

        Seed(Database::"DRO Row", 5);
        Clear(Row);
        Row.SetRange(Id, 2, 4);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('pk_descending_filter', Log.Take());
        Observer.Observe('pk_descending_filter|left', Left(Database::"DRO Row"));

        Seed(Database::"DRO Row", 5);
        Clear(Row);
        Row.SetRange(Id, 2, 4);
        Row.DeleteAll(true);
        Observer.Observe('pk_ascending_filter', Log.Take());
        Observer.Finish();
    end;

    // OnDelete only, secondary key with ties.
    [Test]
    procedure OnDeleteOnly_SecondaryKey_Order()
    var
        Row: Record "DRO Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO Row", 5);
        Row.SetCurrentKey(Grp);
        Row.DeleteAll(true);
        Observer.Observe('grp_ascending', Log.Take());

        Seed(Database::"DRO Row", 5);
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('grp_descending', Log.Take());

        Seed(Database::"DRO Row", 5);
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.SetAscending(Grp, false);
        Row.DeleteAll(true);
        Observer.Observe('grp_setascending_false', Log.Take());

        Seed(Database::"DRO Row", 5);
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.SetRange(Grp, 1, 2);
        Row.DeleteAll(true);
        Observer.Observe('grp_descending_filter', Log.Take());
        Observer.Observe('grp_descending_filter|left', Left(Database::"DRO Row"));
        Observer.Finish();
    end;

    // OnDelete only: MarkedOnly, a temporary record and a RecordRef, all descending.
    [Test]
    procedure OnDeleteOnly_OtherForms_Descending()
    var
        Row: Record "DRO Row";
        TempRow: Record "DRO Row" temporary;
        RecRef: RecordRef;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO Row", 5);
        Row.Get(1);
        Row.Mark(true);
        Row.Get(3);
        Row.Mark(true);
        Row.Get(4);
        Row.Mark(true);
        Row.MarkedOnly(true);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('markedonly_descending', Log.Take());
        Observer.Observe('markedonly_descending|left', Left(Database::"DRO Row"));

        for i := 1 to 3 do begin
            TempRow.Init();
            TempRow.Id := i;
            TempRow.Grp := GrpOf(i);
            TempRow.Insert(false);
        end;
        Log.Take();
        TempRow.Ascending(false);
        TempRow.DeleteAll(true);
        Observer.Observe('temporary_descending', Log.Take());
        Observer.Observe('temporary_descending|count', Format(TempRow.Count()));

        Seed(Database::"DRO Row", 3);
        RecRef.Open(Database::"DRO Row");
        RecRef.Ascending(false);
        RecRef.DeleteAll(true);
        Observer.Observe('recordref_descending', Log.Take());
        Observer.Observe('recordref_descending|left', Left(Database::"DRO Row"));
        Observer.Finish();
    end;

    // OnDelete only: DeleteAll(false) and DeleteAll() run no row code.
    [Test]
    procedure OnDeleteOnly_NoRunTrigger_Descending()
    var
        Row: Record "DRO Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO Row", 3);
        Row.Ascending(false);
        Row.DeleteAll(false);
        Observer.Observe('false_descending', Log.Take());
        Observer.Observe('false_descending|left', Left(Database::"DRO Row"));

        Seed(Database::"DRO Row", 3);
        Clear(Row);
        Row.Ascending(false);
        Row.DeleteAll();
        Observer.Observe('default_descending', Log.Take());
        Observer.Observe('default_descending|left', Left(Database::"DRO Row"));
        Observer.Finish();
    end;

    // Table event subscribers only, no OnDelete.
    [Test]
    procedure EventsOnly_Order()
    var
        Row: Record "DRO Ev Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO Ev Row", 3);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('true_descending', Log.Take());

        Seed(Database::"DRO Ev Row", 3);
        Clear(Row);
        Row.DeleteAll(true);
        Observer.Observe('true_ascending', Log.Take());

        Seed(Database::"DRO Ev Row", 3);
        Clear(Row);
        Row.Ascending(false);
        Row.DeleteAll(false);
        Observer.Observe('false_descending', Log.Take());

        Seed(Database::"DRO Ev Row", 5);
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('true_grp_descending', Log.Take());

        Seed(Database::"DRO Ev Row", 5);
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.DeleteAll(false);
        Observer.Observe('false_grp_descending', Log.Take());
        Observer.Observe('left', Left(Database::"DRO Ev Row"));
        Observer.Finish();
    end;

    // "Global Triggers" OnDatabaseDelete only, no OnDelete.
    [Test]
    procedure DatabaseTriggerOnly_Order()
    var
        Row: Record "DRO Db Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO Db Row", 3);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('true_descending', Log.Take());

        Seed(Database::"DRO Db Row", 3);
        Clear(Row);
        Row.DeleteAll(true);
        Observer.Observe('true_ascending', Log.Take());

        Seed(Database::"DRO Db Row", 3);
        Clear(Row);
        Row.Ascending(false);
        Row.DeleteAll(false);
        Observer.Observe('false_descending', Log.Take());

        Seed(Database::"DRO Db Row", 5);
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('true_grp_descending', Log.Take());
        Observer.Observe('left', Left(Database::"DRO Db Row"));
        Observer.Finish();
    end;

    // OnDelete, table extension triggers, subscribers, OnGlobalDelete and OnDatabaseDelete together: primary key.
    [Test]
    procedure AllRowCode_PrimaryKey_Order()
    var
        Row: Record "DRO All Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO All Row", 3);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('true_descending', Log.Take());

        Seed(Database::"DRO All Row", 3);
        Clear(Row);
        Row.DeleteAll(true);
        Observer.Observe('true_ascending', Log.Take());

        Seed(Database::"DRO All Row", 3);
        Clear(Row);
        Row.Ascending(false);
        Row.DeleteAll(false);
        Observer.Observe('false_descending', Log.Take());

        Seed(Database::"DRO All Row", 5);
        Clear(Row);
        Row.SetRange(Id, 2, 4);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('true_descending_filter', Log.Take());
        Observer.Observe('true_descending_filter|left', Left(Database::"DRO All Row"));
        Observer.Finish();
    end;

    // All row code together: secondary key, temporary record, RecordRef.
    [Test]
    procedure AllRowCode_OtherForms_Order()
    var
        Row: Record "DRO All Row";
        TempRow: Record "DRO All Row" temporary;
        RecRef: RecordRef;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Database::"DRO All Row", 5);
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.DeleteAll(true);
        Observer.Observe('true_grp_descending', Log.Take());

        Seed(Database::"DRO All Row", 5);
        Clear(Row);
        Row.SetCurrentKey(Grp);
        Row.DeleteAll(true);
        Observer.Observe('true_grp_ascending', Log.Take());

        for i := 1 to 3 do begin
            TempRow.Init();
            TempRow.Id := i;
            TempRow.Grp := GrpOf(i);
            TempRow.Insert(false);
        end;
        Log.Take();
        TempRow.Ascending(false);
        TempRow.DeleteAll(true);
        Observer.Observe('temporary_true_descending', Log.Take());

        Seed(Database::"DRO All Row", 3);
        RecRef.Open(Database::"DRO All Row");
        RecRef.Ascending(false);
        RecRef.DeleteAll(true);
        Observer.Observe('recordref_true_descending', Log.Take());
        Observer.Observe('left', Left(Database::"DRO All Row"));
        Observer.Finish();
    end;
}
