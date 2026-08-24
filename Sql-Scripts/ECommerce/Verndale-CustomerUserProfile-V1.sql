select distinct
a.id as sequence, 
cs.address_id as CustomerId,
cs.email_address as Email
from contacts cs 
join customer c (NOLOCK) 
on cs.address_id = c.customer_id
left join dbo.ship_to st (NOLOCK)
on c.customer_id = st.customer_id
join dbo.address a (NOLOCK)
on st.ship_to_id = a.id
join customer_type ct (NOLOCK) 
on ct.customer_type_uid = c.customer_type_cd and ct.customer_type = 'Customer'
where isnull(cs.email_address,'') <> ''
and cs.delete_flag = 'N'
and (c.company_id = 1 and web_enabled_flag = 'Y')