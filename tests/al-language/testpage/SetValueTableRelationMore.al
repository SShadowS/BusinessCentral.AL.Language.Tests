// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 73390 ("LT TSV Book"), 73391 ("LT TSV Host") and 73396 ("LT TSV Cap Book") and
//   pages 73392 ("LT TSV Filtered Var") and 73394 ("LT TSV Host Card") of SetValueTableRelation.al; own table 73340, pages
//   73340..73344, report 73340, test codeunit 73340
// local object: the control's TableRelation is the property under test.
// Probe (follow-up of corpus pull request 1646, SetValueTableRelation.al; the cells the review of AL Runner pull request 9418
//   asks for, point 6 and point 3): TestPage and TestRequestPage <control>.SetValue(Text) on a control with a TableRelation, in the
//   combinations SetValueTableRelation.al does not measure:
//   - a Code[10] variable on a report request page;
//   - a Code[10] variable related to the captioned table, holding a value (set in OnOpenPage), or related by "LT TSV Book"."Code";
//   - a request-page Text[10] variable with a where() filter, related to the non-key field Name, related by "LT TSV Book"."Code",
//     or related to the captioned table;
//   - a const where() on a non-Boolean field (Name = const('Shared'));
//   - a table field typed as a lower-case prefix, holding a value, related by "LT TSV Book"."Code", or on an OpenNew row;
//   - a lower-case prefix inside the filter;
//   - a prefix of a key inside the filter (XYZA, Active) and the same text as an exact key outside it (XYZ, not Active), both stored.
//   The rows of "LT TSV Book": ABC (Name Shared, Active), ABD (Shared, Active), MNO (Unique Name, Active), XYZ (Hidden, not
//   Active), and for the last cell XYZA (Extra, Active); "LT TSV Cap Book": CB1.
//   Each cell opens the page with OpenEdit (or OpenNew), calls SetValue inside a TryFunction and records: set = "ok" or
//   "E: <GetLastErrorText> | <GetLastErrorCode>"; value = the control's Value() afterwards; validated = the OnValidate count where
//   the page shows one; stored = the record after Close for table fields.
//   Measured on a local BC 29.0.54011.57673 service tier (Linux, W1, en-US session) on 2026-11-28 with an invented app holding
//   these objects (AL 18.0.43.1464, run by al runtests of AL tool 18.1.43.24897); the values are those readings, turned into
//   Expect and Verify by convert.py verbatim. This pull request's CI observe run 46161976815 measured every test on BC
//   27.5.54899.59044, the same on both 27.5 legs, with readings equal to BC 29 in every cell, so one set of assertions holds on
//   every version, with no version guard.
//   Facts (BC 29.0.54011.57673):
//   - A Code[10] variable on a request page behaves like one on a page: 'abc' gives ABC, 'mn' gives MNO, 'zzz' fails with "The LT
//     TSV Book does not exist. Identification fields and values: Code='ZZZ'".
//   - Request-page Text variables: with Active = true, the exact key XYZ outside the filter is taken (XYZ), its prefix 'XY' fails
//     with the does-not-exist text, and 'mn' inside gives MNO; related to Name, 'Unique Name' fails with the primary-key text;
//     related by "LT TSV Book"."Code", 'mn' gives MNO; related to the captioned table, 'zzz' fails with "The Captioned Book does
//     not exist. Identification fields and values: Book No.='ZZZ'".
//   - A Code[10] variable related to the captioned table: 'cb1' gives CB1, 'zzz' gives the captioned does-not-exist text. Holding
//     ABC: 'mn' gives MNO (OnValidate ran once), 'zzz' fails and the control keeps ABC (OnValidate did not run). Related by
//     "LT TSV Book"."Code": 'mn' gives MNO, 'zzz' the does-not-exist text.
//   - A const where() on the Text field Name (Shared): 'ABC' gives ABC, 'ab' gives ABC; the exact key MNO outside the filter is
//     taken (MNO); its prefix 'MN' fails with the does-not-exist text for Code='MN'. The same rule as the Boolean filter.
//   - The host table field "Book Code": 'mn' gives MNO; holding ABC, 'mn' gives MNO and 'zzz' fails with the "cannot be found in
//     the related table" text and keeps ABC (stored ABC, OnValidate did not run); on an OpenNew row 'abc' gives ABC and the new
//     row (Id 0) stores ABC. A table field related by "LT TSV Book"."Code": 'mn' gives MNO, 'zzz' fails with "The field Key Book
//     Code of table LT TSF Key Host contains a value (ZZZ) that cannot be found in the related table (LT TSV Book). ...".
//   - The filtered variable (Active = true): 'mn' gives MNO; with XYZA (Active) and XYZ (not Active) both stored, 'XYZ' gives
//     XYZA: the prefix match inside the filter wins over the exact key outside it.
// BC versions: 27, 28, 29 by CI
table 73340 "LT TSF Key Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Key Book Code"; Code[10]) { TableRelation = "LT TSV Book"."Code"; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73340 "LT TSF Code Cap Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Captioned Book Code'; TableRelation = "LT TSV Cap Book"; }
        }
    }

    var
        BookCode: Code[10];
}

