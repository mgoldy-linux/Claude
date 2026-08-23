select *
from customer_ud
where customer_id = 48517

select customer.customer_id, customer.customer_name, customer_ud.legacy_company_id, customer_ud.legacy_customer_id 
from customer join customer_ud 
on customer.customer_id = customer_ud.customer_id and customer.company_id = customer_ud.company_id
where legacy_company_id is not null


select *
from inv_xref
where customer_id = 55932

select item_desc, extended_desc, upc_or_ean_id,class_id1,class_id2,class_id3,inv_mast_uid,*
from inv_mast
where item_desc like '3535 X 1%'  --AHX2314*65MM  -- 3535 X 1-5/8
--where item_desc = 'HM516449'
--where item_desc Like 'JH1312%' -- 'HM 215249'  HM516449
--where extended_desc = 'Withdrawal Sleeve,85mm,45mm'
--where item_id = '2101100887'
--where upc_or_ean_id = '888569092144'
--where item_desc like 'W%'
-- inv_mast_uid = 101841--84798
 
select item_id,class_id1,class_id2,class_id3
from dbo.inventory_supplier s
join dbo.inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
where upc_code = '888569057952'

select *
from alternate_code
where alternate_code = '888569092144'

select *
from inv_xref
where their_item_id = '45PZ43'

select *
from inv_mast_ud
where inv_mast_uid = 84798