// ============================================================
// asi_oe_qto_taker_t8.cs
// ============================================================
// Description : Covers the RMB "Convert to Order" path. When the order
//               header is saved, queries the DB for the original
//               projected_order value. If it was 'Y' (a projected/quote
//               order) and the form is saving 'N' (converting), sets
//               order_taker to the logged-in user.
//               T4 (qtowindowopening) covers the wizard path.
//               This rule covers the RMB direct-convert path.
// Event       : ValidateRecord on Order Entry (oe_hdr header)
// Field Selector: order_no (read), projected_order (read), order_taker (write)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-22  Bus App Team
//   - T5-T7: Window Opened event approach abandoned -- event cannot write
//             back to the QTO dialog form fields
//   - Trace of RMB convert showed direct DataStore UPDATE on oe_hdr:
//             projected_order 'Y' -> 'N', order_taker not touched
//   - T8: ValidateRecord on Order Entry; detects projected_order change
//         via DB query; sets order_taker = session user on conversion
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t8
{
    public class asi_oe_qto_taker_t8 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string orderNo = string.Empty;

            try
            {
                // Only act when the form is saving projected_order = 'N'
                string formProjectedOrder = this.Data.Fields["projected_order"].FieldValue ?? string.Empty;
                if (!string.Equals(formProjectedOrder, "N", StringComparison.OrdinalIgnoreCase))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                orderNo = this.Data.Fields["order_no"].FieldValue ?? string.Empty;
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

                // Query DB for the original projected_order value.
                // If it was 'Y' and the form is saving 'N', this is an RMB conversion.
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

                if (string.Equals(dbProjectedOrder, "Y", StringComparison.OrdinalIgnoreCase))
                    this.Data.Fields["order_taker"].FieldValue = userId;

                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                LogRuleError("order_no=" + orderNo + "\r\n" + ex);
                ruleResult.Success = true;
                ruleResult.Message = "QTO order taker update failed. This error has been logged. Please contact the Bus App Team.\r\n\r\n- asi_oe_qto_taker_t8";
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t8);
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
            return "Sets order_taker to the logged-in user when a projected order (quote) is converted to an order via RMB, detected by projected_order changing 'Y' to 'N' on save.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t8);
        }
    }
}
