use P21Play;

select l.line_no, l.order_no, l.qty_ordered, l.qty_allocated,l.source_loc_id,inv_mast_uid,po_no
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where year(order_date) = 2024 and source_code_no = 708

select top 6 pick_ticket_no,opt.order_no, opt.print_date, opt.invoice_no, ih.ship_date
from oe_pick_ticket  opt
join invoice_hdr ih
on cast(opt.invoice_no as varchar) = ih.invoice_no
where ih.invoice_no is not null and year(opt.print_date) = 2024
