/*
email dated: Wed 10/21/2020 10:50 AM
Can you change the coding on this report for my version where it excludes the following:

Branch ID = 200
Customer_rep_id = 1004, 1005 or 1006
Product_Group_Desc = Other Charge - Non-Inventory

Can you add a field as follows?

Sales Manager = Ryan Linke, George Dib

If you can add that one, then it will cover the first 2 exclusions listed above for branch ID and customer rep ID.
*/

select case when customer_rep_id in (1017,1021,1025,1026,1027,1028,1029,1030,1031,1035,18353) then 'George Dib'
else 'Ryan Linke' end[Sales Manager],*
from aaa_sales_history_report_view_george
where branch_id != 200 and Customer_rep_id != 1004 and Customer_rep_id != 1005 and Customer_rep_id != 1006 and product_group_desc != 'Other Charge - Non-Inventory'