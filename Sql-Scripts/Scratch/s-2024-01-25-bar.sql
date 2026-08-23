select *
from BAR_100_Generic_Receipt_Label_VW
where item_id210 in ('2211071158','2211071229','2211071228','2211071226','2211071227')

select default_product_group,l.delete_flag,l.location_id,m.delete_flag
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where item_id in ('2211071158','2211071229','2211071228','2211071226','2211071227')

SELECT DISTINCT m.item_id AS item_id210, m.item_desc AS item_id, m.extended_desc, mu.legacy_item_description AS item_desc
FROM dbo.inv_mast AS m 
LEFT OUTER JOIN dbo.inv_mast_ud AS mu 
ON m.inv_mast_uid = mu.inv_mast_uid 
INNER JOIN dbo.inv_loc AS l 
ON m.inv_mast_uid = l.inv_mast_uid
WHERE l.location_id in (100,450) and  item_id in ('2211071158','2211071229','2211071228','221107126','2211071227') and m.delete_flag = 'N' and l.delete_flag = 'N' and (default_product_group not in ('OTHERCHG','SNS') OR default_product_group is NULL)