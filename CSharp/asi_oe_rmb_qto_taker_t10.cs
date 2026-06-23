// ============================================================
// asi_oe_rmb_qto_taker_t10.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770
//               (RMB "Convert to Order"). Shows an InputBox pre-filled
//               with the best-guess order number so the user can confirm
//               or correct it before taker is updated.
//               T9: dialog fired correctly but showed wrong quote (query
//               finds most-recently-modified open quote, not the open one).
//               T10: use InputBox so user can correct the order number.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T9 -> T10)
//   - T9: dialog fired, reflection works, but order_no from query was wrong
//   - T10: InputBox pre-filled with best-guess order_no; user can correct
//          before update runs; blank/Cancel = no update
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;

namespace asi_OeRmbQtoTaker_t10
{
    public class asi_oe_rmb_qto_taker_t10 : P21.Extensions.BusinessRule.Rule
    {
        private string ShowInputBox(string prompt, string title, string defaultValue)
        {
            try
            {
                Assembly asm = Assembly.Load(
                    "Microsoft.VisualBasic, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a");
                Type interaction = asm.GetType("Microsoft.VisualBasic.Interaction");
                MethodInfo method = interaction.GetMethod(
                    "InputBox",
                    new Type[] { typeof(string), typeof(string), typeof(string), typeof(int), typeof(int) });

                object result = method.Invoke(null,
                    new object[] { prompt, title, defaultValue, -1, -1 });
                return result != null ? result.ToString().Trim() : string.Empty;
            }
            catch
            {
                return string.Empty;
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

                // Best-guess query — pre-fills the InputBox so user only has
                // to correct it if wrong, not type from scratch.
                string guessOrderNo = string.Empty;
                const string findSql =
                    @"SELECT TOP 1 order_no
                        FROM oe_hdr
                       WHERE projected_order = 'Y'
                       ORDER BY date_last_modified DESC";

                using (SqlCommand findCmd = new SqlCommand(findSql, P21SqlConnection))
                {
                    findCmd.CommandType = CommandType.Text;
                    object result = findCmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        guessOrderNo = result.ToString().Trim();
                }

                string prompt = string.Format(
                    "Confirm or correct the order number shown in Order Entry.\n\nUpdate Taker to {0}:",
                    userIdUpper);

                string orderNo = ShowInputBox(prompt, "QTO Taker Update", guessOrderNo);

                if (string.IsNullOrEmpty(orderNo))
                {
                    // User cancelled or cleared the field — do nothing.
                    ruleResult.Success = true;
                    return ruleResult;
                }

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
                    : string.Format("No open quote found for order {0} — taker not updated.", orderNo);
            }
            catch (Exception ex)
            {
                ruleResult.Message = "T10 error: " + ex.Message;
            }

            ruleResult.Success = true;
            return ruleResult;
        }

        public override string GetDescription()
        {
            return "On RMB Convert to Order (Message Box 7770): prompts user to confirm/correct order number then updates taker to logged-in user.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t10);
        }
    }
}
