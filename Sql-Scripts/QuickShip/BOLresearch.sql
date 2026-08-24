select *
from [QuickShip].[dbo].[Order]
where PONumber = '4509425584'
order by OrderNumber desc

select *
from [QuickShip].[dbo].[Shipment]
where OrderReference = '1154378'

--B7116CEA-1EB5-4B21-8C14-AD0F00C789FC
select *
from [QuickShip].[dbo].[Manifest]
where ManifestId = '1C6294DF-116C-4ADF-B760-AD1000AC5AB8' 


select *
from Document
where Description = 'BOL'

select *
from ShipmentHistory