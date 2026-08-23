-- 9/29/21 - script to update settings after copy over

Select *
from system_setting
where value like '\\192.168.100.10\%'

UPDATE system_setting SET value = 'C:\P21Crystal\Reports', date_last_modified = Getdate(), last_maintained_by = 'mgoldynSQL' WHERE system_setting_uid = 111 AND value = '\\192.168.100.10\P21Shares\Reports'

UPDATE system_setting SET value = 'C:\P21Crystal\P21Forms', date_last_modified = Getdate(), last_maintained_by = 'mgoldynSQL' WHERE system_setting_uid = 166 AND value = '\\192.168.100.10\P21Shares\P21Forms'

UPDATE system_setting SET value = 'C:\P21Crystal\Msglog', date_last_modified = Getdate(), last_maintained_by = 'mgoldynSQL' WHERE system_setting_uid = 138 AND value = '\\192.168.100.10\P21Shares\Msglog'

UPDATE system_setting SET value = 'C:\P21Crystal\Business-Rules', date_last_modified = Getdate(), last_maintained_by = 'mgoldynSQL' WHERE system_setting_uid = 1274 AND value = '\\pti-sql21\p21Shares\Business Rules'

UPDATE system_setting SET value = '2706', date_last_modified = Getdate(), last_maintained_by = 'mgoldynSQL' WHERE system_setting_uid = 986 AND value = '2705'

select *
from system_setting
where datepart(year,date_last_modified) = datepart(year,getdate()) and datepart(month,date_last_modified) = datepart(month,getdate()) and datepart(day,date_last_modified) = datepart(day,getdate())
order by date_last_modified desc

