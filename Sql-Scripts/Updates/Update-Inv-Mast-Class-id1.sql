--use p21play;
use P21;

select inv_mast_uid, item_id, item_desc, default_purchase_disc_group --Count (*)
from inv_mast 
where class_id1 is null and default_sales_discount_group != 'D'

update dbo.inv_mast
set class_id1 = default_sales_discount_group
where class_id1 is null and default_sales_discount_group != 'D'

select Count (*)
from inv_mast 
where class_id1 is null and default_sales_discount_group != 'D'