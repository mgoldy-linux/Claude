select m.item_id, v.item_desc
from inv_mast m
join Bar_Item_ID_PTI_Labels_VW v
on m.default_product_group = v.default_product_group
where m.default_product_group = 'N1'  and m.item_desc like 'SUC%'


select default_product_group,*
from inv_mast
where item_desc like  'SUCSF208-24%'