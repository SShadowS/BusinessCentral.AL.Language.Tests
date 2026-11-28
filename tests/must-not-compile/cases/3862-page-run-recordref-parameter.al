// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 29
// Page.Run, Page.RunModal and Report.Run with a RecordRef parameter as the record (case 1634 is a local variable). (al-runner issue 9280)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53862 "MNC RR Row 53862"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53862 "MNC RR List 53862"
{
    PageType = List;
    SourceTable = "MNC RR Row 53862";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53862 "MNC RR Report 53862"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53862") { } }
}
xmlport 53862 "MNC RR Port 53862"
{
    schema { textelement(Root) { tableelement(Row; "MNC RR Row 53862") { fieldelement(Id; Row.Id) { } } } }
}
codeunit 53862 "MNC RR Run 53862"
{
    procedure Probe(RecRef: RecordRef)
    begin
        Page.Run(Page::"MNC RR List 53862", RecRef);
        Page.RunModal(Page::"MNC RR List 53862", RecRef);
        Report.Run(Report::"MNC RR Report 53862", false, false, RecRef);
    end;
}
