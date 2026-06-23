// ============================================================
// asi_oe_rmb_qto_taker_t1.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770
//               ("Using this method to convert a quote to an order...").
//               Message 7770 fires exclusively during the RMB
//               "Convert to Order" action on a quote — making it a
//               reliable conversion signal. Sets order_taker to the
//               logged-in user for the active quote being converted.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (new series, replaces T1-T14 RMB attempts)
//   - Previous attempts (T8-T14) targeted Workflow/Save and ExecuteAsync;
//     could not reliably detect conversion vs regular save.
//   - Message 7770 fires ONLY during RMB conversion — unique signal.
//   - T1: fires on Message Box Opening, filters message_no=7770,
//     queries DB for the active quote to update order_taker.
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeRmbQtoTaker_t1
{
    public class asi_oe_rmb_qto_taker_t1 : P21.Extensions.BusinessRule.Rule
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

                // Log the full Data.Set to discover whether order context
                // (e.g. order_no) is available from the message box event.
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

                // Attempt to find the active quote for this user and update order_taker.
                // Message 7770 fires before the user clicks Yes/No, so projected_order
                // is still 'Y' in the DB. Query for the most recently touched quote.
                const string findSql =
                    @"SELECT TOP 1 order_no
                        FROM oe_hdr
                       WHERE projected_order = 'Y'
                         AND order_taker != @UserId
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
                             SET order_taker        = @UserId,
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_rmb_qto_taker_t1);
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
            return "Sets order_taker to the logged-in user when RMB Convert to Order fires (detected via Message Box 7770). Multi-Row, Message Box Opening event.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t1);
        }
    }
}
