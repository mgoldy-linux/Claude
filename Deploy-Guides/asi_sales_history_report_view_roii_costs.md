# Deployment Guide — `asi_sales_history_report_view_roii_costs` (kb_ retirement + perf)

> Produced during development 2026-10-02. Update as the artifact changes; commit with the code.

**Status: 🔵 Drafted, NOT run anywhere. Approach changed 2026-10-02: Invoice Detail gets a report-specific function, not the 197-column view.**

## Current plan: `asi_fnt_invoice_detail(@d_start, @d_end)` (decision 2026-10-02)
- The kb_ view is one of kbenish's "giant views": 197 columns built over all invoice history, for any report to call. Invoice Detail reads **45** of those columns, displays 44, and always filters by date.
- The new inline TVF `SQL-Schema/CREATE-OR-ALTER-FUNCTION-asi_fnt_invoice_detail.sql` returns only those 45 columns, with the same names, and applies the date range itself. The row filters and the logic for each column are copied from the kb_ view unchanged. Joins the report never reads are left out.
- **Report change (one line, done after verification):** `FROM kb_sales_history_report_view_roii_costs AS shrv` → `FROM dbo.asi_fnt_invoice_detail(@d_start, @d_end) AS shrv`. The existing `WHERE shrv.invoice_date BETWEEN ...` line becomes redundant but harmless. SA 56113 is editing the same RDL right now, so make this change after that ships.
- **Create on P21Play, in order:**
  1. `asi_fnt_get_sales_manager`
  2. `asi_view_rebill_invoices`
  3. `asi_table_dancik_open_invoice_costs`
  4. `asi_fnt_invoice_detail`
  5. Run `Sql-Scripts/Sales/roii-costs-asi/03-verify-invoice-detail-tvf.sql`. Pass means: A has equal row counts and 0/0 differences; B shows duplicate lines (any on the kb_ side are a fix, not a regression); C1–C3 = 0; then read the D cost numbers, also year-to-date with `@pm = 'ABOEVE'`.
- `asi_sales_history_report_view_roii_costs` (the 197-column drop-in) is **parked as a draft, not deployed**. It is kept for reference and in case Buying Group Invoice Detail or InvoiceDetail with Live Standard Cost need it. Those two could instead each get the same report-specific treatment later. Its verify script is `02`.


## Artifact(s)
- `SQL-Schema/CREATE-OR-ALTER-FUNCTION-asi_fnt_get_sales_manager.sql`: inline TVF. Replaces scalar `kb_fn_get_sales_manager` + `kb_fn_get_sales_manager_names` (and the nested `kb_fn_get_contact_name`)
- `SQL-Schema/CREATE-OR-ALTER-VIEW-asi_view_rebill_invoices.sql`: verbatim port of `kb_view_rebill_invoices`. It already used only native tables.
- `SQL-Schema/CREATE-TABLE-asi_table_dancik_open_invoice_costs.sql`: one-time copy of the `js_view_open_invoice_costs` **table**, which holds 17,624 Dancik-era lines with invoice dates 2014-10 to 2017-07.
- `SQL-Schema/CREATE-OR-ALTER-VIEW-asi_sales_history_report_view_roii_costs.sql`: the view. A drop-in for `kb_sales_history_report_view_roii_costs`, with the same 197 columns in the same order.
- `Sql-Scripts/Sales/roii-costs-asi/01-pull-dependency-definitions.sql`: read-only. Pulls Prod definitions, indexes, dead-join uniqueness and SSRS consumers.
- `Sql-Scripts/Sales/roii-costs-asi/02-verify-equivalence-and-perf.sql`: read-only. Checks the column contract, runs `EXCEPT` both ways plus row counts, tests the TVFs over all inputs, and reads DMV reads/CPU.
- Ticket: none yet

## Consumers (SSRS, all alias the view as `shrv`)
- `Invoice Detail` (Company Reports/Sales). SA 56113 is editing this RDL right now (`C:\SSRS-Local\Invoice Detail.rdl`).
- `Buying Group Invoice Detail`
- `InvoiceDetail with Live Standard Cost`
- Confirm the full list with query 6 in `01` (ReportServer catalog). Only local RDL copies were searched.

