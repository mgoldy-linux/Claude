Use P21Play;

Select  trading_partner_name, delete_flag
from customer
where customer_id = 10828

select *
from customer_edi_setting
where customer_id = 10828

select trading_partner_name
from customer
where customer_id = 10828

select *
from customer_edi_transaction
where customer_id = 10828

select customer_edi_transaction_uid
from customer_edi_transaction
where customer_id = 10828 and edi_transaction = 945

update customer_edi_setting 
set trading_partner_name = '003978277',edi_interchange_id_qualifier = '01',edi_interchange_id = '003978277',application_code = '003978277'
where customer_id = 10828