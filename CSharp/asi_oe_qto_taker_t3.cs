// ============================================================
// asi_oe_qto_taker_t3.cs
// ============================================================
// Description : DIAGNOSTIC — dumps Data.Set table/column/row structure
//               for the qtowindowopening event (multi-row rule context).
//               T2 failed: Data.Fields not accessible in multi-row rules;
//               must use Data.Set instead.
// Event       : qtowindowopening  (business_rule_event_uid = 41)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-16  Bus App Team  (T2 → T3)
//   - T2: Data.Fields throws in multi-row rule; P21 defaulted event to multi-row
//   - T3: Switch to Data.Set; enumerate tables/columns/rows to find taker column
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeQtoTaker_t3
{
    public class asi_oe_qto_taker_t3 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                StringBuilder sb = new StringBuilder();

                DataSet ds = this.Data.Set;
                if (ds == null)
                {
                    sb.AppendLine("Data.Set is null.");
                }
                else
                {
                    sb.AppendLine(string.Format("Data.Set: {0} table(s)", ds.Tables.Count));

                    for (int t = 0; t < ds.Tables.Count; t++)
                    {
                        DataTable table = ds.Tables[t];
                        sb.AppendLine(string.Format("  Table[{0}] Name=\"{1}\"  Cols={2}  Rows={3}",
                            t, table.TableName, table.Columns.Count, table.Rows.Count));

                        foreach (DataColumn col in table.Columns)
                            sb.AppendLine(string.Format("    Col: {0}  Type={1}", col.ColumnName, col.DataType.Name));

                        for (int r = 0; r < table.Rows.Count; r++)
                        {
                            DataRow row = table.Rows[r];
                            foreach (DataColumn col in table.Columns)
                            {
                                object val = row[col];
                                sb.AppendLine(string.Format("    Row[{0}] {1} = {2}",
                                    r, col.ColumnName,
                                    val == null || val == DBNull.Value ? "(null)" : val.ToString()));
                            }
                        }
                    }
                }

                string output = sb.ToString();
                LogDiagnostic(output);

                ruleResult.Success = true;
                ruleResult.Message = output;
            }
            catch (Exception ex)
            {
                ruleResult.Success = true;
                ruleResult.Message = "T3 diagnostic error: " + ex.Message;
            }

            return ruleResult;
        }

        private void LogDiagnostic(string details)
        {
            try
            {
                const string logSql =
                    @"INSERT INTO business_rule_log
                        (user_id, log_action, rule_name, rule_assembly_name, run_type,
                         return_value, return_message,
                         date_created, created_by, date_last_modified, last_maintained_by)
                      VALUES
                        (@User, 'Error', @Rule, @Asm, 'Synchronous (Internal)',
                         'Diagnostic', @Msg,
                         GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
                {
                    string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                        ? this.Session.UserID
                        : "unknown";

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t3);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow
            }
        }

        public override string GetDescription()
        {
            return "DIAGNOSTIC: Lists all Data.Set tables, columns, and row values for the qtowindowopening event.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t3);
        }
    }
}
