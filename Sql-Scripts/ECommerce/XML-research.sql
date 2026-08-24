select *
from invoice_hdr ih
join customer c
on ih.customer_id = c.customer_id
where ih.date_created > '2023-08-01' and web_enabled_flag = 'Y'

select *
from xml_document
where document_template like '%pdf%'

select *
from customer
where web_enabled_flag = 'Y'

select shipping_address,*
from address
where id = 126881

select *
from ship_to
where ship_to_id = 126881

select *
from po_hdr
where po_no like '%1049'