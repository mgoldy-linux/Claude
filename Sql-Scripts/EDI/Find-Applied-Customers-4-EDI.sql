use P21;

select default_branch_id,*
from customer
where customer_name like '%Applied I%' and delete_flag = 'N' and trading_partner_name is not null

