// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// Report.RunModal with a RecordRef as the record. (al-runner issue 9280)
// Measured with AL 16.2.28.57946 (runtime 16.0), AL 17.0.34.45391 (runtime 17.0) and AL 18.0.43.1464 (runtime 18.0): AL0133 on each. The case starts at BC 28, as 1634 does: on the BC 27 leg (runtime 16.1, which only AL 17 and newer compile) AL 17.0.34.45391 and AL 18.0.43.1464 give AL0666 for the overload by name of runtime 17.0 instead.
table 53866 "MNC RR Row 53866"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 53866 "MNC RR List 53866"
{
    PageType = List;
    SourceTable = "MNC RR Row 53866";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 53866 "MNC RR Report 53866"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC RR Row 53866") { } }
}
xmlport 53866 "MNC RR Port 53866"
{
    schema { textelement(Root) { tableelement(Row; "MNC RR Row 53866") { fieldelement(Id; Row.Id) { } } } }
}
codeunit 53866 "MNC RR Run 53866"
{
    procedure Probe()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"MNC RR Row 53866");
        Report.RunModal(Report::"MNC RR Report 53866", false, false, RecRef);
    end;
}
