using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;

#nullable disable
namespace kb_RibbonMetrics_r1;

public class kb_CustRM_getYTDSalesAbbr : P21.Extensions.BusinessRule.Rule
{
  public override RuleResult Execute()
  {
    RuleResult ruleResult = new RuleResult();
    kb_SQLHelper kbSqlHelper = new kb_SQLHelper();
    string ruleName = nameof(kb_CustRM_getYTDSalesAbbr);
    string connectionString = string.Empty;

    if (string.IsNullOrEmpty(this.Data.Fields["cust_id"].FieldValue?.ToString()))
    {
      this.Data.Fields["business_rule_result"].FieldValue = "";
      ruleResult.Success = true;
      return ruleResult;
    }

    try
    {
      if (this.Data.Fields["cust_type"].FieldValue.Equals("Prospect"))
      {
        this.Data.Fields["business_rule_result"].FieldValue = "*PROS";
        this.Data.Fields["business_rule_result_color"].FieldValue = "f2a65a";
      }
      else
      {
        string outputNumber = string.Empty;
        string cmdText = @"SELECT dbo.kb_fn_number_shorten(ISNULL(SUM(ISNULL(sales_price_home,0)),0),1) AS output1,
                           ISNULL(SUM(ISNULL(sales_price_home,0)),0) AS output2
                           FROM kb_sales_history_report_view
                           WHERE year_for_period = CAST(YEAR(GETDATE()) AS CHAR(4))
                           AND customer_id = @CustNo";

        connectionString = kbSqlHelper.GetConnectionString(this.Session, ruleName);

        try
        {
          using (SqlConnection connection = new SqlConnection(connectionString))
          {
            connection.Open();
            using (SqlCommand sqlCommand = new SqlCommand(cmdText, connection))
            {
              sqlCommand.Parameters.Add("@CustNo", SqlDbType.Int).Value =
                int.Parse(this.Data.Fields["cust_id"].FieldValue.ToString());

              DataTable dataTable = new DataTable();
              using (SqlDataReader reader = sqlCommand.ExecuteReader())
                dataTable.Load(reader);

              if (dataTable.Rows.Count < 1)
              {
                kbSqlHelper.LogError(this.Session, ruleName,
                  $"Got no result for query using connection string: {connectionString} and customer ID: {this.Data.Fields["cust_id"].FieldValue}");
                ruleResult.Message = "Customer ID failed to retrieve results. This error has been logged. If it continues to happen, please contact Karen.\r\n\r\n- Karen's Ribbon Metric Business Rule for YTD sales (kb_CustRM_getYTDSalesAbbr).";
                ruleResult.Success = false;
                return ruleResult;
              }

              outputNumber = dataTable.Rows[0].Field<string>("output1");
            }
          }
        }
        catch (Exception ex)
        {
          kbSqlHelper.LogError(this.Session, ruleName,
            $"Getting data from SQL using connection string: {connectionString} and customer ID: {this.Data.Fields["cust_id"].FieldValue}", ex);
          ruleResult.Message = $"SQL Query failed: {ex.Message}\r\n\r\nThis error has been logged. If it continues to happen, please contact Karen.\r\n\r\n- Karen's Ribbon Metric Business Rule for YTD sales (kb_CustRM_getYTDSalesAbbr).";
          ruleResult.Success = false;
          return ruleResult;
        }

        this.Data.Fields["business_rule_result"].FieldValue = outputNumber;
      }

      ruleResult.Success = true;
      return ruleResult;
    }
    catch (Exception ex)
    {
      kbSqlHelper.LogError(this.Session, ruleName,
        $"General rule issue, using connection string: {connectionString} and customer ID: {this.Data.Fields["cust_id"].FieldValue}", ex);
      ruleResult.Success = false;
      ruleResult.Message = $"Rule execution failed: {ex.Message}\r\n\r\nThis error has been logged. If it continues to happen, please contact Karen.\r\n\r\n- Karen's Ribbon Metric Business Rule for YTD sales (kb_CustRM_getYTDSalesAbbr).";
      return ruleResult;
    }
  }

  public override string GetDescription()
  {
    return "Returns the customer's year to date sales in an abbreviated string format.";
  }

  public override string GetName()
  {
    return nameof(kb_CustRM_getYTDSalesAbbr);
  }
}
