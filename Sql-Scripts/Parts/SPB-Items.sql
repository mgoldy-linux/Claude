use P21;

select distinct item_id[SIMG#],item_desc[Item Description],Extended_desc[updated Item Description],class_id1[Brand],
case
when right(isu.manufacturing_class_id,2) = 'XX' then ''
else right(isu.manufacturing_class_id,2)
end[COO]
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
--left join dbo.inventory_supplier_trade ist
--on isu.inventory_supplier_uid = ist.inventory_supplier_uid
where default_sales_discount_group = 'SPB'

/*
select item_id, item_desc,class_id1,default_sales_discount_group,extended_desc,inv_mast_uid
from inv_mast 
where item_id = '2104005806'

select ist.country_of_origin,isu.*,ist.*
from dbo.inventory_supplier isu
left join dbo.inventory_supplier_trade ist
on isu.inventory_supplier_uid = ist.inventory_supplier_uid 
where inv_mast_uid = 119631

select top 6 *
from inventory_supplier_trade

select *
from inv_mast_ud
where inv_mast_uid = 119631
*/

2104005821