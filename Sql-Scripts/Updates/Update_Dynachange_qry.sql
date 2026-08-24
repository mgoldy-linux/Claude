-- duplicate pn
-- P21Play fc_dataobject_table_uid = 30, Live fc_dataobject_table = 29    
--use P21Play;
use P21;
SELECT  *
FROM  fc_dataobject_table 
where fc_dataobject_table_uid = 29     

update fc_dataobject_table
set join_syntax = 'left join inv_xref  on inv_mast.inv_mast_uid = inv_xref.inv_mast_uid and oe_hdr.customer_id = inv_xref.customer_id'
where fc_dataobject_table_uid = 29  

SELECT  join_syntax
FROM  fc_dataobject_table 
where fc_dataobject_table_uid = 29   