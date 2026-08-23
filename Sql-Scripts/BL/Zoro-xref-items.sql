use P21Sand;

select their_item_id, item_id, item_desc, x.customer_id
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
join customer c
on c.customer_id = x.customer_id
where customer_name like '%Zoro%'

-- need to change where clause the second digit is number
/*
select their_item_id, item_id, item_desc, x.customer_id
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
join customer c
on c.customer_id = x.customer_id
where their_item_id like 'G%' and x.customer_id != '55932'
*/