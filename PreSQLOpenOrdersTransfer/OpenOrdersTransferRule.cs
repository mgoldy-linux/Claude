using System;
using P21.Extensions.BusinessRule;

namespace PreSQLOpenOrdersTransfer
{
    /// <summary>
    /// Pre-SQL Business Rule for d_dw_portal_open_orders in Customer Master Inquiry.
    /// 
    /// Purpose: Modifies the Open Orders query to calculate the "Items on Transfer" 
    /// column (ufc_p21soc_items_on_transfer) instead of returning NULL.
    /// 
    /// Changes made to original SQL:
    /// 1. Adds SUM(CASE WHEN oe_line.disposition = 'T' THEN 1 ELSE 0 END) items_on_transfer
    ///    to the der_unshipped_value subquery.
    /// 2. Replaces NULL ufc_p21soc_items_on_transfer with:
    ///    CASE WHEN der_unshipped_value.items_on_transfer > 0 THEN 'Y' ELSE 'N' END
    /// </summary>
    public class OpenOrdersTransferRule : Rule
    {
        public override string GetName()
        {
            return "OpenOrdersTransferRule";
        }

        public override string GetDescription()
        {
            return "Pre-SQL rule that modifies the Open Orders query in Customer Master Inquiry " +
                   "to calculate Items on Transfer (disposition = 'T') instead of returning NULL " +
                   "for the ufc_p21soc_items_on_transfer column.";
        }

        public override RuleResult Execute()
        {
            RuleResult result = new RuleResult();

            try
            {
                // Get the current SQL statement via the Pre-SQL hook API
                string originalSql = Data.Fields["sql_statement"].FieldValue;

                if (string.IsNullOrEmpty(originalSql))
                {
                    result.Success = true;
                    return result;
                }

                string modifiedSql = originalSql;

                // ---------------------------------------------------------------
                // MODIFICATION 1: Add items_on_transfer to der_unshipped_value subquery
                // ---------------------------------------------------------------
                // MUST run before Modification 2, because Mod 2 adds "items_on_transfer"
                // to the outer SELECT, which would trip the idempotency check here.
                //
                // We match "END) items_on_direct_ship" which only appears inside the 
                // subquery (the outer SELECT uses "der_unshipped_value.items_on_direct_ship").

                string subqueryAnchor = "END) items_on_direct_ship";
                string transferColumn = " ,SUM(CASE WHEN oe_line.disposition = 'T' THEN 1 ELSE 0 END) items_on_transfer";

                // Idempotency: check for the SUM expression specifically, not just the column name
                if (!modifiedSql.Contains("disposition = 'T'"))
                {
                    int anchorPos = modifiedSql.IndexOf(subqueryAnchor, StringComparison.OrdinalIgnoreCase);

                    if (anchorPos >= 0)
                    {
                        int insertPos = anchorPos + subqueryAnchor.Length;
                        modifiedSql = modifiedSql.Insert(insertPos, transferColumn);
                    }
                }

                // ---------------------------------------------------------------
                // MODIFICATION 2: Replace NULL ufc_p21soc_items_on_transfer with calculation
                // ---------------------------------------------------------------
                // The original column is:  NULL ufc_p21soc_items_on_transfer
                // Replace with:            CASE WHEN der_unshipped_value.items_on_transfer > 0 THEN 'Y' ELSE 'N' END ufc_p21soc_items_on_transfer

                string originalColumn = "NULL ufc_p21soc_items_on_transfer";
                string replacementColumn = "CASE WHEN der_unshipped_value.items_on_transfer > 0 THEN 'Y' ELSE 'N' END ufc_p21soc_items_on_transfer";

                if (modifiedSql.IndexOf(originalColumn, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    int nullPos = modifiedSql.IndexOf(originalColumn, StringComparison.OrdinalIgnoreCase);
                    modifiedSql = modifiedSql.Substring(0, nullPos) 
                                + replacementColumn 
                                + modifiedSql.Substring(nullPos + originalColumn.Length);
                }

                // Pass the modified SQL back to Prophet 21
                Data.Fields["sql_statement"].FieldValue = modifiedSql;

                result.Success = true;
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.Message = "OpenOrdersTransferRule Error: " + ex.Message;
            }

            return result;
        }
    }
}
