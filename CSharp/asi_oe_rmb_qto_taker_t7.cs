// ============================================================
// asi_oe_rmb_qto_taker_t7.cs
// ============================================================
// Description : DIAGNOSTIC — same as T6 but outputs via ruleResult.Message
//               (P21 popup) instead of business_rule_log, since the log
//               INSERT is failing silently. Shows exactly what
//               RuleState.TriggerWindowTitle contains and whether
//               the order_no parse succeeded.
// Registration: Message Box Opening event (multi-row, Data.Set)
//               Multi-Row: checked
// Field Selector: MessageBoxData > message_no (checked)
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-23  Bus App Team  (T6 -> T7)
//   - T6: return_message blank in log — LogDiagnostic INSERT failing silently
//   - T7: output diagnostic via ruleResult.Message (P21 popup) to bypass log
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Text;

namespace asi_OeRmbQtoTaker_t7
{
    public class asi_oe_rmb_qto_taker_t7 : P21.Extensions.BusinessRule.Rule
    {
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

                string userId = this.Session != null ? this.Session.UserID : "(null session)";

                StringBuilder diag = new StringBuilder();
                diag.AppendLine("asi_oe_rmb_qto_taker_t7 DIAGNOSTIC");
                diag.AppendLine("Session.UserID=" + userId);

                string windowTitle = string.Empty;
                if (this.RuleState != null)
                {
                    windowTitle = this.RuleState.TriggerWindowTitle ?? "(TriggerWindowTitle null)";
                    diag.AppendLine("RuleState.TriggerWindowTitle=" + windowTitle);
                }
                else
                {
                    diag.AppendLine("RuleState=null");
                }

                // Attempt to parse order_no
                string orderNo = string.Empty;
                const string prefix = "Order Entry: ";
                if (windowTitle.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    string rest = windowTitle.Substring(prefix.Length).Trim();
                    int spaceIdx = rest.IndexOf(' ');
                    string candidate = spaceIdx > 0 ? rest.Substring(0, spaceIdx) : rest;
                    int parsed;
                    if (int.TryParse(candidate, out parsed))
                    {
                        orderNo = candidate;
                        diag.AppendLine("Parsed order_no=" + orderNo);
                    }
                    else
                    {
                        diag.AppendLine("Parse failed — candidate=" + candidate);
                    }
                }
                else
                {
                    diag.AppendLine("Title does not start with 'Order Entry: '");
                }

                ruleResult.Success = true;
                ruleResult.Message = diag.ToString();
            }
            catch (Exception ex)
            {
                ruleResult.Success = true;
                ruleResult.Message = "T7 exception: " + ex.Message;
            }

            return ruleResult;
        }

        public override string GetDescription()
        {
            return "DIAGNOSTIC: Shows RuleState.TriggerWindowTitle and order_no parse result via popup on Message Box 7770.";
        }

        public override string GetName()
        {
            return nameof(asi_oe_rmb_qto_taker_t7);
        }
    }
}
