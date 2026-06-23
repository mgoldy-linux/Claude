// ============================================================
// asi_oe_qto_taker_t5.cs
// ============================================================
// Description : Sets the taker field to the logged-in P21 user on the
//               RMB "Convert to Order" path (the non-wizard shortcut), so the
//               converting user is recorded as the order taker rather than the
//               original quote creator. T4 covers the Quote to Order *wizard*
//               (qtowindowopening); that event does not fire on the RMB path.
// Event       : RMB "Convert to Order" -- business_rule_event_uid = TBD
//               (confirm the event uid when binding; this is NOT uid 41).
// Data.Set    : Table "HeaderInfo", column "taker", row 0
//               (confirm the table name for this path before relying on it).
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-17  Bus App Team
//   - T5: production rule for the RMB "Convert to Order" path -- sets
//         HeaderInfo[taker] to the session user. qtowindowopening (T4, uid 41)
//         does not fire on the RMB shortcut, so this rule binds the RMB event.
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t5
{
    public class asi_oe_qto_taker_t5 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                string userId = this.Session != null ? this.Session.UserID : string.Empty;
                if (string.IsNullOrEmpty(userId))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                DataSet ds = this.Data.Set;
                if (ds == null || !ds.Tables.Contains("HeaderInfo"))
                {
                    LogRuleError("Data.Set is null or does not contain the HeaderInfo table. The RMB Convert to Order event structure may differ from the wizard path.");
                    ruleResult.Success = true;
                    return ruleResult;
                }

                DataTable headerInfo = ds.Tables["HeaderInfo"];
                if (headerInfo.Rows.Count == 0)
                {
                    LogRuleError("HeaderInfo table has no rows.");
                    ruleResult.Success = true;
                    return ruleResult;
                }

                headerInfo.Rows[0]["taker"] = userId;
                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                LogRuleError(ex.ToString());
                ruleResult.Success = true;
                ruleResult.Message = "QTO order taker default failed. This error has been logged. Please contact the Bus App Team.\r\n\r\n- asi_oe_qto_taker_t5";
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t5);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow -- the user-facing RuleResult.Message still reports the original error.
            }
        }

        public override string GetDescription()
        {
            return "Sets the order taker to the logged-in P21 user on the RMB Convert to Order path, overriding the original quote creator.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t5);
        }
    }
}
