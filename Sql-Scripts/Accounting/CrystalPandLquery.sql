select account_desc, FLOOR(g.amount/1000)[amount],a.branch_id,a.company_no
from gl g 
inner join chart_of_accts a
on  g.account_number = a.account_no and g.company_no = a.company_no
where account_no LIKE '41%' and period = 3 and year_for_period = 2020