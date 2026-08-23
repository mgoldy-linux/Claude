exec p21_df_delete_stranded_suppliers

select distinct item_id, m.inv_mast_uid
from inventory_supplier s
join inventory_supplier_x_loc sxl
on s.inventory_supplier_uid = sxl.inventory_supplier_uid 
join inv_mast m
on m.inv_mast_uid = s.inv_mast_uid
where supplier_id = 47614 and primary_supplier = 'Y' and m.class_id1 != 'MD'
 and s.delete_flag = 'N' and m.delete_flag = 'N' and m.class_id2 = 'NOTEPL'

select location_id, item_id, m.inv_mast_uid,s.inventory_supplier_uid,inventory_supplier_x_loc_uid,supplier_id,sxl.row_status_flag
from inventory_supplier s
join inventory_supplier_x_loc sxl
on s.inventory_supplier_uid = sxl.inventory_supplier_uid 
join inv_mast m
on m.inv_mast_uid = s.inv_mast_uid
where primary_supplier = 'Y' and s.delete_flag = 'N' and m.delete_flag = 'N'  and item_id = '2101055625' -- and sxl.last_maintained_by != 'ptidom\dcaparaso'
order by location_id 

select location_id, item_id, m.inv_mast_uid,s.inventory_supplier_uid,inventory_supplier_x_loc_uid,supplier_id,sxl.row_status_flag
from inventory_supplier s
join inventory_supplier_x_loc sxl
on s.inventory_supplier_uid = sxl.inventory_supplier_uid 
join inv_mast m
on m.inv_mast_uid = s.inv_mast_uid
where primary_supplier = 'Y' and s.delete_flag = 'N' and m.delete_flag = 'N'  and item_id = '2101055625' -- and sxl.last_maintained_by != 'ptidom\dcaparaso'
order by location_id 