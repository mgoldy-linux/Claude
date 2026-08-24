use P21Sand;
/*
-- not on sales order
select delete_flag, discontinued, location_id, sellable
from inv_loc
where inv_mast_uid = 31726

update dbo.inv_loc
set delete_flag = 'Y', discontinued = 'Y', sellable = 'N'
where inv_mast_uid = 31726 and location_id =100

select delete_flag, discontinued, location_id,sellable
from inv_loc
where inv_mast_uid = 31726
*/
-- On sales order
select delete_flag, discontinued, location_id, sellable
from inv_loc
where inv_mast_uid = 50117 --31726

update dbo.inv_loc
set delete_flag = 'Y', discontinued = 'Y', sellable = 'N'
where inv_mast_uid = 50117 and location_id = 300

select delete_flag, discontinued, location_id,sellable
from inv_loc
where inv_mast_uid = 50117

-- Delete flag inv_mast
select delete_flag
from inv_mast
where inv_mast_uid = 50117

update dbo.inv_mast
set delete_flag = 'Y'
where inv_mast_uid = 50117

select delete_flag
from inv_mast
where inv_mast_uid = 50117