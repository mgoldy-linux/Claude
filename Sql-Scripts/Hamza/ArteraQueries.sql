--387

select item_id, item_desc, default_purchase_disc_group, supplier_name, cost, location_id
from dbo.inv_mast
inner join inventory_supplier on inventory_supplier.inv_mast_uid = inv_mast.inv_mast_uid
inner join supplier on supplier.supplier_id = inventory_supplier.supplier_id
inner join inventory_supplier_x_loc on inventory_supplier_x_loc.inventory_supplier_uid = inventory_supplier.inventory_supplier_uid
where inv_mast.delete_flag = 'N' and default_purchase_disc_group = 'TRITAN' and location_id = '410' and primary_supplier = 'Y';


--418
Select item_id, item_desc, class_id5, qty_on_hand, cost
from inv_mast
Inner Join Inv_loc on inv_loc.inv_mast_uid = inv_mast.inv_mast_uid
inner join inventory_supplier on inventory_supplier.inv_mast_uid = inv_mast.inv_mast_uid
where class_id5 = 'PL1 Packed' and inv_mast.delete_flag = 'N'
order by item_id