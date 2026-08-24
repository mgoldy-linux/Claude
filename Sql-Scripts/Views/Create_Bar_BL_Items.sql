/*
05/17/23 changes requested by Rance (Verbal) ticket # 972

*/
--use [P21Play2021.1.4420Local];
use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_BL_Items', 'V') is not null
drop view Bar_BL_Items;
go

create view [dbo].[Bar_BL_Items] AS
*/
select item_id,item_desc,qty_on_hand,class_id1[Brand],class_id5
from dbo.inv_mast m
join dbo.inv_loc il
on il.inv_mast_uid = m.inv_mast_uid 
where il.location_id = 410 /*and  qty_on_hand >  and item_id = '2101068648'*/

go
/*
grant select,update,references on object::Bar_BL_Items to p21_application_role
grant select,update,references on object::Bar_BL_Items to PxxiUser
grant select,update,references on object::Bar_BL_Items to [PTIDOM\P21Users]
*/