/*───────────────────────────────────────────────────────────────────────────────
  SA 54033 - rebuild + verification harness   (companion to
  SA-54033-lot-bin-mismatch-diagnostics.sql, which holds the investigation)

  Item CBVCPR9258, inv_mast_uid 103353, location 342 (Tri-State Sioux Falls).
  lot 056 (lot_uid 289617) header qty_on_hand = 0 while inv_bin G14D and
  lot_bin_xref 056->G14D both hold 1,818.70. Fix = extended Rebuild Inventory
  Quantities (Setup/System/Rebuild Inventory Quantities), both boxes ticked,
  Retrieve -> Save. This file captures a before/after diff around that GUI
  action and verifies the result.

  Run order:  A (before) -> B start trace -> run rebuild in P21 client ->
              B stop+read -> D (after diff) -> E (verify) -> F (cleanup)
  All read-only except the zz_ scratch tables and the XE session it creates.
  Run in SSMS on the target environment (Claude Code sandbox drops SQL TDS).
  Confirmed on P21Dev 2026-09-10; rebuild also run on Prod.
───────────────────────────────────────────────────────────────────────────────*/


/*=============================================================================
  A.  BEFORE snapshot  - run immediately before the rebuild
=============================================================================*/
IF OBJECT_ID('dbo.zz_SA54033_lot_b')  IS NOT NULL DROP TABLE dbo.zz_SA54033_lot_b;
IF OBJECT_ID('dbo.zz_SA54033_xref_b') IS NOT NULL DROP TABLE dbo.zz_SA54033_xref_b;
IF OBJECT_ID('dbo.zz_SA54033_bin_b')  IS NOT NULL DROP TABLE dbo.zz_SA54033_bin_b;
IF OBJECT_ID('dbo.zz_SA54033_loc_b')  IS NOT NULL DROP TABLE dbo.zz_SA54033_loc_b;
IF OBJECT_ID('dbo.zz_SA54033_tld_b')  IS NOT NULL DROP TABLE dbo.zz_SA54033_tld_b;

SELECT * INTO dbo.zz_SA54033_lot_b  FROM dbo.lot                 WHERE inv_mast_uid=103353 AND location_id=342;
SELECT * INTO dbo.zz_SA54033_xref_b FROM dbo.lot_bin_xref        WHERE inv_mast_uid=103353 AND location_id=342;
SELECT * INTO dbo.zz_SA54033_bin_b  FROM dbo.inv_bin             WHERE inv_mast_uid=103353 AND location_id=342;
SELECT * INTO dbo.zz_SA54033_loc_b  FROM dbo.inv_loc             WHERE inv_mast_uid=103353 AND location_id=342;
SELECT * INTO dbo.zz_SA54033_tld_b  FROM dbo.inv_tran_lot_detail WHERE inv_mast_uid=103353 AND location_id=342;

SELECT 'BEFORE' AS tag,
 (SELECT qty_on_hand    FROM dbo.inv_loc      WHERE inv_mast_uid=103353 AND location_id=342) AS inv_loc_oh,     -- 3077.80
 (SELECT qty_allocated  FROM dbo.inv_loc      WHERE inv_mast_uid=103353 AND location_id=342) AS inv_loc_alloc,  -- 923.34
 (SELECT SUM(quantity)  FROM dbo.inv_bin      WHERE inv_mast_uid=103353 AND location_id=342) AS inv_bin_sum,    -- 3077.80
 (SELECT SUM(qty_linked)FROM dbo.lot_bin_xref WHERE inv_mast_uid=103353 AND location_id=342) AS xref_sum,       -- 3077.80
 (SELECT SUM(qty_on_hand)FROM dbo.lot         WHERE inv_mast_uid=103353 AND location_id=342) AS lot_sum,        -- 1259.10
 (SELECT qty_on_hand    FROM dbo.lot          WHERE lot_uid=289617)                          AS lot056_oh;      -- 0
GO


/*=============================================================================
  B.  Extended Events trace of the rebuild (optional - the diff in D is the
      real evidence; this shows the exact proc + UPDATE statement).
      Needs ALTER ANY EVENT SESSION. Set the DB name in the predicate.
=============================================================================*/
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name='SA54033_rebuild')
    DROP EVENT SESSION SA54033_rebuild ON SERVER;
GO
CREATE EVENT SESSION SA54033_rebuild ON SERVER
ADD EVENT sqlserver.rpc_completed
    (ACTION(sqlserver.session_id,sqlserver.client_app_name,sqlserver.username)
     WHERE sqlserver.database_name=N'P21Dev'),
