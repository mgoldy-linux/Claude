use P21Play;
/*
select *
from customer_edi_setting
where trading_partner_name = '003978277' and edi_interchange_id_qualifier is null

update customer_edi_setting
set edi_interchange_id_qualifier = '01' ,  edi_interchange_id = '003978277', application_code = '003978277'

select *
from customer_edi_setting
where trading_partner_name = '003978277'
*/

select *
from customer_edi_setting
--where customer_id = 48426
where trading_partner_name = '470441100' and edi_interchange_id_qualifier is null

update customer_edi_setting
set edi_interchange_id_qualifier = '01' ,  edi_interchange_id = '003978277', application_code = '003978277'

select *
from customer_edi_setting
where trading_partner_name = '003978277'