## What changed and why
| # | Change | Expected effect |
|---|---|---|
| 1 | 3 scalar UDFs → inline TVFs. `kb_fn_get_sales_manager` was in a **JOIN predicate**. The Invoice Detail report also *filters* on `manager_id` and `product_manager_id`, so all 3 run on every row in the date range. | **Prod confirmed 2026-10-02: SQL 2019 CU32 (15.0.4435.7) Standard, compat 150, `TSQL_SCALAR_UDF_INLINING` = 1.** `is_inlineable`: `kb_fn_get_sales_manager` **0**, `kb_fn_get_sales_manager_names` **0**, `kb_fn_get_product_manager` 1, `kb_fn_get_contact_name` 1. So the two sales-manager UDFs run row-by-row **and force the whole query serial**, which makes this the real UDF win. The product-manager swap is retirement only, since SQL Server is probably inlining it already, so expect no perf change. `kb_fn_get_contact_name` is inlineable but is called from inside the non-inlineable names UDF, so it still runs per call. |
| 2 | `kb_view_invoice_line_rewards`, `drv_sumlines` and `invoice_line_summary` were **all-history aggregates** joined on their GROUP BY key. They are now correlated `OUTER APPLY`. `drv_sumlines` only runs for service orders (1706 / pricing_option 0), the only branches that read it. | Should be the main win (same lesson as SA-55014: unfiltered aggregates were the cost). **Depends on indexes.** `01` §4 lists the keys. Without them each APPLY becomes a scan per row and this gets *slower*. |
| 3 | Dead joins removed: shipping_route, inv_sales_loc, unaliased job_price_line/hdr, progress_billing_x_invoice_hdr, oe_line_dealer_commission, gallon UOM pair, order_floor_plan_xref_10002, drv_nested_lot_header_comm_cost, duplicate salesrep_ud, address_history | Mostly cleanup. Joins on a unique key were probably already pruned by the optimizer. A real gain only comes from the non-unique ones (`01` §5). |
| 4 | `invoice_hdr_salesrep` LEFT JOIN + `WHERE primary_salesrep='Y'` → INNER JOIN | Same rows, honest intent |
| 5 | sales_price_home / line_other_cost_home computed once; gross_profit_dollars = difference | Readability (~180 duplicated lines gone). CPU effect negligible. |

## Still kb_/js_ (phase 2, needs `01` output)
- `js_view_open_invoice_costs`: cost override for imported open invoices. Likely a static conversion-era table, which could be copied once into an `asi_` table.
- `kb_view_direct_invoices_incl_rebills` → `kb_view_oe_pick_ticket` + `kb_view_rebill_invoices`. This is also a **full scan every run**, because the view's `CONVERT(VARCHAR(10), CASE…)` join key is non-sargable. The rewrite is `CASE WHEN EXISTS(...)` against `oe_pick_ticket` (established replacement) plus whatever the rebill view really does.
- `kb_table_sales_manager_values` / `_all`: data tables read inside `asi_fnt_get_sales_manager`. They hold no logic. Retiring them = a rename/copy to `asi_` tables, not a rewrite.
- `kb_fn_get_product_manager` mapping still returns **`KBENISH`** (departed) as its fallback. This was kept for equivalence. Who owns those groups is a business decision.

## Findings from the first `01` run (P21Play, 2026-10-02)
- **Play:** SQL 2019 CU32 Developer, compat 150, inlining on. `is_inlineable` matches Prod: sales-manager functions 0, product-manager and contact-name functions 1.
- **kb_ function definitions match the Dev copies the new TVFs were built from:** `kb_fn_get_sales_manager`, `_names` and `kb_fn_get_contact_name`. `kb_fn_get_product_manager` was cut off in the results grid, but `02` C1 compares it against every item anyway.
- **`js_view_open_invoice_costs` is a TABLE** (created 2022-09-19), not a view. It's static conversion data, so retiring it means copying it to an `asi_` table, not rewriting logic. Section 7d shows which years it covers.
- **7 other kb_ objects read the kb_ view.** They are commission reports: `kb_view_commission_report`, `_branches`, `_adds`, `_ccs`, `kb_proc_commission_report_ccs`, `_ccs_adds`, `_individual`. **The kb_ view must stay** until those are moved too. That's a separate scope, and this list needs re-checking on Prod.
  - **2026-10-02 relic evidence:** no SSRS report or shared dataset on ASDWDB01 mentions `commission_report`, so ExecutionLog3 has nothing either. Query Store shows none of them in its 45-day window. The procs were last modified Apr/Jul/Oct 2024, which fits the commission-formula change about 2 years ago. They are **retirement candidates**, not conversion targets. Agent jobs, portals and Excel/Power Query sources haven't been checked yet.
- **Indexes are in place for the faster lookups:**
  - `invoice_line`: indexes on `invoice_line_uid_parent`, on `(order_no, oe_line_number)` and on `invoice_no`.
  - `invoice_hdr`: an index starting with `invoice_date`.
  - `oe_line`: primary key on `(order_no, line_no)`.
  - Rewards base table: **not found under the name `rewards_program_values`**. Section 7a/7c identifies the real table. This must be checked before trusting the rewards lookup.
