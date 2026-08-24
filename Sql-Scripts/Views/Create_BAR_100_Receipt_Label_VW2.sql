-- 06/23/2022 - modified for new item id, remove qty

use P21Play;
--use P21;

/*
if OBJECT_ID ('BAR_100_Receipt_Label_VW2', 'V') is not null
drop view BAR_100_Receipt_Label_VW2;
go

create view [dbo].[BAR_100_Receipt_Label_VW2] AS
*/

select vessel_receipt_number,t.container_name, l.item_id[item_id210], l.item_desc[item_id],m.short_code,m.extended_desc,date_due,cast(po_container_unit_qty as int)[Qty],mu.legacy_item_description[item_desc]
from p21_view_container_building_report t
join p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
left join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where vrc.row_status_flag not in (700,701,705) and t.location_id = 100 --and vessel_receipt_number = 2600 --and t.container_name like '%23WGSA%'
--order by container_name
--order by len(l.item_id) desc
/*
go 

grant select on object::BAR_100_Receipt_Label_VW2 to p21_application_role
grant select on object::BAR_100_Receipt_Label_VW2 to PxxiUser
grant select on object::BAR_100_Receipt_Label_VW2 to [PTIDOM\P21Users]
*/