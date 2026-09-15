// ============================================================
// asi_item_maint_loc_sort_t1.cs
// ============================================================
// Description : Pre-SQL rule for d_item_maint_loc_response (Item
//               Maintenance > Location List > "Select Additional
//               Locations" popup). Does two things to the retrieve SQL:
//
//               1. STRIPS NULLs OUT OF THE "NOT IN" LIST. Epicor's
//                  DataWindow pads its :al_LocationIdIn17 bind array with
//                  unfilled slots and expands them literally, producing
//                  e.g. "location_id NOT IN (100,342,NULL)". Under SQL's
//                  three-valued logic that is "<> 100 AND <> 342 AND
//                  <> NULL", and "<> NULL" is UNKNOWN -- so the predicate
//                  is never TRUE and the statement returns ZERO rows.
//                  Confirmed by running the captured statement in SSMS.
//               2. Appends ORDER BY location.location_id.
//
//               The whole statement is rewritten, not just appended to --
//               a Pre-SQL rule owns sql_statement outright.
//
//               The SELECT list is deliberately left untouched: P21
//               DataWindows bind result columns by POSITION, not name, so
//               reordering or adding columns lands data in the wrong
//               grid columns silently.
//
//               KNOWN LIMITATION -- THE ORDER BY DOES NOTHING. Proven in
//               BRR 2026-09-15: the DataWindow carries its own compiled-in
//               sort spec that re-sorts rows after retrieve, so SQL row
//               order never reaches the screen. A 2-column probe (dropping
//               compute_selected / company_id / company_name) DID sort by
//               location_id, which means the spec references one of those
//               dropped columns -- almost certainly company_name -- and
//               goes no-op when it is absent. But company_name is a visible
//               grid column, so correct display and our sort order are
//               mutually exclusive. The NULL strip below is the only part
//               of this rule that carries real value.
// Registration: Business Rule Organizer (Tools > DynaChange > DynaChange
//               Rules) > "Create Pre-SQL Rule" button. NOT Import Rule,
//               and not by editing Rule Type on a grid row -- those are a
//               different mechanism and register it as a standard rule.
//                 Class Name : --DW d_item_maint_loc_response
//                 Rule Name  : asi_item_maint_loc_sort_t1
//                 Run Type   : Synchronous
// SA          : 54806
// Prereq      : Test in Training first. Bump AssemblyVersion every build --
//               business_rule_log.rule_assembly_name shows the version, so
//               it tells you at a glance whether the running binary is the
//               one you just built (a stale AppDomain silently keeps the
//               old DLL until every client exits / the SOA pool recycles).
// ============================================================
// CHANGE LOG
// ------------------------------------------------------------
// 2026-09-15  Bus App Team
//   - Added the NOT IN NULL strip after the user found the stock statement
//     returns nothing in SSMS.
//   - Sort changed from company_name/location_name to location_id.
//   - Plan-cache tag moved to the end of the statement: it previously sat
//     ahead of the "--DW ..." identifier line, which that dialog requires
//     to be first.
// ============================================================

using System;
using System.Linq;
using System.Text.RegularExpressions;
using P21.Extensions.BusinessRule;

namespace asi_ItemMaintLocSort_t1
{
    public class asi_item_maint_loc_sort_t1 : Rule
    {
        private const string PlanCacheTag = "/* asi_item_maint_loc_sort_t1 */";

        public override string GetName()
        {
            return nameof(asi_item_maint_loc_sort_t1);
        }

        public override string GetDescription()
        {
            return "Pre-SQL rule for d_item_maint_loc_response: removes the NULL entries " +
                   "Epicor expands into the location_id NOT IN list (which otherwise makes " +
                   "the statement return no rows) and sorts by location_id. SA 54806.";
        }

        public override RuleResult Execute()
        {
            RuleResult result = new RuleResult();

            try
            {
                string sql = Data.Fields["sql_statement"].FieldValue;

                if (string.IsNullOrEmpty(sql))
                {
                    result.Success = true;
                    return result;
                }

                string original = sql;

                sql = StripNullsFromNotInList(sql);

                if (sql.IndexOf("ORDER BY", StringComparison.OrdinalIgnoreCase) < 0)
                {
                    sql = sql.TrimEnd() + " ORDER BY location.location_id";
                }

                if (sql.IndexOf(PlanCacheTag, StringComparison.Ordinal) < 0)
                {
                    sql = sql.TrimEnd() + " " + PlanCacheTag;
                }

                if (!string.Equals(sql, original, StringComparison.Ordinal))
                {
                    Data.Fields["sql_statement"].FieldValue = sql;
                }

                result.Success = true;
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.Message = "asi_item_maint_loc_sort_t1 error: " + ex.Message;
            }

            return result;
        }

        // Rewrites "NOT IN (100,342,NULL)" as "NOT IN (100,342)".
        // If every entry was NULL (a new item with no locations yet), the list
        // would be left empty -- "NOT IN ()" is a syntax error -- so it falls
        // back to a sentinel that excludes nothing.
        private static string StripNullsFromNotInList(string sql)
        {
            return Regex.Replace(
                sql,
                @"NOT\s+IN\s*\(([^)]*)\)",
                match =>
                {
                    string list = match.Groups[1].Value;

                    if (list.IndexOf("NULL", StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        return match.Value;
                    }

                    string[] kept = list
                        .Split(',')
                        .Select(entry => entry.Trim())
                        .Where(entry => entry.Length > 0
                                     && !entry.Equals("NULL", StringComparison.OrdinalIgnoreCase))
                        .ToArray();

                    return "NOT IN (" + (kept.Length > 0 ? string.Join(",", kept) : "-1") + ")";
                },
                RegexOptions.IgnoreCase);
        }
    }
}
