/*
	05/25/2023 test exclude
*/
use P21Play;
--use P21;
/*
if OBJECT_ID ('d_Orders_2_Quotes_VW', 'V') is not null
drop view d_Orders_2_Quotes_VW;
go

create view [dbo].[d_Orders_2_Quotes_VW] AS
*/

select order_no,source_id[quote_no],po_no
from oe_hdr
where source_code_no = 709
/*
go 

grant select on object::d_Orders_2_Quotes_VW to p21_application_role
grant select on object::d_Orders_2_Quotes_VW to PxxiUser
grant select on object::d_Orders_2_Quotes_VW to [PTIDOM\P21Users]
*/

