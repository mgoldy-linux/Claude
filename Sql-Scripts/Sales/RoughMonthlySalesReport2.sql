 /*
	02/27/2020 - 2nd attempt for creating monthly sales report
	4 sales columns - Current Month (Previous Month), Current Fiscal Yr, Same Month Last Fiscal Yr, Same Time last fisal year
	The report will run 1st of the month
	customer_id[Cust #],customer_name[Customer Name],product_group_id[PRD LN],product_group_desc[Product Line],total_sales[Current Sales]
	03/03/2020 add is cases for when the left table column is null

	*** need totals for each group
 */
 Declare @startPeriod as int,
		@endPeriod as int,
		@currentYear as int,
		@fiscalYear as int,
		@prevFiscalYear as int,
		@currentMonth as int,
		@sr_id as int;

set @sr_id = 1032
set @endPeriod = 8;

 -- get last months sales
  with getPreviousMonth(customer_id,customer_name,product_group_id,product_group_desc,BranchID,cm_total_sales)
 as
 (
	select customer_id,customer_name,product_group_id,product_group_desc,BranchID,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = @sr_id and p = @endPeriod and yrp = 2020
	group by customer_id,customer_name,product_group_id,product_group_desc,BranchID
),
-- get sales for the current fiscal year
getCurrentYr(customer_id,customer_name,product_group_id,product_group_desc,BranchID,cy_total_sales)
as
(
	select customer_id,customer_name,product_group_id,product_group_desc,BranchID,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = @sr_id and p between 1 and @endPeriod and yrp = 2020
	group by customer_id,customer_name,product_group_id,product_group_desc,BranchID
),
-- get last months sales for the previous year
getPrevFYM(customer_id,customer_name,product_group_id,product_group_desc,BranchID,pyrm_total_sales)
as
(
	select customer_id,customer_name,product_group_id,product_group_desc,BranchID,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = @sr_id and p = @endPeriod and yrp = 2019 
	Group by customer_id,customer_name,product_group_id,product_group_desc,BranchID
),
-- get previous year sales until last month
getPYr(customer_id,customer_name,product_group_id,product_group_desc,BranchID,pyry_total_sales)
as
(
	select customer_id,customer_name,product_group_id,product_group_desc,BranchID,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = @sr_id and p between 1 and @endPeriod and yrp = 2019
	group by customer_id,customer_name,product_group_id,product_group_desc,BranchID
),
joinCMandCY(ccustomer_id,ccustomer_name,cproduct_group_id,cproduct_group_desc,BranchID,cm_total_sales,cy_total_sales)
as
(
	select cm.customer_id,cm.customer_name,cm.product_group_id,cm.product_group_desc,cm.BranchID,cm_total_sales,cy_total_sales
	from getCurrentYr cm
	full outer join getPreviousMonth gpm
	on cm.customer_id = gpm.customer_id and cm.product_group_id = gpm.product_group_id
),
joinPMandPYR(pcustomer_id,pcustomer_name,pproduct_group_id,pproduct_group_desc,BranchID,pyrmm_total_sales,pyry_total_sales)
as
(
	select gpy.customer_id,gpy.customer_name,gpy.product_group_id,gpy.product_group_desc,gpy.BranchID,gpym.pyrm_total_sales,gpy.pyry_total_sales
	from getPYr gpy
	full outer join getPrevFYM gpym
	on gpy.customer_id = gpym.customer_id and gpy.product_group_id = gpym.product_group_id
	)
 select case when ccustomer_id is null then jp.pcustomer_id
		else jc.ccustomer_id end[Customer_ID],
		case when ccustomer_name is null then jp.pcustomer_name
		else jc.ccustomer_name end[Customer_Name],
		case when cproduct_group_id is null then jp.pproduct_group_id
		else jc.cproduct_group_id end[Product_Group_ID],
		case when cproduct_group_desc is null then jp.pproduct_group_desc
		else jc.cproduct_group_desc end[Product_Group_Desc],
		case when jc.BranchID is null then jp.BranchID
		else jc.BranchID end[Branch ID],
		coalesce(cm_total_sales,0)[Current Month's Sales],
		coalesce(cy_total_sales,0)[Current Year's Sales],
		coalesce(jp.pyrmm_total_sales,0)[Prev Yr Month's Sales],
		coalesce(jp.pyry_total_sales,0)[Prev Year's Sales]
from joinCMandCY jc
full outer join joinPMandPYR jp
on jc.ccustomer_id = jp.pcustomer_id and jc.cproduct_group_id = jp.pproduct_group_id
--where ccustomer_id = 10534
order by Customer_ID,Product_Group_ID


