// ============================================================
// asi_oe_rmb_qto_taker_t3.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770.
//               T2 revealed Data.Set has a second table: table_properties
//               (cols: rowID, table, active_row). T3 reads active_row
//               from table_properties to get the actual open order_no
//               instead of guessing via a DB query.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T2 -> T3)
//   - T2: SELECT TOP 1 found wrong quote (5917105 vs actual 5918369)
//   - T2 log revealed table_properties table with active_row column
//   - T3: reads order_no from table_properties.active_row directly
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeRmbQtoTaker_t3
{
    public class asi_oe_rmb_qto_taker_t3 : P21.Extensions.BusinessRule.Rule
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

                // Read active_row from table_properties — should be the open order_no
                StringBuilder diagLog = new StringBuilder();
                diagLog.AppendLine("message_no=7770 fired. Session.UserID=" + userId);

                DataTable tblProps = this.Data.Set.Tables["table_properties"];
                if (tblProps != null && tblProps.Rows.Count > 0)
                {
                    DataRow propRow = tblProps.Rows[0];
                    object tableVal     = propRow["table"];
                    object activeRowVal = propRow["active_row"];

                    string tableStr     = (tableVal     == null || tableVal     == DBNull.Value) ? "(null)" : tableVal.ToString();
                    string activeRowStr = (activeRowVal == null || activeRowVal == DBNull.Value) ? "(null)" : activeRowVal.ToString().Trim();

                    diagLog.AppendLine("table_properties.table="      + tableStr);
                    diagLog.AppendLine("table_properties.active_row=" + activeRowStr);

                    if (!string.IsNullOrEmpty(activeRowStr) && activeRowStr != "(null)")
                        orderNo = activeRowStr;
                }
                else
                {
                    diagLog.AppendLine("table_properties not found or empty");
                }

                diagLog.AppendLine("order_no to update=" + orderNo);

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
                    diagLog.AppendLine("No order_no found — update skipped.");
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_rmb_qto_taker_t3);
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
            return "Sets taker to the logged-in user on RMB Convert to Order (Message Box 7770). Reads order_no from table_properties.active_row.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t3);
        }
    }
}
