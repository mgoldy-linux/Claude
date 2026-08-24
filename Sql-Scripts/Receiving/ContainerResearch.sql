select po_line_uid, po_no, item_description,inv_mast_uid
from po_line
where (po_no = 4004772 and line_no = 1) or (po_no = 4005295 and line_no = 1)

select container_building_uid, container_name, location_id,*
from p21_view_container_building
where container_name = 'GLH YL-0314/22'

select container_building_uid,po_container_unit_qty, po_line_uid,*
from p21_view_container_building_po
where container_building_uid = 699
--where po_line_uid in (27755,32689) 

select po_no, line_no, item_id, item_desc, inv_mast_uid, container_building_uid, po_line_uid 
from p21_view_container_building_po_report
where (po_no = 4004772 and line_no = 1) or (po_no = 4005295 and line_no = 1)

select t.container_name, l.item_id, l.item_desc,m.short_code,m.extended_desc,date_due,po_container_unit_qty
from p21_view_container_building_report t
join p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
where vrc.row_status_flag not in (700,701,705) and t.location_id = 100 and t.container_name = 'GLH YL-0314/22'
--where container_name = 'GLH YL-0304/22'

select *
from p21_view_container_receipts_hdr
where year_for_period = 2022 and period = 10

select *
from p21_view_vessel_receipts_container
where container_name = 'GLH YL-0314/22'

select container_building_uid
from vessel_receipts_container
where row_status_flag not in (700,701,705) 

select *
from code_p21
where code_no like '70%'

select *
from vessel_receipts_container
where container_name = 'GLH YL-0314/22'

select *
from vessel_receipts_line
where vessel_receipts_hdr_uid = 556

select *
from p21_view_container_building_po
where container_building_uid = 699