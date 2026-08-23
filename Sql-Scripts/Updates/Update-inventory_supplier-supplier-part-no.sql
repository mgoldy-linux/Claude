select count (*)
from dbo.inventory_supplier
where supplier_part_no like '%,%'

select *
from dbo.inventory_supplier
where supplier_part_no like '%,%'

select supplier_part_no,date_last_modified,last_maintained_by
from dbo.inventory_supplier
where inv_mast_uid = 17522 and supplier_id = 16013

update dbo.inventory_supplier 
set supplier_part_no = 'GIKSR10X1-25SR', date_last_modified = GetDate(),last_maintained_by = 'mgoldyn-sql'
where inv_mast_uid = 17522 and supplier_id = 16013

select supplier_part_no,date_last_modified,last_maintained_by
from dbo.inventory_supplier
where inv_mast_uid = 17522 and supplier_id = 16013