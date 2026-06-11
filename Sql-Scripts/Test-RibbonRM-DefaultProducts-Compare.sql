-- Test-RibbonRM-DefaultProducts-Compare.sql
-- Tests the inline query in asi_ribbon_rm_default_products (replaces kb_RepRM_getDefaultProducts)
-- against kb_view_salesrep_type.default_paid_comclass, verifies the assignment-table fallback,
-- and validates the business_rule_log insert.
-- Run against: P21 Prod (read-only except section 6, which inserts inside a rolled-back transaction)
-- 2026-06-11
--
-- Rule output logic:
--   1. Rep has a commission schedule  -> classes eligible for commission (parity with kb_ view)
--   2. Else rep has customer assignments in asi_table_customer_comclass_salesrep
--                                     -> DISTINCT assigned classes (matches salesrep tool)
--   3. Else                           -> 'No comm schedule'

USE P21;
GO

-- ============================================================
-- 1. Single-rep query -- EXACT SQL embedded in the business rule
--    Change @RepID to spot-check any rep.
--      40360 = Walcro House rep, has schedule    -> 'PADDING, SUPPLIES'
--      38120 = Shawn Streyle, fallback           -> 'BAG1, BAG3, PADDING'
--      50512 = Torie Bonafede, fallback          -> 'BAG1, BAG3, PADDING, SUPPLIES'
--      38118 = Joe Kuzemchak, neither source     -> 'No comm schedule'
-- ============================================================
PRINT '--- 1. Single-rep query (rule SQL) ---'

DECLARE @RepID VARCHAR(16) = '38120';

SELECT @RepID AS salesrep_id,
  CASE
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
  END AS output1;

-- ============================================================
-- 2. Parity check (schedule branch) -- new query vs kb_view_salesrep_type
--    Only scheduled reps are compared; fallback reps were never in the old view.
--    Expect: mismatches = 0, old_only = 0  (verified 109/109 on Prod 2026-06-11)
-- ============================================================
PRINT '--- 2. Parity summary, schedule branch (expect 0 mismatches) ---'

