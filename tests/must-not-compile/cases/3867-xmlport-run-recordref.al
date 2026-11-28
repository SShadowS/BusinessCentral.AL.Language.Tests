// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// Xmlport.Run with a RecordRef as the record. (al-runner issue 9280)
// Measured with AL 16.2.28.57946 (runtime 16.0), AL 17.0.34.45391 (runtime 17.0) and AL 18.0.43.1464 (runtime 18.0): AL0133 on each. Xmlport.Run has no overload by name, so the BC 27 leg (runtime 16.1, which only AL 17 and newer compile) gives the same AL0133 with AL 17.0.34.45391 and AL 18.0.43.1464 on the BC 27 symbols; the case holds for every major.
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
