-- Find-InvLoc-Batch-Update-Source.sql
-- Identify who/what ran a batch inv_loc update -- a coordinated multi-field change
-- (classification + replenishment + costing columns all touched together across many
-- rows in a short window) is the signature of a scheduled reclass/replenishment-recalc
-- job or a mass item-maintenance edit, not routine one-off user activity.
--
-- Set @WindowStart/@WindowEnd to the batch window you're investigating (e.g. identified
-- from a plan-cache top-offenders check where many inv_loc-related plans share the same
-- creation_time cluster).
--
-- TRAP (found 2026-09-28): a high execution_count on the inv_loc trigger's per-column
-- audit_trail INSERT statements does NOT mean that many rows actually changed. The
-- trigger fires its full set of ~12 column-specific INSERT statements on every AFTER
-- UPDATE, each guarded by its own WHERE COALESCE(inserted.x,'') <> COALESCE(deleted.x,'')
-- -- most executions insert zero rows. execution_count there measures trigger firings
-- (cumulative since the plan was cached), not real value changes. Before concluding a
-- batch update happened, confirm against actual inv_loc.date_last_modified rows (see the
-- last query below) -- a 700+ execution_count with only a handful of real
-- date_last_modified rows in the same window means normal trigger overhead, not a batch.

DECLARE @WindowStart DATETIME = '2026-09-28 07:30';
DECLARE @WindowEnd   DATETIME = '2026-09-28 07:40';

-- Summary: who/what touched inv_loc in the window, and how many rows
SELECT
    last_maintained_by,
    COUNT(*)                          AS rows_updated,
    MIN(date_last_modified)           AS first_update,
    MAX(date_last_modified)           AS last_update
FROM inv_loc
WHERE date_last_modified >= @WindowStart
    AND date_last_modified <  @WindowEnd
GROUP BY last_maintained_by
ORDER BY rows_updated DESC;

-- Detail: the actual rows + fields changed, to confirm which columns moved together
SELECT TOP 50
    inv_mast_uid, location_id, last_maintained_by, date_last_modified,
    purchase_class, demand_pattern_behavior_cd, track_bins, price10,
    gl_account_no, revenue_account_no, replenishment_location,
    future_standard_cost, standard_cost, drp_item_flag,
    max_safety_stock_days, inv_max
FROM inv_loc
WHERE date_last_modified >= @WindowStart
    AND date_last_modified <  @WindowEnd
ORDER BY date_last_modified;

-- Cross-check: was a SQL Agent job running in the same window?
-- msdb stores run_date/run_time as int (YYYYMMDD / HHMMSS, no leading zeros) --
-- convert @WindowStart/@WindowEnd below by hand if you change the dates above.
SELECT
    j.name                              AS job_name,
    s.step_name,
    h.run_date,
    h.run_time,
    h.run_duration,
    h.run_status,        -- 0=Failed, 1=Succeeded, 3=Cancelled, 4=In Progress
    h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON j.job_id = h.job_id
LEFT JOIN msdb.dbo.sysjobsteps s ON s.job_id = h.job_id AND s.step_id = h.step_id
WHERE h.run_date = 20260928
    AND h.run_time BETWEEN 72000 AND 74000   -- 07:20:00-07:40:00
ORDER BY h.run_time DESC;

-- How many distinct inv_loc rows changed today, and over what actual time span?
SELECT
    CAST(date_last_modified AS DATE)                AS mod_date,
    DATEPART(HOUR, date_last_modified)               AS mod_hour,
    COUNT(*)                                          AS rows_updated,
    COUNT(DISTINCT last_maintained_by)                AS distinct_users
FROM inv_loc
WHERE date_last_modified >= '2026-09-28'
GROUP BY CAST(date_last_modified AS DATE), DATEPART(HOUR, date_last_modified)
ORDER BY mod_hour;