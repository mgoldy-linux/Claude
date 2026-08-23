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
		@Date2yr as datetime,
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
	select taker[Taker],count(distinct h.order_no)[numberOfRMAs],(-1) * sum(extended_price)[Total],location_id,(left(datename(month,order_date),3) + '' '' + left(datename(YEAR,order_date),4))[MonThYearShipped]
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	join users u
	on h.taker = u.id
	where h.date_created between ''2022-01-01'' and ''2024-01-01'' and rma_flag = ''N'' and location_id in (100,410,420,430,440,450,460,470,510,520)
	group by taker,order_date,location_id
		)
		as s
		PIVOT
		(
			SUM(Total)
			for [MonthYearShipped]
			in ( ' + @columns + ')
		)
		as Mpivot
		order by Taker
		'
		
exec sp_executesql @query