ADD EVENT sqlserver.sql_statement_completed
    (ACTION(sqlserver.session_id)
     WHERE sqlserver.database_name=N'P21Dev'),
ADD EVENT sqlserver.module_end
    (SET collect_statement=1
     ACTION(sqlserver.session_id)
     WHERE sqlserver.database_name=N'P21Dev'),
ADD EVENT sqlserver.error_reported
    (ACTION(sqlserver.session_id,sqlserver.message)
     WHERE sqlserver.database_name=N'P21Dev')
ADD TARGET package0.event_file (SET filename=N'SA54033_rebuild.xel', max_file_size=100)
WITH (MAX_DISPATCH_LATENCY=5 SECONDS, TRACK_CAUSALITY=ON);
GO
ALTER EVENT SESSION SA54033_rebuild ON SERVER STATE=START;
GO
SELECT name, create_time FROM sys.dm_xe_sessions WHERE name='SA54033_rebuild';   -- expect 1 row

-- >>> now: RAISERROR('SA54033_START',10,1) WITH NOWAIT;  then run the rebuild
--     in the P21 client (Retrieve -> screenshot Rebuild Info + Timestamp -> Save,
--     repeat Retrieve/Save until clean), then RAISERROR('SA54033_END',10,1) WITH NOWAIT;

-- stop + read back
-- ALTER EVENT SESSION SA54033_rebuild ON SERVER STATE=STOP;
SELECT
  ev.value('@name','varchar(40)')                                         AS event,
  ev.value('@timestamp','datetime2')                                      AS ts,
  ev.value('(action[@name="session_id"]/value)[1]','int')                 AS spid,
  ev.value('(action[@name="attach_activity_id"]/value)[1]','varchar(50)') AS activity,
  ev.value('(data[@name="object_name"]/value)[1]','varchar(300)')         AS object_name,
  ev.value('(data[@name="statement"]/value)[1]','nvarchar(max)')          AS statement,
  ev.value('(data[@name="message"]/value)[1]','nvarchar(max)')            AS message
FROM (SELECT CAST(event_data AS xml) AS x
      FROM sys.fn_xe_file_target_read_file(N'SA54033_rebuild*.xel', NULL, NULL, NULL)) f
CROSS APPLY f.x.nodes('/event') AS t(ev)
ORDER BY ts;
-- if 0 rows / "cannot find file":  the .xel is in the SQL Server default LOG dir -
--   SELECT REPLACE(CAST(SERVERPROPERTY('ErrorLogFileName') AS nvarchar(500)),'ERRORLOG','SA54033_rebuild*.xel');
--   and paste that full path in place of N'SA54033_rebuild*.xel'
GO


/*=============================================================================
  C.  Do the rebuild  (P21 desktop client - NOT SSMS; this version has no
      Stored Procedure Executor window)
      Setup / System / Rebuild Inventory Quantities
        Company 1 | Location 342 To 342 | Item CBVCPR9258 To CBVCPR9258
        [x] Perform extended rebuild
        [x] Allow system to affect Inventory Value if needed (FIFO/Lot Costed/Tag)
      File > Retrieve  -> screenshot grid + Rebuild Info + Timestamp tabs
      File > Save      -> commits (Retrieve alone writes nothing)
      Re-Retrieve / Save until it stops reporting items to update. A count that
      sticks in a "to be Reviewed" box is the KB0011644 report-only bucket.
=============================================================================*/


/*=============================================================================
  D.  AFTER diff  - run once the rebuild is saved
=============================================================================*/
SELECT 'AFTER' AS tag,
 (SELECT qty_on_hand    FROM dbo.inv_loc      WHERE inv_mast_uid=103353 AND location_id=342) AS inv_loc_oh,
 (SELECT qty_allocated  FROM dbo.inv_loc      WHERE inv_mast_uid=103353 AND location_id=342) AS inv_loc_alloc,
 (SELECT SUM(quantity)  FROM dbo.inv_bin      WHERE inv_mast_uid=103353 AND location_id=342) AS inv_bin_sum,
 (SELECT SUM(qty_linked)FROM dbo.lot_bin_xref WHERE inv_mast_uid=103353 AND location_id=342) AS xref_sum,
 (SELECT SUM(qty_on_hand)FROM dbo.lot         WHERE inv_mast_uid=103353 AND location_id=342) AS lot_sum,
 (SELECT qty_on_hand    FROM dbo.lot          WHERE lot_uid=289617)                          AS lot056_oh;
-- expect: inv_loc_oh 3077.80 (unchanged), inv_loc_alloc 923.34 (unchanged),
--         inv_bin_sum / xref_sum / lot_sum all 3077.80, lot056_oh 1818.70

