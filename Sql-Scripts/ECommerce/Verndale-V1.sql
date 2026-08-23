-- leave out Masterdrive because preferrred_location_id no longer used
-- Query for Warehouses/locations
select location_id,
location_name
from location
where company_id = '1' and delete_flag = 'N' and
location_id in (select distinct preferred_location_id from address where customer = 'Y' and delete_flag = 'N')

select distinct preferred_location_id from address where  customer = 'Y' and delete_flag = 'N'

select customer, delete_flag,preferred_location_id, *
from address
where id = 126061

- Query for Customers

select c.customer_id,
s.preferred_location_id,
CASE shipping_address WHEN 'Y' THEN convert(varchar,s.customer_id) ELSE '' END as sequence,
c.credit_limit,
s.terms_id,
customer_name,
phys_address1 as address1,
phys_address2 as address2,
phys_city as city,
phys_state as state,
phys_postal_code as postalcode,
CASE 
  WHEN ISNULL(phys_country,'') = '' THEN 'US'
  WHEN phys_country = 'US' THEN 'US'
  WHEN phys_country ='USA' THEN 'US'
  WHEN phys_country = 'U.S.A.' then 'US'
  WHEN charindex('United st',phys_country) > 0 THEN 'US'
  ELSE ''
END as Country,
phys_country,
central_phone_number,
po_no_required, 
CASE currency_id
  WHEN '1' THEN 'USD'
END as CurrencyCode,
CASE shipping_address WHEN 'Y' THEN 1 ELSE 0 END as IsShipTo,
CASE 
  WHEN email_address = 'DNE' THEN ''
  WHEN email_address IS NULL THEN ''
  WHEN charindex(';',email_address) > 0 THEN 
       SUBSTRING(email_address,1,charindex(';',email_address)-1)
  ELSE email_address
END as email_address,
salesrep_id,
s.preferred_location_id,
CASE c.delete_flag WHEN 'Y' THEN 0 ELSE 1 END as IsActive
from customer c (NOLOCK)
join customer_type ct (NOLOCK) on ct.customer_type_uid = c.customer_type_cd and ct.customer_type = 'Customer'
join address a (NOLOCK) on a.id = c.customer_id
join ship_to s (NOLOCK) on a.id = s.ship_to_id

where c.company_id = '1' and
c.web_enabled_flag = 'Y'
order by c.customer_id desc