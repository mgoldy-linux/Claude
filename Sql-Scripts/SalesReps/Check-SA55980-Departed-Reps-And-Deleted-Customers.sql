-- SA 55980 -- follow-up to Matt 10/7: the 5 rep IDs on Oro customers with no current login
-- (1027 Bogner 73, 1071 Walther 61, 1092 Prentice 26, 38110 Gillson 20, 1091 Sparks 19).
-- Questions: (A) are those customers actually deleted/merged?  (B) across the WHOLE
-- asi_table_customer_comclass_salesrep table, are reps assigned to deleted/missing customers?
-- READ-ONLY. Run in SSMS against Prod. No kb_/js_/ds_ objects referenced.

-- 0) Schema first: any merge-type columns on customer? (P21 has no obvious "merged" flag)
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customer'
  AND (COLUMN_NAME LIKE '%merge%' OR COLUMN_NAME LIKE '%delete%' OR COLUMN_NAME LIKE '%status%'
       OR COLUMN_NAME LIKE '%inactive%' OR COLUMN_NAME LIKE '%active%' OR COLUMN_NAME LIKE '%credit_status%');

-- 1) Departed rep IDs -> customer detail (Oro customers only = same filter as the export proc)
;WITH oro AS (
    SELECT DISTINCT c.address_id AS customer_id
    FROM dbo.contacts AS c
    JOIN dbo.contact_role AS r ON r.contact_role_uid = c.contact_role_uid
    WHERE r.contact_role_id = 'Oro User' AND c.delete_flag = 'N' AND c.address_id IS NOT NULL
)
SELECT a.salesrep_id, a.customer_id, cu.customer_name,
       cu.delete_flag      AS customer_delete_flag,
       CASE WHEN cu.customer_id IS NULL THEN 'NO CUSTOMER ROW' END AS orphan,
       a.row_status_flag,
       CASE WHEN o.customer_id IS NOT NULL THEN 1 ELSE 0 END AS has_oro_user
FROM dbo.asi_table_customer_comclass_salesrep AS a
LEFT JOIN dbo.customer AS cu ON cu.customer_id = a.customer_id
LEFT JOIN oro          AS o  ON o.customer_id  = a.customer_id
WHERE a.salesrep_id IN ('1027','1071','1092','38110','1091')
ORDER BY a.salesrep_id, cu.delete_flag, a.customer_id;

-- 2) Summary of (1): per departed rep, customers by delete_flag (and Oro vs not)
SELECT a.salesrep_id,
       ISNULL(cu.delete_flag, '(no customer row)') AS customer_delete_flag,
       a.row_status_flag,
       COUNT(DISTINCT a.customer_id) AS customers
FROM dbo.asi_table_customer_comclass_salesrep AS a
LEFT JOIN dbo.customer AS cu ON cu.customer_id = a.customer_id
WHERE a.salesrep_id IN ('1027','1071','1092','38110','1091')
GROUP BY a.salesrep_id, ISNULL(cu.delete_flag, '(no customer row)'), a.row_status_flag
ORDER BY a.salesrep_id, customer_delete_flag;

-- 3) WHOLE TABLE: assignments by customer state (deleted / missing / live)
SELECT a.row_status_flag,
       CASE WHEN cu.customer_id IS NULL THEN 'NO CUSTOMER ROW'
            WHEN cu.delete_flag = 'Y'   THEN 'CUSTOMER DELETED'
            ELSE 'customer live' END AS customer_state,
       COUNT(*)                      AS assignment_rows,
       COUNT(DISTINCT a.customer_id) AS customers,
       COUNT(DISTINCT a.salesrep_id) AS reps
FROM dbo.asi_table_customer_comclass_salesrep AS a
LEFT JOIN dbo.customer AS cu ON cu.customer_id = a.customer_id
GROUP BY a.row_status_flag,
         CASE WHEN cu.customer_id IS NULL THEN 'NO CUSTOMER ROW'
              WHEN cu.delete_flag = 'Y'   THEN 'CUSTOMER DELETED'
              ELSE 'customer live' END
ORDER BY a.row_status_flag, customer_state;

-- 4) WHOLE TABLE: every rep on a deleted/missing customer (the rows to review/clean)
SELECT a.customer_id, cu.customer_name, cu.delete_flag, a.salesrep_id,
       ud.id AS login_id, u.delete_flag AS login_delete_flag
