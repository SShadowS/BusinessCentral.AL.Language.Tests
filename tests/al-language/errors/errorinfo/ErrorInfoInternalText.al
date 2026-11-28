// HEADER PLACEHOLDER

codeunit 77401 "LT EIT Raiser"
{
    // Raises the ErrorInfo given to SetInfo when it runs (Codeunit.Run form of the probe).
    var
        Info: ErrorInfo;

    trigger OnRun()
    begin
        Error(Info);
    end;

    procedure SetInfo(NewInfo: ErrorInfo)
    begin
        Info := NewInfo;
    end;
}

codeunit 77400 "LT EIT Internal Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The Probe Observer replaces everything after "Correlation ID: " up to the next backslash by x. Shape keeps the text
    // around the id, writes the label as "Correlation ID=" and replaces each hex digit of the id by h (0-9, a-f) or H (A-F).
    // Braces and dashes stay as they are.
    local procedure Shape(T: Text): Text
    var
        P: Integer;
        Head: Text;
        Rest: Text;
    begin
        P := StrPos(T, CidLbl);
        if P = 0 then
            exit('[no id] ' + T);
        Head := CopyStr(T, 1, P - 1);
        Rest := CopyStr(T, P + StrLen(CidLbl));
        exit(Head + 'Correlation ID=' + HexShape(IdPart(Rest)) + CopyStr(Rest, StrLen(IdPart(Rest)) + 1));
    end;

    local procedure IdPart(Rest: Text): Text
    var
        i: Integer;
    begin
        i := 1;
        while (i <= StrLen(Rest)) and (StrPos('0123456789abcdefABCDEF{}-', CopyStr(Rest, i, 1)) > 0) do
            i += 1;
        exit(CopyStr(Rest, 1, i - 1));
    end;

    local procedure IdOf(T: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(T, CidLbl);
        if P = 0 then
            exit('');
        exit(IdPart(CopyStr(T, P + StrLen(CidLbl))));
    end;

    local procedure HexShape(Id: Text): Text
    var
        i: Integer;
        C: Text;
        Result: Text;
    begin
        for i := 1 to StrLen(Id) do begin
            C := CopyStr(Id, i, 1);
            if StrPos('0123456789abcdef', C) > 0 then
                Result += 'h'
            else
                if StrPos('ABCDEF', C) > 0 then
                    Result += 'H'
                else
                    Result += C;
        end;
        exit(Result);
    end;

    // Facts about the id inside one error text: its length, whether it parses as a Guid, and whether it equals the
    // Guid's Format number 4 (lower case, no braces). The character in front of the label as a code (92 = backslash).
    local procedure ObserveId(var Observer: Codeunit "Probe Observer"; Name: Text; T: Text)
    var
        Id: Text;
        G: Guid;
        P: Integer;
        C: Integer;
    begin
        Id := IdOf(T);
        Observer.Observe(Name + ' shape', Shape(T));
        Observer.Observe(Name + ' len', Format(StrLen(T)));
        Observer.Observe(Name + ' id len', Format(StrLen(Id)));
        Observer.Observe(Name + ' id is guid', Format(Evaluate(G, Id)));
        Observer.Observe(Name + ' id = format 4', Format(Format(G, 0, 4) = Id));
        Observer.Observe(Name + ' brace pos', Format(StrPos(T, '{')));
        P := StrPos(T, CidLbl);
        if P > 1 then begin
            C := T[P - 1];
            Observer.Observe(Name + ' char before label', Format(C));
        end else
            Observer.Observe(Name + ' char before label', 'none');
        if P > 2 then begin
            C := T[P - 2];
            Observer.Observe(Name + ' 2nd char before label', Format(C));
        end;
    end;

    local procedure Internal(Msg: Text): ErrorInfo
    var
        EI: ErrorInfo;
    begin
        EI.Message(Msg);
        EI.ErrorType(ErrorType::Internal);
        exit(EI);
    end;

    [TryFunction]
    local procedure TryRaise(EI: ErrorInfo)
    begin
        Error(EI);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectOne(EI: ErrorInfo; var Collected: ErrorInfo; var Count: Integer)
    var
        Errors: List of [ErrorInfo];
    begin
        Error(EI);
        Errors := GetCollectedErrors(true);
        Count := Errors.Count();
        if Count > 0 then
            Errors.Get(1, Collected);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectAndLeave(EI: ErrorInfo)
    begin
        Error(EI);
    end;

    // The reporter's shape: Message set through the method, ErrorType Internal, asserterror Error(EI), GetLastErrorText().
    [Test]
    procedure Internal_Asserterror_MessageMethod_Text()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
    begin
        EI := Internal('E2 internal');
        asserterror Error(EI);
        ObserveId(Observer, 'text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('message after raise', EI.Message);
        Observer.Finish();
    end;

    // ErrorInfo.Create and the Message property instead of the method.
    [Test]
    procedure Internal_Asserterror_Create_Text()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
    begin
        EI := ErrorInfo.Create('created internal');
        EI.ErrorType := ErrorType::Internal;
        asserterror Error(EI);
        ObserveId(Observer, 'text', GetLastErrorText());
        Observer.Finish();
    end;

    // No Message at all.
    [Test]
    procedure Internal_Asserterror_NoMessage_Text()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
    begin
        EI.ErrorType(ErrorType::Internal);
        asserterror Error(EI);
        ObserveId(Observer, 'text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Finish();
    end;

    // A DetailedMessage beside the Message.
    [Test]
    procedure Internal_Asserterror_DetailedMessage_Text()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
    begin
        EI := Internal('main internal');
        EI.DetailedMessage('detail of the internal error');
        asserterror Error(EI);
        ObserveId(Observer, 'text', GetLastErrorText());
        Observer.Finish();
    end;

    // GetLastErrorText(true) (exclude customer content), GetLastErrorText(false) and GetLastErrorText() of one raise.
    [Test]
    procedure Internal_LastErrorTextForms_SameRaise()
    var
        Observer: Codeunit "Probe Observer";
        TextTrue: Text;
        TextFalse: Text;
        TextDefault: Text;
        TextAgain: Text;
    begin
        asserterror Error(Internal('forms internal'));
        TextTrue := GetLastErrorText(true);
        TextFalse := GetLastErrorText(false);
        TextDefault := GetLastErrorText();
        TextAgain := GetLastErrorText();
        Observer.Observe('true shape', Shape(TextTrue));
        Observer.Observe('false shape', Shape(TextFalse));
        Observer.Observe('default shape', Shape(TextDefault));
        Observer.Observe('true = default', Format(TextTrue = TextDefault));
        Observer.Observe('false = default', Format(TextFalse = TextDefault));
        Observer.Observe('second read = first', Format(TextAgain = TextDefault));
        ClearLastError();
        Observer.Observe('after clear', GetLastErrorText());
        Observer.Finish();
    end;

    // TryFunction: the text after a false return.
    [Test]
    procedure Internal_TryFunction_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('try result', Format(TryRaise(Internal('try internal'))));
        ObserveId(Observer, 'text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Finish();
    end;

    // Codeunit.Run of an instance that raises the ErrorInfo in OnRun.
    [Test]
    procedure Internal_CodeunitRun_Text()
    var
        Observer: Codeunit "Probe Observer";
        Raiser: Codeunit "LT EIT Raiser";
    begin
        Raiser.SetInfo(Internal('run internal'));
        Observer.Observe('run result', Format(Raiser.Run()));
        ObserveId(Observer, 'text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Finish();
    end;

    // A collected Internal error: Message of the collected ErrorInfo.
    [Test]
    procedure Internal_Collected_Message()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
        Collected: ErrorInfo;
        Count: Integer;
    begin
        EI := Internal('collected internal');
        EI.Collectible(true);
        CollectOne(EI, Collected, Count);
        Observer.Observe('count', Format(Count));
        ObserveId(Observer, 'message', Collected.Message);
        Observer.Observe('type', Format(Collected.ErrorType));
        Observer.Finish();
    end;

    // A collected Internal error that leaves the collecting procedure: the text of the error raised at its end.
    [Test]
    procedure Internal_CollectedLeave_Text()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
    begin
        EI := Internal('leave internal');
        EI.Collectible(true);
        asserterror CollectAndLeave(EI);
        ObserveId(Observer, 'text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Finish();
    end;

    // Two raises of one ErrorInfo: the ids differ, the shape does not.
    [Test]
    procedure Internal_TwoRaises_IdsDiffer()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
        First: Text;
        Second: Text;
    begin
        EI := Internal('twice internal');
        asserterror Error(EI);
        First := GetLastErrorText();
        asserterror Error(EI);
        Second := GetLastErrorText();
        Observer.Observe('ids equal', Format(IdOf(First) = IdOf(Second)));
        Observer.Observe('shapes equal', Format(Shape(First) = Shape(Second)));
        Observer.Finish();
    end;

    // Client neighbours: with Message, without Message, with DetailedMessage, and GetLastErrorText(true).
    [Test]
    procedure Client_Asserterror_Texts()
    var
        Observer: Codeunit "Probe Observer";
        EI: ErrorInfo;
        Empty: ErrorInfo;
    begin
        EI.Message('client text');
        EI.ErrorType(ErrorType::Client);
        asserterror Error(EI);
        Observer.Observe('message', GetLastErrorText());
        Observer.Observe('message true', GetLastErrorText(true));
        Observer.Observe('message code', GetLastErrorCode());
        ClearLastError();
        Empty.ErrorType(ErrorType::Client);
        asserterror Error(Empty);
        Observer.Observe('no message', GetLastErrorText());
        Observer.Observe('no message code', GetLastErrorCode());
        ClearLastError();
        EI.DetailedMessage('client detail');
        asserterror Error(EI);
        Observer.Observe('detailed', GetLastErrorText());
        ClearLastError();
        Observer.Observe('try client', Format(TryRaise(EI)));
        Observer.Observe('try client text', GetLastErrorText());
        Observer.Finish();
    end;

    var
        CidLbl: Label 'Correlation ID: ', Locked = true;
}
