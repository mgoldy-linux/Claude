 /*
	02/27/2020 - 2nd attempt for creating monthly sales report
	4 sales columns - Current Month (Previous Month), Current Fiscal Yr, Same Month Last Fiscal Yr, Same Time last fisal year
	The report will run 1st of the month
	customer_id[Cust #],customer_name[Customer Name],product_group_id[PRD LN],product_group_desc[Product Line],total_sales[Current Sales]
	03/03/2020 add is cases for when the left table column is null

	*** need totals for each group - I need to understand Grouping Sets better as of 03/04/2020 will try to total through excel or powershell
 */
 use P21Play;

 -- get last months sales
 with getPreviousMonth(customer_id,customer_name,product_group_id,product_group_desc,cm_total_sales)
 as
 (
	select customer_id,customer_name,product_group_id,product_group_desc,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p = 8 and yrp = 2020
	group by customer_id,customer_name,product_group_id,product_group_desc
),
-- get sales for the current fiscal year
getCurrentYr(customer_id,customer_name,product_group_id,product_group_desc,cy_total_sales)
as
(
	select customer_id,customer_name,product_group_id,product_group_desc,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p between 1 and 8 and yrp = 2020
	group by customer_id,customer_name,product_group_id,product_group_desc
),
-- get last months sales for the previous year
getPrevFYM(customer_id,customer_name,product_group_id,product_group_desc,pyrm_total_sales)
as
(
	select customer_id,customer_name,product_group_id,product_group_desc,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p = 8 and yrp = 2019 --and customer_id = 10564
	Group by customer_id,customer_name,product_group_id,product_group_desc
),
-- get previous year sales until last month
getPYr(customer_id,customer_name,product_group_id,product_group_desc,pyry_total_sales)
as
(
	select customer_id,customer_name,product_group_id,product_group_desc,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p between 1 and 8 and yrp = 2019
	group by customer_id,customer_name,product_group_id,product_group_desc
),
-- Combine current month & year
joinCMandCY(ccustomer_id,ccustomer_name,cproduct_group_id,cproduct_group_desc,cm_total_sales,cy_total_sales)
as
(
	select cm.customer_id,cm.customer_name,cm.product_group_id,cm.product_group_desc,cm_total_sales,cy_total_sales
	from getCurrentYr cm
	full outer join getPreviousMonth gpm
	on cm.customer_id = gpm.customer_id and cm.product_group_id = gpm.product_group_id
),
-- Combine previous month & year
joinPMandPYR(pcustomer_id,pcustomer_name,pproduct_group_id,pproduct_group_desc,pyrmm_total_sales,pyry_total_sales)
as
(
	select gpy.customer_id,gpy.customer_name,gpy.product_group_id,gpy.product_group_desc,gpym.pyrm_total_sales,gpy.pyry_total_sales
	from getPYr gpy
	full outer join getPrevFYM gpym
	on gpy.customer_id = gpym.customer_id and gpy.product_group_id = gpym.product_group_id
),
-- combine current and previous year
joinCandP([Customer_ID],[Customer_Name],[Product_Group_ID],[Product_Group_Desc],[Current Month's Sales],[Current Year's Sales],[Prev Yr Month's Sales],[Prev Year's Sales])
as
(
	 select case when ccustomer_id is null then jp.pcustomer_id
			else jc.ccustomer_id end,
			case when ccustomer_name is null then jp.pcustomer_name
			else jc.ccustomer_name end,
			case when cproduct_group_id is null then jp.pproduct_group_id
			else jc.cproduct_group_id end,
			case when cproduct_group_desc is null then jp.pproduct_group_desc
			else jc.cproduct_group_desc end,
			coalesce(cm_total_sales,0),
			coalesce(cy_total_sales,0),
			coalesce(jp.pyrmm_total_sales,0),
			coalesce(jp.pyry_total_sales,0)
	from joinCMandCY jc
	full outer join joinPMandPYR jp
	on jc.ccustomer_id = jp.pcustomer_id and jc.cproduct_group_id = jp.pproduct_group_id
)
select [Customer_ID],[Customer_Name],[Product_Group_ID],[Product_Group_Desc],SUM([Current Month's Sales]) as TotalCM --,[Current Year's Sales],[Prev Yr Month's Sales],[Prev Year's Sales]
from joinCandP
group by  Rollup([Customer_ID],[Customer_Name],[Product_Group_ID],[Product_Group_Desc])
order by Customer_ID


