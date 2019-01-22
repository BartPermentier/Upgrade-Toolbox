page 54000 "BPE Upgrade Table List"
{

    PageType = List;
    SourceTable = "BPE Upgrade Table";
    Caption = 'Upgrade Table List';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("New Table No."; "New Table No.")
                {
                    ApplicationArea = All;
                }
                field("New Table Caption"; "New Table Caption")
                {
                    ApplicationArea = All;
                }
                field("Original Table No."; "Original Table No.")
                {
                    ApplicationArea = All;
                }
                field("Original Table Caption"; "Original Table Caption")
                {
                    ApplicationArea = All;
                }

                field("CopyMethod"; "Upgrade Method")
                {
                    ApplicationArea = All;
                }
                field("No. of Upgrade Fields"; "No. of Upgrade Fields")
                {
                    ApplicationArea = All;
                }
                field("No. of Skipped Fields"; "No. of Skipped Fields")
                {
                    ApplicationArea = All;
                }
                field("Data Transfered"; "Data Transfered")
                {
                    ApplicationArea = All;
                }
                field(NoOfDatabaseRecordsNewTable; GetNoOfDatabaseRecordsNewTable())
                {
                    Caption = 'No. of Database Records New Table';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(NoOfDatabaseRecordsOriginalTable; GetNoOfDatabaseRecordsOriginalTable())
                {
                    Caption = 'No. of Database Records Original Table';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(GenerateTable)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    GenerateUpgradeTable();
                    FindFirst();
                end;
            }
            action(TransferDataSelectedEntries)
            {
                ApplicationArea = all;
                trigger OnAction()
                var
                    UpgradeTable: Record "BPE Upgrade Table";
                    ProgressBarMgt: Codeunit "BPE Progress Bar Mgt.";
                begin
                    CurrPage.SetSelectionFilter(UpgradeTable);
                    UpgradeTable.SetAutoCalcFields("Original Table Caption", "New Table Caption");
                    UpgradeTable.FindSet();
                    ProgressBarMgt.AddProgressBarParameter(1, 'FromTable');
                    ProgressBarMgt.AddProgressBarParameter(2, 'ToTable');
                    ProgressBarMgt.SetupNewProgressBar('Processing', UpgradeTable.Count(), 1, true, false);
                    repeat
                        ProgressBarMgt.ChangeProgressBarParameterValue(1, UpgradeTable."Original Table Caption");
                        ProgressBarMgt.ChangeProgressBarParameterValue(2, UpgradeTable."New Table Caption");
                        ProgressBarMgt.UpdateProgressBar();
                        UpgradeTable.TransferData();
                        Commit();
                    until UpgradeTable.Next() = 0;
                    ProgressBarMgt.CloseProgressBar();
                end;
            }
            action(CreateSQLStatement)
            {
                ApplicationArea = All;
                Caption = 'Create SQL Statement';
                trigger OnAction()
                begin
                    CreateSqlStatementForRecordSet();
                end;
            }
        }

    }
}
