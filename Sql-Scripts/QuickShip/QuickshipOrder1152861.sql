use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1152861'

select *
from Shipment
where OrderReference = '1152861' and BOLHeaderId = '0AF77172-4218-404A-BC09-AD0B00B8210F'

select *
from BOLHeader
where BOLHeaderId = '0AF77172-4218-404A-BC09-AD0B00B8210F'

select *
from Address
where AddressId = 'E7BC0482-E669-4771-9764-AD0B00B819DE'

select *
from CustomerBilling
where AddressId = 'E7BC0482-E669-4771-9764-AD0B00B819DE'


