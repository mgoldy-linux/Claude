--  vessel_receipts_hdr.vessel_name

Use Play2;
-- the select will change in the future
select vessel_name, vessel_receipts_hdr_uid,departure_date,arrival_date,est_avail_ship_date,*
from dbo.vessel_receipts_hdr
where vessel_name = '425709574'

--  vessel_receipts_container.container_name
select expected_arrival_date,vessel_receipts_container_uid
from dbo.vessel_receipts_container
where vessel_receipts_hdr_uid = 1290

update dbo.vessel_receipts_hdr 
set departure_date = '2023-03-24',arrival_date = '2023-04-07',est_avail_ship_date = '2023-04-20'
where vessel_name = '425709574'

select expected_arrival_date,vessel_receipts_container_uid
from dbo.vessel_receipts_container
where vessel_receipts_hdr_uid = 1290

go

update dbo.vessel_receipts_container 
set expected_arrival_date = '2023-04-20'
where vessel_receipts_container_uid in (1445,1446)

--  vessel_receipts_container.container_name
select expected_arrival_date,vessel_receipts_container_uid
from dbo.vessel_receipts_container
where vessel_receipts_hdr_uid = 1290

/*
-- P21 Live
select *
from vessel_receipts_hdr_ud
where hbl_ud = '429818353PVG'

select vessel_name, vessel_receipts_hdr_uid,departure_date,arrival_date,est_avail_ship_date,*
from dbo.vessel_receipts_hdr
where vessel_receipts_hdr_uid = 1424

--  vessel_receipts_container.container_name
select expected_arrival_date,vessel_receipts_container_uid
from dbo.vessel_receipts_container
where vessel_receipts_hdr_uid = 1424
*/