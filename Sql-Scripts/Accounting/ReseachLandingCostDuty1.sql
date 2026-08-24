select *
from payment_detail
where voucher_no = 6014640

select *
from p21_view_audit_trail_apinv_hdr
where key1_cd = '6014640'

select *
from apinv_hdr
where voucher_no = 6014299

select *
from landed_cost_driver
where landed_cost_driver_cd like '%TARIFF-8483.20.8040'

select *
from po_hdr
where external_po_no = 'CUC INS & NP'

select *
from po_line
where po_no = 4004458

select *
from inventory_receipts_hdr
where receipt_number = 5008837


select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,ap.invoice_no
from apinv_hdr_x_inventory_receipts b
join gl gl
on CAST(b.receipt_number as varchar(255)) = gl.source
left join apinv_hdr ap
on b.voucher_number = ap.voucher_no
where b.date_created > '2021-07-01' and gl.account_number = 14010000300 --and b.receipt_number = 5008837

select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount
	from apinv_hdr_x_inventory_receipts b
	join gl gl
	on CAST(b.receipt_number as varchar(255)) = gl.source
	where b.date_created > '2021-07-01' and gl.account_number = 14010000300

select *
from gl
where account_number = 20025000100

select *
from apinv_hdr_x_inventory_receipts
where voucher_number = 6009434