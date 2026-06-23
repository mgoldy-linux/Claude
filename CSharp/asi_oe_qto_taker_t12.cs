// ============================================================
// asi_oe_qto_taker_t12.cs
// ============================================================
// Description : STEP 1 — confirm order_no is captured correctly
//               in Workflow/Save/Multi-Row context before adding
//               any taker logic. Logs order_no to business_rule_log.
// Registration: Workflow / Save / Order Entry
//               Multi-Row: CHECKED  (REQUIRED — rule will throw otherwise)
// Field Selector: quote (checked)
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoTaker_t12
{
    public class asi_oe_qto_taker_t12 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string orderNo = "(not found)";

            try
            {
                // order_no lives in d_dw_oe_line_dataentry, not d_oe_header
                DataTable lineTable = this.Data.Set.Tables["d_dw_oe_line_dataentry"];
                if (lineTable != null && lineTable.Rows.Count > 0)
                    orderNo = lineTable.Rows[0].Field<string>("order_no") ?? "(null)";

                LogDiagnostic("order_no=" + orderNo);

                ruleResult.Success = true;
                ruleResult.Message = "T12 order_no=" + orderNo;
            }
            catch (Exception ex)
            {
                LogDiagnostic("EXCEPTION order_no=" + orderNo + "\r\n" + ex);
                ruleResult.Success = true;
                ruleResult.Message = "T12 error: " + ex.Message;
            }

            return ruleResult;
        }

        private void LogDiagnostic(string details)
        {
            try
            {
                const string sql =
                    @"INSERT INTO business_rule_log
                        (user_id, log_action, rule_name, rule_assembly_name, run_type,
                         return_value, return_message,
                         date_created, created_by, date_last_modified, last_maintained_by)
                      VALUES
                        (@User, 'Error', @Rule, @Asm, 'Synchronous (Internal)',
                         'Diagnostic', @Msg,
                         GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand cmd = new SqlCommand(sql, P21SqlConnection))
                {
                    string userId = this.Session != null ? this.Session.UserID : "unknown";
                    cmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    cmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t12);
                    cmd.Parameters.Add("@Asm",  SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    cmd.Parameters.Add("@Msg",  SqlDbType.VarChar, 8000).Value = details;
                    cmd.ExecuteNonQuery();
                }
            }
            catch { }
        }

        public override string GetName() { return nameof(asi_oe_qto_taker_t12); }

        public override string GetDescription()
        {
            return "STEP 1 DIAGNOSTIC: Captures order_no from d_dw_oe_line_dataentry and logs it. Multi-Row must be checked.";
        }
    }
}
