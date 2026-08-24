use P21Sand;

select item_id,iu.unit_size,iu.purchasing_unit,iu.selling_unit,sales_pricing_unit,purchase_pricing_unit,purchase_pricing_unit_size, default_selling_unit,default_purchase_disc_group,default_purchasing_unit
from dbo.inv_mast m
join dbo.item_uom iu
on m.inv_mast_uid = iu.inv_mast_uid
where item_id in ('2101112264', '2101093771')

