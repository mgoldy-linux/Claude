-- =============================================================================
-- Create-XE-SA56558-Lot-Qty-Error-Trace-Play.sql
-- Server: P21Dev.allsurfaces.com  (run in master)   Database traced: P21Play
--
-- PURPOSE
--   SA 56558 (lost bin): writing off KARSCB76 in the LOST bin at location 342
--   throws "There is not enough quantity available in lot V025G31".
--   This captures every statement P21 sends to P21Play plus any SQL-raised
--   error, so we can see (a) which lot/bin queries run right before the
--   message and (b) whether the message is raised by SQL at all.
--
-- HOW TO READ THE RESULT
--   * error_reported row containing the message  -> raised by a stored proc/trigger;
--     the sql_text / the statements just before it name the source object.
--   * NO error_reported row, but the message appears on screen -> client-side
--     validation (P21 app code). The last rpc/batch statements before the click
--     show which quantities it compared (lot.qty_on_hand, qty_allocated,
--     lot_bin_xref.qty_linked, inv_bin.quantity) and that is the rule.
--
-- USAGE
--   1. Run the CREATE + START section (nothing else is filtered by text on
--      purpose: a text filter evicted the real event last time).
--   2. Have NO ONE else use Play while you reproduce. Note the clock time,
--      reproduce the error once, note the time again.
--   3. Run the READ section (works while running OR after stop - event_file).
--   4. Run TEARDOWN. Temporary session; STARTUP_STATE = OFF.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'SA56558_Lot_Qty_Error_Trace')
    DROP EVENT SESSION [SA56558_Lot_Qty_Error_Trace] ON SERVER;
GO

CREATE EVENT SESSION [SA56558_Lot_Qty_Error_Trace] ON SERVER
ADD EVENT sqlserver.error_reported
(
    ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_name,
            sqlserver.nt_username, sqlserver.username, sqlserver.sql_text)
    WHERE ([sqlserver].[database_name] = N'P21Play')
),
ADD EVENT sqlserver.rpc_completed
(
    ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_name,
            sqlserver.nt_username, sqlserver.username)
    WHERE ([sqlserver].[database_name] = N'P21Play')
),
ADD EVENT sqlserver.sql_batch_completed
(
    ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_name,
            sqlserver.nt_username, sqlserver.username)
    WHERE ([sqlserver].[database_name] = N'P21Play')
)
ADD TARGET package0.event_file
(
    SET filename           = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\SA56558_Lot_Qty_Error_Trace.xel',
        max_file_size      = 200,   -- MB
        max_rollover_files = 3
)
WITH
(
    MAX_MEMORY            = 8192 KB,
    EVENT_RETENTION_MODE  = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY  = 5 SECONDS,
    MAX_EVENT_SIZE        = 0 KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY       = OFF,
    STARTUP_STATE         = OFF
);
GO

ALTER EVENT SESSION [SA56558_Lot_Qty_Error_Trace] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'SA56558_Lot_Qty_Error_Trace';
GO

-- =============================================================================
-- READ  (fill in the time window from step 2; times are UTC in the XE file)
-- =============================================================================
/*
DECLARE @from datetime2 = DATEADD(MINUTE, -10, SYSUTCDATETIME());   -- adjust

IF OBJECT_ID('tempdb..#x') IS NOT NULL DROP TABLE #x;

    SELECT
        n.c.value('@name','nvarchar(128)')                                      AS event_name,
        n.c.value('@timestamp','datetime2')                                     AS captured_utc,
        n.c.value('(action[@name="username"]/value)[1]','nvarchar(256)')        AS sql_login,
        n.c.value('(action[@name="client_hostname"]/value)[1]','nvarchar(256)') AS host,
        n.c.value('(action[@name="client_app_name"]/value)[1]','nvarchar(256)') AS app,
        n.c.value('(data[@name="message"]/value)[1]','nvarchar(max)')           AS error_message,
        n.c.value('(data[@name="error_number"]/value)[1]','int')                AS error_number,
        n.c.value('(action[@name="sql_text"]/value)[1]','nvarchar(max)')        AS error_sql_text,
        n.c.value('(data[@name="statement"]/value)[1]','nvarchar(max)')         AS rpc_statement,
        n.c.value('(data[@name="batch_text"]/value)[1]','nvarchar(max)')        AS batch_text,
        n.c.value('(data[@name="logical_reads"]/value)[1]','bigint')            AS logical_reads
    INTO #x
    FROM sys.fn_xe_file_target_read_file(
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\SA56558_Lot_Qty_Error_Trace*.xel',
        NULL, NULL, NULL) AS f
    CROSS APPLY (SELECT CAST(f.event_data AS XML)) AS d(xml_data)
    CROSS APPLY d.xml_data.nodes('event') AS n(c);

-- 0) sanity: what did we capture at all?
SELECT event_name, COUNT(*) n, MIN(captured_utc) first_utc, MAX(captured_utc) last_utc FROM #x GROUP BY event_name;

-- 1) did SQL raise the message? (0 rows = client-side validation)
SELECT * FROM #x
WHERE event_name = 'error_reported' AND error_message LIKE '%enough quantity%'
ORDER BY captured_utc;

-- 2) full statement trail for the window (look at the last ~30 before the message)
SELECT captured_utc, event_name, sql_login, host,
       COALESCE(rpc_statement, batch_text, error_sql_text) AS stmt, error_message
FROM #x
WHERE captured_utc >= @from
ORDER BY captured_utc;
*/

-- =============================================================================
-- TEARDOWN
-- =============================================================================
/*
ALTER EVENT SESSION [SA56558_Lot_Qty_Error_Trace] ON SERVER STATE = STOP;
DROP  EVENT SESSION [SA56558_Lot_Qty_Error_Trace] ON SERVER;
*/