/* lot rows that moved */
SELECT a.lot, b.qty_on_hand AS oh_before, a.qty_on_hand AS oh_after,
       b.qty_allocated AS alloc_before, a.qty_allocated AS alloc_after,
       a.last_maintained_by, a.date_last_modified
FROM dbo.lot a JOIN dbo.zz_SA54033_lot_b b ON b.lot_uid=a.lot_uid
WHERE a.qty_on_hand<>b.qty_on_hand OR a.qty_allocated<>b.qty_allocated;
-- 2026-09-10 result: lot 056  0 -> 1818.70  (bare UPDATE - last_maintained_by /
--   date_last_modified NOT stamped); lot 028 .000000000 -> .000000279 (float noise)

/* lot_bin_xref rows that moved  (expect 0 - already correct) */
SELECT a.lot_cd, a.bin_cd, b.qty_linked AS ql_before, a.qty_linked AS ql_after,
       b.qty_allocated AS xa_before, a.qty_allocated AS xa_after,
       a.last_maintained_by, a.date_last_modified
FROM dbo.lot_bin_xref a JOIN dbo.zz_SA54033_xref_b b ON b.lot_bin_xref_uid=a.lot_bin_xref_uid
WHERE a.qty_linked<>b.qty_linked OR a.qty_allocated<>b.qty_allocated;

/* inv_bin rows that moved  (expect 0 - already correct) */
SELECT a.bin, b.quantity AS q_before, a.quantity AS q_after,
       b.qty_allocated AS ba_before, a.qty_allocated AS ba_after,
       a.last_maintained_by, a.date_last_modified
FROM dbo.inv_bin a JOIN dbo.zz_SA54033_bin_b b ON b.inv_bin_uid=a.inv_bin_uid
WHERE a.quantity<>b.quantity OR a.qty_allocated<>b.qty_allocated;

/* inv_loc change  (expect none - no GL posting needed) */
SELECT b.qty_on_hand AS loc_oh_before, a.qty_on_hand AS loc_oh_after,
       b.qty_allocated AS loc_alloc_before, a.qty_allocated AS loc_alloc_after,
       a.inv_last_changed_date, a.date_last_modified
FROM dbo.inv_loc a CROSS JOIN dbo.zz_SA54033_loc_b b
WHERE a.inv_mast_uid=103353 AND a.location_id=342;

/* new inv_tran_lot_detail rows for lot 056  (2026-09-10: NONE - rebuild posts
   no compensating transaction, so the lot's tran history still nets to 0) */
SELECT * FROM dbo.inv_tran_lot_detail
WHERE inv_mast_uid=103353 AND location_id=342 AND lot='056'
  AND inv_tran_lot_detail_uid NOT IN (SELECT inv_tran_lot_detail_uid FROM dbo.zz_SA54033_tld_b)
ORDER BY date_created;
GO


/*=============================================================================
  E.  VERIFY allocatable  - the data preconditions OE checks before it will
      book a lot. Definitive proof is a throwaway 1-carton test SO in the
      client that allocates lot 056 from G14D (then delete it - test envs
      hit live SMTP).
=============================================================================*/
SELECT l.lot, l.qty_on_hand - l.qty_allocated AS lot_free,
       x.bin_cd, x.qty_linked - x.qty_allocated AS bin_free,
       b.pick_locked_flag, b.put_locked_flag, ib.row_status_flag
FROM dbo.lot l
JOIN dbo.lot_bin_xref x ON x.inv_mast_uid=l.inv_mast_uid AND x.location_id=l.location_id AND x.lot_cd=l.lot
JOIN dbo.bin b     ON b.location_id=x.location_id AND b.bin_id=x.bin_cd
JOIN dbo.inv_bin ib ON ib.inv_mast_uid=x.inv_mast_uid AND ib.location_id=x.location_id AND ib.bin=x.bin_cd
WHERE l.lot_uid=289617;
-- want the G14D row: lot_free 1818.70, bin_free 1818.70, pick_locked_flag N,
--   row_status_flag 1037. Other rows are empty leftover xref links - harmless.
GO


/*=============================================================================
  F.  CLEANUP
=============================================================================*/
-- DROP TABLE dbo.zz_SA54033_lot_b, dbo.zz_SA54033_xref_b, dbo.zz_SA54033_bin_b,
--            dbo.zz_SA54033_loc_b, dbo.zz_SA54033_tld_b;
-- IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name='SA54033_rebuild')
--     DROP EVENT SESSION SA54033_rebuild ON SERVER;
--   then delete the SA54033_rebuild*.xel file(s) from the SQL Server LOG folder
