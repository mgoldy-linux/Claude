select price1, price10, *
from inv_loc
where inv_mast_uid = 1064


select price_family_uid,price_page_uid,description,effective_date,expiration_date,calculation_value1,date_last_modified,last_maintained_by,source_price_cd
from price_page
where YEAR(effective_date) = 2021
order by product_group_id,effective_date

select *
from price_library
where price_library_id = '11910'

use P21Play;
select inv_mast_uid,item_id,item_desc,class_id1,class_id2,price1,price8,default_product_group
from inv_mast
where item_id = '04B-10B'

select price1,price10,product_group_id,effective_date
from inv_loc
where inv_mast_uid = 1109

select *
from pricing_service_layout

select *
from price_page
where effective_date = '2021-05-27 00:00:00.000'