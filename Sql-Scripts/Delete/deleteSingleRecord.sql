use P21Sand;

/*
Msg 547, Level 16, State 0, Line 61
The DELETE statement conflicted with the REFERENCE constraint "fk_customer_edi_setting_customer". The conflict occurred in database "P21Play", table "dbo.customer_edi_setting".
Msg 547, Level 16, State 0, Line 44
The DELETE statement conflicted with the REFERENCE constraint "fk_price_library_x_cust_x_cmpy_customer". The conflict occurred in database "P21Play", table "dbo.price_library_x_cust_x_cmpy".
Msg 547, Level 16, State 0, Line 14
The DELETE statement conflicted with the REFERENCE constraint "fk_ship_to_salesrep_ship_to". The conflict occurred in database "P21Play", table "dbo.ship_to_salesrep".
	Msg 547, Level 16, State 0, Line 9
The DELETE statement conflicted with the REFERENCE constraint "fk_ship_to_customer". The conflict occurred in database "P21Play", table "dbo.ship_to"
*/

-- verified bad record
select ship_to_id,salesrep_id
from ship_to_salesrep
where ship_to_id = 0

-- delete record
delete from ship_to_salesrep
where ship_to_id = 0

-- verify removed
select ship_to_id,salesrep_id
from ship_to_salesrep
where ship_to_id = 0

-- verified bad record
select customer_id,state_exemption_number
from ship_to
where customer_id = 0

-- delete record
delete from ship_to
where customer_id = 0

-- verify removed
select customer_id,state_exemption_number
from ship_to
where customer_id = 0

-- verified bad record
select customer_id,last_maintained_by
from price_library_x_cust_x_cmpy
where customer_id = 0

-- delete record
delete from price_library_x_cust_x_cmpy
where customer_id = 0 

-- verify removed
select customer_id,last_maintained_by
from price_library_x_cust_x_cmpy
where customer_id = 0

-- verified bad record
select customer_edi_setting_uid, customer_id
from customer_edi_setting
where customer_id = 0

-- delete record
delete from customer_edi_setting
where customer_id = 0 

-- verify removed
select customer_edi_setting_uid, customer_id
from customer_edi_setting
where customer_id = 0

--customer_salesrep
-- verified bad record
select customer_id,salesrep_id
from customer
where customer_id = 0

-- delete record
delete from customer_salesrep
where customer_id = 0

-- verify removed
select customer_id,salesrep_id
from customer_salesrep
where customer_id = 0

--customer
-- verified bad record
select customer_id,customer_name
from customer
where customer_id = 0

-- delete record
delete from customer
where customer_id = 0 

-- verify removed
select customer_id,customer_name
from customer
where customer_id = 0






