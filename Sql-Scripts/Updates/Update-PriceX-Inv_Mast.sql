/*
  04/16/2021 - update price 9 with price 1 per Olivia.
  10/04/2021 - update price 8 with price 1 next set for October 25 price increase
  10/22/2021 - update P21
  *** DO BOTH EPL & NOTEPL ***
*/
use [P21Play2021.1.4420Local];
--use P21Local2020;
--use P21Play;
--Use P21;
/*
-- PTI EPL
select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'EPL'

update inv_mast
set price7 = price1
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'EPL'

select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'EPL'

-- check p21
select top 5 inv_mast_uid,item_id,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'EPL'
*/

/*
--- PTI NOTEPL
select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'NOTEPL'

update inv_mast
set price7 = price1
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'NOTEPL'

select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'NOTEPL'

-- check p21
select top 5 inv_mast_uid,item_id,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'PTI' and Price1 != 0 and class_id2 = 'NOTEPL'
*/

/*
-- IPTCI EPL
select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'EPL'

update inv_mast
set price7 = price1
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'EPL'

select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'EPL'

-- check p21
select top 5 inv_mast_uid,item_id,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'EPL'
*/

/*
-- IPTCI NOTEPL
select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'NOTEPL'

update inv_mast
set price7 = price1
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'NOTEPL'

select inv_mast_uid,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'NOTEPL'

-- check p21
select top 5 inv_mast_uid,item_id,price1,  price7,price8,price9,price10
from inv_mast
where default_sales_discount_group = 'IPTCI' and Price1 != 0 and class_id2 = 'NOTEPL'
*/