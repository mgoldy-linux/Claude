-- Just customers
with getCustIds
as
(
	select distinct jpc.customer_id
	from job_price_customer_shipto jpc
	where job_price_hdr_uid = 3
	)
select gci.customer_id, a.corp_address_id,c.customer_name, a.phys_address1, a.phys_address2, a.phys_city, a.phys_state
from getCustIds gci
join address a
on gci.customer_id = a.id
join customer c
on gci.customer_id = c.customer_id

-- just ship
with getCustIds
as
(
	select distinct jpc.customer_id
	from job_price_customer_shipto jpc
	where job_price_hdr_uid = 3
	)
select gci.customer_id,s.ship_to_id,a.name
from getCustIds gci
join ship_to s
on gci.customer_id = s.customer_id
join address a
on s.ship_to_id = a.id
--where gci.customer_id = 11580

-- combined
with getCustIds
as
(
	select distinct jpc.customer_id
	from job_price_customer_shipto jpc
	where job_price_hdr_uid = 3
	),
getShip2id
as
(
	select gci.customer_id, a.corp_address_id,c.customer_name, a.phys_address1, a.phys_address2, a.phys_city, a.phys_state,ship_to_id
	from getCustIds gci
	join address a
	on gci.customer_id = a.id
	join customer c
	on gci.customer_id = c.customer_id
	join ship_to s
	on gci.customer_id = s.customer_id
)
select customer_id,gs.corp_address_id,gs.customer_name,gs.phys_address1,gs.phys_address2, gs.phys_city, gs.phys_state,ship_to_id, a.name
from getShip2id gs
join address a
on gs.ship_to_id = a.id
order by customer_id

-- How BL identifies AD customers
select *
from address
where phys_address1 like 'Ad M%'