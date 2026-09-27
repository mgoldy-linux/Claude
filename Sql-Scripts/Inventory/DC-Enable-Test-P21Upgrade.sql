/* ============================================================================
   DC functionality -- ENABLE TEST on the P21 Upgrade DB  (WRITES DATA)
   ----------------------------------------------------------------------------
   Purpose:  Run Epicor's native p21_enable_distribution_center_functionality
             on a DISPOSABLE database (P21 Upgrade is about to be overwritten)
             and capture exactly what it changes: system settings, usage rows,
             run cost.
   Server:   P21Dev.allsurfaces.com  (all lower envs share this instance)
   Author:   mgoldyn / Claude session
   Date:     2026-09-27
   Spec:     Documents\P21\F_DistributionCenters_PORGandTRG_Support_v2.docx

   Run section by section (highlight + F5), NOT the whole file at once.
     STEP 0  pre-flight   (read-only)   -- confirm DB name, version, log space
     STEP 1  BEFORE snapshots  (creates zz_dc_* tables in this DB only)
     STEP 2  RUN the proc      (the write)
     STEP 3  AFTER comparison  (read-only)
     STEP 4  OPTIONAL: turn it back OFF and verify the reversal

   Parameters used: push usage = Y, TRG exclude TBO = Y.
   Periods-to-supply override/factor left untouched (''/0) to isolate the test.
   ============================================================================ */

/* ---- STEP 0a. Confirm the real catalog name (run in any DB) --------------- */
SELECT name, state_desc, recovery_model_desc, create_date
FROM   sys.databases
WHERE  name LIKE '%upgrade%';
GO

USE P21Upgrade;   -- <<< change if 0a shows a different name
GO

/* ---- STEP 0b. Which revision of the proc is here? ------------------------- */
--  Upgrade is on 25.2; Training (21.1) had Revision 6. If this differs, read the
--  new definition before running STEP 2.
SELECT o.name, o.modify_date, LEN(m.definition) AS def_length,
       SUBSTRING(m.definition, CHARINDEX('$Revision', m.definition), 20) AS revision
FROM   sys.objects o
JOIN   sys.sql_modules m ON m.object_id = o.object_id
WHERE  o.name IN ('p21_enable_distribution_center_functionality', 't_inv_period_usage_temp_i', 'p21_get_gtr');
GO

/* ---- STEP 0c. Setting rows must exist (proc silently no-ops otherwise) ---- */
SELECT name, value, date_last_modified, last_maintained_by
FROM   dbo.system_setting
WHERE  name IN ('push_usage_to_replen_loc', 'trg_exclude_tbo_stock_requirements',
                'oveerride_trg_periods_to_supply', 'trg_periods_to_supply_factor',
                'track_scheduled_usage_with_usage', 'gpor_rdc_include_usage_from_spokes')
ORDER  BY name;
GO

/* ---- STEP 0d. Log space -- the proc's first UPDATE touches EVERY usage row
                in one statement. Make sure the log/disk can take it. -------- */
SELECT (SELECT COUNT_BIG(*) FROM dbo.inv_period_usage)       AS usage_rows,
       total_log_size_in_bytes / 1048576.0                   AS log_size_mb,
       used_log_space_in_bytes / 1048576.0                   AS log_used_mb,
       used_log_space_in_percent
FROM   sys.dm_db_log_space_usage;
GO

/* ---- STEP 0e. Other triggers that will fire (cost + side effects) --------- */
SELECT OBJECT_NAME(parent_id) AS on_table, name AS trigger_name, is_disabled
FROM   sys.triggers
WHERE  parent_id IN (OBJECT_ID('dbo.inv_period_usage'), OBJECT_ID('dbo.inv_period_usage_temp'),
                     OBJECT_ID('dbo.system_setting'));
GO

/* ---- STEP 0f. (added after first run) 25.2 has NO t_inv_period_usage_temp_i.
   Only t_inv_period_usage_temp_ssb exists on the temp table -> usage posting
   moved to Service Broker (async). Find where the push logic lives now and
   whether the broker is even running in this restored DB. ----------------- */

