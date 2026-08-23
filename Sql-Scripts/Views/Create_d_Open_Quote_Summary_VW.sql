
use P21Local;
 
/*
if OBJECT_ID('d_Open_Quote_Summary') IS NOT NULL
drop view [d_Open_Quote_Summary];
go
create view [dbo].[d_Open_Quote_Summary] AS
*/
 
  
  with getOrderNos(SalesRepName,order_no) 
    as
    (
	    select distinct SalesRepName,order_no
	    from dWeekly_Quotes_VW
		group by SalesRepName,order_no
	    ),
    getQuoteSum(SalesRepName,Total_Value)
    as
    (
	    select SalesRepName,SUM(extended_price)
	    from dWeekly_Quotes_VW
	    group by SalesRepName
    ),
    getQuoteCount(SalesRepName,CountQuote)
    as
    (
        select SalesRepName, COUNT(order_no)
        from getOrderNos
        group by SalesRepName
    )
	select s.SalesRepName,c.CountQuote[# of Open Quotes],s.Total_Value
	from  getQuoteSum s
	join getQuoteCount c
	on s.SalesRepName = c.SalesRepName
	

	