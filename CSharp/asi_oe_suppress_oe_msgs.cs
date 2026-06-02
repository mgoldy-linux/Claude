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
//   v1  - Refactored: suppression list driven by suppress_messages_p21_ud table
//         via usp_suppress_messages_p21_ud stored proc (CHECK / ALERT actions)
//         Sends database mail alert for any unrecognized message numbers
// =============================================================================

using P21.Extensions.BusinessRule;
using System.Data;
using System.Data.SqlClient;

namespace asi_oe_suppress_oe_msgs
{
    public class asi_oe_suppress_oe_msgs : P21.Extensions.BusinessRule.Rule
{
    public override RuleResult Execute()
    {
        RuleResult ruleResult = new RuleResult();

        // Pull the message number from the P21 message event data
        DataRow msgRow = this.Data.Set.Tables["MessageBoxData"].Rows[0];
        int messageNo  = msgRow.Field<int>("message_no");

        // Check if this message number exists in the suppression table
        bool suppress = CheckSuppression(messageNo);

        if (suppress)
        {
            // Message is in the suppression table — set suppress_message flag to hide it from the user
            msgRow.SetField<string>("suppress_message", "Y");
        }
        else
        {
            // Message is not in the suppression table — let it through and
            // send a database mail alert so it can be evaluated for suppression
            SendAlert(messageNo);
        }

        return ruleResult;
    }

    // Calls usp_suppress_messages_p21_ud with CHECK action
    // Returns true if the message number is in the suppression table, false if not
    private bool CheckSuppression(int messageNo)
    {
        if (P21SqlConnection.State != System.Data.ConnectionState.Open)
            P21SqlConnection.Open();

        using (SqlCommand cmd = new SqlCommand("dbo.usp_suppress_messages_p21_ud", P21SqlConnection))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@action",     "CHECK");
            cmd.Parameters.AddWithValue("@message_no", messageNo);

            // ExecuteScalar returns the BIT value (1/0) from the proc
            object result = cmd.ExecuteScalar();
            return result != null && (bool)result;
        }
    }

    // Calls usp_suppress_messages_p21_ud with ALERT action
    // Triggers a database mail notification via the P21 Alerts mail profile
    // Message title is looked up inside the proc from the P21 message table
    private void SendAlert(int messageNo)
    {
        if (P21SqlConnection.State != System.Data.ConnectionState.Open)
            P21SqlConnection.Open();

        using (SqlCommand cmd = new SqlCommand("dbo.usp_suppress_messages_p21_ud", P21SqlConnection))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@action",     "ALERT");
            cmd.Parameters.AddWithValue("@message_no", messageNo);
            cmd.ExecuteNonQuery();
        }
    }

    public override string GetDescription() => "Suppress OE messages driven by suppress_messages_p21_ud table";
    public override string GetName() => "asi_oe_suppress_oe_msgs";
    }
}