page 73341 "LT TSF Code Held Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode)
            {
                ApplicationArea = All;
                Caption = 'Book Code';
                TableRelation = "LT TSV Book";

                trigger OnValidate()
                begin
                    Validated += 1;
                end;
            }
            field(ValidatedCtl; Validated) { ApplicationArea = All; Editable = false; }
        }
    }

    trigger OnOpenPage()
    begin
        BookCode := 'ABC';
    end;

    var
        BookCode: Code[10];
        Validated: Integer;
}

page 73342 "LT TSF Code KeyField Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Book Code'; TableRelation = "LT TSV Book"."Code"; }
        }
    }

    var
        BookCode: Code[10];
}

page 73343 "LT TSF Const Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode)
            {
                ApplicationArea = All;
                Caption = 'Shared Book Code';
                TableRelation = "LT TSV Book" where(Name = const('Shared'));
            }
        }
    }

    var
        BookCode: Text[10];
}

page 73344 "LT TSF Key Host Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT TSF Key Host";

    layout
    {
        area(Content)
        {
            field(BookCtl; Rec."Key Book Code") { ApplicationArea = All; }
        }
    }
}

report 73340 "LT TSF Request"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Int; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(CodeCtl; CodeVar) { ApplicationArea = All; Caption = 'Code Book'; TableRelation = "LT TSV Book"; }
                field(FilteredCtl; FilteredVar) { ApplicationArea = All; Caption = 'Active Book'; TableRelation = "LT TSV Book" where(Active = const(true)); }
                field(NameCtl; NameVar) { ApplicationArea = All; Caption = 'Book Name'; TableRelation = "LT TSV Book".Name; }
                field(KeyFieldCtl; KeyFieldVar) { ApplicationArea = All; Caption = 'Key Book'; TableRelation = "LT TSV Book"."Code"; }
                field(CapCtl; CapVar) { ApplicationArea = All; Caption = 'Captioned Book Code'; TableRelation = "LT TSV Cap Book"; }
            }
        }
    }

    var
        CodeVar: Code[10];
        FilteredVar: Text[10];
        NameVar: Text[30];
        KeyFieldVar: Text[10];
        CapVar: Text[10];
}

