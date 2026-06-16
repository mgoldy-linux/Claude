-- Check-KB-View-Usage-QueryStore.sql
-- Uses Query Store to find last execution time for all kb_ views.
-- Run on P21.allsurfaces.com / P21
--
-- Query Store survives restarts (unlike sys.dm_exec_* DMVs).
-- Retention window is typically 30 days -- check Section 0 for your settings.
--
-- NOTE: A view not found in results means no query referencing it appeared
-- in Query Store during the retention window -- not necessarily that it is
-- never used. Check stale_query_threshold_days in Section 0.
--
-- FIX: Query Store data is snapshotted into temp tables first to avoid
-- Msg 601 (NOLOCK scan failure) caused by data movement on a live system.
-- ============================================================

-- -------------------------------------------------------
-- Section 0: Query Store settings (verify retention window)
-- -------------------------------------------------------
SELECT
    actual_state_desc               AS qs_state,
    query_capture_mode_desc         AS capture_mode,
    size_based_cleanup_mode_desc    AS cleanup_mode,
    max_storage_size_mb,
    stale_query_threshold_days      AS retention_days,
    current_storage_size_mb
FROM sys.database_query_store_options;

-- -------------------------------------------------------
-- Snapshot Query Store into temp tables (avoids Msg 601)
-- -------------------------------------------------------
IF OBJECT_ID('tempdb..#qs') IS NOT NULL DROP TABLE #qs;

SELECT
    qt.query_sql_text,
    MAX(rs.last_execution_time)         AS last_execution_time,
    SUM(rs.count_executions)            AS count_executions,
    AVG(rs.avg_duration)                AS avg_duration
INTO #qs
FROM sys.query_store_query_text   qt
JOIN sys.query_store_query         q  ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan          qp ON qp.query_id     = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id      = qp.plan_id
WHERE qt.query_sql_text LIKE '%kb_%'   -- pre-filter: skip the vast majority of rows
GROUP BY qt.query_sql_text;

-- -------------------------------------------------------
-- Section 1: Last seen + total executions per kb_ view
-- -------------------------------------------------------
SELECT
    v.name                                  AS view_name,
    v.modify_date                           AS last_modified,
    MAX(qs.last_execution_time)             AS last_seen_in_qs,
    SUM(qs.count_executions)               AS total_executions,
    CAST(AVG(qs.avg_duration) / 1000.0
         AS decimal(10,2))                 AS avg_duration_ms,
    CASE
        WHEN MAX(qs.last_execution_time) IS NULL
            THEN '(not in Query Store)'
        ELSE CAST(DATEDIFF(day, MAX(qs.last_execution_time), GETDATE())
                  AS varchar) + ' day(s) ago'
    END                                     AS last_seen_age
FROM sys.views v
LEFT JOIN #qs qs ON qs.query_sql_text LIKE '%' + v.name + '%'
WHERE v.name LIKE 'kb_%'
GROUP BY v.name, v.modify_date
ORDER BY last_seen_in_qs DESC, v.modify_date DESC;

-- -------------------------------------------------------
-- Section 2: Views with NO Query Store history
--            (not seen within retention window)
-- -------------------------------------------------------
SELECT
    v.name          AS view_name,
    v.modify_date   AS last_modified,
    DATEDIFF(year, v.modify_date, GETDATE()) AS years_since_modified
FROM sys.views v
WHERE v.name LIKE 'kb_%'
  AND NOT EXISTS (
      SELECT 1 FROM #qs
      WHERE query_sql_text LIKE '%' + v.name + '%'
  )
ORDER BY v.modify_date;

DROP TABLE #qs;
