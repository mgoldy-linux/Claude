/* Jet Qry
=(NL("SUM","A_Invoice_Line_with_Hdr_Data_Olivia","extended_price","DATASOURCE=","P21LIVE","product_group_id","<>''&<>OTHERCHG&<>GS&<>K1&<>K1CR&<>K1SE","branch_id",100,"order_date",$D11,"invoice_line_type","0","CustSlsCat","DISTSTD")+NL("SUM","A_oe_line_with_Hdr_Data_Olivia","Open_Amt","DATASOURCE=","P21LIVE","product_group_id","<>''&<>OTHERCHG&<>GS&<>K1&<>K1CR&<>K1SE","order_date",$D11,"cancel_flag","N","projected_order","N","default_branch_id",100,"CustSlsCat","DISTSTD"))/1000
*/

select sum(extended_price)
from A_Invoice_Line_with_Hdr_Data_Olivia
where product_group_id not in ('OTHERCHG','GS','K1','K1CR','K1SE') and branch_id = 100 and order_date = '2021-11-01' and invoice_line_type = 0 and CustSlsCat = 'DISTSTD'

select sum(Open_Amt)
from A_oe_line_with_Hdr_Data_Olivia
where product_group_id not in ('OTHERCHG','GS','K1','K1CR','K1SE') and cancel_flag = 'N' and order_date between '2021-11-01' and '2021-11-01' and projected_order = 'N' and CustSlsCat = 'DISTSTD' and default_branch_id = 100