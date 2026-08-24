with getInvoicesNo(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where invoice_date > '2018-09-30'
),
getQty_Shipped(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id between 'D-127810' and 'D-127881'
),
combineQry(item_id,qty_shipped,shipped_date)
as
(
	select item_id,Isnull(qty_shipped,0),shipped_date
	from getInvoicesNo gi
	join getQty_Shipped gs
	on gi.invoice_no = gs.invoice_no
)
select item_id,sum(qty_shipped)[Total Shipped]
from combineQry
group by item_id
order by item_id