select *
from bin
where bin_id = 'quar'

-- for Ross - 
select bin_id
from dbo.bin
where location_id = 410 and delete_flag = 'N' and (bin_id like 'UM%' or bin_id like 'LM%')
