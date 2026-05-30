using System;
using System.Collections.Generic;
using P21.Extensions.BusinessRule;

namespace P21.Extensions.Examples
{
    /*
     * Description: Validates that each field passed in contains a standard 2-letter US state/territory code.
     * Applies to any state field (mail_state, ship_state, etc.) configured to use this rule.
     * Input is trimmed and uppercased before validation; the normalized value is written back on success.
     */
    public class ValidState : Rule
    {
        private static readonly HashSet<string> ValidStateCodes = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            // 50 states
            "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
            "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
            "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
            "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
            "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
            // District and territories
            "DC", "AS", "GU", "MP", "PR", "VI"
        };

        public override RuleResult Execute()
        {
            RuleResult result = new RuleResult();
            result.Success = true;

            try
            {
                foreach (DataField field in Data.Fields)
                {
                    if (field.ClassName == "global")
                        continue;

                    string raw = (field.FieldValue ?? string.Empty).Trim();

                    if (string.IsNullOrEmpty(raw))
                        continue;

                    string normalized = raw.ToUpper();

                    if (!ValidStateCodes.Contains(normalized))
                    {
                        result.Success = false;
                        result.Message = string.Format(
                            "'{0}' is not a valid 2-letter state code. Please enter a standard US state or territory abbreviation (e.g. IL, TX, CA).",
                            raw);
                        return result;
                    }

                    // Write the normalized (uppercased) value back so casing is always consistent
                    field.FieldValue = normalized;
                }
            }
            catch (Exception e)
            {
                result.Success = false;
                result.Message = e.Message;
            }

            return result;
        }

        public override string GetName()
        {
            return "Valid State Code";
        }

        public override string GetDescription()
        {
            return "Validates that the state field contains a standard 2-letter US state or territory abbreviation and normalizes it to uppercase.";
        }
    }
}
