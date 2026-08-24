select
c.customer_id, convert(varchar,a.corp_address_id)as sequence,
c.credit_limit,
c.terms_id,
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
  WHEN phys_country ='CA' THEN 'CA'
  ELSE ''
END as Country,
phys_country,
central_phone_number,
po_no_required, 
CASE 
  WHEN currency_id = '1' THEN 'USD' 
  WHEN phys_country ='CA' THEN 'CAD' 
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
from
customer c (NOLOCK) 
join address a (NOLOCK) 
on a.id = c.customer_id 
left join ship_to s (NOLOCK) 
on a.id = s.ship_to_id
where c.company_id = '1' and web_enabled_flag = 'Y' --and c.customer_id = 125604 
order by customer_id desc