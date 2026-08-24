/*
	01/24/2020 - Verision 1
	01/27/2020 - Verison 2 - fix no SR & no orders
	01/31/2020 - request to change email to sales@tgbindustrial.com
	02/03/2020 - remove george, $0 lines - per email, change alignment to center
	08/11/2020 - add approved, po_no,order_date - update email address, delete summary header from body of email, update high level table, add unapprove table
	09/04/2020 - add 1017, set sr to ' TGB Industrial Sales (1017,1026) '
	09/10/2020 change subject back to Daily Orders Summary for  ...
	09/17/2020 - clean up summary
	11/25/2020 - solveindustrial to solveindustrial
	12/22/2020 - add logic for no orders
	01/13/2022 - from Gdib changed for each rep such that the orders are sorted by customer name/order number
	08/01/2022 - Scott Kuhn <skuhn@bearingslimited.com> 
*/
Use P21;

DECLARE @tableHighLevel NVARCHAR(MAX),
		@AtableOrders NVARCHAR(MAX),
		@UtableOrders NVARCHAR(MAX),
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@salesRepName as varchar(100) = ' ', -- " = ' '" key for the function to work below
		@Subject as NVARCHAR(125),
		@Ucountorders as int,
		@Acountorders as int,
		@TUcountorders as varchar(5),
		@TAcountorders as varchar(5),
		@Usumorders as Decimal(10,2), 
		@Asumorders as Decimal(10,2), 
		@tusumorders as varchar(10),
		@tasumorders as varchar(10),
		@UTotalHdr as varchar(100),
		@ATotalHdr as varchar(100),
		@Alltables NVARCHAR(MAX);

-- test for orders
select @Acountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where salesrep_id in (1017,1026) and approved = 'Y' and extended_price !=0
select @Ucountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where salesrep_id in (1017,1026) and approved = 'N' and extended_price !=0
-- set text for hdr
set @TAcountorders = FORMAT(@Acountorders, '###,###,###')
set @TUcountorders = FORMAT(@Ucountorders, '###,###,###')
-- set text for sums
select @Asumorders = SUM(extended_price) from Daily_Orders_VW where approved = 'Y' and salesrep_id in (1017,1026)
set @tasumorders = '$' + FORMAT(@Asumorders, '###,###,###.##')
select @Usumorders = SUM(extended_price) from Daily_Orders_VW where approved = 'N' and salesrep_id in (1017,1026)
set @tusumorders = '$' + FORMAT(@Usumorders, '###,###,###.##')

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

Select @salesRepName += x.sr 
From
(
	Select Distinct (SalesRepName) as sr
	from [dbo].[Daily_Orders_VW] where salesrep_id = 1026 or salesrep_id = 1017 and extended_price != 0
	)
as x;

if @salesRepName = ''
begin
set @salesRepName = ' TGB Industrial Sales (1017,1026) '
end
else 
begin
set @salesRepName = ' TGB Industrial Sales (1017,1026) '
end 

-- get sum for hdrs
set @tasumorders = format(@Asumorders, '###,###,###.##')
if @Acountorders = 0
begin
set @ATotalHdr = 'No Approved Orders'
end
else if @Acountorders =1 
begin
set @ATotalHdr = @TAcountorders + ' Approved Order Total $' + @tasumorders
end 
else
begin
set @ATotalHdr = @TAcountorders + ' Approved Orders Total $' + @tasumorders
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

select @Subject = 'Daily Orders Summary for' + @salesRepName + ' for ' + @fullDate

