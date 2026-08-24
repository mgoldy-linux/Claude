use P21;
/*
select Top 10*
from gl
*/

/*
select distinct account_number
from gl
*/
select a.account_desc, FLOOR(g.amount/1000)[amount], g.account_number,a.account_no, a.branch_id,a.company_no, period, year_for_period
from gl g
inner join chart_of_accts a
on  g.account_number = a.account_no and g.company_no = a.company_no
WHERE (account_number LIKE '41%' or account_number LIKE '42%' or account_number LIKE '43%' or account_number LIKE '44%' or account_number LIKE '45%') and period = 3 and year_for_period = 2020
ORDER BY transaction_date desc

select a.account_desc, FLOOR(g.amount/1000)[amount], g.account_number,a.account_no, a.branch_id,a.company_no, period, year_for_period
from gl g
inner join chart_of_accts a
on  g.account_number = a.account_no and g.company_no = a.company_no
WHERE (account_number LIKE '41%' or account_number LIKE '42%' or account_number LIKE '43%' or account_number LIKE '44%' or account_number LIKE '45%') and transaction_date between '09/01/2019' and '09/30/2019'
ORDER BY transaction_date desc


select a.account_desc, FLOOR(g.amount/1000)[amount], g.account_number,a.account_no, a.branch_id,a.company_no, period, year_for_period
from gl g
inner join chart_of_accts a
on  g.account_number = a.account_no and g.company_no = a.company_no
WHERE LEFT(account_number,2) between 41 and 45 and period = 3 and year_for_period = 2020
Group By  a.account_desc, amount, g.account_number,a.account_no, a.branch_id,a.company_no, period, year_for_period

/*
select a.account_desc, FLOOR(g.amount/1000)[amount], g.account_number,a.account_no, a.branch_id,a.company_no, period, year_for_period
from gl g
inner join chart_of_accts a
on  g.account_number = a.account_no and g.company_no = a.company_no
WHERE (LEFT(account_number,2) IN(41) or LEFT(account_number,2) IN(42) or LEFT(account_number,2) IN(43) or LEFT(account_number,2) IN(44) or LEFT(account_number,2) IN(45)) and period = 3 and year_for_period = 2020
ORDER BY transaction_date desc


select FLOOR(amount/1000)[amount], account_number, period, year_for_period
from gl
WHERE account_number LIKE '43%' and period = 3 and year_for_period = 2020
ORDER BY transaction_date desc

select FLOOR(amount/1000)[amount], account_number, period, year_for_period
from gl
WHERE account_number LIKE '44%' and period = 3 and year_for_period = 2020
ORDER BY transaction_date desc

select FLOOR(amount/1000)[amount], account_number, period, year_for_period
from gl
WHERE account_number LIKE '45%' and period = 3 and year_for_period = 2020
ORDER BY transaction_date desc

select FLOOR(amount/1000)[amount], account_number, period, year_for_period
from gl
WHERE account_number LIKE '41%' and period = 3 and year_for_period = 2020
ORDER BY transaction_date desc


SELECT FLOOR(amount/1000)[amount], account_number, period, year_for_period	
FROM gl
WHERE LEFT(account_number,2) IN(41) and period = 3 and year_for_period = 2020

SELECT FLOOR(amount/1000)[amount], account_number, period, year_for_period	
FROM gl
WHERE LEFT(account_number,2) IN(42) and period = 3 and year_for_period = 2020

SELECT FLOOR(amount/1000)[amount], account_number, period, year_for_period	
FROM gl
WHERE LEFT(account_number,2) IN(43) and period = 3 and year_for_period = 2020

SELECT FLOOR(amount/1000)[amount], account_number, period, year_for_period	
FROM gl
WHERE LEFT(account_number,2) IN(44) and period = 3 and year_for_period = 2020

SELECT FLOOR(amount/1000)[amount], account_number, period, year_for_period	
FROM gl
WHERE LEFT(account_number,2) IN(45) and period = 3 and year_for_period = 2020

*/

