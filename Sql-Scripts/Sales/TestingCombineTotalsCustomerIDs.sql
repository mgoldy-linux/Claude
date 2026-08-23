 /*
	03/04/2020 - test combine monthly totals for nulls
 */
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
joinCMandCY(ccustomer_id,ccustomer_name,cproduct_group_id,cproduct_group_desc,cm_total_sales,cy_total_sales)
as
(
	select cm.customer_id,cm.customer_name,cm.product_group_id,cm.product_group_desc,cm_total_sales,cy_total_sales
	from getCurrentYr cm
	full outer join getPreviousMonth gpm
	on cm.customer_id = gpm.customer_id and cm.product_group_id = gpm.product_group_id
),
joinPMandPYR(pcustomer_id,pcustomer_name,pproduct_group_id,pproduct_group_desc,pyrmm_total_sales,pyry_total_sales)
as
(
	select gpy.customer_id,gpy.customer_name,gpy.product_group_id,gpy.product_group_desc,gpym.pyrm_total_sales,gpy.pyry_total_sales
	from getPYr gpy
	full outer join getPrevFYM gpym
	on gpy.customer_id = gpym.customer_id and gpy.product_group_id = gpym.product_group_id
)
/*
select cm.customer_id,gpm.customer_id,cm.customer_name,cm.product_group_id,cm.product_group_desc,cm_total_sales,cy_total_sales
from getCurrentYr cm
full outer join getPreviousMonth gpm
on cm.customer_id = gpm.customer_id and cm.product_group_id = gpm.product_group_id
*/
select gpy.customer_id,gpym.customer_id,gpy.customer_name,gpy.product_group_id,gpy.product_group_desc,gpym.pyrm_total_sales,gpy.pyry_total_sales
from getPYr gpy
full outer join getPrevFYM gpym
on gpy.customer_id = gpym.customer_id and gpy.product_group_id = gpym.product_group_id