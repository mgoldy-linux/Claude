select top 10 price_library_uid,price_library_id,description
from price_library

select top 10 price_lib_x_cust_x_cmpy_uid,customer_id,price_library_uid,sequence_number
from price_library_x_cust_x_cmpy

select cm.price_library_uid,price_library_id,description,customer_id
from price_library_x_cust_x_cmpy cm
join price_library l
on cm.price_library_uid = l.price_library_uid
where customer_id like '1500%'


select distinct description
from price_library