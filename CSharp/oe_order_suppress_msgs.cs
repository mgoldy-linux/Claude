// =============================================================================
// _oe_order_suppress_msgs
// Fires on: Order Entry message box events
//
// Version History:
//   v1  - Initial: suppress overdue invoice message (451) and
//         no-contacts message (688) to prevent interference with BR
//   v2  - Added suppression of multiple-contracts message (8280)
//         Renamed class, namespace, and GetName to _oe_order_suppress_msgs
//   v3  - Added window name check: only suppress if window = w_order_entry_sheet
//   v4  - Diagnostic: dump MessageBoxData columns and DataSet tables
//   v5  - Diagnostic: dump table_properties columns and values
//   v6  - Diagnostic: dump all MessageBoxData field values from Field Selector
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

            DataRow row = this.Data.Set.Tables["MessageBoxData"].Rows[0];
            System.Text.StringBuilder sb = new System.Text.StringBuilder();

            sb.AppendLine("=== MessageBoxData Field Values ===");

            // Dump every column's value dynamically — no hardcoding needed
            foreach (DataColumn col in this.Data.Set.Tables["MessageBoxData"].Columns)
                sb.AppendLine(col.ColumnName + " = " + row[col].ToString());

            // Throw to surface output in P21
            throw new System.Exception(sb.ToString());
        }

        public override string GetDescription() => "Suppress oe messages to prevent interference with BR";
        public override string GetName() => "_oe_order_suppress_msgs";
    }
}