use QuickShip;

select Distinct ShipCode.Description
from Shipment 
join ShipCode
on Shipment.ActualShipCodeId = ShipCode.ShipCodeId
where ShipmentDate between dateadd(day,datediff(day,365,GETDATE()),0) and GETDATE()

select *
from Carrier
where CarrierId = 'F11EE9CF-779A-4ABD-BBA4-05A6C2A41AF5'

select Distinct Carrier.Description
from Shipment 
join ShipCode
on Shipment.ActualShipCodeId = ShipCode.ShipCodeId
join Carrier
on ShipCode.CarrierId = Carrier.CarrierId
where ShipmentDate between dateadd(day,datediff(day,365,GETDATE()),0) and GETDATE()
