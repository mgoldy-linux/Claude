// =============================================================================
// ASI_WWMS_ScannerOnly_T2
// Fires on: ValidateField — c_rf_item_id in WWMS Sales Order Picking
//
// Enforces scanner-only entry on the RF Item ID field.
// Scanner must be configured to prepend "&" to every scan.
// Rule strips the prefix and writes the clean Item ID back so P21 saves correctly.
// Rejects any entry missing the prefix (manual keyboard input).
//
// P21 setup:
//   Form       : WWMS Sales Order Picking
//   Field      : c_rf_item_id
//   Event      : ValidateField
//   Rule name  : ASI_WWMS_ScannerOnly_T2
// =============================================================================

using P21.Extensions.BusinessRule;
using System;

namespace ASI_WWMS_ScannerOnly_T2
{
    public class ASI_WWMS_ScannerOnly_T2 : P21.Extensions.BusinessRule.Rule
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

                // Strip scanner prefix, write clean item ID back so P21 saves without the "&"
                string cleanValue = rawValue.Substring(SCANNER_PREFIX.Length);
                this.Data.Fields[FLD_RF_ITEM_ID].FieldValue = cleanValue;
            }
            catch (Exception ex)
            {
                ruleResult.Message = "[ASI_WWMS_ScannerOnly_T2] Error: " + ex.Message;
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Enforces scanner-only entry on RF Item ID (c_rf_item_id) in WWMS Sales Order Picking. Strips '&' prefix from scanned input before P21 saves the value; rejects manual keyboard entry.";

        public override string GetName() =>
            "ASI_WWMS_ScannerOnly_T2";
    }
}
