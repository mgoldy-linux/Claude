select m.inv_mast_uid,isu.upc_code,check_digit,supplier_id,isu.inv_mast_uid
from dbo.inv_mast  m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101080797' and isu.supplier_id = 47439 and upc_code LIKE '00%' 

select *
from dbo.inventory_supplier
where inv_mast_uid = 81093 and supplier_id = 47439

select *
from inv_mast
where inv_mast_uid = 106304

select item_id,item_desc,s.inventory_supplier_uid,cost,manufacturing_class_id,coalesce(s.upc_code,'')[upc_code],list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid,coalesce(check_digit,0)check_digit
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where  supplier_id = 46788 and item_id = '2101100113'

select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost,
manufacturing_class_id,average_lead_time,coalesce(manual_lead_time,210)[manual_lead_time],s.upc_code,list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id in (46788,182518) and item_id = '2101101267'
order by item_desc