FROM dbo.asi_table_customer_comclass_salesrep AS a
LEFT JOIN dbo.customer AS cu ON cu.customer_id = a.customer_id
LEFT JOIN dbo.users_ud AS ud ON ud.salesrep_id = a.salesrep_id
LEFT JOIN dbo.users    AS u  ON u.id = ud.id
WHERE cu.customer_id IS NULL OR cu.delete_flag = 'Y'
ORDER BY a.salesrep_id, a.customer_id;

-- 5) WHOLE TABLE: LIVE customers whose rep has no current login (the real gap; superset of Matt's 5)
SELECT a.salesrep_id, COUNT(DISTINCT a.customer_id) AS live_customers
FROM dbo.asi_table_customer_comclass_salesrep AS a
JOIN dbo.customer AS cu ON cu.customer_id = a.customer_id AND cu.delete_flag = 'N'
WHERE a.salesrep_id <> ''
  AND NOT EXISTS (SELECT 1 FROM dbo.users_ud AS ud
                  JOIN dbo.users AS u ON u.id = ud.id AND u.delete_flag = 'N'
                  WHERE ud.salesrep_id = a.salesrep_id)
GROUP BY a.salesrep_id
ORDER BY live_customers DESC;

-- 6) "Merged" customers: no merge flag known; look for customers whose name/ID marks a merge
--    (e.g. 'MERGED', 'DO NOT USE', 'DUP') and still carry an assignment. Review by eye.
SELECT a.customer_id, cu.customer_name, cu.delete_flag, a.salesrep_id
FROM dbo.asi_table_customer_comclass_salesrep AS a
JOIN dbo.customer AS cu ON cu.customer_id = a.customer_id
WHERE cu.customer_name LIKE '%MERG%' OR cu.customer_name LIKE '%DUP%'
   OR cu.customer_name LIKE '%DO NOT USE%' OR cu.customer_name LIKE 'ZZ%'
ORDER BY cu.customer_name;


SELECT credit_status, delete_flag, COUNT(*) AS customers
FROM dbo.customer
GROUP BY credit_status, delete_flag
ORDER BY customers DESC;

;WITH oro AS (
    SELECT DISTINCT c.address_id AS customer_id
    FROM dbo.contacts c
    JOIN dbo.contact_role r ON r.contact_role_uid = c.contact_role_uid
    WHERE r.contact_role_id = 'Oro User' AND c.delete_flag = 'N' AND c.address_id IS NOT NULL)
SELECT a.salesrep_id, cu.delete_flag, COUNT(DISTINCT a.customer_id) AS oro_customers
FROM dbo.asi_table_customer_comclass_salesrep a
JOIN oro o ON o.customer_id = a.customer_id
JOIN dbo.customer cu ON cu.customer_id = a.customer_id
WHERE a.salesrep_id IN ('1027','1071','1092','38110','1091')
GROUP BY a.salesrep_id, cu.delete_flag
ORDER BY a.salesrep_id, cu.delete_flag;

;WITH oro AS (
    SELECT DISTINCT c.address_id AS customer_id
    FROM dbo.contacts c
    JOIN dbo.contact_role r ON r.contact_role_uid = c.contact_role_uid
    WHERE r.contact_role_id = 'Oro User' AND c.delete_flag = 'N' AND c.address_id IS NOT NULL)
SELECT a.customer_id, cu.customer_name, cu.credit_status, cu.delete_flag,
       CONVERT(VARCHAR(16), cu.salesrep_id) AS customer_primary_salesrep,
       CASE WHEN CONVERT(VARCHAR(16), cu.salesrep_id) = a.salesrep_id THEN 'Y' ELSE 'N' END AS is_primary,
       COUNT(*) AS comclass_rows     -- how many comclass assignments he holds on this customer
FROM dbo.asi_table_customer_comclass_salesrep a
JOIN oro o ON o.customer_id = a.customer_id
JOIN dbo.customer cu ON cu.customer_id = a.customer_id
WHERE a.salesrep_id = '1091'
GROUP BY a.customer_id, cu.customer_name, cu.credit_status, cu.delete_flag, cu.salesrep_id, a.salesrep_id
ORDER BY is_primary DESC, cu.customer_name;
