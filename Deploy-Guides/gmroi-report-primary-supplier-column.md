# Deployment Guide — (no ticket) GMROI Report: `primary_supplier` column + `#REF!` regression fix

> Produced during development 2026-09-11. Update as the artifact changes; commit with the code.

## Artifact(s)
- **Workbook:** `…\OneDrive - All Surfaces Inc\Documents\Excel\GMROI inventory turns by manufacturer from Derek refreshable 8.19.25 MG_unprotected.xlsx`
  — two Power Queries: **`Trailing-90-Day-qry`** (Sales sheet) and **`qryInventoryValuebyLocation`** (Inventory sheet).
- **Repo copies of the SQL:**
  - `Sql-Scripts/GMROI-Report/Manufacturer-Primary-Supplier-analysis-source-query.sql` — the primary-supplier derivation, standalone
  - `Sql-Scripts/GMROI-Report/Trailing-90-Day-qry-ALL-with-primary-supplier-test.sql`, `Inventory-Value-by-Loc-Mfr-Brand-ALL-with-primary-supplier-test.sql` — full-scope proof copies
  - `Trailing-90-Day-qry-{MAP,ROP,KRA}-only-test.sql` / `-with-primary-supplier-test.sql`, `Inventory-Value-by-Loc-Mfr-Brand-{MAP-ROP,KRA}-*-test.sql` — the incremental single/two-manufacturer proofs done before generalizing
