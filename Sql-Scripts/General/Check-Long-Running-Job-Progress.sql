-- Check-Long-Running-Job-Progress.sql
-- Live progress snapshot for a large/long-running query or job (big UPDATE/DELETE,
-- index rebuild, backup/restore, DBCC). Run this WHILE the job is executing.
--
-- percent_complete / estimated_completion_time are only populated by SQL Server for a
-- specific set of commands: BACKUP/RESTORE, DBCC (CHECKDB/SHRINKDATABASE/etc.), and
-- rollback. For a plain INSERT/UPDATE/DELETE/MERGE these stay 0 -- there, judge progress
-- from elapsed_sec trending against reads/writes, or from a row-count check against the
-- target table if the job doesn't log its own progress.

SELECT
    r.session_id,
    r.status,
    r.command,
    r.percent_complete,
    r.start_time,
    r.total_elapsed_time / 1000.0                              AS elapsed_sec,
    r.estimated_completion_time / 1000.0                       AS est_remaining_sec,
    CASE WHEN r.estimated_completion_time > 0
         THEN DATEADD(SECOND, r.estimated_completion_time / 1000, GETDATE())
    END                                                         AS est_finish_time,
    r.cpu_time                                                 AS cpu_time_ms,
    r.logical_reads,
    r.reads,
    r.writes,
    r.wait_type,
    r.wait_time                                                AS wait_time_ms,
    r.blocking_session_id,
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
    )                                                           AS executing_statement
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s
    ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE r.session_id <> @@SPID
    -- AND r.session_id = <spid>          -- narrow to one session once you know it
ORDER BY r.total_elapsed_time DESC;
