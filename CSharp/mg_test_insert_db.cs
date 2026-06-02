// =============================================================================
// mg_test_insert_db
// Fires on: Order Entry message box events
//
// Purpose: Diagnostic rule — attempts a single INSERT into diag_message_box_p21_ud
//          to identify the executing login via XE trace (error 229 capture).
//          Does not suppress anything.
//
// Version History:
//   t1  - Initial: test INSERT to capture executing login context
// =============================================================================

using P21.Extensions.BusinessRule;
using System;
using System.Data;
using System.Data.SqlClient;

namespace mg_test_insert_db
{
    public class mg_test_insert_db : P21.Extensions.BusinessRule.Rule
    {
        public override RuleResult Execute()
        {
            RuleResult ruleResult = new RuleResult();

            if (P21SqlConnection.State != ConnectionState.Open)
                P21SqlConnection.Open();

            using (SqlCommand cmd = new SqlCommand(
                "INSERT INTO dbo.diag_message_box_p21_ud (session_id, dataset_table, row_no, column_name, column_value) " +
                "VALUES (@session_id, @dataset_table, @row_no, @column_name, @column_value)", P21SqlConnection))
            {
                cmd.Parameters.AddWithValue("@session_id",    Guid.NewGuid());
                cmd.Parameters.AddWithValue("@dataset_table", "TEST");
                cmd.Parameters.AddWithValue("@row_no",        0);
                cmd.Parameters.AddWithValue("@column_name",   "test");
                cmd.Parameters.AddWithValue("@column_value",  "mg_test_insert_db fired at " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                cmd.ExecuteNonQuery();
            }

            return ruleResult;
        }

        public override string GetDescription() => "Diagnostic: test INSERT to identify executing login context";
        public override string GetName() => "mg_test_insert_db";
    }
}
