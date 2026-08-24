select invoice_period, ih.invoice_no, amount_paid, ih.order_no, il.line_no, il.extended_price, ih.invoice_date, gl_revenue_account_no,item_id,note 
from invoice_hdr ih
left join invoice_line il
on il.invoice_no = ih.invoice_no
left join oe_line ol on  il.line_no = ol.line_no and il.order_no = ol.order_no
left join invoice_hdr_notepad ihn
on il.invoice_no = ihn.invoice_no
where invoice_period = '2024009' and ih.order_no is null 

select invoice_period, ih.invoice_no, amount_paid, ih.order_no, il.line_no, il.extended_price, ih.invoice_date, gl_revenue_account_no,item_id,note 
from invoice_hdr ih
left join invoice_line il
on il.invoice_no = ih.invoice_no
left join oe_line ol on  il.line_no = ol.line_no and il.order_no = ol.order_no
left join invoice_hdr_notepad ihn
on il.invoice_no = ihn.invoice_no
where invoice_period = '2024008' and ih.order_no is null 