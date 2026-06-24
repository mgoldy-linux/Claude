// from kb_Order_Validator_v2.dll → kb_Order_Workflow_v2

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;

#nullable disable
namespace kb_Order_Validator_v2;

public class kb_Order_Workflow_v2 : P21.Extensions.BusinessRule.Rule
{
  [Obsolete]
  public override void ExecuteAsync()
  {
    RuleResult ruleResult = new RuleResult();
    kb_SQLHelper kbSqlHelper = new kb_SQLHelper();
    string connectionString = string.Empty;
    if (this.Data.Fields["rma_flag"].FieldValue == "Y" || this.Data.Fields["quote"].FieldValue == "Y" || this.Data.Fields["oe_hdr_completed"].FieldValue == "Y")
    {
      ruleResult.Success = true;
    }
    else
    {
      try
      {
        connectionString = kbSqlHelper.GetConnectionString(this.Session, new string(MethodBase.GetCurrentMethod().DeclaringType.Name.Where<char>(new System.Func<char, bool>(char.IsLetterOrDigit)).ToArray<char>()));
        using (SqlConnection connection = new SqlConnection(connectionString))
        {
          connection.Open();
          SqlCommand sqlCommand = new SqlCommand("dbo.kb_proc_br_oe_hdr_note", connection);
          sqlCommand.CommandType = CommandType.StoredProcedure;
          sqlCommand.Parameters.Add("@ordernumber", SqlDbType.VarChar, 8).Value = (object) this.Data.Fields["order_no"].FieldValue;
          sqlCommand.ExecuteNonQuery();
        }
        ruleResult.Success = true;
      }
      catch (Exception ex)
      {
        kbSqlHelper.LogError(this.Session, new string(MethodBase.GetCurrentMethod().DeclaringType.Name.Where<char>(new System.Func<char, bool>(char.IsLetterOrDigit)).ToArray<char>()), $"Connection and execution of kb_proc_br_oe_hdr_note for order# {this.Data.Fields["order_no"].FieldValue} using connection string: {connectionString}.", ex);
        ruleResult.Message = ex.Message;
        ruleResult.Success = false;
      }
    }
  }

  public override RuleResult Execute()
  {
    return new RuleResult() { Success = true };
  }

  public override string GetDescription()
  {
    return "Runs asynchronously after Order save to add the Order Notes when applicable.";
  }

  public override string GetName()
  {
    return new string(MethodBase.GetCurrentMethod().DeclaringType.Name.Where<char>(new System.Func<char, bool>(char.IsLetterOrDigit)).ToArray<char>());
  }
}
