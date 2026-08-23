/*
-- 09/15/2022 - create container view for BL containers - Ralph/Larry
-- 10/06/2022 - modified to include all containers - ralp
-- 10/19/2022 - add upc code
-- 11/07/2022 - remove join dbo.vessel_receipts_container vrc on t.container_building_uid = vrc.container_building_uid /*where (vrc.row_status_flag not in (700,701,705) or vrc.row_status_flag is null) and*/
-- 11/14/2022 - REMOVE duplicates due missing upc code by adding in and l.supplier_id = si.supplier_id
-- 12/07/2022 - add ean column - ralph 01/09/23 -add container building uid,Location_id, remove completed containers - ralph
-- 06/05/2023 - add po_line.po_no, 08/08/23 - add location 100 -ralph
-- 01/22/2024 - add left join for inv_mast_ud
*/
use P21Play;
--use P21;
/*
if OBJECT_ID ('E_Open_BL_Containers_VW', 'V') is not null
drop view E_Open_BL_Containers_VW;
go

create view [dbo].[E_Open_BL_Containers_VW] AS
*/

select distinct t.container_building_uid,t.location_id,t.container_name,pl.po_no ,l.item_id, l.item_desc,cast(po_container_unit_qty as int)[Qty],base_ut_price,purchasing_weight,length,width,height,si.upc_code,si.ean_code, mu.pack_type,mu.box_size,mu.bag_size,mu.add_logo,
mu.label_desc_line_1,mu.label_desc_line_2,mu.label_size,mu.label_position,mu.tube_size,mu.tube_qty,mu.carton_size,mu.carton_qty,mu.carton_weight,mu.usa_bag_size,mu.usa_box_size,
mu.pack_notes_1,mu.pack_notes_2,mu.pack_notes_3,mu.pack_notes_4,mu.pack_notes_5,l.supplier_id
from dbo.p21_view_container_building_report t
join dbo.p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
left join dbo.inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
join dbo.po_line pl
on l.po_no = pl.po_no and l.line_no = pl.line_no
join dbo.inventory_supplier si
on m.inv_mast_uid = si.inv_mast_uid and l.supplier_id = si.supplier_id
where (t.location_id like '4%'  or t.location_id = 100) and complete = 'N'
go

/*
grant select on object::E_Open_BL_Containers_VW to p21_application_role
grant select on object::E_Open_BL_Containers_VW to PxxiUser
grant select on object::E_Open_BL_Containers_VW to [PTIDOM\P21Users]
*/
