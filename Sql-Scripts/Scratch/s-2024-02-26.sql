select item_id,item_desc,print_quantity
from oe_pick_ticket_detail d
join inv_mast m
on d.inv_mast_uid = m.inv_mast_uid
where pick_ticket_no = 2503574


select p.pick_ticket_no,h.order_no,l.line_no,m.item_id,m.item_desc,
case
	when class_id1 = 'PTI' and default_price_family_uid = 9 then 'GoldSpec'
	when class_id1 = 'PTI' and default_price_family_uid = 11 then 'NSK'
else class_id1
end [LogoBrand],default_product_group,pf.price_family_id,format(qty_ordered,'N0')[Qty2Print]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
where h.location_id = 100 and h.completed = 'N' and projected_order = 'N' and l.delete_flag = 'N' and l.detail_type = 0 and default_product_group not in ('OTHERCHG','D1') and h.rma_flag = 'N' and p.delete_flag = 'N' and p.invoice_no is null 
and l.qty_on_pick_tickets != 0  and p.pick_ticket_no = 2503574

select h.order_no,l.line_no,item_id,item_desc,format(qty_ordered,'N0')[Qty2Print]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
where h.order_No = '1609600' and l.qty_on_pick_tickets != 0 

select *
from Bar_PT_Solve_VW
where pick_ticket_no = 2511466

select item_id,item_desc,short_code,upc_code,check_digit,isu.inv_mast_uid
from inv_mast m
join inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101026091'

