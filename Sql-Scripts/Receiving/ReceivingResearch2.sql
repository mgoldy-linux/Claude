select *
from message_log
order by message_date desc

select *
from container_receipts_hdr
where vessel_receipts_container_uid = 395

select *
from container_receipts_line
where container_receipts_hdr_uid = 1423

select *
from vessel_receipts_hdr
where vessel_receipt_number = 394

select *
from vessel_receipts_line
where vessel_receipts_hdr_uid = 394 and container_building_po_uid =  

select *
from po_line
where po_line_uid = 23602

select *
from po_hdr 
where po_no = 5008459