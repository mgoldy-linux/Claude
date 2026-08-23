-- last checked 09/23/2020

-- to find a carrier - check if carrier flag = 'Y' 
select name,a.id[code],a.date_created,a.date_last_modified, ua.carrier_group_solve
from address a
join address_ud ua
on a.id = ua.id
where carrier_flag = 'Y'
--order by code desc
order by date_created desc