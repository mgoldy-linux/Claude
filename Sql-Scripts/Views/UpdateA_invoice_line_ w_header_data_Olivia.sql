
if OBJECT_ID ('Test_design', 'V') is not null
drop view Test_design;
go
create view [dbo].[Test_design] AS


SELECT	dbo.invoice_line.invoice_no, dbo.invoice_line.qty_requested, dbo.invoice_line.qty_shipped, dbo.invoice_line.unit_of_measure, dbo.invoice_line.item_id, dbo.invoice_line.item_desc, dbo.invoice_line.unit_price, 
		dbo.invoice_line.extended_price, dbo.invoice_line.gl_revenue_account_no, dbo.invoice_line.gl_salse_tax_account_no, dbo.invoice_line.gl_cogs, dbo.invoice_line.gl_inventory, dbo.invoice_line.date_created, 
		dbo.invoice_line.date_last_modified, dbo.invoice_line.last_maintained_by, dbo.invoice_line.order_no, dbo.invoice_line.cogs_amount, dbo.invoice_line.customer_part_number, dbo.invoice_line.company_id, 
		dbo.invoice_line.tax_item, dbo.invoice_line.line_no, dbo.invoice_line.sales_cost, dbo.invoice_line.commission_cost, dbo.invoice_line.other_cost, dbo.invoice_line.oe_line_number, dbo.invoice_line.other_charge_item, 
		dbo.invoice_line.invoice_line_uid, dbo.invoice_line.invoice_line_uid_parent, dbo.invoice_line.inv_mast_uid, dbo.invoice_line.invoice_line_type, dbo.invoice_line.product_group_id, dbo.invoice_line.created_by, 
		dbo.invoice_line.processed_flag, dbo.invoice_line.sales_discount_group_id, dbo.invoice_hdr.order_no AS Expr1, dbo.invoice_hdr.order_date, dbo.invoice_hdr.invoice_date, dbo.invoice_hdr.customer_id, 
		dbo.invoice_hdr.ship2_name, dbo.invoice_hdr.ship2_address2, dbo.invoice_hdr.ship2_address1, dbo.invoice_hdr.ship2_city, dbo.invoice_hdr.ship2_state, dbo.invoice_hdr.ship2_postal_code, dbo.invoice_hdr.salesrep_id, 
		dbo.invoice_hdr.salesrep_name, dbo.invoice_hdr.period, dbo.invoice_hdr.year_for_period, dbo.invoice_hdr.ship_date, dbo.invoice_hdr.total_amount, dbo.invoice_hdr.amount_paid, dbo.invoice_hdr.paid_in_full_flag, 
		dbo.invoice_hdr.paid_by_check_no, dbo.invoice_hdr.date_paid, dbo.invoice_hdr.company_no, dbo.invoice_hdr.corp_address_id, dbo.invoice_hdr.year_fully_paid, dbo.invoice_hdr.period_fully_paid, dbo.invoice_hdr.branch_id, 
		dbo.invoice_hdr.sold_to_customer_id, dbo.invoice_hdr.sales_location_id, dbo.contacts.id, dbo.contacts.first_name AS Rep1st, dbo.contacts.last_name AS RepLast, dbo.contacts.salesrep, dbo.contacts.sales_manager_id, 
		dbo.customer.salesrep_id AS CurrentSlsRep, dbo.customer.class_1id AS CustType, dbo.customer.class_2id AS CustGroup, dbo.customer.class_3id AS ADMember, dbo.customer.class_4id AS CustSlsCat, 
		dbo.inv_mast.class_id1 AS ItemBrand, dbo.inv_mast.class_id2 AS EPL, dbo.inv_mast.class_id3 AS IPTCISubCat, dbo.inv_mast.class_id4 AS PTISubCat, dbo.customer.customer_name, 
		dbo.inv_mast.default_sales_discount_group AS CurrSlsDiscGrp, dbo.invoice_hdr.po_no,dbo.inv_xref.their_item_id as RootPN
FROM	dbo.inv_mast RIGHT OUTER JOIN
        dbo.invoice_line ON dbo.inv_mast.inv_mast_uid = dbo.invoice_line.inv_mast_uid FULL OUTER JOIN
        dbo.customer FULL OUTER JOIN
        dbo.invoice_hdr LEFT OUTER JOIN
        dbo.contacts ON dbo.invoice_hdr.salesrep_id = dbo.contacts.id ON dbo.customer.customer_id = dbo.invoice_hdr.sold_to_customer_id ON dbo.invoice_line.invoice_no = dbo.invoice_hdr.invoice_no
		Left join dbo.inv_xref ON dbo.inv_mast.inv_mast_uid = dbo.inv_xref.inv_mast_uid and dbo.inv_xref.customer_id = 34129
