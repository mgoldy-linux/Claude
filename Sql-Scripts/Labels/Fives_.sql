-- Fives label

select v.item_id,i.item_desc,upc_or_ean_id,order_no,customer_part_number
from p21_order_view v
join inv_mast i
on v.inv_mast_uid = i.inv_mast_uid
where year(order_date) = year(getdate()) and month(order_date) = month(getDate()) and day(order_date) = day(GETDATE())
order by order_no desc


/*  -- research
select *
from inv_mast
where upc_or_ean_id = 80067530916

select *
from p21_view_ord_ack_line
select item_id, customer_part_number,ship2_name
from p21_order_view
where customer_part_number like 'B%'
order by ship2_name
*/