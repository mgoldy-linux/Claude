/* ============================================================================
   Trace a P21 "Build/Update Items" run  --  10 test items
   ----------------------------------------------------------------------------
   Goal:  confirm the utility only writes the intended column(s) on inv_loc and
          does NOT fire a trigger / call a recalc proc / touch anything special.

   Run in:  P21Dev  (then repeat in P21Training)
   Needs:   ALTER ANY EVENT SESSION (server) + read on the P21 tables.

   Sequence:
     STEP 1  populate #test_items, capture #before
     STEP 2  create + start the XE session
     STEP 3  >>> run the P21 Build/Update Items import for the 10 items <<<
     STEP 4  stop session, read captured events
     STEP 5  capture #after, diff vs #before
     STEP 6  trigger / FK cross-check
     STEP 7  drop the XE session
   ============================================================================ */

USE P21Dev;   -- <<< P21Training for the second pass
GO

/* ==== STEP 1 : test items + before-image ================================== */
IF OBJECT_ID('tempdb..#test_items') IS NOT NULL DROP TABLE #test_items;
CREATE TABLE #test_items (item_id varchar(40) PRIMARY KEY);
INSERT INTO #test_items (item_id) VALUES
 ('FUT150553809-22'),('JOH2674078002'),('LFCWEPLII213B'),('CBTGL-CAY-PENNECG'),
 ('CVGCUSTOMCUTCHARGE'),('CBVFIRMFITSTATSIDEDISPLAY'),('WINDA08790'),('WFTFFS-32'),
 ('NCE402265'),('ACC12 C1313B');

IF OBJECT_ID('tempdb..#before') IS NOT NULL DROP TABLE #before;
SELECT im.item_id, il.inv_mast_uid, il.location_id,
       il.replenishment_method, il.inv_min, il.safety_stock_type,
       il.order_quantity, il.safety_stock,
       il.min_safety_stock_days, il.max_safety_stock_days,
       il.date_last_modified, il.last_maintained_by
INTO   #before
FROM   dbo.inv_loc il
JOIN   dbo.inv_mast im ON im.inv_mast_uid = il.inv_mast_uid
JOIN   #test_items  t  ON t.item_id       = im.item_id
WHERE  il.delete_flag = 'N';

SELECT * FROM #before ORDER BY item_id, location_id;   -- eyeball the starting state
GO

/* ==== STEP 2 : create + start the capture =============================== *
   Scoped by DATABASE NAME only -- text predicates on XE are unreliable here.
   Events:
     sql_batch_completed / rpc_completed  -> what the client/middleware sends
     module_end                            -> every proc / TRIGGER / function that runs
     sql_statement_completed               -> ad-hoc DML statements

   Uses an event_file target (NOT ring_buffer): ring_buffer content is only
   reachable through sys.dm_xe_sessions, which drops the session the moment you
   STOP it -- so a "stop first, read second" workflow loses everything. A file
   target survives the stop and can be read any time via
   sys.fn_xe_file_target_read_file.

   >>> First run:  SELECT SERVERPROPERTY('InstanceDefaultLogPath');
       and substitute that path below (SQL Server's service account is
       guaranteed write access there; adjust if you'd rather use another
       folder it can write to). <<<
 * --------------------------------------------------------------------------- */
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'asi_item_import_trace')
    DROP EVENT SESSION asi_item_import_trace ON SERVER;
GO
CREATE EVENT SESSION asi_item_import_trace ON SERVER
ADD EVENT sqlserver.sql_batch_completed (
    ACTION (sqlserver.database_name, sqlserver.client_app_name, sqlserver.client_hostname,
            sqlserver.nt_username, sqlserver.server_principal_name, sqlserver.session_id,
            sqlserver.sql_text)
    WHERE  sqlserver.database_name = N'P21Dev'),
ADD EVENT sqlserver.rpc_completed (
    ACTION (sqlserver.database_name, sqlserver.client_app_name, sqlserver.client_hostname,
            sqlserver.nt_username, sqlserver.server_principal_name, sqlserver.session_id,
            sqlserver.sql_text)
    WHERE  sqlserver.database_name = N'P21Dev'),
