// =============================================================================
// ASI_WWMS_RF_ScannerOnly
// Fires on: ValidateField — c_rf_item_id in WWMS Sales Order Picking
//
// Enforces scanner-only entry on the RF Item ID field.
// Scanner must be configured to prepend "&" to every scan.
// Rule strips the prefix from valid input; rejects any entry missing it.
//
// P21 setup:
//   Form       : WWMS Sales Order Picking
//   Field      : c_rf_item_id
//   Event      : ValidateField
//   Rule name  : ASI_WWMS_RF_ScannerOnly
// =============================================================================

using P21.Extensions.BusinessRule;
using System;

namespace ASI_WWMS_RF_ScannerOnly
{
    public class ASI_WWMS_RF_ScannerOnly : P21.Extensions.BusinessRule.Rule
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

                if (!rawValue.StartsWith(SCANNER_PREFIX))
                {
                    ruleResult.Message = "Item ID must be entered using a scanner. Manual keyboard entry is not permitted on this field.";
                    return ruleResult;
                }

                // Strip scanner prefix, write clean item ID back to field
                this.Data.Fields[FLD_RF_ITEM_ID].FieldValue = rawValue.Substring(SCANNER_PREFIX.Length);
            }
            catch (Exception ex)
            {
                ruleResult.Message = "[ASI_WWMS_RF_ScannerOnly] Error: " + ex.Message;
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Enforces scanner-only entry on RF Item ID (c_rf_item_id) in WWMS Sales Order Picking. Rejects manual keyboard input by requiring the '&' scanner prefix; strips prefix before passing the value through.";

        public override string GetName() =>
            "ASI_WWMS_RF_ScannerOnly";
    }
}
