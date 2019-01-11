page 54001 "BPE Upgrade Fields List"
{

    PageType = List;
    SourceTable = "BPE Upgrade Field";
    Caption = 'Upgrade Fields List';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("NewTableNo"; "NewTableNo")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("NewFieldNo"; "NewFieldNo")
                {
                    ApplicationArea = All;
                }
                field("New Field Caption"; "New Field Caption")
                {
                    ApplicationArea = All;
                }
                field("OriginalTableNo"; "OriginalTableNo")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("OriginalFieldNo"; "OriginalFieldNo")
                {
                    ApplicationArea = All;
                }
                field("Original Field Caption"; "Original Field Caption")
                {
                    ApplicationArea = All;
                }
                field("Action"; "Upgrade Method")
                {
                    ApplicationArea = All;
                }
                field("Caption Match"; "Caption Match")
                {
                    ApplicationArea = All;
                }
                field("Type Match"; "Type Match")
                {
                    ApplicationArea = All;
                }
                field("Len Match"; "Len Match")
                {
                    ApplicationArea = All;
                }
                field("Class Match"; "Class Match")
                {
                    ApplicationArea = All;
                }
                field("Id Match"; "Id Match")
                {
                    ApplicationArea = All;
                }


            }
        }
    }

}
