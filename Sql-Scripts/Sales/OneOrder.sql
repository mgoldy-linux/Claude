SELECT oe_hdr.order_no
       ,oe_hdr.customer_id
       ,address_b.name
       ,oe_hdr.company_id
       ,company.company_name
       ,oe_hdr.location_id
       ,address_a.name
       ,oe_hdr.address_id
       ,oe_hdr.ship_to_phone
       ,address_c.central_fax_number
       ,oe_hdr.po_no
       ,oe_hdr.job_name
       ,oe_hdr.contact_id
       ,oe_hdr.taker
       ,users.name
       ,oe_hdr.order_date
       ,oe_hdr.requested_date
       ,'Y' existing_order
       ,oe_hdr.projected_order
       ,oe_hdr.completed
       ,oe_hdr.delete_flag
       ,oe_hdr.approved
       ,oe_hdr.class_1id
       ,oe_hdr.class_2id
       ,oe_hdr.class_3id
       ,oe_hdr.class_4id
       ,oe_hdr.class_5id
       ,oe_hdr.date_created
       ,oe_hdr.date_last_modified
       ,oe_hdr.last_maintained_by
       ,oe_hdr.ship2_name
       ,oe_hdr.ship2_add1
       ,oe_hdr.ship2_add2
       ,oe_hdr.ship2_city
       ,oe_hdr.ship2_state
       ,oe_hdr.ship2_zip
       ,oe_hdr.ship2_country
       ,oe_hdr.carrier_id
       ,oe_hdr.source_location_id
       ,oe_hdr.packing_basis
       ,shipping_route.route_code
       ,oe_hdr.delivery_instructions
       ,address_d.name
       ,oe_hdr.terms
       ,' ' contact_name
       ,oe_hdr.requested_downpayment
       ,oe_hdr.downpayment_invoiced
       ,' '
       ,' '
       ,address_b.corp_address_id
       ,'N' customer
       ,ship_to.invoice_type
       ,'Y' item_exist
       ,oe_hdr.rma_flag
       ,oe_hdr.cancel_flag
       ,oe_hdr.pick_ticket_type
       ,oe_hdr.will_call
       ,oe_hdr.front_counter
       ,oe_hdr.validation_status
       ,0 year_for_period
       ,0 period
       ,oe_hdr.source_id
       ,oe_hdr.source_code_no
       ,'N' quote_complete
       ,oe_hdr.oe_hdr_uid
       ,oe_hdr.handling_charge_req_flag
       ,oe_hdr.third_party_billing_flag
       ,oe_hdr.po_no_append
       ,oe_hdr.cod_flag
       ,oe_hdr.fob_flag
       ,oe_hdr.freight_out
       ,oe_hdr.freight_code_uid
       ,freight_code.freight_cd
       ,freight_code.freight_desc
       ,oe_hdr.credit_card_hold
       ,oe_hdr.ship2_email_address
       ,address_b.url
       ,oe_hdr.shipping_route_uid
       ,'N' c_create_po
       ,oe_hdr.invoice_batch_uid
       ,invoice_batch.invoice_batch_number
       ,invoice_batch.invoice_batch_desc
       ,'Y' taxable
       ,'N' c_create_transfer
       ,oe_hdr.exclude_rebates
       ,oe_hdr.capture_usage_default
       ,'' order_disposition
       ,oe_hdr.job_price_hdr_uid
       ,' ' c_job_no
       ,' ' c_job_description
       ,'N' c_audit_trail_updated
       ,oe_hdr.front_counter_rma
       ,'N' qty_entered
       ,oe_hdr.order_cost_basis
       ,oe_hdr.profit_percent
       ,oe_hdr.order_type
       ,oe_hdr.currency_line_uid
       ,currency_line.to_currency_id
       ,oe_hdr.invoice_exch_rate_source_cd
       ,oe_hdr.rma_expiration_date
       ,p21_view_oe_hdr_rfq_control_no.control_no
       ,oe_hdr.tag_hold_cancel_date
       ,Cast(NULL AS CHAR(1)) c_usercreateship
       ,oe_hdr.restock_fee_percentage
       ,oe_hdr.date_order_completed
       ,oe_hdr.job_control_flag
       ,oe_hdr.apply_builder_allowance_flag
       ,oe_hdr.req_pymt_upon_release_flag
       ,oe_hdr.merchandise_credit_flag
       ,oe_hdr.downpayment_percentage
       ,oe_hdr.product_group_cost_basis
       ,oe_hdr.expedite_date
       ,oe_hdr.promise_date
       ,oe_hdr.original_promise_date
       ,quote_hdr.expiration_date 'quote_expiration_date'
       ,oe_hdr.landed_cost_included_cd
       ,COALESCE(oe_hdr.prepaid_invoice_flag, 'N')
       ,oe_hdr.routed_eta_date
       ,oe_hdr.route_override_date
       ,oe_hdr.promise_date_edited_date
       ,oe_hdr.promise_date_extended_desc
       ,oe_hdr.packing_list_sent_flag
       ,oe_hdr.strategic_library_uid
       ,oe_hdr.strategic_library_original_uid
       ,crm_contact_information.last_hard_touch_date
       ,crm_contact_information.activity_trans_no
       ,oe_hdr.order_priority_uid
       ,' ' salesrep_id
       ,' ' salesrep_name
       ,oe_hdr.ups_code
       ,'N' c_carrier_changed
       ,COALESCE(pegmost_oe_hdr.pump_off_flag, 'N')
       ,pegmost_oe_hdr.release_no
       ,oe_hdr.supplier_order_no
       ,oe_hdr.supplier_release_no
       ,oe_hdr.supplier_status
       ,ship_to.state_exemption_number
       ,oe_hdr.apply_fuel_surcharge_flag
       ,oe_hdr.freight_out_edited_flag
       ,oe_hdr.print_prices_on_packinglist
       ,oe_hdr.recalc_scheduled_ds_price
       ,oe_hdr.carrier_contract_hdr_uid
       ,' ' carrier_contract_hdr_desc
       ,pegmost_oe_hdr.mdr_nb
       ,pegmost_oe_hdr.drc_code
       ,pegmost_oe_hdr.vessel_nb
       ,oe_hdr.net_billing_flag
       ,oe_hdr.net_billing_edited
       ,oe_hdr.ship2_add3
       ,COALESCE(oe_hdr.electronic_order_flag, 'N')
       ,oe_hdr.hold_invoice_flag
       ,COALESCE(oe_hdr.do_not_export_to_pts_flag, 'N')
       ,COALESCE(oe_hdr.blind_ship_flag, 'N') blind_ship_flag
       ,oe_hdr.quote_type
       ,oe_hdr.pts_label_print_flag
       ,oe_hdr.order_disc_type
       ,oe_hdr.order_disc_factor
       ,oe_hdr.created_by 
       ,oe_hdr.ship2_latitude
       ,oe_hdr.ship2_longitude
      ,COALESCE(oe_hdr.exclude_from_credit_limit_flag, 'N')
      ,oe_hdr.transit_days
      ,oe_hdr.days_early
      ,pegmost_oe_hdr.pegmost_delivery_notes
      ,oe_hdr.advanced_billing_flag
      ,oe_hdr.advanced_billing_print_flag
      ,COALESCE(oe_hdr.advanced_billing_flag, 'N') existing_advanced_bill_order
