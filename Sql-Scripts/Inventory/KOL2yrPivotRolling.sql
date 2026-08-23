-- 01/28/2020 change to last two years

DECLARE @24Mago as varchar(10),
		@23Mago as varchar(10),
		@22Mago as varchar(10),
		@21Mago as varchar(10),
		@20Mago as varchar(10),
		@19Mago as varchar(10),
		@18Mago as varchar(10),
		@17Mago as varchar(10),
		@16Mago as varchar(10),
		@15Mago as varchar(10),
		@14Mago as varchar(10),
		@13Mago as varchar(10),
		@12Mago as varchar(10),
		@11Mago as varchar(10),
		@10Mago as varchar(10),
		@9Mago as varchar(10),
		@8Mago as varchar(10),
		@7Mago as varchar(10),
		@6Mago as varchar(10),
		@5Mago as varchar(10),
		@4Mago as varchar(10),
		@3Mago as varchar(10),
		@2Mago as varchar(10),
		@lastMonth as varchar(10),
		@currentMonth As varchar(10),
		@columns NVARCHAR(MAX),
		@query NVARCHAR(MAX);

Set @24Mago = (left(DateName(month,DATEADD(month,-24,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-24,getdate())),4))
set @23Mago = (left(datename(month,DATEADD(month,-23,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-23,getdate())),4))
set @22Mago = (left(datename(month,DATEADD(month,-22,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-22,getdate())),4))
set @21Mago = (left(datename(month,DATEADD(month,-21,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-21,getdate())),4))
set @20Mago = (left(datename(month,DATEADD(month,-20,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-20,getdate())),4))
set @19Mago = (left(datename(month,DATEADD(month,-19,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-19,getdate())),4))
set @18Mago = (left(datename(month,DATEADD(month,-18,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-18,getdate())),4))
set @17Mago = (left(datename(month,DATEADD(month,-17,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-17,getdate())),4))
set @16Mago = (left(datename(month,DATEADD(month,-16,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-16,getdate())),4))
set @15Mago = (left(datename(month,DATEADD(month,-15,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-15,getdate())),4))
set @14Mago = (left(datename(month,DATEADD(month,-14,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-14,getdate())),4))
set @13Mago = (left(datename(month,DATEADD(month,-13,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-13,getdate())),4))
set @12Mago = (left(datename(month,DATEADD(month,-12,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-12,getdate())),4))
set @11Mago = (left(datename(month,DATEADD(month,-11,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-11,getdate())),4))
set @10Mago = (left(datename(month,DATEADD(month,-10,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-10,getdate())),4))
set @9Mago = (left(datename(month,DATEADD(month,-9,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-9,getdate())),4))
set @8Mago = (left(datename(month,DATEADD(month,-8,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-8,getdate())),4))
set @7Mago = (left(datename(month,DATEADD(month,-7,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-7,getdate())),4))
set @6Mago = (left(datename(month,DATEADD(month,-6,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-6,getdate())),4))
set @5Mago = (left(datename(month,DATEADD(month,-5,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-5,getdate())),4))
set @4Mago = (left(datename(month,DATEADD(month,-4,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-4,getdate())),4))
set @3Mago = (left(datename(month,DATEADD(month,-3,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-3,getdate())),4))
set @2Mago = (left(datename(month,DATEADD(month,-2,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-2,getdate())),4))
set @lastMonth = (left(datename(month,DATEADD(month,-1,getdate())),3) + ' ' + left(DateName(YEAR,DATEADD(month,-1,getdate())),4))
set @currentMonth = (left(datename(month,getdate()),3) + ' ' + left(datename(year,getdate()),4))

set @columns = '[' + @24Mago + '],' + '[' + @23Mago + '],' + '[' + @22Mago + '],' + '[' + @21Mago + '],' + '[' + @20Mago + '],' + '[' + @19Mago + '],' +'[' + @18Mago + '],' + '[' + @17Mago + '],' + '[' + @16Mago + '],' + '[' + @15Mago + '],' + '[' + @14Mago + '],' + '[' + @13Mago + '],' + '[' + @12Mago + '],' + '[' + @11Mago + '],' + '[' + @10Mago + '],' + '[' + @9Mago + '],' + '[' + @8Mago + '],' + '[' + @7Mago + '],' + '[' + @6Mago + '],' + '[' + @5Mago + '],' + '[' + @4Mago + '],' + '[' + @3Mago + '],' + '[' + @lastMonth + '],' + '[' + @currentMonth + ']'

set @query = '	
	select *
	from (
		select il.item_id,floor(ISNULL(qty_shipped,0))[qty_shipped],(left(datename(month,invoice_date),3) + '' '' + left(datename(YEAR,invoice_date),4))[MonThYearShipped]
		from invoice_hdr h
		join invoice_line il
		on h.invoice_no = il.invoice_no
		join inv_mast im
		on il.inv_mast_uid = im.inv_mast_uid
		where Year(invoice_date) > 2018 and im.item_desc like ''KOL%''
		)
		as s
		PIVOT
		(
			SUM(qty_shipped)
			for [MonthYearShipped]
			/*in ([Jan 2019], [Feb 2019],[Mar 2019],[Apr 2019],[May 2019],[Jun 2019],[Jul 2019],[Aug 2019],[Sep 2019],[Oct 2019],[Nov 2019],[Dec 2019],[Jan 2020], [Feb 2020],[Mar 2020],[Apr 2020],[May 2020],[Jun 2020],[Jul 2020],[Aug 2020],[Sep 2020],[Oct 2020],[Nov 2020],[Dec 2020],[Jan 2021],[Feb 2021])*/
			in ( ' + @columns + ')
		)
		as Mpivot
		order by item_id
		'
		
exec sp_executesql @query