// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// Page.Run, Page.RunModal and Report.Run with a var RecordRef parameter as the record. (al-runner issue 9280)
// Measured with AL 16.2.28.57946 (runtime 16.0), AL 17.0.34.45391 (runtime 17.0) and AL 18.0.43.1464 (runtime 18.0): AL0133 on each. BC 27 runs its apps at runtime 16.1, which AL 16.2 does not compile (AL1043), so the case starts at BC 28 as 1634 does.
table 53863 "MNC RR Row 53863"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53863 "MNC RR List 53863"
{
    PageType = List;
    SourceTable = "MNC RR Row 53863";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53863 "MNC RR Report 53863"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53863") { } }
}
xmlport 53863 "MNC RR Port 53863"
{
    schema { textelement(Root) { tableelement(Row; "MNC RR Row 53863") { fieldelement(Id; Row.Id) { } } } }
}
codeunit 53863 "MNC RR Run 53863"
{
    procedure Probe(var RecRef: RecordRef)
    begin
        Page.Run(Page::"MNC RR List 53863", RecRef);
        Page.RunModal(Page::"MNC RR List 53863", RecRef);
        Report.Run(Report::"MNC RR Report 53863", false, false, RecRef);
    end;
}
