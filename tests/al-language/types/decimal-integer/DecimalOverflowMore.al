// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); the helper codeunit 73590 ("LT DOV Probe", its Max and Show) of DecimalOverflowCells.al;
//   own table 73110, helper codeunit 73110, test codeunit 73111
// local object: the table holds the Decimal field whose range check is under test.
// Probe (follow-up of corpus pull request 1630, DecimalOverflowCells.al; AL Runner issues 9267 and 9269, the cells AL Runner pull
//   request 9471 needs): Decimal arithmetic at the limit of the Decimal type, MAX18 = 79228162514264337500000000000 (what the literal
//   79228162514264337593543950335.0 holds), and the range check of a record Decimal field. Cells:
//   - overflow: a negative quotient and a negative divisor; a sum of two negative Decimals; MAX - (-MAX); a negative operand in
//     Decimal * Decimal, Integer * Decimal and Decimal * BigInteger; a BigInteger on the left of *; an Integer, BigInteger or Duration
//     beside a Decimal in /; a result between the .NET maximum (79228162514264337593543950335) and 2 * MAX18;
//   - round-down: a product (5659154465304595540000000000 * 14 = 79228162514264337560000000000) and a quotient
//     (55459713759985036300000000000 / 0.7 = 79228162514264337571428571428.57...) whose 18-digit round-up passes the .NET maximum,
//     and a sum with a BigInteger operand (MAX18 + 60000000000, + 93543950335, + 93543950336); each round-down result is also
//     compared with MAX18 for exact equality, beside two controls that are not MAX18;
//   - field range: Validate, FieldRef.Value, FieldRef.Validate and a temporary record past +-999,999,999,999,999.99, and the value
//     999,999,999,999,999.995 (a variable, Format(D, 0, 9) evaluated back into the target, a field, Validate, FieldRef and a
//     temporary record).
//   Each cell presets its target to 1, runs in a TryFunction and records "ok: <target>" or "E: <GetLastErrorText> |
//   <GetLastErrorCode>; after <target>", the target's value after the error. A value outside the range Format accepts is shown as
//   'big <value / 10^15> e15' (Show of DecimalOverflowCells.al).
//   Measured on a local BC 29.0.54011.57673 (Linux, W1, en-US session); on BC 27.5 this pull request's CI observe run 46168137059
//   gave the same readings, both 27.5 legs alike, so they hold on every version with no version guard.
// BC versions: 27, 28, 29 by CI
table 73110 "LT DOX Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73110 "LT DOX Probe"
{
    var
        Dov: Codeunit "LT DOV Probe";

    // The target of a cell: the variable R, the field Row.Amount, the temporary field TempRow.Amount, or the FieldRef FR.
    [TryFunction]
    local procedure TryCell(Cell: Text; var R: Decimal; var Row: Record "LT DOX Row"; var TempRow: Record "LT DOX Row" temporary; var FR: FieldRef)
    var
        D: Decimal;
        E: Decimal;
        B: BigInteger;
        N: Integer;
        Du: Duration;
    begin
        case Cell of
            // Overflow.
            'div_negmax_half':
                begin
                    D := -Dov.Max();
                    R := D / 0.5;
                end;
            'div_max_neghalf':
                begin
                    D := Dov.Max();
                    R := D / -0.5;
                end;
            'add_negmax_negmax':
                begin
                    D := -Dov.Max();
                    E := -Dov.Max();
                    R := D + E;
                end;
            'sub_max_negmax':
                begin
                    D := Dov.Max();
                    E := -Dov.Max();
                    R := D - E;
                end;
            'mul_negmax_dec10':
                begin
                    D := -Dov.Max();
                    E := 10;
                    R := D * E;
                end;
            'mul_max_decneg10':
                begin
                    D := Dov.Max();
                    E := -10;
                    R := D * E;
                end;
            'mul_int10_negmax':
                begin
                    N := 10;
                    D := -Dov.Max();
                    R := N * D;
                end;
            'mul_intneg10_max':
                begin
                    N := -10;
                    D := Dov.Max();
                    R := N * D;
                end;
            'mul_negmax_big10':
                begin
                    D := -Dov.Max();
                    B := 10;
                    R := D * B;
                end;
            'mul_big10_max':
                begin
                    B := 10;
                    D := Dov.Max();
                    R := B * D;
                end;
            'mul_bigneg10_max':
                begin
                    B := -10;
                    D := Dov.Max();
                    R := B * D;
                end;
            'div_int_tiny':
                begin
                    N := 2147483647;
                    E := 0.00000000000000000001;
                    R := N / E;
                end;
            'div_big_tiny':
                begin
                    B := 9223372036854775807L;
                    E := 0.0000000001;
                    R := B / E;
                end;
            'div_dur_tiny':
                begin
                    B := 9223372036854775807L;
                    Du := B;
                    E := 0.0000000001;
                    R := Du / E;
                end;
            'div_max_int1':
                begin
                    D := Dov.Max();
                    N := 1;
                    R := D / N;
                end;
            'div_max_bigneg1':
                begin
                    D := Dov.Max();
                    B := -1;
                    R := D / B;
                end;
            'div_max_int_half':
                begin
                    D := Dov.Max();
                    N := 2;
                    R := D / N;
                end;
            'add_max18_93543950336':
                begin
                    D := 79228162514264337500000000000.0;
                    R := D + 93543950336.0;
                end;
            'add_max18_1e28':
                begin
                    D := 79228162514264337500000000000.0;
                    R := D + 10000000000000000000000000000.0;
                end;
            'mul_max18_1_1':
                begin
                    D := 79228162514264337500000000000.0;
                    R := D * 1.1;
                end;
            // Round-down.
            'mul_rounddown_int14':
                begin
                    D := 5659154465304595540000000000.0;
                    N := 14;
                    R := D * N;
                end;
            'mul_rounddown_dec14':
                begin
                    D := 5659154465304595540000000000.0;
                    E := 14;
                    R := D * E;
                end;
            'div_rounddown_07':
                begin
                    D := 55459713759985036300000000000.0;
                    E := 0.7;
                    R := D / E;
                end;
            'add_max18_big60000000000':
                begin
                    D := 79228162514264337500000000000.0;
                    B := 60000000000L;
                    R := D + B;
                end;
            'add_max18_big93543950335':
                begin
                    D := 79228162514264337500000000000.0;
                    B := 93543950335L;
                    R := D + B;
                end;
            'add_max18_big93543950336':
                begin
                    D := 79228162514264337500000000000.0;
                    B := 93543950336L;
                    R := D + B;
                end;
            // Controls of the equality cells: results that are not MAX18.
            'mul_rounddown_ctrl':
                begin
                    D := 5659154465304595530000000000.0;
                    N := 14;
                    R := D * N;
                end;
            'sub_max18_big100000000000':
                begin
                    D := 79228162514264337500000000000.0;
                    B := 100000000000L;
                    R := D - B;
                end;
            'add_big_max18':
                begin
                    B := 60000000000L;
                    D := 79228162514264337500000000000.0;
                    R := B + D;
                end;
            // Field range.
            'field_validate_1e15':
                Row.Validate(Amount, 1000000000000000.0);
            'field_validate_neg1e15':
                Row.Validate(Amount, -1000000000000000.0);
            'fieldref_value_1e15':
                begin
                    D := 1000000000000000.0;
                    FR.Value := D;
                end;
            'fieldref_value_neg1e15':
                begin
                    D := -1000000000000000.0;
                    FR.Value := D;
                end;
            'fieldref_validate_1e15':
                begin
                    D := 1000000000000000.0;
                    FR.Validate(D);
                end;
            'temp_assign_1e15':
                TempRow.Amount := 1000000000000000.0;
            'temp_assign_neg1e15':
                TempRow.Amount := -1000000000000000.0;
            'temp_validate_1e15':
                TempRow.Validate(Amount, 1000000000000000.0);
            'var_995':
                R := 999999999999999.995;
            'format_995':
                begin
                    D := 999999999999999.995;
                    Evaluate(R, Format(D, 0, 9), 9);
                end;
            'field_assign_995':
                Row.Amount := 999999999999999.995;
            'field_assign_neg995':
                Row.Amount := -999999999999999.995;
            'field_validate_995':
                Row.Validate(Amount, 999999999999999.995);
            'fieldref_value_995':
                begin
                    D := 999999999999999.995;
                    FR.Value := D;
                end;
            'temp_assign_995':
                TempRow.Amount := 999999999999999.995;
            'field_assign_99':
                Row.Amount := 999999999999999.99;
        end;
    end;

    procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Row: Record "LT DOX Row";
        TempRow: Record "LT DOX Row" temporary;
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
        Ok: Boolean;
        T: Text;
    begin
        R := 1;
        Row.Amount := 1;
        TempRow.Amount := 1;
        RR.Open(Database::"LT DOX Row");
        FR := RR.Field(2);
        FR.Value := 1;
        ClearLastError();
        Ok := TryCell(Name, R, Row, TempRow, FR);
        case true of
            Name.StartsWith('field_'):
                T := Dov.Show(Row.Amount);
            Name.StartsWith('temp_'):
                T := Dov.Show(TempRow.Amount);
            Name.StartsWith('fieldref_'):
                T := Dov.Show(FR.Value);
            else
                T := Dov.Show(R);
        end;
        if Ok then
            T := 'ok: ' + T
        else
            T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + '; after ' + T;
        ClearLastError();
        RR.Close();
        Observer.Observe(Name, T);
    end;
    // The equality cells: the cell runs as in Cell, then <name>_eq records whether the variable target equals MAX18, built as
    // the Max of DecimalOverflowCells.al builds it (the literal 79228162514264337593543950335.0) and as the 18-digit literal.
    procedure EqualCell(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Row: Record "LT DOX Row";
        TempRow: Record "LT DOX Row" temporary;
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
        Ok: Boolean;
    begin
        R := 1;
        RR.Open(Database::"LT DOX Row");
        FR := RR.Field(2);
        ClearLastError();
        Ok := TryCell(Name, R, Row, TempRow, FR);
        ClearLastError();
        RR.Close();
        Observer.Observe(Name + '_eq', StrSubstNo('ok=%1; R = Max()=%2; R = 79228162514264337500000000000=%3', Ok, R = Dov.Max(),
            R = 79228162514264337500000000000.0));
    end;
}

codeunit 73111 "LT DOX Overflow Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Overflow_Negative1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'div_negmax_half');
        Probe.Cell(Observer, 'div_max_neghalf');
        Probe.Cell(Observer, 'add_negmax_negmax');
        Probe.Cell(Observer, 'sub_max_negmax');
        Probe.Cell(Observer, 'mul_negmax_dec10');
        Probe.Cell(Observer, 'mul_max_decneg10');
        Observer.Expect('div_negmax_half', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('div_max_neghalf', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('add_negmax_negmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('sub_max_negmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_negmax_dec10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_max_decneg10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure Overflow_Negative2()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'mul_int10_negmax');
        Probe.Cell(Observer, 'mul_intneg10_max');
        Probe.Cell(Observer, 'mul_negmax_big10');
        Probe.Cell(Observer, 'mul_big10_max');
        Probe.Cell(Observer, 'mul_bigneg10_max');
        Observer.Expect('mul_int10_negmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_intneg10_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_negmax_big10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_big10_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_bigneg10_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure Overflow_Divide()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'div_int_tiny');
        Probe.Cell(Observer, 'div_big_tiny');
        Probe.Cell(Observer, 'div_dur_tiny');
        Probe.Cell(Observer, 'div_max_int1');
        Probe.Cell(Observer, 'div_max_bigneg1');
        Probe.Cell(Observer, 'div_max_int_half');
        Observer.Expect('div_int_tiny', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('div_big_tiny', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('div_dur_tiny', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('div_max_int1', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('div_max_bigneg1', 'ok: big -79228162514264.3375 e15');
        Observer.Expect('div_max_int_half', 'ok: big 39614081257132.1688 e15');
        Observer.Verify();
    end;

    [Test]
    procedure Overflow_PastNetMax()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'add_max18_93543950336');
        Probe.Cell(Observer, 'add_max18_1e28');
        Probe.Cell(Observer, 'mul_max18_1_1');
        Observer.Expect('add_max18_93543950336', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('add_max18_1e28', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_max18_1_1', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDown_Cells()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'mul_rounddown_int14');
        Probe.Cell(Observer, 'mul_rounddown_dec14');
        Probe.Cell(Observer, 'div_rounddown_07');
        Probe.Cell(Observer, 'add_max18_big60000000000');
        Probe.Cell(Observer, 'add_max18_big93543950335');
        Probe.Cell(Observer, 'add_max18_big93543950336');
        Probe.Cell(Observer, 'add_big_max18');
        Observer.Expect('mul_rounddown_int14', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('mul_rounddown_dec14', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('div_rounddown_07', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('add_max18_big60000000000', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('add_max18_big93543950335', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('add_max18_big93543950336', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('add_big_max18', 'ok: big 79228162514264.3375 e15');
        Observer.Verify();
    end;

    // Whether each round-down result equals MAX18 exactly; mul_rounddown_ctrl, sub_max18_big100000000000 and the overflow cell
    // add_max18_big93543950336 (the target keeps 1) are the controls that do not.
    [Test]
    procedure RoundDown_Equality()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.EqualCell(Observer, 'mul_rounddown_int14');
        Probe.EqualCell(Observer, 'mul_rounddown_dec14');
        Probe.EqualCell(Observer, 'div_rounddown_07');
        Probe.EqualCell(Observer, 'add_max18_big60000000000');
        Probe.EqualCell(Observer, 'add_max18_big93543950335');
        Probe.EqualCell(Observer, 'add_big_max18');
        Probe.EqualCell(Observer, 'mul_rounddown_ctrl');
        Probe.EqualCell(Observer, 'sub_max18_big100000000000');
        Probe.EqualCell(Observer, 'add_max18_big93543950336');
        Observer.Expect('mul_rounddown_int14_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('mul_rounddown_dec14_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('div_rounddown_07_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('add_max18_big60000000000_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('add_max18_big93543950335_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('add_big_max18_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('mul_rounddown_ctrl_eq', 'ok=Yes; R = Max()=No; R = 79228162514264337500000000000=No');
        Observer.Expect('sub_max18_big100000000000_eq', 'ok=Yes; R = Max()=No; R = 79228162514264337500000000000=No');
        Observer.Expect('add_max18_big93543950336_eq', 'ok=No; R = Max()=No; R = 79228162514264337500000000000=No');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRange_Past1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'field_validate_1e15');
        Probe.Cell(Observer, 'field_validate_neg1e15');
        Probe.Cell(Observer, 'fieldref_value_1e15');
        Probe.Cell(Observer, 'fieldref_value_neg1e15');
        Observer.Expect('field_validate_1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('field_validate_neg1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: -1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('fieldref_value_1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('fieldref_value_neg1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: -1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRange_Past2()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'fieldref_validate_1e15');
        Probe.Cell(Observer, 'temp_assign_1e15');
        Probe.Cell(Observer, 'temp_assign_neg1e15');
        Probe.Cell(Observer, 'temp_validate_1e15');
        Observer.Expect('fieldref_validate_1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('temp_assign_1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('temp_assign_neg1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: -1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('temp_validate_1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRange_995a()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'var_995');
        Probe.Cell(Observer, 'format_995');
        Probe.Cell(Observer, 'field_assign_995');
        Probe.Cell(Observer, 'field_assign_neg995');
        Observer.Expect('var_995', 'ok: big 0.999999999999999995 e15');
        Observer.Expect('format_995', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 999,999,999,999,999.995. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('field_assign_995', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 999,999,999,999,999.995. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('field_assign_neg995', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: -999,999,999,999,999.995. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRange_995b()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'field_validate_995');
        Probe.Cell(Observer, 'fieldref_value_995');
        Probe.Cell(Observer, 'temp_assign_995');
        Probe.Cell(Observer, 'field_assign_99');
        Observer.Expect('field_validate_995', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 999,999,999,999,999.995. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('fieldref_value_995', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 999,999,999,999,999.995. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('temp_assign_995', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 999,999,999,999,999.995. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('field_assign_99', 'ok: 999999999999999.99');
        Observer.Verify();
    end;
}
