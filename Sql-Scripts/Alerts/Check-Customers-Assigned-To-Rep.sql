-- Is contact_id 1045 (Anthony Basic / TBASIC, ** LEFT 01/2026 **) still assigned
-- as the salesrep on any customer records? Follow-up to
-- Find-Active-Salesreps-Deleted-Login.sql -- a departed rep still holding live
-- customer assignments means new orders/alerts will keep resolving to a dead login.

-- 0) Schema check first -- don't assume column names, incl. status/name (row_status_flag
--    doesn't exist on customer -- confirmed this session).
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customer'
  AND (COLUMN_NAME LIKE '%salesrep%' OR COLUMN_NAME LIKE '%name%' OR COLUMN_NAME LIKE '%status%' OR COLUMN_NAME LIKE '%delete%' OR COLUMN_NAME LIKE '%active%');

-- 1) Customers currently assigned to this rep.
SELECT customer_id, customer_name, salesrep_id, salesrep_assigned_date, delete_flag
FROM customer
WHERE salesrep_id = 1045
ORDER BY delete_flag, customer_name;

-- 2) Count, split by whether the customer itself is deleted -- an assignment on a
--    deleted customer is harmless; one on a live (delete_flag <> 'Y') customer is the real gap.
SELECT
    delete_flag,
    COUNT(*) AS customers_assigned_to_1045
FROM customer
WHERE salesrep_id = 1045
GROUP BY delete_flag;
