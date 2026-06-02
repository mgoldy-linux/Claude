// =============================================================================
// _oe_order_suppress_msgs
// Fires on: Order Entry message box events
//
// Version History:
//   v1  - Initial: suppress overdue invoice message (451) and
//         no-contacts message (688) to prevent interference with BR
//   v2  - Added suppression of multiple-contracts message (8280)
//         Renamed class, namespace, and GetName to _oe_order_suppress_msgs
// =============================================================================

using P21.Extensions.BusinessRule;
using System.Data;

namespace _oe_order_suppress_msgs
{
    public class _oe_order_suppress_msgs : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            // suppress overdue invoice message
            if (this.Data.Set.Tables["MessageBoxData"].Rows[0].Field<int>("message_no") == 451)
                this.Data.Set.Tables["MessageBoxData"].Rows[0].SetField<string>("suppress_message", "Y");
            // suppress no contacts message
            if (this.Data.Set.Tables["MessageBoxData"].Rows[0].Field<int>("message_no") == 688)
                this.Data.Set.Tables["MessageBoxData"].Rows[0].SetField<string>("suppress_message", "Y");
            // suppress multiple contracts message
            if (this.Data.Set.Tables["MessageBoxData"].Rows[0].Field<int>("message_no") == 8280)
                this.Data.Set.Tables["MessageBoxData"].Rows[0].SetField<string>("suppress_message", "Y");

            return ruleResult;
        }

        public override string GetDescription() => "Suppress oe messages to prevent interference with BR";
        public override string GetName() => "_oe_order_suppress_msgs";
    }
}
