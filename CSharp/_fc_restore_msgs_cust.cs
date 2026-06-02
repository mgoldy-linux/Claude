// =============================================================================
// _fc_restore_msgs_cust
// Fires on: customer_id field change in Front Counter
//
// Purpose: Companion to _fc_restore_msgs. Handles the case where customer_id
//          is entered directly and ship_to_id is auto-populated programmatically
//          (which does not fire the ship_to_id business rule trigger).
//          Reads customer_id from the form field directly.
//          Reads ship_to_id from the form field if available (needed for
//          multiple contracts check only).
//
// Version History:
//   v1  - Initial: check overdue invoices, missing contacts, and multiple
//         contracts; display results via ruleResult.Message
//   v2  - Companion rule to _fc_restore_msgs; triggers on customer_id to
//         handle case where ship_to_id is auto-populated programmatically
//         and does not fire the ship_to_id trigger
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace _fc_restore_msgs_cust
{
    public class _fc_restore_msgs_cust : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string customerId = string.Empty;
            string shipToId = string.Empty;

            try
            {
                // Read customer_id directly from the form field
                customerId = this.Data.Fields["customer_id"].FieldValue ?? string.Empty;

                // Read ship_to_id from the form — may be empty if not yet populated
                shipToId = this.Data.Fields["ship_to_id"].FieldValue ?? string.Empty;

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

                    // Check for multiple active contracts — replaces suppressed message 8280
                    // Only runs if ship_to_id is available on the form at the time customer_id fires
                    if (!string.IsNullOrWhiteSpace(shipToId))
                    {
                        const string contractQuery =
                            @"SELECT COUNT(*)
                              FROM job_price_hdr
                              INNER JOIN job_price_customer_shipto
                                ON job_price_customer_shipto.job_price_hdr_uid = job_price_hdr.job_price_hdr_uid
                              WHERE EXISTS (
                                  SELECT 1
                                  FROM job_price_line
                                  INNER JOIN customer
                                    ON customer.customer_id = @customerId
                                   AND customer.company_id = '1'
                                  WHERE job_price_line.job_price_hdr_uid = job_price_hdr.job_price_hdr_uid
                                    AND ((job_price_line.qty_ordered < job_price_line.qty_maximum)
                                      OR (job_price_line.qty_maximum = 0)
                                      OR (customer.allow_exceed_job_qty = 'Y'))
                              )
                              AND job_price_hdr.company_id = '1'
                              AND job_price_customer_shipto.customer_id = @customerId
                              AND job_price_customer_shipto.ship_to_id = @shipToId
                              AND job_price_customer_shipto.row_status_flag = 704
                              AND job_price_hdr.row_status_flag = 704
                              AND job_price_hdr.cancelled <> 'Y'
                              AND job_price_hdr.approved <> 'N'
                              AND start_date <= GETDATE()
                              AND end_date >= GETDATE()";

                        using (SqlCommand cmd = new SqlCommand(contractQuery, P21SqlConnection))
                        {
                            cmd.CommandType = CommandType.Text;
                            cmd.Parameters.Add("@customerId", SqlDbType.VarChar, 50).Value = customerId;
                            cmd.Parameters.Add("@shipToId", SqlDbType.VarChar, 50).Value = shipToId;

                            if (Convert.ToInt32(cmd.ExecuteScalar()) > 1)
                                messages.Add("Multiple contracts found for Customer ID and Ship To ID combination. Please, select a Contract No.");
                        }
                    }

                    if (messages.Count > 0)
                        ruleResult.Message = string.Join(Environment.NewLine, messages);
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = $"[_fc_restore_msgs_cust] Error: customer_id='{customerId}' ship_to_id='{shipToId}' — {ex.Message}";
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Displays overdue invoice, missing contacts, and multiple contract warnings in Front Counter when customer_id is entered directly (companion to _fc_restore_msgs).";

        public override string GetName() =>
            "_fc_restore_msgs_cust";
    }
}
