select item_desc, extended_desc , x.their_item_id,x.date_last_modified, x.last_maintained_by
from inv_mast m
join inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where item_id = '2101073950' and customer_id = 16425