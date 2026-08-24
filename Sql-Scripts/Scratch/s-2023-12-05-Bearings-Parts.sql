use P21Sand;

select item_id, m.inv_mast_uid,default_sales_discount_group
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where  class_id2 = 'EPL' and m.delete_flag = 'N' and location_id in (100,410,420,430,450,470) and class_id1 not in ('PTI','LMS','IPTCI','MD','SPB') and default_sales_discount_group not in ('SPB','MD')

select *
from customer_salesrep
where customer_id = 52473 and primary_salesrep_flag = 'Y' and row_status_flag = 704

select salesrep_id, salesrep_assigned_date,last_maintained_by
from customer
where customer_id = 52473

select *
from customer_salesrep
where customer_id = 12392 and row_status_flag = 704 and primary_salesrep_flag = 'N'

select distinct default_sales_discount_group
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where  class_id2 = 'EPL' and m.delete_flag = 'N' and location_id in (100,410,420,430,450,470) and class_id1 not in ('PTI','LMS','IPTCI','MD','SPB') and default_sales_discount_group not in ('SPB','MD')