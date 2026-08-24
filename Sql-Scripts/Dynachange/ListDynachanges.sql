-- choices: Screen, Popup, Menu, Tab for PlayBeforeUpgrade2020.2.4102.xlsx

-- role changes
select role,object_type,uid,version_id,description,object_name
from p21_view_dynachange_version_manager_versions_roles
where object_type = 'Screen' and role = 'EDI Specialist' and object_name like 'w_order_entry%'
order by object_name

-- users changes
select *
from p21_view_dynachange_version_manager_versions_users
where object_name like 'w_order_entry%'

-- Assembly_Maintenance_General (11.29.2022-RS)
select role,object_type,uid,version_id,description,object_name
from p21_view_dynachange_version_manager_versions_roles
where  version_id like 'Assembly_Ma%'
order by version_id

select role,object_type,uid,version_id,description,object_name
from p21_view_dynachange_version_manager_versions_roles
where  version_id = 'Assembly_Maintenance (06.01.2023-RS)'
order by version_id