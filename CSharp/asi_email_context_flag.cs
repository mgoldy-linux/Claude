// ============================================================
// asi_email_context_flag.cs
// ============================================================
// Description : Records, per user, whether the email window about to open
//               is for an Order Acknowledgment. Writes/updates a single
//               row in asi_email_context_flag (see
//               Create-asi-email-context-flag.sql) every time it fires --
//               not just when it's an Order Ack -- so a stale "true" can
//               never leak into a later, unrelated email for the same
//               user. asi_oe_email_close_diag (OK button on
//               w_email_response) reads this row to decide whether to
//               append its text, since w_email_response has no
//               form_type/document_nos field exposed to a rule attached to
//               its OK button (confirmed 2026-08-03 -- that window is
//               shared by Order Ack, Packing List Transfer, and other
//               document emails, all using the same cb_ok control).
// Event       : Form Printing Pre-Email Response Window (FormPreEmail,
//               business_rule_event_uid = 24). Fires before EVERY emailed
//               form, not just Order Ack.
// Registration: On-Event rule on FormPreEmail. Field Selector: under
//               EmailDataMisc, select form_type (Selected only -- the
//               event itself is the trigger, no field needs to trigger
//               the rule).
// Structure   : Data.Set only (confirmed for this event in
//               asi_oe_order_ack_custom_message_t3). Table["EmailDataMisc"],
//               1 row, column form_type. Order Acknowledgment's form_type
//               is the exact string 'Order Acknowledgement'.
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-08-03  Bus App Team
//   - Initial version. Built after confirming w_email_response's own
//     Field Selector (cb_ok attach point) has no field that identifies
//     the email's form type -- this rule exists solely to hand that
//     information to asi_oe_email_close_diag via a small shared table
//     instead of a P21 field, since none of w_email_response's real
//     fields are safe to repurpose as a flag.
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_EmailContextFlag
{
    public class asi_email_context_flag : P21.Extensions.BusinessRule.Rule
    {
        private const string OrderAckFormType = "Order Acknowledgement";

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                DataSet ds = this.Data.Set;

                if (ds == null || !ds.Tables.Contains("EmailDataMisc"))
                {
                    LogRuleError("EmailDataMisc table not found in Data.Set. Check the rule's Field Selector.");
                }
                else
                {
                    DataTable table = ds.Tables["EmailDataMisc"];

                    if (table.Rows.Count < 1 || !table.Columns.Contains("form_type"))
                    {
                        LogRuleError("EmailDataMisc missing form_type column or has no rows.");
                    }
                    else
                    {
                        string formType = table.Rows[0]["form_type"] as string ?? string.Empty;
                        bool isOrderAck = formType.Equals(OrderAckFormType, StringComparison.OrdinalIgnoreCase);

                        SetFlag(isOrderAck, formType);
                        LogRuleInfo($"form_type='{formType}' is_order_ack={isOrderAck}");
                    }
                }
            }
            catch (Exception ex)
            {
                LogRuleError("Execute failed: " + ex);
            }

            // Never block the email window from opening -- this rule only
            // records a flag for a later rule to read.
            ruleResult.Success = true;
            return ruleResult;
        }

        // Upserts the one row for this user -- the later cb_ok rule only
        // ever wants the most recent value.
        private void SetFlag(bool isOrderAck, string formType)
        {
            const string upsertSql =
                @"MERGE asi_email_context_flag AS target
                  USING (SELECT @User AS user_id) AS src
                  ON target.user_id = src.user_id
                  WHEN MATCHED THEN
                      UPDATE SET is_order_ack = @IsOrderAck, form_type = @FormType, updated_at = GETDATE()
                  WHEN NOT MATCHED THEN
                      INSERT (user_id, is_order_ack, form_type, updated_at)
                      VALUES (@User, @IsOrderAck, @FormType, GETDATE());";

            using (SqlCommand cmd = new SqlCommand(upsertSql, P21SqlConnection))
            {
                cmd.Parameters.Add("@User", SqlDbType.VarChar, 30).Value = GetUserId();
                cmd.Parameters.Add("@IsOrderAck", SqlDbType.Bit).Value = isOrderAck;
                cmd.Parameters.Add("@FormType", SqlDbType.VarChar, 255).Value = formType;
                cmd.ExecuteNonQuery();
            }
        }

        private string GetUserId()
        {
            return this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                ? this.Session.UserID
                : "unknown";
        }

        private void LogRuleInfo(string details)
        {
            LogRule("Info", "Success", details);
        }

        private void LogRuleError(string details)
        {
            LogRule("Error", "Failure", details);
        }

        // Writes to the P21 native business_rule_log table (not
        // kb_table_br_error_log). Best-effort: a logging failure must never
        // mask or block the real email window from opening.
        private void LogRule(string logAction, string returnValue, string details)
        {
            try
            {
                const string logSql =
                    @"INSERT INTO business_rule_log
                        (user_id, log_action, rule_name, rule_assembly_name, run_type,
                         return_value, return_message,
                         date_created, created_by, date_last_modified, last_maintained_by)
                      VALUES
                        (@User, @Action, @Rule, @Asm, 'Synchronous (Internal)',
                         @Return, @Msg,
                         GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
                {
                    string userId = GetUserId();

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Action", SqlDbType.VarChar, 50).Value = logAction;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_email_context_flag);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Return", SqlDbType.VarChar, 50).Value = returnValue;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow -- logging must never mask or block the real send.
            }
        }

        public override string GetDescription()
        {
            return "Records whether the about-to-open email window is an Order Acknowledgment (via form_type) into asi_email_context_flag, for asi_oe_email_close_diag to read.";
        }

        public override string GetName()
        {
            return nameof(asi_email_context_flag);
        }
    }
}
