select *
--from popup_column
--from popup_detail  -- change in this table
--from popup_x_popup  -- change in this table
--from popup_index  -- change in this table
--from popup_field
--from popup_onfly_setup -- not sure what this table tells me
--from popup_statement -- has the modification I made to the sql statement 
--from popup_field_value
--from popup_field_behavior
--from p21_view_dynachange_version_changes_popup -- change in this view
--from  p21_view_popup_detail_second
from p21_view_popup_statement  -- need to add select,from, ... to make statement work
where popup_detail_uid = 4865
--order by date_last_modified desc
--order by uid desc

Select popup_statement_uid_parent,*
from popup_statement
where popup_detail_uid in (4865,4871,4860,4857,4885)

select popup_detail_uid_parent,*
from popup_detail
where created_by = 'RSNEYD' and popup_detail_uid in (4865,4871,4860,4857,4885) -- popup_desc like 'pop-up%'
--where popup_detail_uid = 4830

select *
from popup_field_value
where popup_field_value_uid = 4865


-- who has access to dynachange
select *
from popup_index
where popup_detail_uid = 3903


exec sp_help p21_view_popup_statement


select *
from sys.sql_modules 
where definition like '%p21_view_popup_statement%'

select override_where, override_order_by,*
from p21_view_popup_statement 
where popup_detail_uid = 3903

select override_where, override_order_by,*
from popup_statement 
where from_join like '%inv_mast_ud%' and order_by  = ' '

select *
from popup_detail
where popup_desc like '%-RS)'
--where created_by = 'RSNEYD' and popup_desc = 'Assembly_Maintenance_popup (06.27.2022-RS)'
where popup_detail_uid = 3903
