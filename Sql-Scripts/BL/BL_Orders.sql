/*
		07/19/22 -Give me everything but give me a method to filter them out
		•	Order Number,•	Due Date,•	PO number,•	PO rev,•	Line number,•	Item,•	Description,•	Qty,•	Release Date, bill 2 & ship 2
		from Ralph
*/

select h.order_no,ih.customer_id[bill_to_id],h.address_id[Ship To Id],requested_date,h.po_no,po_no_append,l.line_no,item_id,item_desc,qty_ordered,pick_ticket_no,ols.release_date,l.delete_flag[Line-Delete],l.cancel_flag[Line-cancel],h.completed[Order-Complete],
h.delete_flag[Order-delete],h.cancel_flag[Order-Cancel]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on l.inv_mast_uid = m.inv_mast_uid 
left join oe_line_schedule ols
on ols.order_no = l.order_no
left join invoice_hdr ih
on ih.order_no = h.order_no
left join oe_pick_ticket opt
on h.order_no = opt.order_no
where h.location_id like '4%' and projected_order = 'N'

select bill_to_id,*
from oe_hdr
where order_no = '1281181'

select *
from invoice_hdr 
where order_no = '1281181'