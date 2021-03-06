table 54001 "BPE Upgrade Field"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "BPE Upgrade Fields List";
    LookupPageId = "BPE Upgrade Fields List";
    fields
    {
        field(1; NewTableNo; Integer)
        {
            Caption = 'NewTableID';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where ("Object Type" = filter (Table));
        }
        field(2; NewFieldNo; Integer)
        {
            Caption = 'NewFieldId';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where (TableNo = field (NewTableNo));
        }
        field(3; OriginalTableNo; Integer)
        {
            Caption = 'OriginalTableID';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where ("Object Type" = filter (Table));
        }
        field(4; OriginalFieldNo; Integer)
        {
            Caption = 'OriginalFieldId';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where (TableNo = field (OriginalTableNo), Enabled = filter (true));
        }
        field(20; "Upgrade Method"; Option)
        {
            Caption = 'Upgrade Method';
            OptionMembers = Transfer,Skip;
            OptionCaption = 'Transfer,Skip';
            DataClassification = SystemMetadata;
        }
        field(30; "Caption Match"; Boolean)
        {
            Caption = 'Caption Match';
            DataClassification = SystemMetadata;
        }
        field(31; "Type Match"; Boolean)
        {
            Caption = 'Type Match';
            DataClassification = SystemMetadata;
        }
        field(32; "Len Match"; Boolean)
        {
            Caption = 'Len Match';
            DataClassification = SystemMetadata;
        }
        field(33; "Class Match"; Boolean)
        {
            Caption = 'Class Match';
            DataClassification = SystemMetadata;
        }
        field(34; "Id Match"; Boolean)
        {
            Caption = 'Id Match';
            DataClassification = SystemMetadata;
        }
        field(50; "New Field Caption"; Text[50])
        {
            Caption = 'New Field Caption';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup (Field."Field Caption" where (TableNo = field (NewTableNo), "No." = field (NewFieldNo)));
        }
        field(51; "Original Field Caption"; Text[50])
        {
            Caption = 'Original Field Caption';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup (Field."Field Caption" where (TableNo = field (OriginalTableNo), "No." = field (OriginalFieldNo)));
        }
        field(52; "Origin Disabled"; Boolean)
        {
            Caption = 'Origin Disabled';
            DataClassification = SystemMetadata;
        }
        field(53; "New Field Name"; Text[50])
        {
            Caption = 'New Field Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup (Field.FieldName where (TableNo = field (NewTableNo), "No." = field (NewFieldNo)));
        }
        field(54; "Original Field Name"; Text[50])
        {
            Caption = 'Original Field Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup (Field.FieldName where (TableNo = field (OriginalTableNo), "No." = field (OriginalFieldNo)));
        }


    }

    keys
    {
        key(PK; NewTableNo, NewFieldNo)
        {
            Clustered = true;
        }
        key(UpgradeMethod; "Upgrade Method")
        {
        }
    }

}