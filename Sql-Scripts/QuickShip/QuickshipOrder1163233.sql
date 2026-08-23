use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1163233'

select *
from BOLHeader
where BOLHeaderId = 'D915955A-F24F-47B0-B0BE-AD2C0115DD7C'

select BillingMethodMiscId,ShipToAddressId,*
from Shipment
where OrderReference = '1163233' and ReleaseIdentification = '2134849'

--ship to address
select TableName,RecipientLine1,RecipientLine2,AddressLine1,AddressLine2,AddressLine3,AddressLine4,City,PostalCode
from Address
where AddressId = '6CC9CE9C-D05C-4123-AB9E-AD2C01158896'

-- bill 2 block
select TableName,RecipientLine1,RecipientLine2,AddressLine1,AddressLine2,AddressLine3,AddressLine4,City,PostalCode
from Address
where AddressId = '1EBEB2F8-9B70-4CEF-8774-AD2C0115D586'

select AddressId, *
from CustomerBilling
where BillingMethodMiscId = '777ED5AC-4A36-4A3B-ADDA-D8537C544808'  and CarrierId = '91DC857B-D81A-43BA-A643-AA77010D8E63'

