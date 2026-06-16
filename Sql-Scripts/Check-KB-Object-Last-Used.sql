-- Check-KB-Object-Last-Used.sql
-- Shows last execution time for all kb_ stored procs, functions, triggers, and views.
-- Run on P21.allsurfaces.com / P21
--
-- DMV coverage:
--   PROC    : sys.dm_exec_procedure_stats  (resets on restart)
--   FUNC    : sys.dm_exec_function_stats   (resets on restart, SQL Server 2016+)
--   TRIGGER : sys.dm_exec_trigger_stats    (resets on restart)
--   VIEW    : no DMV available -- showing modify_date only
-- ============================================================

DECLARE @serverStart datetime = (SELECT sqlserver_start_time FROM sys.dm_os_sys_info);

-- Stored Procedures
SELECT
    'PROC'                      AS object_type,
    o.name                      AS object_name,
    o.modify_date               AS last_modified,
    ps.execution_count          AS exec_count,
    ps.last_execution_time,
    CASE
        WHEN ps.last_execution_time IS NULL
            THEN '(none since restart)'
        ELSE CAST(DATEDIFF(day, ps.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
    END                         AS last_exec_age,
    @serverStart                AS server_start_time
FROM sys.objects o
LEFT JOIN sys.dm_exec_procedure_stats ps
    ON  ps.object_id   = o.object_id
    AND ps.database_id = DB_ID()
WHERE o.type = 'P'
  AND o.name LIKE 'kb_%'

UNION ALL

-- Scalar Functions
SELECT
    'SCALAR FUNC'               AS object_type,
    o.name,
    o.modify_date,
    fs.execution_count,
    fs.last_execution_time,
    CASE
        WHEN fs.last_execution_time IS NULL
            THEN '(none since restart)'
        ELSE CAST(DATEDIFF(day, fs.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
    END,
    @serverStart
FROM sys.objects o
LEFT JOIN sys.dm_exec_function_stats fs
    ON  fs.object_id   = o.object_id
    AND fs.database_id = DB_ID()
WHERE o.type = 'FN'
  AND o.name LIKE 'kb_%'

UNION ALL

-- Table-Valued Functions (inline and multi-statement)
SELECT
    'TVF'                       AS object_type,
    o.name,
    o.modify_date,
    fs.execution_count,
    fs.last_execution_time,
    CASE
        WHEN fs.last_execution_time IS NULL
            THEN '(none since restart)'
        ELSE CAST(DATEDIFF(day, fs.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
    END,
    @serverStart
FROM sys.objects o
LEFT JOIN sys.dm_exec_function_stats fs
    ON  fs.object_id   = o.object_id
    AND fs.database_id = DB_ID()
WHERE o.type IN ('IF', 'TF')
  AND o.name LIKE 'kb_%'

UNION ALL

-- Triggers
SELECT
    'TRIGGER'                   AS object_type,
    o.name,
    o.modify_date,
    ts.execution_count,
    ts.last_execution_time,
    CASE
        WHEN ts.last_execution_time IS NULL
            THEN '(none since restart)'
        ELSE CAST(DATEDIFF(day, ts.last_execution_time, GETDATE()) AS varchar) + ' day(s) ago'
    END,
    @serverStart
FROM sys.objects o
LEFT JOIN sys.dm_exec_trigger_stats ts
    ON  ts.object_id   = o.object_id
    AND ts.database_id = DB_ID()
WHERE o.type = 'TR'
  AND o.name LIKE 'kb_%'

UNION ALL

-- Views (no execution DMV -- modify_date only)
SELECT
    'VIEW'                      AS object_type,
    o.name,
    o.modify_date,
    NULL                        AS exec_count,
    NULL                        AS last_execution_time,
    '(no DMV -- use Query Store)' AS last_exec_age,
    @serverStart
FROM sys.objects o
WHERE o.type = 'V'
  AND o.name LIKE 'kb_%'

ORDER BY
    object_type,
    last_execution_time DESC,
    object_name;
