use P21;

select Month(transaction_date)[Month], transaction_date, account_number, amount
from gl
where period = 3 and year_for_period = 2020 and LEFT(account_number,2) IN (41)

select top 5 *
from gl
where period = 3 and year_for_period = 2020 and LEFT(account_number,2) IN (41)

select account_no, account_desc, account_type
from chart_of_accts
where LEFT(account_no,1) IN (4)

select account_no, account_desc, account_type
from chart_of_accts
where account_type IN('R','X') and company_no = 1 

select a.account_desc, FLOOR(g.amount/1000)[amount], g.account_number, a.branch_id,a.company_no, period, year_for_period
from gl g
inner join chart_of_accts a
on  g.account_number = a.account_no and g.company_no = a.company_no
WHERE account_number LIKE '42%' and transaction_date between '09/01/2019' and '09/30/2019'
ORDER BY amount 