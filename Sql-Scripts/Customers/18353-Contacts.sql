--use p21;

select customer_id[Customer Id],legacy_id[Legacy ID],c.default_branch_id[Default Branch Id],salesrep_id[Salesrep ID],customer_name[Name],
case
when currency_id = 1 then 'USD (US Dollars)'
else 'Unknown'
end [Currency ID],
case
when customer_type_cd = 1203 then 'Customer'
else 'Unkown'
end[Customer Type],mail_address1[address1],mail_address2[address2], mail_city[City],mail_state[State],c.company_id[Company Id],mail_postal_code[PostalCode],central_phone_number[Phone Number],(co.first_name + ' ' + co.last_name)[Contact Name],co.email_address
from dbo.customer c
join dbo.address a
on c.customer_id = a.id
left join dbo.contacts co
on c.customer_id = co.address_id
where salesrep_id = 18353 and c.delete_flag = 'N'
