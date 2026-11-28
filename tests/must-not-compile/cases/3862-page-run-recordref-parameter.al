// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// Page.Run, Page.RunModal and Report.Run with a RecordRef parameter as the record (case 1634 is a local variable). (al-runner issue 9280)
// Measured with AL 16.2.28.57946 (runtime 16.0), AL 17.0.34.45391 (runtime 17.0) and AL 18.0.43.1464 (runtime 18.0): AL0133 on each. The case starts at BC 28, as 1634 does: on the BC 27 leg (runtime 16.1, which only AL 17 and newer compile) AL 17.0.34.45391 and AL 18.0.43.1464 give AL0666 for these calls, as 1633 does.
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
