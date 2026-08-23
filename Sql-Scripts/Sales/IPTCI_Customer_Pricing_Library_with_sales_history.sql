/*
	03/26/2021 - George wants Cust #, Name What is their multiper, Sales total for 2018,2019,2020
	sh = sales history
*/

with sh2018(customer_id, Sales2018)
as
(
	Select customer_id,sum(extended_price)
	from invoice_hdr h
	join invoice_line l
	on h.order_no = l.order_no
	where year(order_date) = 2018 
	group by customer_id

),
sh2019(customer_id, Sales2019)
as
(
	Select customer_id,sum(extended_price)
	from invoice_hdr h
	join invoice_line l
	on h.order_no = l.order_no
	where year(order_date) = 2019 
	group by customer_id
),
sh2020(customer_id, Sales2020)
as
(
	Select customer_id,sum(extended_price)
	from invoice_hdr h
	join invoice_line l
	on h.order_no = l.order_no
	where year(order_date) = 2020 
	group by customer_id
),
getDist(customer_id,customer_name,class_2id,price_library_id,lib_description)
as
(
	select c.customer_id,customer_name,c.class_2id,pl.price_library_id,pl.description
	from customer c
	join price_library_x_cust_x_cmpy plxc
	on c.customer_id = plxc.customer_id
	join price_library pl
	on plxc.price_library_uid = pl.price_library_uid
	where delete_flag = 'N' and class_1id = 'DIST' and default_branch_id = 300 and credit_status != 'INACTIVE'
)
select gd.customer_id,customer_name,class_2id,price_library_id,lib_description,isNull(Sales2018,0)[Sales2018],isnull(Sales2019,0)Sales2019,isnull(Sales2020,0)Sales2020
from getDist gd
left join sh2018 s18
on gd.customer_id = s18.customer_id
left join sh2019 s19
on gd.customer_id = s19.customer_id
left join sh2020 s20
on gd.customer_id = s20.customer_id