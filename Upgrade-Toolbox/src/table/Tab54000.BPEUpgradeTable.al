table 54000 "BPE Upgrade Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "New Table No."; Integer)
        {
            Caption = 'New Table No.';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where ("Object Type" = filter (Table));
        }
        field(2; "Original Table No."; Integer)
        {
            Caption = 'Original Table No.';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where ("Object Type" = filter (Table));
        }

        field(3; "Upgrade Method"; Option)
        {
            Caption = 'CopyMethod';
            DataClassification = SystemMetadata;
            OptionMembers = Skip,Transfer;
        }
        field(4; "AppId"; Guid)
        {
            Caption = 'AppId';
            DataClassification = SystemMetadata;
        }
        field(5; "Data Transfered"; Boolean)
        {
            Caption = 'Data Transfered';
            DataClassification = SystemMetadata;
        }
        field(50; "New Table Caption"; Text[50])
        {
            Caption = 'New Table Caption';
            Editable = false;
            DataClassification = SystemMetadata;
            // FieldClass = FlowField;
            // CalcFormula = lookup (AllObjWithCaption."Object Caption" where ("Object ID" = field ("New Table No.")));
        }
        field(51; "Original Table Caption"; Text[50])
        {
            Caption = 'Original Table Caption';
            Editable = false;
            DataClassification = SystemMetadata;
            // FieldClass = FlowField;
            // CalcFormula = lookup (AllObjWithCaption."Object Caption" where ("Object ID" = field ("Original Table No.")));
        }
        field(52; "No. of Upgrade Fields"; Integer)
        {
            Caption = 'No. of Upgrade Fields';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count ("BPE Upgrade Field" where (NewTableNo = field ("New Table No.")));
        }
        field(53; "No. of Skipped Fields"; Integer)
        {
            Caption = 'No. of Skipped Fields';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count ("BPE Upgrade Field" where (NewTableNo = field ("New Table No."), "Upgrade Method" = filter (Skip)));
        }
        field(54; "New Table Name"; Text[50])
        {
            Caption = 'New Table Name';
            Editable = false;
            DataClassification = SystemMetadata;
            // FieldClass = FlowField;
            // CalcFormula = lookup (AllObjWithCaption."Object Caption" where ("Object ID" = field ("Original Table No.")));
        }
        field(55; "Original Table Name"; Text[50])
        {
            Caption = 'Original Table Name';
            Editable = false;
            DataClassification = SystemMetadata;
            // FieldClass = FlowField;
            // CalcFormula = lookup (AllObjWithCaption."Object Name" where ("Object ID" = field ("Original Table No.")));
        }
        field(800; "Prefix/Sufix"; Code[5])
        {
            Caption = 'Prefix/Sufix';
            DataClassification = SystemMetadata;
        }

    }

    keys
    {
        key(PK; "New Table No.")
        {
            Clustered = true;
        }
    }
    //Generate Table
    //#region GenerateUpgradeTable
    procedure GenerateUpgradeTable();
    var
        //Object: Record Object;
        NAVApp: Record "NAV App";
        NAVAppObjectMetadata: Record "NAV App Object Metadata";
        ProgressBarMgt: Codeunit "BPE Progress Bar Mgt.";
        ExtensionManagement: Page "Extension Management";
        PrefixSufix: Code[5];
    begin
        Reset();
        ExtensionManagement.LookupMode(true);
        if ExtensionManagement.RunModal() = Action::LookupOK then begin
            ExtensionManagement.GetRecord(NAVApp);
            //Get Prefix/Sufix

            PrefixSufix := CopyStr(ProgressBarMgt.RequestNewValueForAField(Rec, Rec.FieldNo("Prefix/Sufix"), ''), 1, MaxStrLen(PrefixSufix));

            //Get all Tables and tableExtensions
            NAVAppObjectMetadata.SetRange("App Package ID", NAVApp."Package ID");
            NAVAppObjectMetadata.SetFilter("Object Type", '%1|%2', NAVAppObjectMetadata."Object Type"::Table, NAVAppObjectMetadata."Object Type"::"TableExtension");
            NAVAppObjectMetadata.FindSet();
            repeat
                case NAVAppObjectMetadata."Object Type" of
                    NAVAppObjectMetadata."Object Type"::Table:
                        HandleTable(NAVAppObjectMetadata, PrefixSufix, NAVApp.ID);
                    NAVAppObjectMetadata."Object Type"::TableExtension:
                        HandleTableExtension(NAVAppObjectMetadata, PrefixSufix, NAVApp.ID);
                end;
            until NAVAppObjectMetadata.Next() = 0;
        end;
    end;
    //#endregion GenerateUpgradeTable
    //#region HandleTable
    local procedure HandleTable(var NAVAppObjectMetadata: Record "NAV App Object Metadata"; PrefixSufix: Code[5]; NavAppId: Guid);
    var
        AllObjWithCaption: Record AllObjWithCaption;
        OldFieldTable: Record Field;
        NewFieldTable: Record Field;
        UpgradeField: Record "BPE Upgrade Field";
        Object: Record Object;
        NewTableCaption: Text;
    begin
        Init();
        "New Table No." := NAVAppObjectMetadata."Object ID";
        "New Table Name" := NAVAppObjectMetadata."Object Name";
        AppId := NavAppId;
        "Upgrade Method" := "Upgrade Method"::Transfer;
        if not Insert() then
            Modify();

        //Get New Table Caption
        AllObjWithCaption.SetRange("Object ID", NAVAppObjectMetadata."Object ID");
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        if AllObjWithCaption.FindFirst() then begin
            NewTableCaption := AllObjWithCaption."Object Caption";
            if StrPos(NewTableCaption, PrefixSufix) <> 0 then begin
                NewTableCaption := NewTableCaption.TrimStart(PrefixSufix);
                NewTableCaption := NewTableCaption.TrimStart('_');
                NewTableCaption := NewTableCaption.TrimStart(' ');
                NewTableCaption := NewTableCaption.TrimEnd(PrefixSufix);
                NewTableCaption := NewTableCaption.TrimEnd('_');
                NewTableCaption := NewTableCaption.TrimEnd(' ');
            end;
            "New Table Caption" := AllObjWithCaption."Object Caption";

        end;

        CreateUpgradeFields(UpgradeField, "New Table No.");

        //Search Original Table via Caption
        Object.Setfilter("ID", '<>%1', "New Table No.");
        Object.SetRange("Caption", NewTableCaption);
        Object.SetRange(Compiled, true);
        if Object.FindLast() then begin
            //Original table found
            "Original Table No." := Object.ID;
            "Original Table Name" := Object.Name;
            "Original Table Caption" := Object.Caption;
            //Loop through upgrade fields
            UpgradeField.SetRange(NewTableNo, "New Table No.");
            UpgradeField.FindSet();
            repeat
                //Assign Original Table No
                UpgradeField.OriginalTableNo := "Original Table No.";

                NewFieldTable.SetRange(TableNo, "New Table No.");
                NewFieldTable.SetRange("No.", UpgradeField.NewFieldNo);
                NewFieldTable.FindFirst();

                //Caption
                OldFieldTable.SetRange(TableNo, "Original Table No.");
                OldFieldTable.SetRange("Field Caption", NewFieldTable."Field Caption");
                if OldFieldTable.FindFirst() then
                    CheckMatches(UpgradeField, OldFieldTable, NewFieldTable)
                else
                    UpgradeField."Upgrade Method" := UpgradeField."Upgrade Method"::Skip;

                //If no Match with caption then try with Id
                if not (UpgradeField."Upgrade Method" = UpgradeField."Upgrade Method"::Transfer) then begin
                    OldFieldTable.SetRange("Field Caption");
                    OldFieldTable.SetRange("No.", NewFieldTable."No.");
                    if OldFieldTable.FindFirst() then
                        CheckMatches(UpgradeField, OldFieldTable, NewFieldTable);
                end;

                UpgradeField.Modify();

                if UpgradeField."Upgrade Method" = UpgradeField."Upgrade Method"::Skip then
                    "Upgrade Method" := "Upgrade Method"::Skip
            until UpgradeField.Next() = 0;

        end else
            "Upgrade Method" := "Upgrade Method"::Skip;
        Modify();
    end;
    //#endregion HandleTable
    //#region HandleTableExtension
    local procedure HandleTableExtension(var NAVAppObjectMetadata: Record "NAV App Object Metadata"; PreOrSufix: Code[5]; NavAppId: Guid);
    var
        NewFieldTable: Record Field;
        OldFieldTable: Record Field;
        UpgradeField: Record "BPE Upgrade Field";
        AllObjWithCaption: Record AllObjWithCaption;
        TableNo: Integer;
    begin
        Evaluate(TableNo, NAVAppObjectMetadata."Object Subtype");
        //Clear Table
        UpgradeField.Setrange(NewTableNo, TableNo);
        UpgradeField.DeleteAll();

        NewFieldTable.SetRange(TableNo, TableNo);
        NewFieldTable.SetFilter("No.", '>=%1', 50000);
        NewFieldTable.SetFilter(FieldName, '%1|%2', '*' + PreOrSufix, PreOrSufix + '*');
        NewFieldTable.SetRange(Class, NewFieldTable.Class::Normal);
        NewFieldTable.SetRange(Enabled, true);
        if NewFieldTable.FindSet() then begin
            Init();
            "New Table No." := TableNo;
            "Original Table No." := TableNo;
            AllObjWithCaption.SetRange("Object ID", TableNo);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.FindFirst();
            "New Table Caption" := AllObjWithCaption."Object Caption";
            "New Table Name" := AllObjWithCaption."Object Name";
            "Original Table Caption" := AllObjWithCaption."Object Caption";
            "Original Table Name" := AllObjWithCaption."Object Name";
            AppId := NavAppId;
            "Upgrade Method" := "Upgrade Method"::Transfer;
            if not Insert() then
                Modify();

            repeat
                UpgradeField.Init();
                UpgradeField.NewTableNo := TableNo;
                UpgradeField.NewFieldNo := NewFieldTable."No.";
                UpgradeField.OriginalTableNo := TableNo;
                OldFieldTable.CopyFilters(NewFieldTable);
                OldFieldTable.SetRange(FieldName);
                OldFieldTable.SetRange("Field Caption", NewFieldTable."Field Caption");
                OldFieldTable.SetFilter("No.", '<>%1', NewFieldTable."No.");
                if OldFieldTable.FindFirst() then
                    CheckMatches(UpgradeField, OldFieldTable, NewFieldTable)
                else begin
                    if StrLen(NewFieldTable."Field Caption") <= 30 then begin
                        OldFieldTable.SetRange("Field Caption");
                        OldFieldTable.SetRange(FieldName, NewFieldTable."Field Caption");
                        if OldFieldTable.FindFirst() then
                            CheckMatches(UpgradeField, OldFieldTable, NewFieldTable)
                        else
                            UpgradeField."Upgrade Method" := UpgradeField."Upgrade Method"::Skip;
                    end else
                        UpgradeField."Upgrade Method" := UpgradeField."Upgrade Method"::Skip;

                    OldFieldTable.SetRange(FieldName);
                end;

                if not UpgradeField.Insert() then
                    UpgradeField.Modify();
            until NewFieldTable.Next() = 0;
        end;

    end;
    //#endregion HandleTableExtension
    //#region CreateUpgradeFields
    local procedure CreateUpgradeFields(var UpgradeField: Record "BPE Upgrade Field"; NewTableNo: Integer);
    var
        NewFieldTable: Record Field;
    begin
        //Delete
        UpgradeField.SetRange(NewTableNo, NewTableNo);
        UpgradeField.DeleteAll();

        //Create Upgrade fields
        NewFieldTable.SetRange(TableNo, NewTableNo);
        NewFieldTable.SetRange(Class, NewFieldTable.Class::Normal);
        NewFieldTable.FindSet();
        repeat
            UpgradeField.Init();
            UpgradeField.NewTableNo := NewTableNo;
            UpgradeField.NewFieldNo := NewFieldTable."No.";
            UpgradeField.Insert();
        until NewFieldTable.Next() = 0;
    end;
    //#endregion CreateUpgradeFields
    //#region CheckMatches
    local procedure CheckMatches(var UpgradeField: Record "BPE Upgrade Field"; OldFieldTable: Record Field; NewFieldTable: Record Field);
    begin
        UpgradeField.OriginalFieldNo := OldFieldTable."No.";
        UpgradeField."Caption Match" := (OldFieldTable."Field Caption" = NewFieldTable."Field Caption") or (OldFieldTable."FieldName" = NewFieldTable."Field Caption");
        //Check Id
        UpgradeField."Id Match" := OldFieldTable."No." = NewFieldTable."No.";
        //Check Type
        UpgradeField."Type Match" := OldFieldTable."Type" = NewFieldTable."Type";
        //Check Length
        UpgradeField."Len Match" := OldFieldTable."Len" <= NewFieldTable."Len";
        //Check Class
        UpgradeField."Class Match" := OldFieldTable."Class" = NewFieldTable."Class";
        if UpgradeField."Type Match" and UpgradeField."Len Match" and UpgradeField."Class Match" then
            UpgradeField."Upgrade Method" := UpgradeField."Upgrade Method"::Transfer
        else
            UpgradeField."Upgrade Method" := UpgradeField."Upgrade Method"::Skip;
        UpgradeField."Origin Disabled" := not OldFieldTable.Enabled;
    end;
    //#endregion CheckMatches

    //Transfer Data
    //#region TransferData
    procedure TransferData();
    var
        UpgradeField: Record "BPE Upgrade Field";
        OriginalRecRef: RecordRef;
        TargetRecRef: RecordRef;
        OriginalFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        //if confirm('exit') then exit;
        if "Upgrade Method" <> "Upgrade Method"::Transfer then exit;
        UpgradeField.SetRange(OriginalTableNo, "Original Table No.");
        UpgradeField.SetRange("Upgrade Method", UpgradeField."Upgrade Method"::Transfer);

        OriginalRecRef.Open("Original Table No.");
        if "Original Table No." <> "New Table No." then
            TargetRecRef.Open("New Table No.");
        if OriginalRecRef.FindSet() then
            repeat
                if "Original Table No." = "New Table No." then
                    TargetRecRef := OriginalRecRef
                else
                    TargetRecRef.Init();
                UpgradeField.SetRange("Origin Disabled", false);
                if UpgradeField.FindSet() then
                    repeat
                        OriginalFieldRef := OriginalRecRef.Field(UpgradeField.OriginalFieldNo);
                        TargetFieldRef := TargetRecRef.Field(UpgradeField.NewFieldNo);
                        TargetFieldRef.Value(OriginalFieldRef.Value());
                        //todo option to validate the field instead
                    until UpgradeField.Next() = 0;
                if not TargetRecRef.Insert() then
                    TargetRecRef.Modify();
            until OriginalRecRef.Next() = 0;
        "Data Transfered" := true;
        Modify();
    end;
    //#endregion TransferData
    //#region GetNoOfDatabaseRecordsOriginalTable
    procedure GetNoOfDatabaseRecordsOriginalTable(): Integer;
    var
        RecRef: RecordRef;
    begin
        if "Original Table No." = 0 then exit;
        RecRef.Open("Original Table No.");
        exit(RecRef.Count());
    end;
    //#endregion GetNoOfDatabaseRecordsOriginalTable
    //#region GetNoOfDatabaseRecordsNewTable
    procedure GetNoOfDatabaseRecordsNewTable(): Integer;
    var
        RecRef: RecordRef;
    begin
        if "New Table No." = 0 then exit;
        RecRef.Open("New Table No.");
        exit(RecRef.Count());
    end;
    //#endregion GetNoOfDatabaseRecordsNewTable

    //Create SQL Statement
    //#region CreateSqlStatementForRecordSet
    procedure CreateSqlStatementForRecordSet();
    var
        Company: Record Company;
        ActiveSession: Record "Active Session";
        UpgradeField: Record "BPE Upgrade Field";
        FileManagement: Codeunit "File Management";
        Companies: Page Companies;
        RecRef: RecordRef;
        FldRef: FieldRef;
        SqlScriptOutstream: OutStream;
        SqlScriptFile: File;
        PrimaryKeyRef: KeyRef;
        DatabaseName: Text;
        FullFilePath: Text;
        From: Text;
        InsertInto: Text;
        On: Text;
        cr: Char;
        lf: Char;
        i: Integer;
        FirstLine: Boolean;
        IsTableExtension: Boolean;
    begin
        //Ask for which Company
        Companies.LookupMode(true);
        if not (Companies.RunModal() = Action::LookupOK) then
            exit;
        Companies.GetSelectedCompanies(Company);

        //Ask File Location
        FullFilePath := FileManagement.SaveFileDialog('Create SQL Statement', '', '(Sql files)|*.sql');
        SqlScriptFile.Create(FullFilePath);
        SqlScriptFile.CreateOutStream(SqlScriptOutstream);

        //Set Defaults
        UpgradeField.SetRange("Upgrade Method", UpgradeField."Upgrade Method"::Transfer);
        UpgradeField.SetRange("Origin Disabled", false);
        UpgradeField.SetAutoCalcFields("Original Field Name", "New Field Name");
        SetRange("Upgrade Method", "Upgrade Method"::Transfer);
        cr := 13;
        lf := 10;
        ActiveSession.SetRange("Session ID", SessionId());
        ActiveSession.FindFirst();
        DatabaseName := ActiveSession."Database Name";

        //Start
        Company.FindSet();
        repeat
            FindSet();
            repeat
                IsTableExtension := "Original Table No." = "New Table No.";
                UpgradeField.SetRange(NewTableNo, "New Table No.");

                if UpgradeField.FindSet() then
                    if IsTableExtension then begin
                        SqlScriptOutstream.WriteText('UPDATE');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        From := '[' + DatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters("New Table Name") + '$' + delchr(delchr(AppId, '<', '{'), '>', '}') + ']'; //TableExtension
                        SqlScriptOutstream.WriteText(From);
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('SET');
                        FirstLine := true;
                        repeat
                            SqlScriptOutstream.WriteText(format(cr) + format(lf));
                            if not FirstLine then
                                SqlScriptOutstream.WriteText(',');
                            SqlScriptOutstream.WriteText('[' + ReplaceIlligalSqlCharacters(UpgradeField."New Field Name") + '] = t2.[' + ReplaceIlligalSqlCharacters(UpgradeField."Original Field Name") + ']');
                            FirstLine := false;
                        until UpgradeField.Next() = 0;
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('FROM');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText(From + ' t');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('INNER JOIN');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('[' + DatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters("Original Table Name") + ']' + ' t2');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('ON');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        //Find the key and add it to the statement
                        On := '';
                        RecRef.Open("Original Table No.");
                        PrimaryKeyRef := RecRef.KeyIndex(1);
                        for i := 1 to PrimaryKeyRef.FieldCount() do begin
                            FldRef := PrimaryKeyRef.FieldIndex(i);
                            if On <> '' then
                                On += ' and ';
                            On += 't2.[' + ReplaceIlligalSqlCharacters(FldRef.Name()) + '] = t.[' + ReplaceIlligalSqlCharacters(FldRef.Name() + ']');
                        end;
                        RecRef.Close();
                        SqlScriptOutstream.WriteText(On);
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                    end else begin //not a table extension
                        SqlScriptOutstream.WriteText('INSERT INTO');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        InsertInto := '[' + DatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters("New Table Name") + '$' + delchr(delchr(AppId, '<', '{'), '>', '}') + ']'; //TableExtension
                        SqlScriptOutstream.WriteText(InsertInto);
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('(');
                        FirstLine := true;
                        repeat
                            SqlScriptOutstream.WriteText(format(cr) + format(lf));
                            if not FirstLine then
                                SqlScriptOutstream.WriteText(',');
                            SqlScriptOutstream.WriteText('[' + ReplaceIlligalSqlCharacters(UpgradeField."New Field Name") + ']');
                            FirstLine := false;
                        until UpgradeField.Next() = 0;
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText(')');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('SELECT');

                        FirstLine := true;
                        UpgradeField.FindSet();
                        repeat
                            SqlScriptOutstream.WriteText(format(cr) + format(lf));
                            if not FirstLine then
                                SqlScriptOutstream.WriteText(',');
                            SqlScriptOutstream.WriteText('[' + ReplaceIlligalSqlCharacters(UpgradeField."Original Field Name") + ']');
                            FirstLine := false;
                        until UpgradeField.Next() = 0;
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('FROM');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('[' + DatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters("Original Table Name") + ']' + ' t');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                    end; //end table or tableextension
            until Next() = 0;
        until Company.Next() = 0;
    end;
    //#endregion CreateSqlStatementForRecordSet
    //#region ReplaceIlligalSqlCharacters
    local procedure ReplaceIlligalSqlCharacters(FieldName: Text) SqlFieldName: Text;
    begin
        SqlFieldName := FieldName.Replace('.', '_');
        SqlFieldName := SqlFieldName.Replace('%', '_');
        SqlFieldName := SqlFieldName.Replace('/', '_');
    end;
    //#endregion ReplaceIlligalSqlCharacters
}