If @Acountorders != 0 or @Ucountorders != 0
Begin
Set @tableHighLevel =
	N'<h4><font color="#282828">'+@ATotalHdr + ' & ' +  @UTotalHdr+'</font></h4>' +
	N'<table border="1">'+
	N'<tr align="center"><th>Sales Rep</th><th># Approved Orders</th><th>Total Approved</th><th># Unapproved Orders</th><th>Total Unapproved</th></tr>' +
	cast ((select "td/@align" = 'center',salesrep_id, '',
				   "td/@align" = 'center',ApproveOrders,'',
				   "td/@align" = 'center','$' + convert(Varchar,convert(money,ApproveTotals),1),'',
				   "td/@align" = 'center',OrdersUnapproved,'',
				   "td/@align" = 'center','$' + convert(Varchar,convert(money,TotalUnapprove),1)
			from Daily_Summary_Orders_VW
			where salesrep_id in (1017,1026)
			order by ApproveTotals desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End
Else
Begin
	set @tableHighLevel = 'Unable to find orders for today.'
End

-- Unapproved Table
If @Ucountorders != 0
Begin
Set @UtableOrders =
	N'<h4><font color="#FF0000">Previous 24 hrs UNAPPROVED Orders </font></h4>' +
	N'<table border="1" BORDERCOLOR="red">' +
	N'<tr align="center"><th>Salesrep ID</th><th>Customer''s Name</th><th>Order Number</th><th>Ship to Name</th>' +
	N'<th>Zip Code</th><th>City, State</th><th>Order Date</th><th>PO Number</th>' +
	N'<th>Item No.</th><th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
			cast ((select "td/@align" = 'center',salesrep_id,	'',
						  "td/@align" = 'left',CompanyName,		'',
						  "td/@align" = 'center',order_no,	'',
						  "td/@align" = 'left',ship2_CompanyName,	'',
						  "td/@align" = 'center',ZipCode,	    '',
						  "td/@align" = 'center',City + ', ' + SState,	'',
						  "td/@align" = 'center',order_date, '',
						  "td/@align" = 'center',po_no, '',
						  "td/@align" = 'left',customer_part_number,	'',
						  "td/@align" = 'left',item_desc,	'',
						  "td/@align" = 'center',product_group_id,	'',
						  "td/@align" = 'center',qty_ordered,	'',
						  "td/@align" = 'center',extended_price	
			from Daily_Orders_VW where salesrep_id IN (1017,1026) and extended_price != 0 and approved = 'N'
			order by salesrep_id,CompanyName,order_no
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
Set @UtableOrders = ''
End

-- Approved Table
if @Acountorders != 0
Begin
Set @AtableOrders =
	N'<h4><font color="#008000">Previous 24 hrs APPROVED Orders </font></h4>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Salesrep ID</th><th>Customer''s Name</th><th>Order Number</th><th>Ship to Name</th>' +
	N'<th>Zip Code</th><th>City, State</th><th>Order Date</th><th>PO Number</th>' +
	N'<th>Item No.</th><th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
			cast ((select "td/@align" = 'center',salesrep_id,	'',
						  "td/@align" = 'left',CompanyName,		'',
						  "td/@align" = 'center',order_no,	'',
						  "td/@align" = 'left',ship2_CompanyName,	'',
						  "td/@align" = 'center',ZipCode,	    '',
						  "td/@align" = 'center',City + ', ' + SState,	'',
						  "td/@align" = 'center',order_date, '',
						  "td/@align" = 'center',po_no, '',
						  "td/@align" = 'left',customer_part_number,	'',
						  "td/@align" = 'left',item_desc,	'',
						  "td/@align" = 'center',product_group_id,	'',
						  "td/@align" = 'center',qty_ordered,	'',
						  "td/@align" = 'center',extended_price	
			from Daily_Orders_VW where salesrep_id IN (1017,1026) and extended_price != 0 and approved = 'Y'
			order by salesrep_id,CompanyName,order_no
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
	N''  +
	@UtableOrders +
	N' ' +
	@AtableOrders
 EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'sales@tgbindustrial.com',
      @copy_recipients = 'gdib@solveindustrial.com;skuhn@bearingslimited.com',
      @blind_copy_recipients = 'mgoldyn@solveindustrial.com',
      @reply_to = 'it@solveindustrial.com',
      @subject = @Subject,
      @body = @Alltables,
      @importance = 'normal',
      @body_Format = 'HTML';