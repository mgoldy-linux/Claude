// kb_Order_Workflow_v2
// Runs asynchronously after an Order is saved; calls dbo.kb_proc_br_oe_hdr_note
// to add the order notes, except for RMAs, quotes, and completed orders.
//
// 2026-06-23  Bus App Team
//   - REMOVED kb_SQLHelper: GetConnectionString/SqlConnection/Open replaced with
//     the base-class P21SqlConnection; LogError replaced with LogRuleError ->
//     native business_rule_log.
//   - CHANGED file-scoped namespace to block-scoped and REMOVED #nullable disable
//     (project targets C# 7.3 / .NET 4.7.2; both are C# 8+ features that will not
//     compile). REMOVED using System.Linq / System.Reflection (nameof replaces the
//     MethodBase name builder).
//   - ADDED ResolveConnection() async fallback: P21SqlConnection is proven in
//     SYNCHRONOUS rules, but this rule's work runs in ExecuteAsync. If the
//     framework connection is null/closed in that context, we build our own from
//     this.Session (the exact connection string the retired kb_SQLHelper used) and
//     dispose it; otherwise we reuse the framework connection without disposing it.

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace kb_Order_Validator_v2
{
  public class kb_Order_Workflow_v2 : P21.Extensions.BusinessRule.Rule
  {
    [Obsolete]
    public override void ExecuteAsync()
    {
      // Skip note creation for RMAs, quotes, and already-completed orders.
      if (this.Data.Fields["rma_flag"].FieldValue == "Y"
          || this.Data.Fields["quote"].FieldValue == "Y"
          || this.Data.Fields["oe_hdr_completed"].FieldValue == "Y")
        return;

      string orderNo = this.Data.Fields["order_no"].FieldValue;

      try
      {
        bool ownsConnection;
        SqlConnection connection = ResolveConnection(out ownsConnection);
        try
        {
          using (SqlCommand sqlCommand = new SqlCommand("dbo.kb_proc_br_oe_hdr_note", connection))
          {
            sqlCommand.CommandType = CommandType.StoredProcedure;
            sqlCommand.Parameters.Add("@ordernumber", SqlDbType.VarChar, 8).Value =
              (object)orderNo ?? DBNull.Value;
            sqlCommand.ExecuteNonQuery();
          }
        }
        finally
        {
          // Only dispose a connection WE created; never the framework's.
          if (ownsConnection)
            connection.Dispose();
        }
      }
      catch (Exception ex)
      {
        // Was kbSqlHelper.LogError -> kb_table_br_error_log; now native business_rule_log.
        LogRuleError($"Execution of dbo.kb_proc_br_oe_hdr_note for order# {orderNo} failed.\r\n{ex}");
      }
    }

    public override RuleResult Execute()
    {
      return new RuleResult() { Success = true };
    }

    // Returns an OPEN connection for this async rule. Prefers the base-class
    // P21SqlConnection (framework-owned -- not disposed). If it is null or not open
    // in this ExecuteAsync context, builds a private connection from the Session
    // (replicates the retired kb_SQLHelper.GetConnectionString) and reports that the
    // caller owns it. ownsConnection => caller must Dispose.
    private SqlConnection ResolveConnection(out bool ownsConnection)
    {
      SqlConnection conn = P21SqlConnection;
      if (conn != null && conn.State == ConnectionState.Open)
      {
        ownsConnection = false;
        return conn;
      }

      string connectionString =
        $"server={this.Session.Server};database={this.Session.Database};Trusted_Connection=true;application name=P21_BusinessRule_{nameof(kb_Order_Workflow_v2)}";
      conn = new SqlConnection(connectionString);
      conn.Open();
      ownsConnection = true;
      return conn;
    }

    // Replaces kb_SQLHelper.LogError / kb_table_br_error_log. Writes to the P21
    // native business_rule_log table so failures are queryable:
    // WHERE log_action = 'Error' AND rule_name = 'kb_Order_Workflow_v2'.
    // Best-effort: a logging failure must never mask the original rule error.
    private void LogRuleError(string details)
    {
      try
      {
        const string logSql =
          @"INSERT INTO business_rule_log
              (user_id, log_action, rule_name, rule_assembly_name, run_type,
               return_value, return_message,
               date_created, created_by, date_last_modified, last_maintained_by)
            VALUES
              (@User, 'Error', @Rule, @Asm, 'Asynchronous (Internal)',
               'Failure', @Msg,
               GETDATE(), @User, GETDATE(), @User)";

        bool ownsConnection;
        SqlConnection connection = ResolveConnection(out ownsConnection);
        try
        {
          using (SqlCommand logCmd = new SqlCommand(logSql, connection))
          {
            string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
              ? this.Session.UserID
              : "unknown";

            logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
            logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(kb_Order_Workflow_v2);
            logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
            logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
              details.Length > 8000 ? details.Substring(0, 8000) : details;
            logCmd.ExecuteNonQuery();
          }
        }
        finally
        {
          if (ownsConnection)
            connection.Dispose();
        }
      }
      catch
      {
        // Swallow -- logging must never mask the original error.
      }
    }

    public override string GetDescription()
    {
      return "Runs asynchronously after Order save to add the Order Notes when applicable.";
    }

    public override string GetName()
    {
      return nameof(kb_Order_Workflow_v2);
    }
  }
}
