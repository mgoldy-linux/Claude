select receipt_number, voucher_number, *
	from apinv_hdr_x_inventory_receipts
	--where date_created > '2021-07-01'
	where receipt_number = 5010232

select *
from apinv_hdr_x_inventory_receipts 

select top 15 *
from gl
where journal_id = 'PJ'

select *
from inventory_receipts_hdr
where receipt_number = 5010232

select *
from inventory_receipts_line
where receipt_number = 5010232

select b.receipt_number, irl.inv_mast_uid,m.item_id,voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,ap.invoice_no
from apinv_hdr_x_inventory_receipts b
join gl gl
on CAST(b.receipt_number as varchar(255)) = gl.source
left join apinv_hdr ap
on b.voucher_number = ap.voucher_no
join inventory_receipts_line irl 
on b.receipt_number = irl.receipt_number
join inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
where b.date_created > '2021-07-01' and gl.account_number = 14010000300 and gl.year_for_period = 2022 and gl.period = 8 and b.receipt_number = 5010232


select *
from gl
where source = '5010232'

select linked_transaction_number,account_number,amount,source, description
from gl
where period = 8 and year_for_period = 2022 and journal_id = 'PJ' and last_maintained_by = 'SME' and description = 'LIVINGSTON INTL INC.'

select *
from apinv_hdr
where voucher_no = 6017001
 
 select *
 from apinv_line
where voucher_no = 6017001