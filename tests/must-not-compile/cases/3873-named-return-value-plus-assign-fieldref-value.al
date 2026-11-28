// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// A named Integer return value += FieldRef.Value(). No compound assignment takes a Joker (al-runner issue 9283).
// Measured with AL 16.2.28.57946 (BC 27, runtime 16.0), AL 17.0.34.45391 (BC 28, runtime 17.0) and AL 18.0.43.1464 (BC 29, runtime 18.0): the same diagnostic on each. AL 18.0.43.1464 with the BC 27 symbols at runtime 16.1 (the BC 27 leg) gives it too.
table 53873 "MNC Counter 53873"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53873 "MNC Compound 53873"
{
    procedure Probe() Result: Integer
    var
        RecRef: RecordRef;
        FR: FieldRef;
    begin
        RecRef.Open(Database::"MNC Counter 53873");
        FR := RecRef.Field(2);
        Result += FR.Value();
    end;
}
