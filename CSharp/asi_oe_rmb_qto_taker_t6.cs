// ============================================================
// asi_oe_rmb_qto_taker_t6.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770.
//               Programming mode revealed the Order Entry window title
//               format: "Order Entry: {order_no} ({customer}) Quote: Y*"
//               this.RuleState.TriggerWindowTitle carries that title,
//               so we parse order_no directly — no DB query needed.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T5 -> T6)
//   - T2-T5: could not reliably find order_no via DB query
//   - Programming mode Show Info revealed window title contains order_no:
//     "Order Entry: 5919788 (Shamrock Floorcovering Srv.Inc) Quote: Y*"
//   - T6: parse order_no from RuleState.TriggerWindowTitle
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeRmbQtoTaker_t6
{
    public class asi_oe_rmb_qto_taker_t6 : P21.Extensions.BusinessRule.Rule
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
                diagLog.AppendLine("message_no=7770 fired. Session.UserID=" + userIdUpper);

                // Parse order_no from the triggering window title.
                // Format: "Order Entry: {order_no} ({customer}) Quote: Y*"
                string windowTitle = this.RuleState != null
                    ? this.RuleState.TriggerWindowTitle ?? string.Empty
                    : string.Empty;

                diagLog.AppendLine("RuleState.TriggerWindowTitle=" + windowTitle);

                const string prefix = "Order Entry: ";
                if (windowTitle.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    string rest = windowTitle.Substring(prefix.Length).Trim();
                    int spaceIdx = rest.IndexOf(' ');
                    string candidate = spaceIdx > 0 ? rest.Substring(0, spaceIdx) : rest;

                    int parsed;
                    if (int.TryParse(candidate, out parsed))
                        orderNo = candidate;
                }

                diagLog.AppendLine("Parsed order_no=" + orderNo);

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
                    diagLog.AppendLine("Could not parse order_no from window title — update skipped.");
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_rmb_qto_taker_t6);
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
            return "Sets taker (uppercase) to logged-in user on RMB Convert to Order (Message Box 7770). Parses order_no from RuleState.TriggerWindowTitle.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t6);
        }
    }
}
