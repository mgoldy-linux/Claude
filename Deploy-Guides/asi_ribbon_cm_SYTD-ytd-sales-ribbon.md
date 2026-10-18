# Deployment Guide — YTD Sales Ribbon Tile (`asi_ribbon_cm_SYTD`, kb_ retirement)

> Produced during development. Update as the artifact changes; commit with the code.

**Status: 🟡 Ready to test/deploy — built and reviewed 2026-03-27, never deployed or logged.**
Code is finished and matches the changelog exactly. What's left is entirely manual, in-client
work this session can't perform: register the rule in a P21 ribbon config, then run the TC-01..08
test plan against a live customer ribbon. No further coding needed unless testing surfaces a bug.

## Request
Rewrite the customer-ribbon "YTD Sales" tile business rule, `kb_CustRM_getYTDSalesAbbr`, to fix a
root-cause bug (ribbon shows blank for every customer) and retire its `kb_` dependencies per the
standing 2026 KB-retirement goal. Reference: SysAid 20251229.

## Artifact(s)
- `asi_ribbon_cm_SYTD.cs` (namespace `asi_RibbonMetrics`) — new business rule, replaces
  `kb_CustRM_getYTDSalesAbbr`
- `Docs\asi_ribbon_cm_SYTD_changelog.txt` — full change log, known-variance writeup, and the
  TC-01..08 test plan (do not duplicate that plan here — follow it directly)

## Root cause fixed
`kb_CustRM_getYTDSalesAbbr` filtered `WHERE year_for_period = Year(GetDate())`. `year_for_period`
on `invoice_hdr`/`kb_sales_history_report_view` is `VARCHAR`; `Year(GetDate())` returns `INT`. The
implicit conversion silently matched zero rows — the ribbon tile displayed blank for every
customer, with no error.

## kb_ objects retired
| kb_ object | Replaced with | Notes |
|---|---|---|
| `kb_CustRM_getYTDSalesAbbr` | `asi_ribbon_cm_SYTD` | Full C# rewrite — direct field access replaces `GetFieldByAlias`, `nameof()` replaces LINQ class-name expressions, `kb_SQLHelper`/`LogError` removed in favor of P21's native business rule logging |
| `kb_sales_history_report_view` | `p21_sales_history_view` (P21-native view) | 2nd consuming artifact to retire this view (see `SA-55014-sales-invoiced-yesterday-portal.md`, which hand-ported it into a TVF). Here it's a direct swap since the ribbon only needs a simple SUM. Required 3 compensating changes — see below |
| `kb_fn_number_shorten` | `FormatSalesAbbr()` (private static C# method) | Formatting moved out of SQL entirely: `>= 1,000,000 → $X.Xmln`, `>= 1,000 → $X.Xk`, `< 1,000 → $X`, negative → `-$X.Xk` |

### Compensating changes required by the `p21_sales_history_view` swap
1. **`DISTINCT invoice_line_uid` subquery added** — `p21_sales_history_view` has one row per
   salesrep per invoice line; the `kb_` view didn't. Without this, lines with multiple salesreps
   would be double-counted.
2. **Net sales filters added** to replicate the `kb_` view's exclusion logic:
   `item_id NOT IN ('CREDITMISC','DOWNPAYMENT','PREPAYMENT')`, `other_charge_item = 'N'`,
   `inv_mast_uid <> 0`. `rma_flag` is deliberately **not** excluded — product returns are included
   in net sales, matching `kb_` behavior.
3. **Incentive rewards subtracted** via `LEFT JOIN p21_view_rewards_program_values` (summed
   `accumulated_incentive_points` per `invoice_line_uid`) to replicate how the `kb_` view's
   `sales_price_home` column already had rewards subtracted.
4. `@CustNo` parameter changed `SqlDbType.Int` → `SqlDbType.VarChar` (`customer_id` is `VARCHAR`
   in `p21_sales_history_view`).

## Known variance — accepted, not fixable from this rule
Validated against 200 random customers (two runs of 100): **92–98% exact match per run.**
- **Root cause 1:** `extended_price_home = 0` on swap/exchange lines in `p21_sales_history_view`,
  where `kb_` view's `sales_price_home` showed non-zero (example item `SOMCP51HCBLG`). Column
  calculation difference between the two views — cannot resolve from the BR side.
- **Root cause 2:** real product lines flagged `other_charge_item = 'Y'` exist in
  `p21_view_invoice_line` but aren't exposed by `p21_sales_history_view`, so they're silently
  dropped; `kb_` included them (example item `CBLAQUAPROOFXLDISPLAY`). A `p21_sales_history_view`
  coverage gap — cannot resolve from the BR side.
- **Impact:** consistently small (< 1% of total) on affected customers. Accepted by Bus App Team
  2026-03-27.

## Target environments
Dev/Test (register + run TC-01..08) → Prod, per the changelog's rollback plan.

## Pre-deployment checklist
- [ ] Deploy `asi_ribbon_cm_SYTD.cs` to Dev/Test P21 environment
- [ ] Register the business rule in P21 ribbon configuration
- [ ] Confirm the old rule `kb_CustRM_getYTDSalesAbbr` is disabled (**do not delete** until the new
      rule is confirmed working)

## Deploy steps
1. Compile/deploy `asi_ribbon_cm_SYTD.cs` to the target environment's business rule DLL share.
2. Register `asi_ribbon_cm_SYTD` against the customer ribbon in Rule Manager, field-mapped to
   `customer_id` and `customer_type_cd` (per the changelog's field-rename notes — this rule reads
   `customer_type_cd`, not the old `cust_type`).
3. Disable (do not delete) `kb_CustRM_getYTDSalesAbbr` in the same environment.
4. Run TC-01 through TC-08 from `Docs\asi_ribbon_cm_SYTD_changelog.txt` against real Dev/Test
   customer data.
5. On a clean pass, repeat steps 1–3 in Prod, then re-run the test plan there (at minimum TC-01,
   TC-02, TC-03, TC-05 — the customer-type and year-boundary cases most likely to surface an
   environment-specific data difference).

## Verification
- Each TC-01..08 result recorded in the changelog's own Pass/Fail/Blocked checkboxes.
- TC-05 (year boundary) and the "SQL VALIDATION QUERY" at the bottom of the changelog both still
  reference the old `kb_sales_history_report_view` — **run the validation manually against
  `p21_sales_history_view` with the same net-sales filters this rule uses** (see the SQL in
  `asi_ribbon_cm_SYTD.cs`) rather than the changelog's literal query, since the `kb_` view may no
  longer be trustworthy as an independent check once this deploys.

## Rollback
Per the changelog: re-enable `kb_CustRM_getYTDSalesAbbr` in the P21 ribbon config, disable
`asi_ribbon_cm_SYTD`, log the issue. Do not delete `kb_CustRM_getYTDSalesAbbr` until
`asi_ribbon_cm_SYTD` has run clean in Prod for at least one week.

## Open items
- [ ] Register in Dev/Test, run TC-01..08 (needs the P21 client — outside what a Claude session
      can execute)
- [ ] Deploy to Prod once Dev/Test passes clean
- [x] `kb-replacement-tracker.csv` updated (3 rows: rule rename, view swap, function removal)
- [ ] Delete `kb_CustRM_getYTDSalesAbbr` after one week of clean Prod operation
