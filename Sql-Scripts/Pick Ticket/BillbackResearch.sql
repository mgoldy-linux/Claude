select i.order_no,item_id, o.carrier_id,order_date,o.freight_out,i.unit_price,p.pick_ticket_no,p.freight_out
from invoice_line i
join oe_hdr o
on i.order_no = o.order_no
join oe_pick_ticket p
on o.order_no = p.order_no
where item_id = 'BILLBACK' and i.last_maintained_by = 'NCLEARY' and o.carrier_id = 16370
order by i.order_no desc


select freight_out, freight_out_edited_flag, freight_charge_estimate, quoted_freight_out
from oe_hdr
where order_no = 1056678
