# kb_ Table Usage Analysis
**Date:** 2026-06-03  
**Server:** P21.allsurfaces.com / P21  
**Data window:** 2026-05-17 (last restart) → 2026-06-03 — 17 days  
**Goal:** Identify kb_ tables that can be retired or replaced with standard P21 objects to reduce customization.

---

## Summary Counts
| Category | Count |
|---|---|
| Keep — actively written + read | 14 |
| Keep — read-only config (static reference) | 12 |
| Investigate — no activity, has data | 15 |
| Retire — empty or clearly obsolete | 7 |
| **Total** | **48** |

---

## KEEP — Actively Written and Read

| Table | Rows | Last Write | Notes |
|---|---|---|---|
| kb_table_customer_comclass_salesrep | 361,954 | Today | Core — written + read daily |
| kb_table_p21_license_usage_history | 9,489 | Today | Written daily by scheduled job |
| kb_table_salesrep_commission_classes | 804 | Today | Written today |
| kb_table_financial_overview | 6,218 | Today | Written today |
| kb_table_customer_x_displays | 49,459 | Yesterday | Written daily |
| kb_table_customer_salesrep_audit_trail | 41,168 | Yesterday | Written by trigger |
| kb_table_br_error_log | 63,708 | Yesterday | NULL read = only accessed via view |
| kb_table_fino_monthly | 248 | 2 days ago | Written by scheduled proc |
| kb_table_displays | 362 | 5 days ago | Written regularly |
| kb_table_buying_group_audit_trail | 1,525 | 6 days ago | Written by trigger |
| kb_table_future_prices | 128,493 | 16 days ago | Read daily |
| kb_table_period_first_stocked | 227,511 | None since restart | Read daily — feeds bi_view_item |
| kb_table_sales_manager_values_all | 114,688 | None since restart | Read daily |
| kb_table_fino_loan_balance | 1,212 | None since restart | Read daily |

---

## KEEP — Read-Only Config (Static Reference)

Written manually or rarely. NULL write is expected. Referenced by active objects.

| Table | Rows | Notes |
|---|---|---|
| kb_table_inbound_fuel_surcharge | 3 | Config for order validator BR — static |
| kb_table_required_date_statuses | 4 | Config for order validator BR — static |
| kb_table_credit_analysts | 8 | Read daily |
| kb_comclass_convert | 9 | Read daily by function + view |
| kb_table_sales_manager_values | 14 | Read recently — investigate vs `_all` version |
| kb_table_buying_groups | 41 | Read daily |
| kb_table_ccs_locations | 50 | Read daily by many procs/views |
| kb_table_website_promos | 75 | Written 16 days ago, read daily |
| kb_table_country_code | 196 | Read daily — investigate if P21 has standard country table |
| kb_table_price_pages_to_omit_from_bulk | 417 | Read 10 days ago |
| kb_table_spiff_qualifying_items | 1,256 | Read 5 days ago |
| kb_table_sfdc_crossover | 4,626 | Read daily — is Salesforce still in use? |

---

## INVESTIGATE — Has Data, Not Touched Since Restart

Needs business owner confirmation before any action.

| Table | Rows | Question |
|---|---|---|
| kb_table_sale_day_customers | 36 | Sale day program — still active? |
| kb_table_sale_day_customers_excluded | 103 | Same |
| kb_table_sale_day_items_xl_brand | 182 | Same |
| kb_table_sale_day_earmarked_item_costs | 473 | Same |
| kb_table_sale_day_items | 182,802 | Same — large |
| kb_table_wrong_loc | 109 | Name suggests workaround — still needed? |
| kb_table_invoice_hdr_ship2_state_fixer | 449 | "Fixer" = workaround — still needed? |
| kb_table_display_product_cat | 6 | Referenced by views only — views still used? |
| kb_table_display_product | 524 | Same |
| kb_table_DeadlockEvents | 995 | Is the alert job still running? |
| kb_table_customer_matches | 613 | Only used by merge prep proc — one-time tool? |
| kb_table_temp_customer_list | 33,073 | "Temp" in name, never touched — leftover? |
| kb_table_atrewards_qualifying_items | 6,335 | AT Rewards program — still active? |
| kb_table_invoice_line_commission | 922,990 | 923k rows, never touched — is this abandoned? |

---

## RETIRE — Strong Candidates for Removal

Low risk. Verify no external tools (SSRS, Excel) reference these before dropping.

| Table | Rows | Reason |
|---|---|---|
| kb_table_2022_q4_objective_items | 207 | Year in name, never touched |
| kb_table_atrewards_qualifying_items_OLD | 1,225 | `_OLD` suffix, never touched |
| kb_table_cost_snapshot | 0 | Empty |
| kb_table_customer_pricing_bulktable | 0 | Empty |
| kb_table_pricing_tiers | 0 | Empty |
| kb_table_spiff_qualifying_items_alternate | 0 | Empty |
| kb_table_tool_it_price_audit_trail | 0 | Empty |

---

## Specific Flags

### kb_table_sales_manager_values vs kb_table_sales_manager_values_all
Both referenced by the same functions (`kb_fn_get_sales_manager`, `kb_fn_get_sales_manager_names`, `kb_fn_get_sales_manager_names_portals`) and same procs. 14 rows vs 114,688 rows. One is likely a subset or predecessor — investigate whether `_values` is still needed or can be consolidated into `_values_all`.

### kb_table_invoice_line_commission (922,990 rows)
Large table, never read or written since restart. Referenced only by `kb_proc_grant_permissions` (permissions script, not operational) and `kb_view_invoice_line_commission`. If the view is never queried either, this is a high-value retirement candidate despite its size.

### Sale day cluster (5 tables)
All NULL/NULL. If the sale day pricing program is still active, these should be getting hit by the order entry business rules. Worth confirming whether the BR is deployed and whether a sale day has been triggered in the past 17 days.

---

## Next Steps
1. Run `Check-KB-Object-Last-Used.sql` against P21 Prod for proc/function/trigger stats
2. Retire the 7 empty/obsolete tables (low risk, immediate win)
3. Confirm sale day program status with business owner
4. Investigate `kb_table_invoice_line_commission` — query `kb_view_invoice_line_commission` to see if it returns meaningful data
5. Check whether Salesforce integration (`kb_table_sfdc_crossover`) is still active
