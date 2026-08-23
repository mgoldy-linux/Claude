exec p21_repair_sales_orders 1605860

SELECT COUNT(COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_CATALOG = 'database' AND TABLE_SCHEMA = 'dbo'
AND TABLE_NAME = 'customer'

select *
from sys.tables
where name = 'customer'

select top 5 *
from customer

select l.qty_allocated, m.inv_mast_uid
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where location_id = 300 and item_id = '2101034318'

exec p21_find_bin_allocations 2101034318


-- PT No, line No
exec p21_get_allocations_info 2530092, 15  

-- give results of allocation issue
exec p21_inventory_issues_allocation 2101034318 , 300

exec p21_rebuild_inv_bin_allocation 2101034318, 300

exec p21_rebuild_inv_bin_allocation 34320, 300