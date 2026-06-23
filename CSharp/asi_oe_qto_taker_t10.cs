// ============================================================
// asi_oe_qto_taker_t10.cs
// ============================================================
// Description : Covers the RMB "Convert to Order" path. On Order Entry
//               save, reads Data.Set.Tables["d_oe_header"] (multi-row
//               context) to detect a projected order (quote) being
//               converted. Sets taker to the logged-in P21 user.
//               T4 (qtowindowopening) covers the wizard path.
// Event       : Workflow / Save / Order Entry (Multi-Row checked)
// Field Selector: quote (checked to ensure d_oe_header loads)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-22  Bus App Team  (T8/T9 -> T10)
//   - T8: used Data.Fields; KeyNotFoundException -- Workflow/Save is multi-row
//   - T9: diagnostic not needed after decompiling kb_Order_Validator_v2
//   - kb_Order_Validator_v2 revealed: table = d_oe_header,
//     quote = projected_order equivalent, taker & order_no present
//   - T10: uses Data.Set.Tables["d_oe_header"] matching kb pattern
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t10
{
    public class asi_oe_qto_taker_t10 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string orderNo = string.Empty;

            try
            {
                DataTable hdrTable = this.Data.Set.Tables["d_oe_header"];
                if (hdrTable == null || hdrTable.Rows.Count == 0)
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                DataRow hdrRow = hdrTable.Rows[0];

                // "quote" in d_oe_header = projected_order flag.
                // 'Y' = still a quote (saving as-is), 'N' = saving as a real order.
                // Only act when saving as 'N' — possible conversion.
                string formQuote = hdrRow.Field<string>("quote") ?? string.Empty;
                if (!string.Equals(formQuote, "N", StringComparison.OrdinalIgnoreCase))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                orderNo = hdrRow.Field<string>("order_no") ?? string.Empty;
                if (string.IsNullOrEmpty(orderNo))
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

                // Query DB for the pre-save projected_order value.
                // Workflow/Save fires before the DB commit, so the DB still has
                // 'Y' if this record was a quote. A regular order save returns 'N'.
                const string sql = "SELECT projected_order FROM oe_hdr WHERE order_no = @OrderNo";
                string dbProjectedOrder = string.Empty;

                using (SqlCommand cmd = new SqlCommand(sql, P21SqlConnection))
                {
                    cmd.CommandType = CommandType.Text;
                    cmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo.Trim();

                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        dbProjectedOrder = result.ToString();
                }

                // DB had 'Y' + form is saving 'N' → RMB quote-to-order conversion.
                if (string.Equals(dbProjectedOrder, "Y", StringComparison.OrdinalIgnoreCase))
                    hdrRow["taker"] = userId;

                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                LogRuleError("order_no=" + orderNo + "\r\n" + ex);
                ruleResult.Success = true;
                ruleResult.Message = "QTO order taker update failed. This error has been logged. Please contact the Bus App Team.\r\n\r\n- asi_oe_qto_taker_t10";
            }

            return ruleResult;
        }

        private void LogRuleError(string details)
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
                         'Failure', @Msg,
                         GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
                {
                    string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                        ? this.Session.UserID
                        : "unknown";

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t10);
                    logCmd.Parameters.Add("@Asm",  SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg",  SqlDbType.VarChar, 8000).Value =
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
            return "Sets order_taker (taker) to the logged-in user when a projected order (quote) is converted to an order via RMB Convert to Order, detected via d_oe_header quote flag + DB check.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t10);
        }
    }
}
