// ============================================================
// asi_oe_rmb_qto_taker_t11.cs
// ============================================================
// Description : Fires on Message Box Opening event for message_no 7770
//               (RMB "Convert to Order"). Reads the current user's
//               order_no from asi_session_context (populated by
//               asi_oe_qto_session when user tabs off order_no in
//               Order Entry) then updates oe_hdr.taker to the logged-in
//               user. Shows a Yes/No confirmation via reflection-based
//               MessageBox before updating.
//               T4 (qtowindowopening) covers the wizard path.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
//               Field Selector: MessageBoxData > message_no (checked)
// Prereq      : asi_oe_qto_session_t1 registered and active
//               asi_session_context table exists in P21 DB
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T10 -> T11)
//   - T9/T10: SELECT TOP 1 ORDER BY date_last_modified found wrong quote
//   - T11: reads order_no from asi_session_context populated by
//          asi_oe_qto_session ValidateField rule on Order Entry tab-off
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;

namespace asi_OeRmbQtoTaker_t11
{
    public class asi_oe_rmb_qto_taker_t11 : P21.Extensions.BusinessRule.Rule
    {
        private const int IDYES = 6;

        private int ShowYesNo(string text, string caption)
        {
            try
            {
                Assembly asm = Assembly.Load(
                    "System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089");

                Type msgBoxType  = asm.GetType("System.Windows.Forms.MessageBox");
                Type buttonsType = asm.GetType("System.Windows.Forms.MessageBoxButtons");
                Type iconType    = asm.GetType("System.Windows.Forms.MessageBoxIcon");

                object yesNo    = Enum.ToObject(buttonsType, 4);  // YesNo
                object question = Enum.ToObject(iconType,    32); // Question

                MethodInfo show = msgBoxType.GetMethod(
                    "Show", new Type[] { typeof(string), typeof(string), buttonsType, iconType });

                object result = show.Invoke(null, new object[] { text, caption, yesNo, question });
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

                DataRow msgRow  = msgTable.Rows[0];
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

                // Read the order_no captured when user tabbed off order_no in Order Entry
                string orderNo = string.Empty;
                const string selectSql =
                    @"SELECT order_no
                        FROM asi_session_context
                       WHERE user_id = @UserId";

                using (SqlCommand selectCmd = new SqlCommand(selectSql, P21SqlConnection))
                {
                    selectCmd.CommandType = CommandType.Text;
                    selectCmd.Parameters.Add("@UserId", SqlDbType.VarChar, 30).Value = userIdUpper;
                    object result = selectCmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        orderNo = result.ToString().Trim();
                }

                if (string.IsNullOrEmpty(orderNo))
                {
                    ruleResult.Message = "asi_session_context has no entry for " + userIdUpper
                        + " — ensure asi_oe_qto_session is registered and active.";
                    ruleResult.Success = true;
                    return ruleResult;
                }

                string prompt = string.Format(
                    "Update Taker to {0} on order {1}?", userIdUpper, orderNo);

                int answer = ShowYesNo(prompt, "QTO Taker Update");

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
                        : string.Format("No open quote found for order {0} — taker not updated.", orderNo);
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = "T11 error: " + ex.Message;
            }

            ruleResult.Success = true;
            return ruleResult;
        }

        public override string GetDescription()
        {
            return "On RMB Convert to Order (Message Box 7770): reads order_no from asi_session_context, confirms with user, then updates taker to logged-in user.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t11);
        }
    }
}
