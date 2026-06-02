// =============================================================================
// asi_fc_restore_msg_cust_id
// Fires on: customer_id field change in Front Counter
//
// Purpose: Companion to asi_fc_restore_msg_ship_to_id. Handles the case where
//          customer_id is entered directly and ship_to_id is auto-populated
//          programmatically (which does not fire the ship_to_id trigger).
//          Reads customer_id from the form field directly.
//          Runs overdue invoice and missing contacts checks only.
//
// Version History:
//   v1  - Initial: check overdue invoices and missing contacts;
//         display results via ruleResult.Message
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace asi_fc_restore_msg_cust_id
{
    public class asi_fc_restore_msg_cust_id : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string customerId = string.Empty;

            try
            {
                // Read customer_id directly from the form field
                customerId = this.Data.Fields["customer_id"].FieldValue ?? string.Empty;

                if (!string.IsNullOrWhiteSpace(customerId))
                {
                    List<string> messages = new List<string>();

                    // Check for overdue invoices (> 20 days past due) — replaces suppressed message 688
                    const string overdueQuery =
                        @"SELECT COUNT(*)
                          FROM p21_view_invoice_hdr
                          WHERE customer_id = @customerId
                            AND company_no = 1
                            AND approved = 'Y'
                            AND paid_in_full_flag = 'N'
                            AND consolidated <> 'Y'
                            AND COALESCE(record_type_cd, 0) <> 3023
                            AND DATEDIFF(dd, net_due_date, CURRENT_TIMESTAMP) > 20
                            AND disputed_flag = 'N'
                            AND (total_amount - amount_paid - terms_taken - allowed
                                 + memo_amount + bad_debt_amount - tax_terms_taken) > 0";

                    using (SqlCommand cmd = new SqlCommand(overdueQuery, P21SqlConnection))
                    {
                        cmd.CommandType = CommandType.Text;
                        cmd.Parameters.Add("@customerId", SqlDbType.VarChar, 50).Value = customerId;

                        if (Convert.ToInt32(cmd.ExecuteScalar()) > 0)
                            messages.Add("This customer has overdue invoices.  This order will be placed on credit hold.");
                    }

                    // Check for no contacts — replaces suppressed message 451
                    const string contactsQuery =
                        @"SELECT COUNT(*)
                          FROM oe_contacts_customer
                          INNER JOIN contacts
                            ON oe_contacts_customer.contact_id = contacts.id
                           AND contacts.delete_flag <> 'Y'
                          WHERE oe_contacts_customer.company_id  = 1
                            AND oe_contacts_customer.customer_id = @customerId
                            AND oe_contacts_customer.delete_flag <> 'Y'";

                    using (SqlCommand cmd = new SqlCommand(contactsQuery, P21SqlConnection))
                    {
                        cmd.CommandType = CommandType.Text;
                        cmd.Parameters.Add("@customerId", SqlDbType.VarChar, 50).Value = customerId;

                        if (Convert.ToInt32(cmd.ExecuteScalar()) == 0)
                            messages.Add("No contacts exist for this customer.");
                    }

                    if (messages.Count > 0)
                        ruleResult.Message = string.Join(Environment.NewLine, messages);
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = $"[asi_fc_restore_msg_cust_id] Error: customer_id='{customerId}' — {ex.Message}";
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Displays overdue invoice and missing contacts warnings in Front Counter when customer_id is entered directly (companion to asi_fc_restore_msg_ship_to_id).";

        public override string GetName() =>
            "asi_fc_restore_msg_cust_id";
    }
}
