use P21;
-- this query miss null customers
with  getcustids  
as
(
select distinct customer_id
from invoice_hdr 
where sales_location_id = 460
)
select customer_name, coh.customer_id--,extended_price[May 23 sales],(extended_price - extended_cost)[Profit]
from getcustids gc
left outer join customer_order_history coh
on gc.customer_id = coh.customer_id
left outer join customer c
on c.customer_id = gc.customer_id
where year_ordered = 2022 and month_ordered = 5


-- all 460 customers
with  getcustids  
as
(
select distinct customer_id
from invoice_hdr 
where sales_location_id = 460
)
select  gc.customer_id,customer_name
from getcustids gc
join customer c
on gc.customer_id = c.customer_id
--where year_ordered = 2023 and coh.customer_id = 10038 --and month_ordered = 5

select *
from customer_order_history
where customer_id = 10038 and year_ordered = 2022 
