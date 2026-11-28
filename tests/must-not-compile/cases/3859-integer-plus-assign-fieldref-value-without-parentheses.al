// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// An Integer += FR.Value, without parentheses. (al-runner issue 9283)
// Measured with AL 16.2.28.57946 (BC 27, runtime 16.0), AL 17.0.34.45391 (BC 28, runtime 17.0) and AL 18.0.43.1464 (BC 29, runtime 18.0): the same diagnostic on each.
table 53859 "MNC Counter 53859"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53859 "MNC Compound 53859"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FR: FieldRef;
        X: Integer;
    begin
        RecRef.Open(Database::"MNC Counter 53859");
        FR := RecRef.Field(2);
        X += FR.Value;
    end;
}
