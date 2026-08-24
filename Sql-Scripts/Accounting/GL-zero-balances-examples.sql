select source,gl_uid, account_number,period, year_for_period,journal_id,amount,transaction_date,approved
from gl
where source = '5008837'
order by sequence_number

select source,gl_uid, account_number,period, year_for_period,journal_id,amount,transaction_date,approved
from gl
where source = '6014640'
order by sequence_number

select source,gl_uid, account_number,period, year_for_period,journal_id,amount,transaction_date,approved
from gl
where source = '3160146'
order by sequence_number

-- will tell what the journal id stands for
select *
from journal

-- to find account descriptions
select *
from chart_of_accts
where branch_id = 300

select *
from gl
where source = '6014640'
order by sequence_number