page 54002 "BPE Request Page"
{
    PageType = Card;
    SourceTable = "BPE Temp Request Page Values";
    SourceTableTemporary = true;
    layout
    {
        area(Content)
        {
            group(FromDatabase)
            {
                Caption = 'Take data from which database?';
                field("From Database Name"; "From Database Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    //#region SetFromDatabase
    procedure SetFromDatabase(var FromDatabase: Text[250]);
    begin
        if IsEmpty() then begin
            Init();
            Insert();
        end;
        "From Database Name" := FromDatabase;
        Modify();
    end;
    //#endregion SetFromDatabase
    //#region ReturnFromDatabase
    procedure ReturnFromDatabase() FromDatabase: Text[250];
    begin
        Exit("From Database Name");
    end;
    //#endregion ReturnFromDatabase
}