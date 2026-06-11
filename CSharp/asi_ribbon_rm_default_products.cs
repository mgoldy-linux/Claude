// ============================================================
// asi_ribbon_rm_default_products.cs
// ============================================================
// Description : Returns the item commission classes the salesrep is paid on by
//               default (for new customer assignments), for the P21 salesrep ribbon.
// Namespace   : asi_RibbonMetrics
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-06-11  Bus App Team
//   - RENAMED from kb_RepRM_getDefaultProducts
//   - RENAMED namespace from kb_RibbonMetrics_r1 to asi_RibbonMetrics
//   - REMOVED #nullable disable (not required by project)
//   - REMOVED using System.Reflection, using System.Linq (no longer needed after LINQ expressions removed)
//   - CHANGED GetFieldByAlias("salesrep_id") x4 to this.Data.Fields["salesrep_id"] direct access
//   - CHANGED class name LINQ expression x4 to nameof()
//   - CHANGED private string outputNumber (instance field) to local variable
//   - REMOVED kb_SQLHelper and all LogError calls -- P21 built-in business rule logging used instead
//   - REMOVED connectionString -- replaced with P21SqlConnection -- P21 Rule base class provides connection directly
//   - REMOVED redundant connection.Close() inside using block
//   - REMOVED redundant inner try-catch (outer catch covers it)
//   - REMOVED unused local: string empty
//   - CHANGED namespace syntax to block-scoped (C# 7.3)
//   - CHANGED error messages from "contact Karen" to "contact the Bus App Team"
//   - CHANGED SQL source from kb_view_salesrep_type to inline query against base tables
//     (salesrep_commission, commission_schedule, commission_schedule_detail,
//      commission_rule, commission_rule_detail, item_commission_class)
//     -- parity-verified 109/109 reps identical to kb_view_salesrep_type.default_paid_comclass
//     -- the kb_ view computed pivots/managers/summaries for ALL reps per ribbon lookup
//   - CHANGED @RepID parameter from SqlDbType.Int to SqlDbType.VarChar
//     -- salesrep_commission.salesrep_id is VARCHAR; removes Convert.ToInt32 crash on
//        non-numeric field values
//   - CHANGED no-data behavior -- ROOT CAUSE FIX: reps with no commission schedule
//     (none assigned at rep setup since 2024) were INNER JOINed out of the kb_ view,
//     showing "n/a"/blank. Now shows "No comm schedule" so the missing setup step is
//     visible; reps paid on no classes show "None" instead of NULL/blank.
//   - ADDED LogRuleError() -- writes errors to P21 native business_rule_log table
//     (log_action='Error', return_value='Failure') -- replaces kb_table_br_error_log;
//     best-effort insert, never masks the original failure
//   - ADDED fallback to asi_table_customer_comclass_salesrep for reps with no
//     commission schedule -- shows DISTINCT classes from actual customer assignments
//     (matches the salesrep assignment tool); 18 of 21 no-schedule reps get real data;
//     schedule-derived output unchanged for the 83 scheduled reps (parity preserved)
// ============================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace asi_RibbonMetrics
{
  public class asi_ribbon_rm_default_products : P21.Extensions.BusinessRule.Rule
  {
    public override RuleResult Execute()
    {
      RuleResult ruleResult = new RuleResult();

      // CHANGED: direct field access replaces GetFieldByAlias()
      if (string.IsNullOrEmpty(this.Data.Fields["salesrep_id"].FieldValue?.ToString()))
      {
        this.Data.Fields["business_rule_result"].FieldValue = "";
        ruleResult.Success = true;
        return ruleResult;
      }

      try
      {
        // CHANGED: inline query against base tables replaces kb_view_salesrep_type
        //   Paid classes = all active item commission classes MINUS classes the rep's
        //   commission schedule explicitly omits (rule grouped by item commission class
        //   with an exception detail row: break_type = 'E', value = 0.0001).
        //   FALLBACK: reps with no commission schedule (none assigned at setup since 2024)
        //   show their actual customer assignments from asi_table_customer_comclass_salesrep
        //   (the source behind the salesrep assignment tool). Only reps absent from BOTH
        //   sources get 'No comm schedule' (was: dropped by kb_ view INNER JOIN, showed "n/a").
        const string cmdText =
          @"SELECT CASE
              WHEN EXISTS (
                SELECT 1 FROM salesrep_commission AS src
                WHERE src.salesrep_id = @RepID
                  AND COALESCE(src.commission_schedule_id,'') <> ''
              ) THEN ISNULL(STUFF((
                  SELECT ', ' + icc.commission_class_id
                  FROM item_commission_class AS icc
                  WHERE icc.delete_flag = 'N'
                    AND NOT EXISTS (
                      SELECT 1
                      FROM salesrep_commission AS src
                      JOIN commission_schedule AS cs
                        ON cs.commission_schedule_id = src.commission_schedule_id
                       AND cs.delete_flag = 'N' AND cs.inactive = 'N'
                      JOIN commission_schedule_detail AS csd
                        ON csd.commission_schedule_id = cs.commission_schedule_id
                       AND csd.delete_flag = 'N' AND csd.inactive = 'N'
                      JOIN commission_rule AS cr
                        ON cr.commission_rule_id = csd.commission_rule_id
                       AND cr.delete_flag = 'N' AND cr.group_by = 'IC'
                       AND cr.item_commission_class = icc.commission_class_id
                      JOIN commission_rule_detail AS crd
                        ON crd.commission_rule_id = cr.commission_rule_id
                       AND crd.delete_flag = 'N' AND crd.break_type = 'E'
                       AND crd.[value] = 0.0001
                      WHERE src.salesrep_id = @RepID AND src.delete_flag = 'N'
                    )
                  ORDER BY icc.commission_class_id
                  FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'),1,2,''), 'None')
              WHEN EXISTS (
                SELECT 1 FROM asi_table_customer_comclass_salesrep AS a
                WHERE a.salesrep_id = @RepID AND a.row_status_flag = 704
              ) THEN ISNULL(STUFF((
                  SELECT ', ' + a.commission_class_id
                  FROM (
                    SELECT DISTINCT commission_class_id
                    FROM asi_table_customer_comclass_salesrep
                    WHERE salesrep_id = @RepID AND row_status_flag = 704
                  ) AS a
                  ORDER BY a.commission_class_id
                  FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'),1,2,''), 'None')
              ELSE 'No comm schedule'
            END AS output1";

        string output;

        // CHANGED: P21SqlConnection replaces kb_SQLHelper.GetConnectionString
        //          + SqlConnection -- P21 Rule base class provides connection
        using (SqlCommand sqlCommand = new SqlCommand(cmdText, P21SqlConnection))
        {
          sqlCommand.CommandType = CommandType.Text;

          // CHANGED: SqlDbType.VarChar -- salesrep_commission.salesrep_id is VARCHAR
          sqlCommand.Parameters.Add("@RepID", SqlDbType.VarChar).Value =
            this.Data.Fields["salesrep_id"].FieldValue.ToString().Trim();

          DataTable dataTable = new DataTable();
          using (SqlDataReader reader = sqlCommand.ExecuteReader())
            dataTable.Load(reader);

          if (dataTable.Rows.Count < 1)
          {
            LogRuleError("Query returned no rows for salesrep ID: " + this.Data.Fields["salesrep_id"].FieldValue);
            ruleResult.Message = "Salesrep ID failed to retrieve results. This error has been logged. If it continues to happen, please contact the Bus App Team.\r\n\r\n- asi_ribbon_rm_default_products";
            ruleResult.Success = false;
            return ruleResult;
          }

          output = dataTable.Rows[0].Field<string>("output1") ?? "";
        }

        this.Data.Fields["business_rule_result"].FieldValue = output;
        ruleResult.Success = true;
        return ruleResult;
      }
      catch (Exception ex)
      {
        // CHANGED: kbSqlHelper.LogError replaced with insert into native business_rule_log
        LogRuleError("Salesrep ID: " + this.Data.Fields["salesrep_id"].FieldValue + "\r\n" + ex);
        ruleResult.Success = false;
        ruleResult.Message = $"Rule execution failed: {ex.Message}\r\n\r\nThis error has been logged. If it continues to happen, please contact the Bus App Team.\r\n\r\n- asi_ribbon_rm_default_products";
        return ruleResult;
      }
    }

    // ADDED: replaces kb_SQLHelper.LogError / kb_table_br_error_log
    // Writes the error to the P21 native business_rule_log table so failures are
    // queryable: WHERE log_action = 'Error' AND rule_name = 'asi_ribbon_rm_default_products'.
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
              (@User, 'Error', @Rule, @Asm, 'Synchronous (Internal)',
               'Failure', @Msg,
               GETDATE(), @User, GETDATE(), @User)";

        using (SqlCommand logCmd = new SqlCommand(logSql, P21SqlConnection))
        {
          string userId = this.Session != null && !string.IsNullOrEmpty(this.Session.UserID)
            ? this.Session.UserID
            : "unknown";

          logCmd.Parameters.Add("@User", SqlDbType.VarChar, 255).Value = userId;
          logCmd.Parameters.Add("@Rule", SqlDbType.VarChar, 255).Value = nameof(asi_ribbon_rm_default_products);
          logCmd.Parameters.Add("@Asm", SqlDbType.VarChar, 255).Value = GetType().Assembly.GetName().Name;
          logCmd.Parameters.Add("@Msg", SqlDbType.VarChar, 8000).Value =
            details.Length > 8000 ? details.Substring(0, 8000) : details;
          logCmd.ExecuteNonQuery();
        }
      }
      catch
      {
        // Swallow -- the user-facing RuleResult.Message still reports the original error.
      }
    }

    public override string GetDescription()
    {
      return "Returns the product commission classes that the salesrep will get commission by default for any new customer assignments.";
    }

    public override string GetName()
    {
      // CHANGED: nameof() replaces LINQ expression
      return nameof(asi_ribbon_rm_default_products);
    }
  }
}
