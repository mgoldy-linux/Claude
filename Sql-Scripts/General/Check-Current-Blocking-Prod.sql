-- Check-Current-Blocking-Prod.sql
-- Live snapshot of active requests, blocking chains, and waits on P21 Prod.
-- Run this WHILE someone is experiencing slowness -- it only shows what's happening right now.

SELECT
    r.session_id,
    r.blocking_session_id,
    r.status,
    r.wait_type,
    r.wait_time                                                AS wait_time_ms,
    r.wait_resource,
    r.cpu_time                                                 AS cpu_time_ms,
    r.total_elapsed_time                                       AS elapsed_ms,
    r.logical_reads,
    r.reads,
    r.writes,
    r.open_transaction_count,
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(r.database_id)                                     AS database_name,
    SUBSTRING(
        st.text,
        (r.statement_start_offset / 2) + 1,
        (
            (CASE r.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE r.statement_end_offset
             END - r.statement_start_offset) / 2
        ) + 1
    )                                                           AS executing_statement,
    st.text                                                     AS full_batch_text
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s
    ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE r.session_id <> @@SPID
ORDER BY
    CASE WHEN r.blocking_session_id > 0 THEN 0 ELSE 1 END,   -- blocked sessions first
    r.cpu_time DESC;
