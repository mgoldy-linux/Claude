-- need to elimante extra rows create dby supplier id
Use P21;

select m.item_id, item_desc,f.*, irl.*
from dbo.fifo_layers f
join dbo.inventory_receipts_line irl
on f.document_no = irl.receipt_number and f.inv_mast_uid = irl.inv_mast_uid
join dbo.inv_mast m
on m.inv_mast_uid = f.inv_mast_uid
where location_id like '4%' and fifo_layer_qty > 0