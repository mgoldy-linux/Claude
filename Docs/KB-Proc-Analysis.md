# kb_ Stored Procedure Usage Analysis
**Date:** 2026-06-03  
**Server:** P21.allsurfaces.com / P21  
**Data window:** 2026-05-17 (last restart) → 2026-06-03 — 17 days  
**Source:** sys.dm_exec_procedure_stats (resets on restart)

---

## Summary
| Category | Count |
|---|---|
| Active — executed in window | 6 |
| Investigate — periodic/on-demand | 68 |
| Retire — strong candidates | 10 |
| **Total** | **84** |

---

## KEEP — Executed in 17-Day Window

| Proc | Exec Count | Last Run | Last Modified | Notes |
|---|---|---|---|---|
| kb_proc_customer_pricing_loc_items | 2,572 | Today | 2023 | High-frequency — pricing lookup |
| kb_proc_br_oe_hdr_note | 249 | Today | 2018 | Order entry BR — fires on OE header |
| kb_proc_sched_oe_line_ud_oe_salesrep_id | 14 | Today | 2021 | Scheduled — salesrep assignment |
| kb_proc_log_p21_licenses_used | 3 | Today | 2024 | Scheduled — license monitoring |
| kb_proc_sales_division_all | 1 | Today | 2020 | Scheduled |
| kb_proc_update_fino_table | 1 | Today | 2019 | Scheduled — financial overview |

---

## INVESTIGATE — Not Executed in Window

These are grouped by functional area. Most are on-demand or periodic — absence from the 17-day window doesn't confirm retirement, but each warrants a check.

### Sale Day Cluster
All 10 procs tied to the sale day pricing program. Cross-reference with table analysis — the sale day tables are also untouched. **Confirm with business owner whether any sale day has run in the past 17 days.**

| Proc | Last Modified |
|---|---|
| kb_proc_br_oe_sale_day | 2024-05-13 |
| kb_proc_br_oe_sale_day_setprice | 2024-05-09 |
| kb_proc_br_oe_sale_day_setprice_by_pct | 2024-05-09 |
| kb_proc_br_oe_welcome_back | 2020-06-03 |
| kb_proc_br_oe_insapp | 2020-09-11 |
| kb_proc_br_oe_sale_day_omithouse | 2020-06-01 |
| kb_proc_br_oe_sale_day_onlyhouse | 2020-08-21 |
| kb_proc_br_oe_sale_day_move_br_priced | 2020-05-11 |
| kb_proc_br_oe_sale_day_setprice_xl_brand | 2020-06-12 |
| kb_proc_br_oe_sale_202006_XLB | 2020-06-12 |

### Commission Reports
Likely run monthly or quarterly — check SQL Agent history for last run date.

| Proc | Last Modified |
|---|---|
| kb_proc_commission_report_individual | 2024-04-01 |
| kb_proc_commission_report_ccs | 2024-10-01 |
| kb_proc_commission_report_ccs_adds | 2024-07-01 |
| kb_proc_commission_rule_copy | 2021-01-07 |
| kb_proc_commission_rule_value_edit | 2019-07-23 |
| kb_proc_commission_report_salesmanagers | 2020-11-12 |
| kb_proc_ssrs_sales_dsr | 2021-06-29 |
| kb_proc_turn_earn_report | 2020-01-09 |
| kb_proc_turn_earn_report_ssrs | 2021-03-05 |

### Pricing Maintenance
On-demand procs called manually when prices change. Check if `kb_table_future_prices` is still being populated via these.

| Proc | Last Modified |
|---|---|
| kb_proc_apply_future_prices | 2021-07-20 |
| kb_proc_apply_current_prices | 2021-08-04 |
| kb_proc_apply_future_costs | 2021-06-14 |
| kb_proc_cost_price_change_summary | 2022-01-20 |
| kb_proc_price_page_add | 2024-01-17 |
| kb_proc_price_page_add_item | 2022-11-10 |
| kb_proc_price_page_add_item1off | 2021-07-19 |
| kb_proc_price_page_add_item1off_fb | 2021-09-30 |
| kb_proc_price_page_add_mfgclass1off | 2021-12-29 |
| kb_proc_price_page_add_po_cost_multiplier_customer | 2024-10-08 |
| kb_proc_price_page_book_add | 2023-09-14 |
| kb_proc_price_page_change_mfg_class | 2019-11-20 |
| kb_proc_price_book_add | 2023-09-13 |
| kb_proc_price_book_library_add | 2023-09-13 |
| kb_proc_price_library_customer_add | 2023-09-13 |
| kb_proc_price_mfgclass_split | 2024-01-12 |
| kb_proc_set_mfg_class_include_checkbox | 2023-09-13 |
| kb_proc_customer_pricing_bulktable_calculation | 2023-04-27 |
| kb_proc_customer_pricing_loc_item_omitsale | 2021-07-08 |
| kb_proc_customer_pricing_loc_omitsale_bulktable | 2023-04-12 |
| kb_proc_customer_contract_pricing_settings | 2024-01-25 |
| kb_proc_clear_contract_hdr_oe_defaults | 2024-04-15 |

