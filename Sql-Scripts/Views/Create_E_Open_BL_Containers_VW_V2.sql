-- 09/15/2022 - create container view for BL containers - Ralph/Larry
-- 10/06/2022 - modified to include all containers - ralph
use P21Play;
--use P21;
/*
if OBJECT_ID ('E_Open_BL_Containers_VW', 'V') is not null
drop view E_Open_BL_Containers_VW;
go

create view [dbo].[E_Open_BL_Containers_VW] AS
*/

select t.container_name, l.item_id, l.item_desc,cast(po_container_unit_qty as int)[Qty],base_ut_price,purchasing_weight,length,width,height,mu.pack_type,mu.box_size,mu.bag_size,mu.add_logo,
mu.label_desc_line_1,mu.label_desc_line_2,mu.label_size,mu.label_position,mu.tube_size,mu.tube_qty,mu.carton_size,mu.carton_qty,mu.carton_weight,mu.usa_bag_size,mu.usa_box_size,
mu.pack_notes_1,mu.pack_notes_2,mu.pack_notes_3,mu.pack_notes_4,mu.pack_notes_5
from dbo.p21_view_container_building t
join dbo.p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
left join dbo.vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
join dbo.inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
join dbo.po_line pl
on l.po_no = pl.po_no and l.line_no = pl.line_no
where (vrc.row_status_flag not in (700,701,705) or vrc.row_status_flag is null) and t.location_id like '4%'

go
/*
grant select on object::E_Open_BL_Containers_VW to p21_application_role
grant select on object::E_Open_BL_Containers_VW to PxxiUser
grant select on object::E_Open_BL_Containers_VW to [PTIDOM\P21Users]
*/
