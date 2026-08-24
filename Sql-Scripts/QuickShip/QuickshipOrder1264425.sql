-- error message missing cannot find pick ticket

use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1264425'

select ShipToAddressId,*
from Shipment
where OrderReference = '1264425' -- and ShipmentTrackingnumber = '1Z766E550397479208'

select *
from CustomerBilling
where AccountNumber = '181030'

select RecipientLine1,PostalCode,*
from Address
where AddressId = '409581E2-C29B-4BD9-9F28-AE51015BFD7D'

update Address
SET PostalCode =  '18411 '
where AddressId = '409581E2-C29B-4BD9-9F28-AE51015BFD7D'

select AddressLine1,PostalCode
from Address
where AddressId = '409581E2-C29B-4BD9-9F28-AE51015BFD7D'

-- didn't used below this
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
from CustomerBilling
where AddressId = '6AF719B1-C8D5-4415-8CE4-AE51015BFE50'

-- not found because no BOL neededselect *
from BOLHeader
where TrackingNumber = '1Z766E550397479208'

select AddressLine1,AddressLine2,city,PostalCode
from Address
where AddressId = '5E3773D2-1DF4-4BA2-A7CB-AE5500BBD370'

update Address
SET AddressLine1 =  'Avenida Rafael Estevez '
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select AddressLine1,PostalCode
from Address
where AddressId = '6AF719B1-C8D5-4415-8CE4-AE51015BFE50'

select RecipientLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

update Address
SET RecipientLine1 =  'MILLER INDUSTRIES SRL '
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select RecipientLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'
