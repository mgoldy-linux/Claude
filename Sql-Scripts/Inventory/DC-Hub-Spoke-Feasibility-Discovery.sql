/* ============================================================================
   F_DistributionCenters_PORGandTRG  --  FEASIBILITY DISCOVERY (READ-ONLY)
   ----------------------------------------------------------------------------
   Purpose:  Answer "can we do the Epicor DC mod ourselves?" before any build.
             Source spec: Documents\P21\F_DistributionCenters_PORGandTRG_Support_v2.docx
   Run on:   P21Dev (9/6 refresh is close enough for feasibility).
   Author:   mgoldyn / Claude session
   Date:     2026-09-27

   NO writes in this file. Each section is GO-separated so one bad column
   name can't abort the rest -- just note which section errored.

   Sections:
     0. Schema     - real columns for usage + service level (verify, don't assume)
     1. Settings   - existing system settings touching transfer usage / DC
     2. Topology   - hubs, spoke counts, item-location rows per hub
     3. Violations - multi-level chains + spokes whose hub has no inv_loc row
     4. Volume     - usage rows a one-time copy (#1) would touch
   ============================================================================ */

USE [P21]  --P21Dev;
GO

/* ---- 0a. inv_period_usage columns (what "usage" actually is) -------------- */
SELECT c.column_id, c.name, t.name AS data_type, c.max_length, c.is_nullable
FROM   sys.columns c
JOIN   sys.types   t ON t.user_type_id = c.user_type_id
WHERE  c.object_id = OBJECT_ID('dbo.inv_period_usage')
ORDER  BY c.column_id;
GO

/* ---- 0b. inv_loc columns that look like service level / usage / replen ---- */
SELECT c.name, t.name AS data_type
FROM   sys.columns c
JOIN   sys.types   t ON t.user_type_id = c.user_type_id
WHERE  c.object_id = OBJECT_ID('dbo.inv_loc')
  AND (c.name LIKE '%service%' OR c.name LIKE '%usage%' OR c.name LIKE '%replen%'
       OR c.name LIKE '%safety%' OR c.name LIKE '%demand%' OR c.name LIKE '%forecast%')
ORDER  BY c.name;
GO

/* ---- 0c. Any OTHER tables holding usage/service-level data per location --- */
SELECT OBJECT_NAME(c.object_id) AS table_name, c.name AS column_name
FROM   sys.columns c
JOIN   sys.tables  tb ON tb.object_id = c.object_id
WHERE  (c.name LIKE '%service_level%' OR c.name LIKE '%usage%')
  AND  tb.name NOT LIKE 'zz%'
ORDER  BY table_name, column_name;
GO

/* ---- 1. System settings mentioning transfer usage / distribution center --- */
--  Key question: do transfers already post usage at the hub? If yes, copying
--  spoke usage to the hub DOUBLE COUNTS.
SELECT *
FROM   dbo.system_setting
WHERE  name LIKE '%transfer%' OR name LIKE '%usage%' OR name LIKE '%distribution%'
    OR name LIKE '%replenish%' OR name LIKE '%service_level%'
ORDER  BY name;
GO

/* ---- 2. Topology: hubs and how many spokes/rows point at each ------------- */
SELECT il.replenishment_location           AS hub_location_id,
       COUNT(DISTINCT il.location_id)      AS spoke_locations,
       COUNT(*)                            AS spoke_item_loc_rows,
       COUNT(DISTINCT il.inv_mast_uid)     AS distinct_items
FROM   dbo.inv_loc il
WHERE  il.delete_flag = 'N'
  AND  il.replenishment_location IS NOT NULL
  AND  il.replenishment_location <> il.location_id
GROUP  BY il.replenishment_location
ORDER  BY spoke_item_loc_rows DESC;
GO

-- 2b. Spoke -> hub pairs (is each spoke location consistently on ONE hub?)
SELECT il.location_id                      AS spoke_location_id,
       il.replenishment_location           AS hub_location_id,
       COUNT(*)                            AS item_rows
