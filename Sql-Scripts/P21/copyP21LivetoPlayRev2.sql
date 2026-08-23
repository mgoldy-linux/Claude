/*
Purpose update P21Play database from P21Live on 09/02/2022, 10/04/2022, 10/11/2022, 10/17/2022, 10/20/2022, 10/27/2022, 11/05/22, 09/10/23, 12/21/23
*/

Use Master;

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_prod_to_play20231221.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database p21 To disk = @filename with copy_only, STATS = 10;

Alter database P21Play set OFFLINE with rollback immediate

restore database P21Play From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\P21Play20231221.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\P21Play20231221.ldf'
,  STATS = 10
Alter database P21Play set ONLINE

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

ALTER DATABASE P21Play SET RECOVERY Full

USE P21Play
GO
DBCC SHRINKFILE(seed16_log, 1)
Declare @Online as sql_variant;
set @Online = DATABASEPROPERTYEX('master', 'Status') 

if @Online = 'Online'
begin
update company set company_name = left('*** P21Play Solve ***', 40)
update alert_implementation set row_status_flag = 705

update location set location_name = left('*** Ayrsely HQ ***' + location_name + ' *** Winter ***', 255) where location_id = 100
update branch set branch_description = left('*** Test DB 20231221 ***', 40)

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
end
else Print N'P21Play is offline.';