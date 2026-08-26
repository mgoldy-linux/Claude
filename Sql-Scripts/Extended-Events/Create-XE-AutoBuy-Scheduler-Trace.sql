-- =============================================================================
-- Create-XE-AutoBuy-Scheduler-Trace.sql
-- Server: P21Dev.allsurfaces.com  (run in master)
--
-- PURPOSE
--   One-off diagnostic trace for the "Auto Buy - Test Scheduler" job
--   (scheduled_job_uid 1707975, P21BusinessRules) failing with:
--     UiServerException: Tab page is disabled and cannot be selected
--     at ...PoRequirementCustomizationProvider.Process -> InteractiveRestClient.ChangeData
--   Manually running criteria 466 (RB - Directs) in the P21 client succeeds and
--   generates a PO, so this isn't a data/demand problem -- it's specific to the
--   scheduled job's automated replay. This trace captures every SQL statement the
--   job issues against P21BusinessRules so we can see exactly what it's doing
--   (and what it does differently vs. a live session) up to the point it fails.
--
-- USAGE
--   1. Run this whole script to create + start the session.
--   2. Reproduce: run the "Auto Buy - Test Scheduler" job (Scheduled Task Manager
--      or however it's triggered) in Business Rules; let it fail.
--   3. Run the SELECT in the READ section below to see everything that fired.
--   4. Run the TEARDOWN section when done -- this is a temporary session.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'AutoBuy_Scheduler_Trace')
    DROP EVENT SESSION [AutoBuy_Scheduler_Trace] ON SERVER;
GO

CREATE EVENT SESSION [AutoBuy_Scheduler_Trace] ON SERVER
ADD EVENT sqlserver.error_reported
(
    ACTION
    (
        sqlserver.client_app_name,
        sqlserver.database_name,
        sqlserver.nt_username,
        sqlserver.username,
        sqlserver.sql_text
    )
    WHERE
    (
        [sqlserver].[database_name] = N'P21BusinessRules'
    )
),
ADD EVENT sqlserver.rpc_completed
(
    ACTION
    (
        sqlserver.client_app_name,
        sqlserver.database_name,
        sqlserver.nt_username,
        sqlserver.username
    )
    WHERE
    (
        [sqlserver].[database_name] = N'P21BusinessRules'
    )
),
ADD EVENT sqlserver.sql_batch_completed
(
    ACTION
    (
        sqlserver.client_app_name,
        sqlserver.database_name,
        sqlserver.nt_username,
        sqlserver.username
    )
    WHERE
    (
        [sqlserver].[database_name] = N'P21BusinessRules'
    )
)
ADD TARGET package0.event_file
(
    SET filename            = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\AutoBuy_Scheduler_Trace.xel',
        max_file_size       = 100,   -- MB
        max_rollover_files  = 3
)
WITH
(
    MAX_MEMORY              = 4096 KB,
    EVENT_RETENTION_MODE    = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY    = 5 SECONDS,   -- short latency, this is a live one-off repro
    MAX_EVENT_SIZE          = 0 KB,
    MEMORY_PARTITION_MODE   = NONE,
    TRACK_CAUSALITY         = ON,          -- want call ordering around the failure point
    STARTUP_STATE           = OFF          -- one-off; don't survive a SQL restart
);
GO

ALTER EVENT SESSION [AutoBuy_Scheduler_Trace] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'AutoBuy_Scheduler_Trace';
GO

-- =============================================================================
-- READ THE DATA (run after reproducing the job failure)
-- =============================================================================
/*
;WITH x AS (
    SELECT
        n.c.value('@name','nvarchar(128)')                                       AS event_name,
        n.c.value('@timestamp','datetime2')                                      AS captured_utc,
        n.c.value('(action[@name="username"]/value)[1]','nvarchar(256)')         AS sql_user,
        n.c.value('(action[@name="nt_username"]/value)[1]','nvarchar(256)')      AS nt_user,
        n.c.value('(action[@name="client_app_name"]/value)[1]','nvarchar(256)')  AS app,
        n.c.value('(data[@name="message"]/value)[1]','nvarchar(max)')            AS error_message,
        n.c.value('(data[@name="severity"]/value)[1]','int')                     AS severity,
        n.c.value('(data[@name="error_number"]/value)[1]','int')                 AS error_number,
        n.c.value('(action[@name="sql_text"]/value)[1]','nvarchar(max)')         AS error_sql_text,
        n.c.value('(data[@name="statement"]/value)[1]','nvarchar(max)')          AS rpc_statement,
        n.c.value('(data[@name="batch_text"]/value)[1]','nvarchar(max)')         AS batch_text
    FROM sys.fn_xe_file_target_read_file(
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\AutoBuy_Scheduler_Trace*.xel',
        NULL, NULL, NULL) AS f
    CROSS APPLY (SELECT CAST(f.event_data AS XML)) AS d(xml_data)
    CROSS APPLY d.xml_data.nodes('event') AS n(c)
)
SELECT * FROM x ORDER BY captured_utc DESC;
*/

-- =============================================================================
-- TEARDOWN (run when finished -- this is a temporary one-off trace)
-- =============================================================================
/*
ALTER EVENT SESSION [AutoBuy_Scheduler_Trace] ON SERVER STATE = STOP;
DROP  EVENT SESSION [AutoBuy_Scheduler_Trace] ON SERVER;
*/
