--Use P21Play;

select item_id[SIMG],product_group_desc,class_id1,item_desc,extended_desc, m.delete_flag
from dbo.inv_mast m
join dbo.product_group pg
on m.default_product_group = pg.product_group_id
where default_product_group = 'B4'-- and m.delete_flag = 'N'



select item_id[SIMG],product_group_desc, m.delete_flag, il.product_group_id[Loc Prod Grp],il.location_id,class_id1,item_desc,extended_desc
from dbo.inv_mast m
join dbo.product_group pg
on m.default_product_group = pg.product_group_id
join dbo.inv_loc il
on m.inv_mast_uid = il.inv_mast_uid
where default_product_group = 'B4'