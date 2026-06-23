// ============================================================
// asi_oe_qto_taker_t14.cs
// ============================================================
// Description : DIAGNOSTIC — same logic as T13 but logs every value
//               so we can see why the condition is not passing.
//               Logs: Session.UserID, order_no, dbOrderTaker,
//               dbLastMaintainedBy, and whether the UPDATE ran.
// Registration: Workflow / ASynchronous / Save / Order Entry
//               Multi-Row: NOT checked
// Field Selector: order_no, quote, rma_flag, oe_hdr_completed (all checked)
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace asi_OeQtoTaker_t14
{
    public class asi_oe_qto_taker_t14 : P21.Extensions.BusinessRule.Rule
    {
        [Obsolete]
        public override void ExecuteAsync()
        {
            StringBuilder log = new StringBuilder();
            string orderNo = string.Empty;

            try
            {
                string quoteVal         = this.Data.Fields["quote"].FieldValue          ?? "(null)";
                string rmaVal           = this.Data.Fields["rma_flag"].FieldValue       ?? "(null)";
                string completedVal     = this.Data.Fields["oe_hdr_completed"].FieldValue ?? "(null)";
                orderNo                 = this.Data.Fields["order_no"].FieldValue        ?? string.Empty;
                string userId           = this.Session != null ? this.Session.UserID     : string.Empty;

                log.AppendLine("Data.Fields: quote="     + quoteVal);
                log.AppendLine("Data.Fields: rma_flag="  + rmaVal);
                log.AppendLine("Data.Fields: completed=" + completedVal);
                log.AppendLine("Data.Fields: order_no="  + orderNo);
                log.AppendLine("Session.UserID="         + userId);

                if (quoteVal == "Y" || rmaVal == "Y" || completedVal == "Y")
                {
                    log.AppendLine("EXIT: skipped by guard (quote/rma/completed)");
                    LogDiagnostic(log.ToString());
                    return;
                }

                if (string.IsNullOrEmpty(orderNo))
                {
                    log.AppendLine("EXIT: order_no is empty");
                    LogDiagnostic(log.ToString());
                    return;
                }

                if (string.IsNullOrEmpty(userId))
                {
                    log.AppendLine("EXIT: userId is empty");
                    LogDiagnostic(log.ToString());
                    return;
                }

                using (SqlConnection conn = new SqlConnection(P21SqlConnection.ConnectionString))
                {
                    conn.Open();

                    string dbOrderTaker       = string.Empty;
                    string dbLastMaintainedBy = string.Empty;

                    const string selectSql =
                        "SELECT order_taker, last_maintained_by FROM oe_hdr WHERE order_no = @OrderNo";

                    using (SqlCommand selectCmd = new SqlCommand(selectSql, conn))
                    {
                        selectCmd.CommandType = CommandType.Text;
                        selectCmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo.Trim();

                        using (SqlDataReader reader = selectCmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                dbOrderTaker       = reader.IsDBNull(0) ? "(dbnull)" : reader.GetString(0).Trim();
                                dbLastMaintainedBy = reader.IsDBNull(1) ? "(dbnull)" : reader.GetString(1).Trim();
                            }
                            else
                            {
                                log.AppendLine("SELECT returned 0 rows for order_no=" + orderNo);
                            }
                        }
                    }

                    log.AppendLine("DB order_taker="        + dbOrderTaker);
                    log.AppendLine("DB last_maintained_by=" + dbLastMaintainedBy);

                    bool lastMaintMatch  = string.Equals(dbLastMaintainedBy, userId, StringComparison.OrdinalIgnoreCase);
                    bool takerDiffers    = !string.Equals(dbOrderTaker, userId, StringComparison.OrdinalIgnoreCase);

                    log.AppendLine("last_maintained_by == userId: " + lastMaintMatch);
                    log.AppendLine("order_taker != userId:         " + takerDiffers);

                    if (lastMaintMatch && takerDiffers)
                    {
                        const string updateSql =
                            @"UPDATE oe_hdr
                                 SET order_taker        = @UserId,
                                     last_maintained_by = @UserId,
                                     date_last_modified = GETDATE()
                               WHERE order_no = @OrderNo";

                        using (SqlCommand updateCmd = new SqlCommand(updateSql, conn))
                        {
                            updateCmd.CommandType = CommandType.Text;
                            updateCmd.Parameters.Add("@UserId",  SqlDbType.VarChar, 30).Value = userId;
                            updateCmd.Parameters.Add("@OrderNo", SqlDbType.VarChar, 50).Value = orderNo.Trim();
                            int rows = updateCmd.ExecuteNonQuery();
                            log.AppendLine("UPDATE ran — rows affected: " + rows);
                        }
                    }
                    else
                    {
                        log.AppendLine("UPDATE skipped — condition not met");
                    }
                }
            }
            catch (Exception ex)
            {
                log.AppendLine("EXCEPTION: " + ex.Message);
            }

            LogDiagnostic(log.ToString());
        }

        public override RuleResult Execute()
        {
            return new RuleResult() { Success = true };
        }

        private void LogDiagnostic(string details)
        {
            try
            {
                const string logSql =
                    @"INSERT INTO business_rule_log
                        (user_id, log_action, rule_name, rule_assembly_name, run_type,
                         return_value, return_message,
                         date_created, created_by, date_last_modified, last_maintained_by)
                      VALUES
                        (@User, 'Error', @Rule, @Asm, 'ASynchronous',
                         'Diagnostic', @Msg,
                         GETDATE(), @User, GETDATE(), @User)";

                using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
                {
                    string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
                        ? this.Session.UserID : "unknown";

                    logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
                    logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_oe_qto_taker_t14);
                    logCmd.Parameters.Add("@Asm",  SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
                    logCmd.Parameters.Add("@Msg",  SqlDbType.VarChar, 8000).Value =
                        details.Length > 8000 ? details.Substring(0, 8000) : details;
                    logCmd.ExecuteNonQuery();
                }
            }
            catch { }
        }

        public override string GetName()        { return nameof(asi_oe_qto_taker_t14); }
        public override string GetDescription() { return "DIAGNOSTIC: logs T13 condition values to identify why UPDATE is not firing."; }
    }
}