### Salesrep / Territory Admin
On-demand procs called manually for rep changes. Likely run infrequently.

| Proc | Last Modified |
|---|---|
| kb_proc_evaluate_salesrep_assignments | 2025-01-06 |
| kb_proc_evaluate_locked_salesrep_assignments | 2024-08-05 |
| kb_proc_set_locked_salesrep_assignments | 2024-09-04 |
| kb_proc_evaluate_branchmgr_assignments_retroactively | 2024-08-14 |
| kb_proc_evaluate_branchmgr_assignments | 2022-09-02 |
| kb_proc_evaluate_salesrep_assignment | 2020-11-12 |
| kb_proc_customer_listing_salesrep_assignments | 2024-08-20 |
| kb_proc_credit_analyst_territory_change | 2024-02-28 |
| kb_proc_create_commission_territory_rule | 2024-08-13 |
| kb_proc_terr_cust_add | 2024-11-11 |
| kb_proc_add_salesrep | 2020-07-07 |
| kb_proc_remove_salesrep | 2020-12-08 |
| kb_proc_replace_salesrep | 2020-12-08 |
| kb_proc_set_primary_salesrep | 2023-06-27 |
| kb_proc_add_dealer_type | 2020-09-21 |
| kb_proc_evaluate_dealer_type_pricing | 2020-10-02 |

### User Admin
Utility procs for user management. Run rarely.

| Proc | Last Modified |
|---|---|
| kb_proc_copy_user | 2024-08-16 |
| kb_proc_delete_user | 2024-11-27 |
| kb_proc_salesportals_enable | 2019-04-01 |
| kb_proc_remove_udf | 2023-08-28 |

### Other On-Demand / Scheduled
| Proc | Last Modified |
|---|---|
| kb_proc_br_customer_closed | 2021-12-20 |
| kb_proc_contract_line_deactivate | 2024-06-28 |
| kb_proc_customer_merge_prep | 2024-06-05 |
| kb_proc_edi_832_set_date | 2021-05-12 |
| kb_proc_evaluate_customer_ud_ccs_default_location | 2020-03-09 |
| kb_proc_evaluate_customer_ud_website_promos | 2020-01-07 |
| kb_proc_fino_update_monthly | 2019-07-18 |
| kb_proc_freight_charge_update | 2022-03-11 |
| kb_proc_grant_permissions | 2020-09-11 |
| kb_proc_inv_bin_unlock | 2024-10-21 |
| kb_proc_oel_note_remove_mandatory | 2020-06-12 |
| kb_proc_set_inv_country | 2018-09-19 |
| kb_proc_sched_deadlock_alert | 2024-04-25 |
| kb_proc_update_holidays_in_bi_table_date | 2021-06-03 |
| kb_proc_update_inventory_period_first_stocked_table | 2021-03-15 |
| kb_proc_update_sales_manager_values_all | 2020-07-13 |
| kb_proc_customer_pricing_loc_items | already in KEEP |

---

## RETIRE — Strong Candidates

| Proc | Last Modified | Reason |
|---|---|---|
| kb_proc_test_tables_and_views | 2018-11-29 | "test" in name, never run |
| kb_proc_evaluate_inv_mast_ud_manufacturers | 2016-07-19 | 10 years old, never run |
| kb_proc_evaluate_inv_mast_ud_packaging | 2016-08-23 | 10 years old, never run |
| kb_proc_evaluate_null_salesrep_oe_assignments | 2017-07-19 | 9 years old, never run |
| kb_proc_evaluate_updated_salesrep_inv_assignments | 2016-08-12 | 10 years old, never run |
| kb_proc_evaluate_updated_salesrep_inv_null_oe_assignments | 2017-07-19 | 9 years old, never run |
| kb_proc_evaluate_updated_salesrep_oe_assignments | 2017-07-19 | 9 years old, never run |
| kb_proc_ar_GetPaymentReceipt | 2017-06-15 | 9 years old, PascalCase = very old style |
| kb_proc_mkg_display_shipments | 2019-05-06 | 7 years, never run, display program likely inactive |
| kb_proc_br_oe_sale_202006_XLB | 2020-06-12 | Date in name = 2020, superseded |

---

## Flags

- **kb_proc_fino_update_monthly** (2019) — not run, but `kb_table_fino_monthly` was written 2 days ago. `kb_proc_update_fino_table` (the active proc) writes the daily table; this one may handle a separate monthly rollup — verify before retiring.
- **kb_proc_grant_permissions** — maintenance proc that exists to re-grant permissions. Not operational, but retain — useful for post-refresh steps.
- **Sale day cluster modified dates** — `kb_proc_br_oe_sale_day` was modified in May 2024, meaning someone actively maintained it recently. Program is not dead — likely just not triggered in this 17-day window.
