// ============================================================
// asi_oe_qto_taker_t11.cs
// ============================================================
// Description : Covers the RMB "Convert to Order" path. Detects the
//               quote-to-order conversion using DataRowVersion.Original
//               on d_oe_header.quote, avoiding the DB race condition
//               where the SELECT already sees the committed 'N' value
//               within the same transaction.
//               T4 (qtowindowopening) covers the wizard path.
// Event       : Workflow / Save / Order Entry (Multi-Row checked)
// Field Selector: quote (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-22  Bus App Team  (T10 -> T11)
//   - T10: DB query for projected_order returned 'N' (transaction already
//     applied by the time the rule fires); condition failed; taker not set
//   - T11: use DataRowVersion.Original on d_oe_header.quote to detect
//     the 'Y'->'N' change without a DB round-trip
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t11
{
    public class asi_oe_qto_taker_t11 : P21.Extensions.BusinessRule.Rule
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

                // Current (post-change) value: 'N' = saving as order, 'Y' = still a quote.
                string currentQuote = hdrRow.Field<string>("quote") ?? string.Empty;
                if (!string.Equals(currentQuote, "N", StringComparison.OrdinalIgnoreCase))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                // Original (pre-change) value: was this record a quote before this save?
                // P21 preserves DataRow change tracking so Original reflects the pre-save state.
                // If Original quote = 'Y' -> current quote = 'N', this is a conversion.
                string originalQuote = string.Empty;
                if (hdrRow.HasVersion(DataRowVersion.Original))
                    originalQuote = hdrRow.Field<string>("quote", DataRowVersion.Original) ?? string.Empty;

                if (!string.Equals(originalQuote, "Y", StringComparison.OrdinalIgnoreCase))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                // order_no lives in d_dw_oe_line_dataentry, not d_oe_header — used for logging only
                try
                {
                    DataTable lineTable = this.Data.Set.Tables["d_dw_oe_line_dataentry"];
                    if (lineTable != null && lineTable.Rows.Count > 0)
                        orderNo = lineTable.Rows[0].Field<string>("order_no") ?? string.Empty;
                }
                catch { }

                string userId = this.Session != null ? this.Session.UserID : string.Empty;
                if (string.IsNullOrEmpty(userId))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                hdrRow["taker"] = userId;

                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                LogRuleError("order_no=" + orderNo + "\r\n" + ex);
                ruleResult.Success = true;
                ruleResult.Message = "QTO order taker update failed. This error has been logged. Please contact the Bus App Team.\r\n\r\n- asi_oe_qto_taker_t11";
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t11);
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
            return "Sets taker to the logged-in user when a projected order (quote) is converted to an order via RMB, detected by d_oe_header.quote changing from 'Y' to 'N' (DataRowVersion.Original vs Current).";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t11);
        }
    }
}
