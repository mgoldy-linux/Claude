/*
              How to update Play2 database from live. Ensure Web is turned off
			  last update 08/23/2021, 10/26/2021, 03/12/2022, 05/20/2022
			  , 
			  6/12/2022 - Added set db offline during restore to avoid having to turn off middleware.
			  added copy only parameter to back up so that you don't break your existing chain of full, diff, and log backups
			  added stats parameter to backup and restore to view progress while running

			  Added additional folder path / settings changes for automation

			  ***** After Copy Turn Off Scheduler ****
*/

use master;

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_play_to_play2_20221005.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database P21Play To disk = @filename with copy_only, STATS = 10;

Alter database Play2 set OFFLINE with rollback immediate

restore database Play2 From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\Play2_20221005.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\Play2_20221005.ldf'
,  STATS = 10
Alter database Play2 set ONLINE

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

ALTER DATABASE Play2 SET RECOVERY Full

USE Play2
GO
DBCC SHRINKFILE(seed16_log, 1)

update alert_implementation set row_status_flag = 705

update company set company_name = left('*** Play to Play2 20221005 **** ' + company.company_name + ' *** TEST ONLY ****', 40)
--update location set location_name = left('*** Training Duo 20221005 **** ' + location.location_name + ' *** DB Duo ****', 255)
--update branch set branch_description = left('*** Training Duo 20221005 **** ' + branch_description + ' *** DB Duo ****', 40)
/*
update scheduled_import_master set polling_path = '\\PTI-SQL1\CXM\INBOUND\TEST' where scheduled_import_master_uid = 17

update scheduled_import_master 
set polling_path = replace(polling_path, '\TPCX\', '\TPCXT\')
, transaction_log_path = replace(transaction_log_path, '\TPCX\', '\TPCXT\')
, transaction_sum_path = replace(transaction_sum_path, '\TPCX\', '\TPCXT\')
, transaction_sus_path = replace(transaction_sus_path, '\TPCX\', '\TPCXT\')
, transaction_err_path = replace(transaction_err_path, '\TPCX\', '\TPCXT\')
where polling_path like '%\TPCX\%'

update company set edi_export_path = '\\PTI-EDI\P21Mappertest\P21ExportDirectory' where company_id = 1

update system_setting set value = '\\pti-sql21\P21Shares\Reports_Play' where system_setting_uid =111
update system_setting set value = '\\pti-sql21\P21Shares\P21Forms_Play' where system_setting_uid =166
update system_setting set value = '\\pti-sql21\P21Shares\Mslog_Play' where system_setting_uid =138
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21FFSchemas' where system_setting_uid = 1064
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21ExportDirectory' where system_setting_uid = 1076
*/
-- prevent printing extra pick tickets
update dbo.scheduled_job set active_flag = 'N'