- Ticket: none (ad-hoc; follow-on to `gmroi-report-kb-view-removal.md`, originated from Jerome Butler's team saying they work from "primary supplier" not a rolled-up vendor)
- Related, superseded: `GMROI-Manufacturer-Primary-Supplier-Analysis.xlsx` (standalone 2-tab deliverable built earlier in the same session before the user asked to match the original workbook's fields/tabs instead) and its generator `C:\PowerShell-Scripts\Create-Excel\Create-GMROI-Manufacturer-Primary-Supplier-Analysis.ps1` (not committed, per the Excel-scripts-folder convention) — no longer the live answer.

## What changed

### 1. `#REF!` regression fix (prerequisite — unrelated to primary-supplier, but blocking it)
The 9/3 `kb_`-removal edit (see `gmroi-report-kb-view-removal.md`) was applied to the live file **without** the `AS manufacturer_id` / `AS manufacturer_name` aliases its own deploy guide claimed were preserved. Power Query fell back to raw source names `class_id1`/`class_description`, breaking two structured references built against the old names:

| | Before (broken) | After (fixed) |
|---|---|---|
| Sales table `match` calculated column | `=TEXTJOIN(" ",TRUE,[@[source_loc_id]],#REF!)` | `=TEXTJOIN(" ",TRUE,[@[source_loc_id]],[@[class_id1]])` |
| `Mfr Target Turns` Table5 col F (`Sales (ann)`) | `SUMIFS(Trailing_90_Day_qry[Sales (annualized)],#REF!,...)` | `SUMIFS(Trailing_90_Day_qry[Sales (annualized)],Trailing_90_Day_qry[class_id1],...)` |
| `Mfr Target Turns` Table5 col G (`Cost (ann)`) | same pattern, `COGS (annualized)` | same fix |

The `match` break was the worse of the two — it silently fed `$0` into the Inventory sheet's own "Sales (annualized)" column via `IFERROR`, with no visible error at all, while the Table5 columns errored visibly.

### 2. `primary_supplier` column added (not a replacement)
One join added to each query, keyed by `class_id1`/`Manufacturer Code`:

```sql
;WITH mfr_supplier AS (
    SELECT im.class_id1 AS mfr_code, isup.supplier_id, s.supplier_name,
           COUNT(DISTINCT im.inv_mast_uid) AS item_ct
    FROM inv_mast im
    JOIN inventory_supplier isup ON isup.inv_mast_uid = im.inv_mast_uid AND isup.delete_flag = 'N'
    JOIN supplier s ON s.supplier_id = isup.supplier_id
    WHERE im.delete_flag = 'N' AND im.class_id1 IS NOT NULL AND im.class_id1 <> ''
    GROUP BY im.class_id1, isup.supplier_id, s.supplier_name
),
max_ct AS (SELECT mfr_code, MAX(item_ct) AS max_ct FROM mfr_supplier GROUP BY mfr_code),
po_dollars AS (
    SELECT im.class_id1 AS mfr_code, h.supplier_id, SUM(l.qty_received * l.unit_price) AS received_dollars_12mo
    FROM po_hdr h
    JOIN po_line l ON l.po_no = h.po_no AND l.delete_flag = 'N'
    JOIN inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
    WHERE h.order_date >= DATEADD(MONTH, -12, GETDATE())
      AND im.class_id1 IS NOT NULL AND im.class_id1 <> ''
    GROUP BY im.class_id1, h.supplier_id
),
primary_supplier AS (
    SELECT ms.mfr_code, ms.supplier_id, ms.supplier_name,
           ROW_NUMBER() OVER (PARTITION BY ms.mfr_code
               ORDER BY ms.item_ct DESC, ISNULL(pd.received_dollars_12mo,0) DESC, ms.supplier_id ASC) AS rnk
    FROM mfr_supplier ms
    JOIN max_ct mx ON mx.mfr_code = ms.mfr_code
    LEFT JOIN po_dollars pd ON pd.mfr_code = ms.mfr_code AND pd.supplier_id = ms.supplier_id
)
```
`LEFT JOIN primary_supplier ps ON ps.mfr_code = <class_id1 column> AND ps.rnk = 1`, then `ps.supplier_name` selected right after the manufacturer-code column (both SELECT and GROUP BY). Full text in the `Trailing-90-Day-qry-ALL-with-primary-supplier-test.sql` / `Inventory-Value-by-Loc-Mfr-Brand-ALL-with-primary-supplier-test.sql` files above — those are byte-equivalent to what's live except for cosmetic wrapping.

**Primary-supplier logic:** #1 supplier by distinct item count within the manufacturer class. Ties (4 of 213 manufacturers currently: CLN, DEW, FXI, PSN) broken by trailing-12-month received PO $ **scoped to that manufacturer's own items** — an earlier unscoped attempt pulled in one supplier's $325M of unrelated PO history and had to be redone. Remaining ties with zero PO history either way (currently DEW, FXI) fall to a deterministic last resort (lower `supplier_id`) — not data-driven, worth a manual glance.

**Why add, not replace:** supplier ≠ manufacturer for ~30 distributor/private-label cases (Casabella etc.), so both columns carry real information. Also: replacing/renaming a column is exactly the failure mode that caused the `#REF!` regression above — adding a new column can't touch any existing structured reference by name.

## Target
- The workbook above (`MG_unprotected` copy) — **DONE 2026-09-11**, both fixes applied and verified.
- **Derek Sievertsen's "refreshable" master** — still has never received the 9/3 `kb_` fix, and now also lacks both fixes from this session. Path still not confirmed (open since 9/3).

## Dependencies & deploy order
- The `#REF!` fix must land before or with the `primary_supplier` add — both touch the same tables/formulas and were verified together. No DB objects created; pure query-text + calculated-column-formula changes.

## Backward-compatibility notes
- Existing columns (`class_id1`, `class_description`, `sales`, `cost`, `gp`, `gm%`, `Manufacturer Code`, `Manufacturer Name`, `Value`, etc.) unchanged in name and position — only a new column inserted after the manufacturer-code column in each query, and two formula bodies corrected (text only, not structure).

## Deploy steps (Excel, per workbook copy)
1. Back up the workbook first: `<name>.PRE-REFFIX-<yyyymmdd-hhmmss>.xlsx`, then `<name>.PRE-PRIMARYSUPPLIER-<yyyymmdd-hhmmss>.xlsx` (done for MG_unprotected: `…PRE-REFFIX-20260911-145951.xlsx`, `…PRE-PRIMARYSUPPLIER-20260911-200944.xlsx`).
2. **`#REF!` fix:** via Excel COM, set each broken cell's `.Formula` across the full `DataBodyRange` of the affected calculated column (Sales table `match`; Table5 `Sales (ann)` and `Cost (ann)`) — not just row 1; Excel Tables don't always auto-propagate a COM-set formula to the rest of a calculated column.
3. **`primary_supplier` add:** edit each query's M text via `Workbook.Queries.Item("<name>").Formula`, inserting the CTE + new SELECT/JOIN/GROUP BY entries. Verify the edit persisted by reading `.Formula` back (`-match 'primary_supplier'`), not by re-grepping the raw XLSX bytes (M code is nested three layers deep — see `feedback_excel_powerquery_com_automation.md`).
4. **Refresh — do NOT use `Workbook.RefreshAll()` then `Save()` immediately.** `RefreshAll()` is asynchronous by default; a following `Save()` can land before the (heavy, `bi_view_invoice`-based) query finishes, silently saving the pre-refresh table shape with the new column missing even though the query definition is correct. Instead, for each affected `ListObject`: set `.QueryTable.BackgroundQuery = $false`, then call `.QueryTable.Refresh()` (synchronous, blocks until done — Sales took ~43s, Inventory ~8s), *then* `Save()`.
5. Verify (see below), then `Save()`.

## Verification
- **`#REF!` fix:** scanned the entire workbook (`UsedRange.Find`/`FindNext` on every sheet) for `#REF!` — **0 found**, down from every row of Table5 cols F/G/H/I/J and the Sales table's `match`/`Inventory` columns.
- **`primary_supplier` equivalence, proven on Prod at each stage before touching the live file:**
  - MAP alone (both queries): 42 rows (Sales) / 42 rows (Inv, MAP+ROP combined test = 83), sales/cost/Value identical to the pre-existing baseline, `EXCEPT` not needed since totals matched exactly to the penny.
  - ROP, then KRA: same pattern, same exact-match result.
  - **All 213 manufacturers, unfiltered — Sales:** 2,411 rows, `sales=80,719,992.4109981`, `cost=58,660,203.626184`, identical pre/post. **Inventory:** 2,728 rows, `Value=56,302,737.0225399`, identical pre/post.
  - The 25 rows with blank `Primary Supplier` in the Inventory result are the pre-existing "no manufacturer classified" bucket — confirmed those same 25 rows already had blank `Manufacturer Code` **and** blank `Manufacturer Name`, so nothing new is unresolved.
- **Post-deploy, in the live file:** headers show `primary_supplier` immediately after `class_id1` (Sales) and `Primary Supplier` immediately after `Manufacturer Code` (Inventory); row counts and `sales`/`cost`/`Value` totals match the SQL-side proof above exactly; spot-checked every MAP/ROP/KRA row in the live table (Mapei Corporation / Roppe Corp / Kraft Tool Company, no mismatches).

## Rollback
- `#REF!` fix: restore `…GMROI inventory turns by manufacturer from Derek refreshable 8.19.25 MG_unprotected.PRE-REFFIX-20260911-145951.xlsx` (predates both this fix and the `primary_supplier` add — still has the `#REF!` bug).
- `primary_supplier` add only (keep the `#REF!` fix): restore `…MG_unprotected.PRE-PRIMARYSUPPLIER-20260911-200944.xlsx`.

## Open items (not this deploy — flagged for user review)
1. **DEW and FXI** — primary supplier is a deterministic tiebreak, not data-driven (zero PO history either way in the last 12 months). Worth a manual glance before Jerome sees them.
2. **`Mfr Target Turns`'s own manufacturer list is a separate static ~240-row hand-typed table** (`Table5`, columns B/C), not sourced from either Power Query — it does not show Primary Supplier. Needs a decision: one-time manual swap of ~240 names, or a new lookup formula against a primary-supplier reference.
3. Whether Jerome's team should be told the GM%/Turns figures they've read off this sheet since 9/3 were wrong (see `#REF!` fix above).
4. Derek Sievertsen's separate "refreshable master" workbook still needs the 9/3 `kb_` fix **and** both fixes from this session — path not yet confirmed.
