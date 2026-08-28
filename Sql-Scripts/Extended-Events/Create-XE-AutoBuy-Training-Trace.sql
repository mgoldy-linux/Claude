-- =============================================================================
-- Create-XE-AutoBuy-Training-Trace.sql
-- Server: P21Dev.allsurfaces.com  (run in master)
--
-- PURPOSE
--   One-off diagnostic trace for the "Directs Auto Buy" job
--   (scheduled_job_uid 1692418, P21Training) failing with:
--     UiServerException: Column is disabled: beg_supplier_id
--     at ...PoRequirementCustomizationProvider.Process -> InteractiveRestClient.ChangeData
--   The job was auto-deactivated after 3 consecutive failures on 8/26. It replays a
--   saved window snapshot (po_criteria_id 784, beg/end_supplier_id 3003036,
--   supplier_option_cd 1694, requirement_type_direct_ship only) against
--   m_generatepurchaseorder. This trace captures every SQL statement the job issues
--   against P21Training so we can see what's happening around the failure point --
--   same technique as the BusinessRules trace (Create-XE-AutoBuy-Scheduler-Trace.sql),
--   which found a real impersonation-context collision there via SQL error 15408.
--
-- USAGE
--   1. Run this whole script to create + start the session.
--   2. Before reproducing: close every other P21 client window against Training --
--      especially Scheduled Task Manager -- to rule out the same live-session
--      impersonation collision found in Business Rules (see
--      feedback_p21_scheduler_impersonation_collision memory).
--   3. Reactivate/run the "Directs Auto Buy" job (it's currently Deactivated --
--      re-enable its schedule or use Scheduled Task Manager's on-demand run) and
--      let it fail.
--   4. Run the SELECT in the READ section below to see everything that fired.
--   5. Run the TEARDOWN section when done -- this is a temporary session.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'AutoBuy_Training_Trace')
    DROP EVENT SESSION [AutoBuy_Training_Trace] ON SERVER;
GO

CREATE EVENT SESSION [AutoBuy_Training_Trace] ON SERVER
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
        [sqlserver].[database_name] = N'P21Training'
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
        [sqlserver].[database_name] = N'P21Training'
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
        [sqlserver].[database_name] = N'P21Training'
    )
)
ADD TARGET package0.event_file
(
    SET filename            = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\AutoBuy_Training_Trace.xel',
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

ALTER EVENT SESSION [AutoBuy_Training_Trace] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'AutoBuy_Training_Trace';
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
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\AutoBuy_Training_Trace*.xel',
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
ALTER EVENT SESSION [AutoBuy_Training_Trace] ON SERVER STATE = STOP;
DROP  EVENT SESSION [AutoBuy_Training_Trace] ON SERVER;
*/
