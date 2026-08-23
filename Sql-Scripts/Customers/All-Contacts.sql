use P21sand;

select (co.first_name + ' ' + co.last_name)[Contact Name],customer_id[Customer Id],corp_address_id,co.email_address,c.class_1id,c.class_4id,c.credit_status,c.default_branch_id[Default Branch Id],salesrep_id[Salesrep ID],customer_name[Name],
case
when customer_type_cd = 1203 then 'Customer'
else 'Deleted'
end[Customer Type],mail_address1[address1],mail_address2[address2], mail_city[City],mail_state[State],c.company_id[Company Id],mail_postal_code[PostalCode],central_phone_number[Phone Number]
from dbo.customer c
join dbo.address a
on c.customer_id = a.id
left join dbo.contacts co
on c.customer_id = co.address_id
--where c.delete_flag = 'N'


