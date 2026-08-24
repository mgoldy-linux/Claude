/*
49889	MSC INDUSTRIAL DIRECT
12945	MSC INDUSTRIAL DIRECT CO., INC.
49898	MSC INDUSTRIAL SUPPLY
123160	MSC-CCSG DIVISION OF MSC
*/

--use P21Sand;
--use P21Play;
use P21;

if OBJECT_ID ('Bar_MSC_Xref_VW', 'V') is not null
drop view Bar_MSC_Xref_VW;
go

create view [dbo].[Bar_MSC_Xref_VW] AS


select their_item_id, item_id[select_simg], item_desc
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where m.delete_flag = 'N' and customer_id in (12945,49889,49898,123160)  and x.delete_flag = 'N' --and item_id = '2101075741'

go

grant select on object::Bar_MSC_Xref_VW to p21_application_role
grant select on object::Bar_MSC_Xref_VW to PxxiUser
grant select on object::Bar_MSC_Xref_VW to [PTIDOM\P21Users]
