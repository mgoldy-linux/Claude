/*
              How to update P21Play database
			  Note stop IIS first
*/

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_prod_to_play.bak'
set @delete_command = 'del ' + @filename

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

backup database p21 To disk = @filename

restore database P21Play From
Disk = @filename
with replace 
, move 'seed16_Data' to 'E:\SQL\Data\P21Play.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\P21Play.ldf'

exec master.dbo.xp_fileexist @filename, @backup_file_exists output
if @backup_file_exists = 1
begin
exec master.dbo.xp_cmdshell @delete_command
end

ALTER DATABASE P21Play SET RECOVERY Full

USE P21Play
GO
DBCC SHRINKFILE(seed16_log, 1)

update alert_implementation set row_status_flag = 705

update company set company_name = left('*** Training Copied 09/16/2020 **** ' + company.company_name + ' *** Training Copied 09/16/2020 ****', 40)
update location set location_name = left('*** Training Copied 09/16/2020 **** ' + location.location_name + ' *** Training Copied 09/16/2020 ****', 255)
update branch set branch_description = left('*** Training Copied 09/16/2020 **** ' + branch_description + ' *** Training Copied 09/16/2020 ****', 40)
