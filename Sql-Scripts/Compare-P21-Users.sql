-- Compare-P21-Users.sql
-- Side-by-side comparison of two P21 users using the full User Maintenance field set.
-- Run against: P21 Prod (read-only)
-- 2026-06-15
--
-- Change @UserA / @UserB to compare any two users.
-- Results return as two rows; sort/freeze the id column in SSMS to compare.

USE P21;
GO

DECLARE @UserA VARCHAR(50) = 'THALL';
DECLARE @UserB VARCHAR(50) = 'MREDMOND';

-- ============================================================
-- 1. Full User Maintenance field set - one row per user
-- ============================================================
PRINT '--- 1. Full profile - all User Maintenance fields ---';

SELECT
     users.id
    ,users.name
    ,users.date_created
    ,users.date_last_modified
    ,users.last_maintained_by
    ,users.active
    ,users.delete_flag
    ,users.language_id
    ,users.default_company
    ,users.default_branch
    ,company.company_name
    ,branch.branch_description
    ,users.create_customers
    ,users.create_ship_tos
    ,users.default_location_id
    ,address_a.name                              AS default_location_name
    ,users.prompt_before_clearing
    ,users.system_security
    ,users.company_security
    ,users.window_security
    ,users.remote_user
    ,users.default_customer_id
    ,address_b.name                              AS default_customer_name
    ,users.create_items_at_oe
    ,pc_user_def.profile_skey
    ,pc_user_def.first_name                      AS pc_first_name
    ,pc_user_def.mi                              AS pc_mi
    ,pc_user_def.last_name                       AS pc_last_name
    ,pc_user_def.user_skey
    ,pc_user_def.user_id                         AS pc_user_id
    ,users.default_application
    ,pc_user_def.active_ind
    ,users.script_path
    ,users.role_uid
    ,users.designer_rights
    ,users.create_po_from_oe
    ,users.contact_id
    ,contacts.first_name                         AS contact_first_name
    ,contacts.mi                                 AS contact_mi
    ,contacts.last_name                          AS contact_last_name
    ,users.print_preview_zoom_percentage
    ,users.email_address
    ,users.auto_generate_transfer_in_oe
    ,users.receive_system_alerts
    ,users.default_quote_order
    ,users.link_stock_item_to_po
    ,users.historical_cost_in_sales_hist
    ,users.order_cost_basis_order_cost
    ,users.order_cost_basis_comm_cost
    ,users.order_cost_basis_other_cost
    ,users.default_costing_basis
    ,users.default_to_advanced_search
    ,users.adj_qty_available_at_oe
    ,users.create_vendor_rfq_cd
    ,users.update_cost_from_rfq_receipt
    ,users.task_visibility_cd
    ,users.time_zone_cd
    ,users.display_transaction_tasks
    ,users.allow_nonstock_tbo
    ,users.create_contract_from_oe
    ,users.mgmt_allow_branch_edit
    ,users.mgmt_use_default_branch
    ,users.cnvrt_prospect_to_customer_oe
    ,users.auto_display_rooms
    ,users.default_label_printer
    ,users.display_purchaseprice_breaks
    ,users.default_item_search
    ,users.default_salesrep_on_order
    ,users.default_rep_on_comm_rpt_flag
    ,contacts_salesrep.first_name                AS cc_salesrep_first_name
    ,contacts_salesrep.mi                        AS cc_salesrep_mi
    ,contacts_salesrep.last_name                 AS cc_salesrep_last_name
    ,users.prev_requests_search
    ,users.bypass_check_verify_password
    ,users.view_cost_on_oe_line
    ,users.machine_name
    ,users.sales_supervisor_flag
    ,users.doe_salesrep_id
    ,users.vacation_end_date
    ,contacts_doe_salesrep.first_name            AS cc_doe_salesrep_first_name
    ,contacts_doe_salesrep.mi                    AS cc_doe_salesrep_mi
    ,contacts_doe_salesrep.last_name             AS cc_doe_salesrep_last_name
    ,users.doe_user_flag
    ,users.vacation_end_date_mod_flag
    ,users.users_uid
    ,COALESCE(users.use_po_approval_threshold_flag, 'N') AS use_po_approval_threshold_flag
    ,users.po_approval_threshold
    ,users.search_item_catalog_flag
    ,users.clear_item_catalog_flag
    ,users.make_items_sellable_in_oe_flag
    ,users.add_item_locations_in_oe_flag
    ,COALESCE(users.confirm_dea_pt_flag, 'N')    AS confirm_dea_pt_flag
    ,users.strategic_pricing_role_uid
    ,users.field_chooser_perm_cd
    ,users.customer_profit_role_uid
    ,users.display_open_quote_lines_cd
    ,COALESCE(users.default_send_to_outlook_flag, 'N') AS default_send_to_outlook_flag
    ,users.create_items_at_soe
    ,users.restricted_class_override_flag
    ,CASE WHEN system_setting.value = 'Y'
          THEN COALESCE(users.show_ar_cc_failed, 'Y')
          ELSE users.show_ar_cc_failed
     END                                         AS show_ar_cc_failed
    ,CASE WHEN system_setting.value = 'Y'
          THEN COALESCE(users.show_cc_payment_acct_on_save, 300)
          ELSE users.show_cc_payment_acct_on_save
     END                                         AS show_cc_payment_acct_on_save
    ,users.override_cust_pallet_warn_flag
    ,users.view_vendor_type_cd
    ,users.logo_path_filename
    ,users.over_redeem_rewards_flag
    ,users.user_report_path
    ,users.add_customer_part_number_in_oe
    ,users.fedex_label_printer_path
    ,users.default_item_search_in_imi
    ,users.po_threshold_currency_id
    ,users.allow_add_labor_to_completed_po
    ,users.do_not_export_carrier_po_flag
    ,users.allow_postprint_edit_labor_est
    ,users.network_name
    ,users.order_cost_basis_rebate_cost
    ,users.user_signature_path
    ,NULL                                        AS default_look_ahead_days_cd
    ,users.imi_default_user_location
    ,users.oe_change_customer_with_items
    ,users.allow_edit_labor_time_entry
    ,users.email_signature
    ,users.show_cc_on_save_cash_receipts
    ,users.p21_client_log_path
    ,users.enterprise_search_url
    ,users.allow_report_creation_in_studio
    ,users_ud.ar_terr
    ,users_ud.claims_terr
    ,users_ud.job_title
    ,users_ud.ops_region
    ,COALESCE(users_ud.power_bi_user, 'N')       AS power_bi_user
    ,users_ud.price_family_id
    ,users_ud.sales_region
    ,users_ud.salesrep_id
    ,users_ud.user_description
    ,users_ud.users_ud_uid
