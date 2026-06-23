// ============================================================
// asi_oe_rmb_qto_taker_t5.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770.
//               T3 revealed table_properties.active_row=1 is DataSet
//               row metadata, not order_no. Order_no is not available
//               in the message box event context.
//               T5 uses last_maintained_by = current user (uppercase)
//               to find the active quote, which is more reliable than
//               a global ORDER BY date_last_modified.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T3 -> T5)
//   - T3: table_properties.active_row=1 is DataSet row metadata, not order_no
//   - T2: SELECT TOP 1 ORDER BY date_last_modified found wrong quote (5917105)
//   - T5: filter WHERE last_maintained_by = @UserId (uppercase) to scope
//         to quotes this user most recently touched
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeRmbQtoTaker_t5
{
    public class asi_oe_rmb_qto_taker_t5 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string orderNo = string.Empty;

            try
            {
                DataTable msgTable = this.Data.Set.Tables["MessageBoxData"];
                if (msgTable == null || msgTable.Rows.Count == 0)
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                DataRow msgRow = msgTable.Rows[0];

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

                string userIdUpper = userId.ToUpper();

                StringBuilder diagLog = new StringBuilder();
                diagLog.AppendLine("message_no=7770 fired. Session.UserID=" + userId + " (upper=" + userIdUpper + ")");

                // order_no is not in the message box event context.
                // Find the quote this user most recently touched via last_maintained_by.
                // Note: this only works when the converting user has previously saved
                // the quote. If converting someone else's quote fresh, last_maintained_by
                // may still be the original creator — see TODO below.
                const string findSql =
                    @"SELECT TOP 1 order_no
                        FROM oe_hdr
                       WHERE projected_order    = 'Y'
                         AND last_maintained_by = @UserId
                       ORDER BY date_last_modified DESC";

                using (SqlCommand findCmd = new SqlCommand(findSql, P21SqlConnection))
                {
                    findCmd.CommandType = CommandType.Text;
                    findCmd.Parameters.Add("@UserId", SqlDbType.VarChar, 30).Value = userIdUpper;

                    object result = findCmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        orderNo = result.ToString().Trim();
                }

                diagLog.AppendLine("DB query (last_maintained_by=" + userIdUpper + ") order_no=" + orderNo);

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
                        updateCmd.Parameters.Add("@UserId",  SqlDbType.VarChar, 30).Value = userIdUpper;
                        updateCmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo;
                        int rows = updateCmd.ExecuteNonQuery();
                        diagLog.AppendLine("UPDATE rows affected=" + rows);
                    }
                }
                else
                {
                    diagLog.AppendLine("No quote found for last_maintained_by=" + userIdUpper + " — update skipped.");
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_rmb_qto_taker_t5);
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
            return "Sets taker (uppercase) to logged-in user on RMB Convert to Order (Message Box 7770). Finds quote via last_maintained_by = current user.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t5);
        }
    }
}
