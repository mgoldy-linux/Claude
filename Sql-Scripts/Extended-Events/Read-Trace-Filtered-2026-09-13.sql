/* Filtered read of asi_item_import_trace -- scoped to the actual
   Build/Update Items run: 2026-09-13 07:01:01 - 07:01:22 (server local time),
   30-second buffer each side. Run against the already-captured .xel file --
   no need to re-run the import or the XE session. */

USE P21Dev;
GO

DECLARE @OffsetMin INT = DATEDIFF(MINUTE, GETUTCDATE(), GETDATE());
DECLARE @StartUtc DATETIME2 = DATEADD(SECOND, -30, DATEADD(MINUTE, -@OffsetMin, '2026-09-13 07:01:01'));
DECLARE @EndUtc   DATETIME2 = DATEADD(SECOND,  30, DATEADD(MINUTE, -@OffsetMin, '2026-09-13 07:01:22'));

;WITH raw AS (
    SELECT CAST(event_data AS xml) AS ev
    FROM   sys.fn_xe_file_target_read_file(N'L:\SQL\asi_item_import_trace*.xel', NULL, NULL, NULL)
),
e AS (
    SELECT  ev,
            ev.value('(event/@name)[1]', 'varchar(60)') AS event_name,
            ev.value('(event/@timestamp)[1]', 'datetime2') AS ts_utc
    FROM raw
)
SELECT
    ts_utc,
    event_name,
    ev.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(256)') AS client_app,
    ev.value('(event/action[@name="nt_username"]/value)[1]', 'varchar(128)') AS nt_user,
    ev.value('(event/data[@name="object_type"]/text)[1]', 'varchar(40)') AS object_type,
    ev.value('(event/data[@name="object_name"]/value)[1]', 'varchar(256)') AS object_name,
    COALESCE(
        ev.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)'),
        ev.value('(event/data[@name="batch_text"]/value)[1]', 'nvarchar(max)'),
        ev.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)')
    ) AS sql_text
FROM e
WHERE ts_utc BETWEEN @StartUtc AND @EndUtc
ORDER BY ts_utc;
GO
