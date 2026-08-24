select email_address, * from contacts where email_address not like '%@%' and email_address <> ''

select email_address, * from address where email_address not like '%@%' and email_address <> '' 

select ship2_email_address, * from invoice_hdr where ship2_email_address not like '%@%' and ship2_email_address <> ''

select ship2_email_address
from dbo.invoice_hdr
where invoice_no = '3307380'

update dbo.invoice_hdr
set ship2_email_address = NULL
where invoice_no = '3307380'

select ship2_email_address
from dbo.invoice_hdr
where invoice_no = '3307380'

select top 5 *
from inv_mast 