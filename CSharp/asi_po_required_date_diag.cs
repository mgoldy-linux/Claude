// =============================================================================
// asi_po_required_date_diag
// Fires on: pohdrpostupdate (business_rule_event_uid = 9, "Purchase Order Update")
//
// Purpose: Diagnostic rule for SA-46321 -- pohdrpostupdate's field shape has not
//          been confirmed empirically. Dumps whatever Data.Set exposes (multi-row
//          shape, tables/columns/rows) AND attempts Data.Fields (single-row shape)
//          separately, logging both outcomes to business_rule_log. Whichever one
//          doesn't throw tells us which access pattern the real rule must use, and
//          the dumped table/column names tell us how to find po_no, vendor_id,
//          location_id and order_date on this event.
//
//          THROWAWAY -- not meant to ship. No _tN suffix per convention for
//          diagnostic-only rules (see feedback_p21_rule_naming_diag_no_suffix).
//
// Output: business_rule_log (log_action='Error', return_value='Diagnostic')
//         WHERE rule_name = 'asi_po_required_date_diag'
//
// Version History:
//   Initial -- dump Data.Set + Data.Fields shape for pohdrpostupdate
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_po_required_date_diag
{
    public class asi_po_required_date_diag : P21.Extensions.BusinessRule.Rule
    {
        private const int MaxRowsPerTable = 5;

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            StringBuilder sb = new StringBuilder();

            sb.AppendLine("=== pohdrpostupdate diagnostic capture (SA-46321) ===");
            sb.AppendLine("Captured: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff"));

            // Multi-row shape: this.Data.Set
            try
            {
                DataSet ds = this.Data.Set;
                if (ds == null)
                {
                    sb.AppendLine();
                    sb.AppendLine("Data.Set is null.");
                }
                else
                {
                    sb.AppendLine();
                    sb.AppendLine("Data.Set: " + ds.Tables.Count + " table(s)");

                    foreach (DataTable table in ds.Tables)
                    {
                        sb.AppendLine();
                        sb.AppendLine("TABLE: " + table.TableName + "  (" + table.Rows.Count + " row(s), " + table.Columns.Count + " column(s))");

                        foreach (DataColumn col in table.Columns)
                            sb.AppendLine("  COLUMN: " + col.ColumnName + " (" + col.DataType.Name + ")");

                        int rowNo = 0;
                        foreach (DataRow row in table.Rows)
                        {
                            sb.AppendLine("  Row " + rowNo + ":");
                            foreach (DataColumn col in table.Columns)
                            {
                                string value = row.IsNull(col) ? "(null)" : row[col].ToString();
                                sb.AppendLine("    " + col.ColumnName + " = " + value);
                            }
                            rowNo++;
                            if (rowNo >= MaxRowsPerTable)
                            {
                                sb.AppendLine("  ... (truncated after " + MaxRowsPerTable + " rows)");
                                break;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                sb.AppendLine();
                sb.AppendLine("Data.Set access failed: " + ex.Message);
            }

            // Single-row shape: this.Data.Fields
            try
            {
                sb.AppendLine();
                sb.AppendLine("Data.Fields:");
                int fieldCount = 0;
                foreach (DataField field in this.Data.Fields)
                {
                    sb.AppendLine("  FIELD: " + field.FieldName
                        + " (Table=" + field.TableName + ", Column=" + field.ColumnName + ")"
                        + " = " + (field.FieldValue ?? "(null)"));
                    fieldCount++;
                }
                sb.AppendLine("  (" + fieldCount + " field(s))");
            }
            catch (Exception ex)
            {
                sb.AppendLine();
                sb.AppendLine("Data.Fields access failed: " + ex.Message);
            }

            LogCapture(sb.ToString());

            ruleResult.Success = true;
            return ruleResult;
        }

        // Logs the capture to the native business_rule_log table (queryable,
        // no kb_ dependency) rather than a custom diag table -- per
        // br-error-logging-standard. return_value='Diagnostic' distinguishes
        // this from a genuine error row.
        private void LogCapture(string details)
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_po_required_date_diag);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow -- a logging failure must never break the PO save this rule is riding on.
            }
        }

        public override string GetDescription() =>
            "DIAGNOSTIC ONLY (SA-46321): dumps the Data.Set/Data.Fields shape of pohdrpostupdate to business_rule_log. Not for production use.";

        public override string GetName() =>
            nameof(asi_po_required_date_diag);
    }
}