;WITH new_calc AS (
    SELECT s.salesrep_id, s.salesrep_id_varchar,
        CASE WHEN NOT EXISTS (
                SELECT 1 FROM salesrep_commission src
                WHERE src.salesrep_id = s.salesrep_id_varchar
                  AND COALESCE(src.commission_schedule_id,'') <> ''
             ) THEN NULL  -- no schedule: rule uses assignment fallback (section 4)
        ELSE ISNULL(STUFF((
            SELECT ', ' + icc.commission_class_id
            FROM item_commission_class AS icc
            WHERE icc.delete_flag = 'N'
              AND NOT EXISTS (
                SELECT 1
                FROM salesrep_commission AS src
                JOIN commission_schedule AS cs ON cs.commission_schedule_id = src.commission_schedule_id AND cs.delete_flag = 'N' AND cs.inactive = 'N'
                JOIN commission_schedule_detail AS csd ON csd.commission_schedule_id = cs.commission_schedule_id AND csd.delete_flag = 'N' AND csd.inactive = 'N'
                JOIN commission_rule AS cr ON cr.commission_rule_id = csd.commission_rule_id AND cr.delete_flag = 'N' AND cr.group_by = 'IC' AND cr.item_commission_class = icc.commission_class_id
                JOIN commission_rule_detail AS crd ON crd.commission_rule_id = cr.commission_rule_id AND crd.delete_flag = 'N' AND crd.break_type = 'E' AND crd.[value] = 0.0001
                WHERE src.salesrep_id = s.salesrep_id_varchar AND src.delete_flag = 'N'
              )
            ORDER BY icc.commission_class_id
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'),1,2,''), '~EMPTY~')
        END AS new_val
    FROM kb_view_salesrep AS s
)
SELECT
    SUM(CASE WHEN t.salesrep_id IS NOT NULL THEN 1 ELSE 0 END) AS reps_in_old_view,
    SUM(CASE WHEN t.salesrep_id IS NOT NULL AND ISNULL(t.default_paid_comclass,'~EMPTY~') = n.new_val THEN 1 ELSE 0 END) AS matches,
    SUM(CASE WHEN t.salesrep_id IS NOT NULL AND ISNULL(t.default_paid_comclass,'~EMPTY~') <> ISNULL(n.new_val,'~MISSING~') THEN 1 ELSE 0 END) AS mismatches,
    SUM(CASE WHEN t.salesrep_id IS NOT NULL AND n.new_val IS NULL THEN 1 ELSE 0 END) AS old_only
FROM new_calc AS n
LEFT JOIN kb_view_salesrep_type AS t ON t.salesrep_id = n.salesrep_id;

-- ============================================================
-- 3. Mismatch detail -- only returns rows if section 2 shows mismatches
-- ============================================================
PRINT '--- 3. Mismatch detail (expect empty) ---'

;WITH new_calc AS (
    SELECT s.salesrep_id, s.salesrep_name,
        CASE WHEN NOT EXISTS (
                SELECT 1 FROM salesrep_commission src
                WHERE src.salesrep_id = s.salesrep_id_varchar
                  AND COALESCE(src.commission_schedule_id,'') <> ''
             ) THEN NULL
        ELSE ISNULL(STUFF((
            SELECT ', ' + icc.commission_class_id
            FROM item_commission_class AS icc
            WHERE icc.delete_flag = 'N'
              AND NOT EXISTS (
                SELECT 1
                FROM salesrep_commission AS src
                JOIN commission_schedule AS cs ON cs.commission_schedule_id = src.commission_schedule_id AND cs.delete_flag = 'N' AND cs.inactive = 'N'
                JOIN commission_schedule_detail AS csd ON csd.commission_schedule_id = cs.commission_schedule_id AND csd.delete_flag = 'N' AND csd.inactive = 'N'
                JOIN commission_rule AS cr ON cr.commission_rule_id = csd.commission_rule_id AND cr.delete_flag = 'N' AND cr.group_by = 'IC' AND cr.item_commission_class = icc.commission_class_id
                JOIN commission_rule_detail AS crd ON crd.commission_rule_id = cr.commission_rule_id AND crd.delete_flag = 'N' AND crd.break_type = 'E' AND crd.[value] = 0.0001
                WHERE src.salesrep_id = s.salesrep_id_varchar AND src.delete_flag = 'N'
              )
            ORDER BY icc.commission_class_id
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'),1,2,''), '~EMPTY~')
        END AS new_val
    FROM kb_view_salesrep AS s
)
SELECT n.salesrep_id, n.salesrep_name,
       t.default_paid_comclass AS old_val,
       n.new_val
FROM new_calc AS n
JOIN kb_view_salesrep_type AS t ON t.salesrep_id = n.salesrep_id
WHERE ISNULL(t.default_paid_comclass,'~EMPTY~') <> ISNULL(n.new_val,'~MISSING~')
ORDER BY n.salesrep_id;

-- ============================================================
-- 4. Fallback branch -- no-schedule reps and what the rule will now show
--    (was "n/a"/blank for ALL of these under the kb_ rule)
-- ============================================================
PRINT '--- 4. No-schedule reps: fallback output from assignment table ---'

SELECT s.salesrep_id, s.salesrep_name,
       CONVERT(VARCHAR(19), c.date_created, 120) AS rep_created,
       ISNULL(STUFF((
           SELECT ', ' + a.commission_class_id
           FROM (
             SELECT DISTINCT commission_class_id
             FROM asi_table_customer_comclass_salesrep
             WHERE salesrep_id = s.salesrep_id_varchar AND row_status_flag = 704
           ) AS a
           ORDER BY a.commission_class_id
           FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'),1,2,''), 'No comm schedule') AS rule_output
FROM kb_view_salesrep AS s
JOIN contacts AS c ON c.id = s.salesrep_id_varchar
WHERE s.delete_flag = 'N'
  AND NOT EXISTS (
    SELECT 1 FROM salesrep_commission src
    WHERE src.salesrep_id = s.salesrep_id_varchar
      AND COALESCE(src.commission_schedule_id,'') <> ''
  )
ORDER BY c.date_created DESC;

-- ============================================================
-- 5. Source comparison (informational) -- scheduled reps where commission
--    eligibility differs from actual customer assignments. Expected to differ;
--    the two systems measure different things. Not a defect.
-- ============================================================
PRINT '--- 5. Scheduled reps: schedule-derived vs assigned classes (informational) ---'

SELECT t.salesrep_id, t.salesrep_name,
       t.default_paid_comclass AS schedule_derived,
       STUFF((
           SELECT ', ' + a.commission_class_id
           FROM (
             SELECT DISTINCT commission_class_id
             FROM asi_table_customer_comclass_salesrep
             WHERE salesrep_id = CONVERT(VARCHAR(16), t.salesrep_id) AND row_status_flag = 704
           ) AS a
           ORDER BY a.commission_class_id
           FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'),1,2,'') AS assigned_classes
FROM kb_view_salesrep_type AS t
JOIN kb_view_salesrep AS s ON s.salesrep_id = t.salesrep_id AND s.delete_flag = 'N'
ORDER BY t.salesrep_id;

-- ============================================================
-- 6. business_rule_log error insert -- EXACT SQL in LogRuleError()
--    Runs inside a transaction and ROLLS BACK; nothing persists.
-- ============================================================
PRINT '--- 6. Error log insert test (rolled back) ---'

BEGIN TRAN;

INSERT INTO business_rule_log
  (user_id, log_action, rule_name, rule_assembly_name, run_type,
   return_value, return_message,
   date_created, created_by, date_last_modified, last_maintained_by)
VALUES
  (SYSTEM_USER, 'Error', 'asi_ribbon_rm_default_products', 'asi_ribbon_rm_default_products', 'Synchronous (Internal)',
   'Failure', 'TEST - Test-RibbonRM-DefaultProducts-Compare.sql section 6 - rolled back',
   GETDATE(), SYSTEM_USER, GETDATE(), SYSTEM_USER);

SELECT TOP 1 business_rule_log_uid, user_id, log_action, rule_name, return_value, return_message, date_created
FROM business_rule_log
WHERE log_action = 'Error'
ORDER BY business_rule_log_uid DESC;

ROLLBACK;

-- ============================================================
-- 7. Monitoring query -- run after deployment to see real errors
-- ============================================================
PRINT '--- 7. Logged errors for this rule (expect empty until deployed) ---'

SELECT business_rule_log_uid, user_id, return_message, date_created
FROM business_rule_log
WHERE log_action = 'Error'
  AND rule_name = 'asi_ribbon_rm_default_products'
ORDER BY business_rule_log_uid DESC;
