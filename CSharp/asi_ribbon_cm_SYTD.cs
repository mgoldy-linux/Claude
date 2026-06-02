// ============================================================
// asi_ribbon_cm_SYTD.cs
// ============================================================
// Description : Returns the customer's YTD sales as an abbreviated string for the P21 customer ribbon.
// Namespace   : asi_RibbonMetrics
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-03-27  Bus App Team
//   - RENAMED from kb_CustRM_getYTDSalesAbbr
//   - RENAMED namespace from kb_RibbonMetrics_r1 to asi_RibbonMetrics
//   - REMOVED #nullable disable (not required by project)
//   - REMOVED using System.Reflection, using System.Linq (no longer needed after LINQ expression removed)
//   - CHANGED GetFieldByAlias("cust_id") x7 to this.Data.Fields["customer_id"] direct access
//   - CHANGED GetFieldByAlias("cust_type") to this.Data.Fields["customer_type_cd"] direct access
//   - CHANGED class name LINQ expression x5 to nameof() declared once as: string ruleName = nameof(...)
//   - CHANGED private string outputNumber (instance field) to local variable inside else block
//   - CHANGED SQL year filter Year(GetDate()) [INT] to CAST(YEAR(GETDATE()) AS CHAR(4)) [CHAR] -- ROOT CAUSE FIX: year_for_period is VARCHAR, implicit conversion was returning zero rows
//   - REMOVED redundant connection.Close() inside using block
//   - CHANGED GetName() LINQ expression to nameof()
//   - CHANGED error messages from "contact Karen" to "contact the Bus App Team"
//   - REMOVED kb_SQLHelper and all LogError calls -- P21 built-in business rule logging used instead
//   - REMOVED ruleName -- only used for LogError calls
//   - REMOVED connectionString -- replaced with P21SqlConnection -- P21 Rule base class provides connection directly
//   - CHANGED namespace syntax to block-scoped (C# 7.3)
//   - RENAMED field cust_id to customer_id
//   - CHANGED SQL source from kb_sales_history_report_view to p21_sales_history_view (P21 native view)
//   - CHANGED year_for_period filter from CAST(YEAR(GETDATE()) AS CHAR(4)) to YEAR(GETDATE()) -- year_for_period is DECIMAL in p21 view
//   - CHANGED @CustNo parameter from SqlDbType.Int to SqlDbType.VarChar -- customer_id is VARCHAR in p21_sales_history_view
//   - CHANGED SELECT to raw SUM only -- kb_fn_number_shorten removed
//   - ADDED net sales filters: item_id <> 'CREDITMISC' (excludes credit memos), rma_flag <> 'Y' (excludes return lines)
//   - ADDED DISTINCT invoice_line_uid subquery to deduplicate rows caused by multiple salesreps per invoice line
//   - ADDED FormatSalesAbbr() -- inline C# number abbreviation replaces kb_fn_number_shorten entirely
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_RibbonMetrics
{
  public class asi_ribbon_cm_SYTD : P21.Extensions.BusinessRule.Rule
  {
    public override RuleResult Execute()
    {
      RuleResult ruleResult = new RuleResult();

      // CHANGED: direct field access replaces GetFieldByAlias()
      // CHANGED: cust_id renamed to customer_id
      if (string.IsNullOrEmpty(this.Data.Fields["customer_id"].FieldValue?.ToString()))
      {
        this.Data.Fields["business_rule_result"].FieldValue = "";
        ruleResult.Success = true;
        return ruleResult;
      }

      try
      {
        // CHANGED: direct field access replaces GetFieldByAlias()
        if (this.Data.Fields["customer_type_cd"].FieldValue.Equals("Prospect"))
        {
          this.Data.Fields["business_rule_result"].FieldValue = "*PROS";
          this.Data.Fields["business_rule_result_color"].FieldValue = "FF8C00";
        }
        else
        {
          // CHANGED: local variable, was private instance field
          string outputNumber = string.Empty;

          // CHANGED: p21_sales_history_view replaces kb_sales_history_report_view
          // CHANGED: year_for_period = YEAR(GETDATE()) -- DECIMAL in p21 view, no CAST needed
          // CHANGED: DISTINCT invoice_line_uid deduplicates multiple salesrep rows per line
          // CHANGED: net sales filters exclude credit memos, other charge items,
          //          non-inventory items (payment/financial lines have inv_mast_uid = NULL or 0)
          //          rma_flag excluded -- product returns (rma_flag='Y') ARE included in net sales
          // CHANGED: raw SUM only -- formatting handled in C# by FormatSalesAbbr()
          // CHANGED: incentive rewards subtracted per line -- matches kb_ sales_price_home calculation
          //          LEFT JOIN p21_view_rewards_program_values SUM(accumulated_incentive_points)
          const string cmdText =
            @"SELECT ISNULL(SUM(ISNULL(s.extended_price_home, 0) - ISNULL(r.total_rewards, 0)), 0) AS output2
              FROM (
                SELECT DISTINCT invoice_line_uid, extended_price_home
                FROM p21_sales_history_view
                WHERE year_for_period = YEAR(GETDATE())
                AND customer_id = @CustNo
                AND item_id NOT IN ('CREDITMISC', 'DOWNPAYMENT', 'PREPAYMENT')
                AND other_charge_item = 'N'
                AND inv_mast_uid <> 0
              ) s
              LEFT JOIN (
                SELECT invoice_line_uid, SUM(accumulated_incentive_points) AS total_rewards
                FROM p21_view_rewards_program_values
                WHERE row_status_flag = 704
                GROUP BY invoice_line_uid
              ) r ON s.invoice_line_uid = r.invoice_line_uid";

          // CHANGED: P21SqlConnection replaces kb_SQLHelper.GetConnectionString
          //          + SqlConnection -- P21 Rule base class provides connection
          using (SqlCommand sqlCommand = new SqlCommand(cmdText, P21SqlConnection))
          {
            sqlCommand.CommandType = CommandType.Text;

            // CHANGED: direct field access replaces GetFieldByAlias()
            // CHANGED: cust_id renamed to customer_id
            // CHANGED: SqlDbType.VarChar -- customer_id is VARCHAR in p21_sales_history_view
            sqlCommand.Parameters.Add("@CustNo", SqlDbType.VarChar).Value =
              this.Data.Fields["customer_id"].FieldValue.ToString();

            DataTable dataTable = new DataTable();
            using (SqlDataReader reader = sqlCommand.ExecuteReader())
              dataTable.Load(reader);

            if (dataTable.Rows.Count < 1)
            {
              // REMOVED: kbSqlHelper.LogError -- P21 built-in logging used
              ruleResult.Message = "Customer ID failed to retrieve results. This error has been logged. If it continues to happen, please contact the Bus App Team.\r\n\r\n- asi_ribbon_cm_SYTD";
              ruleResult.Success = false;
              return ruleResult;
            }

            // CHANGED: raw decimal value -- formatted by FormatSalesAbbr()
            //          replaces kb_fn_number_shorten call in SQL
            decimal rawValue = dataTable.Rows[0].Field<decimal>("output2");
            outputNumber = FormatSalesAbbr(rawValue);
          }

          this.Data.Fields["business_rule_result"].FieldValue = outputNumber;
        }

        ruleResult.Success = true;
        return ruleResult;
      }
      catch (Exception ex)
      {
        // REMOVED: kbSqlHelper.LogError -- P21 built-in logging used
        ruleResult.Success = false;
        ruleResult.Message = $"Rule execution failed: {ex.Message}\r\n\r\nThis error has been logged. If it continues to happen, please contact the Bus App Team.\r\n\r\n- asi_ribbon_cm_SYTD";
        return ruleResult;
      }
    }

    public override string GetDescription()
    {
      return "Returns the customer's year to date sales in an abbreviated string format.";
    }

    public override string GetName()
    {
      // CHANGED: nameof() replaces LINQ expression
      return nameof(asi_ribbon_cm_SYTD);
    }

    // ADDED: replaces kb_fn_number_shorten
    // Formats a decimal sales value as an abbreviated string:
    //   >= 1,000,000  →  $1.3mln
    //   >= 1,000      →  $2.4k
    //   < 1,000       →  $450
    //   negative      →  -$2.1k
    private static string FormatSalesAbbr(decimal value)
    {
      if (value == 0m)
        return "$0";

      bool negative = value < 0m;
      decimal abs = Math.Abs(value);
      string formatted;

      if (abs >= 1000000m)
        formatted = "$" + Math.Round(abs / 1000000m, 1).ToString("0.#") + "mln";
      else if (abs >= 1000m)
        formatted = "$" + Math.Round(abs / 1000m, 1).ToString("0.#") + "k";
      else
        formatted = "$" + Math.Round(abs, 0).ToString("0");

      return negative ? "-" + formatted : formatted;
    }
  }
}
