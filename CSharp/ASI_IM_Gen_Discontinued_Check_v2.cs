// =============================================================================
// ASI_IM_Gen_Discontinued_Check_v2
// Fires on: Discontinued checkbox (ufc_inv_mast_ud_discontinued) in Item Maintenance
//           BeforeSave event on Item Maintenance form
//
// When Discontinued is checked:
//   1. If EDI Discontinued Date is blank, show popup warning user to enter a date.
//   2. Populate EDI Last Updated with today if empty.
//   3. Check EDI Updated if EDI Last Updated matches today.
//
// On Save (BeforeSave):
//   1. If Discontinued is checked and EDI Discontinued Date is still blank, set to tomorrow.
//
// Change History:
//   2026-03-16 - Fixed FLD_EXCLUDE_FROM_EDI832 field name from "inv_mast.exclude_from_edi832_flag"
//                to "exclude_from_edi832_flag" — P21 business rules do not support table-prefixed field names.
//   2026-03-16 - If EDI Discontinued Date is blank when Discontinued is checked, show popup warning
//                and default the date to tomorrow. (EventName not available on DataCollection.)
//   2026-04-15 - Removed Step 3: no longer auto-checking Exclude from EDI 832.
// =============================================================================

using P21.Extensions.BusinessRule;
using System;

namespace ASI_IM_Gen_Discontinued_Check_v2
{
    public class ASI_IM_Gen_Discontinued_Check : P21.Extensions.BusinessRule.Rule
    {
        // Field names
        private const string FLD_DISCONTINUED          = "ufc_inv_mast_ud_discontinued"; // trigger - General
        private const string FLD_EDI_DISCONTINUED_DATE = "ufc_inv_mast_ud_edi_discontinued_date";  // General
        private const string FLD_EDI_LAST_UPDATED      = "ufc_inv_mast_ud_edi_last_updated"; // General
        private const string FLD_EDI_UPDATED           = "ufc_inv_mast_ud_edi_updated"; // General

        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            try
            {
                string discontinuedValue = this.Data.Fields[FLD_DISCONTINUED].FieldValue ?? string.Empty;
                if (discontinuedValue != "Y")
                    return ruleResult;

                string today    = DateTime.Today.ToString("MM/dd/yyyy");
                string tomorrow = DateTime.Today.AddDays(1).ToString("MM/dd/yyyy");

                string ediDiscontinuedDate = this.Data.Fields[FLD_EDI_DISCONTINUED_DATE].FieldValue ?? string.Empty;

                if (string.IsNullOrWhiteSpace(ediDiscontinuedDate))
                {
                    // Warn the user and default to tomorrow
                    ruleResult.Message = "EDI Discontinued Date is blank. Defaulting to tomorrow (" + tomorrow + "). Please update if needed.";
                    this.Data.Fields[FLD_EDI_DISCONTINUED_DATE].FieldValue = tomorrow;
                    ediDiscontinuedDate = tomorrow;
                }

                // Step 2: Populate EDI Last Updated if empty
                string ediLastUpdated = this.Data.Fields[FLD_EDI_LAST_UPDATED].FieldValue ?? string.Empty;
                if (string.IsNullOrWhiteSpace(ediLastUpdated))
                {
                    this.Data.Fields[FLD_EDI_LAST_UPDATED].FieldValue = today;
                    ediLastUpdated = today;
                }

                // Step 3: Check EDI Updated if EDI Last Updated matches today
                if (ediLastUpdated == today)
                {
                    this.Data.Fields[FLD_EDI_UPDATED].FieldValue = "Y";
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = $"[ASI_IM_Gen_Discontinued_Check] Error: {ex.Message}";
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "When Discontinued is checked, auto-populates EDI Discontinued Date, EDI Last Updated, and EDI Updated fields.";

        public override string GetName() =>
            "ASI_IM_Gen_Discontinued_Check_v2";
    }
}
