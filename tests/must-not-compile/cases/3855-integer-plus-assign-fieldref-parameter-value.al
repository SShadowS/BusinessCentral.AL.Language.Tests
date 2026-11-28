// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// @from 29
// An Integer += FR.Value(), FR a FieldRef parameter. (al-runner issue 9283)
// Measured with AL compiler 18.0.43.1464 on BC 29 symbols only; BC 27 (AL 16) and BC 28 (AL 17) are not measured yet.
table 53855 "MNC Counter 53855"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53855 "MNC Compound 53855"
{
    procedure Probe(FR: FieldRef)
    var
        I: Integer;
    begin
        I += FR.Value();
    end;
}
