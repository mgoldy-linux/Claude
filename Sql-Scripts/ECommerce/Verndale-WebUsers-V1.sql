select cs.id as ContactId, 
cs.address_id as CustomerId,
cs.email_address as Email,
cs.first_name as FirstName,
cs.last_name as LastName,
cs.direct_phone as Phone,
'solveindustrial' as WebSite,
'Buyer3' as Role
from contacts cs 
join customer c (NOLOCK) 
on cs.address_id = c.customer_id
join address a (NOLOCK) 
on a.id = c.customer_id 
left join ship_to s (NOLOCK) 
on a.id = s.ship_to_id
where isnull(cs.email_address,'') <> ''
and cs.delete_flag = 'N'
and c.company_id = 1 and web_enabled_flag = 'Y'