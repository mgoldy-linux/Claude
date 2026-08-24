--use P21Sand;

select customer_name, customer_id,legacy_id[MD_Legacy_ID],phys_address1,phys_address2,phys_city,phys_state, phys_postal_code, phys_country,c.date_created
from dbo.customer c
join dbo.address a
on c.customer_id = a.id
where ar_account_no like '120100006%' and c.delete_flag = 'N'-- and customer_id = '123688'
order by date_created


