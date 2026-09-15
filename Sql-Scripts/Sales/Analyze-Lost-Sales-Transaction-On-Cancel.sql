/*==============================================================================
  Analyze-Lost-Sales-Transaction-On-Cancel.sql   READ-ONLY. Run vs P21Play.

  Why: dbo.asi_cancel_order (rebuilt from a Profiler trace) does NOT write
  dbo.lost_sales_transaction. A cancel done through the P21 client DOES --
  confirmed on order 6062441, which produced 9 rows:

     8 line rows  : line_no 1..8, sku_qty_change = that line's qty_ordered
     1 trailer row: line_no NULL, sku_qty_change NULL, ~17ms later
     all rows     : lost_sales_uid=16, affect_usage='Y', transaction_code_no=2143,
                    transaction_no='6062441', usage_processed_flag='Y',
                    sub_line_no NULL

  So this is APPLICATION-layer behaviour, not a trigger -- which is why replaying
  the traced UPDATEs alone never produced it.

  Answer these BEFORE adding a Phase 5 insert to the proc. Q2 is the one that
  can do real damage if assumed.
==============================================================================*/
USE P21Play;
GO
SET NOCOUNT ON;

/*------------------------------------------------------------------ Q1 -----
  What related objects actually exist, and are there triggers involved?
---------------------------------------------------------------------------*/
PRINT '=== Q1a: tables matching lost_sale / counter ===';
SELECT name, type_desc FROM sys.objects
WHERE  (name LIKE '%lost_sale%' OR name LIKE '%counter%')
  AND  type IN ('U','V','P','FN','TF')
ORDER BY type_desc, name;
GO

PRINT '=== Q1b: any trigger on lost_sales_transaction, or referencing it ===';
SELECT parent = OBJECT_NAME(t.parent_id), trigger_name = t.name, t.is_disabled
FROM   sys.triggers t
WHERE  OBJECT_NAME(t.parent_id) = 'lost_sales_transaction';

SELECT referencing = OBJECT_NAME(d.referencing_id), d.referenced_entity_name
FROM   sys.sql_expression_dependencies d
WHERE  d.referenced_entity_name = 'lost_sales_transaction';
GO

/*------------------------------------------------------------------ Q2 -----
  *** THE IMPORTANT ONE ***
  Is lost_sales_transaction_uid an IDENTITY, or is it allocated by P21's
  counter mechanism? If it is counter-managed, a raw INSERT skips the counter
  and drifts it -- and the next thing to break is the CLIENT's cancel, not ours.
  See feedback_p21_counter_drift.
---------------------------------------------------------------------------*/
PRINT '=== Q2a: column metadata (is_identity) ===';
SELECT c.name, type_name = TYPE_NAME(c.system_type_id), c.is_identity,
       c.is_nullable, c.max_length
FROM   sys.columns c
WHERE  c.object_id = OBJECT_ID('dbo.lost_sales_transaction')
ORDER BY c.column_id;
GO

PRINT '=== Q2b: P21 counter for this table ===';
/*  P21 does NOT expose counters as a queryable table -- they are read by
    calling p21_set_counter with no arguments, which returns every counter as
    (id, description, counter_num). Convention, per
    Sql-Scripts\Alerts\Check-Fix-Alert-Table-Counters-Play.sql: counter_id is
    simply the table name, so look for 'lost_sales_transaction'.

    Reading it alongside the real MAX(uid) answers two things at once:
      - a counter row exists      -> the table IS counter-managed, so any INSERT
                                     must allocate through p21_set_counter
      - counter_num < real max    -> it has ALREADY drifted, i.e. something has
                                     previously inserted rows raw
      - no counter row at all     -> not counter-managed; check is_identity (Q2a)   */
DECLARE @counters TABLE (id VARCHAR(50), description VARCHAR(255), counter_num INT);
INSERT @counters EXEC p21_set_counter;

SELECT id, description, counter_num,
       real_max_uid = (SELECT MAX(lost_sales_transaction_uid) FROM dbo.lost_sales_transaction),
       verdict = CASE
                    WHEN counter_num < (SELECT MAX(lost_sales_transaction_uid) FROM dbo.lost_sales_transaction)
                         THEN '*** COUNTER HAS DRIFTED ***'
                    ELSE 'counter ahead of / level with max -- healthy'
                 END
FROM   @counters
WHERE  id LIKE '%lost%' OR description LIKE '%lost%';

PRINT '  (no rows above = not counter-managed; rely on is_identity from Q2a)';
GO

/*------------------------------------------------------------------ Q3 -----
  What do lost_sales_uid = 16 and transaction_code_no = 2143 actually mean?
  If 16 is a user-chosen "reason for lost sale", it must be a PARAMETER on the
  proc, not a hardcoded literal.
---------------------------------------------------------------------------*/
PRINT '=== Q3a: the lost_sales parent row (uid 16) ===';
IF OBJECT_ID('dbo.lost_sales') IS NOT NULL
    EXEC sp_executesql N'SELECT * FROM dbo.lost_sales;';
