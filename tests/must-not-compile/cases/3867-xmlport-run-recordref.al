// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 29
// Xmlport.Run with a RecordRef as the record. (al-runner issue 9280)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53867 "MNC RR Row 53867"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53867 "MNC RR List 53867"
{
    PageType = List;
    SourceTable = "MNC RR Row 53867";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53867 "MNC RR Report 53867"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53867") { } }
}
xmlport 53867 "MNC RR Port 53867"
{
    schema { textelement(Root) { tableelement(Row; "MNC RR Row 53867") { fieldelement(Id; Row.Id) { } } } }
}
codeunit 53867 "MNC RR Run 53867"
{
    procedure Probe()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"MNC RR Row 53867");
        Xmlport.Run(Xmlport::"MNC RR Port 53867", false, false, RecRef);
    end;
}
