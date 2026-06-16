-- Check-KB-Table-Last-Used.sql
-- Shows last read and write timestamps for all kb_ tables.
-- Run on P21.allsurfaces.com / P21
--
-- IMPORTANT: sys.dm_db_index_usage_stats resets on every SQL Server restart.
-- The server_start_time column shows how far back these timestamps are valid.
-- Tables showing NULL were not touched since the last restart (or have no indexes).
-- ============================================================

DECLARE @serverStart datetime = (SELECT sqlserver_start_time FROM sys.dm_os_sys_info);

SELECT
    t.name                                          AS table_name,
    p.rows                                          AS row_count,
    -- Most recent of any read type (VALUES MAX works on SQL Server 2008+)
    NULLIF((SELECT MAX(v) FROM (VALUES
        (MAX(u.last_user_seek)),
        (MAX(u.last_user_scan)),
        (MAX(u.last_user_lookup))
    ) x(v)), NULL)                                  AS last_read,
    MAX(u.last_user_update)                         AS last_write,
    CASE
        WHEN MAX(u.last_user_update) IS NULL THEN '(none since restart)'
        ELSE CAST(DATEDIFF(day, MAX(u.last_user_update), GETDATE()) AS varchar) + ' day(s) ago'
    END                                             AS last_write_age,
    @serverStart                                    AS server_start_time
FROM sys.tables t
JOIN sys.partitions p
    ON  p.object_id = t.object_id
    AND p.index_id IN (0, 1)   -- heap (0) or clustered index (1)
LEFT JOIN sys.dm_db_index_usage_stats u
    ON  u.object_id   = t.object_id
    AND u.database_id = DB_ID()
WHERE t.name LIKE 'kb_%'
GROUP BY t.name, p.rows
ORDER BY
    last_write DESC,
    last_read  DESC,
    t.name;
