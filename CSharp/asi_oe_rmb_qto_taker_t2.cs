// ============================================================
// asi_oe_rmb_qto_taker_t2.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770
//               ("Using this method to convert a quote to an order...").
//               Message 7770 fires exclusively during the RMB
//               "Convert to Order" action on a quote — making it a
//               reliable conversion signal. Sets taker to the
//               logged-in user for the active quote being converted.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T1 -> T2)
//   - T1: column named order_taker — Invalid column name error;
//     correct name in oe_hdr is taker (same as in d_oe_header DataSet)
//   - T2: both SELECT and UPDATE use taker column name
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeRmbQtoTaker_t2
{
    public class asi_oe_rmb_qto_taker_t2 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string orderNo = string.Empty;

            try
            {
                // Message Box Opening is a multi-row event — data is in Data.Set
                DataTable msgTable = this.Data.Set.Tables["MessageBoxData"];
                if (msgTable == null || msgTable.Rows.Count == 0)
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                DataRow msgRow = msgTable.Rows[0];

                // Only act on message 7770 — RMB "Convert to Order" confirmation
                object msgNoRaw = msgRow["message_no"];
                string messageNo = (msgNoRaw == null || msgNoRaw == DBNull.Value)
                    ? string.Empty : msgNoRaw.ToString().Trim();

                if (messageNo != "7770")
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                string userId = this.Session != null ? this.Session.UserID : string.Empty;
                if (string.IsNullOrEmpty(userId))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                // Log the full Data.Set to confirm order context availability
                StringBuilder diagLog = new StringBuilder();
                diagLog.AppendLine("message_no=7770 fired. Session.UserID=" + userId);
                diagLog.AppendLine("MessageBoxData fields:");
                foreach (DataColumn col in msgTable.Columns)
                {
                    object val = msgRow[col];
                    diagLog.AppendLine("  " + col.ColumnName + " = " +
                        (val == null || val == DBNull.Value ? "(null)" : val.ToString()));
                }
                diagLog.AppendLine("All Data.Set tables:");
                foreach (DataTable tbl in this.Data.Set.Tables)
                {
                    diagLog.AppendLine("  Table=" + tbl.TableName +
                        " Cols=" + tbl.Columns.Count +
                        " Rows=" + tbl.Rows.Count);
                    if (tbl.TableName != "MessageBoxData")
                    {
                        foreach (DataColumn col in tbl.Columns)
                            diagLog.AppendLine("    Col=" + col.ColumnName);
                    }
                }

                // Message 7770 fires before the user clicks Yes/No, so projected_order
                // is still 'Y' in the DB. Find the most recently touched quote.
                const string findSql =
                    @"SELECT TOP 1 order_no
                        FROM oe_hdr
                       WHERE projected_order = 'Y'
                         AND taker != @UserId
                       ORDER BY date_last_modified DESC";

                using (SqlCommand findCmd = new SqlCommand(findSql, P21SqlConnection))
                {
                    findCmd.CommandType = CommandType.Text;
                    findCmd.Parameters.Add("@UserId", SqlDbType.VarChar, 30).Value = userId;

                    object result = findCmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        orderNo = result.ToString().Trim();
                }

                diagLog.AppendLine("DB query order_no=" + orderNo);

                if (!string.IsNullOrEmpty(orderNo))
                {
                    const string updateSql =
                        @"UPDATE oe_hdr
                             SET taker              = @UserId,
                                 last_maintained_by = @UserId,
                                 date_last_modified = GETDATE()
                           WHERE order_no       = @OrderNo
                             AND projected_order = 'Y'";

                    using (SqlCommand updateCmd = new SqlCommand(updateSql, P21SqlConnection))
                    {
                        updateCmd.CommandType = CommandType.Text;
                        updateCmd.Parameters.Add("@UserId",  SqlDbType.VarChar, 30).Value = userId;
                        updateCmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo;
                        int rows = updateCmd.ExecuteNonQuery();
                        diagLog.AppendLine("UPDATE rows affected=" + rows);
                    }
                }
                else
                {
                    diagLog.AppendLine("No active quote found for update.");
                }

                LogDiagnostic(userId, diagLog.ToString());
                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                LogDiagnostic("unknown", "order_no=" + orderNo + "\r\n" + ex);
                ruleResult.Success = true;
            }

            return ruleResult;
        }

        private void LogDiagnostic(string userId, string details)
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
                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_rmb_qto_taker_t2);
                    logCmd.Parameters.Add("@Asm",  SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg",  SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch { }
        }

        public override string GetDescription()
        {
            return "Sets taker to the logged-in user when RMB Convert to Order fires (detected via Message Box 7770). Multi-Row, Message Box Opening event.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t2);
        }
    }
}
