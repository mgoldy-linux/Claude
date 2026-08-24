select item_id, item_desc,supplier_sort_code
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where supplier_id = 16013 and item_desc not like 'M-%'

select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id = 16013 and primary_supplier = 'Y' and location_id = 100 and item_desc not like 'M-%'
order by item_desc


select inventory_supplier_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where item_id = '2101001132' and supplier_id = 16013

select inventory_supplier_x_loc_uid,location_id
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = 1133 and location_id = 100
