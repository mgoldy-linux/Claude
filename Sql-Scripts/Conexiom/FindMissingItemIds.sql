select upc_or_ean_id,ivs.upc_code,short_code,item_id,item_desc,location_id,  line_no,im.class_id2,l.inv_mast_uid,l.customer_part_number
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast im
on l.inv_mast_uid = im.inv_mast_uid
join inventory_supplier ivs
on im.inv_mast_uid = ivs.inv_mast_uid
where po_no = '05-V56432'

