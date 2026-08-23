use QuickShip;

select OrderReference[Order No.], ReleaseIdentification[Pick Ticket Number],a.RecipientLine1,c.Description,ShipmentTrackingnumber,Status,
case	
	when f.FacilityId = 'CAB2D568-57B9-4870-830A-0E5AE0EEF04A' then 'PTI'
	when f.FacilityId = 'D7B1B8DC-D428-48E0-82EE-AA4701289B19' then 'LMS'
	when f.FacilityId = '70FFB2DF-88F7-4C11-AC60-AA4701297CA5' then 'IPTCI' 
end[From Loc]
from Shipment s
join  ShipCode c
on s.ActualShipCodeId = c.ShipCodeId
join Address a
on s.ShipToAddressId = a.AddressId
join Facility f
on f.FacilityId = s.FacilityId
where year(shipmentdate) = year(getdate()) and  month(shipmentdate) = month(getdate()) and day(shipmentdate) = day(getdate())
order by ShipmentNumber desc

