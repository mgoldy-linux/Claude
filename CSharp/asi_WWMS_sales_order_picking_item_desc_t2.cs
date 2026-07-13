// =============================================================================
// asi_WWMS_sales_order_picking_item_desc_t2   (SA 47981)
// Pre-SQL rule for d_ds_oe_pick_ticket_detail_val (WWMS Sales Order Picking)
//
// Purpose:
//   Adds inv_mast.item_desc to the picking-detail SELECT so an on-screen
//   "Item Description" field can be bound to it. inv_mast is ALREADY joined in
//   the base query (ON inv_mast.inv_mast_uid = oe_pick_ticket_detail.inv_mast_uid),
//   so no new join is needed -- we only add the column.
//
// Base SELECT list ends with:
//     ... ,inv_mast.net_weight ,COALESCE(inv_mast.weight, 0) FROM oe_pick_ticket_detail ...
//   We insert  ",inv_mast.item_desc WWMSITEMDESC"  immediately after the COALESCE
//   column. The result column is aliased WWMSITEMDESC -- a unique name that won't
//   collide with orphaned screen-only "item_desc" columns left in the datawindow.
//
// Field-access note:
//   "sql_statement" does NOT exist on this window/version (it threw KeyNotFound).
//   Rather than hard-code a field name, this rule ENUMERATES Data.Fields and
//   locates the field whose value carries the SELECT (matched by a unique anchor).
//   It modifies and writes back to that same field. If no SQL-bearing field is
//   found, it logs the full field list so we can confirm whether Pre-SQL exposes
//   the query via Data.Fields at all.
//
// IMPORTANT (display side):
//   Adding a column to the result set requires the datawindow to have a matching
//   column for the new on-screen field, or P21 may report a column-count mismatch.
//   Add ONE screen-only column with Column Name = WWMSITEMDESC (Alphanumeric,
//   Max Length 255) via DynaChange; P21 maps the injected result column to it BY
//   NAME. Remove any earlier orphaned item_desc screen-only columns first.
//   All WWMS testing is done in P21BusinessRules -- attach, test, and read
//   business_rule_log there.
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_WWMS_sales_order_picking_item_desc_t2
{
    public class asi_WWMS_sales_order_picking_item_desc_t2 : P21.Extensions.BusinessRule.Rule
    {
        // Unique, pick-ticket-independent marker for the picking-detail SELECT.
        private const string Anchor = "COALESCE(inv_mast.weight, 0)";

        // Column to add, aliased to a UNIQUE name so it never collides with any
        // leftover/orphaned screen-only "item_desc" columns lingering in the
        // datawindow buffer. The screen-only column must be named WWMSITEMDESC.
        private const string NewColumn = " ,inv_mast.item_desc WWMSITEMDESC";

        // Idempotency guard -- never inject twice. Keyed on the unique alias.
        private const string Guard = "WWMSITEMDESC";

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                DataField sqlField = FindSqlField();

                if (sqlField == null)
                {
                    // SQL not found in Data.Fields -- dump the field list so we can
                    // see what IS exposed, then pass through (never block picking).
                    LogInfo("NO SQL FIELD FOUND. " + DumpFields());
                    ruleResult.Success = true;
                    return ruleResult;
                }

                string sql = sqlField.FieldValue ?? string.Empty;

                // Already modified? leave it alone.
                if (sql.IndexOf(Guard, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    LogInfo("ALREADY INJECTED (guard hit) on field '" + (sqlField.FieldName ?? "(null)") + "'.");
                    ruleResult.Success = true;
                    return ruleResult;
                }

                int anchorPos = sql.IndexOf(Anchor, StringComparison.OrdinalIgnoreCase);
                if (anchorPos < 0)
                {
                    // Anchor not present -- a different query reached this rule.
                    LogInfo("ANCHOR NOT FOUND in field '" + (sqlField.FieldName ?? "(null)") + "'. SQL=" + sql);
                    ruleResult.Success = true;
                    return ruleResult;
                }

                int insertPos = anchorPos + Anchor.Length;
                string modified = sql.Substring(0, insertPos) + NewColumn + sql.Substring(insertPos);

                sqlField.FieldValue = modified;

                // TEMP DIAGNOSTIC: confirm injection + show the field name and a
                // snippet around the splice so we can verify result-column naming.
                int snipStart = Math.Max(0, insertPos - 60);
                int snipLen = Math.Min(modified.Length - snipStart, 160);
                LogInfo("INJECTED into field '" + (sqlField.FieldName ?? "(null)")
                        + "'. Snippet: ..." + modified.Substring(snipStart, snipLen) + "...");

                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                // Diagnostic only -- do not block the picking window on failure.
                LogInfo("[error] " + ex);
                ruleResult.Success = true;
            }

            return ruleResult;
        }

        // Locate the field carrying the picking SELECT by matching the unique anchor.
        private DataField FindSqlField()
        {
            foreach (DataField field in this.Data.Fields)
            {
                string val;
                try { val = field.FieldValue; }
                catch { continue; }

                if (!string.IsNullOrEmpty(val)
                    && val.IndexOf(Anchor, StringComparison.OrdinalIgnoreCase) >= 0)
                    return field;
            }
            return null;
        }

        // Build a name=value-preview dump of every exposed field (for discovery).
        private string DumpFields()
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            int count = 0;
            foreach (DataField field in this.Data.Fields)
            {
                count++;
                string name = field.FieldName ?? "(null)";
                string val;
                try { val = field.FieldValue ?? "(null)"; }
                catch (Exception fe) { val = "(read err: " + fe.Message + ")"; }
                if (val.Length > 200)
                    val = val.Substring(0, 200) + "...[+" + (val.Length - 200) + "]";
                sb.Append("\r\n[").Append(count).Append("] ").Append(name).Append(" = ").Append(val);
            }
            if (count == 0) sb.Append(" (no fields exposed)");
            return sb.ToString();
        }

        // Best-effort diagnostic write to native business_rule_log.
        private void LogInfo(string details)
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
                        ? this.Session.UserID : "unknown";
                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_WWMS_sales_order_picking_item_desc_t2);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch { /* swallow -- diagnostics must never affect picking */ }
        }

        public override string GetDescription() =>
            "SA 47981: Pre-SQL rule adding inv_mast.item_desc (aliased WWMSITEMDESC) to the WWMS picking-detail SELECT (d_ds_oe_pick_ticket_detail_val) so a screen-only WWMSITEMDESC column can bind to it.";

        public override string GetName() =>
            nameof(asi_WWMS_sales_order_picking_item_desc_t2);
    }
}
