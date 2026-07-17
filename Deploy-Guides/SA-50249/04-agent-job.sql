/* ============================================================================
   SA-50249  Step 04 — post-restore SQL Agent job (lives in msdb, survives restore)
   Runs the refresh proc after the nightly 2:05 restore + "…Alter SSRS".
   ============================================================================ */
USE msdb;
GO
DECLARE @job NVARCHAR(128) = N'ASI Refresh - Five Way Sales Fact';

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job)
    EXEC dbo.sp_delete_job @job_name = @job;

EXEC dbo.sp_add_job @job_name = @job, @enabled = 1,
     @description = N'SA-50249: rebuild ASI_ReportCache Five Way fact + swap P21 passthrough view (post-restore).';

EXEC dbo.sp_add_jobstep @job_name = @job, @step_name = N'Refresh fact + swap view',
     @subsystem = N'TSQL', @database_name = N'ASI_ReportCache',
     @command = N'EXEC dbo.uspRefreshFiveWaySalesFact;',
     @retry_attempts = 1, @retry_interval = 5;

/* Daily 03:30 — comfortably after the 2:05 restore. CONFIRM the restore reliably
   finishes before this; if not, either move later or (better) chain this as a final
   step of "P21 Daily Restore from Production" so it starts only when the restore ends. */
EXEC dbo.sp_add_schedule @schedule_name = N'ASI FiveWay - daily 0330',
     @freq_type = 4, @freq_interval = 1, @active_start_time = 033000;

EXEC dbo.sp_attach_schedule @job_name = @job, @schedule_name = N'ASI FiveWay - daily 0330';
EXEC dbo.sp_add_jobserver @job_name = @job;   -- (local server)
GO
