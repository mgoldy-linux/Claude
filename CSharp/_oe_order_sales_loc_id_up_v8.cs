// =============================================================================
// _oe_order_sales_loc_id_up
// Fires on: ship_to_id field change in Order Entry
//
// Version History:
//   v1  - Initial: auto-set sales_loc_id from ship-to default branch
//   v2  - Renamed class and namespace to v2
//   v3  - Added overdue invoice (>20 days) and missing contacts warnings
//   v4  - Null-safe field reads (?? string.Empty)
//         Safe ExecuteScalar cast (Convert.ToInt32 vs hard cast)
//         Improved error message includes both ship_to_id and customer_id
//   v4d - Debug: moved ruleResult.Message outside customer check block
//         to always fire in live and confirm whether customerId is populated
//   v5  - Same as v4d; investigating why live shows no message despite
//         customer having overdue invoices (suspect customerId empty on fire)
//   v6  - Fix: customer_id field is empty in live when ship_to_id fires
//         Pull customer_id from ship_to table in the same query as
//         default_branch instead of relying on the form field
//   v7  - Fix: customer_id in ship_to table is Decimal not string
//         Use Convert.ToString(reader.GetValue(1)) instead of reader.GetString(1)
//   v8  - Added multiple-contract check (message 8280): if more than one active 
//         contract matches customer_id / ship_to_id / location, warn the user to
//         select a Contract No.
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace _oe_order_sales_loc_id_up_v8
{
    public class _oe_order_sales_loc_id_up_v8 : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();
            string shipToId = string.Empty;
            string customerId = string.Empty;
            string defaultBranch = string.Empty;

            try
            {
                shipToId = this.Data.Fields["ship_to_id"].FieldValue ?? string.Empty;

                // Set sales_loc_id from ship-to default branch
                // Also pull customer_id from ship_to table — the form field is
                // empty in live P21 when ship_to_id fires (v5 debug confirmed this)
                // customer_id is Decimal in ship_to — use Convert.ToString() (v7 fix)
                if (!string.IsNullOrWhiteSpace(shipToId))
                {
                    const string branchQuery =
                        "SELECT default_branch, customer_id FROM ship_to WHERE ship_to_id = @shipToId";

                    using (SqlCommand cmd = new SqlCommand(branchQuery, P21SqlConnection))
                    {
                        cmd.CommandType = CommandType.Text;
                        cmd.Parameters.Add("@shipToId", SqlDbType.VarChar, 50).Value = shipToId;

                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                if (!reader.IsDBNull(0))
                                {
                                    defaultBranch = reader.GetString(0);
                                    if (!string.IsNullOrWhiteSpace(defaultBranch))
                                        this.Data.Fields["sales_loc_id"].FieldValue = defaultBranch;
                                }

                                if (!reader.IsDBNull(1))
                                    customerId = Convert.ToString(reader.GetValue(1));
                            }
                        }
                    }
                }

                // Customer checks — overdue invoices and contacts
                if (!string.IsNullOrWhiteSpace(customerId))
                {
                    List<string> messages = new List<string>();

                    // Check for overdue invoices (> 20 days past due)
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
                            messages.Add("This customer has overdue invoices.");
                    }

                    // Check for no contacts
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
                            messages.Add("No contacts found.");
                    }

                    // Check for multiple active contracts (message 8280)
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
                          AND end_date >= GETDATE()
                          AND (location_id IS NULL OR location_id = @locationId)";

                    using (SqlCommand cmd = new SqlCommand(contractQuery, P21SqlConnection))
                    {
                        cmd.CommandType = CommandType.Text;
                        cmd.Parameters.Add("@customerId", SqlDbType.VarChar, 50).Value = customerId;
                        cmd.Parameters.Add("@shipToId", SqlDbType.VarChar, 50).Value = shipToId;
                        cmd.Parameters.Add("@locationId", SqlDbType.VarChar, 50).Value = defaultBranch;

                        if (Convert.ToInt32(cmd.ExecuteScalar()) > 1)
                            messages.Add("Multiple contracts found. Please select a Contract No.");
                    }

                    if (messages.Count > 0)
                        ruleResult.Message = string.Join(Environment.NewLine, messages);
                }
            }
            catch (Exception ex)
            {
                ruleResult.Message = $"[_oe_order_sales_loc_id_up_v8] Error: ship_to_id='{shipToId}' customer_id='{customerId}' — {ex.Message}";
            }

            return ruleResult;
        }

        public override string GetDescription() =>
            "Auto-sets sales location from ship-to default branch; warns on overdue invoices, missing contacts or multiple contracts.";

        public override string GetName() =>
            "_oe_order_sales_loc_id_up_v8";
    }
}


