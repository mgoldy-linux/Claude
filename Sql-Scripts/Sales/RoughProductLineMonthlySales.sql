 /*
	03/04/2020 - Product line monthly totals
	4 sales columns - Current Month (Previous Month), Current Fiscal Yr, Same Month Last Fiscal Yr, Same Time last fisal year
	The report will run 1st of the month
	product_group_id[PRD LN],product_group_desc[Product Line],total_sales[Current Sales $],[YTD Sales $],[LYTD Sales $], [LY TOT Sales $]
	03/03/2020 add is cases for when the left table column is null

	*** need totals for each group
 */
 -- get last months sales
 with getPreviousMonth(product_group_id,product_group_desc,BranchID,cm_total_sales)
 as
 (
	select product_group_id,product_group_desc,BranchID,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p = 8 and yrp = 2020
	group by product_group_id,product_group_desc,BranchID
),
-- get sales for the current fiscal year
getCurrentYr(product_group_id,product_group_desc,BranchID,cy_total_sales)
as
(
	select product_group_id,product_group_desc,BranchID,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p between 1 and 8 and yrp = 2020
	group by product_group_id,product_group_desc,BranchID
),
-- get previous year totals
getPrevFYTotals(product_group_id,product_group_desc,BranchID,pyr_total_sales)
as
(
	select product_group_id,product_group_desc,BranchID,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and yrp = 2019 
	Group by product_group_id,product_group_desc,BranchID
),
-- get previous year sales until last month
getPYr(product_group_id,product_group_desc,BranchID,pyrym_total_sales)
as
(
	select product_group_id,product_group_desc,BranchID,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p between 1 and 8 and yrp = 2019
	group by product_group_id,product_group_desc,BranchID
),
-- combine current month and year sales
joinCMandCY(cproduct_group_id,cproduct_group_desc,BranchID,cm_total_sales,cy_total_sales)
as
(
	select cm.product_group_id,cm.product_group_desc,cm.BranchID,cm_total_sales,cy_total_sales
	from getCurrentYr cm
	full outer join getPreviousMonth gpm
	on cm.product_group_id = gpm.product_group_id and cm.BranchID = gpm.BranchID
),
-- combine previous year to month and previous years totals
joinPMandPYR(pproduct_group_id,pproduct_group_desc,BranchID,pyrym_total_sales,pyr_total_sales)
as
(
	select gpy.product_group_id,gpy.product_group_desc,gpy.BranchID,gpym.pyrym_total_sales,gpy.pyr_total_sales
	from getPrevFYTotals gpy
	full outer join getPYr gpym
	on gpy.product_group_id = gpym.product_group_id and gpy.BranchID = gpym.BranchID
	)
 select case when cproduct_group_id is null then jp.pproduct_group_id
		else jc.cproduct_group_id end[Product_Group_ID],
		case when cproduct_group_desc is null then jp.pproduct_group_desc
		else jc.cproduct_group_desc end[Product_Group_Desc],
		case when jc.BranchID is null then jp.BranchID
		else jc.BranchID end [Branch_ID],
		coalesce(cm_total_sales,0)[Current Sales $],
		coalesce(cy_total_sales,0)[YTD Sales $],
		coalesce(jp.pyrym_total_sales,0)[LYTD Sales $],
		coalesce(jp.pyr_total_sales,0)[LY TOT Sales $]
from joinCMandCY jc
full outer join joinPMandPYR jp
on jc.cproduct_group_id = jp.pproduct_group_id and jc.BranchID = jp.BranchID
order by Product_Group_ID