-- Check-Server-Slowness-Diagnostics.sql
-- Combined "why is it slow right now" diagnostic pass for P21 SQL Server.
-- Run the whole batch in SSMS -- each section is its own result set (flip through the
-- Results tabs). For a live blocking-chain drill-down on a specific session, use
-- Check-Current-Blocking-Prod.sql instead; for a single long-running job's progress, use
-- Check-Long-Running-Job-Progress.sql. This script is for "something feels slow, what's
-- the cause" triage across the whole instance.

------------------------------------------------------------------------------
-- 1. Top cumulative wait stats since last restart / DBCC SQLPERF(sys.dm_os_wait_stats, CLEAR)
--    Excludes benign/idle wait types so the real signal isn't buried.
------------------------------------------------------------------------------
SELECT TOP 20
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    wait_time_ms - signal_wait_time_ms                         AS resource_wait_time_ms,
    signal_wait_time_ms,
    CAST(wait_time_ms * 100.0 / SUM(wait_time_ms) OVER () AS DECIMAL(5,2)) AS pct_of_total_wait_time
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK',
    'SQLTRACE_BUFFER_FLUSH','WAITFOR','LOGMGR_QUEUE','CHECKPOINT_QUEUE',
    'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP',
    'CLR_MANUAL_EVENT','CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE',
    'FT_IFTS_SCHEDULER_IDLE_WAIT','XE_DISPATCHER_WAIT','XE_DISPATCHER_JOIN',
    'BROKER_EVENTHANDLER','TRACEWRITE','BROKER_RECEIVE_WAITFOR','ONDEMAND_TASK_QUEUE',
    'DBMIRROR_EVENTS_QUEUE','DBMIRRORING_CMD','BROKER_TRANSMITTER','SQLTRACE_WAIT_ENTRIES',
    'SLEEP_BPOOL_FLUSH','SQLTRACE_INCREMENTAL_FLUSH_SLEEP','WAIT_XTP_HOST_WAIT',
    'WAIT_XTP_OFFLINE_CKPT_NEW_LOG','WAIT_XTP_CKPT_CLOSE','PWAIT_ALL_COMPONENTS_INITIALIZED',
    'SOS_WORK_DISPATCHER','DIRTY_PAGE_POLL','FT_IFTSHC_MUTEX','SP_SERVER_DIAGNOSTICS_SLEEP',
    'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP','QDS_ASYNC_QUEUE','QDS_SHUTDOWN_QUEUE',
    'XE_LIVE_TARGET_TVF','XE_TIMER_EVENT','BROKER_CONNECTION_RECEIVE_TASK',
    'HADR_FILESTREAM_IOMGR_IOCOMPLETION','DBMIRROR_DBM_EVENT','DBMIRROR_WORKER_QUEUE'
)
AND waiting_tasks_count > 0
ORDER BY wait_time_ms DESC;

------------------------------------------------------------------------------
-- 2. Wait types in flight RIGHT NOW, aggregated -- quick pulse check.
------------------------------------------------------------------------------
SELECT
    r.wait_type,
    COUNT(*)                                                   AS sessions_waiting,
    SUM(r.wait_time)                                           AS total_wait_time_ms,
    MAX(r.wait_time)                                           AS longest_wait_ms
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s
    ON s.session_id = r.session_id
WHERE r.wait_type IS NOT NULL
    AND r.session_id <> @@SPID
    AND s.is_user_process = 1          -- exclude background/system session waits
GROUP BY r.wait_type
ORDER BY total_wait_time_ms DESC;

------------------------------------------------------------------------------
-- 3. Memory pressure -- Page Life Expectancy and buffer cache hit ratio.
--    PLE dropping sharply, or sitting low relative to normal, means the buffer pool
--    is churning and queries are paying extra physical I/O they normally wouldn't.
------------------------------------------------------------------------------
SELECT
    object_name,
    counter_name,
    cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name IN ('Page life expectancy', 'Buffer cache hit ratio', 'Buffer cache hit ratio base')
    AND object_name LIKE '%Buffer Manager%';

------------------------------------------------------------------------------
-- 4. tempdb contention -- current PAGELATCH waits on tempdb pages, plus space usage.
------------------------------------------------------------------------------
SELECT
    r.session_id,
    r.wait_type,
    r.wait_time                                                AS wait_time_ms,
    r.wait_resource,
    s.login_name,
    s.program_name
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s
    ON s.session_id = r.session_id
WHERE r.wait_type LIKE 'PAGELATCH%'
    AND r.wait_resource LIKE '2:%'     -- database_id 2 = tempdb
    AND s.is_user_process = 1;

SELECT
    SUM(user_object_reserved_page_count) * 8 / 1024.0           AS user_objects_mb,
    SUM(internal_object_reserved_page_count) * 8 / 1024.0       AS internal_objects_mb,
    SUM(version_store_reserved_page_count) * 8 / 1024.0         AS version_store_mb,
    SUM(unallocated_extent_page_count) * 8 / 1024.0             AS free_mb
