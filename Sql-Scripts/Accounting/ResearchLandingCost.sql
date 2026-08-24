select *
from landed_cost_driver_x_po_hdr

select *
from po_hdr
where vendor_id = 16169

select *
from vessel_receipts_hdr 
where period = 8 and year_for_period = 2022

select *
from container_receipts_hdr 
where container_receipts_hdr_uid = 1782
--where period = 8 and year_for_period = 2022

select *
from container_receipts_line
where container_receipts_hdr_uid = 1782

select *
from inventory_receipts_hdr
where po_number = 4004413