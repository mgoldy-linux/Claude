select *
from invoice_line 
where invoice_no = '3134729'

select branch_id, *
from invoice_hdr
where invoice_date between '2022-09-01' and '2022-09-02' and branch_id = 300

select branch_id,*
from invoice_hdr
where invoice_no = '3134729'

select branch_id,*
from invoice_hdr
where invoice_no like '2%' and branch_id = 300