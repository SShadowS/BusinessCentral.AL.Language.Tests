// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// @from 29
// An Integer parameter += FieldRef.Value(). (al-runner issue 9283)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53850 "MNC Counter 53850"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53850 "MNC Compound 53850"
{
    procedure Probe(I: Integer)
    var
        RecRef: RecordRef;
        FR: FieldRef;
    begin
        RecRef.Open(Database::"MNC Counter 53850");
        FR := RecRef.Field(2);
        I += FR.Value();
    end;
}
