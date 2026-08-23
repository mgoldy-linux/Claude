select max(len(item_id))[item_id_len],max(len(item_desc))[Len_Desc]
from inv_mast
where class_id1 = 'LMS'

-- IPTCI
Select *
from inv_mast
where len(item_id) = 27 and class_id1 = 'IPTCI' and delete_flag = 'N'

Select *
from inv_mast
where len(item_desc) = 40 and class_id1 = 'IPTCI' and delete_flag = 'N'

-- PTI
Select *
from inv_mast
where len(item_id) = 38

Select *
from inv_mast
where len(item_desc) = 40 and class_id1 = 'PTI' and delete_flag = 'N'

-- LMS
Select *
from inv_mast
where len(item_id) = 39

Select *
from inv_mast
where len(item_desc) = 39 and class_id1 = 'LMS' and delete_flag = 'N'

exec sp_help inv_mast