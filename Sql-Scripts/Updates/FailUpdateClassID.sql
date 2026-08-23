--- causes error in P21

select distinct class_id1
from inv_mast
order by class_id1

Update inv_mast
set class_id1 = 'PTI' 
where default_sales_discount_group = 'PTI'

select distinct class_id1
from inv_mast
order by class_id1