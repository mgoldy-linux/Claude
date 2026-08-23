Use P21Local2020;

DECLARE @dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@Acountorders as int,
		@TAcountorders as varchar(5),
		@tasumorders as varchar(10),
		@Asumorders as Decimal(10,2), 
		@ATotalHdr as varchar(100),
		@Subject as NVARCHAR(125);


-- test for orders
select @Acountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where approved = 'Y' and extended_price != 0
Select @Acountorders
--select @Ucountorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] where approved = 'N' and extended_price != 0
-- set text for hdr
set @TAcountorders = FORMAT(@Acountorders, '###,###,###')
Select @TAcountorders
--set @TUcountorders = FORMAT(@Ucountorders, '###,###,###')
-- set text for sums
select @Asumorders = SUM(extended_price) from Daily_Orders_VW where approved = 'Y'
set @tasumorders = '$' + FORMAT(@Asumorders, '###,###,###.##')
--select @Usumorders = SUM(extended_price) from Daily_Orders_VW where approved = 'N'
--set @tusumorders = '$' + FORMAT(@Usumorders, '###,###,###.##')

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

Select @Subject