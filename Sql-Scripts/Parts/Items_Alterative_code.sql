-- 09/29/2022 use for Item_Alternative_code.xlsx

select default_sales_discount_group,item_id,item_desc,u.legacy_item_id,alternate_code
from dbo.inv_mast m
left join dbo.inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid
left join dbo.alternate_code ac
on m.inv_mast_uid = ac.inv_mast_uid
where m.delete_flag = 'N'

/*
where m.inv_mast_uid = 62837


select *
from inv_mast
where item_id = '2101062699'
*/
