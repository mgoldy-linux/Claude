-- *** probably need to change  period = 3 and year_for_period = 2022 if I run again ***

select v.po_line_uid,container_qty_received,container_qty_unloaded,p.inv_mast_uid,p.item_description,on_hand_before_trans,quantity,qty_on_hand
from vessel_receipts_line v
join po_line p
on v.po_line_uid = p.po_line_uid
join inv_tran t
on p.inv_mast_uid = t.inv_mast_uid and trans_type = 'RECPT' and period = 3 and year_for_period = 2022
join inv_loc l
on p.inv_mast_uid = l.inv_mast_uid and l.location_id = 100
where vessel_receipts_hdr_uid = 394
