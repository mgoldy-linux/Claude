Use P21;

select SUM (extended_price)[sum_invoice] -- extended_price,invoice_date --
from A_Invoice_Line_with_Hdr_Data_Olivia
where product_group_id is not null and product_group_id != 'OTHERCHG' and branch_id = 200 and invoice_line_type = 0 and invoice_date between '2023-03-01' and '2023-03-14'
--year(invoice_date) = 2023 and month(invoice_date) = 3 and day(invoice_date) = 14

select SUM(EstimatedSales)[sum_sales]
from A_oe_pick_ticket_detail_view_Olivia
where invoice_no is null and location_id = 200 and c_tracking_no is null and c_tracking_no != '* *cancelled* *' and projected_order = 'N' and cancel_flag = 'N' and c_ship_date between '2023-03-01' and '2023-03-14'

--Bearings
select sum(extended_price)
from A_Invoice_Line_with_Hdr_Data_Olivia
where product_group_id != 'OTHERCHG' and product_group_id is not null and branch_id = 400 and invoice_date between '2023-03-01' and '2023-03-29' and invoice_line_type = 0

select sum(EstimatedSales)
from A_oe_pick_ticket_detail_view_Olivia

select Sum(EstimatedSales)
from A_oe_pick_ticket_detail_view_Olivia
where invoice_no is null and location_id in (410,420,430,440,450,460,470) and c_tracking_no != '* *cancelled* *' and projected_order = 'N' and cancel_flag = 'N' and c_ship_date between '2023-03-01' and '2023-03-29'

select SUM (extended_price)[sum_invoice] -- extended_price,invoice_date --
from A_Invoice_Line_with_Hdr_Data_Olivia
where product_group_id is not null and product_group_id != 'OTHERCHG' and branch_id = 511 and invoice_line_type = 0 and invoice_date between '2022-03-01' and '2022-03-14'
--year(invoice_date) = 2023 and month(invoice_date) = 3 and day(invoice_date) = 14

select *
from p21_bal_view_derived_home_amts
where period = 9 and year_for_period = 2023 and (account_no Like '41000%500' or account_no Like '42000%500')