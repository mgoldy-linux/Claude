with getRecords (receipt_number, voucher_number)
as
(
	select receipt_number, voucher_number
	from apinv_hdr_x_inventory_receipts
	where date_created > '2021-07-01'
),
	pjInventory(receipt_number,voucher_number,period,year_for_period,journal_id,Inventory,gl_uid)
	as
	(
		select receipt_number,voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,gl_uid
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.voucher_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 14010000300
	),
	pjPurchasesClearing(receipt_number, voucher_number,period,year_for_period,journal_id,PurchasesClearing,gl_uid)
	as
	(
		select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,gl_uid
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.voucher_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 20020000300
	)
	select gr.receipt_number, gr.voucher_number,coalesce(pji.journal_id,pjpc.journal_id)[journal_id],coalesce(pji.period,pjpc.period)[period],coalesce(pji.year_for_period,pjpc.year_for_period)[year_for_period],pji.Inventory,pjpc.PurchasesClearing
	from getRecords gr
	left join pjInventory pji
	on gr.receipt_number = pji.receipt_number
	left join pjPurchasesClearing pjpc
	on gr.receipt_number = pjpc.receipt_number
	where pji.journal_id is not null
	order by gr.receipt_number