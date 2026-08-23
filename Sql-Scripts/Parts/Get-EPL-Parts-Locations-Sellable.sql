use P21Sand;

-- EPL Items for one location 
select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.location_id,l.sellable
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid -- and l.location_id = 410
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where class_id2 = 'EPL' and sellable = 'Y' and discontinued = 'N'  and class_id3 = 'ALL' and primary_supplier = 'Y' and l.location_id = 100
order by item_id,location_id

/*
select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,isxl.location_id,isu.inventory_supplier_uid,isu.supplier_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where item_id in ('2100039247', '2100252510','2105000001')

select location_id,*
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = 128688

select *
from dbo.inv_loc 
where inv_mast_uid = 105566

select *
from inventory_supplier 
where inv_mast_uid = 105566
*/

select item_id, m.inv_mast_uid,l.product_group_id,loc.location_id,l.sellable -- isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,
from dbo.inv_mast m
left join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid 
left join dbo.location loc
on loc.location_id = l.location_id
/*
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where class_id2 = 'EPL' and sellable = 'N' and discontinued = 'N' and isxl.location_id not in (150,200,350)
order by item_id,location_id
*/
where item_id = '2101012051' and l.location_id not in (150,200,350)

with getLoc 
as
(
	select loc.location_id
	from dbo.location loc
	where loc.location_id in (100,300,410,420,430,440,450,460,470)
)	
select case
when l.location_id is null then g.location_id
else g.location_id 
end [location_id],item_id,m.inv_mast_uid
from getLoc g
left join dbo.inv_loc l
on g.location_id = l.location_id 
join dbo.inv_mast m
on  m.inv_mast_uid = l.inv_mast_uid 
where  item_id = '2101012051' 
order by g.location_id 


select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.location_id,l.sellable
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid -- and l.location_id = 410
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where  item_id = '2101012051' 
order by item_id,location_id