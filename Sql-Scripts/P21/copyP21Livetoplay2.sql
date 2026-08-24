/*
              How to update play2 database
*/
use master;

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_prod_to_play2_20210514.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database p21 To disk = @filename

restore database Play2 From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\Play2_20210514.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\Play2_20210514.ldf'

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

update company set company_name = left('*** Ralph''s Sandbox 20210514 **** ' + company.company_name + ' *** DB Duo ****', 40)
update location set location_name = left('*** Training Duo 20210514 **** ' + location.location_name + ' *** DB Duo ****', 255)
update branch set branch_description = left('*** Training Duo 20210514 **** ' + branch_description + ' *** DB Duo ****', 40)
