-- item id, date time, amount

select distinct item_id,account_number, gl.date_last_modified,amount,invoice_no
from gl gl
join invoice_line l
on gl.source = l.invoice_no and gl.account_number = l.gl_inventory
where journal_id = 'SJ' and period = 8 and year_for_period  = 2022 and account_number in ('14010000100','14010000200','14010000300')  and invoice_line_uid_parent = 0
order by date_last_modified 

select  item_id,account_number, gl.date_last_modified,cogs_amount,invoice_no
from gl gl
join invoice_line l
on gl.source = l.invoice_no and gl.account_number = l.gl_inventory
where journal_id = 'SJ' and period = 8 and year_for_period  = 2022 and account_number in ('14010000100','14010000200','14010000300') and invoice_line_uid_parent = 0
order by date_last_modified 

select *
from gl
where source = '3185504' and account_number in ('14010000100','14010000200','14010000300')

select *
from invoice_line
where invoice_no = '3185504'