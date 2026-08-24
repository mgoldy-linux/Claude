-- carrier label column looks like it matches the text file

select *
from ContainerCarrierLabel

select *
from ShipmentCarrierOption

select *
from Shipment
where OrderReference = '1143753'  -- referenceNumber -n print files = CustomerPOReference
order by ShipmentDate desc

select *
from CustomerBilling
where AccountNumber = '054939'

select *
from CarrierService
order by CreateDate desc