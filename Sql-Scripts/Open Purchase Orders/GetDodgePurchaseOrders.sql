/*
	02/27/2020 - dodge open po report
*/

with getOpenPOs(po_no,item_description,qty_ordered,qty_received,received_date,date_due,inv_mast_uid)
as
(
	select h.po_no,item_description,qty_ordered,qty_received,received_date,l.date_due,inv_mast_uid
	from po_hdr h
	join po_line l 
	on h.po_no = l.po_no
	where l.complete = 'N'
)
select po_no,item_id,item_description,qty_ordered,qty_received,received_date,date_due
from getOpenPOs gop
join inv_mast im
on gop.inv_mast_uid = im.inv_mast_uid
where item_id between 'D-000000' and 'D-99999'
order by item_id