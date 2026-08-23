select *
from apinv_hdr_x_inventory_receipts
where receipt_number = 5008837

select *
from apinv_hdr_x_inventory_receipts
where voucher_number = 6014299

select *
from apinv_hdr
where voucher_no = 6014299

select *
from apinv_hdr
where voucher_no = 6014640

select *
from apinv_hdr
where vendor_id = 16169 and voucher_no = 6014640

select *
from apinv_hdr
where vendor_id = 16167 and voucher_no = 6014299

select *
from apinv_line
where voucher_no = 6014299

select *
from landed_cost_driver
where supplier_id = 16167
order by date_created desc

select *
from apinv_line
where voucher_no = 6014640

select top 5 *
from gl
where amount = 7355.57

select top 5 *
from gl
where amount = -4403.61
select *
from gl_code

select *
from journal

select *
from chart_of_accts
where branch_id = 300


select source,gl_uid, account_number,period, year_for_period,journal_id,amount,transaction_date,approved
from gl
where period = 4 and year_for_period = 2022
group by source,gl_uid, account_number,period, year_for_period,journal_id,amount,transaction_date,approved
--order by sequence_number

select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.receipt_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 530400000300

select distinct account_number
from gl
where date_created > '2021-07-01' and journal_id = 'PJ'
order by account_number

select *
from gl
where account_number = 53040000300 and journal_id = 'PJ' and date_created > '2021-07-01'
order by gl_uid desc


select *
from apinv_hdr_x_inventory_receipts
where voucher_number between 6014630 and 6014640

select *
from apinv_hdr_x_inventory_receipts
where receipt_number = 5008837

select *
from gl
where account_number = 20025000300 and journal_id = 'PJ' and gl.date_created > '2021-07-01' and source = 6014640
order by gl_uid desc

select *
from apinv_hdr
where voucher_no = 6014640

select *
from apinv_line
where voucher_no = 6014640

select *
from apinv_line_x_inv_receipts_line
where receipt_number = 5008837

select *
from voucher_purchase_acct
where voucher_no = 6014640