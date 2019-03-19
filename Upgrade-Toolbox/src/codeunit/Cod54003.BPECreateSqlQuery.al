codeunit 54003 "BPE Create Sql Query"
{
    //#region CreateSqlStatementForRecordSet
    procedure CreateSqlStatementForRecordSet(var UpgradeTable: Record "BPE Upgrade Table");
    var
        Company: Record Company;
        ActiveSession: Record "Active Session";
        UpgradeField: Record "BPE Upgrade Field";
        FileManagement: Codeunit "File Management";
        Companies: Page Companies;
        FromDatabaseRequestPage: Page "BPE Request Page";
        RecRef: RecordRef;
        FldRef: FieldRef;
        SqlScriptOutstream: OutStream;
        SqlScriptFile: File;
        PrimaryKeyRef: KeyRef;
        DatabaseName: Text;
        SourceDatabaseName: Text[250];
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

        //Ask which Database
        ActiveSession.SetRange("Session ID", SessionId());
        ActiveSession.FindFirst();
        DatabaseName := ActiveSession."Database Name";
        SourceDatabaseName := ActiveSession."Database Name";
        FromDatabaseRequestPage.LookupMode(false);
        FromDatabaseRequestPage.SetFromDatabase(SourceDatabaseName);
        FromDatabaseRequestPage.RunModal();
        SourceDatabaseName := FromDatabaseRequestPage.ReturnFromDatabase();

        //Ask File Location
        FullFilePath := FileManagement.SaveFileDialog('Create SQL Statement', '', '(Sql files)|*.sql');
        SqlScriptFile.Create(FullFilePath);
        SqlScriptFile.CreateOutStream(SqlScriptOutstream);

        //Set Defaults
        UpgradeField.SetRange("Upgrade Method", UpgradeField."Upgrade Method"::Transfer);
        UpgradeField.SetRange("Origin Disabled", false);
        UpgradeField.SetAutoCalcFields("Original Field Name", "New Field Name");
        UpgradeTable.SetRange("Upgrade Method", UpgradeTable."Upgrade Method"::Transfer);
        cr := 13;
        lf := 10;

        //Start
        Company.FindSet();
        repeat
            UpgradeTable.FindSet();
            repeat
                IsTableExtension := UpgradeTable."Original Table No." = UpgradeTable."New Table No.";
                UpgradeField.SetRange(NewTableNo, UpgradeTable."New Table No.");

                if UpgradeField.FindSet() then
                    if IsTableExtension then begin
                        SqlScriptOutstream.WriteText('UPDATE');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        From := '[' + DatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters(UpgradeTable."New Table Name") + '$' + delchr(delchr(LowerCase(UpgradeTable.AppId), '<', '{'), '>', '}') + ']'; //TableExtension
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
                        SqlScriptOutstream.WriteText('[' + SourceDatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters(UpgradeTable."Original Table Name") + ']' + ' t2');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        SqlScriptOutstream.WriteText('ON');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                        //Find the key and add it to the statement
                        On := '';
                        RecRef.Open(UpgradeTable."Original Table No.");
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
                        InsertInto := '[' + DatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters(UpgradeTable."New Table Name") + '$' + delchr(delchr(LowerCase(UpgradeTable.AppId), '<', '{'), '>', '}') + ']'; //TableExtension
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
                        SqlScriptOutstream.WriteText('[' + SourceDatabaseName + '].[dbo].[' + Company.Name + '$' + ReplaceIlligalSqlCharacters(UpgradeTable."Original Table Name") + ']' + ' t');
                        SqlScriptOutstream.WriteText(format(cr) + format(lf));
                    end; //end table or tableextension
            until UpgradeTable.Next() = 0;
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