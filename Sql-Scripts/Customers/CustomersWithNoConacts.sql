
with getCorpIDs (corp_address_id)
as
(
	select distinct corp_address_id
	from address
)
select g.corp_address_id,name,mail_city,mail_state,count(c.id)[NumberOfContacts]
from getCorpIDs g
left join contacts c
on g.corp_address_id = c.address_id
join address a
on g.corp_address_id = a.corp_address_id
where c.id is null and a.customer = 'Y' and a.delete_flag = 'N' and name not like '%INACTIVE%'  and name not like '%CLOSED%'  and name not like '%DUPLICATE%'  and name not like '%DO NOT USE%' and mail_state is not null and mail_country = 'US'
group by g.corp_address_id,name,mail_city,mail_state
order by name


