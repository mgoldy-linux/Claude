using System;
using Prophet21.BusinessRules;

/// <summary>
/// Business Rule: ASI_IM_Gen_Discontinued_Check
/// Screen: Item Maintenance
/// Trigger Field: Discontinued (ufc_inv_mast_ud_discontinued)
///
/// When the Discontinued checkbox is checked, this rule:
///   1. Populates EDI Discontinued Date with today's date if currently empty.
///   2. Populates EDI Last Updated with today's date if currently empty.
///   3. Checks Exclude from EDI 832 if currently unchecked.
///   4. Checks EDI Updated if EDI Last Updated matches today's date.
/// </summary>
public class ASI_IM_Gen_Discontinued_Check : IValidator
{
    // Field names
    private const string FLD_DISCONTINUED          = "ufc_inv_mast_ud_discontinued";
    private const string FLD_EDI_DISCONTINUED_DATE = "ufc_inv_mast_ud_edi_discontinued_date";
    private const string FLD_EDI_LAST_UPDATED      = "ufc_inv_mast_ud_edi_last_updated";
    private const string FLD_EXCLUDE_FROM_EDI832   = "inv_mast.exclude_from_edi832_flag";
    private const string FLD_EDI_UPDATED           = "ufc_inv_mast_ud_edi_updated";

    public void Validate(IValidatorContext context)
    {
        // Only run logic when the Discontinued checkbox is being checked (true)
        bool isDiscontinued = context.GetFieldValue<bool>(FLD_DISCONTINUED);
        if (!isDiscontinued)
            return;

        DateTime today = DateTime.Today;

        // Step 1: Populate EDI Discontinued Date if empty
        DateTime? ediDiscontinuedDate = context.GetFieldValue<DateTime?>(FLD_EDI_DISCONTINUED_DATE);
        if (ediDiscontinuedDate == null)
        {
            context.SetFieldValue(FLD_EDI_DISCONTINUED_DATE, today);
        }

        // Step 2: Populate EDI Last Updated if empty
        DateTime? ediLastUpdated = context.GetFieldValue<DateTime?>(FLD_EDI_LAST_UPDATED);
        if (ediLastUpdated == null)
        {
            context.SetFieldValue(FLD_EDI_LAST_UPDATED, today);
            ediLastUpdated = today;
        }

        // Step 3: Check Exclude from EDI 832 if currently unchecked
        bool excludeFromEdi832 = context.GetFieldValue<bool>(FLD_EXCLUDE_FROM_EDI832);
        if (!excludeFromEdi832)
        {
            context.SetFieldValue(FLD_EXCLUDE_FROM_EDI832, true);
        }

        // Step 4: Check EDI Updated if EDI Last Updated matches today
        if (ediLastUpdated.HasValue && ediLastUpdated.Value.Date == today)
        {
            context.SetFieldValue(FLD_EDI_UPDATED, true);
        }
    }
}
