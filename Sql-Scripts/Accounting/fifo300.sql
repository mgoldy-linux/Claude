-- need to elimante extra rows create dby supplier id
Use p21;

select m.item_id, item_desc,s.supplier_id, f.*, irl.*
from fifo_layers f
join inventory_receipts_line irl
on f.document_no = irl.receipt_number and f.inv_mast_uid = irl.inv_mast_uid
join inv_mast m
on m.inv_mast_uid = f.inv_mast_uid
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where location_id = 300 and fifo_layer_qty > 0

