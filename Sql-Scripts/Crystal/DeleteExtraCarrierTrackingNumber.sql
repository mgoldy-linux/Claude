-- didn't work for crystal reports
select *
from oe_pick_ticket
where order_no = 1101594

select *
from oe_pick_ticket_detail
where pick_ticket_no = 2086707

select *
from transport_shipping_info
where pick_ticket_no = 2086707 

--1st
delete from oe_pick_ticket_detail
where pick_ticket_no = 2086707

--2nd
delete from transport_shipping_info
where pick_ticket_no = 2086707

--3rd
delete from oe_pick_ticket
where pick_ticket_no = 2086707


