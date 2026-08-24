/* -- need login as admin
  last update 08/23/21, 10/26/21, 03/12/22, 05/20/22, 12/19/22, 01/20/23, 01/23/23,02/03/23,03/30/23,04/24/23,05/03/23, 06/15/23,07/10/23,07/25/23, 08/01/23,09/08/23,10/12/23,01/12/24
*/

use master;

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_prod_to_play2_20240112.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database p21 To disk = @filename with copy_only, STATS = 10;

Alter database Play2 set OFFLINE with rollback immediate

restore database Play2 From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\Play2_20240112.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\Play2_20240112.ldf'
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
Declare @Online as sql_variant;
set @Online = DATABASEPROPERTYEX('master', 'Status') 

if @Online = 'Online'
begin
update alert_implementation set row_status_flag = 705

update company set company_name = left('*** Copied from Live on 20240112 **** ', 40)
update location set location_name = left('*** Ver: 2023.2.5111 ***' + location_name, 255) where location_id = 100
update branch set branch_description = left('*** Upg Testing ***', 40) where branch_id = 100

update scheduled_import_master set polling_path = '\\PTI-SQL1\CXM\INBOUND\TEST' where scheduled_import_master_uid = 17

update scheduled_import_master 
set polling_path = replace(polling_path, '\TPCX\', '\TPCXT\')
, transaction_log_path = replace(transaction_log_path, '\TPCX\', '\TPCXT\')
, transaction_sum_path = replace(transaction_sum_path, '\TPCX\', '\TPCXT\')
, transaction_sus_path = replace(transaction_sus_path, '\TPCX\', '\TPCXT\')
, transaction_err_path = replace(transaction_err_path, '\TPCX\', '\TPCXT\')
where polling_path like '%\TPCX\%'

update company set edi_export_path = '\\PTI-EDI\P21Mappertest\P21ExportDirectory' where company_id = 1

update system_setting set value = '\\pti-sql21\P21Shares\Reports_Play2' where system_setting_uid =111
update system_setting set value = '\\pti-sql21\P21Shares\P21Forms_Play2' where system_setting_uid =166
update system_setting set value = '\\pti-sql21\P21Shares\Mslog_Play2' where system_setting_uid =138
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21FFSchemas' where system_setting_uid = 1064
update system_setting set value = '\\PTI-EDI\P21MapperTest\P21ExportDirectory' where system_setting_uid = 1076

-- to prevent extra pick tickets printing
update dbo.scheduled_job set active_flag = 'N'
end
else Print N'Play2 is offline.';