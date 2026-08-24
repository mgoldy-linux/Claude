Use P21;

DECLARE @tableHighLevel NVARCHAR(MAX),
		@UtableOrders NVARCHAR(MAX),
		@AtableOrders NVARCHAR(MAX),
		@tableCustInfo NVARCHAR(MAX),
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@salesRepName as varchar(50) = ' ', -- " = ' '" key for the function to work below
		@Subject as NVARCHAR(125),
		@Ucountorders as int,
		@Acountorders as int,
		@TUcountorders as varchar(5),
		@TAcountorders as varchar(5),
		@Usumorders as Decimal(10,2), 
		@Asumorders as Decimal(10,2), 
		@tusumorders as varchar(10),
		@tasumorders as varchar(10),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(100),
		@sumSRordersTotal as Decimal(10,2), -- total SR orders
		@tsumSRorderTotal as varchar(10),
		@UTotalHdr as varchar(100),
		@ATotalHdr as varchar(100),
		@Alltables NVARCHAR(MAX);

-- test for orders
select @Acountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where approved = 'Y' and extended_price != 0
select @Ucountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where approved = 'N' and extended_price != 0
-- set text for hdr
set @TAcountorders = FORMAT(@Acountorders, '###,###,###')
set @TUcountorders = FORMAT(@Ucountorders, '###,###,###')
-- set text for sums
select @Asumorders = SUM(extended_price) from Daily_Orders_VW where approved = 'Y'
set @tasumorders = '$' + FORMAT(@Asumorders, '###,###,###.##')
select @Usumorders = SUM(extended_price) from Daily_Orders_VW where approved = 'N'
set @tusumorders = '$' + FORMAT(@Usumorders, '###,###,###.##')

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())
select @sortMonth = Month(GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

If @sortMonth < 10
begin
set @sortDate = @yearNum + '0' + @sortMonth + @dayNum
end
else
begin
set @sortDate = @yearNum +  @sortMonth + @dayNum
end

set @fileNames = 'C:\SQL_Out\Orders_&_Quotes_Report_for_' + @sortDate + '.xlsx' 
-- get sum for hdrs
set @tasumorders = format(@Asumorders, '###,###,###.##')
if @Acountorders = 0
begin
set @ATotalHdr = 'No Approved Orders'
set @Subject = 'No Orders For Today'
end
else if @Acountorders =1 
begin
set @ATotalHdr = @TAcountorders + ' Approved Order Total $' + @tasumorders
select @Subject = @TAcountorders + ' Orders for Total of  ' + @tasumorders + ' for ' + @fullDate
end 
else
begin
set @ATotalHdr = @TAcountorders + ' Approved Orders Total $' + @tasumorders
select @Subject = @TAcountorders + ' Orders for Total of  ' + @tasumorders + ' for ' + @fullDate
end 

-- unapprove hdr
set @tusumorders = format(@Usumorders, '###,###,###.##')
if @Ucountorders = 0
begin
set @UTotalHdr = 'No Unapproved Orders'
end
else if @Ucountorders =1 
begin
set @UTotalHdr = @TUcountorders + ' Unapproved Order Total $' + @tusumorders
end 
else
begin
set @UTotalHdr = @TUcountorders + ' Unapproved Orders Total $' + @tusumorders
end 

select salesrep_id, ApproveOrders, ApproveTotals,OrdersUnapproved,TotalUnapprove
from Daily_Summary_Orders_VW

Set @tableHighLevel =
	N'<h4><font color="#282828">'+@ATotalHdr + ' & ' +  @UTotalHdr+'</font></h4>' +
	N'<table border="1">'+
	N'<tr align="center"><th>Sales Rep</th><th># Approved Orders</th><th>Total Approved</th><th># Unapproved Orders</th><th>Total Unapproved</th></tr>' +
	cast ((select  "td/@align" = 'center',salesrep_id, '',
				   "td/@align" = 'center',ApproveOrders,'',
				   "td/@align" = 'center','$' + convert(Varchar,convert(money,ApproveTotals),1),'',
				   "td/@align" = 'center',OrdersUnapproved,'',
				   "td/@align" = 'center','$' + convert(Varchar,convert(money,TotalUnapprove),1)
			from Daily_Summary_Orders_VW
			order by ApproveTotals desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
--Unapproved Orders

If @Ucountorders != 0
Begin
Set @UtableOrders =
	N'<h4><font color="#8B0000">Orders Not Approved over the Last 24 hrs</font></h4>' +
	N'<table border="1" BORDERCOLOR="red">' +
	N'<tr align="center"><th>Salesrep ID</th><th>Customer''s Name</th><th>Zip Code</th>' +
	N'<th>City, State</th><th>Ship to Name</th><th>Order Number</th><th>Ship Loc</th><th>Item No.</th>' +
	N'<th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
		cast ((select "td/@align" = 'center',salesrep_id, '',
					  "td/@align" = 'center',CompanyName,		'',
					  "td/@align" = 'center',ZipCode,	    '',
					  "td/@align" = 'center',City + ', ' + SState,	'',
					  "td/@align" = 'center',ship2_CompanyName,	'',
					  "td/@align" = 'center',order_no,	'',
					  "td/@align" = 'center',ShipFromID,	'',
					  "td/@align" = 'center',customer_part_number,	'',
					  "td/@align" = 'center',item_desc,	'',
					  "td/@align" = 'center',product_group_id,	'',
					  "td/@align" = 'center',qty_ordered,	'',
					  "td/@align" = 'center',extended_price
			from Daily_Orders_VW where extended_price != 0 and approved = 'N'
			order by salesrep_id,CompanyName,order_no desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
Set @UtableOrders = ''
End

-- Approved Orders
if @Acountorders !=0
Begin
Set @AtableOrders =
	N'<h4><font color="#0000FF">Approved Orders over the Last 24 hrs</font></h4>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Salesrep ID</th><th>Customer''s Name</th><th>Zip Code</th>' +
	N'<th>City, State</th><th>Ship to Name</th><th>Order Number</th><th>Ship Loc</th><th>Item No.</th>' +
	N'<th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
		cast ((select "td/@align" = 'center',salesrep_id, '',
					  "td/@align" = 'center',CompanyName,		'',
					  "td/@align" = 'center',ZipCode,	    '',
					  "td/@align" = 'center',City + ', ' + SState,	'',
					  "td/@align" = 'center',ship2_CompanyName,	'',
					  "td/@align" = 'center',order_no,	'',
					  "td/@align" = 'center',ShipFromID,	'',
					  "td/@align" = 'center',customer_part_number,	'',
					  "td/@align" = 'center',item_desc,	'',
					  "td/@align" = 'center',product_group_id,	'',
					  "td/@align" = 'center',qty_ordered,	'',
					  "td/@align" = 'center',extended_price
			from Daily_Orders_VW where extended_price != 0
			order by salesrep_id,CompanyName,order_no desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
Set @AtableOrders = 'Found no orders today.'
End

    Waitfor delay '00:00:05'

set @Alltables = @tableHighLevel +
	N' ' +
	@UtableOrders + 
	N' ' +
	@AtableOrders

select @tableHighLevel,@UtableOrders,@AtableOrders

/*
 EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
     -- @recipients = 'gdib@solveindustrial.com;rlinke@solveindustrial.com',
     -- @copy_recipients = 'ddavenport@solveindustrial.com;mmoonan@solveindustrial.com;lmitchell@solveindustrial.com;rsneyd@solveindustrial.com',
      @blind_copy_recipients = 'mgoldyn@solveindustrial.com',
      @reply_to = 'mgoldyn@solveindustrial.com',
      @subject = @Subject,
      @body = @Alltables,
      @importance = 'normal',
	  --@file_attachments = @fileNames,
      @body_Format = 'HTML';	
*/
