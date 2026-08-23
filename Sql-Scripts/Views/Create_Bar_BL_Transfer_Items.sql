/*
05/17/23 changes requested by Rance (Verbal) ticket # 972

*/
--use P21Sand;
use P21Play;
--use P21;

/*
if OBJECT_ID ('Bar_BL_Transfer_Items', 'V') is not null
drop view Bar_BL_Transfer_Items;
go

create view [dbo].[Bar_BL_Transfer_Items] AS
*/
select item_id,item_desc,class_id1[Brand],bin,m.class_id5
from dbo.inv_bin ib
join dbo.inv_mast m
on m.inv_mast_uid = ib.inv_mast_uid
join dbo.inv_loc il
on il.inv_mast_uid = m.inv_mast_uid and il.location_id = ib.location_id 
where ib.location_id = 410 and m.delete_flag = 'N' and il.delete_flag = 'N'/* and bin = 'UM2000704S'  and bin not in  ('NOBIN','NO BIN','NO_PRIMARY') and item_id = '2101082147'*/

/*
go

grant select,update,references on object::Bar_BL_Transfer_Items to p21_application_role
grant select,update,references on object::Bar_BL_Transfer_Items to PxxiUser
grant select,update,references on object::Bar_BL_Transfer_Items to [PTIDOM\P21Users]
*/