// ============================================================
// asi_oe_rmb_qto_taker_t8.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770
//               (RMB "Convert to Order"). Shows a Yes/No confirmation
//               dialog displaying the found quote number so the user
//               can verify before taker is updated.
//               TriggerWindowTitle is empty for this event (T7 confirmed),
//               so we query oe_hdr for the most recent open quote and
//               display it in the dialog for user confirmation.
//               Uses Win32 P/Invoke for MessageBox — no Windows.Forms ref needed.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T7 -> T8)
//   - T7: confirmed TriggerWindowTitle is empty for this event
//   - T8: show Yes/No confirmation dialog with found order_no
//   - T8b: replaced System.Windows.Forms with Win32 P/Invoke (no ref needed)
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Runtime.InteropServices;

namespace asi_OeRmbQtoTaker_t8
{
    public class asi_oe_rmb_qto_taker_t8 : P21.Extensions.BusinessRule.Rule
    {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern int MessageBox(IntPtr hWnd, string text, string caption, uint type);

        private const uint MB_YESNO       = 0x00000004;
        private const uint MB_OK          = 0x00000000;
        private const uint MB_ICONQUESTION = 0x00000020;
        private const uint MB_ICONINFO    = 0x00000040;
        private const int  IDYES          = 6;

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                DataTable msgTable = this.Data.Set.Tables["MessageBoxData"];
                if (msgTable == null || msgTable.Rows.Count == 0)
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                DataRow msgRow = msgTable.Rows[0];
                object msgNoRaw = msgRow["message_no"];
                string messageNo = (msgNoRaw == null || msgNoRaw == DBNull.Value)
                    ? string.Empty : msgNoRaw.ToString().Trim();

                if (messageNo != "7770")
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                string userId = this.Session != null ? this.Session.UserID : string.Empty;
                if (string.IsNullOrEmpty(userId))
                {
                    ruleResult.Success = true;
                    return ruleResult;
                }

                string userIdUpper = userId.ToUpper();

                // Find the most recent open quote. Show it to the user so they
                // can confirm it matches what they have open before we update.
                string orderNo    = string.Empty;
                string customerId = string.Empty;

                const string findSql =
                    @"SELECT TOP 1 order_no, customer_id
                        FROM oe_hdr
                       WHERE projected_order = 'Y'
                       ORDER BY date_last_modified DESC";

                using (SqlCommand findCmd = new SqlCommand(findSql, P21SqlConnection))
                {
                    findCmd.CommandType = CommandType.Text;
                    using (SqlDataReader rdr = findCmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            orderNo    = rdr["order_no"].ToString().Trim();
                            customerId = rdr["customer_id"].ToString().Trim();
                        }
                    }
                }

                if (string.IsNullOrEmpty(orderNo))
                {
                    MessageBox(IntPtr.Zero,
                        "No open quotes found.\nTaker will not be updated.",
                        "QTO Taker Update",
                        MB_OK | MB_ICONINFO);

                    ruleResult.Success = true;
                    return ruleResult;
                }

                string prompt = string.Format(
                    "Found quote {0} (Customer: {1})\n\nUpdate Taker to {2}?",
                    orderNo, customerId, userIdUpper);

                int answer = MessageBox(IntPtr.Zero, prompt, "QTO Taker Update",
                    MB_YESNO | MB_ICONQUESTION);

                if (answer == IDYES)
                {
                    const string updateSql =
                        @"UPDATE oe_hdr
                             SET taker              = @UserId,
                                 last_maintained_by = @UserId,
                                 date_last_modified = GETDATE()
                           WHERE order_no       = @OrderNo
                             AND projected_order = 'Y'";

                    int rows;
                    using (SqlCommand updateCmd = new SqlCommand(updateSql, P21SqlConnection))
                    {
                        updateCmd.CommandType = CommandType.Text;
                        updateCmd.Parameters.Add("@UserId",  SqlDbType.VarChar, 30).Value = userIdUpper;
                        updateCmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo;
                        rows = updateCmd.ExecuteNonQuery();
                    }

                    ruleResult.Message = rows > 0
                        ? string.Format("Taker updated to {0} on order {1}.", userIdUpper, orderNo)
                        : string.Format("UPDATE ran but 0 rows affected for order {0}.", orderNo);
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = "T8 error: " + ex.Message;
            }

            ruleResult.Success = true;
            return ruleResult;
        }

        public override string GetDescription()
        {
            return "On RMB Convert to Order (Message Box 7770): shows Yes/No confirmation with found quote number before updating taker to logged-in user.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t8);
        }
    }
}
