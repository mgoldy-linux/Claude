Select item_id, item_desc,sum(qty_on_hand) as total_quantity,moving_average_cost, class_id5,m.inv_mast_uid
from inv_mast m
inner Join Inv_loc il
on il.inv_mast_uid = m.inv_mast_uid 
--inner join inventory_supplier
--on inventory_supplier.inv_mast_uid = m.inv_mast_uid
where class_id5 = 'PL1 Packed' and m.delete_flag = 'N' and moving_average_cost != 0
group by item_id, item_desc,moving_average_cost, class_id5,m.inv_mast_uid
order by item_id


select moving_average_cost,qty_on_hand,*
from dbo.inv_loc il
where inv_mast_uid = 53912