-- Ensure Quickship is selected

select *
from ShipmentLine

select *
from OrderLine	

select *
from  [QuickShip].[dbo].[Order]

select *
from Logs
order by TimeStamp desc

select *
from ProductPackaging


--- deliveryInstructions
select * 
from Shipment
where OrderReference = '1020294'