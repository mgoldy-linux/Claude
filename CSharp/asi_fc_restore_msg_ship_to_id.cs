// =============================================================================
// asi_fc_restore_msg_ship_to_id
// Fires on: ship_to_id field change in Front Counter
//
// Purpose: Displays overdue invoice, missing contacts, and multiple contract
//          warnings that are suppressed globally by _oe_order_suppress_msgs.
//          Triggers on ship_to_id; customer_id is looked up from ship_to table.
//
// Version History:
//   v1  - Initial: check overdue invoices, missing contacts, and multiple
//         contracts; display results via ruleResult.Message
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace asi_fc_restore_msg_ship_to_id
{
    public class asi_fc_restore_msg_ship_to_id : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string shipToId = string.Empty;
            string customerId = string.Empty;

            try
            {
                shipToId = this.Data.Fields["ship_to_id"].FieldValue ?? string.Empty;

                // Look up customer_id from ship_to table
                // The form field for customer_id is unreliable when ship_to_id fires
                // customer_id is Decimal in ship_to — use Convert.ToString() to avoid cast errors
                if (!string.IsNullOrWhiteSpace(shipToId))
                {
                    const string customerQuery =
                        "SELECT customer_id FROM ship_to WHERE ship_to_id = @shipToId";

                    using (SqlCommand cmd = new SqlCommand(customerQuery, P21SqlConnection))
                    {
                        cmd.CommandType = CommandType.Text;
                        cmd.Parameters.Add("@shipToId", SqlDbType.VarChar, 50).Value = shipToId;

                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read() && !reader.IsDBNull(0))
                                customerId = Convert.ToString(reader.GetValue(0));
                        }
                    }
                }

                // Run customer checks and collect warning messages
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

                    if (messages.Count > 0)
                        ruleResult.Message = string.Join(Environment.NewLine, messages);
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = $"[asi_fc_restore_msg_ship_to_id] Error: ship_to_id='{shipToId}' customer_id='{customerId}' — {ex.Message}";
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Displays overdue invoice, missing contacts, and multiple contract warnings in Front Counter when ship_to_id is entered (restores messages suppressed globally by _oe_order_suppress_msgs).";

        public override string GetName() =>
            "asi_fc_restore_msg_ship_to_id";
    }
}
