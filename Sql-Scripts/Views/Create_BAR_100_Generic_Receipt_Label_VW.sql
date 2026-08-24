use P21Play;
--use P21;

/*
if OBJECT_ID ('BAR_100_Generic_Receipt_Label_VW', 'V') is not null
drop view BAR_100_Generic_Receipt_Label_VW;
go

create view [dbo].[BAR_100_Generic_Receipt_Label_VW] AS
*/

SELECT DISTINCT m.item_id AS item_id210, m.item_desc AS item_id, m.extended_desc, mu.legacy_item_description AS item_desc
FROM dbo.inv_mast AS m 
LEFT OUTER JOIN dbo.inv_mast_ud AS mu 
ON m.inv_mast_uid = mu.inv_mast_uid 
INNER JOIN dbo.inv_loc AS l 
ON m.inv_mast_uid = l.inv_mast_uid
WHERE l.location_id in (100,450) and m.delete_flag = 'N' and l.delete_flag = 'N' and (default_product_group not in ('OTHERCHG','SNS') OR default_product_group is NULL)

/*
go 

grant select on object::BAR_100_Generic_Receipt_Label_VW to p21_application_role
grant select on object::BAR_100_Generic_Receipt_Label_VW to PxxiUser
grant select on object::BAR_100_Generic_Receipt_Label_VW to [PTIDOM\P21Users]
*/