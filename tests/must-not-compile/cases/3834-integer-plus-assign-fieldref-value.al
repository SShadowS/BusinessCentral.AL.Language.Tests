// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// @from 29
// An Integer += FieldRef.Value(): the value is typed Joker, and AL has no '+=' between Integer and Joker (al-runner issue 9283).
// A plain assignment from a FieldRef value compiles: tests/al-language/record/PZFindDirections.al:76.
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53834 "MNC Counter 3834"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53834 "MNC Compound 3834"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FR: FieldRef;
        I: Integer;
    begin
        RecRef.Open(Database::"MNC Counter 3834");
        FR := RecRef.Field(2);
        I := 5;
        I += FR.Value();
    end;
}
