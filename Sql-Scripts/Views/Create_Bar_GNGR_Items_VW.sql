--use P21Sand;
use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_GNGR_Items_VW', 'V') is not null
drop view Bar_GNGR_Items_VW;
go

create view [dbo].[Bar_GNGR_Items_VW] AS
*/
SELECT distinct ix.their_item_id,m.item_id, m.item_desc, customer_id
FROM dbo.inv_xref AS ix 
INNER JOIN dbo.inv_mast AS m 
ON ix.inv_mast_uid = m.inv_mast_uid 
WHERE ix.customer_id IN (54210, 54533) -- and their_item_id = '35TW68'
go
/*
grant select on object::Bar_GNGR_Items_VW to p21_application_role
grant select on object::Bar_GNGR_Items_VW to PxxiUser
grant select on object::Bar_GNGR_Items_VW to [PTIDOM\P21Users]
*/
