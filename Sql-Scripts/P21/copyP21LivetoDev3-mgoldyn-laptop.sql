/*
  To Copy Live over P21Dev3 - 06-02-2023, 11-08-2023
*/

use master;

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_prod_to_P21Dev3_20231112.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database p21 To disk = @filename with copy_only, STATS = 10;

Alter database P21Dev3 set OFFLINE with rollback immediate

restore database P21Dev3 From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\P21Dev3_20231112.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\P21Dev3_20231112.ldf'
,  STATS = 10
Alter database P21Dev3 set ONLINE

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

ALTER DATABASE P21Dev3 SET RECOVERY Full

USE P21Dev3
GO
DBCC SHRINKFILE(seed16_log, 1)
Declare @Online as sql_variant;
set @Online = DATABASEPROPERTYEX('master', 'Status') 

if @Online = 'Online'
begin
update alert_implementation set row_status_flag = 705

update company set company_name = left('*** Copied from Live on 20231112 **** ', 40)
update location set location_name = left('*** Ver: 2021.1.4420 ***' + location_name, 255) where location_id = 100
update branch set branch_description = left('*** Up 2023.1 Testing ***', 40) where branch_id = 100

update scheduled_import_master set polling_path = '\\PTI-SQL1\CXM\INBOUND\TEST' where scheduled_import_master_uid = 17

update scheduled_import_master 
set polling_path = replace(polling_path, '\TPCX\', '\TPCXT\')
, transaction_log_path = replace(transaction_log_path, '\TPCX\', '\TPCXT\')
, transaction_sum_path = replace(transaction_sum_path, '\TPCX\', '\TPCXT\')
, transaction_sus_path = replace(transaction_sus_path, '\TPCX\', '\TPCXT\')
, transaction_err_path = replace(transaction_err_path, '\TPCX\', '\TPCXT\')
where polling_path like '%\TPCX\%'

update company set edi_export_path = '\\PTI-EDI\P21Mappertest\P21ExportDirectory' where company_id = 1

update system_setting set value = '\\pti-sql21\P21Shares\APIShare_p21Dev3\Reports_P21Dev3' where system_setting_uid =111
update system_setting set value = '\\pti-sql21\P21Shares\APIShare_p21Dev3\P21Forms_P21Dev3' where system_setting_uid =166
update system_setting set value = '\\pti-sql21\P21Shares\APIShare_p21Dev3\Mslog_P21Dev3' where system_setting_uid =138
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21FFSchemas' where system_setting_uid = 1064
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21ExportDirectory' where system_setting_uid = 1076

-- to prevent extra pick tickets printing
update dbo.scheduled_job set active_flag = 'N'
end
else Print N'P21Dev3 is offline.';
