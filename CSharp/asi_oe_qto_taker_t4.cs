// ============================================================
// asi_oe_qto_taker_t4.cs
// ============================================================
// Description : When the Quote to Order window opens, sets the taker field
//               to the logged-in P21 user so the converting user is recorded
//               as the order taker rather than the original quote creator.
// Event       : qtowindowopening  (business_rule_event_uid = 41)
// Data.Set    : Table "HeaderInfo", column "taker", row 0
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-16  Bus App Team
//   - T1: used Data.Fields -- throws in multi-row rule context
//   - T2: attempted field enumeration -- same error
//   - T3: diagnostic; confirmed Data.Set structure:
//         HeaderInfo[taker] = current quote creator (e.g. MJUSTICE)
//   - T4: production rule -- sets HeaderInfo[taker] to session user
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t4
{
    public class asi_oe_qto_taker_t4 : P21.Extensions.BusinessRule.Rule
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
                    LogRuleError("Data.Set is null or does not contain the HeaderInfo table. The qtowindowopening event structure may have changed.");
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
                ruleResult.Message = "QTO order taker default failed. This error has been logged. Please contact the Bus App Team.\r\n\r\n- asi_oe_qto_taker_t4";
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t4);
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
            return "Sets the order taker to the logged-in P21 user when the Quote to Order window opens, overriding the original quote creator.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t4);
        }
    }
}
