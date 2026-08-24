/* looks like P21 stuff, not change made by PTI
select *
from dynachange
order by date_created desc

--looks like P21 stuff, not change made by PTI
select *
from dynachange_config
order by date_created desc


select *
from dynachange_menu
order by date_created desc
*/

-- good source of change
select *
from p21_view_dynachange_custom_objects 
--where version_id = 'qty_allocated_inside_sales_inside sales-pricing maint'
order by date_last_modified desc

select *
from custom_objects
--where version_id = 'EDI_Specialist_Phy_add_3_on_Ship2_Tab_edi specialist'
order by date_last_modified desc

select *
from custom_objects_detail
where custom_objects_uid = 288
order by date_created desc

select role,object_type,uid,version_id,description,object_name
from p21_view_dynachange_version_manager_versions_roles
where object_type = 'tab'
order by object_name

-- Searching for certain changes 
select distinct role_id, version_id, version_desc
from p21_view_dynachange_custom_objects 
where version_desc like 'Moved%' 
--order by date_created desc

select *
from roles
where role_uid = 1

select role_id, type, object_type, apply_to_all
from custom_objects
where version_desc like 'Fixed%'

select *
from p21_view_popup_index
order by date_created desc

select *
from p21_view_popup_detail
where popup_detail_uid = 9406

select *
from p21_view_dynachange_custom_objects 