ADD EVENT sqlserver.module_end (
    SET collect_statement = 1
    ACTION (sqlserver.database_name, sqlserver.session_id, sqlserver.sql_text)
    WHERE  sqlserver.database_name = N'P21Dev'),
ADD EVENT sqlserver.sql_statement_completed (
    ACTION (sqlserver.database_name, sqlserver.session_id, sqlserver.sql_text)
    WHERE  sqlserver.database_name = N'P21Dev')
ADD TARGET package0.event_file (
    SET filename = N'L:\SQL\asi_item_import_trace.xel',
        max_file_size = 50, max_rollover_files = 4)
WITH (MAX_DISPATCH_LATENCY = 3 SECONDS, TRACK_CAUSALITY = ON,
      EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, STARTUP_STATE = OFF);
GO
ALTER EVENT SESSION asi_item_import_trace ON SERVER STATE = START;
GO

/* ==== STEP 3 ============================================================= *
   Go to P21 now. Run Build/Update Items for the 10 test items only.
   Keep the run small and note the wall-clock start/end so you can filter noise.
 * --------------------------------------------------------------------------- */


/* ==== STEP 4 : stop + read ============================================== */
ALTER EVENT SESSION asi_item_import_trace ON SERVER STATE = STOP;
GO

;WITH raw AS (
    SELECT CAST(event_data AS xml) AS ev
    FROM   sys.fn_xe_file_target_read_file(N'L:\SQL\asi_item_import_trace*.xel', NULL, NULL, NULL)
), e AS (
    SELECT  ev,
            ev.value('(event/@name)[1]','varchar(60)')      AS event_name,
            ev.value('(event/@timestamp)[1]','datetime2')   AS ts_utc
    FROM raw
)
SELECT  ts_utc,
        event_name,
        ev.value('(event/action[@name="session_id"]/value)[1]','int')                AS spid,
        ev.value('(event/action[@name="client_app_name"]/value)[1]','varchar(256)')  AS client_app,
        ev.value('(event/action[@name="client_hostname"]/value)[1]','varchar(128)')  AS client_host,
        ev.value('(event/action[@name="nt_username"]/value)[1]','varchar(128)')      AS nt_user,
        ev.value('(event/data[@name="object_type"]/text)[1]','varchar(40)')          AS object_type,
        ev.value('(event/data[@name="object_name"]/value)[1]','varchar(256)')        AS object_name,
        ev.value('(event/data[@name="row_count"]/value)[1]','bigint')                AS row_count,
        ev.value('(event/data[@name="duration"]/value)[1]','bigint')                 AS duration_us,
        COALESCE(
          ev.value('(event/data[@name="statement"]/value)[1]','nvarchar(max)'),
          ev.value('(event/data[@name="batch_text"]/value)[1]','nvarchar(max)'),
          ev.value('(event/action[@name="sql_text"]/value)[1]','nvarchar(max)')
        )                                                                            AS sql_text
FROM e
ORDER BY ts_utc;
GO

-- Focused view: only writes, and only modules that are triggers.
-- (post-capture LIKE in a normal query is fine -- unlike an XE text predicate)
;WITH raw AS (
    SELECT CAST(event_data AS xml) AS ev
    FROM   sys.fn_xe_file_target_read_file(N'L:\SQL\asi_item_import_trace*.xel', NULL, NULL, NULL)
), e AS (
    SELECT  ev,
            ev.value('(event/@name)[1]','varchar(60)')      AS event_name,
            ev.value('(event/@timestamp)[1]','datetime2')   AS ts_utc
    FROM raw
)
SELECT ts_utc, event_name,
       ev.value('(event/data[@name="object_type"]/text)[1]','varchar(40)')   AS object_type,
       ev.value('(event/data[@name="object_name"]/value)[1]','varchar(256)') AS object_name,
       COALESCE(
         ev.value('(event/data[@name="statement"]/value)[1]','nvarchar(max)'),
         ev.value('(event/data[@name="batch_text"]/value)[1]','nvarchar(max)'),
         ev.value('(event/action[@name="sql_text"]/value)[1]','nvarchar(max)')
       ) AS sql_text
