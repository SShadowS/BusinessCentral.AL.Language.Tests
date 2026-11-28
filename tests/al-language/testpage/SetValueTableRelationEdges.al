// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 73390 ("LT TSV Book") and 73396 ("LT TSV Cap Book") and pages 73390 ("LT TSV Text
//   Var") and 73392 ("LT TSV Filtered Var") of SetValueTableRelation.al; own tables 73220..73224, pages 73220..73226, test
//   codeunit 73220
// local object: the control's TableRelation (and the related table's captions, key type and length) is the property under test.
// Probe (follow-up of corpus pull requests 1646 and 1665; the shapes AL Runner issue 9446 still lists, from the review of corpus
//   pull request 1665): TestPage <control>.SetValue on a control with a TableRelation, for:
//   - a Code[30] variable related to the non-key field Name ('Unique Name', 'zzz', '');
//   - a Text[10] variable related to a table whose caption and key caption come from CaptionML;
//   - a Code[10] variable related to a table whose Code key has SQLDataType = Integer (rows 5, 12, 123, and 100 in one test);
//   - a table field with an if relation (Kind 1: the Book table, else the captioned table; Kind 2 typed 'cb1', 'cb', 'mn');
//   - a non-English session (GlobalLanguage 1043, set back to 1033 at the end of the test), on the plain and the CaptionML table;
//   - a typed text longer than the key: 11 characters into the Text[10] variable, and into a Text[30] variable related to the
//     same Code[10] key ('ABCDEFGHIJK', 'MNOPQRSTUVW');
//   - SetValue(5), an Integer, with no row 5, with a row 5, and with only a row 50;
//   - an exact key inside the filter while a longer key that starts with it is outside (XY Active, XYA not Active);
//   - a completed key longer than the control (a Code[3] variable and a Code[3] table field typed 'AB', the row ABCDE);
//   - leading and trailing spaces (' mn', 'mn ');
//   - 'xyz' in lower case with XYZA inside the filter and XYZ outside it.
//   Each cell opens the page with OpenEdit, calls SetValue inside a TryFunction and records: set = "ok" or "E: <GetLastErrorText> |
//   <GetLastErrorCode>"; value = the control's Value() afterwards; stored = the record after Close for table fields.
//   Measured on a local BC 29.0.54011.57673 (Linux, W1, en-US session); on BC 27.5 this pull request's CI observe run 46169003904
//   gave the same readings, both 27.5 legs alike (the 1043 session texts included), so they hold on every version with no
//   version guard. The review cells (SqlDataType_Prefix100, LongTextVar_*, IfRelation_Kind2Prefix, CodeName_NoRow,
//   CodeName_Blank, TextVar_IntegerPrefixRow): observe round, every one ends with Observer.Finish(); nothing is asserted yet.
// BC versions: 27, 28, 29 by CI
table 73220 "LT TSG ML Book"
{
    CaptionML = ENU = 'Multi Book', NLD = 'Meervoudig Boek';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { CaptionML = ENU = 'Multi No.', NLD = 'Meervoudig Nr.'; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 73221 "LT TSG Sql Book"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { SQLDataType = Integer; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 73222 "LT TSG Long Book"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 73223 "LT TSG If Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Integer) { }
        field(3; "Book Code"; Code[10])
        {
            TableRelation = if (Kind = const(1)) "LT TSV Book" else "LT TSV Cap Book";
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 73224 "LT TSG Short Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Short Code"; Code[3]) { TableRelation = "LT TSG Long Book"; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73220 "LT TSG Code Name Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookName) { ApplicationArea = All; Caption = 'Book Name'; TableRelation = "LT TSV Book".Name; }
        }
    }

    var
        BookName: Code[30];
}

page 73221 "LT TSG ML Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Multi Book Code'; TableRelation = "LT TSG ML Book"; }
        }
    }

    var
        BookCode: Text[10];
}

page 73222 "LT TSG Sql Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Integer Book Code'; TableRelation = "LT TSG Sql Book"; }
        }
    }

    var
        BookCode: Code[10];
}

page 73223 "LT TSG If Host Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT TSG If Host";

    layout
    {
        area(Content)
        {
            field(BookCtl; Rec."Book Code") { ApplicationArea = All; }
        }
    }
}

page 73224 "LT TSG Short Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Short Book Code'; TableRelation = "LT TSG Long Book"; }
        }
    }

    var
        BookCode: Code[3];
}

page 73225 "LT TSG Short Host Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT TSG Short Host";

    layout
    {
        area(Content)
        {
            field(BookCtl; Rec."Short Code") { ApplicationArea = All; }
        }
    }
}

page 73226 "LT TSG Long Text Var"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BookCtl; BookCode) { ApplicationArea = All; Caption = 'Long Book Code'; TableRelation = "LT TSV Book"; }
        }
    }

    var
        BookCode: Text[30];
}

