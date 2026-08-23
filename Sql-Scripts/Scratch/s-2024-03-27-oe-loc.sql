select l.line_no,item_id,item_desc,il.location_id, il.sellable,m.class_id2,l.source_loc_id
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join inv_loc il
on il.inv_mast_uid = m.inv_mast_uid --and il.location_id = l.source_loc_id
where h.order_no = 1646178 and l.delete_flag = 'N' and il.location_id = 410