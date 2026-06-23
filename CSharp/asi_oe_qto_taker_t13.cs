// ============================================================
// asi_oe_qto_taker_t13.cs
// ============================================================
// Description : Covers the RMB "Convert to Order" path. ASynchronous
//               Workflow rules override ExecuteAsync() (void), not
//               Execute() — Execute() is a no-op. Data.Fields is
//               available in ExecuteAsync() with order_no, quote,
//               rma_flag, oe_hdr_completed accessible directly.
//               Detection: after save, last_maintained_by = session
//               user but order_taker still differs → conversion.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Workflow / ASynchronous / Save / Order Entry
//               Multi-Row: NOT checked
// Field Selector: order_no, quote, rma_flag, oe_hdr_completed (all checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T8-T12 -> T13)
//   - T8-T12: all failed because we overrode Execute() instead of
//     ExecuteAsync(). kb_Order_Workflow_v2 revealed the correct pattern:
//     ASynchronous Workflow rules use ExecuteAsync() (void return);
//     Execute() returns success and is never the entry point for async rules.
//   - Source: org-kb_Order_Workflow_v2.cs (cleaned: file-scoped namespace,
//     #nullable disable, kb_SQLHelper, MethodBase verbose pattern all removed)
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t13
{
    public class asi_oe_qto_taker_t13 : P21.Extensions.BusinessRule.Rule
    {
        [Obsolete]
        public override void ExecuteAsync()
        {
            // Skip quotes, RMAs, and completed orders — same guard as kb_Order_Workflow_v2
            if (this.Data.Fields["quote"].FieldValue == "Y" ||
                this.Data.Fields["rma_flag"].FieldValue == "Y" ||
                this.Data.Fields["oe_hdr_completed"].FieldValue == "Y")
                return;

            string orderNo = this.Data.Fields["order_no"].FieldValue ?? string.Empty;
            if (string.IsNullOrEmpty(orderNo))
                return;

            string userId = this.Session != null ? this.Session.UserID : string.Empty;
            if (string.IsNullOrEmpty(userId))
                return;

            try
            {
                // Open a fresh connection — P21SqlConnection may be disposed after async handoff
                using (SqlConnection conn = new SqlConnection(P21SqlConnection.ConnectionString))
                {
                    conn.Open();

                    // Detect conversion: we just saved this record (last_maintained_by = us)
                    // but order_taker is still the original quote creator.
                    // Side note: this also fires if a different user edits someone else's order.
                    string dbOrderTaker = string.Empty;
                    string dbLastMaintainedBy = string.Empty;

                    const string selectSql =
                        "SELECT order_taker, last_maintained_by FROM oe_hdr WHERE order_no = @OrderNo";

                    using (SqlCommand selectCmd = new SqlCommand(selectSql, conn))
                    {
                        selectCmd.CommandType = CommandType.Text;
                        selectCmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo.Trim();

                        using (SqlDataReader reader = selectCmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                dbOrderTaker = reader.IsDBNull(0) ? string.Empty : reader.GetString(0).Trim();
                                dbLastMaintainedBy = reader.IsDBNull(1) ? string.Empty : reader.GetString(1).Trim();
                            }
                        }
                    }

                    // We saved this record AND we're not the taker → update
                    if (string.Equals(dbLastMaintainedBy, userId, StringComparison.OrdinalIgnoreCase) &&
                        !string.Equals(dbOrderTaker, userId, StringComparison.OrdinalIgnoreCase))
                    {
                        const string updateSql =
                            @"UPDATE oe_hdr
                                 SET order_taker        = @UserId,
                                     last_maintained_by = @UserId,
                                     date_last_modified = GETDATE()
                               WHERE order_no = @OrderNo";

                        using (SqlCommand updateCmd = new SqlCommand(updateSql, conn))
                        {
                            updateCmd.CommandType = CommandType.Text;
                            updateCmd.Parameters.Add("@UserId",  SqlDbType.VarChar, 30).Value = userId;
                            updateCmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo.Trim();
                            updateCmd.ExecuteNonQuery();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogRuleError("order_no=" + orderNo + "\r\n" + ex);
            }
        }

        // Execute() is the synchronous entry point — not called for ASynchronous rules.
        // Must be overridden; return success so P21 does not block the save.
        public override RuleResult Execute()
        {
            return new RuleResult() { Success = true };
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
                        (@User, 'Error', @Rule, @Asm, 'ASynchronous',
                         'Failure', @Msg,
                         GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
                {
                    string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                        ? this.Session.UserID
                        : "unknown";

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t13);
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
            return "Sets order_taker to the logged-in user when a projected order (quote) is converted to an order via RMB. Fires async after save; detects conversion via last_maintained_by vs order_taker mismatch.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t13);
        }
    }
}
