/*
	01/24/2020 - Verision 1
	01/27/2020 - Verison 2 - fix no SR & no orders
	02/03/2020 - remove george, $0 lines - per email, change alignment to center
	08/11/2020 - add approved, po_no,order_date - update email address, delete summary header from body of email
	01/12/2021 - fixed gmail format, not fancy
*/
Use P21;

DECLARE @tableHighLevel NVARCHAR(MAX),
		@AtableOrders NVARCHAR(MAX),
		@UtableOrders NVARCHAR(MAX),
		@tableCustInfo NVARCHAR(MAX),
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@salesRepName as varchar(50) = ' ', -- " = ' '" key for the function to work below
		@Subject as NVARCHAR(125),
		@Acountorders as int,
		@Ucountorders as int,
		@Asumorders as Decimal(10,2), 
		@Usumorders as Decimal(10,2),
		@Alltables NVARCHAR(MAX);

-- test for orders
select @Acountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where salesrep_id = 1027 and approved = 'Y'
select @Ucountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where salesrep_id = 1027 and approved = 'N'

select @Asumorders = SUM(extended_price) from Daily_Orders_VW where  salesrep_id = 1027 and approved = 'Y'
select @Usumorders = SUM(extended_price) from Daily_Orders_VW where  salesrep_id = 1027 and approved = 'N'

if @Usumorders is null
begin
	set @Usumorders = 0
end
else
begin
	set @Usumorders = @Usumorders
end

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

Select @salesRepName += x.sr 
From
(
	Select Distinct (SalesRepName) as sr
	from [dbo].[Daily_Orders_VW] where salesrep_id = 1027
	)
as x;

if @salesRepName = ''
begin
set @salesRepName = ' Rausch Sales (1027) '
end
else 
begin
set @salesRepName = @salesRepName
end 

select @Subject = 'Daily Orders Summary for' + @salesRepName + ' for ' + @fullDate

If @Acountorders != 0 or @Ucountorders !=0
Begin
Set @tableHighLevel =
	N'<table border="1">' +
	N'<tr align="center"><th>Approved Orders</th><th>Approved Total $</th><th>Unapproved Orders</th><th>Unapproved Total $</th></tr>' +
		cast ((select td = @Acountorders, ' ',
					  td = @Asumorders, ' ',
					  td = @Ucountorders, ' ',	
					  td = @Usumorders 			
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

Set @AtableOrders =
	N'<h3><font color="#008000">Orders from previous 24 hrs</font></h3>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Customer''s Name</th><th>Ship to Name</th>' +
	N'<th>Zip Code</th><th>City, State</th><th>Order Number</th><th>Order Date</th><th>PO Number</th>' +
	N'<th>Approved</th><th>Item No.</th><th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
			cast ((select td = CompanyName,		' ',
						  td = ship2_CompanyName,	' ',
						  td = ZipCode,	    ' ',
						  td = City + ', ' + SState,	' ',
						  td = order_no,	' ',
						  td = order_date, ' ',
						  td = po_no, ' ',
						  td = approved, ' ',
						  td = customer_part_number,	' ',
						  td = item_desc,	' ',
						  td = product_group_id,	' ',
						  td = qty_ordered,	' ',
						  td = extended_price						  
			from Daily_Orders_VW where salesrep_id = 1027 and extended_price != 0 and approved = 'Y'
			order by ZipCode
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
Set @UtableOrders =
	N'<h4><font color="#FF0000">Unapproved Orders from previous 24 hrs</font></h4>' +
	N'<table border="1" BORDERCOLOR="red">' +
	N'<tr align="center"><th>Customer''s Name</th><th>Ship to Name</th>' +
	N'<th>Zip Code</th><th>City, Province</th><th>Order Number</th><th>Order Date</th><th>PO Number</th>' +
	N'<th>Approved</th><th>Item No.</th><th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
			cast ((select td = CompanyName,		' ',
						  td = ship2_CompanyName,	' ',
						  td = ZipCode,	    ' ',
						  td = City + ', ' + SState,	' ',
						  td = order_no,	' ',
						  td = order_date, ' ',
						  td = po_no, ' ',
						  td = approved, ' ',
						  td = customer_part_number,	' ',
						  td = item_desc,	' ',
						  td = product_group_id,	' ',
						  td = qty_ordered,	' ',
						  td = extended_price						  
			from Daily_Orders_VW where salesrep_id = 1027 and extended_price != 0 and approved = 'N'
			order by ZipCode
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
SET @tableHighLevel = 'Unable to find Orders for ' 
Set @UtableOrders = @fullDate 
Set @AtableOrders = '!'
End
   
if @UtableOrders is null
begin
	set @UtableOrders = ''
End
else
begin 
	set @UtableOrders =  @UtableOrders
end

set @Alltables = @tableHighLevel +
	N' ' +
	@UtableOrders +
	N' ' +
	@AtableOrders

Waitfor delay '00:00:05'

 EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'rauschco7@gmail.com',
      @copy_recipients = 'gdib@solveindustrial.com',
      @blind_copy_recipients = 'repairgroup.gmi@gmail.com;mgoldyn@solveindustrial.com',
      @reply_to = 'it@ptintl.com',
      @subject = @Subject,
      @body = @Alltables,
      @importance = 'normal',
      @body_Format = 'HTML';	
