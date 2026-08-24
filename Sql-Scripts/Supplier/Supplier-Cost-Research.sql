select distinct item_id[SIMG#],supplier_id,primary_supplier,upc_code,cost[headerCost],loc_cost[location_Cost],m.inv_mast_uid,manual_lead_time
from inv_mast m
join inventory_supplier si
on m.inv_mast_uid = si.inv_mast_uid
join inventory_supplier_x_loc isxl
on si. inventory_supplier_uid = isxl.inventory_supplier_uid
where item_id = '2101052510'

select top 7 *
from inventory_supplier_x_loc
where inventory_supplier_uid = 75334

select inventory_supplier_uid,*
from inventory_supplier
where supplier_id = 47039 and upc_code = '60579012072'