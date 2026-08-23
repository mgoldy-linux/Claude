-- 12/01/2020 - quick check of conexiom pns

select h.order_no,customer_id,order_date,ship2_name,po_no,im.item_id,customer_part_number,im.item_desc,im.short_code,qty_ordered,qty_per_assembly,im.class_id1,im.class_id2
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast im
on l.inv_mast_uid = im.inv_mast_uid
where po_no = '4502859815'