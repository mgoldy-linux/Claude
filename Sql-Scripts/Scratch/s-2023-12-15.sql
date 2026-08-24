select branch_id, *
from invoice_hdr
where invoice_no = '3245377'

select line_no, inv_mast_uid, *
from invoice_line il
where invoice_no = '3245377'
order by il.line_no

select *
from inv_mast
where inv_mast_uid = 52456

select *
from inv_mast
where delete_flag = 'Y' and last_maintained_by = 'RSNEYD'

select *
from location

select *
from address
where id in (410,420,430,440,450,460,470)

