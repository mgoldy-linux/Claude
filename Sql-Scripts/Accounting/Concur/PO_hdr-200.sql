use P21;
--use P21Sand;

Select '200'[Record Type],po_no[Purchase Order Number],'PO'[Policy External ID],
case
	when currency_id = 1 then 'USD'
	when currency_id = 5 then 'EUR'
	when currency_id = 6 then 'DKK'
	when currency_id = 7 then 'GBP'
	when currency_id = 8 then 'JBY'
	when currency_id = 9 then 'AUD'
	when currency_id = 10 then 'CAD'
	else 'UNK'
end[Currency Code],vendor_id[Vendor Code],vendor_id[Vendor Address Code],convert(varchar(10),order_date, 120)[Order Date],''[Name],po_desc[Description],''[Requested Delivery Date],''[Requested By],''[Payment Terms],''[Discount Terms],''[Discount Percentage],''[Tax],''[Shipping],''[Shipping Description],''[Is Test],''[Shipping Terms],''[Shipping Method],''[Needed By Date],''[Vendor Account Number],''[Status of the Purchase Order],''[Vendor Tax Identification Number],''[Provincial Tax Identification Number],''[Vat Amount 1],''[VAT Amount 2],''[VAT Rate 1],''[VAT Rate 2],''[Amount without VAT],''[Receipt Type],''[Future], ',,'[Custom],'WQTY'[ThirtyOne]
from po_hdr
where po_no in  (4013889,4013545,4013872,4013104,4013423,4012437,4013417,4012410,4013416,4013510,4013016,4013137,4011341,4013508,4013566,4013351,4012998,4013248,4013389,4013004,4013053,4013566,4012729,4013015,4013508,4013014,4013105,4013045,4011435,4012766,4013053,4011341,4013280) and delete_flag = 'N'

-- Daily Queries
select distinct po_number
from dbo.inventory_receipts_hdr irh
join dbo.inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join dbo.po_line pl
on  pl.line_no = irl.po_line_number and irh.po_number = pl.po_no
where irl.date_created between DATEADD(day, -1, GETDATE()) and DATEADD(day, 1, GETDATE()) 
order by po_number


Select '200'[Record Type],po_no[Purchase Order Number],'PO'[Policy External ID],
case
	when currency_id = 1 then 'USD'
	when currency_id = 5 then 'EUR'
	when currency_id = 6 then 'DKK'
	when currency_id = 7 then 'GBP'
	when currency_id = 8 then 'JBY'
	when currency_id = 9 then 'AUD'
	when currency_id = 10 then 'CAD'
	else 'UNK'
end[Currency Code],vendor_id[Vendor Code],vendor_id[Vendor Address Code],convert(varchar(10),order_date, 120)[Order Date],''[Name],po_desc[Description],''[Requested Delivery Date],''[Requested By],''[Payment Terms],''[Discount Terms],''[Discount Percentage],''[Tax],''[Shipping],''[Shipping Description],''[Is Test],''[Shipping Terms],''[Shipping Method],''[Needed By Date],''[Vendor Account Number],''[Status of the Purchase Order],''[Vendor Tax Identification Number],''[Provincial Tax Identification Number],''[Vat Amount 1],''[VAT Amount 2],''[VAT Rate 1],''[VAT Rate 2],''[Amount without VAT],''[Receipt Type],''[Future], ',,'[Custom],'WQTY'[ThirtyOne]
from po_hdr
