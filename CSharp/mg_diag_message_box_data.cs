// =============================================================================
// mg_diag_message_box_data
// Fires on: Order Entry message box events
//
// Purpose: Diagnostic rule — logs all DataSet tables, rows, and column values
//          to diag_message_box_p21_ud table AND to a text file.
//          Does not suppress anything.
//
// Output:
//   DB   : P21BusinessRules.dbo.diag_message_box_p21_ud
//   File : \\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\mg_diag_message_box_data.txt
//
// Version History:
//   t1  - Initial: log all DataSet tables and field values to diag table and text file
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
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

            Guid sessionId   = Guid.NewGuid();
            DateTime capturedDate = DateTime.Now;
            StringBuilder sb = new StringBuilder();

            sb.AppendLine("==============================================================");
            sb.AppendLine("Session  : " + sessionId);
            sb.AppendLine("Captured : " + capturedDate.ToString("yyyy-MM-dd HH:mm:ss.fff"));
            sb.AppendLine("==============================================================");

            if (P21SqlConnection.State != ConnectionState.Open)
                P21SqlConnection.Open();

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
                        LogToDb(sessionId, capturedDate, table.TableName, rowNo, col.ColumnName, row.IsNull(col) ? null : value);
                    }
                    rowNo++;
                }
            }

            sb.AppendLine();
            WriteToFile(sb.ToString());

            return ruleResult;
        }

        private void LogToDb(Guid sessionId, DateTime capturedDate, string tableName, int rowNo, string columnName, string columnValue)
        {
            using (SqlCommand cmd = new SqlCommand(
                "INSERT INTO dbo.diag_message_box_p21_ud (session_id, captured_date, dataset_table, row_no, column_name, column_value) " +
                "VALUES (@session_id, @captured_date, @dataset_table, @row_no, @column_name, @column_value)", P21SqlConnection))
            {
                cmd.Parameters.AddWithValue("@session_id",    sessionId);
                cmd.Parameters.AddWithValue("@captured_date", capturedDate);
                cmd.Parameters.AddWithValue("@dataset_table", (object)tableName   ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@row_no",        rowNo);
                cmd.Parameters.AddWithValue("@column_name",   (object)columnName  ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@column_value",  (object)columnValue ?? DBNull.Value);
                cmd.ExecuteNonQuery();
            }
        }

        private void WriteToFile(string content)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(LogPath));
            File.AppendAllText(LogPath, content, Encoding.UTF8);
        }

        public override string GetDescription() => "Diagnostic: log all message box DataSet fields to table and text file";
        public override string GetName() => "mg_diag_message_box_data";
    }
}
