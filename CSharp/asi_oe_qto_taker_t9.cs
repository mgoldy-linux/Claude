// ============================================================
// asi_oe_qto_taker_t9.cs
// ============================================================
// Description : DIAGNOSTIC — enumerates all Data.Fields available in the
//               Workflow/Save context on Order Entry. T8 failed with
//               KeyNotFoundException on projected_order; Field Selector
//               shows only "quote". This rule logs every field name,
//               alias, table, column, and value to identify what is
//               actually accessible and what "quote" contains.
// Event       : Workflow / Save / Order Entry
// Field Selector: select "quote" (only available field)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-22  Bus App Team  (T8 -> T9)
//   - T8: KeyNotFoundException on projected_order; order_no empty
//   - T9: enumerate Data.Fields to find what is actually available
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeQtoTaker_t9
{
    public class asi_oe_qto_taker_t9 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("Data.Fields in Workflow/Save/OrderEntry context:");

                int i = 0;
                foreach (DataField field in this.Data.Fields)
                {
                    sb.AppendLine(string.Format(
                        "  [{0}] FieldName={1}  FieldAlias={2}  TableName={3}  ColumnName={4}  FieldValue={5}",
                        i++,
                        field.FieldName   ?? "(null)",
                        field.FieldAlias  ?? "(null)",
                        field.TableName   ?? "(null)",
                        field.ColumnName  ?? "(null)",
                        field.FieldValue  ?? "(null)"));
                }

                if (i == 0)
                    sb.AppendLine("  (no fields found)");

                string output = sb.ToString();
                LogDiagnostic(output);

                ruleResult.Success = true;
                ruleResult.Message = output;
            }
            catch (Exception ex)
            {
                ruleResult.Success = true;
                ruleResult.Message = "T9 diagnostic error: " + ex.Message;
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

                    logCmd.Parameters.Add("@User",  SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule",  SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t9);
                    logCmd.Parameters.Add("@Asm",   SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg",   SqlDbType.VarChar, 8000).Value =
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
            return "DIAGNOSTIC: Enumerates all Data.Fields in the Workflow/Save/OrderEntry context to identify available field names and values.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_taker_t9);
        }
    }
}