codeunit 73220 "LT TSG SetValue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The Book rows of SetValueTableRelation.al (ABC, ABD, MNO, XYZ) plus the Extra rows; CB1 in the captioned table; ML1 in the
    // CaptionML table; 5, 12 and 123 in the SQLDataType table (and 100 for the Extra 'SQL100'); ABCDE in the long-key table; the
    // Short Host row 1 (IfHostCell inserts the If Host row). The session language is set back to 1033 first, so a 1043 test that
    // raises cannot leave it in Dutch.
    local procedure Seed(Extra: Text)
    var
        Book: Record "LT TSV Book";
        CapBook: Record "LT TSV Cap Book";
        MlBook: Record "LT TSG ML Book";
        SqlBook: Record "LT TSG Sql Book";
        LongBook: Record "LT TSG Long Book";
        IfHost: Record "LT TSG If Host";
        ShortHost: Record "LT TSG Short Host";
    begin
        GlobalLanguage(1033);
        Book.DeleteAll();
        CapBook.DeleteAll();
        MlBook.DeleteAll();
        SqlBook.DeleteAll();
        LongBook.DeleteAll();
        IfHost.DeleteAll();
        ShortHost.DeleteAll();
        AddBook('ABC', 'Shared', true);
        AddBook('ABD', 'Shared', true);
        AddBook('MNO', 'Unique Name', true);
        AddBook('XYZ', 'Hidden', false);
        case Extra of
            'XYZA':
                AddBook('XYZA', 'Extra', true);
            'XY':
                begin
                    AddBook('XY', 'Extra', true);
                    AddBook('XYA', 'Extra', false);
                end;
            '5':
                AddBook('5', 'Five', true);
            '50':
                AddBook('50', 'Fifty', true);
            'SQL100':
                AddSql('100');
        end;
        CapBook.Init();
        CapBook."Code" := 'CB1';
        CapBook.Insert();
        MlBook.Init();
        MlBook."Code" := 'ML1';
        MlBook.Insert();
        AddSql('5');
        AddSql('12');
        AddSql('123');
        LongBook.Init();
        LongBook."Code" := 'ABCDE';
        LongBook.Insert();
        ShortHost.Init();
        ShortHost.Id := 1;
        ShortHost.Insert();
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

    local procedure AddSql(C: Code[10])
    var
        SqlBook: Record "LT TSG Sql Book";
    begin
        SqlBook.Init();
        SqlBook."Code" := C;
        SqlBook.Insert();
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
    local procedure TrySetCodeName(var TP: TestPage "LT TSG Code Name Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetMl(var TP: TestPage "LT TSG ML Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetSql(var TP: TestPage "LT TSG Sql Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetIfHost(var TP: TestPage "LT TSG If Host Card"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetShort(var TP: TestPage "LT TSG Short Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetShortHost(var TP: TestPage "LT TSG Short Host Card"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetLongText(var TP: TestPage "LT TSG Long Text Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetText(var TP: TestPage "LT TSV Text Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetTextInteger(var TP: TestPage "LT TSV Text Var"; Typed: Integer)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    [TryFunction]
    local procedure TrySetFiltered(var TP: TestPage "LT TSV Filtered Var"; Typed: Text)
    begin
        TP.BookCtl.SetValue(Typed);
    end;

    local procedure TextCell(var Observer: Codeunit "Probe Observer"; Typed: Text; Extra: Text)
    var
        TP: TestPage "LT TSV Text Var";
    begin
        Seed(Extra);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetText(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
    end;

    local procedure FilteredCell(var Observer: Codeunit "Probe Observer"; Typed: Text; Extra: Text)
    var
        TP: TestPage "LT TSV Filtered Var";
    begin
        Seed(Extra);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetFiltered(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
    end;

    // A Code[30] variable related to the non-key field Name.
    [Test]
    procedure CodeName_Exact()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSG Code Name Var";
    begin
        Seed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeName(TP, 'Unique Name')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The following field must be included into the table''s primary key: Field: Name Table: LT TSV Book'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    // A Text[10] variable related to the CaptionML table: other case, and no row.
    [Test]
    procedure CaptionML_LowerCaseAndNoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSG ML Var";
    begin
        Seed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set_ml1', Outcome(TrySetMl(TP, 'ml1')));
        Observer.Observe('value_ml1', TP.BookCtl.Value());
        Observer.Observe('set_zzz', Outcome(TrySetMl(TP, 'zzz')));
        Observer.Observe('value_zzz', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set_ml1', 'ok');
        Observer.Expect('value_ml1', 'ML1');
        Observer.Expect('set_zzz', 'E: Validation error for Field: BookCtl,  Message = ''The Multi Book does not exist. Identification fields and values: Multi No.=''ZZZ'''' | TestValidation');
        Observer.Expect('value_zzz', 'ML1');
        Observer.Verify();
    end;

    // A Code[10] variable related to the SQLDataType = Integer table: an exact key, a prefix ('1': 12 and 123), and no row.
    [Test]
    procedure SqlDataType_Cells()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSG Sql Var";
    begin
        Seed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set_5', Outcome(TrySetSql(TP, '5')));
        Observer.Observe('value_5', TP.BookCtl.Value());
        Observer.Observe('set_1', Outcome(TrySetSql(TP, '1')));
        Observer.Observe('value_1', TP.BookCtl.Value());
        Observer.Observe('set_99', Outcome(TrySetSql(TP, '99')));
        Observer.Observe('value_99', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set_5', 'ok');
        Observer.Expect('value_5', '5');
        Observer.Expect('set_1', 'ok');
        Observer.Expect('value_1', '12');
        Observer.Expect('set_99', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSG Sql Book does not exist. Identification fields and values: Code=''99'''' | TestValidation');
        Observer.Expect('value_99', '12');
        Observer.Verify();
    end;

    // A table field with an if relation: Kind 1 (the Book table) typed 'mn', Kind 2 (the captioned table) typed 'cb1' and 'mn'.
    local procedure IfHostCell(var Observer: Codeunit "Probe Observer"; Kind: Integer; Typed: Text)
    var
        IfHost: Record "LT TSG If Host";
        TP: TestPage "LT TSG If Host Card";
    begin
        Seed('');
        IfHost.Init();
        IfHost.Id := 1;
        IfHost.Kind := Kind;
        IfHost.Insert();
        TP.OpenEdit();
        TP.GoToRecord(IfHost);
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetIfHost(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        IfHost.Get(1);
        Observer.Observe('stored', IfHost."Book Code");
    end;

    [Test]
    procedure IfRelation_Kind1Prefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IfHostCell(Observer, 1, 'mn');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'MNO');
        Observer.Expect('stored', 'MNO');
        Observer.Verify();
    end;

    [Test]
    procedure IfRelation_Kind2LowerCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IfHostCell(Observer, 2, 'cb1');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'CB1');
        Observer.Expect('stored', 'CB1');
        Observer.Verify();
    end;

    [Test]
    procedure IfRelation_Kind2OtherTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IfHostCell(Observer, 2, 'mn');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The field Book Code of table LT TSG If Host contains a value (MN) that cannot be found in the related table (Captioned Book). (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    // A non-English session: GlobalLanguage 1043, then 'mn' and 'zzz' on the Text[10] page; GlobalLanguage set back to 1033.
    [Test]
    procedure Session1043_PrefixAndNoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV Text Var";
    begin
        Seed('');
        GlobalLanguage(1043);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set_mn', Outcome(TrySetText(TP, 'mn')));
        Observer.Observe('value_mn', TP.BookCtl.Value());
        Observer.Observe('set_zzz', Outcome(TrySetText(TP, 'zzz')));
        Observer.Observe('value_zzz', TP.BookCtl.Value());
        TP.Close();
        GlobalLanguage(1033);
        Observer.Expect('set_mn', 'ok');
        Observer.Expect('value_mn', 'MNO');
        Observer.Expect('set_zzz', 'E: Validatiefout voor veld: BookCtl, bericht = ''LT TSV Book bestaat niet. Identificatievelden en -waarden: Code=''ZZZ'''' | TestValidation');
        Observer.Expect('value_zzz', 'MNO');
        Observer.Verify();
    end;

    // The CaptionML table in the 1043 session: a row in other case, and no row.
    [Test]
    procedure Session1043_CaptionMLNoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSG ML Var";
    begin
        Seed('');
        GlobalLanguage(1043);
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set_ml1', Outcome(TrySetMl(TP, 'ml1')));
        Observer.Observe('value_ml1', TP.BookCtl.Value());
        Observer.Observe('set_zzz', Outcome(TrySetMl(TP, 'zzz')));
        Observer.Observe('value_zzz', TP.BookCtl.Value());
        TP.Close();
        GlobalLanguage(1033);
        Observer.Expect('set_ml1', 'ok');
        Observer.Expect('value_ml1', 'ML1');
        Observer.Expect('set_zzz', 'E: Validatiefout voor veld: BookCtl, bericht = ''Meervoudig Boek bestaat niet. Identificatievelden en -waarden: Meervoudig Nr.=''ZZZ'''' | TestValidation');
        Observer.Expect('value_zzz', 'ML1');
        Observer.Verify();
    end;

    // A typed text longer than the key: 11 characters into the Text[10] control related to a Code[10] key.
    [Test]
    procedure TextVar_LongerThanKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextCell(Observer, 'ABCDEFGHIJK', '');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The length of the string is 11, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJK'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    // SetValue(5), an Integer, on the Text[10] page: without and with a row '5'.
    [Test]
    procedure TextVar_IntegerNoRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV Text Var";
    begin
        Seed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetTextInteger(TP, 5)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''5'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    [Test]
    procedure TextVar_IntegerRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV Text Var";
    begin
        Seed('5');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetTextInteger(TP, 5)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'ok');
        Observer.Expect('value', '5');
        Observer.Verify();
    end;

    // The filtered variable: 'XY' with XY (Active, exact inside) and XYA (not Active, a longer key outside).
    [Test]
    procedure Filtered_ExactInsideLongerOutside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredCell(Observer, 'XY', 'XY');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'XY');
        Observer.Verify();
    end;

    // The filtered variable: 'xyz' with XYZA (Active) and XYZ (not Active).
    [Test]
    procedure Filtered_LowerPrefixInsideAndExactOutside()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilteredCell(Observer, 'xyz', 'XYZA');
        Observer.Expect('set', 'ok');
        Observer.Expect('value', 'XYZA');
        Observer.Verify();
    end;

    // A completed key longer than the control: a Code[3] variable and a Code[3] table field typed 'AB', the only row ABCDE.
    [Test]
    procedure ShortVar_CompletedLonger()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSG Short Var";
    begin
        Seed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetShort(TP, 'AB')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The length of the string is 5, but it must be less than or equal to 3 characters. Value: ABCDE'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    [Test]
    procedure ShortHost_CompletedLonger()
    var
        Observer: Codeunit "Probe Observer";
        ShortHost: Record "LT TSG Short Host";
        TP: TestPage "LT TSG Short Host Card";
    begin
        Seed('');
        ShortHost.Get(1);
        TP.OpenEdit();
        TP.GoToRecord(ShortHost);
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetShortHost(TP, 'AB')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        ShortHost.Get(1);
        Observer.Observe('stored', ShortHost."Short Code");
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The length of the string is 5, but it must be less than or equal to 3 characters. Value: ABCDE (Select Refresh to discard errors)'' | TestValidation');
        Observer.Expect('value', '');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    // Leading and trailing spaces: ' mn' and 'mn ' on the Text[10] page.
    [Test]
    procedure TextVar_LeadingSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextCell(Observer, ' mn', '');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''MN'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    [Test]
    procedure TextVar_TrailingSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TextCell(Observer, 'mn ', '');
        Observer.Expect('set', 'E: Validation error for Field: BookCtl,  Message = ''The LT TSV Book does not exist. Identification fields and values: Code=''MN'''' | TestValidation');
        Observer.Expect('value', '');
        Observer.Verify();
    end;

    // Review cells of corpus pull request 1668.
    // SQLDataType = Integer with the rows 5, 12, 100 and 123, typed '1': integer order gives 12, text order 100.
    [Test]
    procedure SqlDataType_Prefix100()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSG Sql Var";
    begin
        Seed('SQL100');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetSql(TP, '1')));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Finish();
    end;

    // A Text[30] variable related to the Code[10] key, typed 11 characters: no row, and a text that a row (MNO) starts.
    local procedure LongTextCell(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        TP: TestPage "LT TSG Long Text Var";
    begin
        Seed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetLongText(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
    end;

    [Test]
    procedure LongTextVar_NoRow11()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LongTextCell(Observer, 'ABCDEFGHIJK');
        Observer.Finish();
    end;

    [Test]
    procedure LongTextVar_RowPrefix11()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LongTextCell(Observer, 'MNOPQRSTUVW');
        Observer.Finish();
    end;

    // The if relation's else branch typed as a prefix: Kind 2, 'cb' (the row CB1).
    [Test]
    procedure IfRelation_Kind2Prefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IfHostCell(Observer, 2, 'cb');
        Observer.Finish();
    end;

    // The Code[30] variable related to Name: no row, and blank.
    local procedure CodeNameCell(var Observer: Codeunit "Probe Observer"; Typed: Text)
    var
        TP: TestPage "LT TSG Code Name Var";
    begin
        Seed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetCodeName(TP, Typed)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
    end;

    [Test]
    procedure CodeName_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeNameCell(Observer, 'zzz');
        Observer.Finish();
    end;

    [Test]
    procedure CodeName_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeNameCell(Observer, '');
        Observer.Finish();
    end;

    // SetValue(5) with only a row 50.
    [Test]
    procedure TextVar_IntegerPrefixRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT TSV Text Var";
    begin
        Seed('50');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('set', Outcome(TrySetTextInteger(TP, 5)));
        Observer.Observe('value', TP.BookCtl.Value());
        TP.Close();
        Observer.Finish();
    end;
}
