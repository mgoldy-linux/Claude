select transfer_shipment_no, transfer_no,sku_qty_shipped,sku_qty_received,from_location_id,to_location_id,pl.po_no,pl.line_no
from p21_transfer_shipment_view v
join dbo.po_line pl
on v.inv_mast_uid = pl.inv_mast_uid
where transfer_no = 8002220 and item_id = '2100038820' and v.delete_flag = 'N' and v.qty_received = 100

select *
from transfer_hdr
where transfer_no = 8002220

select *
from p21_view_transfer_shipment_hdr
where transfer_shipment_hdr_uid = 1104

select *
from po_line
where inv_mast_uid = 105143

select distinct transfer_shipment_no, transfer_no,sku_qty_shipped,sku_qty_received,from_location_id,to_location_id,pl.po_no,pl.line_no,ph.po_type
from p21_transfer_shipment_view v
join dbo.po_line pl
on v.inv_mast_uid = pl.inv_mast_uid
join dbo.po_hdr ph
on pl.po_no = ph.po_no
where item_id = '2101027532' and v.delete_flag = 'N' and v.qty_received = 57