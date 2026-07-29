// ============================================================
// asi_oe_order_ack_custom_message_t1.cs
// ============================================================
// Description : Silently appends a custom message to the body (memo) of
//               Order Acknowledgment emails before they are sent. The P21
//               user never sees this text -- the Email Order Acknowledgment
//               response window is suppressed entirely (display_response_window
//               set to No) so the email goes out directly with the message
//               baked into the body. Only the email recipient sees it.
// Event       : Form Printing Pre-Email Response Window
// Registration: On-Event rule on that event. Field Selector: under
//               EmailDataMisc select form_type, memo, display_response_window,
//               document_nos (document_nos only used for log context).
// Structure   : Unconfirmed at authoring time whether this event exposes
//               Data.Fields (single-row) or Data.Set (multi-row, like
//               qtowindowopening) -- EmailDataMisc + EmailDataRecipient mirrors
//               the HeaderInfo + table_properties shape that turned out to be
//               Data.Set-only. This rule tries Data.Set first, falls back to
//               Data.Fields, and logs a structure dump to business_rule_log if
//               neither path finds the expected fields, so the first test run
//               in P21 Business Rules tells us which path is real.
// Testing     : Verify in P21 Business Rules first (confirm the logged
//               form_type value, confirm the popup is actually suppressed,
//               confirm the recipient's email body). Then register the same
//               rule in Play for a real user-facing Order Ack send.
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-07-28  Bus App Team
//   - Initial version
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeOrderAckCustomMessage_t1
{
    public class asi_oe_order_ack_custom_message_t1 : P21.Extensions.BusinessRule.Rule
    {
        // TEST MESSAGE -- swap for the real message once the plumbing is confirmed.
        private const string CustomMessage =
            "Life is basically just opening 40 tabs in your brain at once, having 5 of them freeze, " +
            "hearing music playing from somewhere but you can't find where, and realizing your battery is at 12%.";

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                bool handled = TryProcessViaDataSet();
                if (!handled)
                    handled = TryProcessViaDataFields();

                if (!handled)
                    LogRuleError("Could not locate EmailDataMisc (form_type/memo) via Data.Set or Data.Fields. Structure dump: " + DumpStructure());
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

        // Path for events where EmailDataMisc arrives as a Data.Set table
        // (1 row), matching the qtowindowopening precedent.
        private bool TryProcessViaDataSet()
        {
            DataSet ds;
            try { ds = this.Data.Set; }
            catch { return false; }

            if (ds == null || !ds.Tables.Contains("EmailDataMisc"))
                return false;

            DataTable table = ds.Tables["EmailDataMisc"];
            if (table.Rows.Count < 1 || !table.Columns.Contains("form_type") || !table.Columns.Contains("memo"))
                return false;

            DataRow row = table.Rows[0];
            string formType = row["form_type"] as string ?? string.Empty;
            string docNos = table.Columns.Contains("document_nos") ? (row["document_nos"] as string ?? string.Empty) : string.Empty;
            bool isOrderAck = IsOrderAcknowledgment(formType);

            LogRuleInfo($"[Data.Set] form_type='{formType}' matched={isOrderAck} document_nos='{docNos}'");

            if (isOrderAck)
            {
                string existingMemo = row["memo"] as string ?? string.Empty;
                row["memo"] = AppendCustomMessage(existingMemo);

                if (table.Columns.Contains("display_response_window"))
                    row["display_response_window"] = "N";
            }

            return true;
        }

        // Fallback path in case this event is actually single-row.
        private bool TryProcessViaDataFields()
        {
            DataFields fields;
            try { fields = this.Data.Fields; }
            catch { return false; }

            if (fields == null)
                return false;

            DataField formTypeField = FindField(fields, "form_type");
            DataField memoField = FindField(fields, "memo");
            if (formTypeField == null || memoField == null)
                return false;

            DataField displayField = FindField(fields, "display_response_window");
            DataField docNosField = FindField(fields, "document_nos");

            string formType = formTypeField.FieldValue ?? string.Empty;
            bool isOrderAck = IsOrderAcknowledgment(formType);

            LogRuleInfo($"[Data.Fields] form_type='{formType}' matched={isOrderAck} document_nos='{(docNosField != null ? docNosField.FieldValue : string.Empty)}'");

            if (isOrderAck)
            {
                string existingMemo = memoField.FieldValue ?? string.Empty;
                memoField.FieldValue = AppendCustomMessage(existingMemo);

                if (displayField != null)
                    displayField.FieldValue = "N";
            }

            return true;
        }

        // Heuristic match instead of an exact string -- the real form_type
        // value is unconfirmed until the first test run logs it.
        private bool IsOrderAcknowledgment(string formType)
        {
            if (string.IsNullOrEmpty(formType))
                return false;

            return formType.IndexOf("order", StringComparison.OrdinalIgnoreCase) >= 0
                && formType.IndexOf("ack", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        // Outlook merges single-newline text onto one line; a blank line
        // keeps the appended message visually separate in the recipient's
        // email body (same trap as the P21 Alert plain-text body).
        private string AppendCustomMessage(string existingMemo)
        {
            if (string.IsNullOrEmpty(existingMemo))
                return CustomMessage;

            return existingMemo + "\r\n\r\n" + CustomMessage;
        }

        // Name-only match (no aliases -- unreliable in newer P21). Matches
        // an exact field name or a table-prefixed name ending in it.
        private DataField FindField(DataFields fields, string name)
        {
            foreach (DataField field in fields)
            {
                if (field.FieldName != null
                    && (field.FieldName.Equals(name, StringComparison.OrdinalIgnoreCase)
                        || field.FieldName.EndsWith("." + name, StringComparison.OrdinalIgnoreCase)))
                    return field;
            }
            return null;
        }

        // Diagnostic dump used only when neither Data.Set nor Data.Fields
        // exposes the expected fields -- tells us the real structure instead
        // of guessing again.
        private string DumpStructure()
        {
            StringBuilder sb = new StringBuilder();

            try
            {
                DataSet ds = this.Data.Set;
                if (ds != null)
                {
                    foreach (DataTable t in ds.Tables)
                    {
                        sb.Append("Table=").Append(t.TableName).Append(" Rows=").Append(t.Rows.Count).Append(" Cols=[");
                        foreach (DataColumn c in t.Columns)
                            sb.Append(c.ColumnName).Append(",");
                        sb.Append("] ");
                    }
                }
            }
            catch (Exception ex)
            {
                sb.Append("Data.Set threw: ").Append(ex.Message).Append(" ");
            }

            try
            {
                foreach (DataField f in this.Data.Fields)
                    sb.Append("Field=").Append(f.FieldName).Append(" ");
            }
            catch (Exception ex)
            {
                sb.Append("Data.Fields threw: ").Append(ex.Message).Append(" ");
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
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_order_ack_custom_message_t1);
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
            return "Silently appends a custom message to the Order Acknowledgment email body; the P21 user never sees it.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_order_ack_custom_message_t1);
        }
    }
}
