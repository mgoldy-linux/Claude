
select t.container_name, l.item_id, l.item_desc,cast(po_container_unit_qty as int)[Qty]
from dbo.p21_view_container_building_report t
join dbo.p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join dbo.vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
join dbo.inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where vrc.row_status_flag not in (700,701,705) and t.location_id like '4%'

select Container_name
from dbo.p21_view_container_building_report
where location_id like '4%' and container_status != 3100