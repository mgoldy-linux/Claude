select their_item_id,s.upc_code,item_desc,item_id,class_id1[Brand]
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where customer_id = 54210