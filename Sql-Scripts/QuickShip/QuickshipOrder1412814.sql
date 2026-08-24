--  will not transfer to quickship - look at p21_view_manifest_pick_ticket_data in P21
use Quickship;

select CurrencyCodeMiscId,FreightBillType,*
from Quickship.dbo.[Order]
where ErpKey = '1412814'

select ActualFreightCharges,BillableFreightCharges,LTLFreighted,ShipToAddressId,CustomerBillingId,ShipmentExportId,OrderReference,*
from Shipment
where OrderReference = '1293072'

select *
from ShipCode
where ShipCodeKey = '16301'

select *
from aspnet_Paths

select top 5 *
from dbo.ShipmentExport
where ShipmentExportId = '7BA8F8CA-4DF4-4C79-AC6D-AF90015C820E'

select *
from dbo.ShipmentExportDetails
order by CreateDate desc

select *
from CustomerBilling
where AccountNumber = '271E27'   -- FROM carrier file

select RecipientLine1,PostalCode,*
from Address
where AddressId = 'F57A4F07-BE5E-4E9D-A80E-AF5401562271'

select RecipientLine1,PostalCode,City,*
from Address
where AddressId = 'E73C9543-6ACF-4CDF-B01E-AF5401421EBC'


update Address
SET PostalCode =  '01001', City = 'AGAWAM'
where AddressId = 'E73C9543-6ACF-4CDF-B01E-AF5401421EBC'

select AddressLine1,PostalCode
from Address
where AddressId = '409581E2-C29B-4BD9-9F28-AE51015BFD7D'

-- didn't used below this
select *
from ShipmentHistory
where ShipmentId = '9E07334A-D55B-488E-B94D-AE32010AF85D'
order by StartDate desc

select *
from Container
where ShipmentId = '9E07334A-D55B-488E-B94D-AE32010AF85D'

select *
from ShipCode
where ShipCodeId = 'A10C3062-1269-4602-9161-AA770142A83E'

-- just the label 
select *
from ContainerCarrierLabel
where ContainerId = '528D6E8B-051B-43A4-8471-AE32010AF86B'


select *
from CustomerBilling
where CustomerBillingId = '220FFF88-F22D-4089-9028-AECF010F4407'
--where CustomerBillingId = 'CD0FB389-9B41-44A7-A8B9-AECF012EB654'  -- 220FFF88-F22D-4089-9028-AECF010F4407

-- not found because no BOL neededselect *
from BOLHeader
where TrackingNumber = '1Z766E550397479208'

select AddressLine1,AddressLine2,city,PostalCode
from Address
where AddressId = '5E3773D2-1DF4-4BA2-A7CB-AE5500BBD370'

update Address
SET AddressLine1 =  'Avenida Rafael Estevez '
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select AddressLine1,PostalCode
from Address
where AddressId = '6AF719B1-C8D5-4415-8CE4-AE51015BFE50'

select RecipientLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

update Address
SET RecipientLine1 =  'MILLER INDUSTRIES SRL '
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select RecipientLine1
from Address
where AddressId = 'CE0E3EE2-D9D5-4763-8FE0-AE320151C7A4'

select *
from country
where countryid = '4C5CF764-D43F-4270-832F-07F4F1BBA3CD'


select *
from Country
--where AlternateNames = 'PR'
order by PrimaryName desc