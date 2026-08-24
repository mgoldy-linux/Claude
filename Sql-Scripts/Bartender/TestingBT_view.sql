select distinct p.pick_ticket_no,m.upc_or_ean_id,
item_id,item_desc,format(qty_ordered,'N0')[Qty2Print],h.order_no,default_product_group,isnull(their_item_id,m.upc_or_ean_id)[their_item_id]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
left join inv_xref x
on h.customer_id = x.customer_id and m.inv_mast_uid = x.inv_mast_uid
--where p.pick_ticket_no = 2141398
where h.location_id = 100 and h.date_created  > DATEADD(DAY,-28,GetDate()) and l.delete_flag = 'N' and l.detail_type = 0 and default_product_group != 'OTHERCHG' and h.rma_flag = 'N' and p.delete_flag = 'N' and p.invoice_no is null
order by pick_ticket_no 

/*
select inv_mast_uid
from oe_line
where order_no = 1171619

select *
from inv_xref
where inv_mast_uid = 48378

select *
from inventory_supplier
where inv_mast_uid = 48377
*/