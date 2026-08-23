--use P21Sand;
--use P21Play;
use P21;

if OBJECT_ID ('Bar_Grainger_Xref_VW', 'V') is not null
drop view Bar_Grainger_Xref_VW;
go

create view [dbo].[Bar_Grainger_Xref_VW] AS


select distinct their_item_id, item_id[select_simg], item_desc
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where m.delete_flag = 'N' and customer_id in (54210,54533)  and x.delete_flag = 'N' --and their_item_id = '35TW68'  --and item_desc = '525 2RS' -- 

go

grant select on object::Bar_Grainger_Xref_VW to p21_application_role
grant select on object::Bar_Grainger_Xref_VW to PxxiUser
grant select on object::Bar_Grainger_Xref_VW to [PTIDOM\P21Users]
