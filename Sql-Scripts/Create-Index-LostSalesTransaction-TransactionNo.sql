-- SA-51376: supplemental index to enable a seek on lost_sales_transaction by transaction_no
-- Existing index is keyed (lost_sales_uid, transaction_code_no, transaction_no) -- transaction_no
-- is the last key column, so the RMA Reason Code DynaChange lookup was scanning (measured
-- 3,082 logical reads / lookup on a 752K-row table in Play, 2026-08-05).
-- MEASURED in P21Play 2026-08-06: 2,905 -> 3 logical reads (scan -> seek). Ran successfully.
-- MEASURED in P21 (Prod) 2026-08-06: 2,951 -> 3 logical reads (scan -> seek). Ran successfully.
-- Index is now live in both environments.
use P21Play; --P21Play; --P21; --

-- Before: force a scan-shaped query and capture logical reads via STATISTICS IO
SET STATISTICS IO ON;
SELECT lst.transaction_no, lst.transaction_code_no, lst.lost_sales_uid
FROM dbo.lost_sales_transaction lst
WHERE lst.transaction_no = 6000380
  AND lst.transaction_code_no = 2145;
SET STATISTICS IO OFF;

CREATE INDEX ix_lost_sales_transaction_transaction_no
    ON dbo.lost_sales_transaction (transaction_no, transaction_code_no)
    INCLUDE (lost_sales_uid);

-- After: same query, confirm Index Seek + lower logical reads
SET STATISTICS IO ON;
SELECT lst.transaction_no, lst.transaction_code_no, lst.lost_sales_uid
FROM dbo.lost_sales_transaction lst
WHERE lst.transaction_no = 6000380
  AND lst.transaction_code_no = 2145;
SET STATISTICS IO OFF;

-- Rollback if needed:
-- DROP INDEX ix_lost_sales_transaction_transaction_no ON dbo.lost_sales_transaction;
