/*
select class_id5, item_id, item_desc
from dbo.inv_mast 
where class_id1 = 'MD' and delete_flag = 'N'
order by class_id5 desc

Update dbo.inv_mast
set class_id5 = 'SINGLE'
where class_id1 = 'MD' and delete_flag = 'N'

select class_id5, item_id, item_desc
from dbo.inv_mast 
where class_id1 = 'MD' and delete_flag = 'N'
*/

select class_id5, item_id, item_desc
from dbo.inv_mast 
where class_id1 = 'MBL' and delete_flag = 'N'
order by class_id5 desc

Update dbo.inv_mast
set class_id5 = 'SINGLE'
where class_id1 = 'MBL' and delete_flag = 'N'

select class_id5, item_id, item_desc
from dbo.inv_mast 
where class_id1 = 'MBL' and delete_flag = 'N'