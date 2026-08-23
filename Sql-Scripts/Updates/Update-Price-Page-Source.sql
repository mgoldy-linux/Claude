
-- change source to the latest
select *
from price_page
where effective_date = '2021-05-27 00:00:00.000'

Update price_page
set source_price_cd = 108
where effective_date = '2021-05-27 00:00:00.000'


select source_price_cd, description,price_page_uid,price_page_type_cd
from price_page
where effective_date = '2021-05-27 00:00:00.000'

select inv_mast_uid,item_id,item_desc,class_id1,class_id2,price1,price8,default_product_group
from inv_mast
where item_id = '04B-10B'