-- SA 55980 -- run in SSMS against Prod (read-only) BEFORE creating asi_proc_sales_rep_export.
-- Paste the results back so the proc's assumptions can be corrected.

-- 1. Contact role table + how 'Oro User' is stored
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'contact_role' OR (TABLE_NAME = 'contacts' AND COLUMN_NAME IN ('address_id','contact_role_uid','delete_flag'));
SELECT * FROM dbo.contact_role;                 -- find the 'Oro User' row and the name column

-- 2. users Active / Delete Flag physical names + types; users_ud key columns
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE (TABLE_NAME = 'users' AND COLUMN_NAME IN ('id','active','delete_flag','contact_id'))
   OR (TABLE_NAME = 'users_ud' AND COLUMN_NAME IN ('id','salesrep_id'))
   OR (TABLE_NAME = 'asi_table_customer_comclass_salesrep' AND COLUMN_NAME IN ('customer_id','salesrep_id','row_status_flag'));
SELECT active, delete_flag, COUNT(*) AS n FROM dbo.users GROUP BY active, delete_flag;

-- 3. Active flag values + freshness of the assignment table
SELECT row_status_flag, COUNT(*) AS n FROM dbo.asi_table_customer_comclass_salesrep GROUP BY row_status_flag;

-- 4. Fan-out: salesrep_id mapping to more than one login, or none
SELECT salesrep_id, COUNT(*) AS logins FROM dbo.users_ud WHERE salesrep_id IS NOT NULL
GROUP BY salesrep_id HAVING COUNT(*) > 1;