-- Is Service Broker enabled in this DB? (restored copies often come back with it OFF)
SELECT name, is_broker_enabled, service_broker_guid
FROM   sys.databases WHERE name = DB_NAME();
GO

-- Queues + the activation procs that do the real work
SELECT q.name AS queue_name, q.is_activation_enabled, q.is_receive_enabled,
       q.is_enqueue_enabled, q.activation_procedure, q.max_readers
FROM   sys.service_queues q
WHERE  q.is_ms_shipped = 0
ORDER  BY q.name;
GO

-- Every module that reads the push setting or writes the this-location column in THIS version
SELECT o.type_desc, OBJECT_NAME(m.object_id) AS object_name, o.modify_date,
       CASE WHEN m.definition LIKE '%push_usage_to_replen_loc%'       THEN 'Y' ELSE '' END AS push_usage,
       CASE WHEN m.definition LIKE '%inv_period_usage_this_location%' THEN 'Y' ELSE '' END AS this_location_col,
       CASE WHEN m.definition LIKE '%inv_period_usage_temp%'          THEN 'Y' ELSE '' END AS reads_temp
FROM   sys.sql_modules m
JOIN   sys.objects     o ON o.object_id = m.object_id
WHERE  m.definition LIKE '%push_usage_to_replen_loc%'
   OR  m.definition LIKE '%inv_period_usage_this_location%'
   OR  OBJECT_NAME(m.object_id) = 't_inv_period_usage_temp_ssb'
ORDER  BY object_name;
GO

-- Anything already sitting unprocessed in the temp table / queues?
SELECT COUNT_BIG(*) AS temp_rows, MIN(date_created) AS oldest, MAX(date_created) AS newest
FROM   dbo.inv_period_usage_temp;
GO

/* ---- STEP 0g. Which path will the 25.2 trigger take? ---------------------
   t_inv_period_usage_temp_ssb is INSTEAD OF INSERT. It does NOT look at
   sys.databases.is_broker_enabled -- it looks at ssb.ssb_check:
     any of ssb.trig_ack_q / ssb.trig_q / ssb_enabled_inv_period_usage_temp /
     type='System' with status='Disabled'  -> SYNCHRONOUS (react proc runs inline)
     otherwise                              -> Service Broker SEND (async)
   With the broker OFF and the SB path chosen, messages sit in
   sys.transmission_queue forever and nothing is pushed.                    */
SELECT * FROM ssb.ssb_check ORDER BY type, name;
GO

SELECT COUNT_BIG(*) AS stuck_messages, MIN(enqueue_time) AS oldest, MAX(enqueue_time) AS newest
FROM   sys.transmission_queue;
GO

SELECT COUNT_BIG(*) AS staging_rows, MIN(date_last_modified) AS oldest, MAX(date_last_modified) AS newest
FROM   ssb.trig_inv_period_usage_temp;
GO

/* ============================================================================
   STEP 1 -- BEFORE snapshots
   ============================================================================ */
DROP TABLE IF EXISTS dbo.zz_dc_ss_before, dbo.zz_dc_loc_before, dbo.zz_dc_expected,
                     dbo.zz_dc_counts_before;
GO

-- 1a. Full copy of system_setting
SELECT * INTO dbo.zz_dc_ss_before FROM dbo.system_setting;
GO

-- 1b. Usage totals per location
SELECT location_id,
       COUNT_BIG(*)                                  AS usage_rows,
       SUM(inv_period_usage)                         AS total_usage,
       SUM(scheduled_usage)                          AS total_scheduled,
       SUM(inv_period_usage_this_location)           AS total_this_location
INTO   dbo.zz_dc_loc_before
FROM   dbo.inv_period_usage
GROUP  BY location_id;
GO

