// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// @from 29
// An Integer += FieldRefs[1].Value(), FieldRefs an array[2] of FieldRef. (al-runner issue 9283)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53854 "MNC Counter 53854"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53854 "MNC Compound 53854"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FieldRefs: array[2] of FieldRef;
        I: Integer;
    begin
        RecRef.Open(Database::"MNC Counter 53854");
        FieldRefs[1] := RecRef.Field(2);
        I += FieldRefs[1].Value();
    end;
}
