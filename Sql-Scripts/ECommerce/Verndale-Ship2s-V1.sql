--Shiptos
select c.customer_id,
a.id as sequence,
c.terms_id,
a.name as CompanyName,
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
CASE 
  WHEN email_address = 'DNE' THEN ''
  WHEN email_address IS NULL THEN ''
  WHEN charindex(';',email_address) > 0 THEN SUBSTRING(email_address,1,charindex(';',email_address)-1)
  ELSE email_address
END as email_address,
salesrep_id,
carrier_id,
--freight_code,
CASE c.delete_flag WHEN 'Y' THEN 0 ELSE 1 END as IsActive
from customer c (NOLOCK) 
join customer_type ct (NOLOCK) on ct.customer_type_uid = c.customer_type_cd and ct.customer_type = 'Customer'
join address a (NOLOCK) on a.corp_address_id = c.customer_id
where c.company_id = '1' and
a.shipping_address = 'Y' and
c.web_enabled_flag = 'Y'
order by customer_id desc

-- not a valid field, no longer used
select customer, shipping_address
from address
where id = 126061