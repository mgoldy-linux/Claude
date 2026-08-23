select l.extended_desc,l.inv_mast_uid,customer_part_number,h.customer_id
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where po_no = 'WI03-00213922'

select upc_code,i.item_id
from inventory_supplier s
join inv_mast i
on s.inv_mast_uid = i.inv_mast_uid
where s.inv_mast_uid = 37282

select *
from p21_view_customer_part_number
where customer_id = 14625