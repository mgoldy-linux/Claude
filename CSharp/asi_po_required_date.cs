// =============================================================================
// asi_po_required_date
// Fires on: pohdrpostupdate (business_rule_event_uid = 9, "Purchase Order Update")
//
// SA-46321: sets PO line + header Required Date once, then freezes both.
//   - Line: order_date + Published Lead Time (fallback Average Lead Time),
//     slid forward past weekends/holidays.
//   - Header: MAX(line Required Date), set once initial lines exist.
// All computation lives in dbo.asi_proc_po_required_date -- this rule is a
// thin wrapper: pull po_no (Data.Set["POHeader"]["key_value"], confirmed via
// asi_po_required_date_diag) and call the proc. Freeze state is tracked in
// asi_table_po_header_required_date_frozen / asi_table_po_line_required_date_frozen,
// NOT via IS NULL guards on po_hdr.date_due / po_line.required_date -- both
// columns are already non-null the instant P21 creates the row (confirmed
// empirically 2026-08-06), so IS NULL can't signal "not yet computed."
//
// pohdrpostupdate is Data.Set-only (multi-row) -- Data.Fields throws
// "cannot be accessed in a multi-row rule" (confirmed via the diagnostic).
//
// Version History:
//   Initial -- SA-46321
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_po_required_date
{
    public class asi_po_required_date : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                DataSet ds = this.Data.Set;
                if (ds == null || !ds.Tables.Contains("POHeader") || ds.Tables["POHeader"].Rows.Count < 1)
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                object rawKeyValue = ds.Tables["POHeader"].Rows[0]["key_value"];
                decimal poNo;
                if (rawKeyValue == null || rawKeyValue == DBNull.Value
                    || !decimal.TryParse(rawKeyValue.ToString(), out poNo))
                {
                    LogRuleError("key_value missing or not numeric: " + (rawKeyValue == null ? "(null)" : rawKeyValue.ToString()));
                    ruleResult.Success = true;
                    return ruleResult;
                }

                using (SqlCommand cmd = new SqlCommand("dbo.asi_proc_po_required_date", P21SqlConnection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@PONo", SqlDbType.Decimal).Value = poNo;
                    cmd.Parameters["@PONo"].Precision = 19;
                    cmd.Parameters["@PONo"].Scale = 0;
                    cmd.ExecuteNonQuery();
                }

                ruleResult.Success = true;
                return ruleResult;
            }
            catch (Exception ex)
            {
                // Never fail the PO save over this -- log and let it through.
                LogRuleError(ex.ToString());
                ruleResult.Success = true;
                return ruleResult;
            }
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_po_required_date);
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
            "SA-46321: sets PO line + header Required Date once (order date + Published Lead Time, slid past weekends/holidays), then freezes both against later edits.";

        public override string GetName() =>
            nameof(asi_po_required_date);
    }
}
