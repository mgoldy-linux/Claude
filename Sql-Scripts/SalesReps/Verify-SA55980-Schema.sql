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

-- how do the doc's sample users look, and which other users columns could mean "enabled"?
SELECT id, name, active, delete_flag, contact_id FROM dbo.users
WHERE id IN ('dnagel','bstolz','jsharer','arestivo','cgaspar');
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users' AND (COLUMN_NAME LIKE '%active%' OR COLUMN_NAME LIKE '%disab%'
   OR COLUMN_NAME LIKE '%status%' OR COLUMN_NAME LIKE '%enab%' OR COLUMN_NAME LIKE '%login%' OR COLUMN_NAME LIKE '%lock%');

   -- do the native columns agree with users_ud.salesrep_id, and are they populated?
SELECT COUNT(*) AS users_total,
       SUM(CASE WHEN u.salesrep_id      <> '' THEN 1 END) AS native_salesrep_id,
       SUM(CASE WHEN u.user_salesrep_id <> '' THEN 1 END) AS native_user_salesrep_id,
       SUM(CASE WHEN ud.salesrep_id     <> '' THEN 1 END) AS ud_salesrep_id,
       SUM(CASE WHEN u.salesrep_id <> '' AND ud.salesrep_id <> '' AND u.salesrep_id <> ud.salesrep_id THEN 1 END) AS disagree
FROM dbo.users u LEFT JOIN dbo.users_ud ud ON ud.id = u.id
WHERE u.delete_flag = 'N';