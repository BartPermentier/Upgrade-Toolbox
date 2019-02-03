codeunit 54002 "BPE Transfer Data"
{
    //Transfer Data
    //#region UpgradeTable_TransferData
    procedure UpgradeTable_TransferData(UpgradeTable: Record "BPE Upgrade Table");
    var
        UpgradeField: Record "BPE Upgrade Field";
        OriginalRecRef: RecordRef;
        TargetRecRef: RecordRef;
        OriginalFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        //if confirm('exit') then exit;
        if UpgradeTable."Upgrade Method" <> UpgradeTable."Upgrade Method"::Transfer then exit;

        OriginalRecRef.Open(UpgradeTable."Original Table No.");
        if UpgradeTable."Original Table No." <> UpgradeTable."New Table No." then
            TargetRecRef.Open(UpgradeTable."New Table No.");
        //Loop through original record
        if OriginalRecRef.FindSet() then
            repeat
                //Assign the Target RecRef if it is a table extension or Create a new one if it is from table to table
                if UpgradeTable."Original Table No." = UpgradeTable."New Table No." then
                    TargetRecRef := OriginalRecRef
                else
                    TargetRecRef.Init();
                //Get all the fields that need to be transfered
                UpgradeField.SetRange(OriginalTableNo, UpgradeTable."Original Table No.");
                UpgradeField.SetRange("Upgrade Method", UpgradeField."Upgrade Method"::Transfer);
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
        UpgradeTable."Data Transfered" := true;
        UpgradeTable.Modify();
    end;
    //#endregion UpgradeTable_TransferData


}