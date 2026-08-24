-- price pages

select item_id, upc_or_ean_id,price1,price10,item_desc,default_product_group,commodity_code
from inv_mast


select *
from inv_mast
where upc_or_ean_id = '80067502553'

select *
from inv_mast 
where delete_flag = 'y'