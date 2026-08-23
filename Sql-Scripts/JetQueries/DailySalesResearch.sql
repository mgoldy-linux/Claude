/*
=(NL("SUM","A_Invoice_Line_with_Hdr_Data_Olivia","extended_price","DATASOURCE=","P21LIVE","product_group_id","<>''&<>OTHERCHG&<>GS&<>K1&<>K1CR&<>K1SE","branch_id",100,"order_date",$G10,"invoice_line_type","0","CustSlsCat","DISTSTD")+NL("SUM","A_oe_line_with_Hdr_Data_Olivia","Open_Amt","DATASOURCE=","P21LIVE","product_group_id","<>''&<>OTHERCHG&<>GS&<>K1&<>K1CR&<>K1SE","order_date",$G10,"cancel_flag","N","projected_order","N","default_branch_id",100,"CustSlsCat","DISTSTD"))/1000

*/

select *
from A_Invoice_Line_with_Hdr_Data_Olivia
where branch_id = 100 and order_date Between '2023-03-01' and '2023-03-02' and CustSlsCat = 'DISTSTD'
order by order_date desc


select item_id[SIMG],item_desc,default_purchase_disc_group,l.stockable
from dbo.inventory_supplier isu 
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
join dbo.inv_mast m
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid and isxl.location_id = l.location_id
where supplier_id = 47614 and primary_supplier ='Y' and l.location_id = 410 and m.delete_flag = 'N' and stockable = 'Y'

select *
from inv_mast
where item_id = '2101000081'

select top 10 custSlsCat, *
from A_Invoice_Line_with_Hdr_Data_Olivia

select distinct class_4id
from customer

select *
from customer
where class_4id = 'DISTSTD' and delete_flag = 'N' and revenue_account_no like '%100'
order by last_check_date desc