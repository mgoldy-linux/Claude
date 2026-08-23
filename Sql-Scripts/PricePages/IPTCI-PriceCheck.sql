select top 10 *
from invoice_line
where date_created > '2022-07-21'

select *
from import_suspense_line
where key_value_table = 'oe_line'

select *
from import_val_status

select item_id,Price1,price7,price8,class_id1,class_id2,delete_flag,default_product_group
from inv_mast
where item_id in ('2101037210','2101037209','2101047151')

select item_id,Price1,price7,price8,class_id1,class_id2,delete_flag,default_product_group
from inv_mast
where price1 = price7 and class_id1 = 'IPTCI' and class_id2 = 'NOTEPL' and delete_flag = 'N'
order by date_created desc

select *
from oe_hdr
where order_date > '2022-07-21'

select *
from inv_mast
where item_desc like '2206-2R%'