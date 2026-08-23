select first_name,last_name,email_address,co.class_5id[Contact Class 5id],id[Contact ID],address_id[Customer ID],c.web_enabled_flag[Customer Web Enable]
from contacts co
join customer c
on co.address_id = c.customer_id and c.default_branch_id = 300 and c.web_enabled_flag = 'Y' and co.class_5id is not null