select ship2_add1,Left(ship2_zip,5)ZipCode,ship_to_phone,location_id,Customer_id,Customer_id[shiptoID],contact_id,left(po_no,4)[BranchID],h.order_no,customer_part_number
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where po_no like 'MA10%' and ship2_name like 'Motion%' and location_id = 300
order by BranchID
/*
SELECT *
FROM contacts
WHERE id = 8885
*/

select *
from address
where id = 14746

select customer_name, customer_id, a.name, a.phys_address1, a.phys_postal_code,central_phone_number
from customer c
join address a
on c.customer_id = a.id
where class_2id = 'Motion' and a.phys_state = 'MA'

select *
from contacts
where address_id = 14110