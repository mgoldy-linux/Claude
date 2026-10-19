# Customer Tab Sales (`customer_tab_sales.srd`) - kb_ retirement

Status 2026-10-19: **built and verified in P21Play only. NOT in Prod. No .srd written yet (Mark builds it in InfoMaker).**
Customer-window tab (not in any portal). 502 opens / 115 users. Live file `\\ASP21FS1\Prod\Portals\customer_tab_sales.srd` (2024-10-24). Arguments: `company_id` string, `customer_id` number.

## Change
Two `OUTER APPLY` blocks over `kb_sales_history_report_view` (12 months each = ~24 view hits) -> two `LEFT JOIN` to `dbo.asi_fnt_customer_period_sales(:company_id, :customer_id, YEAR(GETDATE())-2)`, one row per period. Function: `..\..\SQL-Schema\CREATE-OR-ALTER-FUNCTION-asi_fnt_customer_period_sales.sql` (grants to p21_application_role + PxxiUser). Same price/cost logic and row filters as asi_fnt_invoice_price_cost; rewards logic scoped to the customer's invoices. No kb_ object left. Output columns/order unchanged (10 columns).

## Verification (Play): old vs v2, EXCEPT both ways + row counts, 21 customers (biggest 30K-invoice house account 3023035, small, random, 4 with rewards) = 0 bad. Not covered: order_type 1706 / advance bill (none in Play) - recheck on Prod.

## Performance (plan cache, logical reads / CPU ms / elapsed ms)
| Customer | Old | v2 |
|---|---|---|
| 3023035 (30K invoices) | 11,543,039 / 13,030 / 29,502 | 7,162,257 / 6,215 / 6,239 |
| 1028625 | 365,317 / 393 / 393 | 244,305 / 248 / 258 |
| 1181729 | 20,186 / 45 / 45 | 16,088 / 27 / 27 |
| 1162488 | 4,597 / 22 / 57 | 2,353 / 13 / 13 |
Real win: ~35-40% fewer reads, ~50% less CPU. Remaining cost on the 30K-invoice account is the full-year line scan.

## Prod to-do
Function + grants; EXCEPT on Prod customers (incl. 1706/advance bill); deploy asi_customer_tab_sales.srd (NO embedded data - close preview before save); repoint the customer-window tab config; keep old for rollback.
Mark: InfoMaker data source -> copy `customer_tab_sales`, rename `asi_customer_tab_sales`, paste `v2.retrieve.paste.sql` (on clipboard).

## Known limitation (2026-10-19)
The graph (gr_1, 'Sales Last 12 Months') renders in the P21 desktop client and InfoMaker but NOT in the P21 web client - same in Prod before any change (Mark confirmed). Graph controls aren't drawn by the web client; not caused by the kb_ retirement and not fixable inside the DataWindow. Grid shows the same numbers. Option if a chart is wanted on web: separate chart (dashboard/SSRS).
