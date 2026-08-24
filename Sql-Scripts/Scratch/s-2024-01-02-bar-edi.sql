select Right(t.container_name,( Len(t.container_name)-CHARINDEX(' ',t.container_name,1)))[container_name], l.item_id[item_id210], l.item_desc[item_id],m.short_code,m.extended_desc,date_due,cast(po_container_unit_qty as int)[Qty],mu.legacy_item_description[item_desc],t.container_name[full_name]
from p21_view_container_building_report t
join p21_view_container_building_po_report l
on t.container_building_uid = l.container_building_uid
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join vessel_receipts_container vrc
on t.container_building_uid = vrc.container_building_uid
join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where vrc.row_status_flag not in (700,701,705) and t.location_id = 100 and t.container_name like '%23WGSA2%'

select *
from p21_view_container_building_report t
where t.container_name like '%- 23WGSA284 (OLD C.2896 - 410)%'
order by date_last_modified desc

select *
from item_list_dtl ild
where item_list_hdr_uid = 2

select *
from inv_mast 
where item_id like '%52549'

select *
from item_list_dtl ild
where inv_mast_uid = 56860

select *
from alert_recipient
where alert_email_address like '%IPTCI%'

select *
from alert_message
where alert_message_uid in (52,53)