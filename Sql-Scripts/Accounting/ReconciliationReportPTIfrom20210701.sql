-- 01-11-2022 for Lisa reconciliation report for IPTCI receipts from 07/01/2021 Fy 2022
/*
doesn't work because doesn't reference a receipt number	,
	pjDuty(receipt_number, voucher_number,period,year_for_period,journal_id,pjdAmount)
	as
	(
		select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.voucher_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 53040000300
		)
		01-12-2022  add external invoice number and gl.year_for_period = 2022
		For PTI missing landing cost
*/

with getRecords (receipt_number, voucher_number)
as
(
	select receipt_number, voucher_number
	from apinv_hdr_x_inventory_receipts
	where date_created > '2021-07-01'
),
irInventory(receipt_number, voucher_number,period,year_for_period,journal_id,Inventory,invoice_number)
as
(
	select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,ap.invoice_no
	from apinv_hdr_x_inventory_receipts b
	join gl gl
	on CAST(b.receipt_number as varchar(255)) = gl.source
	left join apinv_hdr ap
	on b.voucher_number = ap.voucher_no
	where b.date_created > '2021-07-01' and gl.account_number = 14010000100 and gl.year_for_period = 2022 and gl.period between 1 and 9

	),
	irInventoryInterim(receipt_number, voucher_number,period,year_for_period,journal_id,InventoryInterim)
	as
	(
		select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.receipt_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 14200000100
	),
	irPurchasesClearing(receipt_number, voucher_number,period,year_for_period,journal_id,PurchasesClearing)
	as
	(
		select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.receipt_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 20020000100
	),
	irInventoryinTransit(receipt_number, voucher_number,period,year_for_period,journal_id,InventoryinTransit,gl_uid)
	as
	(
		select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,gl_uid
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.receipt_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 20023000100
	),
	irLandedCost(receipt_number, voucher_number,period,year_for_period,journal_id,LandedCost,gl_uid)
	as
	(
		select receipt_number, voucher_number,gl.period,gl.year_for_period,gl.journal_id,gl.amount,gl_uid
		from apinv_hdr_x_inventory_receipts b
		join gl gl
		on CAST(b.receipt_number as varchar(255)) = gl.source
		where b.date_created > '2021-07-01' and gl.account_number = 20025000100
	)
	select distinct gr.receipt_number,gr.voucher_number,i.invoice_number,i.journal_id,i.period,i.year_for_period,i.Inventory,iii.InventoryInterim,irpc.PurchasesClearing,itt.InventoryinTransit,irlc.LandedCost
	from getRecords gr
	left join irInventory i
	on gr.receipt_number = i.receipt_number
	left join irInventoryInterim iii
	on gr.receipt_number = iii.receipt_number
	left join irPurchasesClearing irpc
	on gr.receipt_number = irpc.receipt_number
	left join irInventoryinTransit itt
	on gr.receipt_number = itt.receipt_number
	left join irLandedCost irlc
	on gr.receipt_number = irlc.receipt_number
	where i.journal_id is not null
