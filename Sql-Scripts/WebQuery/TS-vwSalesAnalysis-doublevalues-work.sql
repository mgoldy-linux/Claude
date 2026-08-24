use P21;

Select COUNT(*)[of lines]
from P21.dbo.p21_view_invoice_line AS invoice_line 
LEFT OUTER JOIN P21.dbo.oe_pick_ticket AS oe_pick_ticket 
ON oe_pick_ticket.invoice_id_when_shipped = invoice_line.invoice_no
LEFT OUTER JOIN P21.dbo.invoice_hdr AS invoice_hdr 
ON invoice_hdr.invoice_no = invoice_line.invoice_no 
LEFT OUTER JOIN P21.dbo.invoice_hdr_salesrep AS invoice_hdr_salesrep 
ON invoice_hdr_salesrep.invoice_number = invoice_hdr.invoice_no AND invoice_hdr_salesrep.primary_salesrep = 'y'
LEFT OUTER JOIN P21.dbo.ship_to_salesrep AS ship_to_salesrep 
ON ship_to_salesrep.ship_to_id = invoice_hdr.ship_to_id AND ship_to_salesrep.company_id = invoice_hdr.company_no AND ship_to_salesrep.primary_salesrep = 'y' AND ship_to_salesrep.delete_flag = 'n' 
LEFT OUTER JOIN P21.dbo.customer AS customer 
ON invoice_hdr.customer_id = customer.customer_id AND invoice_hdr.company_no = customer.company_id
LEFT OUTER JOIN P21.dbo.territory_x_customer AS txc 
ON customer.customer_id = txc.customer_id and txc.row_status_flag = 704
LEFT OUTER JOIN P21.dbo.territory AS t ON txc.territory_uid = t.territory_uid
where invoice_line.invoice_no = '3474591'

select *
from territory_x_customer
where customer_id = 61124