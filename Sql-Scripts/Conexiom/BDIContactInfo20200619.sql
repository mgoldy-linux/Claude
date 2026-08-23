--- update Shipto for Conexiom, pulling only location 300

select distinct case when ship2_add1 = '' then 'Blank address' else ship2_add1 end[Address],c.email_address,c.first_name,c.last_name,
ship2_zip[ZipCode],ship_to_phone[Phone Number],source_location_id[Location ID],customer_id[Customer ID],o.address_id[ShipTo ID],contact_id[Contact ID]
from oe_hdr o
join contacts c
on o.customer_id = c.id
where ship2_name not like 'BDI%' and source_location_id = 300 and ship2_add1 is not null and (o.address_id is not null and o.address_id != 0) and contact_id is not null and ship2_zip is not null
order by [first_name]

