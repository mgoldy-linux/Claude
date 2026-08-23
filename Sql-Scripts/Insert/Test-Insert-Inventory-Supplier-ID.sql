select upc_code, ean_code, supplier_id,s.inventory_supplier_uid, m.inv_mast_uid-- ,country_of_origin
from dbo.inventory_supplier s
join dbo. inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
where item_id = '2101069249' 


INSERT INTO "inventory_supplier" ( "supplier_id", "division_id", "delete_flag", "date_created", "date_last_modified", "last_maintained_by", "list_price", "cost", "backhaul_amount", "backhaul_type", "lead_time_days",
 "inv_mast_uid", "inventory_supplier_uid" ) VALUES ( 58991, 58991, 'N', GETDATE(), GETDATE(), 'MGOLDYN', 0, 0, 0, 'R', 0, 69417, 132960 )

select upc_code, ean_code, supplier_id,s.inventory_supplier_uid, m.inv_mast_uid-- ,country_of_origin
from dbo.inventory_supplier s
join dbo. inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
where item_id = '2101069249'


