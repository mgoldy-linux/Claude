select upc_code, im.inv_mast_uid,im.item_id,im.item_desc
from inventory_supplier ins
join inv_mast im
on ins.inv_mast_uid = im.inv_mast_uid
where upc_code = '80067515569'


select order_no, order_date, po_no,customer_id
from oe_hdr
order by order_no desc