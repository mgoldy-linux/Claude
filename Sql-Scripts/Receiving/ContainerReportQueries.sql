select supplier_id,supplier_name,po_no,item_id, item_desc,inv_mast_uid,po_container_unit_qty,vessel_receipt_number,container_name
from p21_view_container_building_po_report cb
join p21_view_container_building_report r
on cb.container_building_uid = r.container_building_uid
join 
where cb.container_building_uid = 710

select *
from p21_view_container_building_report
--where container_name = 'FHBL22020030 - CP22-05D'
where container_building_uid = 710

select *
from p21_view_vessel_receipts_container
where vessel_receipts_container_uid = 565

select * 
from p21_view_vessel_report