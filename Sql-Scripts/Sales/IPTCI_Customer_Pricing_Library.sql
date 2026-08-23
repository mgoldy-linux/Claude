/*
	01/22/2021 -generate a report for all Distributor Customer IDs for Location 300 with the assigned Multiplier, Price Library
	Database name for 'Sales Pricing Library ID ¤' is price_library.price_library_id.
	Database name for 'Description' is price_library.description.
	Database name for 'Multiplier' is customer.multiplier.
	The table to be updated is price_library_x_cust_x_cmpy.
*/

select c.customer_id,customer_name,c.class_2id,pl.price_library_id,pl.description,c.credit_status,salesrep_id,(sr.first_name + ' ' + sr.last_name)[SalesrepName]
from customer c
join price_library_x_cust_x_cmpy plxc
on c.customer_id = plxc.customer_id
join price_library pl
on plxc.price_library_uid = pl.price_library_uid
join contacts sr
on c.salesrep_id = sr.id
where c.class_1id = 'DIST' and c.default_branch_id = 300 and c.delete_flag = 'N' and c.credit_status != 'INACTIVE'

