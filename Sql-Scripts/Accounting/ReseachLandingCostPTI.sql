select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,ap.invoice_no
	from apinv_hdr_x_inventory_receipts b
	join gl gl
	on CAST(b.receipt_number as varchar(255)) = gl.source
	left join apinv_hdr ap
	on b.voucher_number = ap.voucher_no 
	where b.date_created > '2021-07-01' and gl.account_number = 14010000100 and gl.year_for_period = 2022 and gl.period = 8 and branch_id = 100

select *
from apinv_hdr 
where voucher_no = 6012232