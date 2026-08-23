SELECT distinct gv.item_desc,gv.item_id,product_group_id
FROM dbo.p21_sales_history_report_view AS gv 
INNER JOIN dbo.customer AS c 
ON gv.customer_id = c.customer_id
join dbo.inv_mast m
on gv.inv_mast_uid = m.inv_mast_uid
WHERE (gv.company_id = '1') AND (NOT (gv.invoice_line_type = 981 OR gv.invoice_line_type = 982 OR gv.invoice_line_type = 1577 OR gv.invoice_line_type = 1719)) 
AND (gv.vendor_consigned = 'N') AND (gv.projected_order = 'N') AND (gv.detail_type IS NULL OR gv.detail_type = 0) AND
(gv.progress_bill_flag = 'N' OR gv.progress_bill_flag IS NULL) AND (gv.consignment_flag = 'N') and product_group_id != 'OTHERCHG' and invoice_date > '2018-07-01'
order by product_group_id