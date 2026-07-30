// ============================================================
// asi_oe_email_close_diag.cs
// ============================================================
// Description : DIAGNOSTIC ONLY, but now performs a real (small, clearly
//               marked, reversible) modification: appends a distinctive
//               test marker to `memo` when the Email Order Acknowledgment
//               window closes via OK. This is the decisive test for one
//               open question: does a write made here actually reach the
//               email that gets sent, or is it too late? Compare the
//               logged "New memo" value against the body of the actually-
//               delivered email for the same test send.
// Event       : On-Demand rule attached to the OK button (cb_ok) on window
//               w_email_response ("Email Order Acknowledgment"). Not tied
//               to a published event (business_rule_event_uid = NULL).
// Registration: Confirmed live 2026-07-29 (business_rule_uid = 173):
//                 - multirow_flag = Y  -> Data.Set is accessible; Data.Fields
//                   now throws ("cannot be accessed in a multi-row rule") --
//                   mutually exclusive, same as qtowindowopening/FormPreEmail.
//                 - run_type = Asynchronous, EVEN with multirow_flag = Y.
//                   The earlier assumption that Run Type is freely
//                   selectable to Synchronous for this attach-to-button
//                   flow (based on kb_Order_Validator_v2 being Synchronous +
//                   multi-row) does not hold here -- that rule may use a
//                   different registration path. Do not assume Async here
//                   means "too late": RuleManager itself logs a structured
//                   Return payload after Execute() containing the (possibly
//                   modified) field values, which implies the framework may
//                   feed the modified dataset back to the caller regardless
//                   of the Async label. This version exists to test that
//                   empirically instead of assuming either way.
//               Data.Set shape confirmed: Table "Buttons" (column cb_ok,
//               the trigger), Table "d_dw_email_info" (column memo, 1 row
//               each).
// Safety      : Appends a short, obviously-diagnostic marker string to
//               `memo` -- reversible, does not suppress the window, does
//               not change recipients, does not block the send either way
//               (RuleResult.Success is always true). Even so, per the
//               2026-07-28 incident (see feedback_p21_test_env_live_email),
//               test only against an order where you control the recipient
//               address -- P21BusinessRules has real customer data and a
//               live SMTP path.
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-07-29  Bus App Team
//   - Initial version (read-only, Data.Set/Data.Fields dump).
// 2026-07-29  Bus App Team
//   - First test run: registered Asynchronous + single-row by default;
//     Data.Set threw "cannot be accessed in a non-multi-row rule."
// 2026-07-29  Bus App Team
//   - Re-registered with multirow_flag = Y (uid changed 172 -> 173).
//     Data.Set now works; Data.Fields now throws as expected (mutually
//     exclusive). run_type stayed Asynchronous regardless. Rewrote as an
//     actual write test: appends TestMarker to memo via Data.Set and logs
//     before/after, to empirically settle whether the write reaches the
//     real outbound email.
// 2026-07-29  Bus App Team
//   - CONFIRMED: TestMarker showed up in the actual delivered .msg body
//     (verified via Outlook COM). Async label does not mean too-late for
//     this attach path. Added a READ-ONLY inspection of attachment,
//     attachment_fullname, b_add_attachments (seen in the original
//     FormPreEmail Field Selector list, under d_dw_email_info) ahead of a
//     user request to attach an image. Logging only, no write yet -- we
//     don't know if attachment_fullname is the live generated PDF's path,
//     which we must not clobber. Requires adding those 3 fields as
//     Selected in the Field Selector before they'll appear in Data.Set.
// 2026-07-29  Bus App Team
//   - Confirmed via a real test send: attachment/attachment_fullname/
//     b_add_attachments were all blank -- no live PDF path sitting there
//     to clobber, so these look like a separate "optionally attach one
//     more file" mechanism, not the same pipeline that attaches the
//     generated Order Ack PDF. Added an actual write attempt: sets
//     attachment_fullname/attachment to TestImagePath and b_add_attachments
//     to true (dataType="!" like cb_ok, so likely a real bool column, not a
//     string -- wrapped in its own try/catch in case that guess is wrong).
//     Logs before/after. Check the real delivered email's Attachments
//     collection (not just Body) to confirm.
// 2026-07-29  Bus App Team
//   - CONFIRMED DEAD END: the write caused a PowerBuilder-level "Invalid
//     DataWindow row/column specified" error in u_dw_core.setcolumn --
//     outside this rule's try/catch, so it can't be suppressed from here.
//     Root cause was already visible in the prior test's Return XML:
//     attachment/attachment_fullname/b_add_attachments all report
//     readOnly="Y" (same as cb_ok), unlike memo/from_name (readOnly="N").
//     Removed the write attempt (TryAttachTestImage) entirely -- these 3
//     fields cannot be used to attach a file via this rule. Left the
//     read-only dump in place for reference. See
//     feedback_p21_readonly_field_writes.md for the general lesson.
// 2026-07-30  Bus App Team
//   - Re-added the attachment write attempt at the user's request, for a
//     firsthand confirmation test -- image moved to a UNC path
//     (\\asp21fs1.ahi.local\BusinessRules\Test-image.png). Expect the SAME
//     "Invalid DataWindow row/column specified" error: the diagnosed cause
//     was readOnly="Y" on the field itself, not file location, so a
//     different path should not change the outcome. Also added an HTML
//     tag test in memo (HtmlTestTag) to answer a separate question: does
//     P21 render memo as HTML or plain text? Check the delivered email's
//     HTMLBody (not just .Body) -- if the tag renders (bold text) HTML is
//     supported; if it shows literal "<b>...</b>" it's plain text only.
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;

