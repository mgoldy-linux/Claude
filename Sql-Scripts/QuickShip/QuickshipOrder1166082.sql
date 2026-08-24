use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1166082'

select *
from BOLHeader
where BOLHeaderId = 'C7530808-99C9-4370-9F7B-AD350129F375'

select BillingMethodMiscId,ShipToAddressId,*
from Shipment
where OrderReference = '1166082' and ReleaseIdentification = '2137604'

--ship to address
select TableName,RecipientLine1,RecipientLine2,AddressLine1,AddressLine2,AddressLine3,AddressLine4,City,PostalCode
from Address
where AddressId = 'D16DB840-1BE2-40C8-9DE8-ACEC00FEC34A'
/* NA for this order
-- bill 2 block
select TableName,RecipientLine1,RecipientLine2,AddressLine1,AddressLine2,AddressLine3,AddressLine4,City,PostalCode
from Address
where AddressId = '1EBEB2F8-9B70-4CEF-8774-AD2C0115D586'

select AddressId, *
from CustomerBilling
where BillingMethodMiscId = 'D0B76758-8610-46A8-B75B-7510FEE3B146'  and CarrierId = '91DC857B-D81A-43BA-A643-AA77010D8E63'
*/