FROM users
INNER JOIN pc_user_def          ON pc_user_def.user_id         = users.id
LEFT JOIN  branch               ON branch.branch_id            = users.default_branch
                                AND branch.company_id          = users.default_company
LEFT JOIN  company              ON company.company_id          = users.default_company
LEFT JOIN  address AS address_a ON address_a.id                = users.default_location_id
LEFT JOIN  address AS address_b ON address_b.id                = users.default_customer_id
LEFT JOIN  contacts             ON contacts.id                 = users.contact_id
LEFT JOIN  contacts AS contacts_salesrep
                                ON contacts_salesrep.id        = users.default_salesrep_on_order
LEFT JOIN  contacts AS contacts_doe_salesrep
                                ON contacts_doe_salesrep.id    = users.doe_salesrep_id
LEFT JOIN  system_setting       ON system_setting.name         = 'use_credit_card'
LEFT JOIN  users_ud             ON users_ud.id                 = users.id
WHERE users.id IN (@UserA, @UserB)
ORDER BY users.id;

-- ============================================================
-- 2. Fields that DIFFER between the two users
--    Unpivots the varchar-castable fields for a clean diff view.
-- ============================================================
PRINT '--- 2. Fields that differ ---';

WITH base AS (
    SELECT
         users.id
        ,CAST(users.active                                          AS VARCHAR(200)) AS active
        ,CAST(users.delete_flag                                     AS VARCHAR(200)) AS delete_flag
        ,CAST(users.default_company                                 AS VARCHAR(200)) AS default_company
        ,CAST(users.default_branch                                  AS VARCHAR(200)) AS default_branch
        ,CAST(users.default_location_id                             AS VARCHAR(200)) AS default_location_id
        ,CAST(users.system_security                                 AS VARCHAR(200)) AS system_security
        ,CAST(users.company_security                                AS VARCHAR(200)) AS company_security
        ,CAST(users.window_security                                 AS VARCHAR(200)) AS window_security
        ,CAST(users.remote_user                                     AS VARCHAR(200)) AS remote_user
        ,CAST(users.role_uid                                        AS VARCHAR(200)) AS role_uid
        ,CAST(users.designer_rights                                 AS VARCHAR(200)) AS designer_rights
        ,CAST(users.create_customers                                AS VARCHAR(200)) AS create_customers
        ,CAST(users.create_ship_tos                                 AS VARCHAR(200)) AS create_ship_tos
        ,CAST(users.create_items_at_oe                              AS VARCHAR(200)) AS create_items_at_oe
        ,CAST(users.create_po_from_oe                               AS VARCHAR(200)) AS create_po_from_oe
        ,CAST(users.create_items_at_soe                             AS VARCHAR(200)) AS create_items_at_soe
        ,CAST(users.create_contract_from_oe                         AS VARCHAR(200)) AS create_contract_from_oe
        ,CAST(users.default_application                             AS VARCHAR(200)) AS default_application
        ,CAST(users.default_costing_basis                           AS VARCHAR(200)) AS default_costing_basis
        ,CAST(users.default_quote_order                             AS VARCHAR(200)) AS default_quote_order
        ,CAST(users.default_item_search                             AS VARCHAR(200)) AS default_item_search
        ,CAST(users.default_to_advanced_search                      AS VARCHAR(200)) AS default_to_advanced_search
        ,CAST(users.default_salesrep_on_order                       AS VARCHAR(200)) AS default_salesrep_on_order
        ,CAST(users.default_rep_on_comm_rpt_flag                    AS VARCHAR(200)) AS default_rep_on_comm_rpt_flag
        ,CAST(users.default_customer_id                             AS VARCHAR(200)) AS default_customer_id
        ,CAST(users.default_label_printer                           AS VARCHAR(200)) AS default_label_printer
        ,CAST(users.historical_cost_in_sales_hist                   AS VARCHAR(200)) AS historical_cost_in_sales_hist
        ,CAST(users.link_stock_item_to_po                           AS VARCHAR(200)) AS link_stock_item_to_po
        ,CAST(users.adj_qty_available_at_oe                         AS VARCHAR(200)) AS adj_qty_available_at_oe
        ,CAST(users.allow_nonstock_tbo                              AS VARCHAR(200)) AS allow_nonstock_tbo
        ,CAST(users.view_cost_on_oe_line                            AS VARCHAR(200)) AS view_cost_on_oe_line
        ,CAST(users.sales_supervisor_flag                           AS VARCHAR(200)) AS sales_supervisor_flag
        ,CAST(users.doe_user_flag                                   AS VARCHAR(200)) AS doe_user_flag
        ,CAST(users.doe_salesrep_id                                 AS VARCHAR(200)) AS doe_salesrep_id
        ,CAST(users.mgmt_allow_branch_edit                          AS VARCHAR(200)) AS mgmt_allow_branch_edit
        ,CAST(users.mgmt_use_default_branch                         AS VARCHAR(200)) AS mgmt_use_default_branch
        ,CAST(users.receive_system_alerts                           AS VARCHAR(200)) AS receive_system_alerts
        ,CAST(users.task_visibility_cd                              AS VARCHAR(200)) AS task_visibility_cd
        ,CAST(users.time_zone_cd                                    AS VARCHAR(200)) AS time_zone_cd
        ,CAST(users.display_transaction_tasks                       AS VARCHAR(200)) AS display_transaction_tasks
        ,CAST(users.strategic_pricing_role_uid                      AS VARCHAR(200)) AS strategic_pricing_role_uid
        ,CAST(users.customer_profit_role_uid                        AS VARCHAR(200)) AS customer_profit_role_uid
        ,CAST(users.field_chooser_perm_cd                           AS VARCHAR(200)) AS field_chooser_perm_cd
        ,CAST(users.restricted_class_override_flag                  AS VARCHAR(200)) AS restricted_class_override_flag
        ,CAST(users.over_redeem_rewards_flag                        AS VARCHAR(200)) AS over_redeem_rewards_flag
        ,CAST(COALESCE(users.use_po_approval_threshold_flag,'N')    AS VARCHAR(200)) AS use_po_approval_threshold_flag
        ,CAST(users.po_approval_threshold                           AS VARCHAR(200)) AS po_approval_threshold
        ,CAST(users.search_item_catalog_flag                        AS VARCHAR(200)) AS search_item_catalog_flag
        ,CAST(users.make_items_sellable_in_oe_flag                  AS VARCHAR(200)) AS make_items_sellable_in_oe_flag
        ,CAST(users.add_item_locations_in_oe_flag                   AS VARCHAR(200)) AS add_item_locations_in_oe_flag
        ,CAST(COALESCE(users.confirm_dea_pt_flag,'N')               AS VARCHAR(200)) AS confirm_dea_pt_flag
        ,CAST(COALESCE(users.default_send_to_outlook_flag,'N')      AS VARCHAR(200)) AS default_send_to_outlook_flag
        ,CAST(users.display_purchaseprice_breaks                    AS VARCHAR(200)) AS display_purchaseprice_breaks
        ,CAST(users.display_open_quote_lines_cd                     AS VARCHAR(200)) AS display_open_quote_lines_cd
        ,CAST(users.view_vendor_type_cd                             AS VARCHAR(200)) AS view_vendor_type_cd
        ,CAST(users.bypass_check_verify_password                    AS VARCHAR(200)) AS bypass_check_verify_password
        ,CAST(users.allow_add_labor_to_completed_po                 AS VARCHAR(200)) AS allow_add_labor_to_completed_po
        ,CAST(users.do_not_export_carrier_po_flag                   AS VARCHAR(200)) AS do_not_export_carrier_po_flag
        ,CAST(users.allow_postprint_edit_labor_est                  AS VARCHAR(200)) AS allow_postprint_edit_labor_est
        ,CAST(users.add_customer_part_number_in_oe                  AS VARCHAR(200)) AS add_customer_part_number_in_oe
        ,CAST(users.cnvrt_prospect_to_customer_oe                   AS VARCHAR(200)) AS cnvrt_prospect_to_customer_oe
        ,CAST(users.override_cust_pallet_warn_flag                  AS VARCHAR(200)) AS override_cust_pallet_warn_flag
        ,CAST(users.allow_edit_labor_time_entry                     AS VARCHAR(200)) AS allow_edit_labor_time_entry
        ,CAST(users.language_id                                     AS VARCHAR(200)) AS language_id
        ,CAST(users_ud.ar_terr                                      AS VARCHAR(200)) AS ud_ar_terr
        ,CAST(users_ud.claims_terr                                  AS VARCHAR(200)) AS ud_claims_terr
        ,CAST(users_ud.job_title                                    AS VARCHAR(200)) AS ud_job_title
        ,CAST(users_ud.ops_region                                   AS VARCHAR(200)) AS ud_ops_region
        ,CAST(COALESCE(users_ud.power_bi_user,'N')                  AS VARCHAR(200)) AS ud_power_bi_user
        ,CAST(users_ud.price_family_id                              AS VARCHAR(200)) AS ud_price_family_id
        ,CAST(users_ud.sales_region                                 AS VARCHAR(200)) AS ud_sales_region
        ,CAST(users_ud.salesrep_id                                  AS VARCHAR(200)) AS ud_salesrep_id
        ,CAST(users_ud.user_description                             AS VARCHAR(200)) AS ud_user_description
    FROM users
    LEFT JOIN users_ud ON users_ud.id = users.id
    WHERE users.id IN (@UserA, @UserB)
),
a AS (SELECT * FROM base WHERE id = @UserA),
b AS (SELECT * FROM base WHERE id = @UserB)
SELECT field_name,
       a_val,
       b_val