codeunit 73340 "LT TSF SetValue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        RequestControl: Text;
        RequestTyped: Text;
        RequestReading: Text;

    local procedure Seed(WithXyza: Boolean)
    var
        Book: Record "LT TSV Book";
        Host: Record "LT TSV Host";
        CapBook: Record "LT TSV Cap Book";
        KeyHost: Record "LT TSF Key Host";
    begin
        Book.DeleteAll();
        Host.DeleteAll();
        CapBook.DeleteAll();
        KeyHost.DeleteAll();
        AddBook('ABC', 'Shared', true);
        AddBook('ABD', 'Shared', true);
        AddBook('MNO', 'Unique Name', true);
        AddBook('XYZ', 'Hidden', false);
        if WithXyza then
            AddBook('XYZA', 'Extra', true);
        Host.Init();
        Host.Id := 1;
        Host.Insert();
        CapBook.Init();
        CapBook."Code" := 'CB1';
        CapBook.Insert();
        KeyHost.Init();
        KeyHost.Id := 1;
        KeyHost.Insert();
    end;

    local procedure AddBook(C: Code[10]; N: Text[30]; A: Boolean)
    var
        Book: Record "LT TSV Book";
    begin
        Book.Init();
        Book."Code" := C;
        Book.Name := N;
        Book.Active := A;
        Book.Insert();
    end;

    local procedure Outcome(Ok: Boolean): Text
    var
        T: Text;
    begin
        if Ok then
            exit('ok');
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    [TryFunction]
    local procedure TrySetCodeCap(var TP: TestPage "LT TSF Code Cap Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetCodeHeld(var TP: TestPage "LT TSF Code Held Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetCodeKeyField(var TP: TestPage "LT TSF Code KeyField Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetConst(var TP: TestPage "LT TSF Const Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetFiltered(var TP: TestPage "LT TSV Filtered Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetHost(var TP: TestPage "LT TSV Host Card"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetKeyHost(var TP: TestPage "LT TSF Key Host Card"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetRequest(var RP: TestRequestPage "LT TSF Request"; Control: Text; Typed: Text)
    begin
        case Control of
            'Code':
                RP.CodeCtl.SetValue(Typed);
            'Filtered':
                RP.FilteredCtl.SetValue(Typed);
            'Name':
                RP.NameCtl.SetValue(Typed);
            'KeyField':
                RP.KeyFieldCtl.SetValue(Typed);
            'Cap':
                RP.CapCtl.SetValue(Typed);
        end;
    end;

    local procedure RequestValue(var RP: TestRequestPage "LT TSF Request"; Control: Text): Text
    begin
        case Control of
            'Code':
                exit(RP.CodeCtl.Value());
            'Filtered':
                exit(RP.FilteredCtl.Value());
            'Name':
                exit(RP.NameCtl.Value());
            'KeyField':
                exit(RP.KeyFieldCtl.Value());
            'Cap':
                exit(RP.CapCtl.Value());
        end;
    end;

    [RequestPageHandler]
    procedure RequestHandler(var RP: TestRequestPage "LT TSF Request")
    var
        SetText: Text;
    begin
        ClearLastError();
        SetText := Outcome(TrySetRequest(RP, RequestControl, RequestTyped));
        RequestReading := StrSubstNo('set=%1 value=%2', SetText, RequestValue(RP, RequestControl));
        RP.Cancel().Invoke();
    end;

    local procedure RequestCell(var Observer: Codeunit "Probe Observer"; Control: Text; Typed: Text)
    begin
        Seed(false);
        RequestControl := Control;
        RequestTyped := Typed;
        RequestReading := '';
        Commit();
        Report.RunModal(Report::"LT TSF Request", true);
        Observer.Observe('request', RequestReading);
    end;

    // A Code[10] variable on a request page.
    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestCode_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Code', 'abc');
        Observer.Expect('request', 'set=ok value=ABC');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestCode_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Code', 'mn');
        Observer.Expect('request', 'set=ok value=MNO');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestCode_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Code', 'zzz');
        Observer.Expect('request', 'set=E: Validation error for Field: CodeCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation value=');
        Observer.Verify();
    end;

    // A request-page Text[10] variable with a where() filter: an exact key outside it, a prefix of it, a lower-case prefix inside.
    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestFiltered_OutsideExact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Filtered', 'XYZ');
        Observer.Expect('request', 'set=ok value=XYZ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestFiltered_OutsidePrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Filtered', 'XY');
        Observer.Expect('request', 'set=E: Validation error for Field: FilteredCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''XY'''' | TestValidation value=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestFiltered_LowerPrefixInside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Filtered', 'mn');
        Observer.Expect('request', 'set=ok value=MNO');
        Observer.Verify();
    end;

    // A request-page Text[30] variable related to the non-key field Name.
    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestName_Exact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Name', 'Unique Name');
        Observer.Expect('request', 'set=E: Validation error for Field: NameCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation value=');
        Observer.Verify();
    end;

    // A request-page Text[10] variable related by "LT TSV Book"."Code".
    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestKeyField_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'KeyField', 'mn');
        Observer.Expect('request', 'set=ok value=MNO');
        Observer.Verify();
    end;

    // A request-page Text[10] variable related to the captioned table: no row.
    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure RequestCap_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RequestCell(Observer, 'Cap', 'zzz');
        Observer.Expect('request', 'set=E: Validation error for Field: CapCtl,  Message = ''The Captioned Book does not exist. Identification fields and values: Book No.=''ZZZ'''' | TestValidation value=');
        Observer.Verify();
    end;

    // A Code[10] variable related to the captioned table: other case, and no row.
    [Test]
    procedure CodeCap_LowerCase()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSF Code Cap Var";
    begin
        Seed(false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeCap(TP, 'cb1')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'CB1');
        Observer.Verify();
    end;

    [Test]
    procedure CodeCap_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSF Code Cap Var";
    begin
        Seed(false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeCap(TP, 'zzz')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The Captioned Book does not exist. Identification fields and values: Book No.=''ZZZ'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    // A Code[10] variable that holds ABC (set in OnOpenPage): a lower-case prefix, and no row.
    [Test]
    procedure CodeHeld_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSF Code Held Var";
    begin
        Seed(false);
        TP.OpenEdit();
        Observer.Observe('before', TP.BookCtl.Value());
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeHeld(TP, 'mn')));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
        Observer.Expect('before', 'ABC');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CodeHeld_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSF Code Held Var";
    begin
        Seed(false);
        TP.OpenEdit();
        Observer.Observe('before', TP.BookCtl.Value());
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeHeld(TP, 'zzz')));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
        Observer.Expect('before', 'ABC');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '0');
        Observer.Verify();
    end;

    // A Code[10] variable related by "LT TSV Book"."Code": a lower-case prefix, and no row.
    [Test]
    procedure CodeKeyField_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSF Code KeyField Var";
    begin
        Seed(false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeKeyField(TP, 'mn')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Verify();
    end;

    [Test]
    procedure CodeKeyField_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSF Code KeyField Var";
    begin
        Seed(false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeKeyField(TP, 'zzz')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''ZZZ'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    // A Text[10] variable related with a const where() on the Text field Name (Shared): inside, an exact key outside, a prefix
    // outside, a lower-case prefix inside.
    local procedure ConstCell(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        TP: TestPage "LT TSF Const Var";
    begin
        Seed(false);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetConst(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
    end;

    [Test]
    procedure Const_Inside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ConstCell(Observer, 'ABC');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure Const_OutsideExact()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ConstCell(Observer, 'MNO');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Verify();
    end;

    [Test]
    procedure Const_OutsidePrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ConstCell(Observer, 'MN');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''MN'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    [Test]
    procedure Const_LowerPrefixInside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ConstCell(Observer, 'ab');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Verify();
    end;

    // The host table field "Book Code" (related to the key): a lower-case prefix; holding ABC, then a lower-case prefix or no row;
    // and on an OpenNew row.
    local procedure HostCell(var Observer: Codeunit "Probe Observer"; Held: Code[10]; Typed: Text)
    var
        Host: Record "LT TSV Host";
        TP: TestPage "LT TSV Host Card";
    begin
        Seed(false);
        Host.Get(1);
        Host."Book Code" := Held;
        Host.Modify();
        TP.OpenEdit();
        TP.GoToRecord(Host);
        Observer.Observe('before', TP.BookCtl.Value());
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetHost(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
        Host.Get(1);
        Observer.Observe('stored', StrSubstNo('Book Code=%1 validated=%2', Host."Book Code", Host.ValidateCount));
    end;

    [Test]
    procedure HostField_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostCell(Observer, '', 'mn');
        Observer.Expect('before', '');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Expect('stored', 'Book Code=MNO validated=1');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_HeldLowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostCell(Observer, 'ABC', 'mn');
        Observer.Expect('before', 'ABC');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Expect('stored', 'Book Code=MNO validated=1');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_HeldNoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostCell(Observer, 'ABC', 'zzz');
        Observer.Expect('before', 'ABC');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The field Book Code of table LT TSV Host contains a value (ZZZ) that cannot be found in the related table (LT TSV Book). (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', 'ABC');
        Observer.Expect('validated', '0');
        Observer.Expect('stored', 'Book Code=ABC validated=0');
        Observer.Verify();
    end;

    [Test]
    procedure HostField_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        Host: Record "LT TSV Host";
        TP: TestPage "LT TSV Host Card";
    begin
        Seed(false);
        Host.DeleteAll();
        TP.OpenNew();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetHost(TP, 'abc')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        if Host.FindFirst() then
            Observer.Observe('stored', StrSubstNo('Id=%1 Book Code=%2 validated=%3', Host.Id, Host."Book Code", Host.ValidateCount))
        else
            Observer.Observe('stored', 'no row');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'ABC');
        Observer.Expect('stored', 'Id=0 Book Code=ABC validated=1');
        Observer.Verify();
    end;

    // A table field related by "LT TSV Book"."Code": a lower-case prefix, and no row.
    local procedure KeyHostCell(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        KeyHost: Record "LT TSF Key Host";
        TP: TestPage "LT TSF Key Host Card";
    begin
        Seed(false);
        KeyHost.Get(1);
        TP.OpenEdit();
        TP.GoToRecord(KeyHost);
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetKeyHost(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        KeyHost.Get(1);
        Observer.Observe('stored', KeyHost."Key Book Code");
    end;

    [Test]
    procedure KeyHost_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyHostCell(Observer, 'mn');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('stored', 'MNO');
        Observer.Verify();
    end;

    [Test]
    procedure KeyHost_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyHostCell(Observer, 'zzz');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The field Key Book Code of table LT TSF Key Host contains a value (ZZZ) that cannot be found in the related table (LT TSV Book). (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    // The filtered Text[10] variable of page 73392 (Active = true): a lower-case prefix inside the filter, and 'XYZ' when both a
    // key XYZA inside the filter (a prefix match) and the key XYZ outside it (an exact match) are stored.
    local procedure FilteredCell(var Observer: Codeunit "Probe Observer"; Typed: Text; WithXyza: Boolean)
    var
        TP: TestPage "LT TSV Filtered Var";
    begin
        Seed(WithXyza);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetFiltered(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        Observer.Observe('validated', TP.ValidatedCtl.Value());
        TP.Close();
    end;

    [Test]
    procedure Filtered_LowerPrefixInside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredCell(Observer, 'mn', false);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_PrefixInsideAndExactOutside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredCell(Observer, 'XYZ', true);
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'XYZA');
        Observer.Expect('validated', '1');
        Observer.Verify();
    end;
}
