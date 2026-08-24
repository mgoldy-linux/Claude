/*
              How to update P21play database from live. Ensure Web is turned off
			  last update 08/23/2021, 10/26/2021
*/

Use Master;

declare @filename varchar(200)
declare @backup_file_exists int
declare @delete_command varchar(1000)

set @filename = 'E:\SQL\Backup\p21_prod_to_play20220121.bak'
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
, move 'seed16_Data' to 'E:\SQL\Data\P21Play20220121.mdf'
, move 'seed16_Log' to 'E:\SQL\Data\P21Play20220121.ldf'

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

update company set company_name = left('*** P21Play Copied 01/21/22 ***', 40)
update location set location_name = left('*** Ver: 2021.1.4420 ***', 255)
update branch set branch_description = left('***  Testing Purposes Only ***', 40)
