--use P21Play;

select count(location_id)[numOfBefore]
from dbo.inv_loc il
join dbo.inv_mast m
on il.inv_mast_uid = m.inv_mast_uid
where il.price1 > 0 and m.delete_flag = 'N'

update dbo.inv_loc 
set price1 = 0
from dbo.inv_loc il
join dbo.inv_mast m
on il.inv_mast_uid = m.inv_mast_uid
where il.price1 > 0 and m.delete_flag = 'N'

select count(location_id)[numOfAfter]
from dbo.inv_loc il
join dbo.inv_mast m
on il.inv_mast_uid = m.inv_mast_uid
where il.price1 > 0 and m.delete_flag = 'N'
