/*
SA 57002 (Change, approved 2026-10-21) - PROD runbook: cancel quotes more than 90 days past expiration, then nightly job.
Run in SSMS against Prod, database P21, in order. Proc + log table come from
Sql-Scripts/Quotes/SA-56290-Complete-Expired-Quotes.sql (STEP 2) - run that block first; it is CREATE OR ALTER / IF NOT EXISTS, safe to re-run.
Tested on Play 2026-10-12 (cancel + reopen in Order Entry). Reopened quotes need a NEW expiration date or the next run re-cancels them.
*/

-- ============================================================
-- A. Pre-checks (read-only)
-- ============================================================
-- A1. Counts by expiration year at the 90-day cutoff - same filters as the proc (includes delete_flag = 'N')
SELECT YEAR(qh.expiration_date) AS exp_year, COUNT(*) AS quotes
FROM quote_hdr qh JOIN oe_hdr oh ON oh.oe_hdr_uid = qh.oe_hdr_uid
WHERE oh.projected_order = 'Y' AND ISNULL(oh.completed,'N') <> 'Y' AND ISNULL(oh.cancel_flag,'N') <> 'Y'
  AND oh.delete_flag = 'N'
  AND qh.expiration_date < DATEADD(DAY, -90, CAST(GETDATE() AS date))
GROUP BY YEAR(qh.expiration_date) ORDER BY 1;

-- A0. STEP 0 of the SA-56290 script, on PROD (verified on Play only): expect 19 rows = 3 + 2 + 7 + 7. Fewer = a column name differs on Prod, STOP.
SELECT t.name AS tbl, c.name AS col
FROM sys.columns c JOIN sys.tables t ON t.object_id = c.object_id
WHERE (t.name = 'quote_hdr'  AND c.name IN ('oe_hdr_uid','expiration_date','complete_flag'))
   OR (t.name = 'quote_line' AND c.name IN ('oe_line_uid','line_complete_flag'))
   OR (t.name = 'oe_hdr'     AND c.name IN ('oe_hdr_uid','order_no','projected_order','completed','cancel_flag','date_last_modified','last_maintained_by'))
   OR (t.name = 'oe_line'    AND c.name IN ('oe_line_uid','order_no','complete','qty_allocated','disposition','date_last_modified','last_maintained_by'))
ORDER BY t.name, c.name;

-- A1b. Sanity: open quotes with NULL expiration (never touched by this job - just know the number)
SELECT COUNT(*) AS open_quotes_null_expiration
FROM quote_hdr qh JOIN oe_hdr oh ON oh.oe_hdr_uid = qh.oe_hdr_uid
WHERE oh.projected_order = 'Y' AND ISNULL(oh.completed,'N') <> 'Y' AND qh.expiration_date IS NULL;

-- A2. Proc + log table present? (NULL = run STEP 2 of the SA-56290 script first)
SELECT OBJECT_ID('dbo.asi_proc_cancel_expired_quotes') AS proc_id, OBJECT_ID('dbo.asi_expired_quote_cancel_log') AS log_id;
GO

-- ============================================================
-- B. Grant (after the proc exists) - app role / SQL Agent run it
-- ============================================================
-- GRANT EXECUTE ON dbo.asi_proc_cancel_expired_quotes TO p21_application_role;

-- ============================================================
-- C. Preview - changes nothing. Eyeball the list; row count must equal the A1 total.
-- ============================================================
-- EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 1;

-- ============================================================
-- D. One-time catch-up run (Mark runs this). Uncomment only after C looks right.
-- ============================================================
-- EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0;

-- ============================================================
-- E. Verify
-- ============================================================
-- E1. Log rows from the run just done (quotes_cancelled returned by D must equal this count)
-- SELECT COUNT(*) AS logged, SUM(lines_cancelled) AS lines, MIN(run_date) AS first_run, MAX(run_date) AS last_run
-- FROM dbo.asi_expired_quote_cancel_log WHERE run_date >= CAST(GETDATE() AS date);
-- E2. Re-run C: should now return 0 rows.
-- E3. Open one logged quote in Order Entry (shows cancelled), then try the Item Maintenance location delete that was blocked.

-- ============================================================
-- F. Nightly job - IT Tech Svcs creates this ONLY AFTER E passes (Mark has no server admin rights)
--    Ticket says nightly (stage in the nightly processing). Start time = IT's call; pick a slot outside the P21 nightly jobs/backups.
-- ============================================================
-- EXEC msdb.dbo.sp_add_job @job_name = N'ASI - Nightly Cancel Expired Quotes', @description = N'SA 57002: cancel quotes > 90 days past expiration';
-- EXEC msdb.dbo.sp_add_jobstep @job_name = N'ASI - Nightly Cancel Expired Quotes', @step_name = N'Run',
--      @subsystem = N'TSQL', @database_name = N'P21',
--      @command = N'EXEC dbo.asi_proc_cancel_expired_quotes @DaysAfterExpiration = 90, @Preview = 0;';
-- EXEC msdb.dbo.sp_add_jobschedule @job_name = N'ASI - Nightly Cancel Expired Quotes', @name = N'Nightly',
--      @freq_type = 4, @freq_interval = 1, @active_start_time = 33000;   -- daily 03:30 (Prod jobs checked 10/21: 1:00-3:05 busy with
--                                                                        -- audit_trail archive, index/integrity, backups, _asi_Nightly_Procedures 3:05; 4:00 jobs next)
-- Owner: sa (like the other nightly jobs). Optional: @owner_login_name = N'sa' on sp_add_job.
-- EXEC msdb.dbo.sp_add_jobserver @job_name = N'ASI - Nightly Cancel Expired Quotes';

-- ============================================================
-- G. Backout
-- ============================================================
-- Disable the job (do not delete). Cancelled quotes are in dbo.asi_expired_quote_cancel_log (order_no).
-- Single quote: reopen in Order Entry and set a new expiration date.
