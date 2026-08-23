-- deleted duplicate  dbo.invoice_hdr.order_no AS Expr1, ih.commission_cost AS Expr2, 


SELECT        il.invoice_no, il.qty_requested, il.qty_shipped, il.unit_of_measure, il.item_id, il.item_desc, il.unit_price, 
                         il.extended_price, il.gl_revenue_account_no, il.gl_salse_tax_account_no, il.gl_cogs, il.gl_inventory, il.date_created, 
                         il.date_last_modified, il.last_maintained_by, il.order_no, il.cogs_amount, il.job_id, il.customer_part_number, 
                         il.company_id, il.tax_item, il.pricing_quantity, il.net_quantity, il.line_no, il.sales_cost, il.commission_cost, 
                         il.other_cost, il.oe_line_number, il.other_charge_item, il.exceptional_sales, il.pricing_unit, il.invoice_line_uid, 
                         il.invoice_line_uid_parent, il.inv_mast_uid, il.invoice_line_type, il.sales_unit_size, il.pricing_unit_size, il.product_group_id, 
                         il.supplier_id, il.created_by, il.job_price_line_uid, il.cost_center, il.budget_cd, il.customer_contract_uid, 
                         il.gl_applied_labor, il.labor_amount, il.one_time_price_flag, il.mac_for_special_items, il.special_purchase_qty_received, 
                         il.suggested_retail_price, il.hours_worked, il.core_price, il.environmental_fee, il.admin_fee, il.covered_extended_price, 
                         il.cost_price_page_uid, il.buyer, il.recipient, il.verified_flag, il.verified_code, il.sku_exceptional_qty, 
                         il.last_reviewed_date, il.processed_flag, il.cogs_markup_amount, il.sales_discount_group_id, il.price_family_uid, il.unit_pick_fee, 
                         il.cost_carrier_contract_line_uid, il.price_carrier_contract_line_uid, il.cost_carrier_contract_z_line_uid, il.target_price, 
                         il.tax_amount_paid_on_dp_applied, il.sent_to_carrier_date, il.net_billing_flag, il.haz_num_of_packages, il.print_part_no, 
                         il.discount_item_flag, il.distributor_funding, il.supplier_funding, il.prior_authorization_cd, il.claim_start_date, il.claim_end_date, 
                         il.gl_distributor_funding_acct_no, il.gl_supplier_funding_acct_no, il.exclude_from_edi_844_867_flag, il.other_charge_credit_rebill_flag, 
                         il.sub_invoice_no, ih.order_date, ih.invoice_date, ih.customer_id, ih.ship2_name, ih.ship2_address2, 
                         ih.ship2_address1, ih.ship2_city, ih.ship2_state, ih.ship2_postal_code, ih.salesrep_id, ih.salesrep_name, ih.period, 
                         ih.year_for_period, ih.invoice_type, ih.ship_to_id, ih.ship_date, ih.total_amount, ih.amount_paid, ih.paid_in_full_flag, 
                         ih.paid_by_check_no, ih.date_paid, ih.company_no, ih.customer_id_number, ih.corp_address_id, ih.year_fully_paid, 
                         ih.period_fully_paid, ih.branch_id, ih.sold_to_customer_id, ih.sales_location_id, ih.invoice_period, 
                         c.id, c.first_name, c.last_name, c.salesrep, c.sales_manager_id
FROM     		invoice_line il 
INNER JOIN      invoice_hdr ih
ON il.invoice_no = ih.invoice_no
LEFT OUTER JOIN contacts c 
ON ih.salesrep_id = c.id