-- [dbo].[ar_receipts_detail].[payment_amount]

select *
from [dbo].[ar_receipts_detail]
where payment_amount = 388.49 

-- [dbo].[audit_trail].[new_value]
select *
from dbo.audit_trail 
where new_value = '388.490000000'   

select amount,description,foreign_amount,date_created,*
from dbo.gl
where amount = 388.49 or description like '388.49%' or foreign_amount = 388.49

select *
from dbo.gl
where amount = -388.49