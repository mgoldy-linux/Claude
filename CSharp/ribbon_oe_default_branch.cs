using P21.Extensions.BusinessRule;
using System;
using System.Data.SqlClient;

namespace ribbon_oe_default_branch_T2
{
public class ribbon_oe_default_branch_T2 : P21.Extensions.BusinessRule.Rule
{
  public override RuleResult Execute()
  {
    RuleResult ruleResult = new RuleResult();

    try
    {
      string shipToId = this.Data.Fields["ship_to_id"].FieldValue;

      if (!string.IsNullOrWhiteSpace(shipToId))
      {
        using (SqlCommand sqlCommand = new SqlCommand("SELECT default_branch FROM ship_to WITH(NOLOCK) WHERE ship_to_id = @ship2id", this.P21SqlConnection))
        {
          sqlCommand.Parameters.AddWithValue("@ship2id", shipToId);

          using (SqlDataReader sqlDataReader = sqlCommand.ExecuteReader())
          {
            if (sqlDataReader.Read())
            {
              string defaultBranch = sqlDataReader["default_branch"].ToString();

              if (!string.IsNullOrWhiteSpace(defaultBranch))
              {
                this.Data.Fields["business_rule_result"].FieldValue           = defaultBranch;
                this.Data.Fields["business_rule_result_font_size"].FieldValue = "14";
                ruleResult.Success = true;
              }
              else
              {
                ruleResult.Success = false;
                ruleResult.Message = "No default branch found for ship to ID " + shipToId + ".";
              }
            }
            else
            {
              ruleResult.Success = false;
              ruleResult.Message = "No default branch found for ship to ID " + shipToId + ".";
            }
          }
        }
      }
      else
      {
        ruleResult.Success = false;
        ruleResult.Message = "Ship to ID is required.";
      }
    }
    catch (Exception ex)
    {
      ruleResult.Success = false;
      ruleResult.Message = ex.Message;
    }

    return ruleResult;
  }

  public override string GetDescription() => "Display default branch based on ship to ID.";

  public override string GetName() => nameof(ribbon_oe_default_branch_T2);
}
}