select version_id, version_desc,object,type
from custom_objects
where role_id = 1 and migrated_to_web = 'N'
order by object

select version_id, version_desc,object,type
from custom_objects
where role_id = 1 and migrated_to_web = 'Y'
order by object

select role, version_id, version_desc
from custom_objects co
join roles r
on co.role_id = r.role_uid
where object = 'w_customer_maint_sheet.d_customer_maint_address' and migrated_to_web = 'N'

select *
from custom_objects