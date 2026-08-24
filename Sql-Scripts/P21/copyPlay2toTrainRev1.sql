/*
              How to update Training database from Play2. 
			  First update 02/06/2023, 04/24/23 (SPB)
*/

use master;

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_play2_to_P21Train_20230424.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database Play2 To disk = @filename with copy_only, STATS = 10;

Alter database P21Train set OFFLINE with rollback immediate

restore database P21Train From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\P21Train_20230424.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\P21Train_20230424.ldf'
,  STATS = 10
Alter database P21Train set ONLINE

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

ALTER DATABASE P21Train SET RECOVERY Full

USE P21Train
GO
DBCC SHRINKFILE(seed16_log, 1)

update alert_implementation set row_status_flag = 705

update company set company_name = left('** SPB Training 20230424 **', 40)
--update location set location_name = left('*** Training Duo 20230424 **** ' + location.location_name + ' *** DB Duo ****', 255)
--update branch set branch_description = left('*** Training Duo 20230424 **** ' + branch_description + ' *** DB Duo ****', 40)

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

-- prevent printing extra pick tickets
update dbo.scheduled_job set active_flag = 'N'