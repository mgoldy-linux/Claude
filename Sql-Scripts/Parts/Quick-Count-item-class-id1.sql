Use P21;

select COUNT (*)[MainCount]
from inv_mast
where class_id1 in ('TRITAN','PTI','IPTCI','SST','SPB') and delete_flag = 'N'

select COUNT (*)[LesserCount]
from inv_mast
where class_id1 not in ('TRITAN','PTI','IPTCI','SST','SPB') and delete_flag = 'N'

select COUNT (*)[AllCount]
from inv_mast
where delete_flag = 'N'

select *
from inv_mast
where class_id1 is null and delete_flag = 'N'
