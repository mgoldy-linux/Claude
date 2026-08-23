/*
--Msg 8114, Level 16, State 5, Line 3
--Error converting data type varchar to numeric.

select item_id, item_desc, class_id1,column_changed,column_description,convert(decimal(10,3),old_value)[old_value],convert(decimal(10,3),new_value)[new_value],FORMAT(aut.date_created,'yyyy-MM-dd')[Date Changed]
from audit_trail aut
join inv_mast m
on aut.inv_mast_uid = m.inv_mast_uid
where column_changed like 'Price%' and key1_cd = 'inv_mast_uid' and table_changed = 'inv_mast'
*/


select item_id, item_desc, class_id1,column_changed,column_description,old_value,new_value,FORMAT(aut.date_created,'yyyy-MM-dd')[Date Changed]
from audit_trail aut
join inv_mast m
on aut.inv_mast_uid = m.inv_mast_uid
where column_changed like 'Price%' and key1_cd = 'inv_mast_uid' and table_changed = 'inv_mast'