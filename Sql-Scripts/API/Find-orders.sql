-- use older ship2 to Ids 

Use P21;

Select customer_id,po_no,address_id[Ship2_id],contact_id,l.line_no,l.customer_part_number,inv_mast_uid,h.carrier_id,qty_ordered,unit_price,h.order_no
from dbo.oe_hdr h
join dbo.oe_line l
on h.order_no = l.order_no
where order_date between '2024-02-01' and '2024-02-08' and location_id = 300 and projected_order = 'N' and h.delete_flag = 'N' and h.cancel_flag = 'N' and l.delete_flag = 'N' and l.cancel_flag = 'N'

Select *
from ship_to
where ship_to_id = 191352

select *
from dbo.oe_hdr
where po_no like 'IPTCI%'
order by order_date