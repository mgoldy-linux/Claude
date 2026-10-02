-- =============================================================================
-- SA 55980 -- independent cross-check of dbo.asi_proc_sales_rep_export
-- Read-only. Works in ANY environment (Play, Training, Prod) -- it proves the
-- proc's logic against that environment's own data, whatever the data looks like.
--
-- Method: build the EXPECTED (customer, username) set with a deliberately
-- different query shape (one set-based statement, EXISTS / no temp-table
-- pipeline, no ROW_NUMBER pivot), UNPIVOT the proc's snapshot back to
-- (customer, slot, username), then compare both ways with EXCEPT.
-- Expected result of every check: 0 rows (except 0a / 0b which are informational).
-- Run the whole script after the proc has been created/updated (needs @ResultSet).
-- =============================================================================
SET NOCOUNT ON
DECLARE @ign BIT = 0   -- 1 = test run that ignores users.delete_flag (must match the proc's @IgnoreDeleteFlag)

-- ---- Capture the proc output (snapshot only) --------------------------------
IF OBJECT_ID('tempdb..#proc') IS NOT NULL DROP TABLE #proc
CREATE TABLE #proc (
    cust VARCHAR(20) NOT NULL PRIMARY KEY,
    u1 VARCHAR(30) NULL, u2 VARCHAR(30) NULL, u3 VARCHAR(30) NULL, u4 VARCHAR(30) NULL, u5 VARCHAR(30) NULL)
INSERT #proc EXEC dbo.asi_proc_sales_rep_export @IgnoreDeleteFlag = @ign, @ResultSet = 1

-- ---- Proc output unpivoted to (customer, slot, username) --------------------
IF OBJECT_ID('tempdb..#got') IS NOT NULL DROP TABLE #got
SELECT p.cust, v.slot, v.usr
INTO #got
FROM #proc AS p
CROSS APPLY (VALUES (1,p.u1),(2,p.u2),(3,p.u3),(4,p.u4),(5,p.u5)) AS v(slot, usr)
WHERE v.usr IS NOT NULL

-- ---- Independent expectation: every eligible (customer, username) ------------
IF OBJECT_ID('tempdb..#exp') IS NOT NULL DROP TABLE #exp
SELECT x.cust, x.usr, x.first_rep
INTO #exp
FROM (
    SELECT CONVERT(VARCHAR(20), a.customer_id) AS cust,
           LOWER(u.id)                         AS usr,
           MIN(a.salesrep_id)                  AS first_rep
    FROM dbo.asi_table_customer_comclass_salesrep AS a
    JOIN dbo.users_ud AS ud ON ud.salesrep_id = a.salesrep_id AND a.salesrep_id <> ''
    JOIN dbo.users    AS u  ON u.id = ud.id AND (u.delete_flag = 'N' OR @ign = 1)
    WHERE a.row_status_flag = 704
      AND EXISTS (SELECT 1
                  FROM dbo.contacts AS c
                  JOIN dbo.contact_role AS r ON r.contact_role_uid = c.contact_role_uid
                  WHERE c.address_id = a.customer_id
                    AND c.delete_flag = 'N'
                    AND r.contact_role_id = 'Oro User')
    GROUP BY a.customer_id, LOWER(u.id)
) AS x

-- Expected slot for each (customer, user): rank by lowest salesrep_id, then username
IF OBJECT_ID('tempdb..#exp_ranked') IS NOT NULL DROP TABLE #exp_ranked
SELECT cust, usr,
       DENSE_RANK() OVER (PARTITION BY cust ORDER BY first_rep, usr) AS slot
INTO #exp_ranked
FROM #exp

