/*
SA 56290 - Scheduled job: CANCEL quotes whose expiration date is over X days old (Sales, Al Ross 10/7: cancel 90 days after expiry).
Test value: 90 days AFTER expiration_date (Sales still deciding the final number).

Tested on PLAY 2026-10-12. Always run on PLAY first, and preview before running.
Approach follows the P21WWUG thread (Topic196767): set oe_hdr/oe_line complete + quote_hdr/quote_line complete flags, PLUS oe_hdr.cancel_flag='Y'.
  Play test 10/12: cancel via flags then reopen in Order Entry worked (flags cleared; a new quote_hdr.expiration_date saved). Reopened quotes MUST get a new expiration date or the next run re-cancels them.
Differences from the forum scripts:
  - keys off quote_hdr.expiration_date, not oe_hdr.requested_date
  - NULL expiration_date is NOT touched (no basis to call it expired)
  - preview mode (@Preview = 1 is the default) returns the rows without changing anything
  - logs what it changed to asi_expired_quote_cancel_log for undo/audit
*/

-- ============================================================
-- STEP 0: verify schema before trusting any of this (names come from the forum + Preview-Quote-Deletion-Candidates.ps1)
-- ============================================================
SELECT t.name AS tbl, c.name AS col
FROM sys.columns c JOIN sys.tables t ON t.object_id = c.object_id
WHERE (t.name = 'quote_hdr'  AND c.name IN ('oe_hdr_uid','expiration_date','complete_flag'))
   OR (t.name = 'quote_line' AND c.name IN ('oe_line_uid','line_complete_flag'))
   OR (t.name = 'oe_hdr'     AND c.name IN ('oe_hdr_uid','order_no','projected_order','completed','cancel_flag','date_last_modified','last_maintained_by'))
   OR (t.name = 'oe_line'    AND c.name IN ('oe_line_uid','order_no','complete','qty_allocated','disposition','date_last_modified','last_maintained_by'))
ORDER BY t.name, c.name;
-- expect 3 + 2 + 7 + 7 = 19 rows

-- ============================================================
-- STEP 1: how many would a 90-day cutoff touch? (read-only, by expiration year)
-- ============================================================
DECLARE @Days int = 90;
SELECT YEAR(qh.expiration_date) AS exp_year, COUNT(*) AS quotes
FROM quote_hdr qh
JOIN oe_hdr oh ON oh.oe_hdr_uid = qh.oe_hdr_uid
WHERE oh.projected_order = 'Y'
  AND ISNULL(oh.completed,'N') <> 'Y'
  AND ISNULL(oh.cancel_flag,'N') <> 'Y'
  AND qh.expiration_date < DATEADD(DAY, -@Days, CAST(GETDATE() AS date))
GROUP BY YEAR(qh.expiration_date) ORDER BY 1;

-- Sanity: open quotes with NULL expiration (never touched by this job)
SELECT COUNT(*) AS open_quotes_null_expiration
FROM quote_hdr qh JOIN oe_hdr oh ON oh.oe_hdr_uid = qh.oe_hdr_uid
WHERE oh.projected_order = 'Y' AND ISNULL(oh.completed,'N') <> 'Y' AND qh.expiration_date IS NULL;
GO

-- ============================================================
-- STEP 2: log table + procedure (CREATE OR ALTER keeps grants)
-- ============================================================
IF OBJECT_ID('dbo.asi_expired_quote_cancel_log') IS NULL
CREATE TABLE dbo.asi_expired_quote_cancel_log (
    log_id          int IDENTITY(1,1) PRIMARY KEY,
    run_date        datetime NOT NULL DEFAULT GETDATE(),
    order_no        varchar(8) NOT NULL,   -- matches oe_hdr.order_no (varchar(8), verified)
    expiration_date datetime NULL,
    days_cutoff     int NOT NULL,
    lines_cancelled int NOT NULL
);
GO

CREATE OR ALTER PROCEDURE dbo.asi_proc_cancel_expired_quotes
    @DaysAfterExpiration int = 90,
    @Preview bit = 1,                   -- 1 = list only, 0 = update
    @OnlyExpiredOn date = NULL          -- optional test limiter: only quotes whose expiration_date is on this ONE day (still must be past the cutoff)
