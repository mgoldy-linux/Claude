/*
  01/20/2020 - find default address for Applied,BDI,DXP,IBT,Kaman,Motion information for Alferdo, what is a default shipping address for the customer

*/

use P21;

Select id,name,mail_address1,mail_city,mail_state,mail_postal_code,mail_country,corp_address_id
from address
where name like 'Butter%'
--where name like 'Motion%Bill%' and shipping_address = 'Y' and customer = 'Y'

/*
Select distinct corp_address_id
from address
where name like 'BDI%'
order by corp_address_id


select id,name,mail_address1,mail_city,mail_state,mail_postal_code,corp_address_id
from address
where id = 13866
*/

select *
from oe_hdr
where customer_id = 13866

select id,name,mail_address1,mail_city,mail_state,mail_postal_code,corp_address_id
from address
where corp_address_id = 16402
order by name