/*MAIN FROM CLAUSE*/
FROM   oe_hdr
       INNER JOIN company ON (company.company_id = oe_hdr.company_id)
       INNER JOIN users ON (users.id = oe_hdr.taker)
       INNER JOIN address AS address_a ON (address_a.id = oe_hdr.location_id)
       INNER JOIN address AS address_b ON (address_b.id = oe_hdr.customer_id)
       LEFT JOIN address AS address_c ON (address_c.id = oe_hdr.address_id)
       INNER JOIN address AS address_d ON (address_d.id = oe_hdr.source_location_id)
       LEFT JOIN ship_to ON (ship_to.ship_to_id = oe_hdr.address_id)
                        AND (ship_to.customer_id = oe_hdr.customer_id)
                        AND (ship_to.company_id = oe_hdr.company_id)
       LEFT JOIN freight_code ON (freight_code.freight_code_uid = oe_hdr.freight_code_uid)
       LEFT JOIN shipping_route ON (shipping_route.shipping_route_uid = oe_hdr.shipping_route_uid)
       LEFT JOIN p21_view_oe_hdr_rfq_control_no ON p21_view_oe_hdr_rfq_control_no.oe_hdr_uid = oe_hdr.oe_hdr_uid
       INNER JOIN invoice_batch ON (invoice_batch.invoice_batch_uid = oe_hdr.invoice_batch_uid)
       INNER JOIN customer ON customer.customer_id = oe_hdr.customer_id
                          AND customer.company_id = oe_hdr.company_id
       LEFT JOIN currency_line ON (currency_line.currency_line_uid = oe_hdr.currency_line_uid)
       LEFT JOIN quote_hdr ON quote_hdr.oe_hdr_uid = oe_hdr.oe_hdr_uid
       LEFT JOIN crm_contact_information ON crm_contact_information.entity_link_id_dec = oe_hdr.customer_id
                                        AND crm_contact_information.company_id = oe_hdr.company_id
                                        AND crm_contact_information.entity_type_cd = 1203
       LEFT JOIN pegmost_oe_hdr ON pegmost_oe_hdr.oe_hdr_uid = oe_hdr.oe_hdr_uid
       LEFT JOIN carrier_contract_hdr ON carrier_contract_hdr.carrier_contract_hdr_uid = oe_hdr.carrier_contract_hdr_uid
/*MAIN WHERE CLAUSE*/
	where oe_hdr.order_no = 1040359 
/*MAIN GROUP BY CLAUSE*/
/*MAIN HAVING CLAUSE*/
/*MAIN ORDER BY CLAUSE*/