AS
BEGIN
    SET NOCOUNT ON;
    IF @DaysAfterExpiration < 1 THROW 50000, 'DaysAfterExpiration must be >= 1', 1;

    DECLARE @cutoff date = DATEADD(DAY, -@DaysAfterExpiration, CAST(GETDATE() AS date));

    SELECT oh.oe_hdr_uid, oh.order_no, qh.expiration_date
    INTO #q
    FROM quote_hdr qh
    JOIN oe_hdr oh ON oh.oe_hdr_uid = qh.oe_hdr_uid
    WHERE oh.projected_order = 'Y'
      AND ISNULL(oh.completed,'N') <> 'Y'
      AND ISNULL(oh.cancel_flag,'N') <> 'Y'
      AND oh.delete_flag = 'N'
      AND qh.expiration_date < @cutoff
      AND (@OnlyExpiredOn IS NULL OR (qh.expiration_date >= @OnlyExpiredOn AND qh.expiration_date < DATEADD(DAY, 1, @OnlyExpiredOn)));

    IF @Preview = 1
    BEGIN
        SELECT q.*, (SELECT COUNT(*) FROM oe_line ol WHERE ol.order_no = q.order_no) AS line_count
        FROM #q q ORDER BY q.expiration_date;
        RETURN;
    END

    BEGIN TRAN;
        INSERT dbo.asi_expired_quote_cancel_log (order_no, expiration_date, days_cutoff, lines_cancelled)
        SELECT q.order_no, q.expiration_date, @DaysAfterExpiration,
               (SELECT COUNT(*) FROM oe_line ol WHERE ol.order_no = q.order_no AND ISNULL(ol.complete,'N') <> 'Y')
        FROM #q q;

        UPDATE ol SET complete = 'Y', qty_allocated = 0, disposition = '',
                      date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = 'P21_DBA'
        FROM oe_line ol JOIN #q q ON q.order_no = ol.order_no
        WHERE ISNULL(ol.complete,'N') <> 'Y';

        UPDATE ql SET line_complete_flag = 'Y'
        FROM quote_line ql
        JOIN oe_line ol ON ol.oe_line_uid = ql.oe_line_uid
        JOIN #q q ON q.order_no = ol.order_no
        WHERE ISNULL(ql.line_complete_flag,'N') <> 'Y';

        UPDATE qh SET complete_flag = 'Y'
        FROM quote_hdr qh JOIN #q q ON q.oe_hdr_uid = qh.oe_hdr_uid
        WHERE ISNULL(qh.complete_flag,'N') <> 'Y';

        UPDATE oh SET cancel_flag = 'Y', completed = 'Y', date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = 'P21_DBA'
        FROM oe_hdr oh JOIN #q q ON q.oe_hdr_uid = oh.oe_hdr_uid;
    COMMIT;

    SELECT COUNT(*) AS quotes_cancelled FROM #q;
END
GO
-- new objects need EXECUTE for the app role
-- GRANT EXECUTE ON dbo.asi_proc_cancel_expired_quotes TO p21_application_role;

-- ============================================================
-- STEP 3: test on PLAY (preview first, eyeball, then run)
-- ============================================================
-- One-day test (no order numbers): preview, eyeball the list, then run. Day must be older than today-90 or nothing matches.
-- EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 1, @OnlyExpiredOn = '2026-07-13';
-- EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0, @OnlyExpiredOn = '2026-07-13';
-- Full run (all qualifying quotes):
-- EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 1;
-- EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0;
-- Then open one affected quote in Order Entry (should show cancelled, no allocation) and check Item Maintenance delete.

-- ============================================================
-- STEP 4: the Agent job (create only after Play test passes; weekly, Sunday 02:00)
-- ============================================================
-- EXEC msdb.dbo.sp_add_job @job_name = N'ASI - Cancel Expired Quotes';
-- EXEC msdb.dbo.sp_add_jobstep @job_name = N'ASI - Cancel Expired Quotes', @step_name = N'Run',
--      @subsystem = N'TSQL', @database_name = N'P21',
--      @command = N'EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0;';
-- EXEC msdb.dbo.sp_add_jobschedule @job_name = N'ASI - Cancel Expired Quotes', @name = N'Weekly Sun 2am',
--      @freq_type = 8, @freq_interval = 1, @freq_recurrence_factor = 1, @active_start_time = 20000;
-- EXEC msdb.dbo.sp_add_jobserver @job_name = N'ASI - Cancel Expired Quotes';
