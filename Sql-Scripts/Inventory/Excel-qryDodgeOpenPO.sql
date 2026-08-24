-- 07/28/2022 - update for new item Id

with getOpenPOs(po_no,item_description,qty_ordered,qty_received,received_date,date_due,inv_mast_uid,po_line_uid,complete)
as
(
	select h.po_no,item_description,qty_ordered,qty_received,received_date,l.date_due,inv_mast_uid,po_line_uid,l.complete
	from po_hdr h
	join po_line l 
	on h.po_no = l.po_no
	where l.complete = 'N'
)
select po_no,item_id,item_description,mu.legacy_item_description,qty_ordered,qty_received,received_date,container_qty_received[On_vessel],date_due
from getOpenPOs gop
join inv_mast m
on gop.inv_mast_uid = m.inv_mast_uid
join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
left join vessel_receipts_line v
on gop.po_line_uid = v.po_line_uid
where item_desc between 'D-000000' and 'D-99999' and qty_received = 0 and gop.complete = 'N'
order by item_id