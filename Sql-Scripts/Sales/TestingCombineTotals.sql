 /*
	03/04/2020 - testing combine totals
 */
 -- get last months sales
 with getPreviousMonth(product_group_id,product_group_desc,cm_total_sales)
 as
 (
	select product_group_id,product_group_desc,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p = 8 and yrp = 2020
	group by product_group_id,product_group_desc
),
-- get sales for the current fiscal year
getCurrentYr(product_group_id,product_group_desc,cy_total_sales)
as
(
	select product_group_id,product_group_desc,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p between 1 and 8 and yrp = 2020
	group by product_group_id,product_group_desc
),
-- get previous year totals
getPrevFYTotals(product_group_id,product_group_desc,pyr_total_sales)
as
(
	select product_group_id,product_group_desc,SUM(total_sales)
    from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and yrp = 2019 --and customer_id = 10564
	Group by product_group_id,product_group_desc
),
-- get previous year sales until last month
getPYr(product_group_id,product_group_desc,pyrym_total_sales)
as
(
	select product_group_id,product_group_desc,SUM(total_sales)
	from dLast_2_Years_Monthly_Sales
    where sr_id = 1032 and p between 1 and 8 and yrp = 2019
	group by product_group_id,product_group_desc
),
-- combine current month and year sales
joinCMandCY(cproduct_group_id,cproduct_group_desc,cm_total_sales,cy_total_sales)
as
(
	select cm.product_group_id,cm.product_group_desc,cm_total_sales,cy_total_sales
	from getCurrentYr cm
	full outer join getPreviousMonth gpm
	on cm.product_group_id = gpm.product_group_id
),
-- combine previous year to month and previous years totals
joinPMandPYR(pproduct_group_id,pproduct_group_desc,pyrym_total_sales,pyr_total_sales)
as
(
	select gpy.product_group_id,gpy.product_group_desc,gpym.pyrym_total_sales,gpy.pyr_total_sales
	from getPrevFYTotals gpy
	full outer join getPYr gpym
	on gpy.product_group_id = gpym.product_group_id
)
select *
--from joinCMandCY
from joinPMandPYR