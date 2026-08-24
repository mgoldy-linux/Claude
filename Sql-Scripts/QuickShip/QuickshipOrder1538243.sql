use Quickship-Test;

select *
from Quickship.dbo.[Order]
where ErpKey = '1538243'

select *
from Shipment
where OrderReference = '1538243' and ReleaseIdentification = '2132896'

select *
from BOLHeader
where BOLHeaderId = 'A478D8B8-6EFE-4DA1-A715-AD240120C84D'



select *
from Address
where AddressId = '8154F7E7-42AE-44A1-8B79-AD2401208088'

select *
from CustomerBilling
where BillingMethodMiscId = '73A68A2B0-3531-49A7-A61D-8C2A9F00A509'