FROM   dbo.inv_loc il
WHERE  il.delete_flag = 'N'
  AND  il.replenishment_location IS NOT NULL
  AND  il.replenishment_location <> il.location_id
GROUP  BY il.location_id, il.replenishment_location
ORDER  BY il.location_id, item_rows DESC;
GO

/* ---- 3a. VIOLATION: multi-level chain (hub itself replenishes elsewhere) -- */
--  Spec supports hub-and-spoke ONLY. Any rows here = spec doesn't fit as-is.
SELECT spoke.location_id                   AS spoke_location_id,
       spoke.replenishment_location        AS hub_location_id,
       hub.replenishment_location          AS hubs_own_replen_location,
       COUNT(*)                            AS item_rows
FROM   dbo.inv_loc spoke
JOIN   dbo.inv_loc hub
       ON  hub.inv_mast_uid = spoke.inv_mast_uid
       AND hub.location_id  = spoke.replenishment_location
       AND hub.delete_flag  = 'N'
WHERE  spoke.delete_flag = 'N'
  AND  spoke.replenishment_location <> spoke.location_id
  AND  hub.replenishment_location IS NOT NULL
  AND  hub.replenishment_location <> hub.location_id
GROUP  BY spoke.location_id, spoke.replenishment_location, hub.replenishment_location
ORDER  BY item_rows DESC;
GO

/* ---- 3b. GAP: spoke points at a hub with no (active) inv_loc row --------- */
--  Spec silently skips these -> that spoke's usage is lost to PORG.
SELECT spoke.location_id                   AS spoke_location_id,
       spoke.replenishment_location        AS hub_location_id,
       SUM(CASE WHEN hub.inv_mast_uid IS NULL THEN 1 ELSE 0 END)  AS hub_row_missing,
       SUM(CASE WHEN hub.delete_flag = 'Y'    THEN 1 ELSE 0 END)  AS hub_row_deleted
FROM   dbo.inv_loc spoke
LEFT   JOIN dbo.inv_loc hub
       ON  hub.inv_mast_uid = spoke.inv_mast_uid
       AND hub.location_id  = spoke.replenishment_location
WHERE  spoke.delete_flag = 'N'
  AND  spoke.replenishment_location <> spoke.location_id
GROUP  BY spoke.location_id, spoke.replenishment_location
HAVING SUM(CASE WHEN hub.inv_mast_uid IS NULL OR hub.delete_flag = 'Y' THEN 1 ELSE 0 END) > 0
ORDER  BY hub_row_missing DESC;
GO

/* ---- 4. Volume: spoke usage rows a one-time copy (#1) would roll up ------- */
SELECT COUNT(*)                            AS spoke_usage_rows,
       COUNT(DISTINCT u.demand_period_uid) AS periods,
       SUM(u.inv_period_usage)             AS total_spoke_usage_qty
FROM   dbo.inv_period_usage u
JOIN   dbo.inv_loc spoke
       ON  spoke.inv_mast_uid = u.inv_mast_uid
       AND spoke.location_id  = u.location_id
       AND spoke.delete_flag  = 'N'
WHERE  spoke.replenishment_location <> spoke.location_id;
GO

/* ============================================================================
   ROUND 2 (added 2026-09-27 after round-1 results)
   Round 1 found NATIVE settings that look like the Epicor spec already:
     push_usage_to_replen_loc = N   (spec #2?)
     gpor_rdc_include_usage_from_spokes = Y
     inv_period_usage.inv_period_usage_this_location  (own-vs-pushed split?)
     inv_loc.transfer_usage_percent / transfer_*.omit_transfer_usage_flag
   These sections find what P21 code actually reads them.
   ============================================================================ */

