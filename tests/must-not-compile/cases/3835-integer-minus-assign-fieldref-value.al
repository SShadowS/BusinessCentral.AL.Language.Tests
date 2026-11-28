// @expect AL0175 | Operator '-=' cannot be applied to operands of type 'Integer' and 'Joker'
// An Integer -= FieldRef.Value(): the value is typed Joker, and AL has no '-=' between Integer and Joker (al-runner issue 9283).
// A plain assignment from a FieldRef value compiles: tests/al-language/record/PZFindDirections.al:76.
// Measured with AL 16.2.28.57946 (BC 27, runtime 16.0), AL 17.0.34.45391 (BC 28, runtime 17.0) and AL 18.0.43.1464 (BC 29, runtime 18.0): the same diagnostic on each.
table 53835 "MNC Counter 3835"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53835 "MNC Compound 3835"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FR: FieldRef;
        I: Integer;
    begin
        RecRef.Open(Database::"MNC Counter 3835");
        FR := RecRef.Field(2);
        I := 5;
        I -= FR.Value();
    end;
}
