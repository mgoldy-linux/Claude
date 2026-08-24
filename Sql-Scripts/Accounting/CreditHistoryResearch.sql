Select highest_credit_limit_used,*
from customer
where customer_id = 13843

select l.extended_price,l.order_no,l.delete_flag,h.delete_flag,*
from oe_hdr h
JOIN oe_line l 
on h.order_no = l.order_no
where customer_id = 13843 and order_date between '2021-08-31' and getdate()

select *
from p21_view_asst_customer_credit_inquiry
where customer_id = 13843


select total_amount, order_no, order_date
from invoice_hdr
where customer_id = 13843
order by total_amount desc

select *
from oe_line
where order_no = 1195557