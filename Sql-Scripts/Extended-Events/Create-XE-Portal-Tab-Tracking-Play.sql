-- =============================================================================
-- Create-XE-Portal-Tab-Tracking-Play.sql
-- Server: P21Dev.allsurfaces.com  (run in master)   -- hosts the P21Play DB
-- DEPLOYED + VERIFIED on Play 2026-06-22.
--
-- Play-first test variant of Create-XE-Portal-Tab-Tracking.sql.
-- Differences from the Prod template:
--   * Predicate ALSO filters database_name = 'P21Play' -- the dev instance
--     hosts several P21 DBs; scope capture to Play only.
--   * File name suffixed _Play so it never collides with Prod's
--     Portal_Tab_Tracking*.xel in the same shared folder.
--
-- WHY sql_batch_completed (not sql_statement_completed):
--   The unique tab-open marker "--DS d_ds_portal_element" is a DataWindow
--   comment that lives ONLY in the BATCH text. sql_statement_completed's
--   [statement] field strips it, so a statement-level predicate captures
--   NOTHING. The batch event's [batch_text] keeps the comment. (Verified:
--   statement-level session captured 0 rows; batch-level captured the clicks.)
--
-- Signature (from Portal-Tab-research.trc):
--   --DS d_ds_portal_element
--   SELECT portal_element... FROM portal_element
--   WHERE portal_element.portal_element_uid = N AND report_metadata_uid IS NOT NULL
--   N = portal_element_uid -> map to tab via ud_tabpage / portal_user_defined.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'Portal_Tab_Tracking')
    DROP EVENT SESSION [Portal_Tab_Tracking] ON SERVER;
GO

CREATE EVENT SESSION [Portal_Tab_Tracking] ON SERVER
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
        [sqlserver].[like_i_sql_unicode_string]([batch_text], N'%d_ds_portal_element%')
        AND [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'P21Play')
    )
)
ADD TARGET package0.event_file
(
    SET filename            = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\Portal_Tab_Tracking_Play.xel',
        max_file_size       = 500,
        max_rollover_files  = 10
)
WITH
(
    MAX_MEMORY              = 4096 KB,
    EVENT_RETENTION_MODE    = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY    = 30 SECONDS,
    MAX_EVENT_SIZE          = 0 KB,
    MEMORY_PARTITION_MODE   = NONE,
    TRACK_CAUSALITY         = OFF,
    STARTUP_STATE           = ON
);
GO

ALTER EVENT SESSION [Portal_Tab_Tracking] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'Portal_Tab_Tracking';
GO

-- Ad-hoc read (run against P21Play for the tab-name join):
/*
;WITH x AS (
    SELECT
        n.c.value('@timestamp','datetime2')                                     AS captured_utc,
        n.c.value('(data[@name="batch_text"]/value)[1]','nvarchar(max)')        AS bt,
        n.c.value('(action[@name="nt_username"]/value)[1]','nvarchar(256)')     AS nt_user,
        n.c.value('(action[@name="client_app_name"]/value)[1]','nvarchar(256)') AS app
    FROM sys.fn_xe_file_target_read_file(
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\Portal_Tab_Tracking_Play*.xel',
        NULL, NULL, NULL) AS f
    CROSS APPLY (SELECT CAST(f.event_data AS XML)) AS d(xml_data)
    CROSS APPLY d.xml_data.nodes('event') AS n(c)
),
y AS (
    SELECT captured_utc, nt_user, app,
           TRY_CAST(
               LEFT( SUBSTRING(bt, PATINDEX('%portal_element_uid = [0-9]%', bt)+21, 12),
                     PATINDEX('%[^0-9]%', SUBSTRING(bt, PATINDEX('%portal_element_uid = [0-9]%', bt)+21, 12) + 'x') - 1
               ) AS int) AS portal_element_uid
    FROM x
    WHERE PATINDEX('%portal_element_uid = [0-9]%', bt) > 0
)
SELECT y.captured_utc, y.nt_user, y.app, y.portal_element_uid,
       tp.tabpage_text, pud.datawindow_name
FROM y
LEFT JOIN ud_tabpage          tp  ON tp.portal_element_uid  = y.portal_element_uid
LEFT JOIN portal_user_defined pud ON pud.portal_element_uid = y.portal_element_uid
ORDER BY y.captured_utc DESC;
*/

-- Teardown:
/*
ALTER EVENT SESSION [Portal_Tab_Tracking] ON SERVER STATE = STOP;
DROP  EVENT SESSION [Portal_Tab_Tracking] ON SERVER;
*/
