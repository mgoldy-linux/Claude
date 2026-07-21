// =============================================================================
// asi_WWMS_sales_order_picking_item_desc_populate_t2   (SA 47981)
// Converter rule for the WWMS Sales Order Picking detail
// (datawindow d_ds_oe_pick_ticket_detail_val)
//
// Purpose:
//   Populate the DynaChange screen-only column "wwmsitemdesc" with the item's
//   description, per detail row, at display time. This REPLACES the Pre-SQL
//   injection approach (asi_WWMS_sales_order_picking_item_desc_t3): a screen-only
//   column is not fed from the SELECT result set, so injecting the column never
//   filled it regardless of name/case. Here we set the field value directly.
//
// Rule type / attachment:
//   Create Business Rule -> RULE TYPE = Converter.
//   Attach to the ITEM_ID column (not wwmsitemdesc): item_id has a value on every
//   row, so the converter is guaranteed to fire per row; the empty screen-only
//   column might never trigger a converter. We read item_id / inv_mast_uid from
//   the current row and write the description into wwmsitemdesc.
//
// Lookup (proven):
//   SELECT item_desc FROM inv_mast WHERE inv_mast_uid = @uid   (or item_id = @id)
//
// FIRST-RUN DISCOVERY:
//   On every run this logs the row's Data.Fields to business_rule_log, so the
//   first execution confirms the exact field names (item_id / inv_mast_uid /
//   wwmsitemdesc) and whether wwmsitemdesc is writable. Trim the DumpFields call
//   to a one-line confirmation once the names are verified.
//
// Notes:
//   - P21 targets C# 7.3 (no C# 8+ syntax).
//   - Read values with .FieldValue; never block picking on failure.
//   - All WWMS testing is done in P21BusinessRules.
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_WWMS_sales_order_picking_item_desc_populate_t2
{
    public class asi_WWMS_sales_order_picking_item_desc_populate_t2 : P21.Extensions.BusinessRule.Rule
    {
        // Screen-only column to fill. P21 auto-prefixes DynaChange screen-only
        // columns with "ufc_p21soc_" -- the Column Name entered as "wwmsitemdesc"
        // is exposed on the row as "ufc_p21soc_wwmsitemdesc" (confirmed via the
        // first-run Data.Fields dump). This prefix -- NOT case -- is why the
        // earlier Pre-SQL "wwmsitemdesc" alias never populated the field.
        private const string TargetField = "ufc_p21soc_wwmsitemdesc";

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                // --- DISCOVERY: dump the row so we learn the real field names ---
                LogInfo("ROW FIELDS: " + DumpFields());

                // Prefer inv_mast_uid (exact key); fall back to item_id.
                DataField uidField = FindField("inv_mast_uid");
                DataField idField = FindField("item_id");
                DataField target = FindField(TargetField);

                if (target == null)
                {
                    LogInfo("TARGET '" + TargetField + "' NOT on row -- cannot populate.");
                    ruleResult.Success = true;
                    return ruleResult;
                }

                string desc = null;

                if (uidField != null && !string.IsNullOrEmpty(uidField.FieldValue))
                    desc = LookupDesc("inv_mast_uid", uidField.FieldValue);
                else if (idField != null && !string.IsNullOrEmpty(idField.FieldValue))
                    desc = LookupDesc("item_id", idField.FieldValue);
                else
                {
                    LogInfo("NO item key on row (inv_mast_uid/item_id both empty).");
                    ruleResult.Success = true;
                    return ruleResult;
                }

                if (desc == null)
                {
                    LogInfo("LOOKUP returned no row for this item.");
                    ruleResult.Success = true;
                    return ruleResult;
                }

                target.FieldValue = desc;
                LogInfo("SET " + TargetField + " = '" + desc + "'.");

                ruleResult.Success = true;
            }
            catch (Exception ex)
            {
                LogInfo("[error] " + ex);
                ruleResult.Success = true;
            }

            return ruleResult;
        }

        // Look up inv_mast.item_desc by the given key column (whitelisted names only).
        private string LookupDesc(string keyColumn, string keyValue)
        {
            string col = keyColumn == "inv_mast_uid" ? "inv_mast_uid" : "item_id";
            string sql = "SELECT item_desc FROM inv_mast WHERE " + col + " = @key";

            using (SqlCommand cmd = new SqlCommand(sql, P21SqlConnection))
            {
                cmd.Parameters.Add("@key", SqlDbType.VarChar, 40).Value = keyValue;
                object result = cmd.ExecuteScalar();
                return (result == null || result == DBNull.Value) ? null : result.ToString();
            }
        }

        // Case-insensitive field lookup by name.
        private DataField FindField(string name)
        {
            foreach (DataField field in this.Data.Fields)
            {
                if (field.FieldName != null
                    && string.Equals(field.FieldName, name, StringComparison.OrdinalIgnoreCase))
                    return field;
            }
            return null;
        }

        // Name=value preview of every exposed field (discovery aid).
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
                if (val.Length > 120)
                    val = val.Substring(0, 120) + "...[+" + (val.Length - 120) + "]";
                sb.Append("\r\n[").Append(count).Append("] ").Append(name).Append(" = ").Append(val);
            }
            if (count == 0) sb.Append(" (no fields exposed -- row may be in Data.Set, not Data.Fields)");
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_WWMS_sales_order_picking_item_desc_populate_t2);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch { /* swallow -- diagnostics must never affect picking */ }
        }

        public override string GetDescription() =>
            "SA 47981: Converter rule populating the screen-only wwmsitemdesc column with inv_mast.item_desc per pick-detail row (replaces the Pre-SQL injection approach).";

        public override string GetName() =>
            nameof(asi_WWMS_sales_order_picking_item_desc_populate_t2);
    }
}
