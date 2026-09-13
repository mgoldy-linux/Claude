/* ============================================================================
   Diagnose "success but no change" -- safety_stock_type import ran in P21,
   reported success, but the trace's before/after diff showed nothing changed.

   Part 1: pull the pricing_service_log report file paths for the most recent
           run(s) -- these are real P21-generated text files on the DEV share
           that describe what the import actually did (processed/skipped/
           error counts). Open them; that's likely the smoking gun.
   Part 2: re-read the already-captured asi_item_import_trace_sst*.xel file
           (still on disk even though the session was stopped/dropped) for
           ANY write attempt touching inv_loc / inv_mast / pricing_service_log,
           filtered down instead of the full unfiltered dump.

   Run in: P21Dev.  READ-ONLY.
   ============================================================================ */
USE P21Dev;
GO

/* ---- Part 1 : most recent pricing_service_log rows ------------------------ */
SELECT TOP (5)
       layout_id, log_id, start_datetime, end_datetime, file_record_count,
       error_report, detail_report, summary_report, error_records, update_report,
       date_last_modified, last_maintained_by
FROM   dbo.pricing_service_log
ORDER  BY date_last_modified DESC;
GO

/* ---- Part 2 : filtered re-read of the sst trace file ---------------------- */
;WITH raw AS (
    SELECT CAST(event_data AS xml) AS ev
    FROM   sys.fn_xe_file_target_read_file(N'L:\SQL\asi_item_import_trace_sst*.xel', NULL, NULL, NULL)
), e AS (
    SELECT  ev,
            ev.value('(event/@name)[1]','varchar(60)')      AS event_name,
            ev.value('(event/@timestamp)[1]','datetime2')   AS ts_utc
    FROM raw
), t AS (
    SELECT ts_utc, event_name,
           ev.value('(event/data[@name="object_type"]/text)[1]','varchar(40)')   AS object_type,
           ev.value('(event/data[@name="object_name"]/value)[1]','varchar(256)') AS object_name,
           COALESCE(
             ev.value('(event/data[@name="statement"]/value)[1]','nvarchar(max)'),
             ev.value('(event/data[@name="batch_text"]/value)[1]','nvarchar(max)'),
             ev.value('(event/action[@name="sql_text"]/value)[1]','nvarchar(max)')
           ) AS sql_text
    FROM e
)
SELECT ts_utc, event_name, object_type, object_name, sql_text
FROM   t
WHERE  sql_text LIKE '%inv_loc%'
   OR  sql_text LIKE '%inv_mast%'
   OR  sql_text LIKE '%pricing_service%'
   OR  sql_text LIKE '%safety_stock_type%'
   OR  object_name IN ('inv_loc','inv_mast','pricing_service_log')
ORDER BY ts_utc;
GO
