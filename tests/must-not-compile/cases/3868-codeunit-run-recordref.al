// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'var Table'
// @from 29
// Codeunit.Run with a RecordRef as the record. (al-runner issue 9280)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53868 "MNC RR Row 53868"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53868 "MNC RR List 53868"
{
    PageType = List;
    SourceTable = "MNC RR Row 53868";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53868 "MNC RR Report 53868"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53868") { } }
}
xmlport 53868 "MNC RR Port 53868"
{
    schema { textelement(Root) { tableelement(Row; "MNC RR Row 53868") { fieldelement(Id; Row.Id) { } } } }
}
codeunit 53868 "MNC RR Run 53868"
{
    procedure Probe()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"MNC RR Row 53868");
        Codeunit.Run(Codeunit::"MNC RR Run 53868", RecRef);
    end;
}
