// ============================================================
// asi_oe_qto_taker_t2.cs
// ============================================================
// Description : DIAGNOSTIC — dumps all field names visible in this.Data.Fields
//               when the QTO Window Opening event fires. Use to confirm the
//               exact field name for taker before writing the production rule.
//               Check business_rule_log or the test tool message for output.
// Event       : qtowindowopening  (business_rule_event_uid = 41)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-16  Bus App Team  (T1 → T2)
//   - T1: GetTakerField() returned null — taker not in Data.Fields
//   - T2: Enumerate and log all available field names to diagnose
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeQtoTaker_t2
{
    public class asi_oe_qto_taker_t2 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("Data.Fields available in qtowindowopening:");

                int i = 0;
                foreach (DataField field in this.Data.Fields)
                {
                    sb.AppendLine(string.Format("  [{0}] FieldName={1}  FieldAlias={2}  TableName={3}  ColumnName={4}  FieldValue={5}",
                        i++,
                        field.FieldName ?? "(null)",
                        field.FieldAlias ?? "(null)",
                        field.TableName ?? "(null)",
                        field.ColumnName ?? "(null)",
                        field.FieldValue ?? "(null)"));
                }

                if (i == 0)
                    sb.AppendLine("  (no fields found — check Field Selector: select at least one field)");

                string output = sb.ToString();

                LogDiagnostic(output);

                ruleResult.Success = true;
                ruleResult.Message = output;
            }
            catch (Exception ex)
            {
                ruleResult.Success = true;
                ruleResult.Message = "T2 diagnostic error: " + ex.Message;
            }

            return ruleResult;
        }

        private void LogDiagnostic(string details)
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
                    string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                        ? this.Session.UserID
                        : "unknown";

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t2);
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
            return "DIAGNOSTIC: Lists all Data.Fields available in the qtowindowopening event.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t2);
        }
    }
}
