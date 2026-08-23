use P21Dev3;

select taker, source_id,*
from oe_hdr
where order_date between '2023-09-15' and GetDate() --and location_id = 601
order by date_created desc


select h.order_no, customer_id, po_no, taker,source_code_no, order_type,inv_mast_uid, customer_part_number, unit_price, qty_ordered,extended_price, line_no
from dbo.oe_hdr h
join dbo.oe_line l
on h.order_no = l.order_no
where h.order_no = 1520356