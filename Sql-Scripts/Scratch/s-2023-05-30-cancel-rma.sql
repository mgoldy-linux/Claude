Update dbo.oe_hdr
set cancel_flag = 'Y' ,completed = 'Y', profit_percent = 0
where order_no = 1397034 and rma_flag = 'Y' and rma_expiration_date < GETDATE()


Update dbo.oe_line
set cancel_flag = 'Y' ,complete = 'Y'
where order_no = 1397034 

select cancel_flag, complete,qty_allocated, extended_price
from dbo.oe_line
where order_no = 1397034