FROM (
    SELECT 'active'                        AS field_name, a.active                        AS a_val, b.active                        AS b_val FROM a CROSS JOIN b
    UNION ALL SELECT 'delete_flag',                       a.delete_flag,                       b.delete_flag                       FROM a CROSS JOIN b
    UNION ALL SELECT 'default_company',                   a.default_company,                   b.default_company                   FROM a CROSS JOIN b
    UNION ALL SELECT 'default_branch',                    a.default_branch,                    b.default_branch                    FROM a CROSS JOIN b
    UNION ALL SELECT 'default_location_id',               a.default_location_id,               b.default_location_id               FROM a CROSS JOIN b
    UNION ALL SELECT 'system_security',                   a.system_security,                   b.system_security                   FROM a CROSS JOIN b
    UNION ALL SELECT 'company_security',                  a.company_security,                  b.company_security                  FROM a CROSS JOIN b
    UNION ALL SELECT 'window_security',                   a.window_security,                   b.window_security                   FROM a CROSS JOIN b
    UNION ALL SELECT 'remote_user',                       a.remote_user,                       b.remote_user                       FROM a CROSS JOIN b
    UNION ALL SELECT 'role_uid',                          a.role_uid,                          b.role_uid                          FROM a CROSS JOIN b
    UNION ALL SELECT 'designer_rights',                   a.designer_rights,                   b.designer_rights                   FROM a CROSS JOIN b
    UNION ALL SELECT 'create_customers',                  a.create_customers,                  b.create_customers                  FROM a CROSS JOIN b
    UNION ALL SELECT 'create_ship_tos',                   a.create_ship_tos,                   b.create_ship_tos                   FROM a CROSS JOIN b
    UNION ALL SELECT 'create_items_at_oe',                a.create_items_at_oe,                b.create_items_at_oe                FROM a CROSS JOIN b
    UNION ALL SELECT 'create_po_from_oe',                 a.create_po_from_oe,                 b.create_po_from_oe                 FROM a CROSS JOIN b
    UNION ALL SELECT 'create_items_at_soe',               a.create_items_at_soe,               b.create_items_at_soe               FROM a CROSS JOIN b
    UNION ALL SELECT 'create_contract_from_oe',           a.create_contract_from_oe,           b.create_contract_from_oe           FROM a CROSS JOIN b
    UNION ALL SELECT 'default_application',               a.default_application,               b.default_application               FROM a CROSS JOIN b
    UNION ALL SELECT 'default_costing_basis',             a.default_costing_basis,             b.default_costing_basis             FROM a CROSS JOIN b
    UNION ALL SELECT 'default_quote_order',               a.default_quote_order,               b.default_quote_order               FROM a CROSS JOIN b
    UNION ALL SELECT 'default_item_search',               a.default_item_search,               b.default_item_search               FROM a CROSS JOIN b
    UNION ALL SELECT 'default_to_advanced_search',        a.default_to_advanced_search,        b.default_to_advanced_search        FROM a CROSS JOIN b
    UNION ALL SELECT 'default_salesrep_on_order',         a.default_salesrep_on_order,         b.default_salesrep_on_order         FROM a CROSS JOIN b
    UNION ALL SELECT 'default_rep_on_comm_rpt_flag',      a.default_rep_on_comm_rpt_flag,      b.default_rep_on_comm_rpt_flag      FROM a CROSS JOIN b
    UNION ALL SELECT 'default_customer_id',               a.default_customer_id,               b.default_customer_id               FROM a CROSS JOIN b
    UNION ALL SELECT 'default_label_printer',             a.default_label_printer,             b.default_label_printer             FROM a CROSS JOIN b
    UNION ALL SELECT 'historical_cost_in_sales_hist',     a.historical_cost_in_sales_hist,     b.historical_cost_in_sales_hist     FROM a CROSS JOIN b
    UNION ALL SELECT 'link_stock_item_to_po',             a.link_stock_item_to_po,             b.link_stock_item_to_po             FROM a CROSS JOIN b
    UNION ALL SELECT 'adj_qty_available_at_oe',           a.adj_qty_available_at_oe,           b.adj_qty_available_at_oe           FROM a CROSS JOIN b
    UNION ALL SELECT 'allow_nonstock_tbo',                a.allow_nonstock_tbo,                b.allow_nonstock_tbo                FROM a CROSS JOIN b
    UNION ALL SELECT 'view_cost_on_oe_line',              a.view_cost_on_oe_line,              b.view_cost_on_oe_line              FROM a CROSS JOIN b
    UNION ALL SELECT 'sales_supervisor_flag',             a.sales_supervisor_flag,             b.sales_supervisor_flag             FROM a CROSS JOIN b
    UNION ALL SELECT 'doe_user_flag',                     a.doe_user_flag,                     b.doe_user_flag                     FROM a CROSS JOIN b
    UNION ALL SELECT 'doe_salesrep_id',                   a.doe_salesrep_id,                   b.doe_salesrep_id                   FROM a CROSS JOIN b
    UNION ALL SELECT 'mgmt_allow_branch_edit',            a.mgmt_allow_branch_edit,            b.mgmt_allow_branch_edit            FROM a CROSS JOIN b
    UNION ALL SELECT 'mgmt_use_default_branch',           a.mgmt_use_default_branch,           b.mgmt_use_default_branch           FROM a CROSS JOIN b
    UNION ALL SELECT 'receive_system_alerts',             a.receive_system_alerts,             b.receive_system_alerts             FROM a CROSS JOIN b
    UNION ALL SELECT 'task_visibility_cd',                a.task_visibility_cd,                b.task_visibility_cd                FROM a CROSS JOIN b
    UNION ALL SELECT 'time_zone_cd',                      a.time_zone_cd,                      b.time_zone_cd                      FROM a CROSS JOIN b
    UNION ALL SELECT 'display_transaction_tasks',         a.display_transaction_tasks,         b.display_transaction_tasks         FROM a CROSS JOIN b
    UNION ALL SELECT 'strategic_pricing_role_uid',        a.strategic_pricing_role_uid,        b.strategic_pricing_role_uid        FROM a CROSS JOIN b
    UNION ALL SELECT 'customer_profit_role_uid',          a.customer_profit_role_uid,          b.customer_profit_role_uid          FROM a CROSS JOIN b
    UNION ALL SELECT 'field_chooser_perm_cd',             a.field_chooser_perm_cd,             b.field_chooser_perm_cd             FROM a CROSS JOIN b
    UNION ALL SELECT 'restricted_class_override_flag',    a.restricted_class_override_flag,    b.restricted_class_override_flag    FROM a CROSS JOIN b
    UNION ALL SELECT 'over_redeem_rewards_flag',          a.over_redeem_rewards_flag,          b.over_redeem_rewards_flag          FROM a CROSS JOIN b
    UNION ALL SELECT 'use_po_approval_threshold_flag',    a.use_po_approval_threshold_flag,    b.use_po_approval_threshold_flag    FROM a CROSS JOIN b
    UNION ALL SELECT 'po_approval_threshold',             a.po_approval_threshold,             b.po_approval_threshold             FROM a CROSS JOIN b
    UNION ALL SELECT 'search_item_catalog_flag',          a.search_item_catalog_flag,          b.search_item_catalog_flag          FROM a CROSS JOIN b
    UNION ALL SELECT 'make_items_sellable_in_oe_flag',    a.make_items_sellable_in_oe_flag,    b.make_items_sellable_in_oe_flag    FROM a CROSS JOIN b
    UNION ALL SELECT 'add_item_locations_in_oe_flag',     a.add_item_locations_in_oe_flag,     b.add_item_locations_in_oe_flag     FROM a CROSS JOIN b
    UNION ALL SELECT 'confirm_dea_pt_flag',               a.confirm_dea_pt_flag,               b.confirm_dea_pt_flag               FROM a CROSS JOIN b
    UNION ALL SELECT 'default_send_to_outlook_flag',      a.default_send_to_outlook_flag,      b.default_send_to_outlook_flag      FROM a CROSS JOIN b
    UNION ALL SELECT 'display_purchaseprice_breaks',      a.display_purchaseprice_breaks,       b.display_purchaseprice_breaks      FROM a CROSS JOIN b
    UNION ALL SELECT 'display_open_quote_lines_cd',       a.display_open_quote_lines_cd,       b.display_open_quote_lines_cd       FROM a CROSS JOIN b
    UNION ALL SELECT 'view_vendor_type_cd',               a.view_vendor_type_cd,               b.view_vendor_type_cd               FROM a CROSS JOIN b
    UNION ALL SELECT 'bypass_check_verify_password',      a.bypass_check_verify_password,      b.bypass_check_verify_password      FROM a CROSS JOIN b
    UNION ALL SELECT 'allow_add_labor_to_completed_po',   a.allow_add_labor_to_completed_po,   b.allow_add_labor_to_completed_po   FROM a CROSS JOIN b
    UNION ALL SELECT 'do_not_export_carrier_po_flag',     a.do_not_export_carrier_po_flag,     b.do_not_export_carrier_po_flag     FROM a CROSS JOIN b
    UNION ALL SELECT 'allow_postprint_edit_labor_est',    a.allow_postprint_edit_labor_est,     b.allow_postprint_edit_labor_est    FROM a CROSS JOIN b
    UNION ALL SELECT 'add_customer_part_number_in_oe',    a.add_customer_part_number_in_oe,    b.add_customer_part_number_in_oe    FROM a CROSS JOIN b
    UNION ALL SELECT 'cnvrt_prospect_to_customer_oe',     a.cnvrt_prospect_to_customer_oe,     b.cnvrt_prospect_to_customer_oe     FROM a CROSS JOIN b
    UNION ALL SELECT 'override_cust_pallet_warn_flag',    a.override_cust_pallet_warn_flag,     b.override_cust_pallet_warn_flag    FROM a CROSS JOIN b
    UNION ALL SELECT 'allow_edit_labor_time_entry',       a.allow_edit_labor_time_entry,        b.allow_edit_labor_time_entry       FROM a CROSS JOIN b
    UNION ALL SELECT 'language_id',                       a.language_id,                        b.language_id                       FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_ar_terr',                        a.ud_ar_terr,                         b.ud_ar_terr                        FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_claims_terr',                    a.ud_claims_terr,                     b.ud_claims_terr                    FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_job_title',                      a.ud_job_title,                       b.ud_job_title                      FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_ops_region',                     a.ud_ops_region,                      b.ud_ops_region                     FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_power_bi_user',                  a.ud_power_bi_user,                   b.ud_power_bi_user                  FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_price_family_id',                a.ud_price_family_id,                 b.ud_price_family_id                FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_sales_region',                   a.ud_sales_region,                    b.ud_sales_region                   FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_salesrep_id',                    a.ud_salesrep_id,                     b.ud_salesrep_id                    FROM a CROSS JOIN b
    UNION ALL SELECT 'ud_user_description',               a.ud_user_description,                b.ud_user_description               FROM a CROSS JOIN b
) AS diff
WHERE ISNULL(a_val, '~NULL~') <> ISNULL(b_val, '~NULL~')
ORDER BY field_name;
