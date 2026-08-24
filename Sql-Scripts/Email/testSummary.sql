select SalesRepName,NumberOpenOrders,TotalValue
from d_Open_Orders_Summary
where SalesRepName like '%17%' or  SalesRepName like '%26%'

select *
from d_Open_Quote_Summary
where SalesRepName like '%17%' or  SalesRepName like '%26%'