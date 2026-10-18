# Retire `kb_sales_history_report_view` — inventory + plan

Started 2026-10-16. Prod inventory is read-only so far. Nothing has been changed.

## Inventory (Prod)

**Database:** 90 objects reference the view (directly or through another object).
- ~70 `js_` objects: `js_fnt_*` (rebates, congo, spiff, buying-group payouts) and `js_proc_*`
- `kb_` procs: `kb_proc_commission_report_ccs`, `_ccs_adds`, `_individual`, `_salesmanagers`, `kb_proc_customer_pricing_bulktable_calculation`, `kb_proc_fino_update_monthly`, `kb_proc_update_fino_table`, `kb_proc_mkg_display_shipments`, `kb_proc_sales_division_all`, `kb_proc_ssrs_sales_dsr`, `kb_proc_turn_earn_report_ssrs`
- `kb_` views: `kb_view_commission_report`, `_adds`, `_branches`, `_ccs`, `kb_view_turn_earn_report`, `kb_view_welcome_back_monitor`, `kb_view_mkg_display_shipment_nos`, `kb_view_samples_open_recentlyshipped_ilin`, `kb_sales_history_report_view_roii_costs`
- Other: `bi_view_budget_framework_marc`; `asi_fnt_sa55014_sales_invoiced_yesterday` (text match only, probably a comment, check)
- Agent job steps: none
- Live consumer today: YTD sales ribbon query `kb_CustRM_getYTDSalesAbbr` (477 plan-cache executions on 2026-10-16). Replacement `asi_ribbon_cm_SYTD` is built but NOT deployed.

**Portals / tabs:** 32 live Prod `.srd` files (top-level `\asp21fs1.ahi.local\Prod\Portals`) reference the view, or `kb_view_mkg_display_shipment_nos`. CORRECTION 2026-10-16: the first scan recursed into `SRD Backup 181015\` and wrongly counted `orders_by_cust_item_date_kb` (Order Search). The live Order Search file does NOT use this view; it uses `kb_view_salesrep` and `kb_fn_get_sales_manager` (separate kb_ cleanup). Always scan top-level only.

## P21 tab usage (XE capture 2026-06-22 .. 2026-10-16, Mark excluded)

Source: `C:\_P25\Data-Out\Excel\XE-Portal-Tab-Detail-Prod.xlsx` (197,149 opens across all tabs; the 33 tabs here are 2,636 of them, 1.3%).

| Rank | srd | Tab | Opens | Users | Last |
|---|---|---|---:|---:|---|
| n/a | orders_by_cust_item_date_kb | ORDER SEARCH (808 opens, 45 users) - NOT a user of this view, see correction above | 808 | 45 | 10/16 |
| 2 | invoice_tab_price_cost_detail | INVOICE TAB PRICE COST DETAIL | 576 | 57 | 10/16 |
| 3 | customer_tab_sales | CUST TAB SALES (customer window tab) | 502 | 115 | 10/16 |
| 4 | customer_tab_open_order_lines | CUSTOMER TAB OPEN ORDER LINES | 216 | 30 | 10/16 |
| 5 | invoices_by_cust_item_date_sm | INVOICE SEARCH SM | 177 | 8 | 10/16 |
| 6 | mkg_display_shipments | MKG DISPLAY SHIPMENTS (via kb_view_mkg_display_shipment_nos) | 151 | 2 | 10/16 |
| 7 | sales_invoiced_yesterday | SALES INVOICED YESTERDAY | 111 | 4 | 10/16 |
| 8 | sales_item_12mytd_all | SALES BY ITEM 12MYTD ALL | 75 | 3 | 10/15 |
| 9 | sales_prodgrp_mlyl_sm | | 6 | 1 | 9/02 |
| 10-11 | sales_account_mlyl_sm / sales_mfg_mlyl_sm | | 4 / 4 | 4 / 4 | 10/09, 10/07 |
| 12 | inv_usage_90_days_orderct | | 3 | 2 | 10/06 |
| 13-14 | invoices_by_cust_item_date, br_sal_sales_invoiced_yesterday | | 2, 1 | 1, 1 | 6/30, 9/16 |

**Zero opens in ~4 months (19 files):** ar_disputed_invoices, ar_invoices_rebilled_free, br_sal_sales_invoiced_yesterday_v2 (already on the SA 55014 TVF), invoices_zero_other_cost, objectives_2016q3, objectives_2016q3_sm, order_search_test, rewards_by_cust_program_choose_kb, sales_account_mlyl_all, sales_corp_mlyl_all, sales_mfg_mlyl_all, sales_mfg_mlyl_all2, sales_prodgrp_mlyl_all, sales_rep_mlyl_all, sales_salesmgr_mlyl_all, sales_salesrep_mlyl_all, sales_salesrep_mlyl_sm, sales_smg_3mo, sr_large_orders_7d_25988.

Portal-assignment findings: `customer_tab_sales` is NOT in any portal (it is a customer-window tab), yet it has 115 users. Unassigned portal tabs: br_sal_sales_invoiced_yesterday, customer_tab_sales, order_search_test, sales_mfg_mlyl_all2, sr_large_orders_7d_25988. `.srd` files not registered in `portal_user_defined`: ar_disputed_invoices, invoices_zero_other_cost, objectives_2016q3(_sm).

## Plan

1. Finish the inventory: SSRS catalog, Excel/Power Query sources, alerts, other environments' portal folders.
2. **Tabs first, in usage order** (see recommendation below). For each: read the `.srd` SQL, build a replacement `asi_view_*` / `asi_fnt_*` (base: `p21_sales_history_view`, or a report-specific TVF as in SA 55014), keep the `.srd` to a trivial SELECT, deploy the object first, keep column order identical.
3. Verify each port: `EXCEPT` both directions = 0/0, then logical reads / CPU from the plan cache (not wall-clock). Report honestly if not faster.
4. Deploy Play, then Prod; keep the old `.srd` for rollback.
5. Retire the zero-use tabs (portal assignments to Inactive, never hard delete, "Cleanup" folder per env) instead of porting them.
6. Ribbon: test and deploy `asi_ribbon_cm_SYTD` (TC-01..08).
7. The ~70 `js_` / `kb_` dependents: check execution history, retire the dead ones, port the live ones.
8. Final gate: no dependents, no plan-cache hits across a month-end, rename to `kb_..._retired` for a period, then drop.

Related: SA 55014 (`Portals\SA-55014\`), `Deploy-Guides\asi_sales_history_report_view_roii_costs.md`, `Deploy-Guides\asi_ribbon_cm_SYTD-ytd-sales-ribbon.md`, `Docs\SA-42483-summary.txt`.