ELSE
    PRINT '  -> dbo.lost_sales not found; see Q1a.';
GO

PRINT '=== Q3b: code_p21 lookup for 2143 (and neighbours) ===';
SELECT code_no, code_description, code_sub_description, row_status_flag
FROM   dbo.code_p21
WHERE  code_no IN (2143, 2142, 2144)
ORDER BY code_no;
GO

/*------------------------------------------------------------------ Q4 -----
  Is lost_sales_uid=16 / code 2143 CONSTANT for order cancels, or does it vary?
  This decides hardcode vs parameter.
---------------------------------------------------------------------------*/
PRINT '=== Q4: distribution over the last 120 days ===';
SELECT lost_sales_uid, transaction_code_no, affect_usage, usage_processed_flag,
       rows_ = COUNT(*), orders_ = COUNT(DISTINCT transaction_no),
       first_seen = MIN(date_created), last_seen = MAX(date_created)
FROM   dbo.lost_sales_transaction
WHERE  date_created >= DATEADD(DAY,-120,GETDATE())
GROUP BY lost_sales_uid, transaction_code_no, affect_usage, usage_processed_flag
ORDER BY rows_ DESC;
GO

/*------------------------------------------------------------------ Q5 -----
  Confirm the shape: is it always N line rows + exactly ONE trailer row
  (line_no NULL)? And does sku_qty_change always equal qty_ordered -- or is it
  the OPEN quantity (qty_ordered - qty_canceled - qty_invoiced)? On 6062441
  nothing was shipped, so the two are indistinguishable there.
---------------------------------------------------------------------------*/
PRINT '=== Q5a: row shape per cancelled order ===';
SELECT TOP (20)
       lst.transaction_no,
       line_rows    = SUM(CASE WHEN lst.line_no IS NOT NULL THEN 1 ELSE 0 END),
       trailer_rows = SUM(CASE WHEN lst.line_no IS NULL     THEN 1 ELSE 0 END),
       created      = MIN(lst.date_created)
FROM   dbo.lost_sales_transaction lst
WHERE  lst.date_created >= DATEADD(DAY,-60,GETDATE())
GROUP BY lst.transaction_no
ORDER BY MIN(lst.date_created) DESC;
GO

PRINT '=== Q5b: sku_qty_change vs the order line quantities ===';
SELECT TOP (50)
       lst.transaction_no, lst.line_no, lst.sku_qty_change,
       ol.qty_ordered, ol.qty_canceled, ol.qty_invoiced,
       ol.unit_size, ol.unit_quantity, ol.pricing_unit_size,
       matches_qty_ordered = CASE WHEN lst.sku_qty_change = ol.qty_ordered THEN 'Y' ELSE 'N' END
FROM   dbo.lost_sales_transaction lst
JOIN   dbo.oe_line ol ON ol.order_no = lst.transaction_no
                     AND ol.line_no  = lst.line_no
WHERE  lst.date_created >= DATEADD(DAY,-60,GETDATE())
ORDER BY lst.date_created DESC, lst.line_no;
GO

/*------------------------------------------------------------------ Q6 -----
  Side-by-side: an order cancelled by the CLIENT vs one cancelled by the PROC.
  6062441 was cancelled manually. Substitute an order the proc cancelled.
---------------------------------------------------------------------------*/
PRINT '=== Q6: client-cancelled vs proc-cancelled ===';
DECLARE @manual VARCHAR(20) = '6062441';
DECLARE @proc   VARCHAR(20) = '6062439';   -- <-- set to an order the proc cancelled

SELECT source = 'client', * FROM dbo.lost_sales_transaction WHERE transaction_no = @manual
UNION ALL
SELECT source = 'proc',   * FROM dbo.lost_sales_transaction WHERE transaction_no = @proc;
GO

/*==============================  DECIDE  ====================================
  Then, before Phase 5 is written:

  1. If the uid is NOT an identity -> the insert MUST allocate through P21's
     counter mechanism, never a raw MAX()+1. Getting this wrong drifts the
     counter and breaks the client's own next cancel.
  2. If lost_sales_uid varies by reason -> add a @lost_sales_uid parameter with
     16 as the default, rather than hardcoding it.
  3. If sku_qty_change is the OPEN quantity rather than qty_ordered, the proc
     must compute it the same way -- partially shipped orders would otherwise
     over-report lost demand.

  WORTH ASKING SEPARATELY: should the proc write these rows at all?
  affect_usage='Y' means these rows feed usage/demand history. In a test
  environment, replaying them makes the proc faithful to the client but also
  injects fake lost-demand into that environment's forecasting data. Fidelity
  and clean test data pull in opposite directions here -- a @write_lost_sales
  parameter (default 'Y') would let the caller choose.
===========================================================================*/
