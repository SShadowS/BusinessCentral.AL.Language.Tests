// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Text' and 'Joker'
// @from 29
// A Text += FieldRef.Value(). (al-runner issue 9283)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53858 "MNC Counter 53858"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53858 "MNC Compound 53858"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FR: FieldRef;
        X: Text;
    begin
        RecRef.Open(Database::"MNC Counter 53858");
        FR := RecRef.Field(2);
        X += FR.Value();
    end;
}
