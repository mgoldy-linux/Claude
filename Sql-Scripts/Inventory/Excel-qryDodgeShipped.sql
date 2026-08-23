with getinvoicesno(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where invoice_date > dateadd(day,-365,getdate())
),
getqty_shipped(inv_mast_uid,qty_shipped,invoice_no)
as
(
	select il.inv_mast_uid,floor(isnull(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast m
	on il.inv_mast_uid = m.inv_mast_uid
	where m.default_product_group = 'd1'
),
combineqry(inv_mast_uid,qty_shipped,shipped_date)
as
(
	select inv_mast_uid,isnull(qty_shipped,0),shipped_date
	from getinvoicesno gi
	join getqty_shipped gs
	on gi.invoice_no = gs.invoice_no
)
select mu.legacy_item_id,cq.qty_shipped,cq.shipped_date
from combineqry cq
join inv_mast_ud mu
on cq.inv_mast_uid = mu.inv_mast_uid