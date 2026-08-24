select distinct item_id[Item ID],item_desc[Item Description],default_sales_discount_group[Default Sales Discount Group],default_purchase_disc_group[Default Purchase Discount Group],unit_description[Default Sales Pricing Unit]
,u.unit_size[Sales Pricing Unit Size],m.default_selling_unit,''[Default Purchase Pricing Unit],m.purchase_pricing_unit_size[purchase_pricing_unit_size],m.purchase_pricing_unit[purchase_pricing_unit],s.control_value[Currency],
''[Hazmat Code ID],''[MSDS Flag],''[MSDS Path],''[Revision Date],m.class_id2,m.class_id5,l.location_id,stockable
from dbo.inv_mast m
join dbo.item_uom u
on m.inv_mast_uid = u.inv_mast_uid
INNER JOIN unit_of_measure  um
ON um.unit_id = u.unit_of_measure
join dbo.inventory_supplier su
on su.inv_mast_uid = m.inv_mast_uid
join dbo.supplier s
on s.supplier_id = su.supplier_id
join dbo.inv_loc l
on l.inv_mast_uid = m.inv_mast_uid
where item_id = '2101080850' and l.location_id = 410 --and default_sa
--Unit Info Tab on Item Maintenance: 2101080850 (ER15)*
SELECT
   item_uom.unit_of_measure,
   item_uom.delete_flag,
   item_uom.date_created,
   item_uom.date_last_modified,
   item_uom.last_maintained_by,
   item_uom.unit_size,
   ' ' dummy1,
   ' ' dummy2,
   unit_of_measure.unit_description,
   'N' purchase_pricing_unit,
   'N' sales_pricing_unit,
   inv_mast.item_id,
   'N' default_sales_unit,
   'N' default_purchasing_unit,
   item_uom.inv_mast_uid,
   'Y',
   item_uom.item_uom_uid,
   'N' base_unit_flag,
   'N' base_unit_is_item_uom,
   item_uom.b2b_unit_flag
FROM
   item_uom
   INNER JOIN unit_of_measure ON (
      unit_of_measure.unit_id = item_uom.unit_of_measure
   )
   INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = item_uom.inv_mast_uid)
WHERE
   (inv_mast.item_id = '2101080850')


   select revis
   from inv_mast m
   join inventory_supplier su
   on su.inv_mast_uid = m.inv_mast_uid
   where item_id = '2101102215'

   select *
   from inventory_supplier su
   join supplier s
   on s.supplier_id = su.supplier_id
   where inv_mast_uid = 102324

   select *
   from supplier
   where supplier_id = 47614

   select *
   from inv_mast_msds