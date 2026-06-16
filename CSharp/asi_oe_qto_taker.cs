// ============================================================
// asi_oe_qto_taker.cs
// ============================================================
// Description : Defaults order_taker to the logged-in P21 user when the
//               Quote to Order window opens, so the user does not have to
//               manually set it before converting.
// Event       : qtowindowopening  (business_rule_event_uid = 41)
// Registration: Event rule on qtowindowopening; add order_taker as an
//               editable field in the rule's field configuration.
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-16  Bus App Team
//   - Initial version
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker
{
    public class asi_oe_qto_taker : P21.Extensions.BusinessRule.Rule
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

                DataField takerField = GetTakerField();
                if (takerField == null)
                {
                    LogRuleError("taker field not found in rule data. Ensure 'taker' (HeaderInfo > taker) is selected in the rule's Field Selector in P21.");
                    ruleResult.Success = true;
                    return ruleResult;
                }

                takerField.FieldValue = userId;
                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                LogRuleError(ex.ToString());
                ruleResult.Success = true;
                ruleResult.Message = "QTO order taker default failed. This error has been logged. Please contact the Bus App Team.\r\n\r\n- asi_oe_qto_taker";
            }

            return ruleResult;
        }

        // Enumerates Data.Fields to find the taker field regardless of whether
        // the event registers it as "taker" or with a table prefix.
        private DataField GetTakerField()
        {
            foreach (DataField field in this.Data.Fields)
            {
                if (field.FieldName != null
                    && (field.FieldName.Equals("taker", StringComparison.OrdinalIgnoreCase)
                        || field.FieldName.EndsWith(".taker", StringComparison.OrdinalIgnoreCase)))
                    return field;
            }
            return null;
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker);
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
            return "Defaults order_taker to the logged-in P21 user when the Quote to Order window opens.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker);
        }
    }
}
