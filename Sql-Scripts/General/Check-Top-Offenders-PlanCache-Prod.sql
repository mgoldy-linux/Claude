-- Check-Top-Offenders-PlanCache-Prod.sql
-- Chronic offenders from the plan cache on P21 Prod, ranked by total logical reads and total CPU.
-- Measures logical reads / CPU (per SQL Perf Playbook), not wall-clock.
-- NOTE: cache resets on service restart / memory pressure / plan eviction -- this only reflects
-- what's currently cached, not all-time history.

SELECT TOP 25
    qs.execution_count,
    qs.total_logical_reads,
    qs.total_logical_reads / qs.execution_count                AS avg_logical_reads,
    qs.total_worker_time                                        AS total_cpu_us,
    qs.total_worker_time / qs.execution_count                   AS avg_cpu_us,
    qs.total_elapsed_time / qs.execution_count                  AS avg_elapsed_us,
    qs.last_execution_time,
    qs.creation_time,
    DB_NAME(st.dbid)                                            AS database_name,
    SUBSTRING(
        st.text,
        (qs.statement_start_offset / 2) + 1,
        (
            (CASE qs.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE qs.statement_end_offset
             END - qs.statement_start_offset) / 2
        ) + 1
    )                                                            AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE st.dbid = DB_ID('P21')
ORDER BY qs.total_logical_reads DESC;

-- Same query set, ranked by total CPU instead of reads -- uncomment to run separately if the
-- reads-based offender list doesn't line up with what people are feeling.
/*
SELECT TOP 25
    qs.execution_count,
    qs.total_worker_time                                        AS total_cpu_us,
    qs.total_worker_time / qs.execution_count                   AS avg_cpu_us,
    qs.total_logical_reads,
    qs.total_elapsed_time / qs.execution_count                  AS avg_elapsed_us,
    qs.last_execution_time,
    DB_NAME(st.dbid)                                            AS database_name,
    SUBSTRING(
        st.text,
        (qs.statement_start_offset / 2) + 1,
        (
            (CASE qs.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE qs.statement_end_offset
             END - qs.statement_start_offset) / 2
        ) + 1
    )                                                            AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE st.dbid = DB_ID('P21')
ORDER BY qs.total_worker_time DESC;
*/
