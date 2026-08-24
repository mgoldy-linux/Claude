select *
from oe_hdr_ud
where order_no = 1584334


select *
from customer
where customer_name like '%Grainger%' 

select their_item_id, item_id[select_simg], item_desc
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where m.delete_flag = 'N' and customer_id = 12945  and x.delete_flag = 'N'

select*
from inv_xref
where customer_id = 54210
order by customer_id

select distinct their_item_id, item_id[select_simg], item_desc
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where m.delete_flag = 'N' and customer_id in (54210,54533)  and x.delete_flag = 'N'