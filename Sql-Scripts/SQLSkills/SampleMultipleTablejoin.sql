select *
from sales.Customer as c
	inner join	Sales.SalesOrderHeader as soh
			on	c.CustomerID = soh.CustomerID
	inner join sales.SalesOrderDetail as sod
			on soh.SalesOrderID = sod.SalesOrderID
	-- continue on with this format