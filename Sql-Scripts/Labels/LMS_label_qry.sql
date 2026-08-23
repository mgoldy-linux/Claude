-- lms labels research.

select * 
from inv_mast
where item_id = '109191' or item_id = '071118SM-V'

-- missing Qty per 
select item_id,a.phys_country,iv.supplier_id
from p21_item_view iv
join address a
on iv.supplier_id = a.corp_address_id
where iv.class_id1 = 'LMS'

select distinct iv.supplier_id,a.phys_country,iv.item_id
from p21_item_view iv
join address a
on iv.supplier_id = a.corp_address_id
where iv.class_id1 = 'LMS'
order by iv.item_id

-- look for upc 
select item_id,upc_or_ean_id,upc_or_ean,item_desc,class_id1,class_id2,class_id3,class_id4,class_id5
from inv_mast 
where class_id1 = 'LMS'