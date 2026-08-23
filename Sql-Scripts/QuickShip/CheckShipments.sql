/*
CS0002400333 - UPS Shipments not showing on manifest

Normal EOD was run at 3:30 and manifest report was printed.  Shipping department then started scanning again however they changed the shipping date on QS screen to be the next day.  The orders in P21 show the the shipdate as today but with a time of 6:00.  If you print a manifest report this morning these packages do not show on there.  If unship and reship they will not show on todays manifest.  I guess the big question is when does the manifest report push up to ups and would these packages pushed up or does that actually occur when they print the manifest report?  I need to know this quick or they are going to delete these 25 packages and reprocess them from the picking ticket level, which will be a real pain.  I also need to know the proper procedure for shipping after the close day procedure has been processed.  Do they change the date in QS or do they leave the date alone?
*/
use QuickShip;

select *
from Shipment
--where OrderReference = '1128537'
where ShipmentDate between '2021-01-19' and '2021-01-21'
order by ShipmentNumber desc

select *
from Manifest
where CreateDate > '2021-01-19'-- and carrierReference2 = '4502940510'
order by ManifestNumber desc

select *
from logs