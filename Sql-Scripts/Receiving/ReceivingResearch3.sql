select vessel_receipts_container_uid,*
from vessel_receipts_container -- vessel_receipts_container
--where container_name = 'KIRBY 21-2054'
where container_name = 'KIRBY 22-2001'

select *
from container_receipts_hdr
--where vessel_receipts_container_uid = 484
where vessel_receipts_container_uid = 507

Select *
from vessel_receipts_line
WHERE vessel_receipts_hdr_uid =  506
AND vessel_receipts_container_uid= 507
AND row_status_flag = 701

select *
from vessel_receipts_hdr
where vessel_name = 'SABC201707K03412'

select *
from container_receipts_hdr
--where vessel_receipts_container_uid = 484
where vessel_receipts_container_uid = 507


select vessel_receipts_container_uid,*
from vessel_receipts_container -- vessel_receipts_container
--where container_name = 'KIRBY 21-2054'
where container_name = 'KIRBY 22-2001'

select *
from container_receipts_line
where container_receipts_line_uid = 507

Select *
from vessel_receipts_line
WHERE vessel_receipts_hdr_uid =  483
AND vessel_receipts_container_uid= 484
AND row_status_flag = 701