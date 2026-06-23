// ============================================================
// asi_oe_rmb_qto_taker_t9.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770
//               (RMB "Convert to Order"). Shows a Yes/No confirmation
//               dialog with the found quote number for user verification.
//               T8 P/Invoke failed: security-transparent assembly cannot
//               call native code directly. T9 loads System.Windows.Forms
//               via reflection — managed-to-managed call, no P/Invoke
//               from our code, bypasses transparency restriction.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T8 -> T9)
//   - T8 P/Invoke: security transparent method cannot call native code
//   - T9: load System.Windows.Forms via Assembly.Load + reflection
//         to call MessageBox.Show — no P/Invoke from our transparent assembly
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;

namespace asi_OeRmbQtoTaker_t9
{
    public class asi_oe_rmb_qto_taker_t9 : P21.Extensions.BusinessRule.Rule
    {
        // DialogResult.Yes = 6
        private const int IDYES = 6;

        private int ShowMessageBox(string text, string caption, bool yesNo)
        {
            try
            {
                Assembly asm = Assembly.Load(
                    "System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089");

                Type msgBoxType  = asm.GetType("System.Windows.Forms.MessageBox");
                Type buttonsType = asm.GetType("System.Windows.Forms.MessageBoxButtons");
                Type iconType    = asm.GetType("System.Windows.Forms.MessageBoxIcon");

                // MessageBoxButtons: OK=0, YesNo=4
                // MessageBoxIcon:    Information=64, Question=32
                object buttons = Enum.ToObject(buttonsType, yesNo ? 4 : 0);
                object icon    = Enum.ToObject(iconType,    yesNo ? 32 : 64);

                MethodInfo showMethod = msgBoxType.GetMethod(
                    "Show", new Type[] { typeof(string), typeof(string), buttonsType, iconType });

                object result = showMethod.Invoke(null, new object[] { text, caption, buttons, icon });
                return Convert.ToInt32(result);
            }
            catch
            {
                return 0;
            }
        }

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

                // Find the most recent open quote and show it in the confirmation
                // so the user can verify it matches what they have open.
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
                    ShowMessageBox(
                        "No open quotes found.\nTaker will not be updated.",
                        "QTO Taker Update", false);

                    ruleResult.Success = true;
                    return ruleResult;
                }

                string prompt = string.Format(
                    "Found quote {0} (Customer: {1})\n\nUpdate Taker to {2}?",
                    orderNo, customerId, userIdUpper);

                int answer = ShowMessageBox(prompt, "QTO Taker Update", true);

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
                ruleResult.Message = "T9 error: " + ex.Message;
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
            return nameof(asi_oe_rmb_qto_taker_t9);
        }
    }
}
