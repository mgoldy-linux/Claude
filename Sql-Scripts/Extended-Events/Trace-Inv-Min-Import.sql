/* ============================================================================
   Trace a P21 "Build/Update Items" run  --  inv_min  --  10 test items
   ----------------------------------------------------------------------------
   Same purpose/pattern as Trace-Replenishment-Method-Import.sql (2026-09-13),
   applied to the second of the three columns. That trace found the native
   import forces iva_taxable_flag='N' and wipes usage_lock_period/year on
   EVERY inv_loc row it touches, not just rows where the target field changes
   -- this run checks whether the inv_min import path does anything similar,
   or something new.

   Run in:  P21Dev  (then repeat in P21Training if warranted)
   Needs:   ALTER ANY EVENT SESSION (server) + read on the P21 tables.

   Sequence:
     STEP 1  auto-pick 10 items needing an inv_min change, capture #before
             (prints the item list -- use it in P21, don't reselect)
     STEP 2  create + start the XE session
     STEP 3  >>> run the P21 Build/Update Items import for those 10 items <<<
     STEP 4  stop session, read captured events
     STEP 5  capture #after, diff vs #before (explicit watch-list columns,
             including the two side-effect columns found last time)
     STEP 5b any-column change detector (catches surprises 5 might miss)
     STEP 6  trigger / FK cross-check
     STEP 7  drop the XE session
   ============================================================================ */

USE P21Dev;   -- <<< P21Training for the second pass
GO

/* ==== STEP 1 : auto-pick 10 items + before-image =========================== *
   One item per distinct default_product_group, fewest locations first --
   same selection logic as Pick-10-Test-Items-Replenishment-Method-Only.sql,
   just filtered on inv_min instead.
 * --------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#test_items') IS NOT NULL DROP TABLE #test_items;

;WITH cand AS (
    SELECT  im.inv_mast_uid, im.item_id, im.default_product_group,
            COUNT(*) AS loc_rows,
            SUM(CASE WHEN il.inv_min <> 0 OR il.inv_min IS NULL THEN 1 ELSE 0 END) AS min_would_change
    FROM    dbo.inv_mast im
    JOIN    dbo.inv_loc  il ON il.inv_mast_uid = im.inv_mast_uid AND il.delete_flag = 'N'
    WHERE   im.delete_flag = 'N'
      AND   NULLIF(LTRIM(RTRIM(im.default_product_group)), '') IS NOT NULL
    GROUP BY im.inv_mast_uid, im.item_id, im.default_product_group
    HAVING  SUM(CASE WHEN il.inv_min <> 0 OR il.inv_min IS NULL THEN 1 ELSE 0 END) > 0
), ranked AS (
    SELECT c.*,
           ROW_NUMBER() OVER (PARTITION BY c.default_product_group ORDER BY c.loc_rows, c.item_id) AS rn
    FROM cand c
)
SELECT TOP (10) item_id
INTO   #test_items
FROM   ranked
WHERE  rn = 1
ORDER BY NEWID();

IF OBJECT_ID('tempdb..#before') IS NOT NULL DROP TABLE #before;
SELECT im.item_id, il.*
INTO   #before
FROM   dbo.inv_loc il
JOIN   dbo.inv_mast im ON im.inv_mast_uid = il.inv_mast_uid
JOIN   #test_items  t  ON t.item_id       = im.item_id
WHERE  il.delete_flag = 'N';
-- #before captures EVERY inv_loc column (needed for the STEP 5b any-column
-- diff) -- not just the ones we expect the import to touch.

SELECT item_id, inv_mast_uid, location_id, inv_min, replenishment_method, safety_stock_type
FROM   #before ORDER BY item_id, location_id;   -- >>> this is your P21 import list <<<
GO

/* ==== STEP 2 : create + start the capture ================================ */
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'asi_item_import_trace_invmin')
    DROP EVENT SESSION asi_item_import_trace_invmin ON SERVER;
GO
CREATE EVENT SESSION asi_item_import_trace_invmin ON SERVER
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
    SET filename = N'L:\SQL\asi_item_import_trace_invmin.xel',
        max_file_size = 50, max_rollover_files = 4)
WITH (MAX_DISPATCH_LATENCY = 3 SECONDS, TRACK_CAUSALITY = ON,
      EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, STARTUP_STATE = OFF);
GO
ALTER EVENT SESSION asi_item_import_trace_invmin ON SERVER STATE = START;
GO

/* ==== STEP 3 ============================================================= *
   Go to P21 now. Run Build/Update Items -- inv_min ONLY -- for exactly the
   10 items STEP 1 printed. Note wall-clock start/end to help filter noise.
 * --------------------------------------------------------------------------- */


/* ==== STEP 4 : stop + read ============================================== */
ALTER EVENT SESSION asi_item_import_trace_invmin ON SERVER STATE = STOP;
GO