FROM tempdb.sys.dm_db_file_space_usage;

------------------------------------------------------------------------------
-- 5. Plan cache top offenders by LOGICAL READS -- the measured, not-wall-clock signal
--    for "what's actually expensive." Sorts/limits to the top 20 BEFORE decoding SQL
--    text -- decoding text for every cached plan instance-wide first, then filtering,
--    is itself a needless load on a busy server. database_name lets you eyeball which
--    env a given row belongs to (not pre-filtered, since that would mean decoding text
--    for the whole cache just to read dbid).
------------------------------------------------------------------------------
;WITH top_reads AS (
    SELECT TOP 20
        sql_handle, statement_start_offset, statement_end_offset,
        execution_count, total_logical_reads, total_worker_time,
        total_elapsed_time, creation_time, last_execution_time
    FROM sys.dm_exec_query_stats
    ORDER BY total_logical_reads DESC
)
SELECT
    tr.execution_count,
    tr.total_logical_reads,
    tr.total_logical_reads / tr.execution_count                 AS avg_logical_reads,
    tr.total_worker_time / 1000                                 AS total_cpu_ms,
    tr.total_elapsed_time / 1000                                AS total_elapsed_ms,
    tr.creation_time,
    tr.last_execution_time,
    DB_NAME(st.dbid)                                            AS database_name,
    SUBSTRING(
        st.text,
        (tr.statement_start_offset / 2) + 1,
        (
            (CASE tr.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE tr.statement_end_offset
             END - tr.statement_start_offset) / 2
        ) + 1
    )                                                            AS statement_text
FROM top_reads AS tr
CROSS APPLY sys.dm_exec_sql_text(tr.sql_handle) AS st
ORDER BY tr.total_logical_reads DESC;

------------------------------------------------------------------------------
-- 6. Plan cache top offenders by CPU (total_worker_time) -- complements #5; a query can
--    be CPU-heavy (lots of computation per row) without being I/O-heavy. Same
--    sort-then-decode pattern as #5.
------------------------------------------------------------------------------
;WITH top_cpu AS (
    SELECT TOP 20
        sql_handle, statement_start_offset, statement_end_offset,
        execution_count, total_worker_time, total_logical_reads,
        total_elapsed_time, creation_time
    FROM sys.dm_exec_query_stats
    ORDER BY total_worker_time DESC
)
SELECT
    tc.execution_count,
    tc.total_worker_time / 1000                                 AS total_cpu_ms,
    tc.total_worker_time / tc.execution_count / 1000.0           AS avg_cpu_ms,
    tc.total_logical_reads,
    tc.total_elapsed_time / 1000                                AS total_elapsed_ms,
    tc.creation_time,
    DB_NAME(st.dbid)                                            AS database_name,
    SUBSTRING(
        st.text,
        (tc.statement_start_offset / 2) + 1,
        (
            (CASE tc.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE tc.statement_end_offset
             END - tc.statement_start_offset) / 2
        ) + 1
    )                                                            AS statement_text
FROM top_cpu AS tc
CROSS APPLY sys.dm_exec_sql_text(tc.sql_handle) AS st
ORDER BY tc.total_worker_time DESC;

------------------------------------------------------------------------------
-- 7. Ad-hoc / single-use plan cache bloat check. A pile of never-reused plans (one
--    execution each, often from literal-valued batches like a script of thousands of
--    individual UPDATE statements) burns plan cache memory and CPU on compilation for
--    everyone else. If this is large, consider 'optimize for ad hoc workloads' and/or
--    parameterizing the offending script.
------------------------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS single_use_plan_count,
    SUM(CAST(size_in_bytes AS BIGINT)) / 1024 / 1024             AS single_use_plan_cache_mb
FROM sys.dm_exec_cached_plans
WHERE cacheobjtype = 'Compiled Plan'
    AND objtype = 'Adhoc'
    AND usecounts = 1;

------------------------------------------------------------------------------
-- 8. Recent data/log file autogrow events (default trace). An autogrow event stalls
--    all writers to that file while it grows -- especially painful for log files or
--    data files without instant file initialization.
------------------------------------------------------------------------------
DECLARE @tracefile NVARCHAR(260);
SELECT @tracefile = REVERSE(SUBSTRING(REVERSE([path]), CHARINDEX(N'\', REVERSE([path])), 260)) + N'log.trc'
FROM sys.traces
WHERE is_default = 1;

SELECT
    DatabaseName,
    FileName,
    StartTime,
    Duration / 1000.0                                           AS duration_sec,
    CASE EventClass WHEN 92 THEN 'Data File Auto Grow' WHEN 93 THEN 'Log File Auto Grow' END AS event_type
FROM ::fn_trace_gettable(@tracefile, DEFAULT)
WHERE EventClass IN (92, 93)
ORDER BY StartTime DESC;
