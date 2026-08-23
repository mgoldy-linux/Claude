select *
from  p21_view_audit_trail_oe_hdr_1319
where key1_value = '1195983'
order by column_changed

select *
from inv_mast
where item_id = '39F206201-BOX[BTO]'

select *
from audit_trail
where key1_value IN ('1195557', '1195983')
order by date_created 

SELECT customer.company_id, customer.customer_id, customer.credit_status, credit_status.credit_status_id, credit_status.credit_status_desc, credit_status.validation_action FROM customer LEFT JOIN credit_status ON credit_status.credit_status_id = customer.credit_status	WHERE customer.company_id = '1' AND customer.customer_id = 13843

SELECT date_last_modified,*
from customer
where customer_id = 13843

select *
FROM p21_view_audit_trail_customer_1307
where key2_value = '13843'

select date_last_modified,*
from invoice_hdr
where customer_id = 13843

select *
from customer_credit_history
where customer_id = 13843

select *
from oe_hdr
where customer_id = 13843
order by order_date desc

select sum(extended_price)
from oe_line 
where order_no = 1195557

select *
from invoice_hdr
where customer_id = 13843

select key1_cd TransType, key1_value OrderNo, column_changed, line_no, old_value, new_value, date_created, created_by, * from audit_trail 
where column_changed = 'extended_price' and key1_cd = 'order_no' 
and key1_value in (select order_no from oe_hdr where customer_id = '13843')
order by audit_trail_uid

select high_credit_used as 'high credit used',
year_invoiced as 'year invoiced',
month_invoiced as 'month invoiced'
from customer_credit_history
where company_id = '1'
and customer_id = '13843'
and year_invoiced ='2021'
order by year_invoiced desc, month_invoiced desc