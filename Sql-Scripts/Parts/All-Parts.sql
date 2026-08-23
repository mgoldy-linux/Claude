Select distinct default_product_group
from dbo.inv_mast 
where delete_flag = 'N'

go

Select item_id[SIMG],item_desc,class_id1,class_id2,class_id3
from dbo.inv_mast 
where delete_flag = 'N' and default_product_group != 'OTHERCHG'