-- 1c. What the proc SHOULD add to each hub (same logic as the proc's INSERT).
--     Direct one-level push only; a hub that itself replenishes from another
--     location may cascade further -- STEP 3c will show that as a mismatch.
SELECT spoke.replenishment_location              AS hub_location_id,
       COUNT(DISTINCT spoke.location_id)         AS spokes,
       SUM(u.inv_period_usage)                   AS expected_usage_added,
       SUM(u.scheduled_usage)                    AS expected_scheduled_added
INTO   dbo.zz_dc_expected
FROM   dbo.inv_period_usage u
JOIN   dbo.inv_loc spoke
       ON  spoke.location_id  = u.location_id
       AND spoke.inv_mast_uid = u.inv_mast_uid
       AND spoke.location_id <> spoke.replenishment_location
WHERE  EXISTS (SELECT 1 FROM dbo.inv_loc hub
               WHERE hub.location_id  = spoke.replenishment_location
                 AND hub.inv_mast_uid = spoke.inv_mast_uid)
GROUP  BY spoke.replenishment_location;
GO

-- 1d. Row counts
SELECT (SELECT COUNT_BIG(*) FROM dbo.inv_period_usage)      AS usage_rows,
       (SELECT COUNT_BIG(*) FROM dbo.inv_period_usage_temp) AS usage_temp_rows
INTO   dbo.zz_dc_counts_before;
GO

SELECT * FROM dbo.zz_dc_expected ORDER BY expected_usage_added DESC;
GO

/* ============================================================================
   STEP 2 -- RUN IT  (the only write in this file besides STEP 4)
   ============================================================================ */
DECLARE @t0 datetime2 = SYSDATETIME();

EXEC dbo.p21_enable_distribution_center_functionality
       @push_usage_to_replen_loc           = 'Y',
       @trg_exclude_tbo_stock_requirements = 'Y';

SELECT DATEDIFF(SECOND, @t0, SYSDATETIME()) AS elapsed_seconds_wallclock;  -- context only
GO

-- 2b. Real cost from the plan-cache DMVs (quote THESE, not wall-clock)
SELECT 'proc' AS kind, OBJECT_NAME(object_id) AS object_name, execution_count,
       total_logical_reads, total_logical_writes,
       total_worker_time / 1000  AS total_cpu_ms,
       total_elapsed_time / 1000 AS total_elapsed_ms
FROM   sys.dm_exec_procedure_stats
WHERE  database_id = DB_ID() AND OBJECT_NAME(object_id) = 'p21_enable_distribution_center_functionality'
UNION ALL
SELECT 'trigger', OBJECT_NAME(object_id), execution_count,
       total_logical_reads, total_logical_writes,
       total_worker_time / 1000, total_elapsed_time / 1000
FROM   sys.dm_exec_trigger_stats
WHERE  database_id = DB_ID() AND OBJECT_NAME(object_id) = 't_inv_period_usage_temp_i';
GO

/* ============================================================================
   STEP 3 -- AFTER comparison (read-only)
   ============================================================================ */

-- 3a. SETTINGS: every row that changed / appeared / disappeared (EXCEPT both ways)
SELECT 'AFTER (new/changed)' AS side, s.system_setting_uid, s.name, s.value,
       s.date_last_modified, s.last_maintained_by
FROM   (SELECT system_setting_uid, name, value, date_last_modified, last_maintained_by FROM dbo.system_setting
        EXCEPT
        SELECT system_setting_uid, name, value, date_last_modified, last_maintained_by FROM dbo.zz_dc_ss_before) s
UNION ALL
SELECT 'BEFORE (old value)', b.system_setting_uid, b.name, b.value,
       b.date_last_modified, b.last_maintained_by
FROM   (SELECT system_setting_uid, name, value, date_last_modified, last_maintained_by FROM dbo.zz_dc_ss_before
        EXCEPT
        SELECT system_setting_uid, name, value, date_last_modified, last_maintained_by FROM dbo.system_setting) b
ORDER  BY name, side;
GO

-- 3b. Row counts before vs after (new hub usage rows? rows left in _temp?)
SELECT b.usage_rows AS usage_rows_before,
       (SELECT COUNT_BIG(*) FROM dbo.inv_period_usage)      AS usage_rows_after,
       b.usage_temp_rows AS temp_rows_before,
       (SELECT COUNT_BIG(*) FROM dbo.inv_period_usage_temp) AS temp_rows_after
FROM   dbo.zz_dc_counts_before b;
GO

-- 3c. HUBS: actual usage increase vs expected. match = 'Y' is the pass condition.
--     Any 'N' = cascade (hub feeds another hub) or something unexpected.
WITH after_loc AS (
    SELECT location_id, SUM(inv_period_usage) AS total_usage,
           SUM(inv_period_usage_this_location) AS total_this_location
    FROM   dbo.inv_period_usage GROUP BY location_id)
SELECT COALESCE(e.hub_location_id, a.location_id)                         AS location_id,
       e.spokes,
       e.expected_usage_added,
       a.total_usage - COALESCE(b.total_usage, 0)                          AS actual_usage_added,
       CASE WHEN ABS(COALESCE(e.expected_usage_added, 0)
                     - (a.total_usage - COALESCE(b.total_usage, 0))) < 0.0001
            THEN 'Y' ELSE 'N' END                                          AS match,
       a.total_this_location - COALESCE(b.total_this_location, 0)          AS this_location_change
FROM   after_loc a
LEFT   JOIN dbo.zz_dc_loc_before b ON b.location_id = a.location_id
LEFT   JOIN dbo.zz_dc_expected   e ON e.hub_location_id = a.location_id
WHERE  e.hub_location_id IS NOT NULL
   OR  ABS(a.total_usage - COALESCE(b.total_usage, 0)) > 0.0001   -- any non-hub that moved
ORDER  BY match, actual_usage_added DESC;
GO

-- 3d. The proc sets this_location = total on ALL rows first. How do the
--     buckets look now? (Before: 5.08M NULL / 2.91M equal / 22K total>own in Dev)
SELECT CASE WHEN inv_period_usage_this_location IS NULL                THEN '1 this_location NULL'
            WHEN inv_period_usage = inv_period_usage_this_location     THEN '2 equal'
            WHEN inv_period_usage >  inv_period_usage_this_location    THEN '3 total > own (pushed in)'
            ELSE                                                            '4 total < own' END AS bucket,
       COUNT_BIG(*) AS row_count
FROM   dbo.inv_period_usage
GROUP  BY CASE WHEN inv_period_usage_this_location IS NULL                THEN '1 this_location NULL'
               WHEN inv_period_usage = inv_period_usage_this_location     THEN '2 equal'
               WHEN inv_period_usage >  inv_period_usage_this_location    THEN '3 total > own (pushed in)'
               ELSE                                                            '4 total < own' END
ORDER  BY bucket;
GO

-- 3e. Everything the proc stamped
SELECT 'inv_period_usage'      AS source, COUNT_BIG(*) AS rows_stamped
FROM   dbo.inv_period_usage      WHERE last_maintained_by = 'enable_dc_functionality'
UNION ALL
SELECT 'inv_period_usage_temp', COUNT_BIG(*)
FROM   dbo.inv_period_usage_temp WHERE last_maintained_by = 'enable_dc_functionality'
UNION ALL
SELECT 'system_setting',        COUNT_BIG(*)
FROM   dbo.system_setting        WHERE last_maintained_by = 'enable_dc_functionality';
GO

/* ---- 3f. (added after first run) Explain the 3c mismatches: CASCADE --------
   The backfill lands at hub H1; if H1's OWN inv_loc row for that item points
   at another location H2, the usage trigger pushes it again to H2.
   predicted extra per H2 should equal actual - expected from 3c.            */
SELECT h1.replenishment_location              AS second_level_hub,
       COUNT(DISTINCT h1.location_id)         AS first_level_hubs,
       COUNT(DISTINCT spoke.inv_mast_uid)     AS items,
       SUM(u.inv_period_usage)                AS predicted_cascade_usage
FROM   dbo.inv_loc spoke
JOIN   dbo.inv_loc h1
       ON  h1.location_id  = spoke.replenishment_location
       AND h1.inv_mast_uid = spoke.inv_mast_uid
       AND h1.replenishment_location <> h1.location_id
JOIN   dbo.inv_loc h2
       ON  h2.location_id  = h1.replenishment_location
       AND h2.inv_mast_uid = h1.inv_mast_uid
JOIN   dbo.inv_period_usage u
       ON  u.location_id  = spoke.location_id
       AND u.inv_mast_uid = spoke.inv_mast_uid
WHERE  spoke.replenishment_location <> spoke.location_id
GROUP  BY h1.replenishment_location
ORDER  BY predicted_cascade_usage DESC;
GO

-- 3g. Which hub-to-hub links exist (item counts)?
SELECT h1.location_id AS first_level_hub, h1.replenishment_location AS feeds_into,
       COUNT(*) AS item_rows
FROM   dbo.inv_loc h1
WHERE  h1.replenishment_location <> h1.location_id
  AND  h1.location_id IN (SELECT hub_location_id FROM dbo.zz_dc_expected)
GROUP  BY h1.location_id, h1.replenishment_location
ORDER  BY item_rows DESC;
GO

/* ---- 3h. Item-level CLEANUP LIST for Purchasing ----------------------------
   (a) CHAIN: spoke -> hub1 -> hub2 for the SAME item. Real-time push only
       reaches hub1, so hub2 under-counts. Fix: point the spoke at hub2
       (or make hub1 self-replenishing).
   (b) CIRCULAR: A replenishes from B and B from A for the same item.       */
SELECT 'CHAIN' AS issue, im.item_id, spoke.location_id AS spoke, h1.location_id AS hub1,
       h1.replenishment_location AS hub2
FROM   dbo.inv_loc spoke
JOIN   dbo.inv_loc h1 ON h1.location_id = spoke.replenishment_location
                     AND h1.inv_mast_uid = spoke.inv_mast_uid
                     AND h1.replenishment_location <> h1.location_id
JOIN   dbo.inv_mast im ON im.inv_mast_uid = spoke.inv_mast_uid
WHERE  spoke.replenishment_location <> spoke.location_id
  AND  spoke.delete_flag = 'N' AND h1.delete_flag = 'N'
  AND  h1.replenishment_location <> spoke.location_id
UNION ALL
SELECT 'CIRCULAR', im.item_id, a.location_id, b.location_id, a.location_id
FROM   dbo.inv_loc a
JOIN   dbo.inv_loc b ON b.location_id = a.replenishment_location
                    AND b.inv_mast_uid = a.inv_mast_uid
                    AND b.replenishment_location = a.location_id
JOIN   dbo.inv_mast im ON im.inv_mast_uid = a.inv_mast_uid
WHERE  a.location_id < b.location_id
  AND  a.delete_flag = 'N' AND b.delete_flag = 'N'
ORDER  BY issue, item_id;
GO

/* ============================================================================
   STEP 4 -- OPTIONAL: turn it OFF and check the reversal
   Then re-run 3c: actual_usage_added should return to ~0 for every hub.
   (Known: this_location stays set to the old total -- the OFF path doesn't reset it.)
   ============================================================================ */
-- EXEC dbo.p21_enable_distribution_center_functionality
--        @push_usage_to_replen_loc           = 'N',
--        @trg_exclude_tbo_stock_requirements = 'N';
-- GO

/* ---- Cleanup when done (P21 Upgrade is being overwritten anyway) --------- */
-- DROP TABLE IF EXISTS dbo.zz_dc_ss_before, dbo.zz_dc_loc_before, dbo.zz_dc_expected,
--                      dbo.zz_dc_counts_before;
