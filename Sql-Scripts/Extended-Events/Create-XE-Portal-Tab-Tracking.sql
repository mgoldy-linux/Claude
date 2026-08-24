-- =============================================================================
-- Create-XE-Portal-Tab-Tracking.sql
-- Server: P21.allsurfaces.com  (run in master)
--
-- PURPOSE
--   Captures EVERY portal-tab / portal-element selection, including the standard
--   embedded window tabs (e.g. Login History = sa_user_login_history) that the
--   existing Portal_Usage_Tracking session is blind to.
--
-- WHY A SECOND SESSION
--   Portal_Usage_Tracking keys on  statement LIKE '%subscriber_datawindow%'
--   -- that only matches Dynachange user-defined portal loads. When a user
--   clicks ANY portal tab, the UI/desktop client also fires this DataWindow:
--
--       --DS d_ds_portal_element
--       SELECT portal_element... FROM portal_element
--       WHERE portal_element.portal_element_uid = <UID>
--         AND portal_element.report_metadata_uid IS NOT NULL ...
--
--   <UID> = portal_element_uid -> map to a tab via ud_tabpage / portal_user_defined.
--   Confirmed from trace Portal-Tab-research.trc (189 = Login History,
--   248 = Print History) and verified live on P21Play 2026-06-22.
--
-- WHY sql_batch_completed (NOT sql_statement_completed)
--   The "--DS d_ds_portal_element" marker is a DataWindow comment that exists
--   ONLY in the batch text. sql_statement_completed's [statement] field strips
--   the comment, so a statement-level predicate captures NOTHING. Capture the
--   batch event and key on [batch_text]. (Verified on Play: statement-level = 0
--   rows, batch-level = the clicks.)
--
-- OUTPUT
--   \\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\Portal_Tab_Tracking*.xel
--   (same folder as Portal_Usage_Tracking; different file prefix -- no collision)
--
-- NOTE: Prod (P21) hosts a single P21 DB, so no database_name filter is needed
--       here. The Play variant adds AND database_name='P21Play' because that
--       instance is shared. See Create-XE-Portal-Tab-Tracking-Play.sql.
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
    )
)
ADD TARGET package0.event_file
(
    SET filename            = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\Portal_Tab_Tracking.xel',
        max_file_size       = 500,   -- MB per file
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
    STARTUP_STATE           = ON          -- survives a SQL Server restart
);
GO

ALTER EVENT SESSION [Portal_Tab_Tracking] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'Portal_Tab_Tracking';
GO

-- =============================================================================
-- READ THE DATA (run anytime; works while session is running)
-- =============================================================================
/*
;WITH x AS (
    SELECT
        n.c.value('@timestamp','datetime2')                                     AS captured_utc,
        n.c.value('(data[@name="batch_text"]/value)[1]','nvarchar(max)')        AS bt,
        n.c.value('(action[@name="nt_username"]/value)[1]','nvarchar(256)')     AS nt_user,
        n.c.value('(action[@name="client_app_name"]/value)[1]','nvarchar(256)') AS app
    FROM sys.fn_xe_file_target_read_file(
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\Portal_Tab_Tracking*.xel',
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

-- =============================================================================
-- TEARDOWN (when finished)
-- =============================================================================
/*
ALTER EVENT SESSION [Portal_Tab_Tracking] ON SERVER STATE = STOP;
DROP  EVENT SESSION [Portal_Tab_Tracking] ON SERVER;
*/
