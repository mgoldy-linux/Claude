Declare @last_boot datetime
Set @last_boot = (select [sqlserver_start_time] from sys.dm_os_sys_info)
 

select @@servername as [ServerName],'last_boot' = @last_boot, 'days_since_last_boot' = datediff(d, @last_boot, getdate())
 
if object_id('tempdb..##Table_usage_data') is not null
drop table ##Table_usage_data
create table ##Table_usage_data (ID int identity (1,1), [database] varchar(255),[last_user_seek] datetime,[last_user_scan] datetime,  [last_update] datetime)
 
declare @get_last_user_activity_timestamp varchar(max)
set @get_last_user_activity_timestamp = ''
select @get_last_user_activity_timestamp = @get_last_user_activity_timestamp +
'select db_name([database_id]), max(last_user_seek), max(last_user_scan), max([last_user_update]) from sys.dm_db_index_usage_stats where db_name([database_id]) = ''' + [name] + ''' group by [database_id];' + char(10)
from sys.databases where [database_id] > 4 and [state_desc] = 'online'
 
insert into ##Table_usage_data ([database],[last_user_seek],[last_user_scan],[last_update])
exec (@get_last_user_activity_timestamp)
 

select
[database], last_user_scan,last_user_seek,last_update
from
##Table_usage_data