- **Removed joins:** all 6 uniqueness checks returned 0, so none of them was duplicating rows. Removing them can't change results. They're also probably perf-neutral.
- **Direct-ship chain:** `kb_view_oe_pick_ticket` is just `oe_pick_ticket` with `CONVERT(VARCHAR(10), invoice_no)`. `kb_view_rebill_invoices` is already built only on native tables (invoice_hdr + `p21_view_rebill_invoice`). Done: a verbatim `asi_view_rebill_invoices` plus `oe_pick_ticket` directly, keeping the original set-based shape. A per-invoice EXISTS rewrite was considered and rejected for now: the rebill chain's `original_invoice_no` comes out of a COALESCE that can't use an index, so the rewrite carried more risk than gain.

- **Section 7 results (Play, 2026-10-02):**
  - `oe_pick_ticket.invoice_no` is `decimal(19,0)` and has indexes that start with it.
  - The rebill view only reads native tables, so it's ported verbatim. Direct-ship logic is unchanged and still set-based: one pass over direct pick tickets, then a hash join. That's one scan per report run, not one per row. Whether it costs much will show in `02`.
  - `js_view_open_invoice_costs` is static Dancik data, so it's copied to an asi_ table.
  - **The view now has no kb_/js_ references in its code.** The only kb_ objects left are the two sales-manager data tables inside `asi_fnt_get_sales_manager`.
  - **Rewards index confirmed (§7e):** `invoice_line_rewards` is clustered on `(invoice_line_uid, rewards_program_uid)`, so the per-line rewards lookup is a clustered-index seek. `p21_view_rewards_program_values` is `customer_x_rewards_program` → `rewards_program` → LEFT JOIN `invoice_line_rewards`. Filtering on `invoice_line_uid` turns that LEFT JOIN into an inner join, and the optimizer can then drive the lookup from the clustered index. Every index the new lookups need is present.

## Product manager: kb_ function kept on purpose (decision 2026-10-02)
- **Who uses the filter** (ExecutionLog3, about 60 days): the Product Manager filter on Invoice Detail ran 14 of 647 times. Leaving out jvadakkel's testing, the real users are **aboeve** (ABOEVE, about 165K rows per run, roughly monthly) and **jklitzman** (PADMGR). Both pick valid buckets. Nobody picks a departed name. The Sales Manager filter ran 0 times, though `manager_name` is still displayed.
- **Decision:** don't port `kb_fn_get_product_manager`. Its hard-coded mapping still names departed **GTHOMAS** and **KBENISH**, so a copy would only duplicate stale data. The view calls the kb_ function directly. That costs little, because it's inlineable on SQL 2019.
- **Future replacement:** use the P21 **"Product Manager" role** plus a `users_ud` field holding each manager's product assignments. Once those have good values, swap this one column to a lookup against them. Still to define: which `users_ud` field, and whether assignments are keyed by product group, manufacturer class, or both, as the current mapping mixes them.

## Target environments
- Play (P21Play) → verify → Prod (P21 @ P21.allsurfaces.com). The SSRS repoint is a separate, later step.

## Dependencies & deploy order
1. `asi_fnt_get_sales_manager`
2. `asi_view_rebill_invoices`
3. `asi_table_dancik_open_invoice_costs` (copy + index + grants, then confirm both row counts match)
4. the view
5. Run `02-verify` → must be column contract 0 rows, B = equal counts + 0/0, C2–C5 = 0
6. Only then repoint an RDL: `FROM kb_sales_history_report_view_roii_costs` → `FROM asi_sales_history_report_view_roii_costs`. That one line is the whole report edit.
- The kb_ view is **not** dropped or altered. Both coexist until every consumer is moved.

## Deploy steps
1. Run `01` on Prod and Play and save the output. Diff `kb_fn_get_product_manager`, `kb_fn_get_sales_manager(_names)` and `kb_fn_get_contact_name` against the files the TVFs were built from.
2. On Play, run the 3 `SQL-Schema` files in the order above. They already contain `USE [P21Play]`, so change it for Prod. Grants to `p21_application_role` + `PxxiUser` are included.
3. Run `02` on Play: 1-month window, then 12 months.

## Verification
- `02` A: 0 rows. B: kb_rows = asi_rows, 0/0. C1/C2: 0.
- `02` D3: quote `avg_logical_reads` / `avg_cpu_ms` for both. For the kb_ side, **add** the `dm_exec_function_stats` totals, because scalar-UDF work is not counted in the statement's own reads. Ignore elapsed time.
- If asi_ is not faster, say so, and check `01` §4 indexes first.

## Rollback
- Consumers still point at the kb_ view, which is untouched. Rollback = `DROP VIEW dbo.asi_sales_history_report_view_roii_costs; DROP VIEW dbo.asi_view_rebill_invoices; DROP FUNCTION dbo.asi_fnt_get_sales_manager; DROP TABLE dbo.asi_table_dancik_open_invoice_costs;`. For a repointed RDL, revert the one `FROM` line.
