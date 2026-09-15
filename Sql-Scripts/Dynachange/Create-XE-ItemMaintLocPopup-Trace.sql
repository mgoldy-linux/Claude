-- =============================================================================
-- Create-XE-ItemMaintLocPopup-Trace.sql
-- Server: P21Dev.allsurfaces.com (run in master)  --  Database: P21Training
-- (Confirmed via sys.databases 2026-09-14 -- catalog is "P21Training", not
-- "Training" as reference_p21_environments memory had it; that memory has
-- been corrected.)
--
-- PURPOSE
--   SA 54806. Two uses, same session:
--
--   (a) ORIGINAL: capture the "--DS"/"--DW" identifier comment PowerBuilder
--       prepends to the d_item_maint_loc_response retrieve SQL, for the
--       Create Pre-SQL Rule dialog's Class Name field.
--       ANSWERED: --DW d_item_maint_loc_response
--
--   (b) CURRENT: capture the WRITE-BACK. The real requirement is adding
--       MULTIPLE locations to an item at once; sorting the popup turned out
--       to be unachievable (the DataWindow's compiled sort spec beats any
--       Pre-SQL ORDER BY). So instead: check several locations, click OK,
--       and capture exactly what P21 does -- which tables it writes, whether
--       it calls a stored proc, how it allocates UIDs. That recipe is what a
--       bulk-add tool would need to reproduce faithfully.
--
-- USAGE
--   1. Run this whole script to create + start the session.
--   2. In P21, open Item Maintenance on a THROWAWAY item, go to Location
--      List, click Add Company, CHECK SEVERAL LOCATIONS, then click OK.
--      NOTE: this writes real data -- use a scratch item in a test env.
--   3. Run the SELECT in the READ section below.
--   4. Run the TEARDOWN section when done -- this is a temporary session.
--
--   DATABASE: set to P21BusinessRules (BRR) below, where the SA 54806 rule
--   work has been running. Change both WHERE clauses to 'P21Training' to
--   trace Training instead.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'ItemMaintLocPopup_Trace')
    DROP EVENT SESSION [ItemMaintLocPopup_Trace] ON SERVER;
GO

CREATE EVENT SESSION [ItemMaintLocPopup_Trace] ON SERVER
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
    SET filename            = N'\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\ItemMaintLocPopup_Trace.xel',
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

ALTER EVENT SESSION [ItemMaintLocPopup_Trace] ON SERVER STATE = START;
GO

SELECT s.name, s.startup_state, r.create_time
FROM sys.server_event_sessions s
LEFT JOIN sys.dm_xe_sessions r ON r.name = s.name
WHERE s.name = N'ItemMaintLocPopup_Trace';
GO

-- =============================================================================
-- READ THE DATA (run after reproducing the popup retrieve in the client)
-- =============================================================================
/*
;WITH x AS (
    SELECT
        n.c.value('@name','nvarchar(128)')                                       AS event_name,
        n.c.value('@timestamp','datetime2')                                      AS captured_utc,
        n.c.value('(action[@name="nt_username"]/value)[1]','nvarchar(256)')      AS nt_user,
        n.c.value('(action[@name="client_app_name"]/value)[1]','nvarchar(256)')  AS app,
        n.c.value('(data[@name="statement"]/value)[1]','nvarchar(max)')          AS rpc_statement,
        n.c.value('(data[@name="batch_text"]/value)[1]','nvarchar(max)')         AS batch_text
    FROM sys.fn_xe_file_target_read_file(
        '\\AHI-FILESRVR.AHI.LOCAL\Shared\mgoldyn\Portal-Tracking\ItemMaintLocPopup_Trace*.xel',
        NULL, NULL, NULL) AS f
    CROSS APPLY (SELECT CAST(f.event_data AS XML)) AS d(xml_data)
    CROSS APPLY d.xml_data.nodes('event') AS n(c)
)
SELECT *
FROM x
WHERE app LIKE 'PXXI%'          -- real P21 client traffic only; excludes the
                                -- scheduler service (Framework Microsoft
                                -- SqlClient Data Provider), SSMS and MH_API
  AND (COALESCE(rpc_statement, batch_text) LIKE '%inv_loc%'
    OR COALESCE(rpc_statement, batch_text) LIKE '%INSERT%'
    OR COALESCE(rpc_statement, batch_text) LIKE '%UPDATE%'
    OR COALESCE(rpc_statement, batch_text) LIKE '%counter%'
    OR COALESCE(rpc_statement, batch_text) LIKE '%p21_%')
ORDER BY captured_utc;          -- ASC: read the write-back in execution order
*/

-- =============================================================================
-- TEARDOWN (run when finished -- this is a temporary one-off trace)
-- =============================================================================
/*
ALTER EVENT SESSION [ItemMaintLocPopup_Trace] ON SERVER STATE = STOP;
DROP  EVENT SESSION [ItemMaintLocPopup_Trace] ON SERVER;
*/
