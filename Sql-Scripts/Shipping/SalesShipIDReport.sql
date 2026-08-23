select distinct customer_id[Cust#],h.location_id[Branch],a.name[Cust Name],sr.salesrep_id[Sales Rep ID],h.address_id[Drop Ship#],ship2_name[Drop Ship Customer Name],(c.first_name + ' ' + c.last_name)[Drop Ship Contact Name],ship2_add1[Drop Ship Address],ship2_city[Drop Ship City],ship2_state[Drop Ship ST],ship2_zip[Drop Ship Zip]
from oe_hdr h
join oe_hdr_salesrep sr
on h.order_no = sr.order_number
join address a 
on h.customer_id = a.id
join contacts c
on h.contact_id = c.id
where h.delete_flag = 'N' and cancel_flag = 'N' and h.projected_order = 'N'
order by [Cust#]

