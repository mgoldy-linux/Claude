/*
	09/02/2021 - convert jet to sql query
=NL("rows","INV_MAST",,"DataSource=","P21LIVE","class_id2","EPL","default_sales_discount_group","pti","delete_flag","N")
*/

select *
from inv_mast
where class_id2 = 'EPL' and default_sales_discount_group = 'pti' and delete_flag = 'N'