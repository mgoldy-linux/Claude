select customer_name, customer_id
from dbo.customer c
where customer_id in (12945,49889)

-- MSC INDUSTRIAL DIRECT
select their_item_id, item_id, item_desc
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where customer_id = 49889

-- MSC INDUSTRIAL DIRECT CO., INC.
select their_item_id, item_id, item_desc, x.date_created
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where customer_id = 12945


