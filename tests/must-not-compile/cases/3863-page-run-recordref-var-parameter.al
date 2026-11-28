// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 29
// Page.Run, Page.RunModal and Report.Run with a var RecordRef parameter as the record. (al-runner issue 9280)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
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
