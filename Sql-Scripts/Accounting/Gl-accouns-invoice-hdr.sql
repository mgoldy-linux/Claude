select *
from p21_gl_account_balances_view v
join invoice_hdr h
on v.account_no = h.ar_account_no and v.period = h.period and v.year_for_period = h.year_for_period and v.branch_id = h.branch_id
where account_desc= 'Accounts Receivable' and v.period = 1 and v.year_for_period = 2024 and v.branch_id = 100

select SUM(total_amount)
from invoice_hdr
where branch_id = 100 and period = 1 and year_for_period = 2024 and ar_account_no = 12010000100