namespace asi_OeEmailCloseDiag
{
    public class asi_oe_email_close_diag : P21.Extensions.BusinessRule.Rule
    {
        // Distinctive and safe -- if this text shows up in the delivered
        // email body, writes made here reach the real send.
        private const string TestMarker = "\r\n\r\n[DIAG-MARKER-7A29 -- asi_oe_email_close_diag test write]";

        // Plain <b> tag -- if the delivered email's HTMLBody shows this
        // rendered bold, memo supports HTML. If it shows the literal tag
        // text, memo is plain-text only.
        private const string HtmlTestTag = "\r\n\r\n<b>[HTML-TEST-9F21]</b>";

        // Moved to a UNC path per user request (was a local OneDrive path).
        // Expected to fail the same way regardless -- the write target
        // fields are readOnly="Y", which is not affected by file location.
        private const string TestImagePath = @"\\asp21fs1.ahi.local\BusinessRules\Test-image.png";

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                DataSet ds = this.Data.Set;

                if (ds == null || !ds.Tables.Contains("d_dw_email_info"))
                {
                    LogRuleError("d_dw_email_info table not found in Data.Set.");
                }
                else
                {
                    DataTable table = ds.Tables["d_dw_email_info"];

                    if (table.Rows.Count < 1 || !table.Columns.Contains("memo"))
                    {
                        LogRuleError("d_dw_email_info missing memo column or has no rows.");
                    }
                    else
                    {
                        DataRow row = table.Rows[0];
                        string originalMemo = row["memo"] as string ?? string.Empty;
                        string newMemo = originalMemo + TestMarker + HtmlTestTag;
                        row["memo"] = newMemo;

                        LogRuleInfo($"Original memo='{originalMemo}' New memo='{newMemo}'. Check the delivered email's Body for TestMarker and HTMLBody for whether HtmlTestTag rendered.");
                    }

                    LogRuleInfo("Attachment fields BEFORE: " + DumpAttachmentFields(table));

                    // Re-added at user request for a firsthand confirmation
                    // test with the new UNC path. Expected to fail the same
                    // way as before (readOnly="Y" on these fields) -- this
                    // is deliberately being re-tried, not a regression.
                    TryAttachTestImage(table);

                    LogRuleInfo("Attachment fields AFTER: " + DumpAttachmentFields(table));
                }
            }
            catch (Exception ex)
            {
                LogRuleError("Execute failed: " + ex);
            }

            // Never block the window from closing or the real email from
            // sending, regardless of what the test above found.
            ruleResult.Success = true;
            return ruleResult;
        }

        // Separate try/catch per field so a failure on one doesn't stop the
        // others from being attempted. Expected to fail -- attachment/
        // attachment_fullname/b_add_attachments were confirmed readOnly="Y"
        // on 2026-07-29. Kept for a firsthand re-confirmation with the new
        // UNC path per user request.
        private void TryAttachTestImage(DataTable table)
        {
            DataRow row = table.Rows[0];

            try
            {
                if (table.Columns.Contains("attachment_fullname"))
                    row["attachment_fullname"] = TestImagePath;
                if (table.Columns.Contains("attachment"))
                    row["attachment"] = Path.GetFileName(TestImagePath);

                LogRuleInfo($"Set attachment/attachment_fullname to '{TestImagePath}'.");
            }
            catch (Exception ex)
            {
                LogRuleError("attachment/attachment_fullname write failed: " + ex);
            }

            try
            {
                if (table.Columns.Contains("b_add_attachments"))
                {
                    row["b_add_attachments"] = true;
                    LogRuleInfo("Set b_add_attachments = true (bool).");
                }
            }
            catch (Exception ex)
            {
                LogRuleError("b_add_attachments bool write failed, retrying as string 'Y': " + ex);

                try
                {
                    row["b_add_attachments"] = "Y";
                    LogRuleInfo("Set b_add_attachments = 'Y' (string fallback).");
                }
                catch (Exception ex2)
                {
                    LogRuleError("b_add_attachments string write also failed: " + ex2);
                }
            }
        }

        private string DumpAttachmentFields(DataTable table)
        {
            string[] fieldsToCheck = { "attachment", "attachment_fullname", "b_add_attachments" };
            StringBuilder sb = new StringBuilder();

            foreach (string fieldName in fieldsToCheck)
            {
                if (!table.Columns.Contains(fieldName))
                {
                    sb.Append(fieldName).Append("=<not selected in Field Selector> ");
                    continue;
                }

                object val = table.Rows[0][fieldName];
                sb.Append(fieldName).Append("=")
                  .Append(val == DBNull.Value || val == null ? "<null>" : val.ToString())
                  .Append(" ");
            }

            return sb.ToString();
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
        // mask or block the real window close/send.
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_email_close_diag);
                    logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Return", SqlDbType.VarChar, 50).Value = returnValue;
                    logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Swallow -- logging must never mask or block the real close/send.
            }
        }

        public override string GetDescription()
        {
            return "DIAGNOSTIC -- appends TestMarker + an HTML tag to memo, and retries attaching TestImagePath (now UNC) via attachment/attachment_fullname/b_add_attachments, on Email Order Acknowledgment window close (cb_ok).";
        }

        public override string GetName()
        {
            return nameof(asi_oe_email_close_diag);
        }
    }
}
