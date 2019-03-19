table 54002 "BPE Temp Request Page Values"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "id"; Integer)
        {
            Caption = 'id';
            DataClassification = SystemMetadata;
        }
        field(2; "From Database Name"; Text[250])
        {
            Caption = 'From Database Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; id)
        {
            Clustered = true;
        }
    }

}