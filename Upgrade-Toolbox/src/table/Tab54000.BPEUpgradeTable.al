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
            trigger OnValidate()
            begin
                if "Object Type" = "Object Type"::"Table Extension" then
                    HandleTableExtension()
                else
                    HandleTable();
            end;
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
        field(6; "Object Type"; enum BPEObjectType)
        {
            Caption = 'Object Type';
            DataClassification = SystemMetadata;
        }
        field(50; "New Table Caption"; Text[50])
        {
            Caption = 'New Table Caption';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(51; "Original Table Caption"; Text[50])
        {
            Caption = 'Original Table Caption';
            Editable = false;
            DataClassification = SystemMetadata;
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
        }
        field(55; "Original Table Name"; Text[50])
        {
            Caption = 'Original Table Name';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(800; "Prefix/Suffix"; Code[5])
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

    //#region InitUpgradeTable
    procedure InitUpgradeTable(TableNo: Integer; PreOrSuffix: Code[5]; NavAppId: Guid; ObjectType: Enum BPEObjectType);
    begin
        Init();
        "New Table No." := TableNo;
        "Original Table No." := TableNo;
        AppId := NavAppId;
        "Upgrade Method" := "Upgrade Method"::Transfer;
        "Prefix/Suffix" := PreOrSuffix;
        "Object Type" := ObjectType;
    end;
    //#endregion InitUpgradeTable

    //Generate Data
    //#region GenerateUpgradeTable
    procedure GenerateUpgradeTable();
    var
        GenerateUpgradeTable: Codeunit "BPE Generate Upgrade Table";
    begin
        GenerateUpgradeTable.GenerateUpgradeTable(Rec);
    end;
    //#endregion GenerateUpgradeTable
    //#region HandleTableExtension
    procedure HandleTableExtension();
    var
        NAVAppObjectMetadata: Record "NAV App Object Metadata";
        GenerateUpgradeTable: Codeunit "BPE Generate Upgrade Table";
    begin
        NAVAppObjectMetadata.SetRange("App Package ID", AppId);
        NAVAppObjectMetadata.SetRange("Object Type", "Object Type");
        NAVAppObjectMetadata.SetRange("Object ID", "New Table No.");
        NAVAppObjectMetadata.FindFirst();
        GenerateUpgradeTable.HandleTableExtension(Rec, NAVAppObjectMetadata, "Prefix/Suffix", AppId);
    end;
    //#endregion HandleTableExtension
    //#region HandleTable
    procedure HandleTable();
    var
        NAVAppObjectMetadata: Record "NAV App Object Metadata";
        GenerateUpgradeTable: Codeunit "BPE Generate Upgrade Table";
    begin
        NAVAppObjectMetadata.SetRange("App Package ID", AppId);
        NAVAppObjectMetadata.SetRange("Object Type", "Object Type");
        NAVAppObjectMetadata.SetRange("Object ID", "New Table No.");
        NAVAppObjectMetadata.FindFirst();
        GenerateUpgradeTable.HandleTable(Rec, NAVAppObjectMetadata, "Prefix/Suffix", AppId);
    end;
    //#endregion HandleTable

    //Transfer Data
    //#region TransferData
    procedure TransferData();
    var
        TransferData: Codeunit "BPE Transfer Data";
    begin
        TransferData.UpgradeTable_TransferData(Rec);
    end;
    //#endregion TransferData

    //Create SQL Statement
    //#region CreateSqlStatementFromRecordSet
    procedure CreateSqlStatementFromRecordSet();
    var
        CreateSqlQuery: Codeunit "BPE Create Sql Query";
    begin
        CreateSqlQuery.CreateSqlStatementForRecordSet(Rec);
    end;
    //#endregion CreateSqlStatementFromRecordSet 

    //Get Info
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
        AllObjWithCaption: Record AllObjWithCaption;
        RecRef: RecordRef;
    begin
        if "New Table No." = 0 then exit;
        //check if the table still exists or we get an error
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", "New Table No.");
        if not AllObjWithCaption.FindFirst() then exit;
        RecRef.Open("New Table No.");
        exit(RecRef.Count());
    end;
    //#endregion GetNoOfDatabaseRecordsNewTable


}