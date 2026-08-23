-- quick way to tell if AD customer is market-place or not. If they have a value in trading partner name then they are marketplace

select customer_name,customer_id, trading_partner_name
from customer
where customer_name like 'AD-%' and delete_flag = 'N' and class_2id like 'IDC%'