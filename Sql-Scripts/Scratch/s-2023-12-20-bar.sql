use P21Sand;

select their_item_id, item_id, item_desc, customer_id
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where their_item_id = '35JA09'

select *
from inv_mast m
where item_desc like '%525%' --  2RS

select top 5*
from inv_mast_ud 
where legacy_item_id like '%525%' 

SELECT DISTINCT ix.their_item_id, isu.upc_code, m.item_id, m.item_desc
FROM            dbo.inv_xref AS ix INNER JOIN
                         dbo.inventory_supplier AS isu ON ix.inv_mast_uid = isu.inv_mast_uid INNER JOIN
                         dbo.inv_mast AS m ON ix.inv_mast_uid = m.inv_mast_uid
WHERE        (ix.customer_id IN (54210, 54533)) and their_item_id = '35JA09'


SELECT DISTINCT ix.their_item_id, isu.upc_code, m.item_id, m.item_desc,customer_id
FROM            dbo.inv_xref AS ix INNER JOIN
                         dbo.inventory_supplier AS isu ON ix.inv_mast_uid = isu.inv_mast_uid INNER JOIN
                         dbo.inv_mast AS m ON ix.inv_mast_uid = m.inv_mast_uid
WHERE        (ix.customer_id IN (54210, 54533)) and item_id = '2101081861'