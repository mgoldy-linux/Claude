Use P21Play;

select upc_code, item_id, class_id1,supplier_id,m.inv_mast_uid,s.ean_code
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where default_sales_discount_group = 'TRITAN'  and m.delete_flag = 'N'

update s
set upc_code = '', ean_code = ' '
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where default_sales_discount_group = 'TRITAN'  and m.delete_flag = 'N'

select upc_code, item_id, class_id1,supplier_id,m.inv_mast_uid,s.ean_code
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where default_sales_discount_group = 'TRITAN'  and m.delete_flag = 'N'
order by class_id1
