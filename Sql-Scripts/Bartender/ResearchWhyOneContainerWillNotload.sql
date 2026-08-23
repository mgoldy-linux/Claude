SELECT  distinct CHARINDEX(' ',container_name,1)[CHAR], container_name 
FROM p21_view_container_building_report 
where location_id = 100

SELECT  distinct Right(container_name,( Len(container_name)-CHARINDEX(' ',container_name,1)))[container_name],container_name 
FROM p21_view_container_building_report 
where location_id = 100

select *
from p21_view_container_building_report 
where container_name = 'KINETECH KT-20039 AIR'

select *
from  p21_view_container_building_po_report
where container_building_uid = 136