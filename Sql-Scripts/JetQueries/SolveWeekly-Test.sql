/*=(NL("SUM","A_Invoice_Line_with_Hdr_Data_Olivia","extended_price","DATASOURCE=","P21LIVE","product_group_id","<>''&<>OTHERCHG","branch_id",200,"invoice_date",'date calcs'!$D$10,"invoice_line_type","0")+NL("sum","A_oe_pick_ticket_detail_view_Olivia","EstimatedSales","DataSource=","P21LIVE","invoice_no","''","location_id","200","c_tracking_no","<>* *cancelled* *","c_ship_date",'date calcs'!$D$10,"projected_order","N","cancel_flag","N"))/1000
*/

Select sum(extended_price)/1000[sumShip]
from dbo.A_Invoice_Line_with_Hdr_Data_Olivia
where product_group_id != '' and product_group_id != 'OTHERCHG' and branch_id = 200 and invoice_date between '2023-07-01' and GetDate() and invoice_line_type= 0

Select sum(extended_price)/1000
from dbo.A_Invoice_Line_with_Hdr_Data_Olivia
where product_group_id != '' and product_group_id != 'OTHERCHG' and branch_id = 200 and invoice_date between '2022-07-01' and  GetDate() and invoice_line_type= 0

select sum(EstimatedSales)/1000[sumUNShip]
from dbo.A_oe_pick_ticket_detail_view_Olivia
where invoice_no is null and location_id = 200 and c_ship_date between '2023-07-01' and GETDATE() and  c_tracking_no is null and c_tracking_no != '*cancelled*'  and projected_order = 'N' and cancel_flag = 'N'

select sum(EstimatedSales)/1000
from dbo.A_oe_pick_ticket_detail_view_Olivia
where invoice_no is null and location_id = 200 and c_ship_date between '2022-06-01' and '2022-06-23' and  c_tracking_no is null and c_tracking_no != '*cancelled*'  and projected_order = 'N' and cancel_flag = 'N' 

-- balance section
-- =-(@NL("sum","p21_bal_view_derived_home_amts",'date calcs'!$D$28,"DataSource=","P21LIVE","period",'date calcs'!$D$26,"year_for_period",'date calcs'!$D$27,"account_no","41000*200|42000*200")/1000)

select SUM(budget_1)Plan_Budget
from p21_bal_view_derived_home_amts
where year_for_period = 2024 and account_no in (41000000100, 42000000100) and period = 1

select SUM(period_balance)Plan_Budget
from p21_bal_view_derived_home_amts
where year_for_period = 2023 and account_no in (41000000100, 42000000100) and period = 1
/*
select distinct budget_1
from p21_bal_view_derived_home_amts
where year_for_period = 2023 and period = 1
*/