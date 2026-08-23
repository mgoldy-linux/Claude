select  distinct item_id, item_desc, class_id1,class_id2,class_id3, class_id5, default_purchase_disc_group, '9999'[supplier_id],ist.country_of_origin, schedule_b_number,isu.manufacturing_class_id,unit_of_measure,unit_size[UNIT SIZE],m.default_selling_unit[default_sales_unit],
case
when iu.unit_of_measure = sales_pricing_unit then 'Y'
else 'N'
end[sales_pricing_unit],
case
when iu.unit_of_measure = sales_pricing_unit then 'Y'
else 'N'
end[default_purchasing_unit],
case
when iu.unit_of_measure = sales_pricing_unit then 'Y'
else 'N'
end[purchase_pricing_unit],
case
when iu.unit_of_measure = sales_pricing_unit then 'Y'
else 'N'
end[base_unit_flag],
location_id,il.stockable,il.sellable,il.buy,il.make,m.default_sales_discount_group,price_family_id,il.product_group_id,il.track_bins,il.primary_bin,	il.gl_account_no
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
left join dbo.inventory_supplier_trade ist
on isu.inventory_supplier_uid = ist.inventory_supplier_uid
join dbo.inv_mast_trade mt
on m.inv_mast_uid = mt.inv_mast_uid
join dbo.item_uom iu
on m.inv_mast_uid = iu.inv_mast_uid
join dbo.inv_loc il
on m.inv_mast_uid = il.inv_mast_uid 
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
where default_purchase_disc_group = 'Tritan' and m.delete_flag = 'N' and item_id = '21039286' -- '2101052602' -- = '2101052504'
order by item_id