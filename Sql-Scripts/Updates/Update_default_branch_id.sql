-- 06/09/2020 - nightly script to ensure customer default branch id is updated

Use P21Local;

update customer
set customer.default_branch_id = ship_to.default_branch
from customer, ship_to
where customer.default_branch_id is null and customer.customer_id = ship_to.customer_id 