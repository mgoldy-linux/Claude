select count(*) [numOf]
from dbo.inv_mast
where len(item_id) < 10 and delete_flag = 'N'

select *
from dbo.inv_mast
where len(item_id) < 10 and delete_flag = 'N'

select count(*) [numOf]
from dbo.inv_mast
where len(item_id) > 10 and delete_flag = 'N'

select *
from dbo.inv_mast
where len(item_id) > 10 and delete_flag = 'N'
