select document_no, quantity,item_id,t.date_created
from inv_tran t
join inv_mast m
on t.inv_mast_uid = m.inv_mast_uid
where trans_type = 'PO' and location_id = 200 --and quantity > 0
order by t.date_created desc

select *
from inv_tran t
join invoice_line l
on t.inv_mast_uid = l.inv_mast_uid
where trans_type = 'PO' and location_id = 200
order by t.date_created desc

select *
from inv_tran
where transaction_number = '7000002'