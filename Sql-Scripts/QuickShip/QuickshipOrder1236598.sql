use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1236598'

select *
from QuickShip.dbo.[Order]
where PONumber = '31436'

select *
from BOLHeader
where TrackingNumber = '148500'

select *
from Shipment
where OrderReference = '1236598' --and BOLHeaderId = '79DCE579-EBB5-4F54-A1CD-AD1D011907C0'

select *
from Address
where AddressId = '0251010D-0336-452E-8725-AE300139E69A'

select *
from CustomerBilling
where AddressId = '6A163963-C1E7-4834-9617-AD1D01194B04'

select *
from Shipment
where ReleaseIdentification = '2192315'