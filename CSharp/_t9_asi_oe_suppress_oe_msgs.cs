// =============================================================================
// asi_oe_suppress_oe_msgs
// Fires on: Order Entry message box events
//
// Version History:
//   t1  - Initial: suppress overdue invoice message (451) and
//         no-contacts message (688) to prevent interference with BR
//   t2  - Added suppression of multiple-contracts message (8280)
//         Renamed class, namespace, and GetName to _oe_order_suppress_msgs
//   t3  - Added window name check: only suppress if window = w_order_entry_sheet
//   t4  - Diagnostic: dump MessageBoxData columns and DataSet tables
//   t5  - Diagnostic: dump table_properties columns and values
//   t6  - Diagnostic: dump all MessageBoxData field values from Field Selector
//   t7  - Refactored: suppression list driven by suppress_messages_p21_ud table
//         via usp_suppress_messages_p21_ud stored proc (CHECK / ALERT actions)
//         Sends database mail alert for any unrecognized message numbers
//   t8  - Updated CHECK handling from BIT to 3-state string:
//         SUPPRESS = hide popup, ALLOW = show popup no alert, ALERT = show popup + send email
//   t9  - Replaced email alert with LOG action to message_log_p21_ud for end-of-day review
// =============================================================================

using P21.Extensions.BusinessRule;
using System.Data;
using System.Data.SqlClient;

namespace _t9_asi_oe_suppress_oe_msgs
{
    public class _t9_asi_oe_suppress_oe_msgs : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            DataRow msgRow     = this.Data.Set.Tables["MessageBoxData"].Rows[0];
            int    messageNo   = msgRow.Field<int>("message_no");
            string action      = GetMessageAction(messageNo);

            if (action == "SUPPRESS")
            {
                msgRow.SetField<string>("suppress_message", "Y");
            }
            else if (action == "ALERT")
            {
                string messageTitle = msgRow.IsNull("message_title") ? null : msgRow.Field<string>("message_title");
                string methodName   = msgRow.IsNull("method_name")   ? null : msgRow.Field<string>("method_name");
                string userText     = msgRow.IsNull("user_text")     ? null : msgRow.Field<string>("user_text");
                LogMessage(messageNo, messageTitle, methodName, userText);
            }
            // ALLOW: let the popup through with no action

            return ruleResult;
        }

        // Calls usp_suppress_messages_p21_ud with CHECK action.
        // Returns 'SUPPRESS', 'ALLOW', or 'ALERT'.
        private string GetMessageAction(int messageNo)
        {
            if (P21SqlConnection.State != ConnectionState.Open)
                P21SqlConnection.Open();

            using (SqlCommand cmd = new SqlCommand("dbo.usp_suppress_messages_p21_ud", P21SqlConnection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@action",     "CHECK");
                cmd.Parameters.AddWithValue("@message_no", messageNo);

                object result = cmd.ExecuteScalar();
                return result != null ? result.ToString() : "ALERT";
            }
        }

        // Calls usp_suppress_messages_p21_ud with LOG action.
        // Inserts or updates message_log_p21_ud for end-of-day review.
        private void LogMessage(int messageNo, string messageTitle, string methodName, string userText)
        {
            if (P21SqlConnection.State != ConnectionState.Open)
                P21SqlConnection.Open();

            using (SqlCommand cmd = new SqlCommand("dbo.usp_suppress_messages_p21_ud", P21SqlConnection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@action",        "LOG");
                cmd.Parameters.AddWithValue("@message_no",    messageNo);
                cmd.Parameters.AddWithValue("@message_title", (object)messageTitle ?? System.DBNull.Value);
                cmd.Parameters.AddWithValue("@method_name",   (object)methodName   ?? System.DBNull.Value);
                cmd.Parameters.AddWithValue("@user_text",     (object)userText     ?? System.DBNull.Value);
                cmd.ExecuteNonQuery();
            }
        }

        public override string GetDescription() => "Suppress OE messages driven by suppress_messages_p21_ud table";
        public override string GetName() => "_t9_asi_oe_suppress_oe_msgs";
    }
}
