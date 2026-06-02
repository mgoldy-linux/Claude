// =============================================================================
// ASI_WWMS_ScannerOnly_T3
// Fires on: DataChanged — c_rf_item_id in WWMS Sales Order Picking
//
// T2 used ValidateField. Problem: P21 ran its own item lookup on the original
// "&ITEM" value before the write-back could land, causing "invalid ID".
// T3 switches to DataChanged so the prefix is stripped before P21 validates.
//
// Behavior:
//   "&" present  → strip prefix, write clean item ID back (scanner path)
//   No "&"       → clear the field silently (manual entry detected, no message)
//
// NOTE: DataChanged fires on every keystroke. The clear-on-no-"&" logic will
// wipe partial manual input on each character. This is intentional — the field
// is scanner-only, so manual typing should not be possible at all.
//
// P21 setup:
//   Form       : WWMS Sales Order Picking
//   Field      : c_rf_item_id
//   Event      : DataChanged
//   Rule name  : ASI_WWMS_ScannerOnly_T3
// =============================================================================

using P21.Extensions.BusinessRule;
using System;

namespace ASI_WWMS_ScannerOnly_T3
{
    public class ASI_WWMS_ScannerOnly_T3 : P21.Extensions.BusinessRule.Rule
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
                    return ruleResult;

                if (rawValue.StartsWith(SCANNER_PREFIX))
                {
                    // Scanner input — strip prefix, write clean item ID back
                    string cleanValue = rawValue.Substring(SCANNER_PREFIX.Length);
                    this.Data.Fields[FLD_RF_ITEM_ID].FieldValue = cleanValue;
                }
                else
                {
                    // Manual keyboard entry detected — clear the field silently
                    this.Data.Fields[FLD_RF_ITEM_ID].FieldValue = string.Empty;
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = "[ASI_WWMS_ScannerOnly_T3] Error: " + ex.Message;
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Scanner-only entry on c_rf_item_id (WWMS Sales Order Picking). DataChanged event strips '&' prefix on scan; clears field silently on manual keyboard input.";

        public override string GetName() =>
            "ASI_WWMS_ScannerOnly_T3";
    }
}