-- =============================================================================
PRINT '--- 0a. Informational: row counts ---'
SELECT (SELECT COUNT(*) FROM #proc)                                    AS proc_customers,
       (SELECT COUNT(DISTINCT CONVERT(VARCHAR(20), c.address_id))
          FROM dbo.contacts c JOIN dbo.contact_role r ON r.contact_role_uid = c.contact_role_uid
         WHERE r.contact_role_id = 'Oro User' AND c.delete_flag = 'N') AS expected_oro_customers,
       (SELECT COUNT(*) FROM #proc WHERE u1 IS NOT NULL)               AS customers_with_a_rep,
       (SELECT COUNT(*) FROM #proc WHERE u1 IS NULL)                   AS customers_with_no_rep,
       (SELECT COUNT(*) FROM #proc WHERE u5 IS NOT NULL)               AS customers_with_5_reps,
       (SELECT COUNT(DISTINCT cust) FROM #exp_ranked WHERE slot > 5)   AS customers_over_5

PRINT '--- 0b. Informational: distribution of reps per customer ---'
SELECT reps, COUNT(*) AS customers
FROM (SELECT cust, COUNT(*) AS reps FROM #exp GROUP BY cust) AS d
GROUP BY reps ORDER BY reps

PRINT '--- 1. Customer set: expected Oro customers vs proc rows (both directions; expect 0 rows) ---'
SELECT 'in proc, not expected' AS issue, p.cust FROM #proc p
WHERE NOT EXISTS (SELECT 1 FROM dbo.contacts c JOIN dbo.contact_role r ON r.contact_role_uid = c.contact_role_uid
                  WHERE CONVERT(VARCHAR(20), c.address_id) = p.cust AND c.delete_flag = 'N' AND r.contact_role_id = 'Oro User')
UNION ALL
SELECT 'expected, missing from proc', CONVERT(VARCHAR(20), c.address_id)
FROM dbo.contacts c JOIN dbo.contact_role r ON r.contact_role_uid = c.contact_role_uid
WHERE c.delete_flag = 'N' AND r.contact_role_id = 'Oro User' AND c.address_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM #proc p WHERE p.cust = CONVERT(VARCHAR(20), c.address_id))

PRINT '--- 2. (customer, username) pairs: proc vs expected, slots 1-5 only (expect 0 rows) ---'
(SELECT cust, usr FROM #exp_ranked WHERE slot <= 5 EXCEPT SELECT cust, usr FROM #got)
UNION ALL
(SELECT cust, usr FROM #got EXCEPT SELECT cust, usr FROM #exp_ranked WHERE slot <= 5)

PRINT '--- 3. Slot ORDER: same user in the wrong column (expect 0 rows) ---'
SELECT g.cust, g.usr, g.slot AS proc_slot, e.slot AS expected_slot
FROM #got g JOIN #exp_ranked e ON e.cust = g.cust AND e.usr = g.usr
WHERE g.slot <> e.slot

PRINT '--- 4. Contiguous slots, no gaps (a blank before a filled column; expect 0 rows) ---'
SELECT cust FROM #proc
WHERE (u1 IS NULL AND (u2 IS NOT NULL OR u3 IS NOT NULL OR u4 IS NOT NULL OR u5 IS NOT NULL))
   OR (u2 IS NULL AND (u3 IS NOT NULL OR u4 IS NOT NULL OR u5 IS NOT NULL))
   OR (u3 IS NULL AND (u4 IS NOT NULL OR u5 IS NOT NULL))
   OR (u4 IS NULL AND u5 IS NOT NULL)

PRINT '--- 5. Same username twice for one customer (expect 0 rows) ---'
SELECT cust, usr, COUNT(*) AS times FROM #got GROUP BY cust, usr HAVING COUNT(*) > 1

PRINT '--- 6. Every username in the output is a real, non-deleted login, lowercase (expect 0 rows) ---'
SELECT DISTINCT g.usr
FROM #got g
WHERE NOT EXISTS (SELECT 1 FROM dbo.users u WHERE LOWER(u.id) = g.usr AND (u.delete_flag = 'N' OR @ign = 1))
   OR g.usr <> LOWER(g.usr) COLLATE Latin1_General_BIN

PRINT '--- 7. Overflow customers: independent count of users beyond 5 vs proc exceptions (expect 0 rows) ---'
DECLARE @exc TABLE (customer_id VARCHAR(20), issue VARCHAR(30), detail VARCHAR(4000))
INSERT @exc EXEC dbo.asi_proc_sales_rep_export @IgnoreDeleteFlag = @ign, @ResultSet = 2
SELECT e.cust, 'overflow not logged' AS issue
FROM (SELECT cust FROM #exp_ranked GROUP BY cust HAVING MAX(slot) > 5) AS e
WHERE NOT EXISTS (SELECT 1 FROM @exc x WHERE x.customer_id = e.cust AND x.issue = 'OVER_5_USERS')
UNION ALL
SELECT x.customer_id, 'logged but not an overflow'
FROM @exc x
WHERE x.issue = 'OVER_5_USERS'
  AND NOT EXISTS (SELECT 1 FROM #exp_ranked e WHERE e.cust = x.customer_id AND e.slot > 5)

PRINT '--- 8. Exceptions: house / placeholder accounts must NOT be reported as NO_USERS_UD; real reps without a login must be (expect 0 rows) ---'
SELECT x.customer_id, x.detail, 'house/placeholder wrongly reported' AS issue
FROM @exc x JOIN dbo.contacts c ON c.id = x.detail
WHERE x.issue = 'NO_USERS_UD' AND (c.last_name LIKE 'House%' OR c.last_name = 'Rep' OR c.first_name LIKE '( Unassigned%')
UNION ALL
SELECT CONVERT(VARCHAR(20), a.customer_id), a.salesrep_id, 'real rep without login not reported'
FROM dbo.asi_table_customer_comclass_salesrep a
JOIN dbo.contacts c ON c.id = a.salesrep_id
WHERE a.row_status_flag = 704 AND a.salesrep_id <> ''
  AND NOT EXISTS (SELECT 1 FROM dbo.users_ud ud WHERE ud.salesrep_id = a.salesrep_id)
  AND NOT (c.last_name LIKE 'House%' OR c.last_name = 'Rep' OR c.first_name LIKE '( Unassigned%')
  AND EXISTS (SELECT 1 FROM dbo.contacts o JOIN dbo.contact_role r ON r.contact_role_uid = o.contact_role_uid
              WHERE o.address_id = a.customer_id AND o.delete_flag = 'N' AND r.contact_role_id = 'Oro User')
  AND NOT EXISTS (SELECT 1 FROM @exc x WHERE x.customer_id = CONVERT(VARCHAR(20), a.customer_id) AND x.issue = 'NO_USERS_UD' AND x.detail = a.salesrep_id)

PRINT '--- Done. All numbered checks 1-8 should return no rows. ---'
