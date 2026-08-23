use P21Local;

update c
set c.default_branch_id = s.default_branch
From customer c, ship_to s
where c.customer_id = s.customer_id and c.customer_id > 26456