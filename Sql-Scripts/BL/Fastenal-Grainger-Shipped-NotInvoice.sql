select v.order_no, 
case 
	when customer_id = 16425 then 'Fastenal'
	when customer_id = 54210 then 'Grainger'
end [Customer],tracking_no, v.invoice_no
from p21_view_oe_pick_ticket v
join oe_hdr h
on v.order_no = h.order_no 
where v.date_created between '2022-07-18' and Getdate() and customer_id in (16425,54210) and tracking_no not in ('Null', '* * CANCELLED * *')