use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1237626'

select *
from Shipment
where OrderReference = '1237626' and ShipmentTrackingnumber = '1Z766E550397479208'

select *
from ShipmentHistory
where ShipmentId = '9E07334A-D55B-488E-B94D-AE32010AF85D'
order by StartDate desc

select *
from Container
where ShipmentId = '9E07334A-D55B-488E-B94D-AE32010AF85D'

select *
from ShipCode
where ShipCodeId = 'A10C3062-1269-4602-9161-AA770142A83E'

-- just the label 
select *
from ContainerCarrierLabel
where ContainerId = '528D6E8B-051B-43A4-8471-AE32010AF86B'

select *
from Address
where AddressId = '546622DE-91F5-4A45-BD0F-AE32010AF832'

select *
from CustomerBilling
where AddressId = '546622DE-91F5-4A45-BD0F-AE32010AF832'

-- not found because no BOL needed
select *
from BOLHeader
where TrackingNumber = '1Z766E550397479208'