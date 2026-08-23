/*
05/17/23 changes requested by Rance (Verbal) ticket # 972

*/
--use P21Sand;
use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_MD_Items_VW', 'V') is not null
drop view Bar_MD_Items_VW;
go

create view [dbo].[Bar_MD_Items_VW] AS
*/
select item_id[SIMG],item_desc,
case 
when class_id1 = 'MD' then 'MASTERDRIVE'
else class_id1
end[Brand],class_id5[PackType]
from dbo.inv_mast m
where class_id1 in ('MD','MBL') and delete_flag = 'N'
go
/*
grant select,update,references on object::Bar_MD_Items_VW to p21_application_role
grant select,update,references on object::Bar_MD_Items_VW to PxxiUser
grant select,update,references on object::Bar_MD_Items_VW to [PTIDOM\P21Users]
*/