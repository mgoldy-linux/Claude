
select *
from popup_index

select item_id,m.inv_mast_uid
from inventory_supplier s
join inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
where upc_code = '80067566633'
--where upc_code = '80067562418' and division_id = 16361
--where upc_code in ('80067576013','80067576017','80067576025','80067576036','80067576063','80067562418') 


select *
from inventory_supplier s
where inv_mast_uid = 37477

select *
from inv_mast 
where item_id = '2101015822'


select *
from customer_ud
where legacy_customer_id = '0999'

select top 5 legacy_id, *
from customer 
where legacy_id = '999'