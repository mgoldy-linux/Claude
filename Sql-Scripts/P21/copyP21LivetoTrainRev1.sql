/*
    Purpose update Training database from P21Live on 2023-08-02,2023-11-27
*/

use master;

Declare @filename varchar(200)
Declare @backup_file_exists int
Declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_prod_to_P21Train_20231127.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database P21 To disk = @filename with copy_only, STATS = 10;

Alter database P21Train set OFFLINE with rollback immediate

restore database P21Train From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\P21Train_20231127.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\P21Train_20231127.ldf'
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
Declare @Online as sql_variant;
set @Online = DATABASEPROPERTYEX('master', 'Status') 

if @Online = 'Online'
begin
update company set company_name = left('** MD Training 20231127 **', 40)
update alert_implementation set row_status_flag = 705

update company set company_name = left('** MD Training 20231127 **', 40)
update location set location_name = left('*** MD 20231127 **** ' + location.location_name + ' *** Pratice ***', 255) where location_id = 100
update branch set branch_description = left('*** MD  20231127 **** ' + branch_description + ' ***  WI ***', 40)

update scheduled_import_master set polling_path = '\\PTI-SQL1\CXM\INBOUND\TEST' where scheduled_import_master_uid = 17

update scheduled_import_master 
set polling_path = replace(polling_path, '\TPCX\', '\TPCXT\')
, transaction_log_path = replace(transaction_log_path, '\TPCX\', '\TPCXT\')
, transaction_sum_path = replace(transaction_sum_path, '\TPCX\', '\TPCXT\')
, transaction_sus_path = replace(transaction_sus_path, '\TPCX\', '\TPCXT\')
, transaction_err_path = replace(transaction_err_path, '\TPCX\', '\TPCXT\')
where polling_path like '%\TPCX\%'

update company set edi_export_path = '\\PTI-EDI\P21Mappertest\P21ExportDirectory' where company_id = 1

update system_setting set value = '\\pti-sql21\P21Shares\APIShare_Train\Reports_Train' where system_setting_uid =111
update system_setting set value = '\\pti-sql21\P21Shares\APIShare_Train\P21Forms_Train' where system_setting_uid =166
update system_setting set value = '\\pti-sql21\P21Shares\APIShare_Train\MSGLog_Train' where system_setting_uid =138
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21FFSchemas' where system_setting_uid = 1064
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21ExportDirectory' where system_setting_uid = 1076

-- prevent printing extra pick tickets
update dbo.scheduled_job set active_flag = 'N'
end
else Print N'P21Train is offline.';