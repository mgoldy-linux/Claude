use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1157613'

select *
from BOLHeader
where TrackingNumber = '892495242'

select *
from Shipment
where OrderReference = '1157613' and BOLHeaderId = '79DCE579-EBB5-4F54-A1CD-AD1D011907C0'

select *
from Address
where AddressId = '6A163963-C1E7-4834-9617-AD1D01194B04'

select *
from CustomerBilling
where AddressId = '6A163963-C1E7-4834-9617-AD1D01194B04'