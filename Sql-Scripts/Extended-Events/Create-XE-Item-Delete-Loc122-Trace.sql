-- =============================================================================
-- Create-XE-Item-Delete-Loc122-Trace.sql
-- Server: P21Dev.allsurfaces.com (run in master)  --  Database: P21Play
--
-- PURPOSE
--   Item Maintenance: deleting location 122 from an item fails with
--     "Unable to delete item MDPCM2199HTI12. Potential Reasons: Item is on an open
--      sales order line. You must remove this item from its existing status before it
--      can be marked as deleted."
--   but the user sees no open orders. Reproduced in Play. This session captures what P21
--   actually runs in the background when the delete is attempted, so we can see which
--   table/check raises the message (open order lines? quotes? transfers? PO?).
--   Items: MDPCM2199HTI12, CARGLACIER38ANTI, ROPC60C83P177, AFCA020912F, AFCA020810F
--
-- DESIGN (lessons from memory, same as the other traces in this folder)
--   * event_file target, NOT ring_buffer (ring_buffer is unreadable after STOP).
--   * NO text predicate on statement/batch_text (silently captured nothing before) -
--     scope by database only and filter when reading.
--   * sql_statement_completed included: P21's generic engines run dynamic SQL via
--     EXEC(@sql), which sp_statement_completed never sees.
--   * error_reported included in case the message is raised from SQL.
--
-- USAGE
--   1. Run section 1 (create + start).
--   2. In the P21 client (Play), reproduce: Item Maintenance > item > location 122 > delete.
--      Do ONE attempt, ideally nothing else running in Play.
--   3. Run the READ section (section 2).
--   4. Run the TEARDOWN (section 3) when done - temporary session.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'ItemDeleteLoc122_Trace')
    DROP EVENT SESSION [ItemDeleteLoc122_Trace] ON SERVER;
GO

CREATE EVENT SESSION [ItemDeleteLoc122_Trace] ON SERVER
ADD EVENT sqlserver.rpc_completed
(
    ACTION (sqlserver.client_app_name, sqlserver.database_name, sqlserver.nt_username)
    WHERE ([sqlserver].[database_name] = N'P21Play')
),
ADD EVENT sqlserver.sql_batch_completed
(
    ACTION (sqlserver.client_app_name, sqlserver.database_name, sqlserver.nt_username)
    WHERE ([sqlserver].[database_name] = N'P21Play')
),
ADD EVENT sqlserver.sql_statement_completed
(
    ACTION (sqlserver.client_app_name, sqlserver.database_name, sqlserver.nt_username)
    WHERE ([sqlserver].[database_name] = N'P21Play')
),
ADD EVENT sqlserver.error_reported
(
    ACTION (sqlserver.client_app_name, sqlserver.database_name, sqlserver.nt_username)
    WHERE ([sqlserver].[database_name] = N'P21Play')
)
ADD TARGET package0.event_file
(
    SET filename            = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\ItemDeleteLoc122_Trace.xel',
        max_file_size       = 100,   -- MB
        max_rollover_files  = 3
)
WITH
(
    MAX_MEMORY              = 4096 KB,
    EVENT_RETENTION_MODE    = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY    = 5 SECONDS,
    MAX_EVENT_SIZE          = 0 KB,
    MEMORY_PARTITION_MODE   = NONE,
    TRACK_CAUSALITY         = OFF,
    STARTUP_STATE           = OFF
);
GO

ALTER EVENT SESSION [ItemDeleteLoc122_Trace] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'ItemDeleteLoc122_Trace';
GO

-- =============================================================================
-- 2) READ THE DATA (run after reproducing the delete in the client)
--    First pass: everything from the P21 client, in execution order.
--    Second pass: add AND (...) LIKE '%MDPCM2199HTI12%' / '%inv_mast_uid%' to narrow it.
--    If it is empty, DON'T conclude P21 never hit SQL - widen/remove the app filter.
-- =============================================================================
/*
;WITH x AS (
    SELECT
        n.c.value('@name','nvarchar(128)')                                       AS event_name,
        n.c.value('@timestamp','datetime2')                                      AS captured_utc,
        n.c.value('(action[@name="nt_username"]/value)[1]','nvarchar(256)')      AS nt_user,
        n.c.value('(action[@name="client_app_name"]/value)[1]','nvarchar(256)')  AS app,
        n.c.value('(data[@name="statement"]/value)[1]','nvarchar(max)')          AS statement_text,
        n.c.value('(data[@name="batch_text"]/value)[1]','nvarchar(max)')         AS batch_text,
        n.c.value('(data[@name="message"]/value)[1]','nvarchar(max)')            AS error_message
    FROM sys.fn_xe_file_target_read_file(
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\ItemDeleteLoc122_Trace*.xel',
        NULL, NULL, NULL) AS f
    CROSS APPLY (SELECT CAST(f.event_data AS XML)) AS d(xml_data)
    CROSS APPLY d.xml_data.nodes('event') AS n(c)
)
SELECT *
FROM x
WHERE app LIKE 'PXXI%'            -- real P21 client traffic only
ORDER BY captured_utc;
*/

-- =============================================================================
-- 3) TEARDOWN (run when finished)
-- =============================================================================
/*
ALTER EVENT SESSION [ItemDeleteLoc122_Trace] ON SERVER STATE = STOP;
DROP  EVENT SESSION [ItemDeleteLoc122_Trace] ON SERVER;
*/
