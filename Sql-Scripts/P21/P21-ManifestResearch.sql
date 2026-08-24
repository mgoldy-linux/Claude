use P21;

select *
from p21_view_manifest_order_refresh
where ShipFromSite = 100 and OrderLineDate <  '2021-09-28'
order by OrderLineDate desc

select *
from p21_view_manifest_pick_ticket_rate_shop
where ShipFromSite = 100 and ShipmentDate <  '2021-09-28'
order by ShipmentDate desc 

select *
from p21_view_manifest_pick_ticket_data
where location_id = 100 and [Shipment.DueDate] between '2021-09-26' and '2021-09-28' 

select *
from p21_view_manifest_pick_ticket_shipment_status
order by PickTicketNo desc

select *
from p21_view_manifest_refresh_ship_to

-- might be useful 
select *
from p21_view_manifest_order_release
where ReleaseDate between '2021-10-11' and '2021-10-15'