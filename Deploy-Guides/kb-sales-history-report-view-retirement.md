# kb_sales_history_report_view retirement - P21 tabs (Order Search, Invoice Tab Price Cost Detail, Customer Tab Sales)

**Ticket:** none (2026 goal: retire kb_/js_/ds_). Plan + usage ranking: `Docs\kb_sales_history_report_view-retirement-plan.md`. Per-tab detail: `Portals\<tab>\README.md`.

## Status (2026-10-19)
| Tab | Artifacts | Play | Dev/BRR/Training | Prod |
|---|---|---|---|---|
| Order Search (`orders_by_cust_item_date_kb` -> `asi_orders_by_cust_item_date.srd`) | view `asi_view_salesrep_division_manager` | 🟢 | 🟢 per Mark (not verified by Claude) | 🟢 **LIVE 10/19, tested OK** |
| Invoice Tab Price Cost Detail (element 120, `invoice_tab_price_cost_detail`) | TVFs `asi_fnt_invoice_line_rewards`, `asi_fnt_invoice_price_cost`; `asi_invoice_tab_price_cost_detail.srd` | 🟢 works | not started | ⏳ to do |
| Customer Tab Sales (`customer_tab_sales`, customer window) | TVF `asi_fnt_customer_period_sales`; `asi_customer_tab_sales.srd` | SQL only; .srd not built | not started | ⏳ to do |

## Deploy order (every tab) and steps
1. **SQL objects first** (CREATE OR ALTER; each file carries grants to `p21_application_role` + `PxxiUser`): `SQL-Schema\CREATE-OR-ALTER-VIEW-asi_view_salesrep_division_manager.sql`, `CREATE-OR-ALTER-FUNCTION-asi_fnt_invoice_price_cost.sql` (both invoice functions), `CREATE-OR-ALTER-FUNCTION-asi_fnt_customer_period_sales.sql`. Verify grants after.
2. **Prove equivalence on that environment** old-vs-new retrieve, `EXCEPT` both ways + row counts (harness pattern in the tab READMEs). On Prod also cover order_type 1706 and advance-bill invoices (none in Play).
3. **.srd**: Mark rebuilds in InfoMaker (copy data source, rename `asi_<name>`, paste the retrieve). **Close the preview and strip any `data(` line before saving** - embedded preview rows cause "Error serializing DW definition" in P21. Check size ~ original (135 KB for Order Search).
4. Copy the .srd to the environment's Portals folder (`\\ASP21FS1\<env>\Portals\`).
5. **Portal Element Configuration**: new element (Object Name = `asi_...` without .srd, Library File = Portals folder), add to the same portal as the old one, confirm role assignments. Rename the old element "... KB" and take it off the portal. Never hard-delete.
6. Test in the client (customer search, item search, open an order/invoice link).

## Rollback
Put the old element back on the portal (and take the new one off). New SQL objects and .srd files can stay. Old .srd files untouched.

## Notes / traps
- Replacements are per-use lean functions, not the giant view; same CASE logic and WHERE row filters copied from `kb_sales_history_report_view`.
- Latent bug kept identical on purpose: Order Search `:salesrep_id` filters `updated_salesrep_id` only (grid shows COALESCE with `oe_salesrep_id`). Mark has not decided.
- Perf: Order Search reads flat/elapsed 2-3x lower; Invoice Tab no perf win (already ~13K reads); Customer Tab -35-40% reads/-50% CPU, 30K-invoice account 29.5 s -> 6.2 s.
- Customer Tab Sales graph renders on desktop client/InfoMaker only, not the web client (pre-existing; Report Studio later - Work-Log backlog).
- `orders_by_cust_item_date_sm` (element 175) still uses kb_view_salesrep + kb_fn_get_sales_manager: next.
- Still to drop later: the view itself, once all ~70 `js_`/`kb_` dependents and `Portals\SA-55014\*`, `asi_ribbon_cm_SYTD`, `kb_CustRM_getYTDSalesAbbr`, `_roii_costs` are handled.