/* ---- 5a. Which procs/views/functions reference the native settings ------- */
SELECT o.type_desc, OBJECT_NAME(m.object_id) AS object_name,
       CASE WHEN m.definition LIKE '%push_usage_to_replen_loc%'           THEN 'Y' ELSE '' END AS push_usage,
       CASE WHEN m.definition LIKE '%gpor_rdc_include_usage_from_spokes%' THEN 'Y' ELSE '' END AS gpor_rdc,
       CASE WHEN m.definition LIKE '%inv_period_usage_this_location%'     THEN 'Y' ELSE '' END AS this_location_col,
       CASE WHEN m.definition LIKE '%transfer_usage_percent%'             THEN 'Y' ELSE '' END AS xfer_usage_pct,
       CASE WHEN m.definition LIKE '%omit_transfer_usage_flag%'           THEN 'Y' ELSE '' END AS omit_xfer_usage
FROM   sys.sql_modules m
JOIN   sys.objects     o ON o.object_id = m.object_id
WHERE  m.definition LIKE '%push_usage_to_replen_loc%'
   OR  m.definition LIKE '%gpor_rdc_include_usage_from_spokes%'
   OR  m.definition LIKE '%inv_period_usage_this_location%'
   OR  m.definition LIKE '%transfer_usage_percent%'
   OR  m.definition LIKE '%omit_transfer_usage_flag%'
ORDER  BY object_name;
GO

/* ---- 5b. Has usage EVER been pushed? (total vs this-location split) ------- */
SELECT CASE WHEN inv_period_usage_this_location IS NULL                     THEN '1 this_location NULL'
            WHEN inv_period_usage = inv_period_usage_this_location          THEN '2 equal (nothing pushed in)'
            WHEN inv_period_usage >  inv_period_usage_this_location         THEN '3 total > own (pushed in)'
            ELSE                                                                 '4 total < own' END AS bucket,
       COUNT(*) AS row_count,
       MAX(date_last_modified) AS latest_modified
FROM   dbo.inv_period_usage
GROUP  BY CASE WHEN inv_period_usage_this_location IS NULL                     THEN '1 this_location NULL'
               WHEN inv_period_usage = inv_period_usage_this_location          THEN '2 equal (nothing pushed in)'
               WHEN inv_period_usage >  inv_period_usage_this_location         THEN '3 total > own (pushed in)'
               ELSE                                                                 '4 total < own' END
ORDER  BY bucket;
GO

/* ---- 5c. Do transfers count as usage today? ------------------------------ */
SELECT transfer_usage_percent, COUNT(*) AS inv_loc_rows
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
GROUP  BY transfer_usage_percent
ORDER  BY inv_loc_rows DESC;
GO

SELECT ISNULL(omit_transfer_usage_flag,'(NULL)') AS omit_transfer_usage_flag, COUNT(*) AS transfer_lines
FROM   dbo.transfer_line
GROUP  BY omit_transfer_usage_flag;
GO

/* ---- 5d. The usage_copied flag (what sets it?) --------------------------- */
SELECT usage_copied, COUNT(*) AS row_count, MAX(date_last_modified) AS latest_modified
FROM   dbo.inv_period_usage
GROUP  BY usage_copied;
GO

/* ============================================================================
   ROUND 3 (added 2026-09-27 after reading the native objects)
   p21_enable_distribution_center_functionality takes 4 params that map to the
   Epicor spec, incl. @trg_exclude_tbo_stock_requirements (= spec #3).
   BUT the proc only UPDATEs existing system_setting rows -- if a row is
   missing, the call silently does nothing. Confirm the rows exist, and
   confirm TRG code actually reads the TRG setting.
   ============================================================================ */

/* ---- 6a. Do the DC-related setting rows exist, and what are they? -------- */
SELECT name, value, module_cd, date_last_modified, last_maintained_by
FROM   dbo.system_setting
WHERE  name IN ('push_usage_to_replen_loc', 'trg_exclude_tbo_stock_requirements',
                'oveerride_trg_periods_to_supply', 'trg_periods_to_supply_factor',
                'gpor_rdc_include_usage_from_spokes', 'replenishment_location_only',
                'default_transfer_usage_percent')
ORDER  BY name;
GO

