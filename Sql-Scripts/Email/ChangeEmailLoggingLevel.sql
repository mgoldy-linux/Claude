--https://database.guide/find-out-why-an-email-failed-to-send-in-sql-server-t-sql/

SELECT * FROM msdb.dbo.sysmail_event_log
order by log_date desc

EXEC msdb.dbo.sysmail_help_configure_sp  @parameter_name = LoggingLevel;

EXECUTE msdb.dbo.sysmail_configure_sp  'LoggingLevel', '3';