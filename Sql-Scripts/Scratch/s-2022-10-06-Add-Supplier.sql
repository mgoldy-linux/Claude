select ol.*
from dbo.oe_line ol
join dbo.inv_mast m
on ol.inv_mast_uid = m.inv_mast_uid
where item_id = '2101094935'

select upc_code, ean_code, supplier_id,s.inventory_supplier_uid, m.inv_mast_uid-- ,country_of_origin
from dbo.inventory_supplier s
join dbo. inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
join dbo. inventory_supplier_trade ist
on ist.inventory_supplier_uid = s.inventory_supplier_uid
where item_id = '2101069249' 

select inventory_supplier_uid,*
from dbo.inventory_supplier
where  inv_mast_uid = 61288

select top 5 *--country_of_origin
from dbo. inventory_supplier_trade
where inventory_supplier_uid = 132959

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 573741