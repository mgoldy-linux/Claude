-- 09/30/2022 -- Do we have a master file for all Solve Part Numbers showing SIMG# and traditional part number? George

select default_sales_discount_group,item_id[SIMG Item ID],item_desc,u.legacy_item_id,extended_desc
from dbo.inv_mast m
left join dbo.inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid
where m.delete_flag = 'N'


select item_id[SIMG#],item_desc,class_id1[Brand],class_id5[Pack Type],price1
from dbo.inv_mast m
where class_id1 != 'NOTEPL' and delete_flag = 'N'