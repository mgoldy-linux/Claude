-- this data is only correct until line 11
-- order was deleted, resaon why do data returned for shipment
use Quickship;

select len(OrderNotes),*
from Quickship.dbo.[Order]
where ErpKey = '1201202'

update Quickship.dbo.[Order]
set OrderNotes = ''
where OrderId = '1583D16A-0FC3-4544-BBF9-ADBA011D1915'

select BillingMethodMiscId,ShipToAddressId,*
from Shipment
--where ReleaseIdentification like '216778%'
where OrderReference = '1201202' and ReleaseIdentification = '2157704' -- releaseidentification = pick ticket no

select *
from BOLHeader
where BOLHeaderId = 'D89BB4BE-61B1-4538-A518-AD36011701F8'

--ship to address
select TableName,RecipientLine1,RecipientLine2,AddressLine1,AddressLine2,AddressLine3,AddressLine4,City,PostalCode
from Address
where AddressId = 'DF79280B-DBDA-47AC-AD13-AB5700EE0885'

/* NA for this order
-- bill 2 block
select TableName,RecipientLine1,RecipientLine2,AddressLine1,AddressLine2,AddressLine3,AddressLine4,City,PostalCode
from Address
where AddressId = 'DF79280B-DBDA-47AC-AD13-AB5700EE0885'

select AddressId, *
from CustomerBilling
where BillingMethodMiscId = 'D0B76758-8610-46A8-B75B-7510FEE3B146'  and CarrierId = '52D9CC30-C5F0-4294-BE29-AA77011CAC2D'
*/
