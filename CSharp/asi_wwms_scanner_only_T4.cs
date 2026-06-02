// =============================================================================
// ASI_WWMS_ScannerOnly_T4
// Fires on: DataChanged — c_rf_item_id in WWMS Sales Order Picking
//
// T3 change: blank field now returns a failure instead of passing through.
// T4 change: clearing on manual entry also shows the "scan required" message.
//
// Behavior:
//   Blank        → FAIL  "Item ID is required. Please scan the item."
//   "&" present  → strip prefix, write clean item ID back (scanner path), PASS
//   No "&"       → clear the field + FAIL "Need to scan the item ID."
//
// P21 setup:
//   Form       : WWMS Sales Order Picking
//   Field      : c_rf_item_id
//   Event      : DataChanged
//   Rule name  : ASI_WWMS_ScannerOnly_T4
// =============================================================================

using P21.Extensions.BusinessRule;
using System;

namespace ASI_WWMS_ScannerOnly_T4
{
    public class ASI_WWMS_ScannerOnly_T4 : P21.Extensions.BusinessRule.Rule
    {
        private const string FLD_RF_ITEM_ID = "c_rf_item_id";
        private const string SCANNER_PREFIX = "&";

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                string rawValue = this.Data.Fields[FLD_RF_ITEM_ID].FieldValue ?? string.Empty;

                if (string.IsNullOrWhiteSpace(rawValue))
                {
                    ruleResult.Message = "Item ID is required. Please scan the item.";
                    return ruleResult;
                }

                if (rawValue.StartsWith(SCANNER_PREFIX))
                {
                    // Scanner input — strip prefix, write clean item ID back
                    string cleanValue = rawValue.Substring(SCANNER_PREFIX.Length);
                    this.Data.Fields[FLD_RF_ITEM_ID].FieldValue = cleanValue;
                }
                else
                {
                    // Manual keyboard entry detected — clear the field and prompt to scan
                    this.Data.Fields[FLD_RF_ITEM_ID].FieldValue = string.Empty;
                    ruleResult.Message = "Need to scan the item ID.";
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = "[ASI_WWMS_ScannerOnly_T4] Error: " + ex.Message;
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Scanner-only entry on c_rf_item_id (WWMS Sales Order Picking). Fails on blank; strips '&' prefix on scan; clears field and prompts to scan on manual keyboard input.";

        public override string GetName() =>
            "ASI_WWMS_ScannerOnly_T4";
    }
}
