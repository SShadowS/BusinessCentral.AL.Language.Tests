// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 73590 ("LT DOV Row") and helper codeunit 73590 ("LT DOV Probe", its Max and Show)
//   of DecimalOverflowCells.al; own helper codeunit 73110, test codeunit 73111
// local object: the helper codeunit runs each cell in a TryFunction and reads the target after it.
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
//   Review cells of corpus pull request 1669 and AL Runner pull request 9471 (tests Overflow_Negative3 and later): the remaining sign
//   pairs; - and / just past the .NET maximum; one cell per * triple (Decimal, Integer, BigInteger on either side, each sign pair)
//   at 138753349412021607000000000 * 571 = 79228162514264337597000000000; negative round-down compared with -MAX18; compound
//   assignments (+=, -=, *=, /=) with an in-range start and an out-of-range result, on a variable, a field and a temporary field;
//   a var argument the callee sets past the field range, sets past and back, or leaves; and the 29-digit literal straight in an
//   expression (literal_minus_max18, the literal minus the 18-digit literal, and literal_minus_varmax18, the literal minus a
//   variable holding MAX18, are 0 when the literal holds MAX18; max_minus_max18 is the same for the held Max(); the literal times
//   10 does not compile: AL0371 'The operation overflows at compile time.', AL compiler 18.0).
//   Each cell presets its target to 1, runs in a TryFunction and records "ok: <target>" or "E: <GetLastErrorText> |
//   <GetLastErrorCode>; after <target>", the target's value after the error. A value outside the range Format accepts is shown as
//   'big <value / 10^15> e15' (Show of DecimalOverflowCells.al).
//   Measured on a local BC 29.0.54011.57673 (Linux, W1, en-US session); on BC 27.5 this pull request's CI observe run 46168137059
//   gave the same readings, both 27.5 legs alike, so they hold on every version with no version guard. The review cells (tests
//   Overflow_Negative3 and later): CI observe run 46171889951 gave the same readings on BC 27.5, both 27.5 legs alike, so they
//   hold on every version with no version guard too.
// BC versions: 27, 28, 29 by CI
codeunit 73110 "LT DOX Probe"
{
    var
        Dov: Codeunit "LT DOV Probe";

    // The target of a cell: the variable R, the field Row.Amount, the temporary field TempRow.Amount, or the FieldRef FR.
    [TryFunction]
    local procedure TryCell(Cell: Text; var R: Decimal; var Row: Record "LT DOV Row"; var TempRow: Record "LT DOV Row" temporary; var FR: FieldRef)
    var
        D: Decimal;
        E: Decimal;
        B: BigInteger;
        N: Integer;
        Du: Duration;
    begin
        if Cell.StartsWith('mulx_') then begin
            MulX(Cell, R);
            exit;
        end;
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
            'add_big_max18':
                begin
                    B := 60000000000L;
                    D := 79228162514264337500000000000.0;
                    R := B + D;
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
            // Sign pairs (review of corpus pull request 1669, point 2).
            'div_negmax_neghalf':
                begin
                    D := -Dov.Max();
                    R := D / -0.5;
                end;
            'mul_negmax_decneg10':
                begin
                    D := -Dov.Max();
                    E := -10;
                    R := D * E;
                end;
            'mul_intneg10_negmax':
                begin
                    N := -10;
                    D := -Dov.Max();
                    R := N * D;
                end;
            'mul_max_bigneg10':
                begin
                    D := Dov.Max();
                    B := -10;
                    R := D * B;
                end;
            'mul_negmax_bigneg10':
                begin
                    D := -Dov.Max();
                    B := -10;
                    R := D * B;
                end;
            'mul_big10_negmax':
                begin
                    B := 10;
                    D := -Dov.Max();
                    R := B * D;
                end;
            'mul_bigneg10_negmax':
                begin
                    B := -10;
                    D := -Dov.Max();
                    R := B * D;
                end;
            'div_intneg_tiny':
                begin
                    N := -2147483647;
                    E := 0.00000000000000000001;
                    R := N / E;
                end;
            'div_bigneg_tiny':
                begin
                    B := -9223372036854775807L;
                    E := 0.0000000001;
                    R := B / E;
                end;
            'div_durneg_tiny':
                begin
                    B := -9223372036854775807L;
                    Du := B;
                    E := 0.0000000001;
                    R := Du / E;
                end;
            'add_big93543950336_max18':
                begin
                    B := 93543950336L;
                    D := 79228162514264337500000000000.0;
                    R := B + D;
                end;
            'sub_negmax18_big93543950336':
                begin
                    D := -79228162514264337500000000000.0;
                    B := 93543950336L;
                    R := D - B;
                end;
            // Just past the .NET maximum for - and / (point 3; Decimal * Integer is mulx_di_pp).
            'div_max18_0999999999999999998':
                begin
                    D := 79228162514264337500000000000.0;
                    E := 0.999999999999999998;
                    R := D / E;
                end;
            'sub_negmax18_93543950336':
                begin
                    D := -79228162514264337500000000000.0;
                    R := D - 93543950336.0;
                end;
            // Negative round-down (point 4) and its control.
            'mul_rounddown_neg_int14':
                begin
                    D := -5659154465304595540000000000.0;
                    N := 14;
                    R := D * N;
                end;
            'div_rounddown_neg_07':
                begin
                    D := -55459713759985036300000000000.0;
                    E := 0.7;
                    R := D / E;
                end;
            'sub_negmax18_big60000000000':
                begin
                    D := -79228162514264337500000000000.0;
                    B := 60000000000L;
                    R := D - B;
                end;
            'add_bigneg60000000000_negmax18':
                begin
                    B := -60000000000L;
                    D := -79228162514264337500000000000.0;
                    R := B + D;
                end;
            'add_negmax18_big100000000000':
                begin
                    D := -79228162514264337500000000000.0;
                    B := 100000000000L;
                    R := D + B;
                end;
            // Compound assignments: an in-range start, an out-of-range result (review of AL Runner pull request 9471).
            'plusassign_5e28':
                begin
                    R := 50000000000000000000000000000.0;
                    R += 50000000000000000000000000000.0;
                end;
            'minusassign_neg5e28':
                begin
                    R := -50000000000000000000000000000.0;
                    R -= 50000000000000000000000000000.0;
                end;
            'mulassign_5e28':
                begin
                    R := 50000000000000000000000000000.0;
                    R *= 2;
                end;
            'divassign_5e28':
                begin
                    R := 50000000000000000000000000000.0;
                    R /= 0.5;
                end;
            'field_plusassign_9e14':
                begin
                    Row.Amount := 900000000000000.0;
                    Row.Amount += 900000000000000.0;
                end;
            'field_minusassign_neg9e14':
                begin
                    Row.Amount := -900000000000000.0;
                    Row.Amount -= 900000000000000.0;
                end;
            'field_mulassign_9e14':
                begin
                    Row.Amount := 900000000000000.0;
                    Row.Amount *= 2;
                end;
            'field_divassign_9e14':
                begin
                    Row.Amount := 900000000000000.0;
                    Row.Amount /= 0.5;
                end;
            'temp_plusassign_9e14':
                begin
                    TempRow.Amount := 900000000000000.0;
                    TempRow.Amount += 900000000000000.0;
                end;
            // A var argument: the callee sets it past the field range, sets it past and back, or leaves it.
            'field_varset_1e16':
                SetTo(Row.Amount, 10000000000000000.0);
            'field_varset_back':
                SetPastAndBack(Row.Amount);
            'field_varleave':
                LeaveIt(Row.Amount);
            'temp_varset_1e16':
                SetTo(TempRow.Amount, 10000000000000000.0);
            'varset_1e16':
                SetTo(R, 10000000000000000.0);
            // The 29-digit literal straight in an expression.
            'literal_times_1':
                R := 79228162514264337593543950335.0 * 1;
            'literal_plus_0':
                R := 79228162514264337593543950335.0 + 0;
            'literal_neg_times_1':
                R := -79228162514264337593543950335.0 * 1;
            'literal_minus_max18':
                R := 79228162514264337593543950335.0 - 79228162514264337500000000000.0;
            'literal_assign':
                R := 79228162514264337593543950335.0;
            'literal_minus_varmax18':
                begin
                    D := 79228162514264337500000000000.0;
                    R := 79228162514264337593543950335.0 - D;
                end;
            'max_minus_max18':
                begin
                    D := Dov.Max();
                    R := D - 79228162514264337500000000000.0;
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
            // Format(D, 0, 9) and Evaluate run in one cell: the cell does not tell which of the two calls raises.
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

    // mulx_<pair>_<signs>: 138753349412021607000000000 times 571, exact 79228162514264337597000000000, just above the .NET maximum.
    // <pair> is the left and right type: d = Decimal, i = Integer, b = BigInteger; <signs> the left and right sign: p or n.
    local procedure MulX(Cell: Text; var R: Decimal)
    var
        D: Decimal;
        E: Decimal;
        B: BigInteger;
        N: Integer;
        Pair: Text;
        SL: Integer;
        SR: Integer;
    begin
        Pair := CopyStr(Cell, 6, 2);
        SL := 1;
        SR := 1;
        if CopyStr(Cell, 9, 1) = 'n' then
            SL := -1;
        if CopyStr(Cell, 10, 1) = 'n' then
            SR := -1;
        case Pair of
            'di':
                begin
                    D := 138753349412021607000000000.0 * SL;
                    N := 571 * SR;
                    R := D * N;
                end;
            'id':
                begin
                    N := 571 * SL;
                    D := 138753349412021607000000000.0 * SR;
                    R := N * D;
                end;
            'db':
                begin
                    D := 138753349412021607000000000.0 * SL;
                    B := 571 * SR;
                    R := D * B;
                end;
            'bd':
                begin
                    B := 571 * SL;
                    D := 138753349412021607000000000.0 * SR;
                    R := B * D;
                end;
            'dd':
                begin
                    D := 138753349412021607000000000.0 * SL;
                    E := 571 * SR;
                    R := D * E;
                end;
        end;
    end;

    local procedure SetTo(var X: Decimal; V: Decimal)
    begin
        X := V;
    end;

    local procedure SetPastAndBack(var X: Decimal)
    begin
        X := 10000000000000000.0;
        X := 5;
    end;

    local procedure LeaveIt(var X: Decimal)
    begin
        if X = 0 then
            Error('not reached');
    end;

    procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Row: Record "LT DOV Row";
        TempRow: Record "LT DOV Row" temporary;
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
        Ok: Boolean;
        T: Text;
    begin
        R := 1;
        Row.Amount := 1;
        TempRow.Amount := 1;
        RR.Open(Database::"LT DOV Row");
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
        Row: Record "LT DOV Row";
        TempRow: Record "LT DOV Row" temporary;
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
        Ok: Boolean;
    begin
        R := 1;
        RR.Open(Database::"LT DOV Row");
        FR := RR.Field(2);
        ClearLastError();
        Ok := TryCell(Name, R, Row, TempRow, FR);
        ClearLastError();
        RR.Close();
        Observer.Observe(Name + '_eq', StrSubstNo('ok=%1; R = Max()=%2; R = 79228162514264337500000000000=%3', Ok, R = Dov.Max(),
            R = 79228162514264337500000000000.0));
    end;
    // As EqualCell, against -MAX18: -Max() and the 18-digit literal.
    procedure NegEqualCell(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Row: Record "LT DOV Row";
        TempRow: Record "LT DOV Row" temporary;
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
        Ok: Boolean;
    begin
        R := 1;
        RR.Open(Database::"LT DOV Row");
        FR := RR.Field(2);
        ClearLastError();
        Ok := TryCell(Name, R, Row, TempRow, FR);
        ClearLastError();
        RR.Close();
        Observer.Observe(Name + '_eq', StrSubstNo('ok=%1; R = -Max()=%2; R = -79228162514264337500000000000=%3', Ok, R = -Dov.Max(),
            R = -79228162514264337500000000000.0));
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

    // The sign pairs the earlier tests leave out.
    [Test]
    procedure Overflow_Negative3()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'div_negmax_neghalf');
        Probe.Cell(Observer, 'mul_negmax_decneg10');
        Probe.Cell(Observer, 'mul_intneg10_negmax');
        Probe.Cell(Observer, 'mul_max_bigneg10');
        Probe.Cell(Observer, 'mul_negmax_bigneg10');
        Probe.Cell(Observer, 'mul_big10_negmax');
        Probe.Cell(Observer, 'mul_bigneg10_negmax');
        Observer.Expect('div_negmax_neghalf', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_negmax_decneg10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_intneg10_negmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_max_bigneg10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_negmax_bigneg10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_big10_negmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mul_bigneg10_negmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure Overflow_Negative4()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'div_intneg_tiny');
        Probe.Cell(Observer, 'div_bigneg_tiny');
        Probe.Cell(Observer, 'div_durneg_tiny');
        Probe.Cell(Observer, 'add_big93543950336_max18');
        Probe.Cell(Observer, 'sub_negmax18_big93543950336');
        Observer.Expect('div_intneg_tiny', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('div_bigneg_tiny', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('div_durneg_tiny', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('add_big93543950336_max18', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('sub_negmax18_big93543950336', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure Overflow_JustPastNetMax()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'div_max18_0999999999999999998');
        Probe.Cell(Observer, 'sub_negmax18_93543950336');
        Observer.Expect('div_max18_0999999999999999998', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('sub_negmax18_93543950336', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    // One cell per * triple (types and signs) just above the .NET maximum.
    [Test]
    procedure Multiply_Triples1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'mulx_di_pp');
        Probe.Cell(Observer, 'mulx_di_np');
        Probe.Cell(Observer, 'mulx_di_pn');
        Probe.Cell(Observer, 'mulx_di_nn');
        Probe.Cell(Observer, 'mulx_id_pp');
        Probe.Cell(Observer, 'mulx_id_np');
        Probe.Cell(Observer, 'mulx_id_pn');
        Probe.Cell(Observer, 'mulx_id_nn');
        Observer.Expect('mulx_di_pp', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_di_np', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_di_pn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_di_nn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_id_pp', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_id_np', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_id_pn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_id_nn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure Multiply_Triples2()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'mulx_db_pp');
        Probe.Cell(Observer, 'mulx_db_np');
        Probe.Cell(Observer, 'mulx_db_pn');
        Probe.Cell(Observer, 'mulx_db_nn');
        Probe.Cell(Observer, 'mulx_bd_pp');
        Probe.Cell(Observer, 'mulx_bd_np');
        Probe.Cell(Observer, 'mulx_bd_pn');
        Probe.Cell(Observer, 'mulx_bd_nn');
        Observer.Expect('mulx_db_pp', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_db_np', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_db_pn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_db_nn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_bd_pp', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_bd_np', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_bd_pn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_bd_nn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    [Test]
    procedure Multiply_Triples3()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'mulx_dd_pp');
        Probe.Cell(Observer, 'mulx_dd_np');
        Probe.Cell(Observer, 'mulx_dd_pn');
        Probe.Cell(Observer, 'mulx_dd_nn');
        Observer.Expect('mulx_dd_pp', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_dd_np', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_dd_pn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('mulx_dd_nn', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;

    // Negative round-down; add_negmax18_big100000000000 is the control that is not -MAX18.
    [Test]
    procedure RoundDown_Negative()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'mul_rounddown_neg_int14');
        Probe.Cell(Observer, 'div_rounddown_neg_07');
        Probe.Cell(Observer, 'sub_negmax18_big60000000000');
        Probe.Cell(Observer, 'add_bigneg60000000000_negmax18');
        Probe.Cell(Observer, 'add_negmax18_big100000000000');
        Observer.Expect('mul_rounddown_neg_int14', 'ok: big -79228162514264.3375 e15');
        Observer.Expect('div_rounddown_neg_07', 'ok: big -79228162514264.3375 e15');
        Observer.Expect('sub_negmax18_big60000000000', 'ok: big -79228162514264.3375 e15');
        Observer.Expect('add_bigneg60000000000_negmax18', 'ok: big -79228162514264.3375 e15');
        Observer.Expect('add_negmax18_big100000000000', 'ok: big -79228162514264.3374 e15');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDown_NegativeEquality()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.NegEqualCell(Observer, 'mul_rounddown_neg_int14');
        Probe.NegEqualCell(Observer, 'div_rounddown_neg_07');
        Probe.NegEqualCell(Observer, 'sub_negmax18_big60000000000');
        Probe.NegEqualCell(Observer, 'add_bigneg60000000000_negmax18');
        Probe.NegEqualCell(Observer, 'add_negmax18_big100000000000');
        Observer.Expect('mul_rounddown_neg_int14_eq', 'ok=Yes; R = -Max()=Yes; R = -79228162514264337500000000000=Yes');
        Observer.Expect('div_rounddown_neg_07_eq', 'ok=Yes; R = -Max()=Yes; R = -79228162514264337500000000000=Yes');
        Observer.Expect('sub_negmax18_big60000000000_eq', 'ok=Yes; R = -Max()=Yes; R = -79228162514264337500000000000=Yes');
        Observer.Expect('add_bigneg60000000000_negmax18_eq', 'ok=Yes; R = -Max()=Yes; R = -79228162514264337500000000000=Yes');
        Observer.Expect('add_negmax18_big100000000000_eq', 'ok=Yes; R = -Max()=No; R = -79228162514264337500000000000=No');
        Observer.Verify();
    end;

    // Compound assignments with an in-range start and an out-of-range result.
    [Test]
    procedure Compound_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'plusassign_5e28');
        Probe.Cell(Observer, 'minusassign_neg5e28');
        Probe.Cell(Observer, 'mulassign_5e28');
        Probe.Cell(Observer, 'divassign_5e28');
        Observer.Expect('plusassign_5e28', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after big 50000000000000 e15');
        Observer.Expect('minusassign_neg5e28', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after big -50000000000000 e15');
        Observer.Expect('mulassign_5e28', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after big 50000000000000 e15');
        Observer.Expect('divassign_5e28', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after big 50000000000000 e15');
        Observer.Verify();
    end;

    [Test]
    procedure Compound_Field1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'field_plusassign_9e14');
        Probe.Cell(Observer, 'field_minusassign_neg9e14');
        Probe.Cell(Observer, 'field_mulassign_9e14');
        Observer.Expect('field_plusassign_9e14', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,800,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 900000000000000');
        Observer.Expect('field_minusassign_neg9e14', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: -1,800,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after -900000000000000');
        Observer.Expect('field_mulassign_9e14', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,800,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 900000000000000');
        Observer.Verify();
    end;

    [Test]
    procedure Compound_Field2()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'field_divassign_9e14');
        Probe.Cell(Observer, 'temp_plusassign_9e14');
        Observer.Expect('field_divassign_9e14', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,800,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 900000000000000');
        Observer.Expect('temp_plusassign_9e14', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,800,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 900000000000000');
        Observer.Verify();
    end;

    // A var argument the callee sets past the field range, sets past and back, or leaves.
    [Test]
    procedure VarArgument_Cells()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'field_varset_1e16');
        Probe.Cell(Observer, 'field_varset_back');
        Probe.Cell(Observer, 'field_varleave');
        Probe.Cell(Observer, 'temp_varset_1e16');
        Probe.Cell(Observer, 'varset_1e16');
        Observer.Expect('field_varset_1e16', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 10,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('field_varset_back', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 10,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('field_varleave', 'ok: 1');
        Observer.Expect('temp_varset_1e16', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 10,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange; after 1');
        Observer.Expect('varset_1e16', 'ok: big 10 e15');
        Observer.Verify();
    end;

    // Whether the literal results equal MAX18 (Max() and the 18-digit literal), and the held Max() minus MAX18 as a control.
    [Test]
    procedure Literal_Equality()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.EqualCell(Observer, 'literal_assign');
        Probe.EqualCell(Observer, 'literal_times_1');
        Probe.EqualCell(Observer, 'literal_plus_0');
        Probe.Cell(Observer, 'literal_minus_varmax18');
        Probe.Cell(Observer, 'max_minus_max18');
        Observer.Expect('literal_assign_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('literal_times_1_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('literal_plus_0_eq', 'ok=Yes; R = Max()=Yes; R = 79228162514264337500000000000=Yes');
        Observer.Expect('literal_minus_varmax18', 'ok: 0');
        Observer.Expect('max_minus_max18', 'ok: 0');
        Observer.Verify();
    end;

    // The 29-digit literal straight in an expression.
    [Test]
    procedure Literal_Cells()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOX Probe";
    begin
        Probe.Cell(Observer, 'literal_times_1');
        Probe.Cell(Observer, 'literal_plus_0');
        Probe.Cell(Observer, 'literal_neg_times_1');
        Probe.Cell(Observer, 'literal_minus_max18');
        Observer.Expect('literal_times_1', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('literal_plus_0', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('literal_neg_times_1', 'ok: big -79228162514264.3375 e15');
        Observer.Expect('literal_minus_max18', 'ok: 93543950335');
        Observer.Verify();
    end;
}
