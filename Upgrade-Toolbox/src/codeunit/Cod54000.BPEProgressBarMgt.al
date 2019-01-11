codeunit 54000 "BPE Progress Bar Mgt."
{
    //#region Stopwatch

    procedure StartStopWatch()
    begin
        StopWatchStart := CurrentDateTime();
        StopWatchRunning := true;
    end;

    procedure EndStopWatch()
    begin
        StopWatchEnd := CurrentDateTime();
        StopWatchRunning := false;
    end;

    Procedure ReturnStopWatchDuration(Encapsulate: Boolean): Text
    var
        ElapsedSeconds: Integer;
        EmptyDateTime: DateTime;
    begin
        clear(EmptyDateTime);
        case true of
            StopWatchIsrunning():
                ElapsedSeconds := CurrentDateTime() - StopWatchStart;
            (StopWatchStart = EmptyDateTime):
                exit('');
            (StopWatchEnd = EmptyDateTime):
                exit('');
            else
                ElapsedSeconds := StopWatchEnd - StopWatchStart;
        end;
        ElapsedSeconds := round(ElapsedSeconds / 1000, 1, '>');

        if Encapsulate then
            exit(EncapsulateElapsedTime())
        else
            exit(strsubstno('%1', ElapsedSeconds));
    end;

    procedure StopWatchIsrunning(): Boolean
    begin
        exit(StopWatchrunning);
    end;

    procedure SetStopWatchEncapsulation(EncapsulationText: Text; EncapsulationPlaceholder: integer)
    var
        InvalidEncapsulationPlaceholderErr: label 'Invalid Encapsulation Placeholder index';
        InvalidEncapsulationTextErr: label 'Invalid Encapsulation Text';
    begin
        if EncapsulationPlaceholder = 0 then error(InvalidEncapsulationPlaceholderErr);
        if EncapsulationText = '' then error(InvalidEncapsulationTextErr);

        if not EncapsulationText.Contains('%' + format(EncapsulationPlaceholder)) then error(InvalidEncapsulationPlaceholderErr);

        StopWatchEncapsulationText := EncapsulationText;
        StopWatchEncapsulationPlaceholder := EncapsulationPlaceholder;
        CanEncapsulate := true;
    end;

    procedure ResetStopWatchEncapsulation()
    begin
        StopWatchEncapsulationText := '';
        StopWatchEncapsulationPlaceholder := 0;
        CanEncapsulate := false;
    end;

    local procedure EncapsulateElapsedTime(): Text
    var
        PlaceHolder: Text;
        ReturnValue: Text;
    begin
        if not CanEncapsulate then
            ReturnValue := ReturnStopwatchDuration(false)
        else begin
            PlaceHolder := '%' + format(StopWatchEncapsulationPlaceholder);
            ReturnValue := ReturnValue.Replace(PlaceHolder, ReturnStopwatchDuration(false));
        end;
        exit(ReturnValue);
    end;
    //#endregion Stopwatch
    //#region Progressbar
    procedure ClearProgressBarParameters()
    begin
        clear(ProgressBarTitles);
        clear(ProgressBarValues);
    end;

    procedure AddProgressBarParameter(KeyIndex: integer; Value: Text)
    var
        NewValue: Text;
        MaxParamaterCountErr: label 'Max. ProgressBar Parameter count reached';
    begin
        NewValue := Value;
        if ProgressBarTitles.Get(KeyIndex, Value) then
            ProgressBarTitles.Remove(KeyIndex);
        if ProgressBarTitles.Count() < 10 then
            ProgressBarTitles.Add(KeyIndex, NewValue)
        else
            error(MaxParamaterCountErr);
    end;

    procedure SetupNewProgressBar(Title: Text; RecordCount: Integer; UpdatePer: Integer; UseStopWatch: boolean; UseTimePrediction: boolean)
    begin
        ProgressBarTitle := Title;
        ProgressBarRecordCount := RecordCount;
        ProgressBarUpdatePer := UpdatePer;
        ProgressBarUseStopWatch := UseStopWatch;
        ProgressBarUseTimePrediction := UseTimePrediction;
        ProgressBarRecordsProcessed := 0;
        ProgressBarProgress := 0;
        ProgressBarOldProgress := 0;

        if ProgressBarUpdatePer = 0 then
            ProgressBarUpdatePer := 1;

        if GuiAllowed() then begin
            if ProgressBarUseStopWatch or ProgressBarUseTimePrediction then begin
                clear(ProgreeBarMgt);
                ProgreeBarMgt.StartStopWatch();
            end;
            OpenGenericProgressBar();
        end;
    end;

    procedure ChangeProgressBarParameterValue(KeyIndex: integer; NewValue: Text)
    var
        Value: Text;
    begin
        Value := NewValue;
        if ProgressBarValues.Get(KeyIndex, NewValue) then
            ProgressBarValues.Remove(KeyIndex);
        ProgressBarValues.add(KeyIndex, Value);
        doUpdateProgressBar(true);
    end;

    procedure UpdateProgressBar()
    begin
        ProgressBarRecordsProcessed += 1;
        doUpdateProgressBar(false);
    end;

    procedure UpdateProgressBatWithSpecificValue(ProgressSteps: Integer)
    begin
        ProgressBarRecordsProcessed += ProgressSteps;
        doUpdateProgressBar(false);
    end;

    local procedure doUpdateProgressBar(ForceUpdate: boolean)
    begin
        if (ProgressBarRecordsProcessed mod ProgressBarUpdatePer = 0) and GuiAllowed() then
            ProgressBarProgress := round((ProgressBarRecordsProcessed / progressbarRecordCount) * 10000, 1);

        if ForceUpdate then begin
            UpdateProgressBarValues();
            ProgressBar.Update();
        end else
            if ProgressBarOldProgress <> ProgressBarProgress then begin
                UpdateProgressBarValues();
                ProgressBar.Update();
                ProgressBarOldProgress := ProgressBarProgress;
            end;
    end;

    procedure CloseProgressBar()
    begin
        if GuiAllowed() then begin
            if ProgressBarUseStopWatch or ProgressBarUseTimePrediction then
                ProgreeBarMgt.EndStopWatch();
            ProgressBar.Close();
        end;
    end;

    local procedure OpenGenericProgressBar()
    var
        ProgressBarContents: Text;
    begin
        ProgressBarContents := GenerateProgressBarContents();
        // Should work with arrays, still looking how to do that
        Value1 := GetProgressBarValue(1);
        Value2 := GetProgressBarValue(2);
        Value3 := GetProgressBarValue(3);
        Value4 := GetProgressBarValue(4);
        Value5 := GetProgressBarValue(5);
        Value6 := GetProgressBarValue(6);
        Value7 := GetProgressBarValue(7);
        Value8 := GetProgressBarValue(8);
        Value9 := GetProgressBarValue(9);
        Value10 := GetProgressBarValue(10);

        if not ProgressBarUseStopWatch and not ProgressBarUseTimePrediction then
            case ProgressBarTitles.Count() of
                0:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress);
                1:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1);
                2:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, value2);
                3:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3);
                4:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4);
                5:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, value5);
                6:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, value5, Value6);
                7:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, value5, Value6, Value7);
                8:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, value5, Value6, Value7, Value8);
                9:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, value5, Value6, Value7, Value8, Value9);
                10:
                    Progressbar.Open(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, value5, Value6, Value7, Value8, Value9, Value10);
            end;
        if ProgressBarUseStopWatch and ProgressBarUseTimePrediction then
            case ProgressBarTitles.Count() of
                0:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, StopwatchValue, TimePredictionValue);
                1:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, StopWatchValue, TimePredictionValue);
                2:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, StopWatchValue, TimePredictionValue);
                3:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, StopWatchValue, TimePredictionValue);
                4:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, StopWatchValue, TimePredictionValue);
                5:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, StopWatchValue, TimePredictionValue);
                6:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, StopWatchValue, TimePredictionValue);
                7:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, StopWatchValue, TimePredictionValue);
                8:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, StopWatchValue, TimePredictionValue);
                9:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, StopWatchValue, TimePredictionValue);
                10:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10, StopWatchValue, TimePredictionValue);
            end;
        if ProgressBarUseStopWatch and not ProgressBarUseTimePrediction then
            case ProgressBarTitles.Count() of
                0:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, StopWatchValue);
                1:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, StopWatchValue);
                2:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, StopWatchValue);
                3:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, StopWatchValue);
                4:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, StopWatchValue);
                5:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, StopWatchValue);
                6:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, StopWatchValue);
                7:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, StopWatchValue);
                8:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, StopWatchValue);
                9:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, StopWatchValue);
                10:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10, StopWatchValue);
            end;
        if not ProgressBarUseStopWatch and ProgressBarUseTimePrediction then
            case ProgressBarTitles.Count() of
                0:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, TimePredictionValue);
                1:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, TimePredictionValue);
                2:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, TimePredictionValue);
                3:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, TimePredictionValue);
                4:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, TimePredictionValue);
                5:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, TimePredictionValue);
                6:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, TimePredictionValue);
                7:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, TimePredictionValue);
                8:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, TimePredictionValue);
                9:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, TimePredictionValue);
                10:
                    Progressbar.OPEN(ProgressBarContents, ProgressBarProgress, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10, TimePredictionValue);
            end;
    end;

    local procedure GetProgressBarValue(ValueIndex: Integer): Text
    var
        ReturnValue: Text;
    begin
        if ProgressBarValueList.Get(ValueIndex, ReturnValue) then
            exit(ReturnValue)
        else
            exit('');
    end;

    local procedure UpdateProgressBarValues()
    var
        index: integer;
        MilisecondsPerRecord: Decimal;
        ElapsedTime: Integer;
        EstimatedRemainingTime: INteger;
        RemainingRecords: integer;
        ValueAtIndex: Text;
    begin
        // Should work with arrays, still looking how to do that
        Value1 := GetProgressBarValue(1);
        Value2 := GetProgressBarValue(2);
        Value3 := GetProgressBarValue(3);
        Value4 := GetProgressBarValue(4);
        Value5 := GetProgressBarValue(5);
        Value6 := GetProgressBarValue(6);
        Value7 := GetProgressBarValue(7);
        Value8 := GetProgressBarValue(8);
        Value9 := GetProgressBarValue(9);
        Value10 := GetProgressBarValue(10);

        CLEAR(ProgressBarValueList);
        for index := 1 to ProgressBarValues.Count() do begin
            ProgressBarValues.Get(index, ValueAtIndex);
            ProgressBarValueList.Add(ValueAtIndex);
        end;

        if ProgressBarUseStopWatch then begin
            Evaluate(ElapsedTime, ProgreeBarMgt.ReturnStopwatchDuration(false));
            StopWatchvalue := ReturnTimeSpanTextValue(ElapsedTime);
        end;

        if ProgressBarUseTimePrediction then begin
            Evaluate(ElapsedTime, ProgreeBarMgt.ReturnStopwatchDuration(false));
            MilisecondsPerRecord := 0;
            if ProgressBarRecordsProcessed <> 0 then
                MilisecondsPerRecord := (ElapsedTime * 1000) / ProgressBarRecordsProcessed;
            RemainingRecords := ProgressBarRecordCount - ProgressBarRecordsProcessed;
            EstimatedRemainingTime := round(((MilisecondsPerRecord / 1000) * RemainingRecords), 1, '>');
            TimePredictionValue := ReturnTimeSpanTextvalue(EstimatedRemainingTime);
        end;
    end;

    local procedure ReturnTimeSpanTextValue(TimeSpan: Integer): Text
    begin
        exit(Format(TimeSpan) + ' S');
    end;

    local procedure GenerateProgressBarContents(): Text
    var
        ProgressBarContents: TextBuilder;
        PlaceHolderIndex: Integer;
        Index: integer;
        ParameterTitle: Text;
        ParameterText: Text;
        ElapsedTimeLbl: label 'Elapsed Time:';
        EstimatedTimeRemainingLbl: label 'Estimated Time Remaining:';
    begin
        ProgressBarContents.Append(ProgressBarTitle);
        ProgressBarContents.Append('\\');
        PlaceHolderIndex := 2;

        for index := 1 to ProgressBarTitles.Count() do begin
            ProgressBarTitles.Get(Index, ParameterTitle);
            ParameterText := ParameterTitle + ' #' + format(PlaceHolderIndex);
            ProgressBarContents.Append(ParameterText);
            ProgressBarContents.append('\');
            PlaceHolderIndex += 1;
        end;

        if ProgressBarUseStopWatch then begin
            ProgressBarContents.Append('\\');
            ParameterText := ElapsedTimeLbl + ' #' + format(PlaceHolderIndex);
            ProgressBarContents.Append(ParameterText);
            PlaceHolderIndex += 1;
        end;

        if ProgressBarUseTimePrediction then begin
            ProgressBarContents.Append('\\');
            ParameterText := EstimatedTimeRemainingLbl + ' #' + format(PlaceHolderIndex);
            ProgressBarContents.Append(ParameterText);
            PlaceHolderIndex += 1;
        end;

        ProgressBarContents.Append('\\');
        ProgressBarContents.Append('@1@@@@@@@@@@@@@@@@@@@@');

        exit(ProgressBarContents.ToText());
    end;

    //#endregion Progressbar
    //#region Request Page
    //#region RequestNewValueForAField
    procedure RequestNewValueForAField(RecordVariant: Variant; FieldNo: Integer; InitialValue: Text) Result: Text
    var
        FilterPage: FilterPageBuilder;
        FldRef: FieldRef;
        RecRef: RecordRef;
        GetFiltersText: Text;
        StringPosition: Integer;
        ModifyFieldLbl: Label 'New Value for Field:';
        TooManyParametersErr: Label 'You have used to many parameters. Please only use 1.';
    begin
        // #This function asks the user a new value for a field
        // @RecordVariant : Variant: The record
        // @FieldNo : Integer: The field No.
        // @InitialValue : Text: Optional the value of the current field
        // |Result: the value that the user entered
        FilterPage.PAGECAPTION(ModifyFieldLbl);
        FilterPage.ADDRECORD(ModifyFieldLbl, RecordVariant);
        RecRef.GETTABLE(RecordVariant);
        FldRef := RecRef.FIELD(FieldNo);
        FilterPage.ADDFIELD(ModifyFieldLbl, FldRef, InitialValue);
        IF NOT FilterPage.RUNMODAL() THEN ERROR('');
        RecRef.SETVIEW(FilterPage.GETVIEW(ModifyFieldLbl));
        GetFiltersText := RecRef.GETFILTERS();
        StringPosition := STRPOS(GetFiltersText, ':');
        GetFiltersText := COPYSTR(GetFiltersText, StringPosition + 2);
        StringPosition := STRPOS(GetFiltersText, ':');
        IF StringPosition <> 0 THEN
            ERROR(TooManyParametersErr);
        EXIT(GetFiltersText);
    end;
    //#endregion RequestNewValueForAField
    //#endregion Request Page
    var
        ProgreeBarMgt: Codeunit "BPE Progress Bar Mgt.";
        StopWatchRunning: Boolean;
        CanEncapsulate: Boolean;
        ProgressBarUseStopWatch: Boolean;
        ProgressBarUseTimePrediction: Boolean;
        StopWatchStart: DateTime;
        StopWatchEnd: DateTime;
        StopWatchEncapsulationText: Text;
        ProgressBarTitle: Text;
        StopWatchvalue: Text;
        TimePredictionValue: Text;
        Value1: text;
        Value2: Text;
        Value3: Text;
        Value4: Text;
        value5: Text;
        Value6: Text;
        Value7: text;
        Value8: Text;
        Value9: Text;
        Value10: text;
        ProgressBarTitles: Dictionary of [Integer, Text];
        ProgressBarValues: Dictionary of [Integer, Text];
        StopWatchEncapsulationPlaceholder: Integer;
        ProgressBarRecordCount: Integer;
        ProgressBarRecordsProcessed: Integer;
        ProgressBarProgress: integer;
        ProgressBarUpdatePer: integer;
        ProgressBarOldProgress: Integer;
        ProgressBar: Dialog;
        ProgressBarValueList: List of [Text];
}