;WITH raw AS (
    SELECT CAST(event_data AS xml) AS ev
    FROM   sys.fn_xe_file_target_read_file(N'L:\SQL\asi_item_import_trace_invmin*.xel', NULL, NULL, NULL)
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
;WITH raw AS (
    SELECT CAST(event_data AS xml) AS ev
    FROM   sys.fn_xe_file_target_read_file(N'L:\SQL\asi_item_import_trace_invmin*.xel', NULL, NULL, NULL)
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

/* ==== STEP 5 : after-image + explicit-column diff ======================= */
IF OBJECT_ID('tempdb..#after') IS NOT NULL DROP TABLE #after;
SELECT im.item_id, il.*
INTO   #after
FROM   dbo.inv_loc il
JOIN   dbo.inv_mast im ON im.inv_mast_uid = il.inv_mast_uid
JOIN   #test_items  t  ON t.item_id       = im.item_id
WHERE  il.delete_flag = 'N';

SELECT b.item_id, b.location_id,
       b.inv_min              AS min_before, a.inv_min             AS min_after,
       b.replenishment_method AS rm_before, a.replenishment_method AS rm_after,
       b.safety_stock_type    AS sst_before, a.safety_stock_type   AS sst_after,
       b.order_quantity       AS oq_before, a.order_quantity       AS oq_after,
       b.safety_stock         AS ss_before, a.safety_stock         AS ss_after,
       b.min_safety_stock_days AS min_ssd_before, a.min_safety_stock_days AS min_ssd_after,
       b.max_safety_stock_days AS max_ssd_before, a.max_safety_stock_days AS max_ssd_after,
       b.iva_taxable_flag     AS iva_before, a.iva_taxable_flag    AS iva_after,
       b.usage_lock_period    AS ulp_before, a.usage_lock_period   AS ulp_after,
       b.usage_lock_year      AS uly_before, a.usage_lock_year     AS uly_after,
       b.last_maintained_by   AS by_before, a.last_maintained_by   AS by_after,
       b.date_last_modified   AS dt_before, a.date_last_modified   AS dt_after
FROM   #before b
JOIN   #after  a ON a.inv_mast_uid = b.inv_mast_uid AND a.location_id = b.location_id
WHERE  EXISTS (
         SELECT b.inv_min,b.replenishment_method,b.safety_stock_type,
                b.order_quantity,b.safety_stock,b.min_safety_stock_days,b.max_safety_stock_days,
                b.iva_taxable_flag,b.usage_lock_period,b.usage_lock_year
         EXCEPT
         SELECT a.inv_min,a.replenishment_method,a.safety_stock_type,
                a.order_quantity,a.safety_stock,a.min_safety_stock_days,a.max_safety_stock_days,
                a.iva_taxable_flag,a.usage_lock_period,a.usage_lock_year
       )
ORDER BY b.item_id, b.location_id;
GO

/* ==== STEP 5b : any-column change detector (safety net) ================= *
   Genuinely checks EVERY column on inv_loc, not just the ones in STEP 5's
   named list -- this is how the iva_taxable_flag/usage_lock_* side effects
   got found in the replenishment_method trace, generalized so it doesn't
   depend on already knowing what to look for.

   Excludes item_id/inv_mast_uid/location_id (the join keys -- never differ)
   and date_last_modified/last_maintained_by (expected to change on every
   touched row -- not a "surprise"). Everything else on inv_loc is checked.
   LOB/incomparable types (text/ntext/image/xml/etc.) are excluded from the
   comparison since they can't be CONVERTed/compared this way -- if inv_loc
   has any, they won't be checked here and would need a manual look.
 * --------------------------------------------------------------------------- */
DECLARE @diff_sql nvarchar(max);

SELECT @diff_sql = STRING_AGG(CAST(
    'SELECT b.item_id, b.inv_mast_uid, b.location_id, ''' + c.name + ''' AS changed_column, ' +
    'CONVERT(nvarchar(200), b.[' + c.name + ']) AS before_value, ' +
    'CONVERT(nvarchar(200), a.[' + c.name + ']) AS after_value ' +
    'FROM #before b JOIN #after a ON a.inv_mast_uid = b.inv_mast_uid AND a.location_id = b.location_id ' +
    'WHERE ISNULL(CONVERT(nvarchar(200), b.[' + c.name + ']), N''~NULL~'') <> ISNULL(CONVERT(nvarchar(200), a.[' + c.name + ']), N''~NULL~'')'
    AS nvarchar(max)), N' UNION ALL ')
FROM   sys.columns c
WHERE  c.object_id = OBJECT_ID('tempdb..#before')
  AND  c.name NOT IN ('item_id','inv_mast_uid','location_id','date_last_modified','last_maintained_by')
  AND  TYPE_NAME(c.user_type_id) NOT IN ('text','ntext','image','xml','geometry','geography','sql_variant','timestamp','hierarchyid');

IF @diff_sql IS NOT NULL
    EXEC sp_executesql @diff_sql;
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
   AND fk.delete_referential_action_desc <> 'NO_ACTION';
GO

/* ==== STEP 7 : cleanup ================================================== */
DROP EVENT SESSION asi_item_import_trace_invmin ON SERVER;
GO
