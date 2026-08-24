-- Case CS0004135793

select *
from counter
where id = 'vendor_edi_transaction_detail'

update counter 
set column_name = 'vendor_edi_trans_detail_uid' 
where id = 'vendor_edi_transaction_detail'

select *
from counter
where id = 'vendor_edi_transaction_detail'