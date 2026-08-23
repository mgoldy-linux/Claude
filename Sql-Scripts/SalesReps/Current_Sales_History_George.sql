select 
	case 
		when customer_rep_id in (1004,1028,1030,18353) then 'George Dib'
		when customer_rep_id in (1020,1022,1032,1023,10659,1033,1038,1039,1040,34446) then 'Ryan Linke' 
		when customer_rep_id in (1017,1021,1025,1026,1029,1035,34445) then 'Scott Kuhn'
		else 'UNKOWN'
		end[Sales Manager],branch_id,customer_id,customer_name,class_1id,	class_2id,Customer_rep_id,year_for_period,invoice_date,product_group_desc
		item_id,item_desc,qty_shipped,sales_price_home,po_no,ship2_name
		from dbo.aaa_sales_history_report_view_george v
		join dbo.inv_mast m
		on v.in
		where branch_id != 200 and Customer_rep_id != 1004 and Customer_rep_id != 1005 and Customer_rep_id != 1006 and product_group_desc != 'Other Charge - Non-Inventory' and invoice_date > '2022-08-01'