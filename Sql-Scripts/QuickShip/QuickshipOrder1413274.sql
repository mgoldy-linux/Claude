-- ITN - error message

use Quickship;

select CurrencyCodeMiscId,FreightBillType,*
from Quickship.dbo.[Order]
where ErpKey = '1413274'

select ActualFreightCharges,BillableFreightCharges,LTLFreighted,ShipToAddressId,CustomerBillingId,ShipmentExportId,OrderReference,*
from Shipment
where OrderReference = '1413274'