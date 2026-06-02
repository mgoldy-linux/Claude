// =============================================================================
// mg_diag_message_box_data
// Fires on: Order Entry message box events
//
// Purpose: Diagnostic rule — logs all DataSet tables, rows, and column values
//          to a text file. Does not suppress anything.
//
// Output:
//   File : \\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\mg_diag_message_box_data.txt
//
// Version History:
//   t1  - Initial: log all DataSet tables and field values to diag table and text file
//   t2  - Attempted DB + file logging — blocked by INSERT permission on admin login
//   t3  - Removed DB logging, output to text file only
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.IO;
using System.Text;

namespace mg_diag_message_box_data
{
    public class mg_diag_message_box_data : P21.Extensions.BusinessRule.Rule
    {
        private const string LogPath = @"\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\mg_diag_message_box_data.txt";

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            Guid sessionId    = Guid.NewGuid();
            DateTime captured = DateTime.Now;
            StringBuilder sb  = new StringBuilder();

            sb.AppendLine("==============================================================");
            sb.AppendLine("Session  : " + sessionId);
            sb.AppendLine("Captured : " + captured.ToString("yyyy-MM-dd HH:mm:ss.fff"));
            sb.AppendLine("==============================================================");

            foreach (DataTable table in this.Data.Set.Tables)
            {
                sb.AppendLine();
                sb.AppendLine("TABLE: " + table.TableName + "  (" + table.Rows.Count + " row(s), " + table.Columns.Count + " column(s))");
                sb.AppendLine(new string('-', 60));

                int rowNo = 0;
                foreach (DataRow row in table.Rows)
                {
                    sb.AppendLine("  Row " + rowNo + ":");
                    foreach (DataColumn col in table.Columns)
                    {
                        string value = row.IsNull(col) ? "(null)" : row[col].ToString();
                        sb.AppendLine("    " + col.ColumnName + " = " + value);
                    }
                    rowNo++;
                }
            }

            sb.AppendLine();
            File.AppendAllText(LogPath, sb.ToString(), Encoding.UTF8);

            return ruleResult;
        }

        public override string GetDescription() => "Diagnostic: log all message box DataSet fields to text file";
        public override string GetName() => "mg_diag_message_box_data";
    }
}
