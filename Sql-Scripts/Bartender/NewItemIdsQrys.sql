use play2;

-- pti
select substring(item_desc,0,charindex(' ',item_desc,0 ))[item_id], item_desc,extended_desc,item_id
from inv_mast
where class_id1 = 'pti' and delete_flag = 'N' and class_id2 = 'EPL'

-- IPTCI
select substring(item_desc,0,charindex(' ',item_desc,0 ))[item_id], item_desc,extended_desc,item_id
from inv_mast
where class_id1 = 'IPTCI' and delete_flag = 'N' and class_id2 = 'EPL'

-- LMS
select substring(item_desc,0,charindex(' ',item_desc,0 ))[item_id], item_desc,extended_desc,item_id
from inv_mast
where class_id1 = 'LMS' and delete_flag = 'N'-- and class_id2 = 'EPL'

--BL
select substring(item_desc,0,charindex(' ',item_desc,0 ))[item_id], item_desc,extended_desc,item_id
from inv_mast
where default_sales_discount_group = 'BL' and delete_flag = 'N'-- and class_id2 = 'EPL'

-- new table for legacy item ids, not sure will be updated
select legacy_item_id,legacy_item_description
from inv_mast_ud

select *
from inv_mast 