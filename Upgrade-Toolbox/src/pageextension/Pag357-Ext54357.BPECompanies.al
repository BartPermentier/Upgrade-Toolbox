pageextension 54357 "BPECompanies" extends Companies //357
{
    layout
    {

    }

    actions
    {
    }
    //#region GetSelectedCompanies
    procedure GetSelectedCompanies(var Company: Record Company);
    begin
        CurrPage.SetSelectionFilter(Company);
    end;
    //#endregion GetSelectedCompanies
}