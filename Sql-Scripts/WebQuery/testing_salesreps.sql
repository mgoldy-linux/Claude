select customer_name,item_id, item_desc,ShipDate,qty_shipped
from vwSalesAnalysis
where customer_name like '%FASTENAL%' and InvoiceDate > '2021-05-01'


use WQMetaData
select customer_name,item_id, item_desc,ShipDate,qty_shipped,SalesRepCust,SalesRepIDCust,SalesRepIDOrder,order_no
from vwSalesAnalysis
where invoice_no in ('3247687','3351078')

use P21;
select *
from oe_hdr_salesrep
where order_number in ('1299175','1438326')


use WQMetaData
select customer_name,item_id, item_desc,ShipDate,qty_shipped,SalesRepCust,SalesRepIDCust,SalesRepIDOrder,order_no
from vwSalesAnalysis
where customer_id = 48620
order by ShipDate desc

use WQMetaData
select top 24 customer_name,item_id, item_desc,ShipDate,qty_shipped,SalesRepCust,SalesRepIDCust,SalesRepIDOrder,order_no,customer_id,invoice_no
from vwSalesAnalysis
where customer_id like '48%'
order by ShipDate desc