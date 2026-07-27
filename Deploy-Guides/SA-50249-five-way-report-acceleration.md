# Deployment Guide — Five Way Sales Report Acceleration (ASI_ReportCache)

> **Ticket note:** SA-50249 was an **access-only** request and is **closed**. This performance work is a
> separate deliverable, now tracked as **Report 1** under the **SSRS Reports Performance Improvements**
> initiative (`C:\_P25\SSRS-Report-Performance-Progress.md`). Filenames keep the `SA-50249` name for continuity.
>
> Produced during development. Update as the artifact changes; commit with the code.
> **STATUS (2026-07-20): NOT yet live — no view swap has ever been performed.**
> DB, synonyms, map, compute view and a first fact build all exist on the DW. The 2026-07-17
> one-time build+verify surfaced **two defects (both now fixed, see below)**; the fact is being
> rebuilt on **2026-07-20 23:00** before go-live is reconsidered.
> Originally built and proven in **P21Play**; this guide adapts that to the DW's nightly-restore reality.

## What problem this solves
`asi_3yr_sales_history_report_view` recomputes heavy per-row logic (3 scalar UDFs over ~3.6M rows)
on every report run. Measured on P21Play: the core query = **149,547 ms CPU / 1.3M+ reads**.
Materializing the view's output into a **columnstore fact table** and pointing the view at it as a
passthrough = **125 ms / 2,016 reads** — proven byte-for-byte equal (EXCEPT both ways, all 195 cols).

## Artifact(s)
- **New database `ASI_ReportCache`** (persistent, SIMPLE recovery, not backed up — fully rebuildable)
- `ASI_ReportCache.dbo.asi_salesrep_manager_map` — memoizes the sales-manager UDFs (~505 rows)
- `ASI_ReportCache.dbo.FiveWaySalesCompute` — the fast compute VIEW (reads `P21.dbo.*` + local map)
- `ASI_ReportCache.dbo.FiveWaySalesFact` — materialized table + clustered columnstore (~3.6M rows)
- `ASI_ReportCache.dbo.uspRefreshFiveWaySalesFact` — nightly refresh proc
- SQL Agent job **`ASI Refresh - Five Way Sales Fact`** (runs the proc post-restore)
- **Swap** of `P21.dbo.asi_3yr_sales_history_report_view` →
  `SELECT * FROM ASI_ReportCache.dbo.FiveWaySalesFact WHERE invoice_date >= DATEADD(year,-3,GETDATE())`
- Ticket: SA-50249

## Target environment
- DW: **`asdwdb01.ahi.local`** (the `DW-P21` data source `→` database `P21`). **This is the reports' "Prod."**
- **Prod ERP (`ASP21DB1`) is NOT touched.** No ERP object changes at all.

## The hard constraint that shapes everything
`P21` on the DW is **dropped and re-restored from Prod every night at 2:05 AM**
(`P21 Daily Restore from Production`). Therefore:
- Anything created **inside `P21`** is wiped nightly.
- Persistent objects live in **`ASI_ReportCache`** (a new DB, not restored) — mirrors how the shop
  already keeps custom tables in `Budget` and refreshes them post-restore.
- The **only** thing re-applied inside `P21` each night is the passthrough view swap — done by the
  refresh proc, gated on a successful fact build (see Safety).

## Architecture / data flow
```
2:05 AM   P21 restored from Prod  (brings ORIGINAL asi_3yr view + base tables + kb_ funcs)
~3:30 AM  Agent job -> ASI_ReportCache.dbo.uspRefreshFiveWaySalesFact:
            1. rebuild asi_salesrep_manager_map   (calls P21.dbo.kb_fn_* once per ~505 pairs)
            2. TRUNCATE + reload FiveWaySalesFact from FiveWaySalesCompute (reads P21.dbo.*)
            3. IF load OK  ->  CREATE OR ALTER P21.dbo.asi_3yr_sales_history_report_view
                               AS SELECT * FROM ASI_ReportCache.dbo.FiveWaySalesFact
               ELSE        ->  leave the restored ORIGINAL view in place (reports slow but CORRECT)
Report run  asi_3yr_sales_history_report_view (passthrough) -> reads columnstore fact -> fast
```
Persistent objects (`FiveWaySalesCompute`, `FiveWaySalesFact`, `asi_salesrep_manager_map`, the proc) all
live in `ASI_ReportCache` and survive the restore; they reference `P21.dbo.*` via 3-part names.

## Prerequisites (confirm before deploy)
1. ~~Permission to `CREATE DATABASE` on `asdwdb01`.~~ **CONFIRMED** — `AHI\mgoldyn` is `sysadmin` on `asdwdb01` (2026-07-17).
2. `SSRS_Users` can be granted `SELECT` on `ASI_ReportCache` (cross-DB read from the P21 passthrough).
3. Confirm the post-restore run window (proposed **3:30 AM**, after `…Alter SSRS`, before business hours).
4. ~~DW account running the deploy has DDL rights and Agent-job create rights.~~ **CONFIRMED** — sysadmin covers all of it.

## Deploy order
1. `01-create-database.sql`  — create `ASI_ReportCache`, SIMPLE recovery, grants.
2. `02-generate-objects.ps1` — generates + creates `asi_salesrep_manager_map`, `FiveWaySalesCompute`,
   `FiveWaySalesFact` (+ CCI) from the validated `_fast3` logic (P21 refs → 3-part names).
3. `03-refresh-proc.sql`     — create `uspRefreshFiveWaySalesFact`.
4. Run the proc once manually  — seeds the fact + performs the first view swap (immediate effect).
5. `04-agent-job.sql`        — create the post-restore Agent job + schedule.

