--DS d_ds_oe_hdr
SELECT oe_hdr.order_no,oe_hdr.customer_id,oe_hdr.order_date,oe_hdr.ship2_name,oe_hdr.ship2_add1,oe_hdr.ship2_add2,oe_hdr.ship2_city,oe_hdr.ship2_state,oe_hdr.ship2_zip
,oe_hdr.ship2_country,oe_hdr.requested_date,oe_hdr.po_no,oe_hdr.terms,oe_hdr.delete_flag,oe_hdr.completed,oe_hdr.company_id,oe_hdr.date_created,oe_hdr.date_last_modified
,oe_hdr.projected_order,oe_hdr.po_no_append,oe_hdr.location_id,oe_hdr.carrier_id,oe_hdr.address_id,oe_hdr.contact_id,COALESCE(oe_hdr.corp_address_id, address.corp_address_id) corp_address_id
,oe_hdr.class_1id,oe_hdr.class_2id,oe_hdr.class_3id,oe_hdr.class_4id,oe_hdr.class_5id,oe_hdr.rma_flag,oe_hdr.taker,oe_hdr.job_name,oe_hdr.approved,oe_hdr.source_location_id
,oe_hdr.packing_basis,shipping_route.route_code,oe_hdr.delivery_instructions,oe_hdr.pick_ticket_type,oe_hdr.requested_downpayment,oe_hdr.downpayment_invoiced,oe_hdr.cancel_flag,oe_hdr.will_call
,oe_hdr.front_counter,oe_hdr.validation_status,oe_hdr.oe_hdr_uid,oe_hdr.ship_to_phone,oe_hdr.last_maintained_by,oe_hdr.cod_flag,oe_hdr.handling_charge_req_flag,oe_hdr.fob_flag
,oe_hdr.third_party_billing_flag,oe_hdr.source_id,oe_hdr.credit_card_hold,oe_hdr.source_code_no,oe_hdr.shipping_route_uid,oe_hdr.exclude_rebates,oe_hdr.job_price_hdr_uid
,oe_hdr.invoice_exch_rate_source_cd,oe_hdr.currency_line_uid,oe_hdr.rma_expiration_date,oe_hdr.order_type,oe_hdr.invoice_no,oe_hdr.tag_hold_cancel_date,currency_line.to_currency_id,oe_hdr.date_order_completed,oe_hdr.apply_builder_allowance_flag,oe_hdr.req_pymt_upon_release_flag,oe_hdr.merchandise_credit_flag,oe_hdr.downpayment_percentage,oe_hdr.invoice_batch_uid,ship_to.invoice_type,address.name,' ' contact_name,oe_hdr.product_group_cost_basis,oe_hdr.landed_cost_included_cd,oe_hdr.prepaid_invoice_flag,oe_hdr.default_pricing_cd,oe_hdr.packing_list_sent_flag,oe_hdr.strategic_library_uid,oe_hdr.strategic_library_original_uid,oe_hdr.send_partial_order_flag,oe_hdr.use_vendor_item_terms_flag,oe_hdr.exclude_from_credit_limit_flag,oe_hdr.approved_for_ar_flag,oe_hdr.freight_out,oe_hdr.ship2_add3,oe_hdr.environmental_fee_flag,oe_hdr.admin_fee_flag,oe_hdr.supplier_order_no,oe_hdr.carrier_contract_hdr_uid,oe_hdr.promise_date,oe_hdr.original_promise_date,oe_hdr.advanced_billing_flag,oe_hdr.rental_quote_no,oe_hdr.rental_transaction_no      ,oe_hdr.rental_billing_flag        ,oe_hdr.quote_type 
FROM oe_hdr
INNER JOIN address 
ON address.id = oe_hdr.customer_id
LEFT JOIN shipping_route 
ON shipping_route.shipping_route_uid = oe_hdr.shipping_route_uid
LEFT JOIN currency_line 
ON currency_line.currency_line_uid = oe_hdr.currency_line_uid
LEFT JOIN ship_to 
ON ship_to.ship_to_id = oe_hdr.address_id        AND ship_to.customer_id = oe_hdr.customer_id        AND ship_to.company_id = oe_hdr.company_id 
WHERE oe_hdr.order_no = '1158016' AND ( (oe_hdr.delete_flag <> 'Y' ) ) 