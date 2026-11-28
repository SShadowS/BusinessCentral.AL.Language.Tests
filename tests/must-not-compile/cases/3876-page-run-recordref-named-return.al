// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// Page.Run, Page.RunModal and Report.Run with the named RecordRef return value of the procedure as the record. (al-runner issue 9280)
// Measured with AL 16.2.28.57946 (runtime 16.0), AL 17.0.34.45391 (runtime 17.0) and AL 18.0.43.1464 (runtime 18.0): AL0133 on each. The case starts at BC 28, as 1634 does: on the BC 27 leg (runtime 16.1, which only AL 17 and newer compile) AL 17.0.34.45391 and AL 18.0.43.1464 give AL0666 for these calls, as 1633 does.
table 53876 "MNC RR Row 53876"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53876 "MNC RR List 53876"
{
    PageType = List;
    SourceTable = "MNC RR Row 53876";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53876 "MNC RR Report 53876"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53876") { } }
}
codeunit 53876 "MNC RR Run 53876"
{
    procedure Probe() RR: RecordRef
    begin
        RR.Open(Database::"MNC RR Row 53876");
        Page.Run(Page::"MNC RR List 53876", RR);
        Page.RunModal(Page::"MNC RR List 53876", RR);
        Report.Run(Report::"MNC RR Report 53876", false, false, RR);
    end;
}
