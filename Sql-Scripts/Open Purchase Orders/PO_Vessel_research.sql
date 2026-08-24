select item_id,m.item_desc,cost[supplier_cost],pl.unit_price,pl.po_no,pl.line_no, po_line_uid,pl.qty_ordered --,(cost * .90)[new_cost]
from inventory_supplier isu
join inv_mast m
on isu.inv_mast_uid = m.inv_mast_uid
left join po_line pl
on pl.inv_mast_uid = m.inv_mast_uid
where supplier_id = 46865 and complete = 'N' and po_no = 4011348 and cancel_flag = 'N'
order by item_id 

select top  5 *
from  vessel_receipts_hdr
where vessel_receipt_number = 1504

select pl.item_description, qty_ordered,container_qty_received
from  vessel_receipts_line vrl
join po_line pl
on vrl.po_line_uid = pl.po_line_uid
where vessel_receipts_hdr_uid = 1504 and cancel_flag = 'N'
order by item_description