select total_amount,order_no,po_no,*
from invoice_hdr 
where invoice_no = '460149401'

select invoice_no, *
from oe_hdr
where customer_id = 48055 and po_no = 'consignment March'     


selecT *
from invoice_line
where invoice_no = '460149401'

select cancel_flag,*
from oe_hdr
where order_no = 1485056

select top 100* 
from audit_trail
where table_changed = 'oe_hdr' and created_by = 'PTIDOM\edivm' --  key1_value = '1485056'
order by date_created desc


select top 100* 
from edi