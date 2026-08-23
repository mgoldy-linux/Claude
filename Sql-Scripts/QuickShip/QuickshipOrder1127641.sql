use Quickship;

select *
from Quickship.dbo.[Order]
where ErpKey = '1127641'

select *
from BOLHeader
where BOLHeaderId = 'FF71576E-E5C9-40B6-BD06-AD2C011FE0B4'

select BillingMethodMiscId,ShipToAddressId,*
from Shipment
where OrderReference = '1127641' and ReleaseIdentification = '2134950'

--ship to address
select *
from Address
where AddressId = 'B592B9CF-ACBC-4D9F-AAAF-AAFE00F10FCB'

-- bill 2 block
select TableName,RecipientLine1,RecipientLine2,AddressLine1,AddressLine2,AddressLine3,AddressLine4,City,PostalCode
from Address
where AddressId = '4D2DE90D-FFDB-4C65-9B4C-AD2C011FD728'

select *
from CustomerBilling
where BillingMethodMiscId = '777ED5AC-4A36-4A3B-ADDA-D8537C544808'  and AddressId = '4D2DE90D-FFDB-4C65-9B4C-AD2C011FD728'
