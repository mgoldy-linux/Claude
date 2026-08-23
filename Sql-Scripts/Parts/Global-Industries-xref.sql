use P21Sand;

select their_item_id,item_id[SIMG],item_desc,extended_desc ,customer_id,x.inv_mast_uid,x.inv_xref_uid,x.date_created,x.created_by
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where  customer_id = 53736 