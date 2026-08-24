use P21;

select item_id, inv_mast_uid,default_sales_discount_group,default_price_family_uid,pf.price_family_id,pf.price_family_desc
from dbo.inv_mast m
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
where class_id2 = 'EPL' and delete_flag = 'N' and default_sales_discount_group not in ('SPB','MD','MBL','SST','LMS','D')-- and item_id = '2308291230'
order by item_id 


select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.location_id,l.sellable
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid -- and l.location_id = 410
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where m.inv_mast_uid = 52624 and isxl.location_id = 100  and primary_supplier = 'Y' and discontinued = 'N'
order by item_id,location_id

select item_id, inv_mast_uid
from dbo.inv_mast
where class_id2 = 'EPL' and delete_flag = 'N' and default_sales_discount_group not in ('SPB','MD','MBL','SST','LMS','D')
order by item_id 


select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.location_id,l.sellable
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid -- and l.location_id = 410
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where m.inv_mast_uid = 12053 and isxl.location_id = 440
order by item_id,location_id

select distinct default_sales_discount_group
from dbo.inv_mast

-- PTI only
use P21;

select item_id, m.inv_mast_uid,default_sales_discount_group,default_price_family_uid,pf.price_family_id,pf.price_family_desc,isu.supplier_id,isxl.primary_supplier, isxl.location_id[from]
from dbo.inv_mast m
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
where class_id2 = 'EPL' and m.delete_flag = 'N' and default_sales_discount_group = 'PTI' and class_id3 = 'ALL'  and isxl.location_id = 100 and primary_supplier = 'Y' -- and item_id = '2101003736'
order by item_id 

-- IPTCI only
select item_id, m.inv_mast_uid,default_sales_discount_group,default_price_family_uid,pf.price_family_id,pf.price_family_desc,isu.supplier_id,isxl.primary_supplier, isxl.location_id[from]
from dbo.inv_mast m
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
where class_id2 = 'EPL' and m.delete_flag = 'N' and default_sales_discount_group = 'IPTCI' and class_id3 = 'ALL'  and isxl.location_id = 300 and primary_supplier = 'Y'
order by item_id 

-- Tritan
select item_id, m.inv_mast_uid,default_sales_discount_group,default_price_family_uid,pf.price_family_id,pf.price_family_desc,isu.supplier_id,isxl.primary_supplier, isxl.location_id[from]
from dbo.inv_mast m
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
where class_id2 = 'EPL' and m.delete_flag = 'N' and default_sales_discount_group = 'TRITAN' and class_id3 = 'ALL' and isxl.location_id = 410 and primary_supplier = 'Y'
order by item_id 


-- Tritan Missing
select item_id, m.inv_mast_uid,default_sales_discount_group,default_price_family_uid,pf.price_family_id,pf.price_family_desc,isu.supplier_id,isxl.primary_supplier, isxl.location_id[from]
from dbo.inv_mast m
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
where class_id2 = 'EPL' and m.delete_flag = 'N' and default_sales_discount_group = 'TRITAN' and class_id3 = 'ALL' and isxl.location_id = 410 and primary_supplier = 'Y' and item_id in ('2305041231','2308291230','2101098164')
order by item_id 

select item_id, m.inv_mast_uid,default_sales_discount_group,default_price_family_uid,pf.price_family_id,pf.price_family_desc,isu.supplier_id,isxl.primary_supplier, isxl.location_id[from]
from dbo.inv_mast m
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
where item_id = '2101098164'
order by item_id 