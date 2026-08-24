-- PO number, PO line, release date and quantity.

select pl.po_no,pl.line_no,item_id,item_desc,pl.qty_ordered,release_no,release_date,pls.release_qty,pls.qty_received
from dbo.po_line_schedule pls
join dbo.po_line pl
on pls.po_line_uid = pl.po_line_uid
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
--where pl.po_line_uid = 96701

select *
from po_line
where po_line_uid = 96701

select 