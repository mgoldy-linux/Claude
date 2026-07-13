// =============================================================================
// asi_wwms_picking_sql_logger
//
// THROWAWAY DIAGNOSTIC RULE -- not for permanent deployment.
//
// Purpose:
//   Captures the EXACT SQL string that P21 generates for the WWMS Sales Order
//   Picking datawindow, so we can build reliable string anchors for the real
//   Pre-SQL "add item description" rule (SA 47981).
//
//   A Pre-SQL rule receives the query in Data.Fields["sql_statement"].FieldValue
//   BEFORE it executes. That raw text -- exact casing, whitespace, line breaks --
//   is what our production rule must match. The web-client DW debugger / Object
//   Viewer zoom is NotImplemented on WWMS, so we capture the string here instead.
//
// Behavior:
//   - Reads sql_statement, writes it verbatim to business_rule_log
//     (log_action = 'Info', rule_name = 'asi_wwms_picking_sql_logger').
//   - Does NOT modify the SQL -- passes through unchanged so the picking window
//     works normally while attached.
//   - Logging is best-effort; a logging failure never blocks the query.
//
// Retrieve the captured SQL:
//   SELECT TOP 50 date_created, return_message
//   FROM   business_rule_log
//   WHERE  rule_name = 'asi_wwms_picking_sql_logger'
//   ORDER  BY date_created DESC;
//
// P21 setup:
//   Window    : WWMS Sales Order Picking
//   Datawindow: <the picking grid/detail dw -- shown in the Create Business Rule dialog>
//   Rule type : Pre-SQL
//   Rule name : asi_wwms_picking_sql_logger
//
//   REMOVE / INACTIVATE this rule once the SELECT has been captured.
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_wwms_picking_sql_logger
{
    public class asi_wwms_picking_sql_logger : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                // DISCOVERY MODE: "sql_statement" is not the field name on this
                // window/version (it threw KeyNotFound). Enumerate every field
                // exposed to the rule so we can identify which one holds the SQL.
                // For each field we capture: name + a preview of its value.
                System.Text.StringBuilder sb = new System.Text.StringBuilder();
                sb.Append("FIELD DUMP (asi_wwms_picking_sql_logger): ");

                int count = 0;
                foreach (DataField field in this.Data.Fields)
                {
                    count++;
                    string name = field.FieldName ?? "(null)";

                    string val;
                    try { val = field.FieldValue ?? "(null)"; }
                    catch (Exception fe) { val = "(read err: " + fe.Message + ")"; }

                    // Trim long values so one field can't blow the 8000-char budget;
                    // a SQL-bearing field will still be obvious from its preview.
                    if (val.Length > 300)
                        val = val.Substring(0, 300) + "...[+" + (val.Length - 300) + " chars]";

                    sb.Append("\r\n[").Append(count).Append("] ").Append(name)
                      .Append(" = ").Append(val);
                }

                if (count == 0)
                    sb.Append("\r\n(no fields exposed to this rule)");

                LogSql(sb.ToString());

                // Pass through untouched -- do NOT modify the picking query.
                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                // Never block the window over a diagnostic capture.
                LogSql("[capture error] " + ex);
                ruleResult.Success = true;
            }

            return ruleResult;
        }

        // Best-effort write of the captured SQL to the native business_rule_log.
        private void LogSql(string sql)
        {
            try
            {
                const string logSql =
                  @"INSERT INTO business_rule_log
                      (user_id, log_action, rule_name, rule_assembly_name, run_type,
                       return_value, return_message,
                       date_created, created_by, date_last_modified, last_maintained_by)
                    VALUES
                      (@User, 'Info', @Rule, @Asm, 'Synchronous (Internal)',
                       'Success', @Msg,
                       GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
                {
                    string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                        ? this.Session.UserID
                        : "unknown";

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_wwms_picking_sql_logger);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        sql.Length > 8000 ? sql.Substring(0, 8000) : sql;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow -- diagnostic logging must never affect the picking window.
            }
        }

        public override string GetDescription() =>
            "DIAGNOSTIC (SA 47981): logs the raw WWMS Sales Order Picking SELECT to business_rule_log for anchor analysis. Passes the SQL through unchanged. Remove after capture.";

        public override string GetName() =>
            nameof(asi_wwms_picking_sql_logger);
    }
}
