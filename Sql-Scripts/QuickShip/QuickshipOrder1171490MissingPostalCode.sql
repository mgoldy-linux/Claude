use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1171490'

select  *
from Shipment
where OrderReference = '1171490' 

select *
from Address
where AddressId = '212E52DC-0148-47D1-8756-AE2900F5F6A2'

select *
from CustomerBilling
where CustomerBillingId = 'CD36A8DD-5C69-44FB-B3D7-AE1A015392EA'

-- fix missing postal code
select *
from Address
where AddressId = '56F18F2D-F8C0-4A73-A5E4-AE1A01539254'

update Address
set City = 'Dearborn', PostalCode = '48126'
where AddressId = '56F18F2D-F8C0-4A73-A5E4-AE1A01539254'

select *
from Address
where AddressId = '56F18F2D-F8C0-4A73-A5E4-AE1A01539254'
