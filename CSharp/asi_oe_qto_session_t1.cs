// ============================================================
// asi_oe_qto_session_t1.cs
// ============================================================
// Description : ValidateField rule on order_no in Order Entry.
//               Fires when the user tabs off the Order Number field,
//               capturing the loaded order_no into asi_session_context
//               keyed by user_id. The asi_oe_rmb_qto_taker rule reads
//               this value when Message Box 7770 fires to identify the
//               correct quote being converted via RMB "Convert to Order".
// Registration: ValidateField event
//               Multi-Row: NOT checked (uses Data.Fields)
//               Field Selector: order_no checked
//               Window: Order Entry
// Prereq      : Run Create-asi-session-context.sql on target P21 DB
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_OeQtoSession_t1
{
    public class asi_oe_qto_session_t1 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                object orderNoRaw = this.Data.Fields["order_no"];
                string orderNo = (orderNoRaw == null || orderNoRaw == DBNull.Value)
                    ? string.Empty : orderNoRaw.ToString().Trim();

                if (string.IsNullOrEmpty(orderNo))
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

                // UPSERT: one row per user, always reflects the latest order loaded
                const string upsertSql =
                    @"MERGE asi_session_context AS target
                      USING (SELECT @UserId AS user_id, @OrderNo AS order_no) AS source
                         ON target.user_id = source.user_id
                       WHEN MATCHED THEN
                            UPDATE SET order_no = source.order_no, updated_at = GETDATE()
                       WHEN NOT MATCHED THEN
                            INSERT (user_id, order_no, updated_at)
                            VALUES (source.user_id, source.order_no, GETDATE());";

                using (SqlCommand cmd = new SqlCommand(upsertSql, P21SqlConnection))
                {
                    cmd.CommandType = CommandType.Text;
                    cmd.Parameters.Add("@UserId",  SqlDbType.VarChar, 30).Value = userIdUpper;
                    cmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo;
                    cmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // Never block Order Entry — swallow all errors silently
            }

            ruleResult.Success = true;
            return ruleResult;
        }

        public override string GetDescription()
        {
            return "Captures order_no into asi_session_context when user tabs off Order Number in Order Entry. Used by asi_oe_rmb_qto_taker to identify the correct quote on RMB conversion.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_qto_session_t1);
        }
    }
}
