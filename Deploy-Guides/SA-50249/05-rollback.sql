/* ============================================================================
   SA-50249  ROLLBACK — instant, no report/.rdl changes
   ============================================================================ */

-- 1) Stop the automation so it never re-swaps the view again.
EXEC msdb.dbo.sp_update_job @job_name = N'ASI Refresh - Five Way Sales Fact', @enabled = 0;
GO

-- 2) Restore the ORIGINAL P21 report view immediately (for mid-day rollback).
--    If you can wait, the next 2:05 restore also brings back the original on its own,
--    and with the job disabled it simply stays original.
--    Apply the preserved original definition (SQLCMD mode):
--        :r original-asi_3yr-view.sql
--    (recreates P21.dbo.asi_3yr_sales_history_report_view as the original compute view)

-- 3) Optional cleanup (only once you're sure you won't re-enable):
--    DROP DATABASE ASI_ReportCache;   -- rebuildable; safe to drop
GO

/* Reports flip back the instant step 2 runs — they always reference the view name,
   which is now the original compute logic again. Blast radius on rollback = the same
   5 asi_3yr reports; My Five Way / Branch Five Way are unaffected throughout. */
