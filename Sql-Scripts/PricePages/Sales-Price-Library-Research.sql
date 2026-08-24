-- Test delete update
use P21Sand;

select pc.price_library_uid,pc.row_status_flag, price_library_id,sequence_number
from dbo.price_library_x_cust_x_cmpy pc
join dbo.price_library pl
on pc.price_library_uid = pl.price_library_uid
where customer_id = 51241

update dbo.price_library_x_cust_x_cmpy
set row_status_flag = 700
where customer_id = 51241 

select pc.price_library_uid,pc.row_status_flag, price_library_id, sequence_number
from dbo.price_library_x_cust_x_cmpy pc
join dbo.price_library pl
on pc.price_library_uid = pl.price_library_uid
where customer_id = 51241

Update dbo.price_library_x_cust_x_cmpy
set price_library_uid = 188, row_status_flag = 704 
where customer_id = 51241 and sequence_number = 1

select pc.price_library_uid,pc.row_status_flag, price_library_id, sequence_number
from dbo.price_library_x_cust_x_cmpy pc
join dbo.price_library pl
on pc.price_library_uid = pl.price_library_uid
where customer_id = 10795
select *
from price_library
where price_library_uid = 4