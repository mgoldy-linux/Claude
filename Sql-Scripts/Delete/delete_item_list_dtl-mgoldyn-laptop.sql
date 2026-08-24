/*
select count (*)[NumOfDup]
from dbo.item_list_dtl
where item_list_hdr_uid = 2 and date_created between '2023-05-26 12:07:00.000' and '2023-05-26 12:20:00.000' 

delete
from dbo.item_list_dtl
where item_list_hdr_uid = 2 and date_created between '2023-05-26 12:07:00.000' and '2023-05-26 12:20:00.000' 

select count (*)[NumOfDup]
from dbo.item_list_dtl
where item_list_hdr_uid = 2 and date_created between '2023-05-26 12:07:00.000' and '2023-05-26 12:20:00.000' 
*/

/* not on the counter list
exec p21_set_counter
*/
use P21Sand;

select *
from dbo.item_list_hdr
where item_list_hdr_uid = 2

select count (*)[NumOf]
from dbo.item_list_dtl
where item_list_hdr_uid = 2

delete
from dbo.item_list_dtl
where item_list_hdr_uid = 2  -- All fastenal 

select count (*)[NumOf]
from dbo.item_list_dtl
where item_list_hdr_uid = 2 