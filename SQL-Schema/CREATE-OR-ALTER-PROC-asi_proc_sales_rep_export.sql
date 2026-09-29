-- =============================================================================
-- dbo.asi_proc_sales_rep_export
-- SA 55980 -- P21 Customer Sales Manager Username Export
--
-- Called daily by Export-SalesRepSftp.ps1 (scheduled task on ASWEB1). Read-only.
-- Returns TWO result sets:
--   1. Snapshot: one row per P21 Customer ID that has an 'Oro User' contact,
--      up to 5 distinct P21 usernames (lowercase) in salesRep 1..5 columns.
--      Customers with no eligible rep are included with blank rep columns.
--   2. Exceptions (customer_id, issue, detail):
--        OVER_5_USERS      customer has > 5 eligible user IDs (extras NOT in file)
--        NO_USERS_UD       active salesrep_id has no users_ud row
--        NO_ELIGIBLE_USER  salesrep_id maps to users_ud row(s), but none are
--                          active + not deleted in dbo.users
--
-- ASSUMPTIONS TO VERIFY FIRST -- run Sql-Scripts\SalesReps\Verify-SA55980-Schema.sql
--   * Oro role: dbo.contact_role (contact_role_uid, <name col>) joined from
--     dbo.contacts.contact_role_uid; customer key = contacts.address_id
--   * asi_table_customer_comclass_salesrep.row_status_flag = 704 means active
--   * users_ud.salesrep_id (varchar) -> users_ud.id = users.id (login id)
--   * dbo.users.active = 'Y' and dbo.users.delete_flag = 'N'
--   * Slot order = MIN(salesrep_id) then user id (deterministic; CONFIRM with requester)
--
-- Test:  EXEC dbo.asi_proc_sales_rep_export
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.asi_proc_sales_rep_export
AS
BEGIN
    SET NOCOUNT ON

    -- 1. Customers with at least one live 'Oro User' contact (deduped)
    CREATE TABLE #cust (customer_id VARCHAR(20) NOT NULL PRIMARY KEY)

    INSERT #cust (customer_id)
    SELECT DISTINCT CONVERT(VARCHAR(20), c.address_id)
    FROM dbo.contacts AS c
    JOIN dbo.contact_role AS r
      ON r.contact_role_uid = c.contact_role_uid
    WHERE r.contact_role_desc = 'Oro User'      -- VERIFY column name
      AND c.delete_flag = 'N'
      AND c.address_id IS NOT NULL

    -- 2. Active assignments for those customers (deduped on customer + salesrep)
    CREATE TABLE #asg (customer_id VARCHAR(20) NOT NULL, salesrep_id VARCHAR(16) NOT NULL,
                       PRIMARY KEY (customer_id, salesrep_id))

    INSERT #asg (customer_id, salesrep_id)
    SELECT DISTINCT cu.customer_id, a.salesrep_id
    FROM #cust AS cu
    JOIN dbo.asi_table_customer_comclass_salesrep AS a
      ON CONVERT(VARCHAR(20), a.customer_id) = cu.customer_id
    WHERE a.row_status_flag = 704
      AND a.salesrep_id IS NOT NULL

    -- 3. Resolve salesrep_id -> eligible user id (deduped per customer + user)
    CREATE TABLE #usr (customer_id VARCHAR(20) NOT NULL, user_id VARCHAR(30) NOT NULL,
                       sort_key VARCHAR(16) NOT NULL, rn INT NULL,
                       PRIMARY KEY (customer_id, user_id))

    INSERT #usr (customer_id, user_id, sort_key)
    SELECT a.customer_id, LOWER(u.id), MIN(a.salesrep_id)
    FROM #asg AS a
    JOIN dbo.users_ud AS ud ON ud.salesrep_id = a.salesrep_id
    JOIN dbo.users    AS u  ON u.id = ud.id
    WHERE u.active = 'Y' AND u.delete_flag = 'N'   -- VERIFY column names
    GROUP BY a.customer_id, LOWER(u.id)

    UPDATE x SET rn = y.rn
    FROM #usr AS x
    JOIN (SELECT customer_id, user_id,
                 ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY sort_key, user_id) AS rn
          FROM #usr) AS y
      ON y.customer_id = x.customer_id AND y.user_id = x.user_id

    -- Result set 1: snapshot
    SELECT cu.customer_id                                        AS [P21 Customer ID],
           MAX(CASE WHEN x.rn = 1 THEN x.user_id END)            AS [salesRep 1 Username],
           MAX(CASE WHEN x.rn = 2 THEN x.user_id END)            AS [salesRep 2 Username],
           MAX(CASE WHEN x.rn = 3 THEN x.user_id END)            AS [salesRep 3 Username],
           MAX(CASE WHEN x.rn = 4 THEN x.user_id END)            AS [salesRep 4 Username],
           MAX(CASE WHEN x.rn = 5 THEN x.user_id END)            AS [salesRep 5 Username]
    FROM #cust AS cu
    LEFT JOIN #usr AS x ON x.customer_id = cu.customer_id
    GROUP BY cu.customer_id
    ORDER BY cu.customer_id

    -- Result set 2: exceptions (nothing silently omitted)
    SELECT customer_id, issue, detail
    FROM (
        SELECT customer_id, 'OVER_5_USERS' AS issue,
               CONVERT(VARCHAR(10), COUNT(*)) + ' eligible users; omitted: ' +
               ISNULL(STUFF((SELECT ',' + z.user_id FROM #usr AS z
                             WHERE z.customer_id = x.customer_id AND z.rn > 5
                             ORDER BY z.rn FOR XML PATH('')), 1, 1, ''), '') AS detail
        FROM #usr AS x
        GROUP BY customer_id
        HAVING COUNT(*) > 5

        UNION ALL
        SELECT a.customer_id, 'NO_USERS_UD', a.salesrep_id
        FROM #asg AS a
        WHERE NOT EXISTS (SELECT 1 FROM dbo.users_ud AS ud WHERE ud.salesrep_id = a.salesrep_id)

        UNION ALL
        SELECT a.customer_id, 'NO_ELIGIBLE_USER', a.salesrep_id
        FROM #asg AS a
        WHERE EXISTS (SELECT 1 FROM dbo.users_ud AS ud WHERE ud.salesrep_id = a.salesrep_id)
          AND NOT EXISTS (SELECT 1 FROM dbo.users_ud AS ud
                          JOIN dbo.users AS u ON u.id = ud.id
                          WHERE ud.salesrep_id = a.salesrep_id
                            AND u.active = 'Y' AND u.delete_flag = 'N')
    ) AS e
    ORDER BY issue, customer_id
END
GO

GRANT EXECUTE ON dbo.asi_proc_sales_rep_export TO p21_application_role, PxxiUser
GO