FROM e
WHERE ev.value('(event/data[@name="object_type"]/text)[1]','varchar(40)') = 'TRIGGER'
   OR ev.value('(event/action[@name="sql_text"]/value)[1]','nvarchar(max)') LIKE '%UPDATE %'
   OR ev.value('(event/action[@name="sql_text"]/value)[1]','nvarchar(max)') LIKE '%INSERT %'
   OR ev.value('(event/action[@name="sql_text"]/value)[1]','nvarchar(max)') LIKE '%DELETE %'
   OR ev.value('(event/data[@name="statement"]/value)[1]','nvarchar(max)')  LIKE '%UPDATE %'
   OR ev.value('(event/data[@name="statement"]/value)[1]','nvarchar(max)')  LIKE '%INSERT %'
   OR ev.value('(event/data[@name="statement"]/value)[1]','nvarchar(max)')  LIKE '%DELETE %'
ORDER BY ts_utc;
GO

/* ==== STEP 5 : after-image + diff ====================================== */
IF OBJECT_ID('tempdb..#after') IS NOT NULL DROP TABLE #after;
SELECT im.item_id, il.inv_mast_uid, il.location_id,
       il.replenishment_method, il.inv_min, il.safety_stock_type,
       il.order_quantity, il.safety_stock,
       il.min_safety_stock_days, il.max_safety_stock_days,
       il.date_last_modified, il.last_maintained_by
INTO   #after
FROM   dbo.inv_loc il
JOIN   dbo.inv_mast im ON im.inv_mast_uid = il.inv_mast_uid
JOIN   #test_items  t  ON t.item_id       = im.item_id
WHERE  il.delete_flag = 'N';

SELECT b.item_id, b.location_id,
       b.replenishment_method AS rm_before, a.replenishment_method AS rm_after,
       b.inv_min              AS min_before, a.inv_min             AS min_after,
       b.safety_stock_type    AS sst_before, a.safety_stock_type   AS sst_after,
       b.order_quantity       AS oq_before, a.order_quantity       AS oq_after,
       b.safety_stock         AS ss_before, a.safety_stock         AS ss_after,
       b.min_safety_stock_days AS min_ssd_before, a.min_safety_stock_days AS min_ssd_after,
       b.max_safety_stock_days AS max_ssd_before, a.max_safety_stock_days AS max_ssd_after,
       b.last_maintained_by   AS by_before, a.last_maintained_by   AS by_after,
       b.date_last_modified   AS dt_before, a.date_last_modified   AS dt_after
FROM   #before b
JOIN   #after  a ON a.inv_mast_uid = b.inv_mast_uid AND a.location_id = b.location_id
WHERE  EXISTS (
         SELECT b.replenishment_method,b.inv_min,b.safety_stock_type,
                b.order_quantity,b.safety_stock,b.min_safety_stock_days,b.max_safety_stock_days
         EXCEPT
         SELECT a.replenishment_method,a.inv_min,a.safety_stock_type,
                a.order_quantity,a.safety_stock,a.min_safety_stock_days,a.max_safety_stock_days
       )
ORDER BY b.item_id, b.location_id;
GO

/* ==== STEP 6 : trigger / FK cross-check (independent of the trace) ====== */
SELECT tr.name AS trigger_name, OBJECT_NAME(tr.parent_id) AS on_table,
       tr.is_disabled, tr.is_instead_of_trigger
FROM   sys.triggers tr
WHERE  tr.parent_id IN (OBJECT_ID('dbo.inv_loc'), OBJECT_ID('dbo.inv_mast'));

SELECT fk.name AS fk_name,
       OBJECT_NAME(fk.parent_object_id)     AS child_table,
       OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc, fk.update_referential_action_desc
FROM   sys.foreign_keys fk
WHERE  fk.referenced_object_id IN (OBJECT_ID('dbo.inv_loc'), OBJECT_ID('dbo.inv_mast'))
   AND fk.delete_referential_action_desc <> 'NO_ACTION';   -- cascades worth knowing about
GO

/* ==== STEP 7 : cleanup ================================================== */
DROP EVENT SESSION asi_item_import_trace ON SERVER;
GO
