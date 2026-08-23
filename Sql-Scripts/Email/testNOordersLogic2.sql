/*
	01/24/2020 - Version 1
	01/27/2020 - Verison 2 - fix no SR & no orders
	02/03/2020 - summary all orders created for george & darin, change alignment to center
	02/06/2020 - added mmoonan@ptintl.com, add BranchID
	02/24/2020 - change Branch Id to SalesBranchID and add ShipFromID
	03/18/2020 - email from george - I am thinking the better way to sort this report (and the quote report) is by rep / then by order number.  Is it possible?
	03/19/2020 - add lmitchell@ptintl.com;rsneyd@ptintl.com per email from Darin
	07/17/2020 - add rlinke@ptintl.com and excel attachments
	**** need to find the code if the attachment doesn't exist
	07/20/2020 - one file for orders & quotes
	09/11/2020 - report be sorted by Rep/Customer Name/Order#?
	09/17/2020 - add unapprove information
	11/24/2020 - change ptintl to solveindustrial
	12/22/2020 - add logic for no orders
	04/06/2021 = remove DD
*/
Use P21Local2020;

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

If @dayNum < 10
begin
set @dayNum =  '0'  + @dayNum
end
else
begin
set @dayNum = @dayNum
end

If @sortMonth < 10
begin
set @sortDate = @yearNum + '0' + @sortMonth + @dayNum
end
else
begin
set @sortDate = @yearNum +  @sortMonth + @dayNum
end

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

set @fileNames = 'C:\SQL_Out\Orders_&_Quotes_Report_for_' + @sortDate + '.xlsx' 
-- get sum for hdrs
set @tasumorders = format(@Asumorders, '###,###,###.##')
if @Acountorders = 0
begin
set @ATotalHdr = 'No Approved Orders'
set @Subject = 'No Orders For Today'
end
else if @Acountorders = 1 
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

Select @Acountorders
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

--select @Subject = @TAcountorders + ' Orders for Total of  ' + @tasumorders + ' for ' + @fullDate

If @Acountorders != 0 or @Ucountorders != 0
Begin
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
End
Else
Begin
	set @tableHighLevel = 'Unable to find orders for today.'
End

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
Set @AtableOrders = ''
End

    Waitfor delay '00:00:05'

set @Alltables = @tableHighLevel +
	N' ' +
	@UtableOrders + 
	N' ' +
	@AtableOrders

Select @Subject[Subject], @TAcountorders[countOfOrders], @tasumorders[Sum], @fullDate[Date], @Acountorders[Approve count]
select @Alltables[all],@tableHighLevel[T-High],@UtableOrders[T-Un],@AtableOrders[t-Approve]
/*
 EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'gdib@solveindustrial.com;rlinke@solveindustrial.com',
      @copy_recipients = 'mmoonan@solveindustrial.com;lmitchell@solveindustrial.com;rsneyd@solveindustrial.com',
      @blind_copy_recipients = 'mgoldyn@solveindustrial.com',
      @reply_to = 'mgoldyn@solveindustrial.com',
      @Subject = @Subject,
      @body = @Alltables,
      @importance = 'normal',
	  @file_attachments = @fileNames,
      @body_Format = 'HTML';	
*/