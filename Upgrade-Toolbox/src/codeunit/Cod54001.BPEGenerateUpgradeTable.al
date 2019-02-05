codeunit 54001 "BPE Generate Upgrade Table"
{
    //Globals
    //#region GenerateUpgradeTable
    procedure GenerateUpgradeTable(var UpgradeTable: Record "BPE Upgrade Table");
    var
        //Object: Record Object;
        NAVApp: Record "NAV App";
        NAVAppObjectMetadata: Record "NAV App Object Metadata";
        ProgressBarMgt: Codeunit "BPE Progress Bar Mgt.";
        ExtensionManagement: Page "Extension Management";
        PrefixSufix: Code[5];
    begin
        UpgradeTable.Reset();
        ExtensionManagement.LookupMode(true);
        if ExtensionManagement.RunModal() = Action::LookupOK then begin
            ExtensionManagement.GetRecord(NAVApp);
            //Get Prefix/Sufix

            PrefixSufix := CopyStr(ProgressBarMgt.RequestNewValueForAField(UpgradeTable, UpgradeTable.FieldNo("Prefix/Suffix"), UpgradeTable."Prefix/Suffix"), 1, MaxStrLen(PrefixSufix));

            //Get all Tables and tableExtensions
            NAVAppObjectMetadata.SetRange("App Package ID", NAVApp."Package ID");
            NAVAppObjectMetadata.SetFilter("Object Type", '%1|%2', NAVAppObjectMetadata."Object Type"::Table, NAVAppObjectMetadata."Object Type"::"TableExtension");
            NAVAppObjectMetadata.FindSet();
            repeat
                case NAVAppObjectMetadata."Object Type" of
                    NAVAppObjectMetadata."Object Type"::Table:
                        HandleTable(UpgradeTable, NAVAppObjectMetadata, PrefixSufix, NAVApp.ID);
                    NAVAppObjectMetadata."Object Type"::TableExtension:
                        HandleTableExtension(UpgradeTable, NAVAppObjectMetadata, PrefixSufix, NAVApp.ID);
                end;
            until NAVAppObjectMetadata.Next() = 0;
        end;
    end;
    //#endregion GenerateUpgradeTable
    //#region HandleTableExtension
    procedure HandleTableExtension(var UpgradeTable: Record "BPE Upgrade Table"; var NAVAppObjectMetadata: Record "NAV App Object Metadata"; PrefixOrSuffix: Code[5]; NavAppId: Guid);
    var
        NewFieldTable: Record Field;
        UpgradeField: Record "BPE Upgrade Field";
        AllObjWithCaption: Record AllObjWithCaption;
        ObjectType: Enum BPEObjectType;
        TableNo: Integer;
    begin
        Evaluate(TableNo, NAVAppObjectMetadata."Object Subtype");
        //Clear Table
        UpgradeField.Setrange(NewTableNo, TableNo);
        UpgradeField.DeleteAll();

        //Search for fields in the TableExtension with a Prefix Or Suffix
        //These are the new fields from our Table Extension
        NewFieldTable.SetRange(TableNo, TableNo);
        NewFieldTable.SetFilter("No.", '>=%1', 50000);
        NewFieldTable.SetFilter(FieldName, '%1|%2', '*' + PrefixOrSuffix, PrefixOrSuffix + '*');
        NewFieldTable.SetRange(Class, NewFieldTable.Class::Normal);
        NewFieldTable.SetRange(Enabled, true);
        if NewFieldTable.FindSet() then begin
            //Create Upgrade Table
            UpgradeTable.InitUpgradeTable(TableNo, PrefixOrSuffix, NavAppId, ObjectType::"Table Extension");

            //Get Caption Data
            AllObjWithCaption.SetRange("Object ID", TableNo);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.FindFirst();
            UpgradeTable."New Table Caption" := AllObjWithCaption."Object Caption";
            UpgradeTable."New Table Name" := AllObjWithCaption."Object Name";
            UpgradeTable."Original Table Caption" := AllObjWithCaption."Object Caption";
            UpgradeTable."Original Table Name" := AllObjWithCaption."Object Name";

            if not UpgradeTable.Insert() then
                UpgradeTable.Modify();
            //Create Upgrade Fields
            repeat
                //For each field in that table create a UpgradeField Entry and try to match with a C/Side field
                UpgradeField.Init();
                UpgradeField.NewTableNo := TableNo;
                UpgradeField.NewFieldNo := NewFieldTable."No.";
                UpgradeField.OriginalTableNo := TableNo;
                UpgradeField."Upgrade Method" := UpgradeField."Upgrade Method"::Skip;
                //Match the Caption of the New Field with the Caption of the Old Field
                if not MatchCaptionWithCaption(UpgradeField, NewFieldTable) then
                    //Match the Caption of the New Field with the Name of the Old Field
                    MatchCaptionWithName(UpgradeField, NewFieldTable);
                if not UpgradeField.Insert() then
                    UpgradeField.Modify();
            until NewFieldTable.Next() = 0;
        end;

    end;
    //#endregion HandleTableExtension

    //#region HandleTable
    procedure HandleTable(var UpgradeTable: Record "BPE Upgrade Table"; var NAVAppObjectMetadata: Record "NAV App Object Metadata"; PrefixOrSuffix: Code[5]; NavAppId: Guid);
    var
        AllObjWithCaption: Record AllObjWithCaption;
        OldFieldTable: Record Field;
        NewFieldTable: Record Field;
        UpgradeField: Record "BPE Upgrade Field";
        Object: Record Object;
        ObjectType: Enum BPEObjectType;
        NewTableCaption: Text;
    begin
        UpgradeTable.InitUpgradeTable(NAVAppObjectMetadata."Object ID", PrefixOrSuffix, NavAppId, ObjectType::Table);
        UpgradeTable."New Table Name" := NAVAppObjectMetadata."Object Name";
        if not UpgradeTable.Insert() then
            UpgradeTable.Modify();

        //Get New Table Caption
        AllObjWithCaption.SetRange("Object ID", NAVAppObjectMetadata."Object ID");
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        if AllObjWithCaption.FindFirst() then begin
            NewTableCaption := AllObjWithCaption."Object Caption";
            //If the caption still has his Pre of Suffix then remove it
            if StrPos(NewTableCaption, PrefixOrSuffix) <> 0 then begin
                NewTableCaption := NewTableCaption.TrimStart(PrefixOrSuffix);
                NewTableCaption := NewTableCaption.TrimStart('_');
                NewTableCaption := NewTableCaption.TrimStart(' ');
                NewTableCaption := NewTableCaption.TrimEnd(PrefixOrSuffix);
                NewTableCaption := NewTableCaption.TrimEnd('_');
                NewTableCaption := NewTableCaption.TrimEnd(' ');
            end;
            UpgradeTable."New Table Caption" := AllObjWithCaption."Object Caption";

        end;
        //Add all the fields of the new table
        CreateUpgradeFields(UpgradeField, UpgradeTable."New Table No.");

        //Search Original Table via Caption
        Object.Setfilter("ID", '<>%1', UpgradeTable."New Table No.");
        Object.SetRange("Caption", NewTableCaption);
        Object.SetRange(Compiled, true);
        Object.SetRange(Type, Object.Type::Table);
        if Object.FindLast() then begin
            //Original table found
            UpgradeTable."Original Table No." := Object.ID;
            UpgradeTable."Original Table Name" := Object.Name;
            Object.CalcFields(Caption);
            UpgradeTable."Original Table Caption" := Object.Caption;
            //Loop through upgrade fields
            UpgradeField.SetRange(NewTableNo, UpgradeTable."New Table No.");
            UpgradeField.FindSet();
            repeat
                //Assign Original Table No
                UpgradeField.OriginalTableNo := UpgradeTable."Original Table No.";

                NewFieldTable.SetRange(TableNo, UpgradeTable."New Table No.");
                NewFieldTable.SetRange("No.", UpgradeField.NewFieldNo);
                NewFieldTable.FindFirst();

                //Match New fields and Old fields with their Caption
                OldFieldTable.SetRange(TableNo, UpgradeTable."Original Table No.");
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
                    UpgradeTable."Upgrade Method" := UpgradeTable."Upgrade Method"::Skip
            until UpgradeField.Next() = 0;

        end else
            UpgradeTable."Upgrade Method" := UpgradeTable."Upgrade Method"::Skip;
        UpgradeTable.Modify();
    end;
    //#endregion HandleTable

    //Locals
    //#region MatchCaptionWithCaption
    local procedure MatchCaptionWithCaption(var UpgradeField: Record "BPE Upgrade Field"; var NewFieldTable: Record Field) MatchFound: Boolean;
    var
        OldFieldTable: Record Field;
    begin
        OldFieldTable.CopyFilters(NewFieldTable);
        OldFieldTable.SetRange(FieldName);
        OldFieldTable.SetRange("Field Caption", NewFieldTable."Field Caption");
        OldFieldTable.SetFilter("No.", '<>%1', NewFieldTable."No.");
        if OldFieldTable.FindFirst() then
            CheckMatches(UpgradeField, OldFieldTable, NewFieldTable);
        exit(UpgradeField."Upgrade Method" = UpgradeField."Upgrade Method"::Transfer);
    end;
    //#endregion MatchCaptionWithCaption
    //#region MatchCaptionWithName
    local procedure MatchCaptionWithName(var UpgradeField: Record "BPE Upgrade Field"; var NewFieldTable: Record Field) MatchFound: Boolean;
    var
        OldFieldTable: Record Field;
    begin
        if StrLen(NewFieldTable."Field Caption") > 30 then exit;
        OldFieldTable.CopyFilters(NewFieldTable);
        OldFieldTable.SetRange(FieldName, NewFieldTable."Field Caption");
        OldFieldTable.SetFilter("No.", '<>%1', NewFieldTable."No.");
        if OldFieldTable.FindFirst() then
            CheckMatches(UpgradeField, OldFieldTable, NewFieldTable);
        exit(UpgradeField."Upgrade Method" = UpgradeField."Upgrade Method"::Transfer);
    end;
    //#endregion MatchCaptionWithName
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
        UpgradeField."Id Match" := OldFieldTable."No." = NewFieldTable."No."; //Only usefull for Table Upgrades not Table Extension Upgrades
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

}