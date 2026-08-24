select item_id[SIMG], item_desc, s.supplier_id,su.supplier_name, s.manufacturing_class_id,country_of_origin,location_id
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.supplier su
on s.supplier_id = su.supplier_id
join dbo.inventory_supplier_x_loc l
on s.inventory_supplier_uid = l.inventory_supplier_uid
left join dbo.inventory_supplier_trade st
on s.inventory_supplier_uid = st.inventory_supplier_uid
where location_id = 410 and s.delete_flag = 'N'  and m.delete_flag = 'N' 
order by SIMG

select *
from dbo.inv_mast m
where item_id = '2101004605'

select *
from dbo.inv_loc l
where inv_mast_uid = 4607

select *
from dbo.inventory_supplier
where inv_mast_uid = 4607

select *
from inventory_supplier_x_loc