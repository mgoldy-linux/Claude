--- delete the detail first, *** Problem resets all data
select *
from customer_edi_trans_detail
where customer_edi_transaction_uid between 5436 and 5625

delete customer_edi_trans_detail
where customer_edi_transaction_uid between 5436 and 5625

select *
from customer_edi_trans_detail
where customer_edi_transaction_uid between 5436 and 5625

--then edi transaction 
select *
from customer_edi_transaction
where last_maintained_by = 'dbo'
order by customer_edi_transaction_uid desc

delete customer_edi_transaction
where customer_edi_transaction_uid between 5436 and 5625

select *
from customer_edi_transaction
where last_maintained_by = 'dbo'
order by customer_edi_transaction_uid desc


