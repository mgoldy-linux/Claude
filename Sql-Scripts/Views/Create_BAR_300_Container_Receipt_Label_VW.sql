-- 10/27/2022 - modified for IPTCI 

use P21Play;
--use P21;

/*
if OBJECT_ID ('BAR_300_Container_Receipt_Label_VW', 'V') is not null
drop view BAR_300_Container_Receipt_Label_VW;
go

create view [dbo].[BAR_300_Container_Receipt_Label_VW] AS
*/

select Right(t.container_name,( Len(t.container_name)-CHARINDEX(' ',t.container_name,1)))[container_name], l.item_id[item_id210], l.item_desc[item_id],
m.short_code,m.extended_desc,format(date_due,'yyyy-MM-dd')[date_due],cast(po_container_unit_qty as int)[Qty],mu.legacy_item_description[item_desc]
from dbo.p21_view_container_building_report t
join dbo.p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join dbo.vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
left join dbo.inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where vrc.row_status_flag not in (700,701,705) and t.location_id = 300 --and l.item_id = '2106000035'

/*
go 

grant select on object::BAR_300_Container_Receipt_Label_VW to p21_application_role
grant select on object::BAR_300_Container_Receipt_Label_VW to PxxiUser
grant select on object::BAR_300_Container_Receipt_Label_VW to [PTIDOM\P21Users]
*/