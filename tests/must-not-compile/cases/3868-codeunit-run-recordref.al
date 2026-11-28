// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// Codeunit.Run with a RecordRef as the record. (al-runner issue 9280)
// Measured with AL 16.2.28.57946 (runtime 16.0), AL 17.0.34.45391 (runtime 17.0) and AL 18.0.43.1464 (runtime 18.0): AL0133 on each. The case starts at BC 28, as 1634 does: on the BC 27 leg (runtime 16.1, which only AL 17 and newer compile) AL 17.0.34.45391 and AL 18.0.43.1464 give AL0666 for the overload by name of runtime 17.0 instead.
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
