// ============================================================
// asi_oe_order_ack_custom_message_t3.cs
// ============================================================
// Description : Appends a custom message to the body (memo) of Order
//               Acknowledgment emails, leaving a few blank lines above it so
//               the P21 user has room to type their own comments before it.
//               The Email Order Acknowledgment window still displays normally
//               -- the P21 user can enter their own notes and click OK as
//               usual. Our text is pre-filled into the memo box before the
//               window opens (P21 exposes no event that runs after OK, only
//               before), so it always ends up at the bottom of the body.
// Event       : Form Printing Pre-Email Response Window (FormPreEmail,
//               business_rule_event_uid = 24)
// Registration: On-Event rule on that event. Field Selector: under
//               EmailDataMisc select form_type, memo, document_nos
//               (document_nos only used for log context).
// Structure   : Confirmed 2026-07-28 via business_rule_log during P21
//               Business Rules testing -- this event is Data.Set only
//               (EmailDataMisc table, 1 row), never Data.Fields. form_type
//               value confirmed to be the exact string 'Order Acknowledgement'.
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-07-28  Bus App Team  (T1 -> T2)
//   - T1 suppressed the window entirely (display_response_window = "N") so
//     the email sent automatically. That's no longer wanted -- the P21 user
//     needs to see the window and enter their own notes first. REMOVED the
//     display_response_window override; the window now displays normally.
//   - CHANGED form_type match from a loose Contains("order")+Contains("ack")
//     heuristic to an exact match on 'Order Acknowledgement', now that T1's
//     test run confirmed the real value.
//   - REMOVED TryProcessViaDataFields() fallback and DumpStructure() --
//     T1's test run confirmed this event is Data.Set only; the speculative
//     single-row fallback path never fired and is dead code.
// 2026-07-28  Bus App Team  (T2 -> T3)
//   - T2 confirmed working (window displays normally, no auto-send). ADDED
//     a few leading blank lines before the message so the user has visible
//     room to type their own comments above it, instead of the message
//     landing immediately at the top of an otherwise-empty box.
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeOrderAckCustomMessage_t3
{
    public class asi_oe_order_ack_custom_message_t3 : P21.Extensions.BusinessRule.Rule
    {
        // TEST MESSAGE -- swap for the real message once the plumbing is confirmed.
        private const string CustomMessage =
            "Life is basically just opening 40 tabs in your brain at once, having 5 of them freeze, " +
            "hearing music playing from somewhere but you can't find where, and realizing your battery is at 12%.";

        // Blank lines left above the message for the user's own comments.
        private const string LeadingBlankLines = "\r\n\r\n\r\n";

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

                    if (table.Rows.Count < 1 || !table.Columns.Contains("form_type") || !table.Columns.Contains("memo"))
                    {
                        LogRuleError("EmailDataMisc missing expected columns (form_type/memo) or has no rows.");
                    }
                    else
                    {
                        DataRow row = table.Rows[0];
                        string formType = row["form_type"] as string ?? string.Empty;
                        string docNos = table.Columns.Contains("document_nos") ? (row["document_nos"] as string ?? string.Empty) : string.Empty;
                        bool isOrderAck = formType.Equals("Order Acknowledgement", StringComparison.OrdinalIgnoreCase);

                        LogRuleInfo($"form_type='{formType}' matched={isOrderAck} document_nos='{docNos}'");

                        if (isOrderAck)
                        {
                            string existingMemo = row["memo"] as string ?? string.Empty;
                            row["memo"] = AppendCustomMessage(existingMemo);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogRuleError(ex.ToString());
            }

            // Always succeed -- this rule only adds text to the email body.
            // A failure here must never block the real Order Ack from sending.
            ruleResult.Success = true;
            return ruleResult;
        }

        // Outlook merges single-newline text onto one line; a blank line
        // keeps the appended message visually separate in the recipient's
        // email body (same trap as the P21 Alert plain-text body). The extra
        // leading blank lines give the user room to type their own comments
        // above the message when the window opens.
        private string AppendCustomMessage(string existingMemo)
        {
            return (existingMemo ?? string.Empty) + LeadingBlankLines + CustomMessage;
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
        // mask or block the original email send.
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
                    string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                        ? this.Session.UserID
                        : "unknown";

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Action", SqlDbType.VarChar, 50).Value = logAction;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_order_ack_custom_message_t3);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Return", SqlDbType.VarChar, 50).Value = returnValue;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow -- logging must never mask or block the original email send.
            }
        }

        public override string GetDescription()
        {
            return "Appends a custom message to the bottom of the Order Acknowledgment email body; the window still displays normally for the P21 user.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_order_ack_custom_message_t3);
        }
    }
}
