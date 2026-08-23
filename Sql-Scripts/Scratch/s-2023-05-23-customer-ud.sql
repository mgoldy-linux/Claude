update customer_ud 
set legacy_customer_id = 'MICT04'
where customer_id = 115692

select *
from customer_ud
where customer_id = 115692

select total_amount
from invoice_hdr 
where customer_id = 48215 and invoice_date between '2022-05-01' and '2022-05-31'

select distinct class_id1
from inv_mast
order by class_id1

exec sp_help customer_ud