## Verification (run after step 4)
- **Correctness (on DW data):**
  ```sql
  -- expect 0 / 0
  SELECT COUNT(*) FROM (SELECT * FROM P21.dbo.asi_3yr_sales_history_report_view_ORIG WHERE invoice_date >= DATEADD(day,-7,GETDATE())
                        EXCEPT SELECT * FROM ASI_ReportCache.dbo.FiveWaySalesFact WHERE invoice_date >= DATEADD(day,-7,GETDATE())) a;
  -- and the reverse
  ```
  (Capture the ORIGINAL view as `..._ORIG` during step 4 so this comparison is possible.)
- **Speed:** run the core query against the passthrough view — expect double-digit ms, not ~150 s.
- **Rendered report:** run `/Company Reports/Sales/Five Way Sales Report Reduced wo Customer Dropdown`
  → renders near-instantly, totals sane.
- **Next-morning check:** after the first automated 2:05 restore + 3:30 job, confirm the view is a
  passthrough again and the report is still fast (proves the self-healing cycle).

## Rollback (`05-rollback.sql`)
Single, instant, no report changes:
1. Disable the Agent job.
2. `CREATE OR ALTER P21.dbo.asi_3yr_sales_history_report_view AS <original definition>`
   (preserved as `P21.dbo.asi_3yr_sales_history_report_view_ORIG` + saved in this folder).
Reports flip back to the original behavior immediately. The next 2:05 restore also restores the
original on its own; leaving the job disabled means it simply stays original. `ASI_ReportCache` can
be left in place (harmless) or dropped later.

## Affected reports (blast radius)
ONLY the 5 reports that read `asi_3yr_sales_history_report_view`:
- `/Company Reports/Sales/Five Way Sales Report Reduced wo Customer Dropdown`
- `/Company Reports/Sales/Five Way Sales Report Reduced wo Customer Dropdown-SA-48715-Fix`
- `/Test-Mark/…` (3 copies)
**NOT** `My Five Way` or `Branch Five Way` — those read `kb_sales_history_report_view` (untouched).

## Defects found by the 2026-07-17 one-time build+verify (both FIXED 2026-07-20)

The one-time job logged `fact_minus_compute=5` and `compute_minus_orig=2 / orig_minus_compute=2`
instead of the hoped-for 0/0. Diagnosis:

**1. `manager_name` wrong on 13,349 rows — REAL BUG (the reason go-live was held).**
The memo-map join was `smn_map.commission_class_id = inv_mast.commission_class_id`. Where
`commission_class_id` is NULL, `NULL = NULL` is UNKNOWN → the LEFT JOIN misses → `COALESCE(...,'None')`
returns `'None'`. The correct answer was sitting in the map under a NULL key, unreachable (70 such
map rows). The ORIGINAL view was unaffected because it calls the UDF per row and the UDF handles a
NULL argument fine — **this was a regression introduced by the memoization itself.**
Impact: all 13,349 fact rows with a NULL `commission_class_id` (0.35% of 3.83M) reported manager
`None`; only 4 rows were legitimately `None`. On a sales-manager breakdown report that silently
misattributes revenue away from real managers.
**Fix:** NULL-safe join, `ISNULL(smn_map.commission_class_id,'') = ISNULL(inv_mast.commission_class_id,'')`.
Verified collision-free: **zero** empty-string `commission_class_id` values exist in map or fact.
The parallel `pm_map` join keys on `inv_mast_uid` and has no NULL exposure.
**Proven:** 2026-07-15 compute-vs-original went from 2/2 to **0/0**.

**2. The `5`-row diff — benign, a verification artifact.**
The compute view filtered `invoice_date >= DATEADD(year,-3,GETDATE())`. The fact was built at
23:04 and verified at 00:04 the next day; the 3-year boundary slid across midnight, and exactly 5
rows on 2023-07-18 carry a `00:00:00` timestamp, so they fell out of the live view while already
frozen into the fact. Not a logic defect — but it made the nightly verify **non-deterministic**.
**Fix:** the fact is now built with a day-stable boundary (`CAST(GETDATE() AS DATE)`, a superset) and
the exact sliding filter moved to the P21 passthrough view at read time. This preserves the
ORIGINAL's semantics precisely *and* makes fact-vs-compute a meaningful, repeatable check.

**Lesson:** memoizing a scalar UDF into a lookup table changes NULL semantics — a UDF accepts a NULL
argument, a join key does not. Any future `*Compute`/`*Fact` pair in this DB must use NULL-safe joins
on nullable memo keys.

## Safety notes
- The view swap is **gated on a successful, sanity-checked fact load** (rowcount threshold). On any
  failure the proc leaves the restored ORIGINAL view in place → reports are slow but never broken.
- `ASI_ReportCache` is SIMPLE recovery and needs **no backups** — it is rebuilt nightly from P21.
- KB dependency is **reduced, not retired**: the map is still populated by `kb_fn_*` (505 calls/night)
  and the compute view still references `kb_view_*`. Log in the KB tracker; full retirement is later.

## Scaling to other reports (design intent)
`ASI_ReportCache` is a shared home. Each future report to accelerate =
1. add `FooCompute` view + `FooFact` table (+ CCI) in `ASI_ReportCache`,
2. add a step to the refresh proc/job,
3. swap its P21 passthrough view.
Watch the **post-restore window** (2:30 AM → business hours). When it fills up: switch heavy facts to
**incremental refresh** (reload only recent days) and/or parallelize job steps. Candidates next:
`My Five Way` / `Branch Five Way` (heavier `kb_sales_history_report_view`).
