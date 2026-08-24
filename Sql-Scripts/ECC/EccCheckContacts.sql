select id,address_id, first_name, last_name, email_address,class_5id,address_name
from contacts
where email_address like '%n@mechdrives.com'
order by date_created desc

select id,address_id, first_name, last_name, email_address,class_5id,address_name
from contacts
where email_address like '%@mrosupply.com'
order by date_created desc

select id,address_id, first_name, last_name, email_address,class_5id,address_name
from contacts
where email_address like '%@DJ-Reps.com'
order by date_created desc

select id,address_id, first_name, last_name, email_address,class_5id,address_name
from contacts
where email_address like '%@bakerperkins.com'
order by date_created desc

select id,address_id, first_name, last_name, email_address,class_5id,address_name
from contacts
where email_address like '%@fbnsalesinc.com'
order by date_created desc

select id,address_id, first_name, last_name, email_address,class_5id,address_name
from contacts
where first_name = 'Matt' and last_name = 'Low'
order by date_created desc



select *
from address
--where phys_city = 'Grand Rapids'
where id = 17030

select *
from customer
--where customer_id = 17030
order by date_created desc

select *
from contacts 
where address_id = 38763