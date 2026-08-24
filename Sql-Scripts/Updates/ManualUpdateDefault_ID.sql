-- need to turn into nightly job
-- make sure I check if the ID  should be 100, 200 or 300

select distinct c.customer_id,c.customer_name, c.date_created,s.default_branch[ShipTo Default ID],default_branch_id[Customer Default]
from customer c
join ship_to s
on c.customer_id = s.customer_id
where c.default_branch_id is null and c.delete_flag = 'N'
order by customer_id desc

select default_branch, date_last_modified,customer_id,last_maintained_by
from ship_to 
where customer_id > 33766 and date_last_modified > '2021-01-01'
order by date_last_modified desc

select default_branch_id, date_last_modified,last_maintained_by,date_last_modified
from customer
where customer_id = 31461

update customer
set default_branch_id = 200
where customer_id =  29398
--where customer_id in (29271,29335,29437,29484,29518,29592,29644,29712,29761,29769)

select customer_id,default_branch_id, date_last_modified,last_maintained_by
from customer
where customer_id = 31461

-- to check results
select c.customer_id,customer_name, c.date_created,default_branch_id[Customer Default],s.default_branch,c.date_last_modified
from customer c
join ship_to s
on c.customer_id = s.customer_id
where c.date_created > '2021-01-01' and c.customer_id > 33766
order by c.date_created desc

select *
from ship_to
where customer_id = 30193