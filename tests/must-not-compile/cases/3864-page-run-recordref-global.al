// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// Page.Run, Page.RunModal and Report.Run with a global RecordRef as the record. (al-runner issue 9280)
// Measured with AL 16.2.28.57946 (runtime 16.0), AL 17.0.34.45391 (runtime 17.0) and AL 18.0.43.1464 (runtime 18.0): AL0133 on each. BC 27 runs its apps at runtime 16.1, which AL 16.2 does not compile (AL1043), so the case starts at BC 28 as 1634 does.
table 53864 "MNC RR Row 53864"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53864 "MNC RR List 53864"
{
    PageType = List;
    SourceTable = "MNC RR Row 53864";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53864 "MNC RR Report 53864"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53864") { } }
}
xmlport 53864 "MNC RR Port 53864"
{
    schema { textelement(Root) { tableelement(Row; "MNC RR Row 53864") { fieldelement(Id; Row.Id) { } } } }
}
codeunit 53864 "MNC RR Run 53864"
{
    var
        RecRef: RecordRef;

    procedure Probe()
    begin
        RecRef.Open(Database::"MNC RR Row 53864");
        Page.Run(Page::"MNC RR List 53864", RecRef);
        Page.RunModal(Page::"MNC RR List 53864", RecRef);
        Report.Run(Report::"MNC RR Report 53864", false, false, RecRef);
    end;
}
