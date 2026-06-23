// ============================================================
// asi_oe_qto_taker_t7.cs
// ============================================================
// Description : Window Opened event approach — filters on window_title =
//               "Order Processing", then attempts to set taker to the
//               logged-in user via Data.Set.
// Event       : Window Opened
// Field Selector: WindowOpenedData > window_name, window_title (both checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-22  Bus App Team  (T6 → T7)
//   - T6: diagnostic confirmed window_name=w_response_common, window_title=Order Processing
//   - T7: filter on window_title = "Order Processing" only; attempt to set taker
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t7
{
    public class asi_oe_qto_taker_t7 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                DataSet ds = this.Data.Set;
                if (ds == null || !ds.Tables.Contains("WindowOpenedData"))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                DataTable windowData = ds.Tables["WindowOpenedData"];
                if (windowData.Rows.Count == 0)
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                string windowTitle = windowData.Rows[0]["window_title"] as string ?? string.Empty;

                // Only act on the Order Processing (QTO) window
                if (!string.Equals(windowTitle, "Order Processing", StringComparison.OrdinalIgnoreCase))
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

                // Attempt to set taker — only possible if this event exposes it in Data.Set
                bool takerSet = false;
                foreach (DataTable table in ds.Tables)
                {
                    if (table.Columns.Contains("taker") && table.Rows.Count > 0)
                    {
                        table.Rows[0]["taker"] = userId;
                        takerSet = true;
                        break;
                    }
                }

                if (!takerSet)
                {
                    LogRuleError("Window Opened event does not expose the taker field in Data.Set. " +
                        "window_title=Order Processing matched but taker cannot be set from this event. " +
                        "Use qtowindowopening event instead.");
                    ruleResult.Success = true;
                }
                else
                {
                    ruleResult.Success = true;
                }
            }
            catch (Exception ex)
            {
                LogRuleError(ex.ToString());
                ruleResult.Success = true;
                ruleResult.Message = "QTO order taker default failed. This error has been logged. Please contact the Bus App Team.\r\n\r\n- asi_oe_qto_taker_t7";
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t7);
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
            return "Sets order taker to logged-in user when the Order Processing (QTO) window opens, using the Window Opened event filtered by window_title.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t7);
        }
    }
}
