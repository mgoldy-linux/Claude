use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1086794'

select *
from Shipment
where OrderReference = '1086794' and ShipmentTrackingnumber = '1Z766E550397479208'

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

select RecipientLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select *
from CustomerBilling
where AddressId = 'F20A91AA-501D-4CCA-9B5E-AE060149E2A1'

-- not found because no BOL needed
select *
from BOLHeader
where BOLHeaderId = 'AC5D9852-1145-4749-A477-AE39013D9AD5'

select AddressLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

update Address
SET AddressLine1 =  'Avenida Rafael Estevez '
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select AddressLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select RecipientLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

update Address
SET RecipientLine1 =  'MILLER INDUSTRIES SRL '
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select RecipientLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'
