use P21Sand;

select customer_name, customer_id,bill_to_contact_id,*
from customer
where customer_name like '%zoro%'

select customer_name, bill_to_contact_id
from customer
where customer_id = 10806

select customer_name, customer_id,salesrep_id,class_1id,class_2id,credit_status,trading_partner_name,default_branch_id,legacy_id
from customer c
where bill_to_contact_id = 23206

select c.address_name,c.email_address,phys_address1,phys_address2,phys_address3,phys_city,phys_state,phys_postal_code
from dbo.contacts c
join dbo.address a
on c.address_id = a.id
where c.id = 23206

select customer_name, c.customer_id,salesrep_id,c.class_1id,c.class_2id,credit_status,trading_partner_name,
case 
when cet.row_status_flag = 2709 then 'P21 Mapper for P21'
else 'Inactive'
end[810 Invoice Send],c.default_branch_id,legacy_id,co.email_address,phys_address1,phys_address2,phys_address3,phys_city,phys_state,phys_postal_code
from dbo.customer c
join dbo.address a
on c.customer_id = a.id
left join dbo.contacts co
on c.bill_to_contact_id = co.id
left join dbo.customer_edi_transaction cet
on c.customer_id = cet.customer_id
where c.class_2id = 'BDI'

select top 7 *
from customer_edi_transaction
where customer_id = 10806

-- find billable contact
select customer_name,customer_id, bill_to_contact_id
from customer c
join address a
on c.customer_id = a.id
where corp_address_id = 10806 and c.delete_flag = 'N'
order by bill_to_contact_id