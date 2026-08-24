

with getSRNames
as
(
	select distinct salesrep_id
	from customer
	)
select salesrep_id,email_address,c.email_address2,address_name
from contacts c
join getSRNames gsr
on c.id = gsr.salesrep_id
where email_address is not null -- removes in-house reps
order by salesrep_id

