Use WQMetaData;

select [Customer Id_cached] as "Customer Id", [Customer Name_cached] as "Customer Name", [Price Library Id_cached] as "Price Library Id", [Price Library Description_cached] as "Price Library Description", [Price Book Id_cached] as "Price Book Id", [Price Book Description_cached] as "Price Book Description", [Price Page Id_cached] as "Price Page Id", [Price Page Description_cached] as "Price Page Description", [Pricing Category_cached] as "Pricing Category", [Pricing Method_cached] as "Pricing Method", [Product Group Desc_cached] as "Product Group Desc", [Multiplier_cached] as "Multiplier", [Price Page Type_cached] as "Price Page Type", [Calculator Type_cached] as "Calculator Type", [Calculation Method_cached] as "Calculation Method", [Calculation Value 01_cached] as "Calculation Value 01" 
from [webresultsets].[dbo].rwtmp_90_1737598738 
--where [Customer Id_cached] < 20000
--where [Customer Id_cached] Between 20000 and 29999
--where [Customer Id_cached] Between 30000 and 39999
--where [Customer Id_cached] Between 40000 and 49999
--where [Customer Id_cached] Between 50000 and 50999
--where [Customer Id_cached] Between 51000 and 51999
--where [Customer Id_cached] Between 52000 and 52999
--where [Customer Id_cached] Between 53000 and 53999
--where [Customer Id_cached] Between 54000 and 54999
--where [Customer Id_cached] Between 55000 and 55999
--where [Customer Id_cached] Between 56000 and 56999
where [Customer Id_cached] > 57000
group by [Customer Id_cached], [Customer Name_cached], [Price Library Id_cached], [Price Library Description_cached], [Price Book Id_cached], [Price Book Description_cached], [Price Page Id_cached], [Price Page Description_cached], [Pricing Category_cached], [Pricing Method_cached], [Product Group Desc_cached], [Multiplier_cached], [Price Page Type_cached], [Calculator Type_cached], [Calculation Method_cached], [Calculation Value 01_cached] order by [Customer Id_cached] asc, [Customer Name_cached] asc, [Price Library Id_cached] asc, [Price Library Description_cached] asc, [Price Book Id_cached] asc, [Price Book Description_cached] asc, [Price Page Id_cached] asc, [Price Page Description_cached] asc, [Pricing Category_cached] asc, [Pricing Method_cached] asc, [Product Group Desc_cached] asc, [Multiplier_cached] asc, [Price Page Type_cached] asc, [Calculator Type_cached] asc, [Calculation Method_cached] asc, [Calculation Value 01_cached] asc