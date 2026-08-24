-- 06/09/2022 -- for clark FIFO layer for vendor 16361

with getlayers 
as
(
	select f.qty_received,f.fifo_layer_qty[QtyOpen],f.cost,p.inv_mast_uid ,po_no,po_line_uid,item_id
	from fifo_layers f
	join po_line p
	on f.inv_mast_uid = p.inv_mast_uid and year(f.date_received) = year(p.received_date) and month(f.date_received) = month(p.received_date) and day(f.date_received) = day(p.received_date)
	join inv_mast m
	on f.inv_mast_uid = m.inv_mast_uid
)
select ap.voucher_no,ap.description[CP's Invoice NO],g.item_id,g.qty_received,QtyOpen,g.cost
from getlayers g
--where inv_mast_uid = 31669 
join apinv_line ap
on ap.inv_mast_uid = g.inv_mast_uid  and ap.po_line_uid = g.po_line_uid and ap.item_id = g.item_id
where ap.description like 'CP%'

/*
select *
from po_line
where po_no = 4004889 and inv_mast_uid = 31669

select *
from po_hdr 
where po_no = 4004889

select *
from apinv_hdr
where voucher_no = 6018760

select *
from fifo_layers
where inv_mast_uid = 31669 and document_no = 5011407

select *
from inv_tran
where document_no = 5011407

select *
from payment_detail
where voucher_no = 6018760

select *
from p21_view_check_voucherdetails
where voucher_no = 6018760

select *
from apinv_line
where voucher_no = 6018760
*/
