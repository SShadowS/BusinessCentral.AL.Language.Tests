// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @from 29
// Page.Run(Page, RecRef, FieldNo) with a RecordRef as the record. (al-runner issue 9280)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53865 "MNC RR Row 53865"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53865 "MNC RR List 53865"
{
    PageType = List;
    SourceTable = "MNC RR Row 53865";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53865 "MNC RR Report 53865"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53865") { } }
}
xmlport 53865 "MNC RR Port 53865"
{
    schema { textelement(Root) { tableelement(Row; "MNC RR Row 53865") { fieldelement(Id; Row.Id) { } } } }
}
codeunit 53865 "MNC RR Run 53865"
{
    procedure Probe()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"MNC RR Row 53865");
        Page.Run(Page::"MNC RR List 53865", RecRef, 1);
    end;
}
