// ============================================================
// asi_email_context_flag.cs
// ============================================================
// Description : Records, per user, the context of the email window about to
//               open: whether it is an Order Acknowledgment, and which
//               document (order) it is for. Writes/updates a single row in
//               asi_email_context_flag (see
//               Create-asi-email-context-flag.sql) every time it fires --
//               not just when it's an Order Ack -- so a stale "true" (or a
//               stale order number) can never leak into a later, unrelated
//               email for the same user. Read at the cb_ok attach point on
//               w_email_response by:
//                 * asi_oe_email_close_diag        -- gates its memo append
//                 * asi_oe_order_ack_email_subject -- gates its subject
//                   stamp AND takes the order number from document_nos
//               Both need this table because w_email_response has no
//               form_type/document_nos field exposed to a rule attached to
//               its OK button (confirmed 2026-08-03 -- that window is
//               shared by Order Ack, Packing List Transfer, and other
//               document emails, all using the same cb_ok control).
// Event       : Form Printing Pre-Email Response Window (FormPreEmail,
//               business_rule_event_uid = 24). Fires before EVERY emailed
//               form, not just Order Ack.
// Registration: On-Event rule on FormPreEmail. Field Selector: under
//               EmailDataMisc, select form_type AND document_nos (Selected
//               only -- the event itself is the trigger, no field needs to
//               trigger the rule). Multi-Row = Yes at creation.
//               NOTE: adding document_nos means re-saving this rule in Rule
//               Manager, which REPLACES the whole data-element list
//               (feedback_p21_rule_manager_destroys_data_elements). Snapshot
//               business_rule_data_element before and after, and confirm
//               BOTH columns are present afterwards -- a silently dropped
//               form_type turns every email into "not an Order Ack".
// Structure   : Data.Set only (confirmed for this event in
//               asi_oe_order_ack_custom_message_t3). Table["EmailDataMisc"],
//               1 row, columns form_type + document_nos. Order
//               Acknowledgment's form_type is the exact string
//               'Order Acknowledgement'.
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
// 2026-09-06  Bus App Team
//   - v1.0.0.2 -- now also records document_nos (SA 54321). The 2026-09-06
//     BRR test proved d_dw_email_info.subject at cb_ok is the rep's
//     free-text portion, not the delivered subject line, so
//     asi_oe_order_ack_email_subject cannot parse the order number out of
//     it. This rule already sees document_nos at FormPreEmail, so it hands
//     that over the same way it hands over form_type. Nothing about the
//     is_order_ack behaviour changes; asi_oe_email_close_diag is
//     unaffected and needs no rebuild for this.
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
                        DataRow row = table.Rows[0];

                        string formType = row["form_type"] as string ?? string.Empty;
                        bool isOrderAck = formType.Equals(OrderAckFormType, StringComparison.OrdinalIgnoreCase);

                        // Absent column != blank value (feedback_p21_datawindow_missing_vs_null):
                        // if document_nos was never added to the Field Selector we must say so
                        // loudly, because the subject rule downstream will silently do nothing.
                        bool haveDocCol = table.Columns.Contains("document_nos");
                        string docNos = haveDocCol
                            ? Convert.ToString(row["document_nos"]) ?? string.Empty
                            : string.Empty;

                        SetFlag(isOrderAck, formType, docNos);
                        LogRuleInfo($"form_type='{formType}' is_order_ack={isOrderAck} document_nos='{docNos}'");

                        if (!haveDocCol)
                        {
                            LogRuleError("EmailDataMisc has no document_nos column -- add it to this rule's "
                                + "Field Selector. asi_oe_order_ack_email_subject cannot stamp a subject without it.");
                        }
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

        // Upserts the one row for this user -- the later cb_ok rules only
        // ever want the most recent value. Every field is overwritten on
        // every fire, document_nos included, so a previous email's order
        // number can never be read by a later, unrelated one.
        private void SetFlag(bool isOrderAck, string formType, string documentNos)
        {
            const string upsertSql =
                @"MERGE asi_email_context_flag AS target
                  USING (SELECT @User AS user_id) AS src
                  ON target.user_id = src.user_id
                  WHEN MATCHED THEN
                      UPDATE SET is_order_ack = @IsOrderAck, form_type = @FormType,
                                 document_nos = @DocumentNos, updated_at = GETDATE()
                  WHEN NOT MATCHED THEN
                      INSERT (user_id, is_order_ack, form_type, document_nos, updated_at)
                      VALUES (@User, @IsOrderAck, @FormType, @DocumentNos, GETDATE());";

            using (SqlCommand cmd = new SqlCommand(upsertSql, P21SqlConnection))
            {
                cmd.Parameters.Add("@User", SqlDbType.VarChar, 30).Value = GetUserId();
                cmd.Parameters.Add("@IsOrderAck", SqlDbType.Bit).Value = isOrderAck;
                cmd.Parameters.Add("@FormType", SqlDbType.VarChar, 255).Value = formType;
                cmd.Parameters.Add("@DocumentNos", SqlDbType.VarChar, 255).Value =
                    string.IsNullOrEmpty(documentNos) ? (object)DBNull.Value : documentNos;
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
            return "Records the about-to-open email window's context -- whether it is an Order Acknowledgment (form_type) and which order it is for (document_nos) -- into asi_email_context_flag, for asi_oe_email_close_diag and asi_oe_order_ack_email_subject to read at the cb_ok attach point.";
        }

        public override string GetName()
        {
            return nameof(asi_email_context_flag);
        }
    }
}
