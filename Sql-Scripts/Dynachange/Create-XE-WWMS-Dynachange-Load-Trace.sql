-- =============================================================================
-- Create-XE-WWMS-Dynachange-Load-Trace.sql
-- Server: P21Dev.allsurfaces.com  (run in master)  --  Database: P21BusinessRules
--
-- PURPOSE
--   One-off diagnostic trace: capture what SQL actually fires when loading the
--   WWMS_screen_tab_oder web DynaChange (design_uid=3) in the P21BusinessRules
--   Version Manager -- confirms whether it hits p21_dynachange_info_web /
--   dynachange / design / assignment / modification as expected (see
--   [[reference_p21_wwms_web_dynachange_schema]]), or something else.
--
-- USAGE
--   1. Run this whole script to create + start the session.
--   2. In P21BusinessRules, load the WWMS_screen_tab_oder Dynachange.
--   3. Run the SELECT in the READ section below to see what fired.
--   4. Run the TEARDOWN section when done -- this is a temporary session.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'WWMS_Dynachange_Load_Trace')
    DROP EVENT SESSION [WWMS_Dynachange_Load_Trace] ON SERVER;
GO

CREATE EVENT SESSION [WWMS_Dynachange_Load_Trace] ON SERVER
ADD EVENT sqlserver.error_reported
(
    ACTION
    (
        sqlserver.client_app_name,
        sqlserver.database_name,
        sqlserver.nt_username,
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
        sqlserver.nt_username
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
        sqlserver.nt_username
    )
    WHERE
    (
        [sqlserver].[database_name] = N'P21BusinessRules'
    )
)
ADD TARGET package0.event_file
(
    SET filename            = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\WWMS_Dynachange_Load_Trace.xel',
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
    TRACK_CAUSALITY         = OFF,
    STARTUP_STATE           = OFF          -- one-off; don't survive a SQL restart
);
GO

ALTER EVENT SESSION [WWMS_Dynachange_Load_Trace] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'WWMS_Dynachange_Load_Trace';
GO

-- =============================================================================
-- READ THE DATA (run after reproducing the load in the client)
-- =============================================================================
/*
;WITH x AS (
    SELECT
        n.c.value('@name','nvarchar(128)')                                       AS event_name,
        n.c.value('@timestamp','datetime2')                                      AS captured_utc,
        n.c.value('(action[@name="nt_username"]/value)[1]','nvarchar(256)')      AS nt_user,
        n.c.value('(action[@name="client_app_name"]/value)[1]','nvarchar(256)')  AS app,
        n.c.value('(data[@name="message"]/value)[1]','nvarchar(max)')            AS error_message,
        n.c.value('(data[@name="statement"]/value)[1]','nvarchar(max)')          AS rpc_statement,
        n.c.value('(data[@name="batch_text"]/value)[1]','nvarchar(max)')         AS batch_text
    FROM sys.fn_xe_file_target_read_file(
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\WWMS_Dynachange_Load_Trace*.xel',
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
ALTER EVENT SESSION [WWMS_Dynachange_Load_Trace] ON SERVER STATE = STOP;
DROP  EVENT SESSION [WWMS_Dynachange_Load_Trace] ON SERVER;
*/
