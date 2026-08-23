/*
		04/14/2021 - create view for PTI labels - testing in Play
		All bartender views will begin with BAR
*/
--use P21Play;
use P21;
/*
if OBJECT_ID ('Bar_PTI_Labels_VW', 'V') is not null
drop view Bar_PTI_Labels_VW;
go

create view [dbo].[Bar_PTI_Labels_VW] AS
*/

select inv_mast_uid,upc_or_ean_id[UPC],item_id, item_desc,short_code,extended_desc
from inv_mast
where class_id1 = 'PTI'  and inactive = 'N' and delete_flag = 'N'

go 
/*
grant select on object::Bar_PTI_Labels_VW to p21_application_role
grant select on object::Bar_PTI_Labels_VW to PxxiUser
grant select on object::Bar_PTI_Labels_VW to [PTIDOM\P21Users]
*/