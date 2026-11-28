// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// @from 29
// An Integer += RecRef.Field(2).Value(). (al-runner issue 9283)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53853 "MNC Counter 53853"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53853 "MNC Compound 53853"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        I: Integer;
    begin
        RecRef.Open(Database::"MNC Counter 53853");
        I += RecRef.Field(2).Value();
    end;
}
