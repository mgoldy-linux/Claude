select distinct branch_id,ih.invoice_no,bill2_name[customer_name],year_for_period,FORMAT(invoice_date,'yyyy-MM-dd')[invoice_date],product_group_desc,m.item_id,m.item_desc,extended_desc,qty_shipped,extended_price,po_no
from dbo.invoice_hdr ih
join dbo.invoice_line il 
on ih.invoice_no = il.invoice_no
join dbo.inv_mast m
on m.inv_mast_uid = il.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join dbo.product_group pg
on il.product_group_id = pg.product_group_id
where customer_id = 12993 and invoice_date > '2017-07-01'
order by invoice_date