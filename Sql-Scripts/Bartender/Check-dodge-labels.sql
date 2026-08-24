select distinct item_id,po_no,substring(item_desc,3,6)[Dodge_PN],legacy_item_description,(s.upc_code + convert(varchar(1),s.check_digit))[UPC],Format(net_weight,'N2')[net_weight],ist.country_of_origin
from oe_hdr h
join oe_pick_ticket ph
on h.order_no = ph.order_no
join oe_pick_ticket_detail pl
on ph.pick_ticket_no = pl.pick_ticket_no
join inv_mast m
on m.inv_mast_uid = pl.inv_mast_uid
join inv_mast_ud mu
on mu.inv_mast_uid = m.inv_mast_uid
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join inventory_supplier_trade ist
on ist.inventory_supplier_uid = s.supplier_id
where  ph.delete_flag = 'N' and ph.invoice_no is null and default_product_group = 'D1' and item_id = '2402150838'
order by po_no


select default_product_group 
from inv_mast 
where item_id = '2402150838'

select *
from oe_pick_ticket_detail
where inv_mast_uid = 132841

select delete_flag, invoice_no
from oe_pick_ticket
where pick_ticket_no = 2515845