/* ---- 6b. What code reads the TRG settings (spec #3)? --------------------- */
SELECT o.type_desc, OBJECT_NAME(m.object_id) AS object_name,
       CASE WHEN m.definition LIKE '%trg_exclude_tbo_stock_requirements%' THEN 'Y' ELSE '' END AS exclude_tbo,
       CASE WHEN m.definition LIKE '%oveerride_trg_periods_to_supply%'     THEN 'Y' ELSE '' END AS override_pts,
       CASE WHEN m.definition LIKE '%trg_periods_to_supply_factor%'        THEN 'Y' ELSE '' END AS pts_factor
FROM   sys.sql_modules m
JOIN   sys.objects     o ON o.object_id = m.object_id
WHERE  m.definition LIKE '%trg_exclude_tbo_stock_requirements%'
   OR  m.definition LIKE '%oveerride_trg_periods_to_supply%'
   OR  m.definition LIKE '%trg_periods_to_supply_factor%'
ORDER  BY object_name;
GO

/* ---- 6c. Has the enable proc EVER been run here? ------------------------- */
--  The proc stamps last_maintained_by = 'enable_dc_functionality'.
SELECT 'system_setting' AS source, COUNT(*) AS row_count, MAX(date_last_modified) AS latest
FROM   dbo.system_setting WHERE last_maintained_by = 'enable_dc_functionality'
UNION ALL
SELECT 'inv_period_usage', COUNT(*), MAX(date_last_modified)
FROM   dbo.inv_period_usage WHERE last_maintained_by = 'enable_dc_functionality';
GO

/* ============================================================================
   ROUND 4 (added 2026-09-27) -- WHERE does push_usage_to_replen_loc live in
   the P21 UI (System Settings window), and what is its on-screen label?
   ============================================================================ */

/* ---- 7a. Tables that could hold setting labels/descriptions/UI placement -- */
SELECT t.name AS table_name,
       STUFF((SELECT ', ' + c.name FROM sys.columns c
              WHERE c.object_id = t.object_id ORDER BY c.column_id
              FOR XML PATH('')), 1, 2, '') AS columns
FROM   sys.tables t
WHERE  t.name LIKE '%setting%' OR t.name LIKE '%module%'
ORDER  BY t.name;
GO

/* ---- 7b. Brute force: any text column in any table containing the name --- */
--  Finds label/description/help rows keyed to the setting name.
--  SLOW (2026-09-27: ran several minutes on P21Dev and was cancelled). Leading-
--  wildcard LIKE = full scan of every text column in every table. Optional; 7a
--  already showed there is no label table. Skip unless you really need it.
--  Scans only small tables (< 200k rows) to stay fast on a big DB.
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
     + N' WHERE ' + QUOTENAME(c.name) + N' LIKE ''%push_usage_to_replen%'') '
     + N'SELECT ''' + t.name + N''' AS table_name, ''' + c.name + N''' AS column_name;' + CHAR(10)
FROM   sys.tables t
JOIN   sys.schemas s ON s.schema_id = t.schema_id
JOIN   sys.columns c ON c.object_id = t.object_id
JOIN   sys.types  ty ON ty.user_type_id = c.user_type_id
WHERE  ty.name IN ('varchar','nvarchar','char','nchar')
  AND  (c.max_length >= 20 OR c.max_length = -1)
  AND  t.name NOT LIKE 'zz%' AND t.name NOT LIKE 'temp%'
  AND  (SELECT SUM(p.rows) FROM sys.partitions p
        WHERE p.object_id = t.object_id AND p.index_id IN (0,1)) < 200000;
EXEC sp_executesql @sql;
GO

/* ---- 7c. Module code 805 -> module name (= System Settings tab?) --------- */
--  module.module_id is varchar ('AP'...), NOT the int module_cd -- Msg 245 if used.
--  module_cd is a code_p21 value.
SELECT code_no, code_description FROM dbo.code_p21 WHERE code_no IN (805, 809);
GO
