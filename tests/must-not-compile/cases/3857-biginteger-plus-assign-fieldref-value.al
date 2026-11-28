// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'BigInteger' and 'Joker'
// @from 29
// A BigInteger += FieldRef.Value(). (al-runner issue 9283)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53857 "MNC Counter 53857"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53857 "MNC Compound 53857"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FR: FieldRef;
        X: BigInteger;
    begin
        RecRef.Open(Database::"MNC Counter 53857");
        FR := RecRef.Field(2);
        X += FR.Value();
    end;
}
