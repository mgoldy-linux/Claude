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
            "DC", "AS", "GU", "MP", "PR", "VI",
            // USPS military APO/FPO codes
            "AA", "AE", "AP"
        };

        public override RuleResult Execute()
        {
            RuleResult result = new RuleResult();
            result.Success = true;

            if (Data == null || Data.Fields == null)
            {
                result.Success = false;
                result.Message = "No field data was provided to the ValidState rule.";
                return result;
            }

            try
            {
                // Pass 1: validate all fields and collect every invalid value before reporting
                var errors = new List<string>();
                foreach (DataField field in Data.Fields)
                {
                    if (string.Equals(field.ClassName, "global", StringComparison.OrdinalIgnoreCase))
                        continue;

                    string raw = (field.FieldValue ?? string.Empty).Trim();

                    if (string.IsNullOrEmpty(raw))
                        continue;

                    if (!ValidStateCodes.Contains(raw))
                        errors.Add(string.Format("'{0}' ({1})", raw, field.FieldName));
                }

                if (errors.Count > 0)
                {
                    string body = string.Format(
                        "Invalid state code{0}: {1}\n\nPlease use a standard 2-letter US state or territory abbreviation (e.g. IL, TX, CA).",
                        errors.Count > 1 ? "s" : "",
                        string.Join(", ", errors));

                    result.Success = false;
                    result.Message = body;

                    if (IsInteractiveContext())
                    {
                        result.ShowResponse = true;
                        result.ResponseAttributes = new ResponseAttributes(
                            "Invalid State Code",
                            body,
                            null)
                        {
                            Buttons = new[] { new ResponseButton("OK", "OK", "OK") }
                        };
                    }
                    return result;
                }

                // Pass 2: all fields are valid — write normalized (uppercase) values back
                foreach (DataField field in Data.Fields)
                {
                    if (string.Equals(field.ClassName, "global", StringComparison.OrdinalIgnoreCase))
                        continue;

                    string raw = (field.FieldValue ?? string.Empty).Trim();

                    if (string.IsNullOrEmpty(raw))
                        continue;

                    if (!field.ReadOnly)
                        field.FieldValue = raw.ToUpper();
                }
            }
            catch (Exception e)
            {
                Log.AddAndPersist(string.Format(
                    "[ValidState] Unhandled exception in Execute: {0}\nStackTrace: {1}",
                    e.Message, e.StackTrace));
                result.Success = false;
                result.Message = "An unexpected error occurred in the ValidState rule. Please contact your system administrator.";
            }

            return result;
        }

        private bool IsInteractiveContext()
        {
            // A populated trigger window name means the rule fired from a UI form
            if (RuleState != null && !string.IsNullOrEmpty(RuleState.TriggerWindowName))
                return true;

            // Batch, API, and EDI contexts have no Win/Web client platform
            if (Session != null)
            {
                string platform = Session.ClientPlatform ?? string.Empty;
                return platform.IndexOf("Win", StringComparison.OrdinalIgnoreCase) >= 0
                    || platform.IndexOf("Web", StringComparison.OrdinalIgnoreCase) >= 0;
            }

            return false;
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
