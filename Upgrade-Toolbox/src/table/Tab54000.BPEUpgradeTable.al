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
            FieldClass = FlowField;
            CalcFormula = lookup (AllObjWithCaption."Object Caption" where ("Object ID" = field ("New Table No.")));
        }
        field(51; "Original Table Caption"; Text[50])
        {
            Caption = 'New Table Caption';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup (AllObjWithCaption."Object Caption" where ("Object ID" = field ("Original Table No.")));
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
                        HandleTable(NAVAppObjectMetadata, PrefixSufix);
                    NAVAppObjectMetadata."Object Type"::TableExtension:
                        HandleTableExtension(NAVAppObjectMetadata, PrefixSufix);
                end;
            until NAVAppObjectMetadata.Next() = 0;
        end;
    end;
    //#endregion GenerateUpgradeTable
    //#region HandleTable
    local procedure HandleTable(var NAVAppObjectMetadata: Record "NAV App Object Metadata"; PrefixSufix: Code[5]);
    var
        AllObjWithCaption: Record AllObjWithCaption;
        OldFieldTable: Record Field;
        NewFieldTable: Record Field;
        UpgradeField: Record "BPE Upgrade Field";
        NewTableCaption: Text;
    begin
        Init();
        "New Table No." := NAVAppObjectMetadata."Object ID";
        AppId := NAVAppObjectMetadata."App Package ID";
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

        end;

        CreateUpgradeFields(UpgradeField, "New Table No.");

        //Search Original Table via Caption
        AllObjWithCaption.Setfilter("Object ID", '<>%1', "New Table No.");
        AllObjWithCaption.SetRange("Object Caption", NewTableCaption);
        if AllObjWithCaption.FindLast() then begin
            //Original table found
            "Original Table No." := AllObjWithCaption."Object ID";

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
    local procedure HandleTableExtension(var NAVAppObjectMetadata: Record "NAV App Object Metadata"; PreOrSufix: Code[5]);
    var
        NewFieldTable: Record Field;
        OldFieldTable: Record Field;
        UpgradeField: Record "BPE Upgrade Field";
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
        if NewFieldTable.FindSet() then begin
            Init();
            "New Table No." := TableNo;
            "Original Table No." := TableNo;
            AppId := NAVAppObjectMetadata."App Package ID";
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
    //     UPDATE
    //     [NAV100_BE_Chabert_BC].[dbo].[Stanley and Stella SA$Sales Invoice Header$9acfa8a0-7159-4791-a575-884a741a2384]
    // SET
    //     [STST OGM] = t2.[OGM]
    // FROM
    //     [NAV100_BE_Chabert_BC].[dbo].[Stanley and Stella SA$Sales Invoice Header$9acfa8a0-7159-4791-a575-884a741a2384] t
    // INNER JOIN
    //     [NAV100_BE_Chabert_BC].[dbo].[Stanley and Stella SA$Sales Invoice Header] t2
    // ON 
    //     t2.No_ = t.No_
}