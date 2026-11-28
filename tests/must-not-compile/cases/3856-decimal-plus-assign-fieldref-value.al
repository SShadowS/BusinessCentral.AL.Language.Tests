// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Decimal' and 'Joker'
// @from 29
// A Decimal += FieldRef.Value(): no compound assignment takes a Joker, whatever the left type. (al-runner issue 9283)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53856 "MNC Counter 53856"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53856 "MNC Compound 53856"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FR: FieldRef;
        X: Decimal;
    begin
        RecRef.Open(Database::"MNC Counter 53856");
        FR := RecRef.Field(2);
        X += FR.Value();
    end;
}
