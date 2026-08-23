-- case CS0002481072 - tested on play forst

select *
from system_setting
where name = 'use_dwo_template'

UPDATE dbo.system_setting SET value = 'N'
FROM dbo.system_setting
WHERE name = 'use_dwo_template'

select *
from system_setting
where name = 'use_dwo_template'